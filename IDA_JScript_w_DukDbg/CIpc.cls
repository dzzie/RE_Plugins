VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "CIpc"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Private WithEvents sc As clsSubClass
Attribute sc.VB_VarHelpID = -1

Private Declare Function SendMessage Lib "user32" Alias "SendMessageA" (ByVal hwnd As Long, ByVal wMsg As Long, ByVal wParam As Long, lParam As Any) As Long
Private Declare Function SendMessageByVal Lib "user32" Alias "SendMessageA" (ByVal hwnd As Long, ByVal wMsg As Long, ByVal wParam As Long, ByVal lParam As Any) As Long

Private Declare Sub CopyMemory Lib "kernel32" Alias "RtlMoveMemory" (hpvDest As Any, hpvSource As Any, ByVal cbCopy As Long)
Private Declare Function RegisterWindowMessage Lib "user32" Alias "RegisterWindowMessageA" (ByVal lpString As String) As Long
Private Declare Function SendMessageTimeout Lib "user32" Alias "SendMessageTimeoutA" (ByVal hwnd As Long, ByVal msg As Long, ByVal wParam As Long, ByVal lParam As Long, ByVal fuFlags As Long, ByVal uTimeout As Long, lpdwResult As Long) As Long
Private Declare Function PostMessage Lib "user32" Alias "PostMessageA" (ByVal hwnd As Long, ByVal wMsg As Long, ByVal wParam As Long, ByVal lParam As Long) As Long
 
Private Type COPYDATASTRUCT
    dwFlag As Long
    cbSize As Long
    lpData As Long
End Type

'quick call offers about 3x performance boost over original..
Public Enum quickCallMessages
    qcmJmpAddr = 1    ' jmp:lngAdr
    qcmJmpRVA = 7     ' jmp_rva:lng_rva
    qcmImgBase = 8    ' imgbase
    qcmReadByte = 10  ' readbyte:lngva
    qcmOrgByte = 11   ' orgbyte:lngva
    qcmRefresh = 12   ' refresh
    qcmNumFuncs = 13  ' numfuncs
    qcmFuncStart = 14 ' funcstart:funcIndex
    qcmFuncEnd = 15   ' funcend:funcIndex
    qcmUndef = 20     ' undefine:offset
    qcmHide = 22      ' hide:offset
    qcmShow = 23      ' show:offset
    qcmRemName = 24   ' remname:offset
    qcmMakeCode = 25  ' makecode:offset
    qcmFuncIdx = 32   ' funcindex:va
    qcmNextEa = 33    ' nextea:va
    qcmPrevEa = 34    ' prevea:va
    qcmScreenEA = 37  ' screenea:
    qcmDebugMessages = 38
    qcmhasDecompiler = 39
    qcmFlushDecompilationResults = 40
    qcmIDAHwnd = 41     'gets main IDA Window HWND
    qcmGetVersion = 42  'version of interface
    qcmSetFocusSelectLine = 43 'bring IDA to forefront and select current line
    qcmIsCode = 44
    qcmIsData = 45
    qcmInstLen = 46
    qcmReadLong = 47
    qcmReadShort = 48
End Enum

Private Const WM_COPYDATA = &H4A
Private Const HWND_BROADCAST = &HFFFF&
Private IDASRVR_BROADCAST_MESSAGE As Long
Private IDA_QUICKCALL_MESSAGE As Long

Public Servers As New Collection
Public RemoteHWND As Long
Private subclassed_hwnd As Long
Public ServerName As String
         
Public timeout As Long
Private DataIn As String

Private isListening As Boolean


Property Get IamListening() As Boolean
    IamListening = isListening
End Property

Function Listen(hwnd As Long) As String

    If isListening Then Exit Function
     
    subclassed_hwnd = hwnd
    
    If Not sc.AttachMessage(subclassed_hwnd, WM_COPYDATA) Then Exit Function
        
    isListening = True
    IDASRVR_BROADCAST_MESSAGE = RegisterWindowMessage("IDA_SERVER")
    IDA_QUICKCALL_MESSAGE = RegisterWindowMessage("IDA_QUICKCALL")
    sc.AttachMessage subclassed_hwnd, IDASRVR_BROADCAST_MESSAGE
    
    'FindActiveIDAWindows
    
End Function

Function FindActiveIDAWindows(Optional async As Boolean = False) As Long
     Dim ret As Long
     'so a client starts up, it gets the message to use (system wide) and it broadcasts a message to all windows
     'looking for IDASrvr instances that are active. It passes its command window hwnd as wParam
     'IDASrvr windows will receive this, and respond to the HWND with the same IDASRVR message as a pingback
     'sending thier command window hwnd as the lParam to register themselves with the clients.
     'clients track these hwnds.
     
     'Form1.List2.AddItem "Broadcasting message looking for IDASrvr instances msg= " & IDASRVR_BROADCAST_MESSAGE
     
     If async Then
        PostMessage HWND_BROADCAST, IDASRVR_BROADCAST_MESSAGE, subclassed_hwnd, 0
     Else
        SendMessageTimeout HWND_BROADCAST, IDASRVR_BROADCAST_MESSAGE, subclassed_hwnd, 0, 0, 1000, ret
     End If
     
      ValidateActiveIDAWindows
      FindActiveIDAWindows = Servers.Count
     
 End Function

 Private Function ValidateActiveIDAWindows()
     On Error Resume Next
     Dim x
     For Each x In Servers 'remove any that arent still valid..
        If IsWindow(x) = 0 Then
            Servers.Remove "hwnd:" & x
        End If
     Next
 End Function
 
Function SendCmdRecvText(msg As String) As String
    Send msg
    SendCmdRecvText = DataIn
End Function
 
'this was the old way i was doing it, receiving the int as a data callback..
'but more optimized way exists..using SendMessage return value (duh)
'the plugin still supports the old method so I dont break any old code..
'
'Function SendCmdRecvInt(msg As String) As Long
'    On Error Resume Next
'    Send msg
'    SendCmdRecvInt = CLng(DataIn)
'End Function

Function SendCmdRecvInt(msg As String) As Long
    SendCmdRecvInt = Send(msg)
End Function

Function quickCall(msg As quickCallMessages, Optional arg1 As Long = 0) As Long
    
    If IsWindow(RemoteHWND) = 0 Then
        Form1.List1.AddItem "SendData Invalid hwnd: " & RemoteHWND
        Form1.lblIDB.caption = "Current DB (Null)"
        Exit Function
    End If
    
    quickCall = SendMessageByVal(RemoteHWND, IDA_QUICKCALL_MESSAGE, msg, arg1)
End Function

Function Send(msg As String) As Long
    On Error Resume Next
    
    DataIn = Empty
    Dim buffer(1 To 2048) As Byte
    Dim CopyData As COPYDATASTRUCT
    
    If IsWindow(RemoteHWND) = 0 Then
        Form1.List1.AddItem "SendData Invalid hwnd: " & RemoteHWND
        Form1.lblIDB.caption = "Current DB (Null)"
        Exit Function
    End If
    
    Form1.List1.AddItem "SendData: " & msg
    
    CopyMemory buffer(1), ByVal msg, Len(msg)
    CopyData.dwFlag = 3
    CopyData.cbSize = Len(msg) + 1
    CopyData.lpData = VarPtr(buffer(1))
    Send = SendMessage(RemoteHWND, WM_COPYDATA, RemoteHWND, CopyData)
    
End Function

'finds a client by reg name lookup, sets it as remoteHWND if found
Function FindClient(client As String) As Boolean
    Dim hwnd As Long
    On Error Resume Next
    hwnd = CLng(GetSetting("IPC", "Handles", client, 0))
    If hwnd <> 0 Then
        If IsWindow(hwnd) = 1 Then
            FindClient = True
            RemoteHWND = hwnd
        Else
            SaveSetting "IPC", "Handles", client, 0
            RemoteHWND = 0
            FindClient = False
        End If
    End If
End Function


Private Sub Class_Initialize()
    Set sc = New clsSubClass
End Sub

Function ShutDown()
    isListening = False
    sc.DetatchMessage subclassed_hwnd, WM_COPYDATA
    sc.DetatchMessage subclassed_hwnd, IDASRVR_BROADCAST_MESSAGE
End Function

Private Sub sc_MessageReceived(hwnd As Long, wMsg As Long, wParam As Long, lParam As Long, Cancel As Boolean)
      
      Dim msg As String
    
      If wMsg = IDASRVR_BROADCAST_MESSAGE Then
        If IsWindow(lParam) = 1 Then
            If Not KeyExistsInCollection(Servers, "hwnd:" & lParam) Then
                Servers.Add lParam, "hwnd:" & lParam
            End If
        End If
     End If
     
      If wMsg = WM_COPYDATA Then
            If RecieveTextMessage(lParam, msg) Then
                If msg = "DONE" Then msg = Empty
                DataIn = DataIn & msg
            End If
      End If
            
End Sub

Private Function RecieveTextMessage(lParam As Long, ByRef msg As String) As Boolean
   
    Dim CopyData As COPYDATASTRUCT
    Dim buffer(1 To 2048) As Byte
    Dim temp As String
    
    msg = Empty
    
    CopyMemory CopyData, ByVal lParam, Len(CopyData)
    
    If CopyData.dwFlag = 3 Then
        CopyMemory buffer(1), ByVal CopyData.lpData, CopyData.cbSize
        temp = StrConv(buffer, vbUnicode)
        temp = Left$(temp, InStr(1, temp, Chr$(0)) - 1)
        'heres where we work with the intercepted message
        msg = temp
        RecieveTextMessage = True
        Form1.List1.AddItem "RecvData: " & msg
    End If
    
End Function

 
