Attribute VB_Name = "modGeneral"
Option Explicit

Private Declare Function GetModuleFileName Lib "kernel32" Alias "GetModuleFileNameA" (ByVal hModule As Long, ByVal lpFileName As String, ByVal nSize As Long) As Long
Private Declare Function GetModuleHandle Lib "kernel32" Alias "GetModuleHandleA" (ByVal lpModuleName As String) As Long
Private Declare Function LoadLibrary Lib "kernel32" Alias "LoadLibraryA" (ByVal lpLibFileName As String) As Long

Public hUtypes As Long
Public uTypesPath As String

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

Sub push(ary, Value) 'this modifies parent ary object
    On Error GoTo Init
    Dim X
       
    X = UBound(ary)
    ReDim Preserve ary(X + 1)
    
    If IsObject(Value) Then
        Set ary(X + 1) = Value
    Else
        ary(X + 1) = Value
    End If
    
    Exit Sub
Init:
    ReDim ary(0)
    If IsObject(Value) Then
        Set ary(0) = Value
    Else
        ary(0) = Value
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
