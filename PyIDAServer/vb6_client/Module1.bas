Attribute VB_Name = "Module1"
Option Explicit
'this was all ripped from IDASrvr, in turn ripped from my even older IPC demos

Private Type COPYDATASTRUCT
    dwFlag As Long
    cbSize As Long
    lpData As Long
End Type

Public Type LARGE_INTEGER
    lowpart As Long
    highpart As Long
End Type

 Public Const GWL_WNDPROC = (-4)
 Public Const WM_COPYDATA = &H4A
 Global lpPrevWndProc As Long
 Global subclassed_hwnd As Long
 Global IDA_HWND As Long
 Global ResponseBuffer As String
 
 Private Declare Sub CopyMemory Lib "kernel32" Alias "RtlMoveMemory" (hpvDest As Any, hpvSource As Any, ByVal cbCopy As Long)
 Private Declare Function CallWindowProc Lib "user32" Alias "CallWindowProcA" (ByVal lpPrevWndFunc As Long, ByVal hwnd As Long, ByVal msg As Long, ByVal wParam As Long, ByVal lParam As Long) As Long
 Private Declare Function SetWindowLong Lib "user32" Alias "SetWindowLongA" (ByVal hwnd As Long, ByVal nIndex As Long, ByVal dwNewLong As Long) As Long
 Private Declare Function SendMessage Lib "user32" Alias "SendMessageA" (ByVal hwnd As Long, ByVal wMsg As Long, ByVal wParam As Long, lParam As Any) As Long
 Private Declare Function SendMessageByVal Lib "user32" Alias "SendMessageA" (ByVal hwnd As Long, ByVal wMsg As Long, ByVal wParam As Long, ByVal lParam As Any) As Long
 Declare Function IsWindow Lib "user32" (ByVal hwnd As Long) As Long
 Private Declare Function RegisterWindowMessage Lib "user32" Alias "RegisterWindowMessageA" (ByVal lpString As String) As Long
 Private Declare Function SendMessageTimeout Lib "user32" Alias "SendMessageTimeoutA" (ByVal hwnd As Long, ByVal msg As Long, ByVal wParam As Long, ByVal lParam As Long, ByVal fuFlags As Long, ByVal uTimeout As Long, lpdwResult As Long) As Long
 Public Declare Function QueryPerformanceCounter Lib "kernel32" (lpPerformanceCount As LARGE_INTEGER) As Long

 Private Const HWND_BROADCAST = &HFFFF&
 Private PYIDA_QUICKCALL_MESSAGE As Long
 Private PYIDASRVR_BROADCAST_MESSAGE As Long
 Public Servers As New Collection
 
Function d(msg, Optional isList2 As Boolean)
    Dim l As ListBox
    Set l = IIf(isList2, Form1.List2, Form1.List1)
    l.AddItem msg
    l.ListIndex = l.ListCount - 1
End Function

Function BenchMark() As Long
    Dim i As LARGE_INTEGER
    QueryPerformanceCounter i
    BenchMark = i.lowpart
End Function

 Public Sub Hook(hwnd As Long)
     subclassed_hwnd = hwnd
     lpPrevWndProc = SetWindowLong(subclassed_hwnd, GWL_WNDPROC, AddressOf WindowProc)
     PYIDASRVR_BROADCAST_MESSAGE = RegisterWindowMessage("PYIDA_SERVER")
     PYIDA_QUICKCALL_MESSAGE = RegisterWindowMessage("PYIDA_QUICKCALL")
     'Form1.List1.AddItem "QuickCall: " & Hex(PYIDA_QUICKCALL_MESSAGE) & " Broadcast: " & Hex(PYIDASRVR_BROADCAST_MESSAGE)
 End Sub


 'will find last opened instance if still active
Function FindClient() As Boolean
    Dim hwnd As Long
    
    On Error Resume Next
    
    hwnd = CLng(GetSetting("IPC", "Handles", "PIDA_SERVER", 0))
    If hwnd <> 0 Then
        If IsWindow(hwnd) = 1 Then
            FindClient = True
            Module1.IDA_HWND = hwnd
        Else
            SaveSetting "IPC", "Handles", "PIDA_SERVER", 0
            Module1.IDA_HWND = 0
            FindClient = False
        End If
    End If
    
End Function

'enumerates all open instances, returns count, access hwnds through servers collection
 Function FindActive_PYIDAWindows() As Long
     Dim ret As Long
     'so a client starts up, it gets the message to use (system wide) and it broadcasts a message to all windows
     'looking for IDASrvr instances that are active. It passes its command window hwnd as wParam
     'IDASrvr windows will receive this, and respond to the HWND with the same IDASRVR message as a pingback
     'sending thier command window hwnd as the lParam to register themselves with the clients.
     'clients track these hwnds.

     Form1.List2.AddItem "Broadcasting message looking for IDASrvr instances msg= " & PYIDASRVR_BROADCAST_MESSAGE
     SendMessageTimeout HWND_BROADCAST, PYIDASRVR_BROADCAST_MESSAGE, subclassed_hwnd, 0, 0, 100, ret

     ValidateActiveIDAWindows
     FindActive_PYIDAWindows = Servers.Count

 End Function

 Function ValidateActiveIDAWindows()
     On Error Resume Next
     Dim x
     For Each x In Servers 'remove any that arent still valid..
        If IsWindow(x) = 0 Then
            Servers.Remove "hwnd:" & x
        End If
     Next
 End Function
 
 Public Sub Unhook()
     If lpPrevWndProc <> 0 And subclassed_hwnd <> 0 Then
            SetWindowLong subclassed_hwnd, GWL_WNDPROC, lpPrevWndProc
     End If
 End Sub

 Function WindowProc(ByVal hw As Long, ByVal uMsg As Long, ByVal wParam As Long, ByVal lParam As Long) As Long
     
     If uMsg = PYIDASRVR_BROADCAST_MESSAGE Then
        If IsWindow(lParam) = 1 Then
            If Not KeyExistsInCollection(Servers, "hwnd:" & lParam) Then
                Servers.Add lParam, "hwnd:" & lParam
                Form1.List2.AddItem "New IDASrvr registering itself hwnd= " & lParam
            End If
        End If
     End If
     
     If uMsg = WM_COPYDATA Then RecieveTextMessage lParam
     WindowProc = CallWindowProc(lpPrevWndProc, hw, uMsg, wParam, lParam)
     
 End Function

Function KeyExistsInCollection(c As Collection, val As String) As Boolean
    On Error GoTo nope
    Dim t
    t = c(val)
    KeyExistsInCollection = True
 Exit Function
nope: KeyExistsInCollection = False
End Function

Private Sub RecieveTextMessage(lParam As Long)
   
    Dim CopyData As COPYDATASTRUCT
    Dim Buffer(1 To 2048) As Byte
    Dim Temp As String
    Dim lpData As Long
    Dim sz As Long
    Dim tmp() As Byte
    ReDim tmp(30)
    
    CopyMemory CopyData, ByVal lParam, Len(CopyData)
    
    If CopyData.dwFlag = 3 Then
    
        CopyMemory tmp(0), ByVal lParam, Len(CopyData)
        'Text1 = HexDump(tmp, Len(CopyData))
        
        lpData = CopyData.lpData
        sz = CopyData.cbSize
        
        CopyMemory Buffer(1), ByVal lpData, sz
        Temp = StrConv(Buffer, vbUnicode)
        Temp = Left$(Temp, InStr(1, Temp, Chr$(0)) - 1)
        'heres where we work with the intercepted message
        d "Recv(" & Temp & ")", 1
        d "", 1
        ResponseBuffer = Temp
    End If
     
End Sub

'returns the SendMessage return value which can be an int response.
Function SendCMD(msg As String, Optional ByVal hwnd As Long) As Long
    Dim cds As COPYDATASTRUCT
    Dim buf(1 To 255) As Byte
    
    If hwnd = 0 Then hwnd = IDA_HWND
    
    ResponseBuffer = Empty
    d "SendingCMD(hwnd=" & hwnd & ", msg=" & msg & ")", 1
    
    Call CopyMemory(buf(1), ByVal msg, Len(msg))
    cds.dwFlag = 3
    cds.cbSize = Len(msg) + 1
    cds.lpData = VarPtr(buf(1))
    SendCMD = SendMessage(hwnd, WM_COPYDATA, subclassed_hwnd, cds)
    'since SendMessage is syncrnous if the command has a response it will be received before this returns..
    
End Function

Function SendCmdRecvText(cmd As String, Optional ByVal hwnd As Long) As String
    SendCMD cmd, hwnd
    SendCmdRecvText = ResponseBuffer
End Function

Function SendCmdRecvLong(cmd As String, Optional ByVal hwnd As Long) As Long
    SendCmdRecvLong = SendCMD(cmd, hwnd)
End Function

Function QuickCall(msg As Long, Optional arg1 As Long = 0) As Long
    QuickCall = SendMessageByVal(IDA_HWND, PYIDA_QUICKCALL_MESSAGE, msg, arg1)
End Function
