Attribute VB_Name = "modGeneral"
Option Explicit
Private Declare Function GetTickCount Lib "kernel32" () As Long
Private Declare Sub SetWindowPos Lib "user32" (ByVal hwnd As Long, ByVal hWndInsertAfter As Long, ByVal x As Long, ByVal Y As Long, ByVal cx As Long, ByVal cy As Long, ByVal wFlags As Long)
Private Declare Function GetModuleFileName Lib "kernel32" Alias "GetModuleFileNameA" (ByVal hModule As Long, ByVal lpFileName As String, ByVal nSize As Long) As Long
Private Declare Function GetModuleHandle Lib "kernel32" Alias "GetModuleHandleA" (ByVal lpModuleName As String) As Long
Private Declare Function LoadLibrary Lib "kernel32" Alias "LoadLibraryA" (ByVal lpLibFileName As String) As Long
Private Const HWND_TOPMOST = -1
Private Const HWND_NOTOPMOST = -2

Public hUtypes As Long
Public uTypesPath As String
Private startTime As Long


Sub StartBenchMark(Optional ByRef t As Long = -111)
    If t = -111 Then
        startTime = GetTickCount()
    Else
        t = GetTickCount()
    End If
End Sub

Function EndBenchMark(Optional ByRef t As Long = -111) As String
    Dim endTime As Long, loadTime As Long
    endTime = GetTickCount()
    If t = -111 Then
        loadTime = endTime - startTime
    Else
        loadTime = endTime - t
    End If
    EndBenchMark = loadTime / 1000 & " seconds"
End Function


Function cCLng(x) As Long
    On Error Resume Next
    cCLng = CLng(Replace(x, "0x", "&h"))
End Function

Function TopMost(frm As Object, Optional ontop As Boolean = True)
    On Error Resume Next
    Dim s
    s = IIf(ontop, HWND_TOPMOST, HWND_NOTOPMOST)
    SetWindowPos frm.hwnd, s, frm.Left / 15, frm.top / 15, frm.Width / 15, frm.Height / 15, 0
End Function

Function Rpad(v, Optional L As Long = 8, Optional char As String = " ")
    On Error GoTo hell
    Dim x As Long
    x = Len(v)
    If x < L Then
        Rpad = v & String(L - x, char)
    Else
hell:
        Rpad = v
    End If
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
