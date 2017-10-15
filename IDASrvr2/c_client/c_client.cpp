
#include <stdio.h>
#include <conio.h>
#include <string.h>
#include <windows.h>
#include <stdlib.h>

const int WM_DISPLAY_TEXT = 3;

//this is a super quick and dirty demo of a C client..

typedef struct{
    int dwFlag;
    int cbSize;
    int lpData;
} cpyData;


HWND hServer;
WNDPROC oldProc;
cpyData CopyData;

int  m_debug = 0;
int  m_ServerHwnd = 0;
char* IDA_SERVER_NAME = "IDA_SERVER2";
char m_msg[2020];
bool received_response = false;
UINT IDA_QUICKCALL_MESSAGE;
int IDA_HWND=0;

//quick call offers about 3x performance boost over original..
enum quickCallMessages{
	qcmJmpAddr = 1, // jmp:lngAdr
	qcmJmpRVA = 7, // jmp_rva:lng_rva
	qcmImgBase = 8, // imgbase 
	qcmReadByte = 10, //readbyte,lngva 
	qcmOrgByte = 11, //orgbyte,lngva 
	qcmRefresh = 12, // refresh,
	qcmNumFuncs = 13, // numfuncs 
	qcmFuncStart = 14, //funcstart,funcIndex 
	qcmFuncEnd = 15, //funcend,funcIndex 
	qcmUndef = 20, //undefine,offset
	qcmHide = 22, //hide,offset
	qcmShow = 23, //show,offset
	qcmRemName = 24, //remname,offset
	qcmMakeCode = 25, //makecode,offset
	qcmFuncIdx = 32, //funcindex,va 
	qcmNextEa = 33, //nextea,va   
	qcmPrevEa = 34 //prevea:va   
};
		

#pragma warning (disable:4996)

HWND ReadReg(char* name){ //todo support multiple IDA idb's and not just last one opened...

	 char* baseKey = "Software\\VB and VBA Program Settings\\IPC\\Handles";
	 char tmp[20] = {0};
     unsigned long l = sizeof(tmp);
	 HKEY h;
	 
	 RegOpenKeyExA(HKEY_CURRENT_USER, baseKey, 0, KEY_READ, &h);
	 RegQueryValueExA(h, name, 0,0, (unsigned char*)tmp, &l);
	 RegCloseKey(h);

	 return (HWND)atoi(tmp);
}

int SendTextMessage(int hwnd, char *Buffer, int blen) 
{
		  char* nullString = "NULL";
		  if(blen==0){ //in case they are waiting on a message with data len..
				Buffer = nullString;
				blen=4;
		  }
		  if(m_debug){
			  printf("Trying to send message to %x size:%d\n", hwnd, blen);
			  printf(" msg> %s\n", Buffer);
		  }
		  if(Buffer[blen] != 0) Buffer[blen]=0; ;
		  cpyData cpStructData;  
		  cpStructData.cbSize = blen;
		  cpStructData.lpData = (int)Buffer;
		  cpStructData.dwFlag = 3;
		  return SendMessage((HWND)hwnd, WM_COPYDATA, (WPARAM)hwnd,(LPARAM)&cpStructData);  
}  

int SendIntMessage(int hwnd, __int64 resp){
	char tmp[30]={0};
	sprintf(tmp, "%llu", resp);
	if(m_debug) printf("SendIntMsg(%d, %s)", hwnd, tmp);
	return SendTextMessage(hwnd,tmp, sizeof(tmp));
} 

void HandleMsg(char* m){
	//Message Received from IDA do stuff here...
	printf("%s\n", m);
}

/* old method */		//these next 2 are a very simple implementation..SendMessage automatically blocks so this works...
__int64 ReceiveInt(char* command, int hwnd){
	memset(m_msg,0,2020);
	received_response = false;
	SendTextMessage(hwnd,command,strlen(command)+1);
	return _atoi64(m_msg);
}

int NewReceiveInt(char* command, int hwnd){
	return SendTextMessage(hwnd,command,strlen(command)+1);
}

char* ReceiveText(char* command, int hwnd){
	memset(m_msg,0,2020);
	received_response = false;
	SendTextMessage(hwnd, command,strlen(command)+1);
	return m_msg;
}


LRESULT CALLBACK WindowProc(HWND hwnd,UINT uMsg,WPARAM wParam,LPARAM lParam){

		if( uMsg != WM_COPYDATA) return 0;
		if( lParam == 0) return 0;
		
		memcpy((void*)&CopyData, (void*)lParam, sizeof(cpyData));
    
		if( CopyData.dwFlag == 3 ){
			if( CopyData.cbSize >= sizeof(m_msg) ) CopyData.cbSize = sizeof(m_msg)-1;
			memcpy((void*)&m_msg[0], (void*)CopyData.lpData, CopyData.cbSize);
			if(m_debug)	printf("Message Received: %s \n", m_msg); 
			received_response = true;
		}
			
    return 0;
}

//some quick call messages now require reading memfile which we havent setup in this example...
//might eliminate those from the quick call..
int QuickCall(quickCallMessages msg, int arg1 =0 ){
	return SendMessage( (HWND)IDA_HWND, IDA_QUICKCALL_MESSAGE, msg, arg1);
}

int main(int argc, char* argv[])
{
 
	system("cls");

	m_ServerHwnd = (int)CreateWindowA("EDIT","MESSAGE_WINDOW", 0, 0, 0, 0, 0, 0, 0, 0, 0);
	oldProc = (WNDPROC)SetWindowLongA((HWND)m_ServerHwnd, GWL_WNDPROC, (LONG)WindowProc);

	IDA_HWND = (int)ReadReg(IDA_SERVER_NAME);
	if(!IsWindow((HWND)IDA_HWND)) IDA_HWND = 0;

	IDA_QUICKCALL_MESSAGE = RegisterWindowMessageA("IDA_QUICKCALL2");

	if( m_ServerHwnd == 0){
		printf("Could not create listener window to receive data on exiting...\n");
		printf("Press any key to exit..");
		getch();
		return 0;
	}

	if( IDA_HWND==0 ){
		printf("IDA Server window not found exiting...\n");
		printf("Press any key to exit..");
		getch();
		return 0;
	}
	
	printf("Listening for responses on hwnd: %d\n", m_ServerHwnd); 
	printf("Active IDA hwnd: %d\n", IDA_HWND);

	char buf[255];
	__int64 ret = 0;
    char* sret = 0;
	LARGE_INTEGER start , end, freq;
	
	QueryPerformanceFrequency(&freq);
	printf("1 tick = 1/%d seconds\n\n", freq.QuadPart);

	sprintf(buf,"loadedfile:%d", m_ServerHwnd);
	sret = ReceiveText(buf,IDA_HWND); 	
    printf("Loaded IDB: %s\n", sret);

	sprintf(buf,"numfuncs:%d", m_ServerHwnd);
	
	QueryPerformanceCounter(&start);
	ret = ReceiveInt(buf, IDA_HWND); //two copydata's  + sprintf + string to int
	QueryPerformanceCounter(&end);
	
	printf("Function Count: %d  (org method %d ticks)\n", ret, end.QuadPart-start.QuadPart);

	QueryPerformanceCounter(&start);
	ret = NewReceiveInt("numfuncs", IDA_HWND);
	QueryPerformanceCounter(&end);
	
	printf("Function Count: %d  (new method %d ticks)\n", ret, end.QuadPart-start.QuadPart);

	QueryPerformanceCounter(&start);
	ret = QuickCall(qcmNumFuncs);
	QueryPerformanceCounter(&end);
	
	printf("Function Count: %d  (quick call %d ticks)\n", ret, end.QuadPart-start.QuadPart);
	
	sprintf(buf,"funcstart:0:%d", m_ServerHwnd);
	int funcStart = ReceiveInt(buf, IDA_HWND);
	printf("\nFirst Func Start: 0x%x\n", funcStart);

	sprintf(buf,"funcend:0:%d", m_ServerHwnd);
	ret = ReceiveInt(buf, IDA_HWND);
	printf("First Func End: 0x%x\n", ret);

	sprintf(buf,"getasm:%d:%d", funcStart, m_ServerHwnd);
	sret = ReceiveText(buf,IDA_HWND); 	
    printf("First Func Disasm[0]: %s\n", sret);
	
	printf("Press any key to exit..");
	getch();
	
	return 0;

}