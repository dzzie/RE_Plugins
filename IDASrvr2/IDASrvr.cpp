

/*

Status: in progress so far c and vb6 clients are tested with plw/p64

IDASRVR2: move to support x64 addresses everywhere, even between 32bit and 64 bit clients...

Soo..since I have to work between a 32bit client and 64bit server now..I cant pass offset args
via SendMessage because a 32bit sendMessage is limited...I guess all offsets now have to be passed
in an alternative manner..probably memory mapped files..
in an alternative manner..probably memory mapped files..

NOTE: to build this project it is assumed you have an envirnoment variable 
named IDASDK set to point to the base SDK directory. this env var is used in
the C/C++ property tab, Preprocessor catagory, Additional include directoriestodo
texbox so that this project can be built without having to be in a specific path
Also used in the Linker - additional include directories.

Note: this includes a decompile function that requires the hexrays decompiler. If you
	  dont have it, you can just comment out the few lines that reference it. 
*/

bool m_debug = true;  
#define USE_STANDARD_FILE_FUNCTIONS

#define HAS_DECOMPILER //if you dont have the hexrays decompiler comment this line out..
#define __EA64__  //create the plugin for the 64 bit databases

#ifndef _WIN64
	#error "You can only compile this as an x64 binary, 32/64 bit mode is set with __EA64__ define above"
#endif

#ifdef __EA64__
	#ifndef  _DEBUG
		#error "For some reason the x64 version requires debug builds only right now or IDA crash on init...yay plugins.."
	#endif
	#pragma comment(linker, "/out:./bin/IDASrvr2_64.dll")
	#pragma comment(lib, "D:\\idasdk75\\lib\\x64_win_vc_64\\ida.lib")
#else
	#pragma comment(linker, "/out:./bin/IDASrvr2.dll")
	#pragma comment(lib, "D:\\idasdk75\\lib\\x64_win_vc_32\\ida.lib")
#endif

#pragma warning(disable:4996) //may be unsafe function
#pragma warning(disable:4244) //conversion from '__int64' to 'ea_t', possible loss of data


#include <windows.h>  //define this before other headers or get errors 
#include <stdlib.h>
#include <string.h>

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
#include <stdio.h>
#include <search.hpp>
#include <xref.hpp>
#include <enum.hpp>

#ifdef HAS_DECOMPILER
	#include <hexrays.hpp>    
	hexdsp_t *hexdsp = NULL;  
	int __stdcall DecompileFunction(__int64 offset, char* fpath);
#endif

int hasDecompiler = 0;
int InterfaceVersion = 2;

#undef sprintf
#undef strcpy
#undef strtok
#undef fopen
#undef fprintf
#undef fclose

#include "IDASrvr.h"

xrefblk_t xb;


typedef struct{
    int dwFlag;
    int cbSize;
    int lpData;
} cpyData32;

typedef struct {
	ULONG_PTR dwFlag; // dwData;
	DWORD     cbSize; // cbData;
	PVOID     lpData;
} cpyData;

char baseKey[200] = "Software\\VB and VBA Program Settings\\IPC\\Handles";
char *IPC_NAME = "IDA_SERVER2";
HWND ServerHwnd=0;
WNDPROC oldProc=0;
char m_msg[2020];
cpyData CopyData;
CRITICAL_SECTION m_cs;
UINT IDASRVR_BROADCAST_MESSAGE=0;
UINT IDA_QUICKCALL_MESSAGE = 0;

__int64 __stdcall ImageBase(void);
int __stdcall DumpFunction(int funcIndex, int flags, char* outFilePath);
int __stdcall DumpFunctionBytes(int funcIndex, char* outFilePath);
int __stdcall GetImm(__int64 ea, int hwnd); //not returning anything?
int __stdcall get_operand_value(__int64 va, int n, int hwnd);

//void __stdcall SetFocusSelectLine(void);




int EaForFxName(char* fxName){
	
	func_t *fx;
	int x = get_func_qty();
	qstring q;

	for(int i=0;i<x;i++){
		fx = getn_func(i);
		if(fx != nullptr && get_func_name(&q, fx->start_ea) > 0){
			//if(m_debug) msg("on index %d name=%s\n", i, buf);
			if(q == fxName){
				if(m_debug) msg("Found ea for name %s=%x\n", fxName, fx->start_ea );
				return fx->start_ea;
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


int FileSize(char* path)
{
    HANDLE hFile = CreateFile(path, GENERIC_READ, 0, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
	if (hFile == INVALID_HANDLE_VALUE) return 0;
	DWORD dwFileSize = GetFileSize(hFile, NULL);
	CloseHandle(hFile);
	return dwFileSize;
}

/*
int file_length(FILE* f)
{
	int pos;
	int end;

	pos = ftell(f);
	fseek(f, 0, SEEK_END);
	end = ftell(f);
	fseek(f, pos, SEEK_SET);

	return end;
}*/

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

bool SendTextMessage(int hwnd, char* Buffer, int blen)
{
	char* nullString = "NULL";
	if (blen == 0 || Buffer == NULL) { //in case they are waiting on a message with data len..
				Buffer = nullString;
				blen=4;
		  }
		  if(m_debug) msg("Trying to send message to %x size:%d\n", hwnd, blen);
		  cpyData cpStructData;  
		  cpStructData.cbSize = blen ;
		  cpStructData.lpData = (PVOID)Buffer;
		  cpStructData.dwFlag = 3;
		  SendMessage((HWND)hwnd, WM_COPYDATA, (WPARAM)hwnd,(LPARAM)&cpStructData);  
		  return true;
}  

bool SendIntMessage(char* name, __int64 resp){
	char tmp[100]={0};
	sprintf(tmp, "%llu", resp);
	if(m_debug) msg("SendIntMsg(%s, %s)", name, tmp);
	return SendTextMessage(name,tmp, strlen(tmp));
}

bool SendIntMessage(int hwnd, __int64 resp){
	char tmp[100]={0};
	sprintf(tmp, "%llu", resp);
	if(m_debug) msg("SendIntMsg(%d, %s)", hwnd, tmp);
	return SendTextMessage(hwnd,tmp, strlen(tmp));
}

//__atoi64 does not support 0x prefix
bool get64(char* str, unsigned __int64* outval)
{
	char* end;

	if (str == NULL) {
		outval = 0;
		return false;
	}

	*outval = strtoull(str, &end, 0); //base determined by string (supports 0x prefix)
	if (*outval == 0 && end == str) {
		return false; // str was not a number 
	}
	else if (*outval == ULLONG_MAX) {
		return false; // the value of str does not fit in int64
	}
	//else if (*end) { //junk left over at the end dont care
	return true;
}

int HandleQuickCall(unsigned __int64 fIndex, unsigned __int64 arg1){

	//msg("QuickCall( %d, 0x%x)\n" , fIndex, arg1);
	insn_t ins;

	switch(fIndex){

		/*-------------------------------------------------------------------------------------
		this next block of indented functions should work for x64 disassemblies
		IF called from an 64bit client. 32bit clients accessing 64 disasm should not use
		these quick call functions and use the regular string based versions instead.
	     -------------------------------------------------------------------------------------*/
	//#ifndef __EA64__

			case 1: // jmp:lngAdr
					Jump( arg1 );
					return 0;

			case 8: // imgbase
					return ImageBase();

			case 10: //readbyte:lngva
					return get_byte(arg1);

			case 11: //orgbyte:lngva
					return get_original_byte(arg1);

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

			case 44:
					return is_code(get_flags(arg1));
			case 45:
					return is_data(get_flags(arg1));
			case 46:
					decode_insn(&ins, arg1);
					return ins.size;
			case 47:
					return get_32bit(arg1);  //todo: IDA 7 this is now 32bit specific..add an x64?
			case 48:
					return get_16bit(arg1);

	//#endif  


		/*----------------------------------------------------------------------------
		    quick calls below here are safe for both 32bit and 64bit clients always...
		  ----------------------------------------------------------------------------*/
		case 7: // jmp_rva:lng_rva
				Jump( ImageBase()+arg1 );
				return 0;

		case 12: // refresh:
				Refresh();
				return 0;

		case 13: // numfuncs 
				return NumFuncs();		 

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

		//case 41: //getIDAHwnd  todo: IDA 7?
				//return (int)callui(ui_notification_t::ui_get_hwnd).vptr;

		case 42: //getVersion
				return InterfaceVersion;

		/*case 43:
				SetFocusSelectLine();
				return 0;*/

		case 49: //isX64 disasm
				#ifndef __EA64__
					return 0;
				#else
					return 1;
				#endif

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
			
		Change note: all of these now support 64 bit addresses by switching to _atoi64, 32bit safe still...
        q marks quick call, * = 32bit disasm only

		0 msg:message
	q	1 jmp:lngAdr  
		2 jmp_name:function_name
		3 name_va:fx_name[:hwnd]          (returns va for fxname) - hwnd no longer optional...
	    4 rename:oldname:newname[:hwnd]   (w/confirm: sends back 1 for success or 0 for fail)
	    5 loadedfile:hwnd
	    6 getasm:lngva:hwnd
	q   7 jmp_rva:lng_rva
	q* 	8 imgbase[:hwnd]                  hwnd required for x64..
		9 patchbyte:lng_va:byte_newval
	q* 10 readbyte:lngva[:hwnd]
	q* 11 orgbyte:lngva[:hwnd]
	q  12 refresh:
	q  13 numfuncs[:hwnd]
	q* 14 funcstart:funcIndex[:hwnd]     hwnd required for x64..
	q* 15 funcend:funcIndex[:hwnd]       hwnd required for x64..
	   16 funcname:funcIndex:hwnd  
	   17 setname:va:name
	q  18 refsto:offset:hwnd          //multiple call backs to hwnd each int as string, still synchronous  
	q  19 refsfrom:offset:hwnd        //multiple call backs to hwnd each int as string, still synchronous  
	q* 20 undefine:offset
	   21 getname:offset:hwnd
	q* 22 hide:offset
	q* 23 show:offset
	q* 24 remname:offset
    q* 25 makecode:offset
	   26 addcomment:offset:comment (non repeatable)
	   27 getcomment:offset:hwnd    (non repeatable) 
	   28 addcodexref:offset:tova 
	   29 adddataxref:offset:tova 
	   30 delcodexref:offset:tova 
	   31 deldataxref:offset:tova 
	q  32 funcindex:va[:hwnd] 
	q* 33 nextea:va[:hwnd]  - hwnd required for x64..
	q* 34 prevea:va[:hwnd]  - hwnd required for x64..
	   35 makestring:va:[ascii | unicode] 
	   36 makeunk:va:size 
	q* 37 screenea:[:hwnd]  - hwnd required for x64..
	   38 findcode:start:end:hexstr  //indexes no longer aligned with quick call.. 
	   39 decompile:va:fpath         //replace the c:\ with c_\ so we dont break tokenization..humm that sucks.. 
	   44 iscode:va
	   45 isdata:va
	   46 decodeins:va (instr length)
	   47 getlong:va
	   48 getword:va
	   50 getx64:va:hwnd
	   51 dumpfunc:va:flags:fpath
	   52 dumpfuncbytes:va:fpath
	   53 immvals:va:hwnd  //not working ?
	   54 getopv:va:n:hwnd
	   55 addenum:name
	   56 addenummem:enumid:value:name
	   57 getenum:name
	   58 addseg:base:size:name
	   59 segExists:nameOrBase
	   60 delSeg:nameOrBase
	   61 getsegs:hwnd
	   62 funcmap:path  since a full dump of all functions probably has 1-10k+ entries just dump to tmp file 
	   63 importpatch:path:va

	   todo: not implemented in regular call yet...(40-43 are quick call usable even for x64)
	     case 49: //isX64 disasm

		 x = '[{"name":"a","base":"0x1"},{"name":"b","base":"0x2"}]' // 0x must be a string? direct hex num not supported...x64 would require string anyway...
		 x = JSON.parse(x)
		 alert(x[0].name)

    */

	const int MAX_ARGS = 6;
	char *args[MAX_ARGS];
	char *token=0;
	char buf[500];
	char tmp[500];
	insn_t ins;
	qstring q;
	qstring s;

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
    /*               40           41        42        43        44        45        46         47        48 */
					"qc_only","qc_only","qc_only","qc_only", "iscode", "isdata", "decodeins","getlong","getword",
    /*               49           50        51          52        53        54        55         56        57 */
		             "isx64","getx64","dumpfunc","dumpfuncbytes", "immvals","getopv", "addenum", "addenummem", "getenum",
	/*               58           59        60          61        62        63        64         65        66 */
		             "addseg","segexists", "delseg","getsegs","funcmap","importpatch",
					"\x00"};
	FILE* fp = 0;
	qstring name;
	unsigned __int64 i=0;
	unsigned __int64 x=0;
	int argc=0;
	int* zz = 0; //used only for returning 8 bit values with mask always 32bit safe and used as return value...

	if (m == 0) {
		msg("HandleMsg had null arg");
		return 0;
	}

	/*MessageBox(0, m, "Message", 0);
	msg("HandleMsg len: %d", strlen(m));
	//return 0;*/

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

	unsigned __int64 ua1 = 0; bool b1 = false;
	unsigned __int64 ua2 = 0; bool b2 = false;

	if (argc >= 1) if(get64(args[1], &ua1)) b1 = true;
	if (argc >= 2) if(get64(args[2], &ua2)) b2 = true;


	//if(m_debug) msg("command handler: %d",i);
	//MessageBox(0, "", "", 0);

	//handle specific command
	switch(i){
		default: msg("IDASrv Unknown Command\n"); break; //unknown command
		
		case  0: //msg:UI_MESSAGE
				if( argc < 1 ){msg("msg needs 1 args\n"); return -1;}
				msg(args[1]);					  
				break; 
		
		case  1: //jmp:lngAdr
				if( argc != 1 ){msg("jmp needs 1 args\n"); return -1;}
				Jump(ua1);
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
				 x = GetAsm(ua1, buf, 499);
				 if (x == 0) sprintf(buf, "Fail");
				 SendTextMessage(atoi(args[2]), buf, strlen(buf)); 
				 break;

		case 7: //jmp_rva:rva
				if( argc != 1 ){msg("jmp_rva needs 1 args\n"); return -1;}
				i = ImageBase();  
			    //x = _atoi64(args[1]);
				if (ua1 == 0 || ua1 > i) { msg("Invalid rva to jmp_rva\n"); break; }
				Jump(i + ua1);
				break;

		case 8: //imgbase[:HWND]
				i = ImageBase();  
				if(argc == 1) SendIntMessage( atoi(args[1]), i );
				return i;
				break;

		case 9: //patchbyte:lng_va:byte_newval
			    if( argc != 2 ){msg("patchbyte needs 1 args\n"); return -1;}
				PatchByte(ua1, atoi(args[2]));
				break;

		case 10: //readbyte:lngva[:HWND]
			    if( argc < 1 ){msg("readbyte needs 1 args\n"); return -1;}
				GetBytes(ua1, buf, 1); //on a patched byte this is reading a 4 byte int?
				if (argc == 2) {
					sprintf(tmp, "%x", buf[0]);
					memset(&buf[1], 0, 4);
					SendTextMessage(atoi(args[2]), tmp, strlen(tmp));
				}
				zz = (int*)&buf;
				return *zz & 0x000000FF;
				break;

		case 11: //orgbyte:lngva[:HWND]
			    if( argc < 1 ){msg("orgbyte needs 1 args\n"); return -1;}
				buf[0] = OriginalByte(ua1);
				if (argc == 2) {
					sprintf(tmp, "%x", buf[0]);
					SendTextMessage(atoi(args[2]), tmp, strlen(tmp));
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

		case 14: //funcstart:funcIndex:[hwnd] - x64 requires hwnd, legacy 32bit code still ok
			     if( argc < 1 ){msg("funcstart needs 1 args\n"); return -1;}
				 x = FunctionStart(ua1);
				 if(argc == 2) SendIntMessage(atoi(args[2]),x);
				 return x;
				 break;

		 case 15: //funcend:funcIndex[:hwnd]  - x64 requires hwnd, legacy 32bit code still ok
			     if( argc < 1 ){msg("funcend needs 1 args\n"); return -1;}
				 i = atoi(args[1]);
				 if(i < 0) return -1;
				 x = FunctionEnd(i);
				 if(argc == 2) SendIntMessage(atoi(args[2]),x);
				 return x;
				 break;

		 case 16: //funcname:funcIndex:hwnd
			     if( argc != 2 ){msg("funcname needs 2 args\n"); return -1;}
				 i = atoi(args[1]);
				 if(i < 0) return -1;
			     x = FunctionStart(i);
				 FuncName(x,buf,499);
				 SendTextMessage(atoi(args[2]),buf,strlen(buf));
				 break;

		  case 17: //setname:va:name
			      if( argc != 2 ){msg("setname needs 2 args\n"); return -1;}
				  Setname(ua1, args[2]);
				  break;

		  case 18: //refsto:offset:hwnd
			        if( argc != 2 ){msg("refsto needs 2 args\n"); return -1;}
					GetRefsTo(ua1, atoi(args[2]));
					break;
		  case 19: //refsfrom:offset:hwnd
			        if( argc != 2 ){msg("refsfrom needs 2 args\n"); return -1;}
					GetRefsFrom(ua1, atoi(args[2]));
					break;
		  case 20: //undefine:offset
			        if( argc != 1 ){msg("undefine needs 1 args\n"); return -1;}
					Undefine(ua1);
					break;
		  case 21: //getname:offset:hwnd
				    if( argc != 2 ){msg("getname needs 2 args\n"); return -1;}
					GetName(ua1, buf, 499);
					SendTextMessage(atoi(args[2]), buf, strlen(buf));
					break;
		  case 22: //hide:offset
			        if( argc != 1 ){msg("hide needs 1 args\n"); return -1;}
					HideEA(ua1);
					break;
		  case 23: //show:offset
			        if( argc != 1 ){msg("show needs 1 args\n"); return -1;}
					ShowEA(ua1);
					break;
		  case 24: //remname:offset
			        if( argc != 1 ){msg("remname needs 1 args\n"); return -1;}
					RemvName(ua1);
					break;
		  case 25: //makecode:offset
				   if( argc != 1 ){msg("makecode needs 1 args\n"); return -1;}
				   MakeCode(ua1);
				   break;
		  case 26: //addcomment:offset:comment
				   if( argc != 2 ){msg("addcomment needs 2 args\n"); return -1;}
				   SetComment(ua1, args[2]);
				   break;
		  case 27: //getcomment:offset:hwnd
				   if( argc != 2 ){msg("getcomment needs 2 args\n"); return -1;}
				   GetComment(ua1, buf, 499);
				   SendTextMessage(atoi(args[2]), buf, strlen(buf));
				   break;
		  case 28: //addcodexref:offset:tova
				   AddCodeXRef(ua1, ua2);
				   break;
		  case 29: //adddataxref:offset:tova
				   if( argc != 2 ){msg("adddataxref needs 2 args\n"); return -1;}
				   AddDataXRef(ua1, ua2);
			       break;
		  case 30: //delcodexref:offset:tova
				   if( argc != 2 ){msg("delcodexref needs 2 args\n"); return -1;}
				   DelCodeXRef(ua1,ua2);
				   break;
		  case 31: //deldataxref:offset:tova
				   if( argc != 2 ){msg("deldataxref needs 2 args\n"); return -1;}
				   DelDataXRef(ua1,ua2);
				   break;
		  case 32: //funcindex:va[:hwnd]
					if( argc < 1 ){msg("funcindex needs 1 args\n"); return -1;}
					x = get_func_num(ua1);
					if( argc == 2 ) SendIntMessage( atoi(args[2]), x);
					return x;
					break;
		  case 33: //nextea:va[:hwnd]  should this return null if it crosses function boundaries? yes probably...   - x64 requires hwnd, legacy 32bit code still ok
					if( argc < 1 ){msg("nextea needs 1 args\n"); return -1;}
					x = find_code(ua1, SEARCH_DOWN | SEARCH_NEXT );
					if( argc == 2 ) SendIntMessage( atoi(args[2]), x);
					return x;
					break;
		  case 34: //prevea:va[:hwnd]  should this return null if it crosses function boundaries? yes probably...  - x64 requires hwnd, legacy 32bit code still ok
					if( argc < 1 ){msg("prevea needs 1 args\n"); return -1;}
					x = find_code(ua1, SEARCH_UP | SEARCH_NEXT );
					if( argc == 2 ) SendIntMessage( atoi(args[2]), x);
					return x;
					break;
		  case 35: //makestring:va:[ascii | unicode]
					if( argc != 2 ){msg("makestring needs 2 args\n"); return -1;}
					x = strcmp(args[2],"ascii") == 0 ? STRTYPE_TERMCHR : STRTYPE_C;
					create_strlit(ua1, 0 /*auto*/, x);
					break;
		  case 36: //makeunk:va:size
					if( argc != 2 ){msg("makeunk needs 2 args\n"); return -1;}
					//do_unknown_range( _atoi64(args[1]), _atoi64(args[2]), DOUNK_SIMPLE);
					del_items(ua1, DELIT_SIMPLE, ua2);
					break;

		  case 37: //screenea:[hwnd] - x64 must supply hwnd..
					i = ScreenEA();
					if(argc == 1) SendIntMessage( atoi(args[1]), i );
					return i;

		  case 38: //findcode:start:end:hexstr
				    if( argc != 3 ){msg("findcode needs 3 args\n"); return -1;}
					return find_binary(ua1, ua2, args[3], 16, SEARCH_DOWN);

#ifdef HAS_DECOMPILER
		  case 39: //decompile:va:fpath
					if( argc != 2 ){msg("decompile needs 2 args\n"); return -1;}
					if( hasDecompiler == 0) {msg("HexRays Decompiler either not installed or version to old (this binary built against 6.7 SDK)\n"); return -1;}
					return DecompileFunction(ua1, args[2]);

#endif

		  case 44: //iscode
					if( argc != 1 ){msg("iscode needs 1 args\n"); return -1;}
					return is_code(get_flags(ua1));

		  case 45: //isdata
			  		if( argc != 1 ){msg("isdata needs 1 args\n"); return -1;}
					return is_data(get_flags(ua1));

		  case 46: //decodeins  qcmInstLen = 46
			  		if( argc != 1 ){msg("decode_insn needs 1 args\n"); return -1;}
					decode_insn(&ins, ua1);
					return ins.size;
					

		  case 47: //getlong
			  		if( argc != 1 ){msg("getlong needs 1 args\n"); return -1;}
					return get_32bit(ua1);

		  case 48: //getword
					if( argc != 1 ){msg("getword needs 1 args\n"); return -1;}
					return get_16bit(ua1);

		  case 50: //getx64:va:hwnd
					if (argc != 2) { msg("getx64 needs 2 args\n"); return -1; }
					i = get_64bit(ua1);
					sprintf(tmp, "0x%llX",i);
					SendTextMessage(atoi(args[2]), tmp, strlen(tmp));
					return i;

		  case 51:  //dumpfunc:va:flags:fpath
			        if (argc != 3) { msg("dumpfunc needs 3 args\n"); return -1; }
					return DumpFunction(atoi(args[1]), atoi(args[2]), args[3]);

		  case 52: //dumpfuncbytes:va:fpath
				   if (argc != 2) { msg("dumpfuncbytes needs 2 args\n"); return -1; }
				   return DumpFunctionBytes(atoi(args[1]), args[2]);

		  case 53: //immvals:va:hwnd
				   if (argc != 2) { msg("immVals needs 2 args\n"); return -1; }
				   return  GetImm(ua1, atoi(args[2]));

		  case 54: //getopv:va:n:hwnd
				   if (argc != 3) { msg("getopv needs 3 args\n"); return -1; }
				   i = get_operand_value(ua1, atoi(args[2]), atoi(args[3]));
				   if(i != 1)SendTextMessage(atoi(args[3])," ",1);
				   return i;

		  /*case 55: getopn:va not working?
					if (argc != 1) { msg("getopn needs 1 args\n"); return -1; }
					decode_insn(&ins, ua1);
					return ins.ops->n;*/

		  case 55: //addenum:name
			       if (argc != 1) { msg("addenum needs 1 arg\n"); return -1; }
				   return add_enum(BADADDR, args[1], hex_flag() );

		  case 56: //addenummem:enumid:value:name
				   if (argc != 3) { msg("addenummem needs 3 arg\n"); return -1; }
				   return add_enum_member(atoi(args[1]), args[3], ua2);

		  case 57: //getenum:name
				   if (argc != 1) { msg("getenum needs 1 arg\n"); return -1; }
				   return get_enum(args[1]);

		  case 58: //addseg:base:endVa_or_size:name
				   if (argc != 3) { msg("addseg needs 3 arg\n"); return -1; }
				   if(ua2 < ua1) ua2 = ua1 + ua2;
				   return add_segm(0, ua1, ua2, args[3], "CODE",0);

		  case 59: //segExists:nameOrBase
				   if (argc != 1) { msg("segExists needs 1 arg\n"); return -1; }
				   if(ua1!=0){
					   return getseg(ua1) == NULL ? 0 : 1;
				   }else{
					   return get_segm_by_name(args[1]) == NULL ? 0 : 1;
				   }

		  case 60: //delSeg:nameOrBase
				   if (argc != 1) { msg("degSeg needs 1 arg\n"); return -1; }
				   if (ua1 != 0) {
					  return del_segm(ua1, SEGMOD_KEEP);
				   }
				   else {
					  segment_t *seg = get_segm_by_name(args[1]);
					  if(seg==NULL) return 0;
					  return del_segm(seg->start_ea, SEGMOD_KEEP);
				   }
		  case 61: //getsegs:hwnd
					if (argc != 1) { msg("getSegs needs 1 arg\n"); return -1; }
					s = "[\n"; //x = '[{"name":"a","base":"0x1"},{"name":"b","base":"0x2"}]'
					for(i = 0; i < get_segm_qty(); i++){
						segment_t* seg = getnseg(i);
						if(seg != NULL){
							get_segm_name(&name,seg,0);
							//name.replace("'","."); name.replace("\"","."); name.replace("\\","."); //make safe(r) for json translation... looks like IDA already replaces these with underscore
							q.sprnt("\t{'name':'%s','base':'0x%llx','size':'0x%X','index':%d}", name.c_str(), seg->start_ea, seg->end_ea - seg->start_ea, i);
							s+=q;
							if(i != get_segm_qty()-1) s += ",\n"; else s += "\n";
						}
					}
					s+="]";
					SendTextMessage(atoi(args[1]), (char*)s.c_str(), s.length());

		  case 62: //funcmap:path  
					if (argc != 1) { msg("getSegs needs 1 arg\n"); return -1; }
					if (args[1][1] == '_') args[1][1] = ':'; //fix cheesy workaround to tokinizer reserved char..
					fp = fopen(args[1], "w");
					if(fp==NULL) return -1;
					x = 0;
					for(i=0; i < get_func_qty(); i++){
						func_t *fu = getn_func(i);
						if(fu != NULL){
							get_func_name(&name, fu->start_ea);
							ua1 = fu->start_ea; //always a 64bit type even on 32bit disasm so no padding junk 
							ua2 = fu->end_ea;
							fprintf(fp, "%d,%s,%llx,%llx,%d,%d\n", i, name.c_str(), ua1, ua2, (fu->end_ea - fu->start_ea), fu->referers);
							x++;
						}
					}
					fclose(fp);
					return x;

		  case 63: //importpatch:path:va
				  if (argc != 2) { msg("getSegs needs 2 arg\n"); return -1; }
				  if (args[1][1] == '_') args[1][1] = ':'; //fix cheesy workaround to tokinizer reserved char..
				  	
				  int fsize = FileSize(args[1]);
				  //q.sprnt("%d:%s:%llx", fsize, args[1],ua2);
				  //MessageBox(0,q.c_str(),"",0); ;
				  if (fsize < 1) {return -2;}

				  fp = fopen(args[1], "r");
				  if (fp == NULL) return -3;

				  unsigned char* data = (unsigned char*)malloc(fsize);
				  if(data == NULL){fclose(fp); return -4;}
				  fread(&data[0],1,fsize,fp);
				  fclose(fp);

				  for(i=0; i<fsize; i++){
					  patch_byte(ua2+i, data[i]);
				  }

				  free(data);
				  fclose(fp);
				  return 1;

	}				


};


//we can only assume these args/ret val to be 32bit because we must support a 32 bit sendmessage caller (vb6)
//The integral types WPARAM , LPARAM , and LRESULT are 32 bits wide on 32-bit systems and 64 bits wide on 64-bit systems

LRESULT CALLBACK WindowProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam){
		
		
		//msg("WindowProc(hwnd=%x ,uMsg=%x, wParam=%x, lParam=%x)", hwnd, uMsg, wParam, lParam);

		if( uMsg == IDA_QUICKCALL_MESSAGE )//uMsg apparently has to be a registered message to be received...
		{
			try{
				if(m_debug) msg("QuickCall Message Received(%llu, %llu)\n", (__int64)wParam, (__int64)lParam );
				return HandleQuickCall( (unsigned __int64)wParam, (unsigned __int64)lParam );
			}catch(...){ 
				msg("Error in HandleQuickCall(%llu, %llu)\n", (unsigned int)wParam, (unsigned int)lParam );
				return -1;
			}
		}
	
		if( uMsg == IDASRVR_BROADCAST_MESSAGE){ //so clients can sent a broadcast to all windows with wparam of their command hwnd
			if (m_debug) msg("IDASRVR_BROADCAST_MESSAGE Message Received\n");
			if( IsWindow((HWND)wParam) ){       //we ping them back with with lParam = ServerHwnd to say were alive 
				SendMessage((HWND)wParam, IDASRVR_BROADCAST_MESSAGE, 0, (LPARAM)ServerHwnd);
			}
			return 0;
		}

		if( uMsg != WM_COPYDATA) return DefWindowProc(hwnd, uMsg, wParam, lParam);
		if( lParam == 0)         return DefWindowProc(hwnd, uMsg, wParam, lParam);
		
		int retVal = 0;
		EnterCriticalSection(&m_cs);
		memcpy((void*)&CopyData, (void*)lParam, sizeof(cpyData));
    
		if (CopyData.dwFlag == 3 && CopyData.cbSize > 0) {

			if (CopyData.cbSize >= sizeof(m_msg) - 2) CopyData.cbSize = sizeof(m_msg) - 2;

			memcpy((void*)&m_msg[0], (void*)CopyData.lpData, CopyData.cbSize);
			m_msg[CopyData.cbSize] = 0; //always null terminate..

			if (m_debug)	msg("Message Received: %s \n", m_msg);

			try {
				retVal = HandleMsg(m_msg);
			}
			catch (...) { //remember this doesnt help any if we did anything that led to memory corruption...
				msg("Caught an Error in HandleMsg!");
				if (!m_debug) msg("Message: %s \n", m_msg);
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

void CreateServerWindow()
{
	WNDCLASSEX wc = { };
	MSG msg;
	HWND hwnd;

	wc.cbSize = sizeof(wc);
	wc.style = 0;
	wc.lpfnWndProc = WindowProc;
	wc.cbClsExtra = 0;
	wc.cbWndExtra = 0;
	wc.hInstance = GetModuleHandle(NULL);
	wc.hIcon = NULL;
	wc.hCursor = NULL;
	wc.hbrBackground = NULL;
	wc.lpszMenuName = NULL;
	wc.lpszClassName = IPC_NAME;
	wc.hIconSm = NULL;

	if (!RegisterClassEx(&wc)) {
		MessageBox(NULL, TEXT("Could not register IPC Server window class"),NULL, MB_ICONERROR);
		return;
	}

	ServerHwnd = CreateWindowEx(WS_EX_LEFT,
		IPC_NAME,
		NULL,
		WS_OVERLAPPEDWINDOW,
		CW_USEDEFAULT,
		CW_USEDEFAULT,
		CW_USEDEFAULT,
		CW_USEDEFAULT,
		NULL,
		NULL,
		GetModuleHandle(NULL),
		NULL);

	if (!ServerHwnd) {
		MessageBox(NULL, TEXT("Could not create window"), NULL, MB_ICONERROR);
		return;
	}

	//msg("ServerHWND = %x oldProc=%x newProc=%x", ServerHwnd, oldProc, WindowProc);
}

void idaapi term(void)
{
	try {
#ifdef HAS_DECOMPILER 
		if (hasDecompiler) term_hexrays_plugin();
#endif
		DestroyWindow(ServerHwnd);
		HWND saved_hwnd = ReadReg(IPC_NAME);
		if (!IsWindow(saved_hwnd)) 
			SetReg(IPC_NAME, 0);
		//CloseHandle(hMemMapFile);
	}
	catch (...) {};
}

bool idaapi run(size_t arg)
{
	Launch_IdaJscript();
	return true;
}

void startUp(void)
{
	CreateServerWindow();
	SetReg(IPC_NAME, (int)ServerHwnd);
	IDASRVR_BROADCAST_MESSAGE = RegisterWindowMessage(IPC_NAME);
	IDA_QUICKCALL_MESSAGE = RegisterWindowMessage("IDA_QUICKCALL2");

	InitializeCriticalSection(&m_cs);
	//msg("idasrvr2: initializing... hwnd=%x BROADCAST=%x QUICKCALL=%x ThreadID=%x\n", ServerHwnd, IDASRVR_BROADCAST_MESSAGE, IDA_QUICKCALL_MESSAGE, GetCurrentThreadId());

	//MessageBox(0, "1", "", 0);

#ifdef HAS_DECOMPILER
	if (init_hexrays_plugin(0)) {
		hasDecompiler = 1;
		msg("IDASrvr2: detected hexrays decompiler version %s\n", get_hexrays_version());
	}
	else {
		msg("idasrvr2: init_hexrays_plugin failed...\n");
	}
#endif

	/*if(!CreateMemMapFile("IDASRVR2_VFILE", 2048)){
		  msg("Failed to create vfile");
		  return 0;
	}*/

	//MessageBox(0, "2", "", 0);
}

static plugmod_t* idaapi init()
{
	if (inf_get_filetype() == f_ELF) return nullptr; // we do not want to work with this idb
	startUp();
	return PLUGIN_KEEP;
}


char comment[] = "";
char help[] = "";
char wanted_name[] = "IDA JScript2";
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


//https://github.com/idapython/src/blob/17a1c5445736e9f1967ee392e140c39abd6d949c/python/idc.py#L1654
int __stdcall get_operand_value(__int64 va, int n, int hwnd)
{
	qstring q;
	if (n < 0 || n > 8) return -1;
	insn_t ins;
	decode_insn(&ins, va);
	if (ins.size == 0) return -2;
	op_t op = ins.ops[n];
	switch (op.type)
	{
		case o_mem:
		case o_far:
		case o_near:
		case o_displ: // Memory Ref [Base Reg + Index Reg + Displacement].
			q.sprnt("0x%llx", op.addr);
			break;
		/*case o_reg:
			//from intel.hpp enum RegNo ? not useful just parse asm
		    q.sprnt("reg:%llx", op.reg);
			break;*/
		case o_imm:
			//use op.value
			q.sprnt("0x%llx", op.value);
			break;
		/*case o_phrase: //Memory Ref [Base Reg + Index Reg].
			//use op.phrase
			q.sprnt("phrase:%llx", op.phrase);
			break;*/
		default:
			return -3;
	}

	SendTextMessage(hwnd, (char*)q.c_str(), q.length()+1);
	return 1;

}
//todo: returning nothing...
int __stdcall GetImm(__int64 ea, int hwnd)
{
	qstring q;
	uval_t vals[16] = { 0 };
	int i = get_printable_immvals((uval_t*)&vals, ea, 8, 0);
	if (i < 1 || i > 16) {
		SendTextMessage(hwnd, " ", 1);
		return -2;
	}
	for (int j = 0; j < i; j++){
		q.cat_sprnt("%llX,", vals[j]);
	}
	SendTextMessage(hwnd, (char*)q.c_str(), q.length()+1);
	return i;
}

//Export API for the VB app to call and access IDA API data
//_________________________________________________________________

/*
void __stdcall SetFocusSelectLine(void){ 
	/*HWND ida = (HWND)callui(ui_get_hwnd).vptr;   //todo IDA7
	SetForegroundWindow(ida);	//make ida window active and send HOME+ SHIFT+END keys to select the current line
	keybd_event(VK_HOME,0x4F,KEYEVENTF_EXTENDEDKEY | 0,0);
	keybd_event(VK_HOME,0x4F,KEYEVENTF_EXTENDEDKEY | KEYEVENTF_KEYUP,0);
	keybd_event(VK_SHIFT,0x2A,0,0);
	keybd_event(VK_END,0x4F,KEYEVENTF_EXTENDEDKEY | 0,0);
	keybd_event(VK_END,0x4F,KEYEVENTF_EXTENDEDKEY | KEYEVENTF_KEYUP,0);
	keybd_event(VK_SHIFT,0x2A,KEYEVENTF_KEYUP,0); * /
}*/

void __stdcall Jump(__int64 addr)  { jumpto(addr);}
void __stdcall Refresh   (void)      { refresh_idaview();      }
__int64  __stdcall ScreenEA  (void)      { return get_screen_ea(); }
int  __stdcall NumFuncs  (void)      { return get_func_qty();  }
void __stdcall RemvName  (__int64 addr)  { del_global_name(addr);  }
void __stdcall Setname(__int64 addr, const char* name){ set_name(addr, name); }
//void __stdcall AddComment(char *cmt, char color){ generate_big_comment(cmt, color);}
void __stdcall AddProgramComment(char *cmt){ add_pgm_cmt(cmt); }
void __stdcall AddCodeXRef(__int64 start, __int64 end){ add_cref(start, end, cref_t(fl_F | XREF_USER) );}
void __stdcall DelCodeXRef(__int64 start, __int64 end){ del_cref(start, end, 1 );}
void __stdcall AddDataXRef(__int64 start, __int64 end){ add_dref(start, end, dref_t(dr_O | XREF_USER) );}
void __stdcall DelDataXRef(__int64 start, __int64 end){ del_dref(start, end );}
void __stdcall MessageUI(char *m){ msg(m);}
void __stdcall PatchByte(__int64 addr, char val){ patch_byte(addr, val); }
void __stdcall PatchWord(__int64 addr, int val){  patch_word(addr, val); }
void __stdcall DelFunc(__int64 addr){ del_func(addr); }
int  __stdcall FuncIndex(__int64 addr){ return get_func_num(addr); }
//void __stdcall SelBounds( ea_t* selStart, ea_t* selEnd){ /*read_selection(selStart, selEnd);*/} //todo IDA7
void __stdcall Undefine(__int64 offset){ auto_mark(offset, AU_UNK); }
char __stdcall OriginalByte(__int64 offset){ return get_original_byte(offset); }

void __stdcall SetComment(__int64 offset, char* comm){set_cmt(offset,comm,false);}

int  __stdcall GetBytes(__int64 offset, void* buf, int length) 
{ 
	return get_bytes(buf, length, offset);
}

void __stdcall FuncName(__int64 addr, char* buf, size_t bufsize) 
{
	qstring q;
	get_func_name(&q, addr); 
	memset(buf, 0, bufsize);
	if (q.length() > 0 && q.length() <  bufsize) {
		qstrncpy(buf, q.c_str(), q.length()+1);
	}

}

void __stdcall GetComment(__int64 offset, char* buf, int bufsize){ 
	qstring q;
	int retlen = get_cmt(&q, offset,false); 
	memset(buf, 0, bufsize);
	if (q.length() > 0 && q.length() <  bufsize) {
		qstrncpy(buf, q.c_str(), q.length()+1);
	}
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
	retlen = get_root_filename(buf,bufsize);
	return retlen;
}

void __stdcall HideEA(__int64 offset){	set_visible_item(offset, false); }
void __stdcall ShowEA(__int64 offset){	set_visible_item(offset, true); }

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
void __stdcall AnalyzeArea(__int64 startat, __int64 endat){ /*analyse_area(startat, endat);*/}


//now works to get local labels
void __stdcall GetName(__int64 offset, char* buf, int bufsize){

	qstring q;
	q = get_name(offset);
	memset(buf, 0, bufsize);

	if (q.length() > 0)
	{
		if (q.length() < bufsize)
		{
			qstrncpy(buf, q.c_str(), q.length()+1);
		}
	}
	else  //todo: IDA 7 - use fx in names.hpp
	{
		/*func_t* f = get_func(offset);
		llabel_t* ll = f->llabels;
		for(int i=0; i < f->llabelqty; i++){
			if( ll.ea == offset ){
				int sz = strlen(ll.name);
				if(sz < bufsize) strcpy(buf,ll.name);
				return;
			}
			ll++;
		}*/
	}

}

//not workign to make code and analyze
void __stdcall MakeCode(__int64 offset){
	 auto_mark(offset, AU_CODE);
	 /*analyse_area(offset, (offset+1) );*/
}


__int64 __stdcall FunctionStart(int n){
	func_t *clsFx = getn_func(n);
	if (clsFx == nullptr) {
		if (m_debug) msg("Invalid function index specified!");
		return -1;
	}
	return clsFx->start_ea;
}

__int64 __stdcall FunctionEnd(int n){
	func_t *clsFx = getn_func(n);
	if (clsFx == nullptr) {
		if (m_debug) msg("Invalid function index specified!");
		return -1;
	}
	return clsFx->end_ea;
}

int __stdcall FuncArgSize(int index){
		func_t *clsFx = getn_func(index);
		if (clsFx == nullptr) {
			if (m_debug) msg("Invalid function index specified!");
			return -1;
		}
		return clsFx->argsize ;
}

int __stdcall FuncColor(int index){
		func_t *clsFx = getn_func(index);
		if (clsFx == nullptr) {
			if (m_debug) msg("Invalid function index specified!");
			return -1;
		}
		return clsFx->color  ;
}

int __stdcall GetAsm(__int64 addr, char* buf, int bufLen){

    flags_t flags;                                                       
    int sLen=0;
	qstring q; 

	memset(buf, 0, bufLen);
    flags = get_flags(addr);                        
	if (is_code(flags)) {
		generate_disasm_line(&q, addr, GENDSM_MULTI_LINE);
		if (q.length() > 0) {
			sLen = tag_remove(&q) + 1;
			if (sLen > 1 && sLen < bufLen) {
				qstrncpy(buf, q.c_str(), sLen);
				return sLen;
			}
		}
    }

	return 0;

}


//todo: improve me - this function is simplistic, will miss undisasm sections and chunked function tails. maybe output to memmap file instead
//      also add options bitflag w/addr, w/opcodes
int __stdcall DumpFunction(int funcIndex, int flags, char* outFilePath)
{
	func_t* clsFx = getn_func(funcIndex);
	if (clsFx == nullptr) {
		if (m_debug) msg("Invalid function index specified!");
		return -1;
	}

	__int64 curEA = clsFx->start_ea;
	__int64 endAt = clsFx->end_ea;

	if (outFilePath[1] == '_') outFilePath[1] = ':'; //fix cheesy workaround to tokinizer reserved char..

	FILE* f = fopen(outFilePath, "w+");
	if (f == NULL) {
		if (m_debug) msg("Invalid function index specified!");
		return -2;
	}

	char buf[500] = { 0 };
	char cmt[500] = { 0 };
	char tmp[100] = { 0 };
	char* t;

	insn_t ins;

	while (curEA < endAt && curEA != BADADDR)
	{
		int sz = GetAsm(curEA, buf, sizeof(buf));
		if (sz == 0) break;
		if (flags & 1) {
			#ifdef __EA64__
				fprintf(f, "%016llX  ", curEA);
			#else
				fprintf(f, "%08X  ", (int)curEA);
			#endif
		}
		if (flags & 2) {
			t = (char*)&tmp;
			memset(tmp, 0, sizeof(tmp));
			decode_insn(&ins, curEA);
			for (int i = 0; i < ins.size; i++) { //max size is 16
				sprintf(t, "%02X ", get_byte(curEA + i));
				t += 3;
				if (i > 16) {sprintf(t, "%s", " ... "); break;}
			}
			fprintf(f, "%-20s  ", tmp);
		}
		if(flags & 4) GetComment(curEA, cmt, sizeof(cmt)); //mem zeroed internally
		fprintf(f, "%s %s\r\n", buf, cmt);
		curEA = find_code(curEA, SEARCH_DOWN | SEARCH_NEXT);
	}
	
	fclose(f);
	return 1;

}

int __stdcall DumpFunctionBytes(int funcIndex, char* outFilePath)
{
	func_t* clsFx = getn_func(funcIndex);
	if (clsFx == nullptr) {
		if (m_debug) msg("Invalid function index specified!");
		return -1;
	}

	__int64 startEA = clsFx->start_ea;
	__int64 endEA = clsFx->end_ea;
	int size = endEA - startEA;

	if (startEA == 0 || endEA == 0 || size == 0) return -1;

	if (outFilePath[1] == '_') outFilePath[1] = ':'; //fix cheesy workaround to tokinizer reserved char..

	FILE* f = fopen(outFilePath, "w+");
	if (f == NULL) {
		if (m_debug) msg("Invalid function index specified!");
		return -2;
	}

	unsigned char* buf = (unsigned char*)malloc(size);
	get_bytes(buf, size, startEA);
	for (int i = 0; i < size-1; i++)
	{
		fprintf(f, "\\x%02X", buf[i]);
	}
	fclose(f);
	return 1;

}


__int64 __stdcall FirstCodeFrom(__int64 ea){

	xb.first_from(ea, XREF_ALL);
	return xb.iscode ==1 ? xb.to : 0 ;

}

__int64 __stdcall FirstCodeTo(__int64 ea){

	xb.first_to(ea, XREF_ALL);
	return xb.iscode ==1 ? xb.from : 0;

}

__int64 __stdcall NextCodeTo(__int64 ea){

	xb.next_to();
	return xb.iscode ==1 ? xb.from : 0;

}

__int64 __stdcall NextCodeFrom(__int64 ea){

	xb.next_from();
	return xb.iscode ==1 ? xb.to : 0;

}

__int64 __stdcall ImageBase(void){

  netnode penode("$ PE header");
  ea_t loaded_base = penode.altval(-2);
  return loaded_base;

}

//idaman ea_t ida_export find_text(ea_t start_ea, int y, int x, const char *ustr, int sflag);
//#define SEARCH_UP       0x000		// only one of SEARCH_UP or SEARCH_DOWN can be specified
//#define SEARCH_DOWN     0x001
//#define SEARCH_NEXT     0x002
/*
int __stdcall SearchText(int addr, char* buf, int search_type,int debug){

	char msg[500]={0};
	int y=0,x=0;
	int ret = find_text(addr,y,x,buf, search_type);
	
	if(m_debug==1){
		qsnprintf(msg,499,"ret=%x addr=%x search_type=%x",ret,addr,search_type);
		MessageBox(0,msg,"",0);
	}

	return ret;

}
*/


//todo: switch this to dumping to memfile
int __stdcall GetRefsTo(__int64 offset, int hwnd){

	int count=0;
	int retVal=0;

	xrefblk_t xb;
    for ( bool ok=xb.first_to(offset, XREF_ALL); ok; ok=xb.next_to() ){
		SendIntMessage(hwnd,xb.from);
		SendTextMessage(hwnd,",",2);
    }
	SendTextMessage(hwnd,"DONE",5);

	/* more efficient to buffer? COPYDATA max is 1048 bytes..
	__int64 v = 0;
	int sz = 0; pos = 0;, bufSz = 2000;
	char tmp[200] = {0};
	char* buf = (char*)malloc(bufSz);
	memset(buf,0,bufSz);

	xrefblk_t xb;
    for ( bool ok=xb.first_to(offset, XREF_ALL); ok; ok=xb.next_to() ){
		sprintf(tmp, "%llu", xb.from);
		sz = strlen(tmp);
		if( (sz+pos) >= 1020){
			SendTextMessage(hwnd,buf,strlen(buf));
			memset(buf,0,bufSz);
			pos=0;
		}
		memcpy(&buf[pos], tmp, sz);
		pos += sz;
		buf[pos+1] = ',';
		pos++;
    }

	SendTextMessage(hwnd,buf,strlen(buf));
	SendTextMessage(hwnd,"DONE",5);
	*/

	return count;

}


//todo: switch this to dumping to memfile
int __stdcall GetRefsFrom(__int64 offset, int hwnd){

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

//todo: switch this to dumping to memfile?
int __stdcall DecompileFunction(__int64 offset, char* fpath)
{
#ifdef HAS_DECOMPILER
			
		qstring buf;

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
		
		/*if(m_debug)*/ msg("%a: successfully decompiled\n", pfn->start_ea);

		const strvec_t &sv = cfunc->get_pseudocode(); //not available in 6.2 known ok in 6.5..
		for ( int i=0; i < sv.size(); i++ )
		{
			tag_remove(&buf, sv[i].line, 0);
			fprintf(f,"%s\n", buf.c_str());
		}
		fclose(f);
		return 1;
#else
		return -1;
#endif
	}




/*

//memmapped file stuff
HANDLE hMemMapFile = 0;
void* gMemMapAddr = 0;
unsigned int MaxSize = 0;

//another alternative to WM_COPYDATA basically ping back arg1 hwnd arg to get or set text...is it any quicker though?
leng = SendMessage(h, WM_GETTEXTLENGTH, 0, 0);
SendMessage(h, WM_GETTEXT, 256, (LPARAM)p);
printf("%s",p);
getch();

strcpy(p,"testing!");
SendMessage(h, WM_SETTEXT, 0, (LPARAM)p);
getch();



__int64 write64(unsigned __int64 x){
	memcpy(gMemMapAddr,&x,8);
	return x;
}

int write32(unsigned int x){
	memcpy(gMemMapAddr,&x,4);
	return x;
}

int write16(unsigned int x){
	memcpy(gMemMapAddr,&x,2);
	return x;
}

int write8(unsigned int x){
	memcpy(gMemMapAddr,&x,1);
	return x;
}

int writeStr(char* x){
	if(x==NULL){
		memset(gMemMapAddr,0,1);
		return 0;
	}
	int len = strlen(x)+1;
	memcpy(gMemMapAddr,x,len);
	return len;
}

void writeBlob(unsigned char* x, int len){
	memcpy(gMemMapAddr,x,len);
}

unsigned __int64 read64u(){
	unsigned __int64 x=0;
	memcpy(&x,gMemMapAddr,8);
	return x;
}





bool CreateMemMapFile(char* fName, int mSize){
    

    if((int)hMemMapFile!=0){
        msg("Cannot open multiple virtural files with one class");
        return false;
    }

    MaxSize = 0;
    hMemMapFile = CreateFileMapping((HANDLE)-1, 0, PAGE_READWRITE, 0, mSize, fName);

    if( hMemMapFile == 0 ){
        msg("Unable to create virtual file");
        return false;
    }

     gMemMapAddr = MapViewOfFile(hMemMapFile, FILE_MAP_ALL_ACCESS, 0, 0, mSize);

     if (gMemMapAddr == 0) return false;

	 MaxSize = mSize;
     return true;
    
}

		case 8: // imgbase - changed now memfile output, still 32bit safe old way..
				return write64(ImageBase());
				 
		case 10: //readbyte:lngva - changed now reads address from memFile
				return get_byte(tmp);
				 
		case 11: //orgbyte:lngva  - changed now reads address from memFile
				return get_original_byte(tmp);		 


		case 14: //funcstart:funcIndex - changed to memfile output
				return write64(FunctionStart( arg1 ));
				 
		case 15: //funcend:funcIndex - changed to memfile output
				 return write64(FunctionEnd( arg1 ));
				 
		case 20: //undefine:offset   - changed now reads address from memFile
				Undefine( tmp );
				return 0;

		case 22: //hide:offset   - changed now reads address from memFile
				HideEA( tmp );
				return 0;

		case 23: //show:offset   - changed now reads address from memFile
				ShowEA( tmp );
				return 0;

		case 24: //remname:offset   - changed now reads address from memFile
				RemvName( tmp );
				return 0;

		case 25: //makecode:offset   - changed now reads address from memFile
			    MakeCode( tmp );
			    return 0;

		case 32: //funcindex:va     - changed now reads address from memFile
				 return get_func_num( tmp );
					
		case 33: //nextea:va  should this return null if it crosses function boundaries? yes probably... changed writes to memfile
				 write64( find_code( tmp , SEARCH_DOWN | SEARCH_NEXT ) );
				 return 1;
					
		case 34: //prevea:va  should this return null if it crosses function boundaries? yes probably...  changed writes to memfile
				 write64( find_code( tmp , SEARCH_UP | SEARCH_NEXT ));
				 return 1;

	    case 37: //screenea: changed writes to memfile
				 write64( ScreenEA() );
				 return 1;

		case 44:
				return isCode(getFlags(tmp));
		case 45:
				return isData(getFlags(tmp));
		case 46:
				return decode_insn(tmp);
		case 47:
				return get_long(tmp);
		case 48:
				return get_word(tmp);







*/


/*
struct plugin_ctx_t : public plugmod_t, public event_listener_t
{
	plugin_ctx_t()
	{

	}

	~plugin_ctx_t()
	{
		term();
	}

	bool idaapi run(size_t arg) {
		return  run(arg);
	}

	ssize_t idaapi on_event(ssize_t code, va_list va) {
		// This callback is called for IDP notification events
		return 0;
	}
};

plugin_ctx_t* pd = new plugin_ctx_t;*/