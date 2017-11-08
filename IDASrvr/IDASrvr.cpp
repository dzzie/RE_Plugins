

/*
NOTE: to build this project it is assumed you have an envirnoment variable 
named IDASDK set to point to the base SDK directory. this env var is used in
the C/C++ property tab, Preprocessor catagory, Additional include directories
texbox so that this project can be built without having to be in a specific path
Also used in the Linker - additional include directories.

Note: this includes a decompile function that requires the hexrays decompiler. If you
	  dont have it, you can just comment out the few lines that reference it. 
*/
 

#include <windows.h>  //define this before other headers or get errors 
#include <ida.hpp>
#include <idp.hpp>
#include <expr.hpp>
#include <bytes.hpp>
#include <loader.hpp>
#include <kernwin.hpp>
#include <name.hpp>
#include <auto.hpp>
#include <frame.hpp>
#include <dbg.hpp>
#include <area.hpp>
#include <stdio.h>
#include <search.hpp>
#include <xref.hpp>

bool SendTextMessage(int hwnd, char *Buffer, int blen); 

#define HAS_DECOMPILER //if you dont have the hexrays decompiler comment this line out..

#ifdef HAS_DECOMPILER
	#include <hexrays.hpp>    
	hexdsp_t *hexdsp = NULL;  
	int __stdcall DecompileFunction(int offset, char* fpath);
#endif

#define PYTHON_TEST
#ifdef PYTHON_TEST
//note changed to cdecl as default calling convention..
//otherwise in pyport.h had to: define PyAPI_FUNC(RTYPE) __declspec(dllimport)  RTYPE __cdecl
//pyconfig.h ifdef _DEBUG pragma comment(lib,"python27_d.lib") <-- IDA uses release build of dll always
//was causing plugin load fail for debug build
#ifdef _DEBUG
	#undef _DEBUG
	#include <python27\Python.h>
	#define _DEBUG
#else
	#include <python27\Python.h>
#endif

int hPYClient = 0;

static PyObject *pyreply(PyObject *self, PyObject* args)
{
    const char *command;
    if (!PyArg_ParseTuple(args, "s", &command)) return NULL;
    int rv = SendTextMessage(hPYClient, (char*)command, strlen(command)); 
    return PyLong_FromLong(rv);
}

static PyObject *pytest(PyObject *self, PyObject* args)
{
    return PyInt_FromLong(42L);
}

static PyMethodDef pyClient_methods[] = {
	{"reply", pyreply, METH_VARARGS,  NULL},
	{"test",  pytest,  METH_NOARGS,   NULL},
    {NULL,NULL}           /* sentinel */
};

void init_pyClient(void)
{
    PyImport_AddModule("idasrvr");
    Py_InitModule("idasrvr", pyClient_methods);
}

//we take care of some housekeeping so client scripts are easier..
char* pyStub = 
"import idasrvr\r\n"
"def chunkString(s,sz=1000):\r\n"
"    o = []\r\n"
"    while s:\r\n"
"        o.append(s[:sz])\r\n"
"        s = s[sz:]\r\n"
"    return o\r\n"
"\r\n"
"def reply(message):\r\n"
"    message = str(message)\r\n"
"    print \"sending msg '%s'\" % message\r\n"
"  \r\n"
"    if len(message) > 1000:\r\n"
"        chunks = chunkString(message)\r\n"
"        for c in chunks:\r\n"
"            idasrvr.reply(c)\r\n"
"    else:\r\n"
"        idasrvr.reply(message)\r\n"
;

#endif



int hasDecompiler = 0;
int InterfaceVersion = 1;

#undef sprintf
#undef strcpy
#undef strtok
#undef fopen
#undef fprintf
#undef fclose

#pragma warning(disable:4996)

#include "IDASrvr.h"

xrefblk_t xb;

typedef struct{
    int dwFlag;
    int cbSize;
    int lpData;
} cpyData; 

char baseKey[200] = "Software\\VB and VBA Program Settings\\IPC\\Handles";
char *IPC_NAME = "IDA_SERVER";
HWND ServerHwnd=0;
WNDPROC oldProc=0;
bool m_debug = false;
char m_msg[2020];
cpyData CopyData;
CRITICAL_SECTION m_cs;
UINT IDASRVR_BROADCAST_MESSAGE=0;
UINT IDA_QUICKCALL_MESSAGE = 0;



int __stdcall ImageBase(void);
void __stdcall SetFocusSelectLine(void);

int EaForFxName(char* fxName){
	
	func_t *fx;
	int x = get_func_qty();
	char buf[200];

	for(int i=0;i<x;i++){
		fx = getn_func(i);
		get_func_name(fx->startEA, (char*)buf, 199);
		if(buf){
			//if(m_debug) msg("on index %d name=%s\n", i, buf);
			if(strcmp(buf, fxName)==0){
				if(m_debug) msg("Found ea for name %s=%x\n", fxName, fx->startEA );
				return fx->startEA;
			}
		}
	}

	if(m_debug) msg("Could not find ea for name %s\n", fxName);
	return 0;
}

bool FileExists(char* szPath)
{
  DWORD dwAttrib = GetFileAttributes(szPath);
  bool rv = (dwAttrib != INVALID_FILE_ATTRIBUTES && !(dwAttrib & FILE_ATTRIBUTE_DIRECTORY)) ? true : false;
  return rv;
}

void Launch_IdaJscript(){

	 char tmp[500] = {0};
	 char tmp2[500] = {0};
     unsigned long l = sizeof(tmp);
	 HKEY h;
	 
	 RegOpenKeyEx(HKEY_CURRENT_USER, baseKey, 0, KEY_READ, &h);
	 RegQueryValueExA(h, "IDAJSCRIPT" , 0, 0, (unsigned char*)tmp, &l);
	 RegCloseKey(h);

	 if( strlen(tmp) == 0 ){
		 MessageBox(0,"IDA JScript path not yet set in registry. run it once first","",0);
		 return;
	 }

	 if( !FileExists(tmp) ){
		MessageBox(0,"IDA JScript path not found. run it again to re-register path in registry","",0);
		return;
	 }

	 if( strlen(tmp) < (sizeof(tmp) + 20)){
		 sprintf(tmp2, "%s /hwnd=%d", tmp, ServerHwnd);
	 }

	 WinExec(tmp2,1);
	 
}

HWND ReadReg(char* name){

	 char tmp[20] = {0};
     unsigned long l = sizeof(tmp);
	 HKEY h;
	 
	 RegOpenKeyEx(HKEY_CURRENT_USER, baseKey, 0, KEY_READ, &h);
	 RegQueryValueExA(h, name, 0,0, (unsigned char*)tmp, &l);
	 RegCloseKey(h);

	 return (HWND)atoi(tmp);
}



void SetReg(char* name, int value){

	 char tmp[20];

	 HKEY hKey;
	 LONG lRes = RegOpenKeyEx(HKEY_CURRENT_USER, baseKey, 0, KEY_ALL_ACCESS, &hKey);

	 if(lRes != ERROR_SUCCESS){
		lRes = RegCreateKeyEx(HKEY_CURRENT_USER, baseKey, 0, NULL, REG_OPTION_NON_VOLATILE, KEY_ALL_ACCESS, NULL, &hKey, NULL );
	    if(lRes != ERROR_SUCCESS) return;
	 }

	 qsnprintf(tmp,200,"%d",value);
	 RegSetValueEx(hKey, name,0, REG_SZ, (const unsigned char*)tmp , strlen(tmp)); 
	 RegCloseKey(hKey);

}

//Note that using HWND_BROADCAST as the target window will send the message to every window
bool SendTextMessage(char* name, char *Buffer, int blen) 
{
		  HWND h = ReadReg(name);
		  if(IsWindow(h) == 0){
			  if(m_debug) msg("Could not find valid hwnd for server %s\n", name);
			  return false;
		  }
		  return SendTextMessage((int)h,Buffer,blen);
}  

bool SendTextMessage(int hwnd, char *Buffer, int blen) 
{
		  char* nullString = "NULL";
		  if(blen==0){ //in case they are waiting on a message with data len..
				Buffer = nullString;
				blen=4;
		  }
		  if(m_debug) msg("Trying to send message to %x size:%d\n", hwnd, blen);
		  cpyData cpStructData;  
		  cpStructData.cbSize = blen ;
		  cpStructData.lpData = (int)Buffer;
		  cpStructData.dwFlag = 3;
		  SendMessage((HWND)hwnd, WM_COPYDATA, (WPARAM)hwnd,(LPARAM)&cpStructData);  
		  return true;
}  

bool SendIntMessage(char* name, int resp){
	char tmp[30]={0};
	sprintf(tmp, "%d", resp);
	if(m_debug) msg("SendIntMsg(%s, %s)", name, tmp);
	return SendTextMessage(name,tmp, strlen(tmp));
}

bool SendIntMessage(int hwnd, int resp){
	char tmp[30]={0};
	sprintf(tmp, "%d", resp);
	if(m_debug) msg("SendIntMsg(%d, %s)", hwnd, tmp);
	return SendTextMessage(hwnd,tmp, strlen(tmp));
}

int HandleQuickCall(unsigned int fIndex, unsigned int arg1){

	//msg("QuickCall( %d, 0x%x)\n" , fIndex, arg1);

	switch(fIndex){
		case 1: // jmp:lngAdr
				Jump( arg1 );
				return 0;

		case 7: // jmp_rva:lng_rva
				Jump( ImageBase()+arg1 );
				return 0;

		case 8: // imgbase 
				return ImageBase();
				 
		case 10: //readbyte:lngva 
				return get_byte(arg1);
				 
		case 11: //orgbyte:lngva 
				return get_original_byte(arg1);		 

		case 12: // refresh:
				Refresh();
				return 0;

		case 13: // numfuncs 
				return NumFuncs();		 

		case 14: //funcstart:funcIndex 
				 return FunctionStart( arg1 );
				 
		case 15: //funcend:funcIndex 
				 return FunctionEnd( arg1 );
				 
		case 20: //undefine:offset
				Undefine( arg1 );
				return 0;

		case 22: //hide:offset
				HideEA( arg1 );
				return 0;

		case 23: //show:offset
				ShowEA( arg1 );
				return 0;

		case 24: //remname:offset
				RemvName( arg1 );
				return 0;

		case 25: //makecode:offset
			    MakeCode( arg1 );
			    return 0;

		case 32: //funcindex:va 
				 return get_func_num( arg1 );
					
		case 33: //nextea:va  should this return null if it crosses function boundaries? yes probably...
				 return find_code( arg1 , SEARCH_DOWN | SEARCH_NEXT );
					
		case 34: //prevea:va  should this return null if it crosses function boundaries? yes probably...
				 return find_code( arg1 , SEARCH_UP | SEARCH_NEXT );

	    case 37: //screenea:
				 return ScreenEA();

		case 38: //debugmsgs: 1/0
				m_debug = arg1 == 1 ? true : false;
				return 0;

		case 39: //decompiler active
				return hasDecompiler;

		case 40: //Flush all cached decompilation results. 
			#ifdef HAS_DECOMPILER
				clear_cached_cfuncs();
				return 1;
			#endif
				return 0;

		case 41: //getIDAHwnd
				return (int)callui(ui_get_hwnd).vptr;

		case 42: //getVersion
				return InterfaceVersion;

		case 43:
				SetFocusSelectLine();
				return 0;
		case 44:
				return isCode(getFlags(arg1));
		case 45:
				return isData(getFlags(arg1));
		case 46:
				return decode_insn(arg1);
		case 47:
				return get_long(arg1);
		case 48:
				return get_word(arg1);

	}

	return -1; //not implemented

}

int HandleMsg(char* m){
	/*  for responses we whould pass in hwnd and not bother with having to do lookup...
		note all offsets/hwnds/indexes transfered as decimal
		11 of these now have the callback hwnd optional [:hwnd] because I realized I can just use the 
			SendMessage return value to return a int instead of an integer string data callback (duh!)
			the old style is still supported so I dont break any code.

			those marked with q are eligable for quickcall handling
				full  call ~ 20399 ticks    1
				new   call ~ 15993         4/5
				quick call ~  7322         1/3
			
		0 msg:message
	q	1 jmp:lngAdr
		2 jmp_name:function_name
		3 name_va:fx_name[:hwnd]          (returns va for fxname)
	    4 rename:oldname:newname[:hwnd]   (w/confirm: sends back 1 for success or 0 for fail)
	    5 loadedfile:hwnd
	    6 getasm:lngva:hwnd
	q   7 jmp_rva:lng_rva
	q  	8 imgbase[:hwnd]
		9 patchbyte:lng_va:byte_newval
	q  10 readbyte:lngva[:hwnd]
	q  11 orgbyte:lngva[:hwnd]
	q  12 refresh:
	q  13 numfuncs[:hwnd]
	q  14 funcstart:funcIndex[:hwnd]
	q  15 funcend:funcIndex[:hwnd]
	   16 funcname:funcIndex:hwnd
	   17 setname:va:name
	q  18 refsto:offset:hwnd          //multiple call backs to hwnd each int as string, still synchronous
	q  19 refsfrom:offset:hwnd        //multiple call backs to hwnd each int as string, still synchronous
	q  20 undefine:offset
	   21 getname:offset:hwnd
	q  22 hide:offset
	q  23 show:offset
	q  24 remname:offset
    q  25 makecode:offset
	   26 addcomment:offset:comment (non repeatable)
	   27 getcomment:offset:hwnd    (non repeatable)
	   28 addcodexref:offset:tova
	   29 adddataxref:offset:tova
	   30 delcodexref:offset:tova
	   31 deldataxref:offset:tova
	q  32 funcindex:va[:hwnd]
	q  33 nextea:va[:hwnd]
	q  34 prevea:va[:hwnd]
	   35 makestring:va:[ascii | unicode]
	   36 makeunk:va:size
	   37 screenea:
	   38 findcode:start:end:hexstr  //indexes no longer aligned with quick call..
	   39 decompile:va:fpath         //replace the c:\ with c_\ so we dont break tokenization..humm that sucks..
    */

	const int MAX_ARGS = 6;
	char *args[MAX_ARGS];
	char *token=0;
	char buf[500];
	char tmp[500];

	memset(buf, 0,500);
	memset(tmp, 0,500);
 
	//                0      1         2       3        4          5          6        7         8
	char *cmds[] = {"msg","jmp","jmp_name","name_va","rename","loadedfile","getasm","jmp_rva","imgbase",
	/*                9            10         11       12        13        14           15         16      */
		            "patchbyte","readbyte","orgbyte","refresh","numfuncs", "funcstart", "funcend","funcname",
	/*                17         18        19       20          21        22     23   24        25         */
					"setname","refsto","refsfrom","undefine","getname","hide","show","remname","makecode",
    /*               26            27           28             29           30             31              */
	                "addcomment","getcomment","addcodexref","adddataxref","delcodexref","deldataxref",
	/*               32          33         34        35           36        37           38         39    */
					"funcindex","nextea","prevea","makestring","makeunk", "screenea", "findcode", "decompile",
    /*               40 */
					"pycmd",
					"\x00"};
	int i=0;
	int argc=0;
	int x=0;
	int* zz = 0;

	//split command string into args array
	token = strtok(m,":");
	for(i=0;i<MAX_ARGS;i++){
		args[i] = token;
		token = strtok(NULL,":");
		if(!token) break;
	
	}

	argc=i;

	//get command index from cmds array
	for(i=0; ;i++){
		if( cmds[i][0] == 0){ i = -1; break;}
		if(strcmp(cmds[i],args[0])==0 ) break;
	}

	if(m_debug) msg("command handler: %d",i);

	//handle specific command
	switch(i){
		case -1: msg("IDASrv Unknown Command\n"); break; //unknown command
		
		case  0: //msg:UI_MESSAGE
				if( argc < 1 ){msg("jmp_name needs 1 args\n"); return -1;}
				msg(args[1]);					  
				break; 
		
		case  1: //jmp:lngAdr
				if( argc != 1 ){msg("jmp needs 1 args\n"); return -1;}
				Jump( atoi(args[1]) );		  
				break; 
		case  2: //jmp_name:fx_name
			     if( argc != 1 ){msg("jmp_name needs 1 args\n"); return -1;}
				 i = EaForFxName(args[1]);
				 if(i==0) break;
				 Jump(i);
				 break;

		case 3: //name_va:fx_name[:hwnd]  (returns va) hwnd optional - specify if want response as data callback default returns int 
			    if( argc < 1 ){msg("name_va needs 1 args\n"); return -1;}
				i =  EaForFxName(args[1]);
				if(argc == 2) SendIntMessage( atoi(args[2]), i);
				return i;
				break;
		
		case 4: //rename:oldname:newname[:hwnd]
				if( argc < 2 ){msg("rename needs 2 args\n"); return -1;}
				i = EaForFxName(args[1]);
				if(i==0){
					if(argc == 3) SendIntMessage( atoi(args[3]), 0); //fail
					return 0;
					break;
				}
				if( set_name(i,args[2]) ){
					if(argc == 3) SendIntMessage( atoi(args[3]), 1);
					return 1;
				}else{
					if(argc == 3) SendIntMessage( atoi(args[3]), 0);
					return 0;
				}
				break;

		case 5: //loadedfile:hwnd
			    if( argc != 1 ){msg("loadedfile needs 1 args\n"); return -1;}
				x = FilePath(buf, 499);
				SendTextMessage( atoi(args[1]), buf, strlen(buf) );
				break;

		case 6: //getasm:va:hwnd
			     if( argc != 2 ){msg("getasm needs 2 args\n"); return -1;}
				  x = GetAsm(atoi(args[1]),buf,499);
				  if(x==0) sprintf(buf,"Fail");
				  SendTextMessage(atoi(args[2]),buf,strlen(buf));
				  break;

		case 7: //jmp_rva:rva
				if( argc != 1 ){msg("jmp_rva needs 1 args\n"); return -1;}
				i = ImageBase();  
			    x = atoi(args[1]);
				if(x == 0 || x > i){ msg("Invalid rva to jmp_rva\n"); break;}
				Jump(i+x);
				break;

		case 8: //imgbase[:HWND]
				i = ImageBase();  
				if(argc == 1) SendIntMessage( atoi(args[1]), i );
				return i;
				break;

		case 9: //patchbyte:lng_va:byte_newval
			    if( argc != 2 ){msg("patchbyte needs 1 args\n"); return -1;}
				PatchByte( atoi(args[1]), atoi(args[2]) );
				break;

		case 10: //readbyte:lngva[:HWND]
			    if( argc < 1 ){msg("readbyte needs 1 args\n"); return -1;}
				GetBytes( atoi(args[1]), buf, 1); //on a patched byte this is reading a 4 byte int?
				if(argc == 2){
					sprintf( tmp, "%x", buf[0]);
					memset(&buf[1],0,4); 
					SendTextMessage( atoi(args[2]),tmp, strlen(tmp) );
				}
				zz = (int*)&buf;
				return *zz & 0x000000FF ;
				break;

		case 11: //orgbyte:lngva[:HWND]
			    if( argc < 1 ){msg("orgbyte needs 1 args\n"); return -1;}
				buf[0] = OriginalByte(atoi(args[1]));
				if(argc == 2){ 
					sprintf( tmp, "%x", buf[0]);
					SendTextMessage( atoi(args[2]),tmp, strlen(tmp) );
				}
				zz = (int*)&buf;
				return *zz & 0x000000FF;
				break;

		case 12: //refresh:
				 Refresh();
				 break;

		case 13: //numfuncs[:HWND]
				 i = NumFuncs();
				 if(argc == 1) SendIntMessage(atoi(args[1]), i);
				 return i;
				 break;

		case 14: //funcstart:funcIndex[:hwnd]
			     if( argc < 1 ){msg("funcstart needs 1 args\n"); return -1;}
				 x = FunctionStart(atoi(args[1]));
				 if(argc == 2) SendIntMessage(atoi(args[2]),x);
				 return x;
				 break;

		 case 15: //funcend:funcIndex[:hwnd]
			     if( argc < 1 ){msg("funcend needs 1 args\n"); return -1;}
				 x = FunctionEnd(atoi(args[1]));
				 if(argc == 2) SendIntMessage(atoi(args[2]),x);
				 return x;
				 break;

		 case 16: //funcname:funcIndex:hwnd
			     if( argc != 2 ){msg("funcname needs 2 args\n"); return -1;}
			     x = FunctionStart(atoi(args[1]));
				 FuncName(x,buf,499);
				 SendTextMessage(atoi(args[2]),buf,strlen(buf));
				 break;

		  case 17: //setname:va:name
			      if( argc != 2 ){msg("setname needs 2 args\n"); return -1;}
				  Setname( atoi(args[1]), args[2]);
				  break;

		  case 18: //refsto:offset:hwnd
			        if( argc != 2 ){msg("refsto needs 2 args\n"); return -1;}
					GetRefsTo( atoi(args[1]), atoi(args[2]) );
					break;
		  case 19: //refsfrom:offset:hwnd
			        if( argc != 2 ){msg("refsfrom needs 2 args\n"); return -1;}
					GetRefsFrom( atoi(args[1]), atoi(args[2]) );
					break;
		  case 20: //undefine:offset
			        if( argc != 1 ){msg("undefine needs 1 args\n"); return -1;}
					Undefine(atoi(args[1]));
					break;
		  case 21: //getname:offset:hwnd
				    if( argc != 2 ){msg("getname needs 2 args\n"); return -1;}
					GetName(atoi(args[1]), buf,499);
					SendTextMessage( atoi(args[2]), buf, strlen(buf));
					break;
		  case 22: //hide:offset
			        if( argc != 1 ){msg("hide needs 1 args\n"); return -1;}
					HideEA( atoi(args[1]) );
					break;
		  case 23: //show:offset
			        if( argc != 1 ){msg("show needs 1 args\n"); return -1;}
					ShowEA( atoi(args[1]) );
					break;
		  case 24: //remname:offset
			        if( argc != 1 ){msg("remname needs 1 args\n"); return -1;}
					RemvName(  atoi(args[1]) );
					break;
		  case 25: //makecode:offset
				   if( argc != 1 ){msg("makecode needs 1 args\n"); return -1;}
				   MakeCode( atoi(args[1]) );
				   break;
		  case 26: //addcomment:offset:comment
				   if( argc != 2 ){msg("addcomment needs 2 args\n"); return -1;}
				   SetComment( atoi(args[1]), args[2] );
				   break;
		  case 27: //getcomment:offset:hwnd
				   if( argc != 2 ){msg("getcomment needs 2 args\n"); return -1;}
				   GetComment( atoi(args[1]),buf, 499);
				   SendTextMessage( atoi(args[2]), buf, strlen(buf) );
				   break;
		  case 28: //addcodexref:offset:tova
				   AddCodeXRef( atoi(args[1]), atoi(args[2]) );
				   break;
		  case 29: //adddataxref:offset:tova
				   if( argc != 2 ){msg("adddataxref needs 2 args\n"); return -1;}
				   AddDataXRef( atoi(args[1]), atoi(args[2]) );
			       break;
		  case 30: //delcodexref:offset:tova
				   if( argc != 2 ){msg("delcodexref needs 2 args\n"); return -1;}
                   DelCodeXRef( atoi(args[1]), atoi(args[2]) );
				   break;
		  case 31: //deldataxref:offset:tova
				   if( argc != 2 ){msg("deldataxref needs 2 args\n"); return -1;}
				   DelDataXRef( atoi(args[1]), atoi(args[2]) );
				   break;
		  case 32: //funcindex:va[:hwnd]
					if( argc < 1 ){msg("funcindex needs 1 args\n"); return -1;}
					x = get_func_num( atoi(args[1]) );
					if( argc == 2 ) SendIntMessage( atoi(args[2]), x);
					return x;
					break;
		  case 33: //nextea:va[:hwnd]  should this return null if it crosses function boundaries? yes probably...
					if( argc < 1 ){msg("nextea needs 1 args\n"); return -1;}
					x = find_code( atoi(args[1]), SEARCH_DOWN | SEARCH_NEXT );
					if( argc == 2 )SendIntMessage( atoi(args[2]), x);
					return x;
					break;
		  case 34: //prevea:va[:hwnd]  should this return null if it crosses function boundaries? yes probably...
					if( argc < 1 ){msg("prevea needs 1 args\n"); return -1;}
					x = find_code( atoi(args[1]), SEARCH_UP | SEARCH_NEXT );
					if( argc == 2 ) SendIntMessage( atoi(args[2]), x);
					return x;
					break;
		  case 35: //makestring:va:[ascii | unicode]
					if( argc != 2 ){msg("makestring needs 2 args\n"); return -1;}
					x = strcmp(args[2],"ascii") == 0 ? ASCSTR_TERMCHR : ASCSTR_UNICODE ;
					make_ascii_string( atoi(args[1]), 0 /*auto*/, x);
					break;
		  case 36: //makeunk:va:size
					if( argc != 2 ){msg("makeunk needs 2 args\n"); return -1;}
					do_unknown_range( atoi(args[1]), atoi(args[2]), DOUNK_SIMPLE);
					break;

		  case 37: //screenea:
					return ScreenEA();

		  case 38: //findcode:start:end:hexstr
				    if( argc != 3 ){msg("findcode needs 3 args\n"); return -1;}
					return find_binary( atoi(args[1]), atoi(args[2]), args[3], 16, SEARCH_DOWN);

#ifdef HAS_DECOMPILER
		  case 39: //decompile:va:fpath
					if( argc != 2 ){msg("decompile needs 2 args\n"); return -1;}
					if( hasDecompiler == 0) {msg("HexRays Decompiler either not installed or version to old (this binary built against 6.7 SDK)\n"); return -1;}
					return DecompileFunction( atoi(args[1]), args[2]);
#endif

#ifdef PYTHON_TEST
		  case 40: //pycmd:hwnd:replace(cmd,":",chr(5))
			  if( argc != 2 ){msg("pycmd needs 2 args\n"); return -1;}
			  hPYClient = atoi(args[1]);                    //hwnd used in idasrvr.reply so we dont have to track in py
			  for(i=0;i<strlen(args[2]);i++){               //since we use : as a token transpose back..
				  if(args[2][i] == 5) args[2][i] = ':';     // use idasrvr.reply to ret vals to caller through ipc
			  }
			  PyGILState_STATE state = PyGILState_Ensure(); // Acquire the GIL
			  init_pyClient();                              // add our idasrvr extension to the pyEnv
			  PyRun_SimpleString(pyStub);
			  PyRun_SimpleString(args[2]);                  // execute the python code passed to us by remote client
			  PyGILState_Release(state);                    // Release the GIL
#endif

	}				

};



LRESULT CALLBACK WindowProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam){
		
		
		if( uMsg == IDA_QUICKCALL_MESSAGE )//uMsg apparently has to be a registered message to be received...
		{
			try{
				if(m_debug) msg("QuickCall Message Received(%d, %x)\n", (int)wParam, (int)lParam );
				return HandleQuickCall( (unsigned int)wParam, (unsigned int)lParam );
			}catch(...){ 
				msg("Error in HandleQuickCall(%d, %x)\n", (unsigned int)wParam, (unsigned int)lParam );
				return -1;
			}
		}
	
		if( uMsg == IDASRVR_BROADCAST_MESSAGE){ //so clients can sent a broadcast to all windows with wparam of their command hwnd
			if( IsWindow((HWND)wParam) ){       //we ping them back with with lParam = ServerHwnd to say were alive 
				SendMessage((HWND)wParam, IDASRVR_BROADCAST_MESSAGE, 0, (LPARAM)ServerHwnd);
			}
			return 0;
		}

		if( uMsg != WM_COPYDATA) return 0;
		if( lParam == 0) return 0;
		
		int retVal = 0;
		EnterCriticalSection(&m_cs);
		memcpy((void*)&CopyData, (void*)lParam, sizeof(cpyData));
    
		if( CopyData.dwFlag == 3 ){
			if( CopyData.cbSize >= sizeof(m_msg) - 2 ) CopyData.cbSize = sizeof(m_msg) - 2;
 
			memcpy((void*)&m_msg[0], (void*)CopyData.lpData, CopyData.cbSize);
			m_msg[CopyData.cbSize] = 0; //always null terminate..

			if(m_debug)	msg("Message Received: %s \n", m_msg); 

			try{
				retVal = HandleMsg(m_msg); 				    
			}catch(...){ //remember this doesnt help any if we did anything that led to memory corruption...
				msg("Caught an Error in HandleMsg!");
				if(!m_debug) msg("Message: %s \n", m_msg); 
			}
		}
			
		 
	
	LeaveCriticalSection(&m_cs);
    return retVal;
}

/*
void DoEvents() 
{ 
    MSG msg; 
    while (PeekMessage(&msg,0,0,0,PM_NOREMOVE)) { 
        TranslateMessage(&msg); 
        DispatchMessage(&msg); 
    } 

} 
*/

int idaapi init(void) 
{
  //immediatly create server window for use (no need to explicitly launch plugin)  
  ServerHwnd = CreateWindow("EDIT","MESSAGE_WINDOW", 0, 0, 0, 0, 0, 0, 0, 0, 0);
  oldProc = (WNDPROC)SetWindowLong(ServerHwnd, GWL_WNDPROC, (LONG)WindowProc);
  SetReg(IPC_NAME, (int)ServerHwnd);
  IDASRVR_BROADCAST_MESSAGE = RegisterWindowMessage(IPC_NAME);
  IDA_QUICKCALL_MESSAGE = RegisterWindowMessage("IDA_QUICKCALL");
  InitializeCriticalSection(&m_cs);
  msg("idasrvr: initializing...\n");

	#ifdef HAS_DECOMPILER
	  if( init_hexrays_plugin(0) ){
		  hasDecompiler = 1;
		  msg("IDASrvr: detected hexrays decompiler version %s\n", get_hexrays_version() );
	  }else{
		  msg("idasrvr: init_hexrays_plugin failed...\n");
	  }
	#endif

  return PLUGIN_KEEP; //keeps it loaded into mem always..(for server to always be running)
}

void idaapi term(void)
{
	try{	
		#ifdef HAS_DECOMPILER 
			if ( hasDecompiler ) term_hexrays_plugin();
		#endif
		SetWindowLong(ServerHwnd, GWL_WNDPROC, (LONG)oldProc);
		DestroyWindow(ServerHwnd);
		HWND saved_hwnd = ReadReg("IDA_SERVER");
		if( !IsWindow(saved_hwnd) ) SetReg("IDA_SERVER", 0); 
	}
	catch(...){};

}

void idaapi run(int arg)
{
 
  Launch_IdaJscript();

}



char comment[] = "";
char help[] ="";
char wanted_name[] = "IDA JScript";
char wanted_hotkey[] = "Alt-0";

//Plugin Descriptor Block
plugin_t PLUGIN =
{
  IDP_INTERFACE_VERSION,
  0,                    // plugin flags
  init,                 // initialize
  term,                 // terminate. this pointer may be NULL.
  run,                  // invoke plugin
  comment,              // long comment about the plugin (status line or hint)
  help,                 // multiline help about the plugin
  wanted_name,          // the preferred short name of the plugin
  wanted_hotkey         // the preferred hotkey to run the plugin
};



 


//Export API for the VB app to call and access IDA API data
//_________________________________________________________________

void __stdcall SetFocusSelectLine(void){ 
	HWND ida = (HWND)callui(ui_get_hwnd).vptr;
	SetForegroundWindow(ida);	//make ida window active and send HOME+ SHIFT+END keys to select the current line
	keybd_event(VK_HOME,0x4F,KEYEVENTF_EXTENDEDKEY | 0,0);
	keybd_event(VK_HOME,0x4F,KEYEVENTF_EXTENDEDKEY | KEYEVENTF_KEYUP,0);
	keybd_event(VK_SHIFT,0x2A,0,0);
	keybd_event(VK_END,0x4F,KEYEVENTF_EXTENDEDKEY | 0,0);
	keybd_event(VK_END,0x4F,KEYEVENTF_EXTENDEDKEY | KEYEVENTF_KEYUP,0);
	keybd_event(VK_SHIFT,0x2A,KEYEVENTF_KEYUP,0); 
}

void __stdcall Jump(int addr)  { jumpto(addr);}
void __stdcall Refresh   (void)      { refresh_idaview();      }
int  __stdcall ScreenEA  (void)      { return get_screen_ea(); }
int  __stdcall NumFuncs  (void)      { return get_func_qty();  }
void __stdcall RemvName  (int addr)  { del_global_name(addr);  }
void __stdcall Setname(int addr, const char* name){ set_name(addr, name); }
//void __stdcall AddComment(char *cmt, char color){ generate_big_comment(cmt, color);}
void __stdcall AddProgramComment(char *cmt){ add_pgm_cmt(cmt); }
void __stdcall AddCodeXRef(int start, int end){ add_cref(start, end, cref_t(fl_F | XREF_USER) );}
void __stdcall DelCodeXRef(int start, int end){ del_cref(start, end, 1 );}
void __stdcall AddDataXRef(int start, int end){ add_dref(start, end, dref_t(dr_O | XREF_USER) );}
void __stdcall DelDataXRef(int start, int end){ del_dref(start, end );}
void __stdcall MessageUI(char *m){ msg(m);}
void __stdcall PatchByte(int addr, char val){ patch_byte(addr, val); }
void __stdcall PatchWord(int addr, int val){  patch_word(addr, val); }
void __stdcall DelFunc(int addr){ del_func(addr); }
int  __stdcall FuncIndex(int addr){ return get_func_num(addr); }
void __stdcall SelBounds( ulong* selStart, ulong* selEnd){ read_selection(selStart, selEnd);}
void __stdcall FuncName(int addr, char *buf, size_t bufsize){ get_func_name(addr, buf, bufsize);}
int  __stdcall GetBytes(int offset, void *buf, int length){ return get_many_bytes(offset, buf, length);}
void __stdcall Undefine(int offset){ autoMark(offset, AU_UNK); }
char __stdcall OriginalByte(int offset){ return get_original_byte(offset); }

void __stdcall SetComment(int offset, char* comm){set_cmt(offset,comm,false);}

void __stdcall GetComment(int offset, char* buf, int bufSize){ 
	int retlen = get_cmt(offset,false,buf,bufSize); 
}

int __stdcall ProcessState(void){ return get_process_state(); }

int __stdcall FilePath(char *buf, int bufsize){ 
	int retlen=0;
	char *str;

	retlen = get_input_file_path(buf,bufsize);
	return retlen;
}

int __stdcall RootFileName(char *buf, int bufsize){ 
	int retlen=0;
	char *str;

	retlen = get_root_filename(buf,bufsize);
	return retlen;
}

void __stdcall HideEA(int offset){	set_visible_item(offset, false); }
void __stdcall ShowEA(int offset){	set_visible_item(offset, true); }

/*
int __stdcall NextAddr(int offset){
   areacb_t a;
   return a.get_next_area(offset);
}

int __stdcall PrevAddr(int offset){
	areacb_t a;
    return a.get_prev_area(offset); 
}
*/


//not working?
void __stdcall AnalyzeArea(int startat, int endat){ /*analyse_area(startat, endat);*/}


//now works to get local labels
void __stdcall GetName(int offset, char* buf, int bufsize){

	get_true_name( BADADDR, offset, buf, bufsize );

	if(strlen(buf) == 0){
		func_t* f = get_func(offset);
		for(int i=0; i < f->llabelqty; i++){
			if( f->llabels[i].ea == offset ){
				int sz = strlen(f->llabels[i].name);
				if(sz < bufsize) strcpy(buf,f->llabels[i].name);
				return;
			}
		}
	}

}

//not workign to make code and analyze
void __stdcall MakeCode(int offset){
	 autoMark(offset, AU_CODE);
	 /*analyse_area(offset, (offset+1) );*/
}


int __stdcall FunctionStart(int n){
	if(n < 0 || n >  NumFuncs()){
		if(debug) msg("Invalid function index specified!");
		return -1;
	}
	func_t *clsFx = getn_func(n);
	return clsFx->startEA;
}

int __stdcall FunctionEnd(int n){
	if(n < 0 || n >  NumFuncs()){
		if(debug) msg("Invalid function index specified!");
		return -1;
	}
	func_t *clsFx = getn_func(n);
	return clsFx->endEA;
}

int __stdcall FuncArgSize(int index){
		if(index < 0 || index >  NumFuncs()){
			if(debug) msg("Invalid function index specified!");
			return -1;
		}
		func_t *clsFx = getn_func(index);
		return clsFx->argsize ;
}

int __stdcall FuncColor(int index){
		if(index < 0 || index >  NumFuncs()){
			if(debug) msg("Invalid function index specified!");
			return -1;
		}
		func_t *clsFx = getn_func(index);
		return clsFx->color  ;
}

int __stdcall GetAsm(int addr, char* buf, int bufLen){

    flags_t flags;                                                       
    int sLen=0;

    flags = getFlags(addr);                        
    if(isCode(flags)) {                            
        generate_disasm_line(addr, buf, bufLen, GENDSM_MULTI_LINE );
        sLen = tag_remove(buf, buf, bufLen);  
    }

	return sLen;

}

int __stdcall FirstCodeFrom(int ea){

	xb.first_from(ea, XREF_ALL);
	return xb.iscode ==1 ? xb.to : 0 ;

}

int __stdcall FirstCodeTo(int ea){

	xb.first_to(ea, XREF_ALL);
	return xb.iscode ==1 ? xb.from : 0;

}

int __stdcall NextCodeTo(int ea){

	xb.next_to();
	return xb.iscode ==1 ? xb.from : 0;

}

int __stdcall NextCodeFrom(int ea){

	xb.next_from();
	return xb.iscode ==1 ? xb.to : 0;

}

int __stdcall ImageBase(void){

  netnode penode("$ PE header");
  ea_t loaded_base = penode.altval(-2);
  return loaded_base;

}

//idaman ea_t ida_export find_text(ea_t startEA, int y, int x, const char *ustr, int sflag);
//#define SEARCH_UP       0x000		// only one of SEARCH_UP or SEARCH_DOWN can be specified
//#define SEARCH_DOWN     0x001
//#define SEARCH_NEXT     0x002
/*
int __stdcall SearchText(int addr, char* buf, int search_type,int debug){

	char msg[500]={0};
	int y=0,x=0;
	int ret = find_text(addr,y,x,buf, search_type);
	
	if(debug==1){
		qsnprintf(msg,499,"ret=%x addr=%x search_type=%x",ret,addr,search_type);
		MessageBox(0,msg,"",0);
	}

	return ret;

}
*/

int __stdcall GetRefsTo(int offset, int hwnd){

	int count=0;
	int retVal=0;

	xrefblk_t xb;
    for ( bool ok=xb.first_to(offset, XREF_ALL); ok; ok=xb.next_to() ){
		SendIntMessage(hwnd,xb.from);
		SendTextMessage(hwnd,",",2);
    }
	SendTextMessage(hwnd,"DONE",5);
	
	return count;

}


int __stdcall GetRefsFrom(int offset, int hwnd){

	//this also returns jmp type xrefs not just call
	//there is always one back reference from next instruction 

	int count=0;
	int retVal=0;

	xrefblk_t xb;
    for ( bool ok=xb.first_from(offset, XREF_ALL); ok; ok=xb.next_from() ){
		SendIntMessage(hwnd,xb.to);
		SendTextMessage(hwnd,",",2);	
    }
	SendTextMessage(hwnd,"DONE",5);
	return count;

}

int __stdcall DecompileFunction(int offset, char* fpath)
{
#ifdef HAS_DECOMPILER
			
	 
		if(fpath==NULL) return 0;
		if(strlen(fpath)==0) return 0;
	
		func_t *pfn = get_func(offset);
		if ( pfn == NULL )
		{
			warning("Please position the cursor within a function");
			return 0;
		}

		hexrays_failure_t hf;
		cfuncptr_t cfunc = decompile(pfn, &hf);
		if ( cfunc == NULL )
		{
			warning("#error \"%a: %s", hf.errea, hf.desc().c_str());
			return 0;
		}

		if( fpath[1] == '_' ) fpath[1] = ':'; //fix cheesy workaround to tokinizer reserved char..

		FILE* f = fopen(fpath, "w");
		if(f==NULL)
		{
			warning("Error could not open %s", fpath);
			return 0;
		}
		
		/*if(debug)*/ msg("%a: successfully decompiled\n", pfn->startEA);

		const strvec_t &sv = cfunc->get_pseudocode(); //not available in 6.2 known ok in 6.5..
		for ( int i=0; i < sv.size(); i++ )
		{
			char buf[MAXSTR];
			tag_remove(sv[i].line.c_str(), buf, MAXSTR);
			fprintf(f,"%s\n", buf);
		}
		fclose(f);
		return 1;
#else
		return -1;
#endif
	}

