Attribute VB_Name = "Module1"
'now in CIPC

Private Declare Sub SetWindowPos Lib "user32" (ByVal hwnd As Long, ByVal hWndInsertAfter As Long, ByVal x As Long, ByVal y As Long, ByVal cx As Long, ByVal cy As Long, ByVal wFlags As Long)
Private Declare Function GetModuleFileName Lib "kernel32" Alias "GetModuleFileNameA" (ByVal hModule As Long, ByVal lpFileName As String, ByVal nSize As Long) As Long
Private Declare Function GetModuleHandle Lib "kernel32" Alias "GetModuleHandleA" (ByVal lpModuleName As String) As Long
Private Declare Function LoadLibrary Lib "kernel32" Alias "LoadLibraryA" (ByVal lpLibFileName As String) As Long
Declare Function IsWindow Lib "user32" (ByVal hwnd As Long) As Long

Private Const HWND_TOPMOST = -1
Private Const HWND_NOTOPMOST = -2

Public hUtypes As Long
Public uTypesPath As String


'Private Type COPYDATASTRUCT
'    dwFlag As Long
'    cbSize As Long
'    lpData As Long
'End Type
'
'Public Type LARGE_INTEGER
'    lowpart As Long
'    highpart As Long
'End Type
'
' Public Const GWL_WNDPROC = (-4)
' Public Const WM_COPYDATA = &H4A
' Global lpPrevWndProc As Long
' Global SUBCLASSED_HWND As Long
' Global IDA_HWND As Long
' Global ResponseBuffer As String
'
' Private Declare Sub CopyMemory Lib "kernel32" Alias "RtlMoveMemory" (hpvDest As Any, hpvSource As Any, ByVal cbCopy As Long)
' Private Declare Function CallWindowProc Lib "user32" Alias "CallWindowProcA" (ByVal lpPrevWndFunc As Long, ByVal hwnd As Long, ByVal msg As Long, ByVal wParam As Long, ByVal lParam As Long) As Long
' Private Declare Function SetWindowLong Lib "user32" Alias "SetWindowLongA" (ByVal hwnd As Long, ByVal nIndex As Long, ByVal dwNewLong As Long) As Long
' Private Declare Function SendMessage Lib "user32" Alias "SendMessageA" (ByVal hwnd As Long, ByVal wMsg As Long, ByVal wParam As Long, lParam As Any) As Long
' Public Declare Function SendMessageByVal Lib "user32" Alias "SendMessageA" (ByVal hwnd As Long, ByVal wMsg As Long, ByVal wParam As Long, ByVal lParam As Any) As Long
' Declare Function IsWindow Lib "user32" (ByVal hwnd As Long) As Long
' Private Declare Function RegisterWindowMessage Lib "user32" Alias "RegisterWindowMessageA" (ByVal lpString As String) As Long
' Public Declare Function SendMessageTimeout Lib "user32" Alias "SendMessageTimeoutA" (ByVal hwnd As Long, ByVal msg As Long, ByVal wParam As Long, ByVal lParam As Long, ByVal fuFlags As Long, ByVal uTimeout As Long, lpdwResult As Long) As Long
' Public Declare Function QueryPerformanceCounter Lib "kernel32" (lpPerformanceCount As LARGE_INTEGER) As Long
'
' Private Const HWND_BROADCAST = &HFFFF&
'
' Public IDA_QUICKCALL_MESSAGE As Long
' Private IDASRVR_BROADCAST_MESSAGE As Long
' Public Servers As New Collection
'
'
'
' Public Sub Hook(hwnd As Long)
'     SUBCLASSED_HWND = hwnd
'     lpPrevWndProc = SetWindowLong(SUBCLASSED_HWND, GWL_WNDPROC, AddressOf WindowProc)
'     IDASRVR_BROADCAST_MESSAGE = RegisterWindowMessage("IDA_SERVER2")
'     IDA_QUICKCALL_MESSAGE = RegisterWindowMessage("IDA_QUICKCALL2")
' End Sub
'
' Function FindActiveIDAWindows() As Long
'     Dim ret As Long
'     'so a client starts up, it gets the message to use (system wide) and it broadcasts a message to all windows
'     'looking for IDASrvr instances that are active. It passes its command window hwnd as wParam
'     'IDASrvr windows will receive this, and respond to the HWND with the same IDASRVR message as a pingback
'     'sending thier command window hwnd as the lParam to register themselves with the clients.
'     'clients track these hwnds.
'
'     'Form1.List2.AddItem "Broadcasting message looking for IDASrvr instances msg= " & IDASRVR_BROADCAST_MESSAGE
'     SendMessageTimeout HWND_BROADCAST, IDASRVR_BROADCAST_MESSAGE, SUBCLASSED_HWND, 0, 0, 100, ret
'
'     ValidateActiveIDAWindows
'     FindActiveIDAWindows = Servers.Count
'
' End Function
'
' Function ValidateActiveIDAWindows()
'     On Error Resume Next
'     Dim x
'     For Each x In Servers 'remove any that arent still valid..
'        If IsWindow(x) = 0 Then
'            Servers.Remove "hwnd:" & x
'        End If
'     Next
' End Function
'
' Public Sub Unhook()
'     If lpPrevWndProc <> 0 And SUBCLASSED_HWND <> 0 Then
'            SetWindowLong SUBCLASSED_HWND, GWL_WNDPROC, lpPrevWndProc
'     End If
' End Sub
'
' Function WindowProc(ByVal hw As Long, ByVal uMsg As Long, ByVal wParam As Long, ByVal lParam As Long) As Long
'
'     If uMsg = IDASRVR_BROADCAST_MESSAGE Then
'        If IsWindow(lParam) = 1 Then
'            If Not KeyExistsInCollection(Servers, "hwnd:" & lParam) Then
'                Servers.add lParam, "hwnd:" & lParam
'                'Form1.List2.AddItem "New IDASrvr registering itself hwnd= " & lParam
'            End If
'        End If
'     End If
'
'     If uMsg = WM_COPYDATA Then RecieveTextMessage lParam
'     WindowProc = CallWindowProc(lpPrevWndProc, hw, uMsg, wParam, lParam)
'
' End Function
'
'Function KeyExistsInCollection(c As Collection, val As String) As Boolean
'    On Error GoTo nope
'    Dim t
'    t = c(val)
'    KeyExistsInCollection = True
' Exit Function
'nope: KeyExistsInCollection = False
'End Function
'
'Private Sub RecieveTextMessage(lParam As Long)
'
'    Dim CopyData As COPYDATASTRUCT
'    Dim Buffer(1 To 2048) As Byte
'    Dim Temp As String
'    Dim lpData As Long
'    Dim sz As Long
'    Dim tmp() As Byte
'    ReDim tmp(30)
'
'    CopyMemory CopyData, ByVal lParam, Len(CopyData)
'
'    If CopyData.dwFlag = 3 Then
'
'        CopyMemory tmp(0), ByVal lParam, Len(CopyData)
'        'Text1 = HexDump(tmp, Len(CopyData))
'
'        lpData = CopyData.lpData
'        sz = CopyData.cbSize
'
'        CopyMemory Buffer(1), ByVal lpData, sz
'        Temp = StrConv(Buffer, vbUnicode)
'        Temp = Left$(Temp, InStr(1, Temp, Chr$(0)) - 1)
'        'heres where we work with the intercepted message
'        'Form1.List2.AddItem "Recv(" & Temp & ")"
'        'Form1.List2.AddItem ""
'        ResponseBuffer = Temp
'    End If
'
'End Sub
'
' 'returns the SendMessage return value which can be an int response.
'Function SendCMD(msg As String, Optional ByVal hwnd As Long) As Long
'    Dim cds As COPYDATASTRUCT
'    Dim buf(1 To 255) As Byte
'
'    If hwnd = 0 Then hwnd = IDA_HWND
'
'    ResponseBuffer = Empty
'    'Form1.List2.AddItem "SendingCMD(hwnd=" & hwnd & ", msg=" & msg & ")"
'
'    Call CopyMemory(buf(1), ByVal msg, Len(msg))
'    cds.dwFlag = 3
'    cds.cbSize = Len(msg) + 1
'    cds.lpData = VarPtr(buf(1))
'    SendCMD = SendMessage(hwnd, WM_COPYDATA, SUBCLASSED_HWND, cds)
'    'since SendMessage is syncrnous if the command has a response it will be received before this returns..
'
'End Function

Function cCLng(x) As Long
    On Error Resume Next
    cCLng = CLng(Replace(x, "0x", "&h"))
End Function

Function KeyExistsInCollection(c As Collection, val As String) As Boolean
    On Error GoTo nope
    Dim t
    t = c(val)
    KeyExistsInCollection = True
 Exit Function
nope: KeyExistsInCollection = False
End Function

Function isIde() As Boolean
    On Error GoTo out
    Debug.Print 1 / 0
out: isIde = Err
End Function

Function ensureUTypes() As Boolean
    
    On Error Resume Next
    
    If hUtypes <> 0 Then
        ensureUTypes = True
        Exit Function
    End If
    
    Dim pth As String, b() As Byte, f As Long
    Dim thisDll As String, pd(), parentDir
    
    thisDll = GetDllPath("vbUtypes.dll")
    If Len(thisDll) > 0 Then push pd, GetParentFolder(thisDll)
    push pd, App.path
    push pd, Environ("WinDir")
    push pd, App.path & "\binary_snapshot"
    
    For Each parentDir In pd
        pth = parentDir & "\UTypes.dll"
        If Not FileExists(pth) Then pth = parentDir & "\UTypes.dll"
        If Not FileExists(pth) Then pth = parentDir & "\..\UTypes.dll"
        If Not FileExists(pth) Then pth = parentDir & "\..\..\UTypes.dll"
        If Not FileExists(pth) Then pth = parentDir & "\..\..\..\UTypes.dll"
        If FileExists(pth) Then Exit For
    Next
    
'    If Not FileExists(pth) Then

'        pth = App.path & "\UTypes.dll"
'        b() = LoadResData("UTYPES", "DLLS")
'        If AryIsEmpty(b) Then
'            MsgBox "Failed to find UTypes.dll in resource?"
'            Exit Function
'        End If
'
'        f = FreeFile
'        Open pth For Binary As f
'        Put f, , b()
'        Close f
        
        'MsgBox "Dropped utypes.dll to: " & pth & " - Err: " & Err.Number
'    End If
  
    hUtypes = LoadLibrary(pth)
    If hUtypes = 0 Then Exit Function

    uTypesPath = pth
    ensureUTypes = True
    
End Function

Public Function GetDllPath(Optional dll As String = "vbUtypes.dll") As String
     Dim h As Long, ret As String
     ret = Space(500)
     h = GetModuleHandle(dll)
     h = GetModuleFileName(h, ret, 500)
     If h > 0 Then ret = Mid(ret, 1, h)
     GetDllPath = ret
End Function

Sub push(ary, value) 'this modifies parent ary object
    On Error GoTo init
    Dim x
       
    x = UBound(ary)
    ReDim Preserve ary(x + 1)
    
    If IsObject(value) Then
        Set ary(x + 1) = value
    Else
        ary(x + 1) = value
    End If
    
    Exit Sub
init:
    ReDim ary(0)
    If IsObject(value) Then
        Set ary(0) = value
    Else
        ary(0) = value
    End If
End Sub

Function ReadFile(filename) As Variant
  Dim f As Long
  Dim Temp As Variant
  f = FreeFile
  Temp = ""
   Open filename For Binary As #f        ' Open file.(can be text or image)
     Temp = Input(FileLen(filename), #f) ' Get entire Files data
   Close #f
   ReadFile = Temp
End Function

Sub WriteFile(path As String, it As Variant)
    Dim f As Long
    f = FreeFile
    Open path For Output As #f
    Print #f, it
    Close f
End Sub

Sub AppendFile(path, it)
    Dim f As Long
    f = FreeFile
    Open path For Append As #f
    Print #f, it
    Close f
End Sub

Function GetParentFolder(path, Optional levelUp = 1)
    Dim tmp() As String
    Dim my_path
    Dim ub As String, i As Long
    
    On Error GoTo hell
    If Len(path) = 0 Then Exit Function
    If levelUp < 1 Then levelUp = 1
    
    my_path = path
    While Len(my_path) > 0 And Right(my_path, 1) = "\"
        my_path = Mid(my_path, 1, Len(my_path) - 1)
    Wend
    
    tmp = Split(my_path, "\")
    If levelUp > UBound(tmp) Then levelUp = UBound(tmp)
    
    For i = 0 To levelUp - 1
        If InStr(tmp(UBound(tmp) - i), ":") < 1 Then tmp(UBound(tmp) - i) = Empty
    Next
    
    my_path = Join(tmp, "\")
    While Len(my_path) > 0 And Right(my_path, 1) = "\"
        my_path = Mid(my_path, 1, Len(my_path) - 1)
    Wend
        
    GetParentFolder = my_path
    Exit Function
    
hell:
    GetParentFolder = Empty
    
End Function

Function FileExists(path) As Boolean
  On Error GoTo hell
    
  If Len(path) = 0 Then Exit Function
  If Right(path, 1) = "\" Then Exit Function
  If InStr(path, Chr(0)) > 0 Then Exit Function
  If Dir(path, vbHidden Or vbNormal Or vbReadOnly Or vbSystem) <> "" Then FileExists = True
  
  Exit Function
hell: FileExists = False
End Function

Function FolderExists(path) As Boolean
  If Len(path) = 0 Then Exit Function
  If Dir(path, vbDirectory) <> "" Then FolderExists = True _
  Else FolderExists = False
End Function

Function DeleteFile(fpath As String) As Boolean
 On Error GoTo hadErr
    Kill fpath
    DeleteFile = True
 Exit Function
hadErr:
'MsgBox "DeleteFile Failed" & vbCrLf & vbCrLf & fpath
DeleteFile = False
End Function

Function FileNameFromPath(fullpath) As String
    If InStr(fullpath, "\") > 0 Then
        tmp = Split(fullpath, "\")
        FileNameFromPath = CStr(tmp(UBound(tmp)))
    End If
End Function

Function GetFreeFileName(folder, Optional extension = ".txt") As String
    
    If Not FolderExists(folder) Then Exit Function
    If Right(folder, 1) <> "\" Then folder = folder & "\"
    If Left(extension, 1) <> "." Then extension = "." & extension
    
    Dim tmp As String
    Do
      tmp = folder & RandomNum() & extension
    Loop Until Not FileExists(tmp)
    
    GetFreeFileName = tmp
End Function

Function RandomNum() As Long
    Dim tmp As Long
    Dim tries As Long
    
    On Error Resume Next

    Do While 1
        Err.Clear
        Randomize
        tmp = Round(Timer * Now * Rnd(), 0)
        RandomNum = tmp
        If Err.Number = 0 Then Exit Function
        If tries < 100 Then
            tries = tries + 1
        Else
            Exit Do
        End If
    Loop
    
    RandomNum = GetTickCount
    
End Function



