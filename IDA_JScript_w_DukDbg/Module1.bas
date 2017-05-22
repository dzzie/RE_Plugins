Attribute VB_Name = "Module1"
 Public Type LARGE_INTEGER
    lowpart As Long
    highpart As Long
End Type

Public Enum hexOutFormats
    hoDump
    hoSpaced
    hoHexOnly
End Enum

Public Enum InputFormats
    ifHex = 1
    ifDecimal = 2
    ifString = 3
'    ifHexDump = 4
End Enum

Public Declare Function QueryPerformanceCounter Lib "kernel32" (lpPerformanceCount As LARGE_INTEGER) As Long
Declare Function IsWindow Lib "user32" (ByVal hwnd As Long) As Long
Global dlg As New vbDevKit.clsCmnDlg2
Global fso As New CFileSystem2

Sub FormPos(fform As Form, Optional andSize As Boolean = False, Optional save_mode As Boolean = False)
    
    On Error Resume Next
    
    Dim f, sz
    f = Split(",Left,Top,Height,Width", ",")
    
    If fform.WindowState = vbMinimized Then Exit Sub
    If andSize = False Then sz = 2 Else sz = 4
    
    For i = 1 To sz
        If save_mode Then
            ff = CallByName(fform, f(i), VbGet)
            SaveSetting App.EXEName, fform.name & ".FormPos", f(i), ff
        Else
            def = CallByName(fform, f(i), VbGet)
            ff = GetSetting(App.EXEName, fform.name & ".FormPos", f(i), def)
            CallByName fform, f(i), VbLet, ff
        End If
    Next
    
End Sub

Sub SaveMySetting(key, value)
    SaveSetting App.EXEName, "Settings", key, value
End Sub

Function GetMySetting(key, Optional defaultval = "")
    GetMySetting = GetSetting(App.EXEName, "Settings", key, defaultval)
End Function

Function KeyExistsInCollection(c As Collection, val As String) As Boolean
    On Error GoTo nope
    Dim t
    t = c(val)
    KeyExistsInCollection = True
 Exit Function
nope: KeyExistsInCollection = False
End Function

Sub push(ary, value) 'this modifies parent ary object
    On Error GoTo init
    x = UBound(ary) '<-throws Error If Not initalized
    ReDim Preserve ary(UBound(ary) + 1)
    ary(UBound(ary)) = value
    Exit Sub
init:     ReDim ary(0): ary(0) = value
End Sub

Function FirstOccurance(it, ByVal csvFind As String, ByRef outFoundVal) As Long
    If Len(csvFind) = 0 Then Exit Function
    
    Dim find() As String, x, lowestOffset As Long, lowestIndex As Long, i As Long, a As Long
    
    outFoundVal = Empty
    lowestOffset = MAX_LONG
    find = Split(csvFind, ",")
    
    For i = 0 To UBound(find)
        If Len(find(i)) = 0 Then find(i) = ","
        a = InStr(1, it, find(i), vbTextCompare)
        If a > 0 And a < lowestOffset Then
            lowestOffset = a
            lowestIndex = i
        End If
    Next
    
    If lowestOffset = MAX_LONG Then Exit Function
    
    outFoundVal = find(lowestIndex)
    FirstOccurance = lowestOffset
    
End Function

Public Function isHexChar(hexValue As String, Optional b As Byte) As Boolean
    On Error Resume Next
    Dim v As Long
    
    If Len(hexValue) = 0 Then GoTo nope
    If Len(hexValue) > 2 Then GoTo nope 'expecting hex char code like FF or 90
    
    v = CLng("&h" & hexValue)
    If Err.Number <> 0 Then GoTo nope 'invalid hex code
    
    b = CByte(v)
    If Err.Number <> 0 Then GoTo nope  'shouldnt happen.. > 255 cant be with len() <=2 ?

    isHexChar = True
    
    Exit Function
nope:
    Err.Clear
    isHexChar = False
End Function

Function hexDump(bAryOrStrData, Optional ByVal length As Long = -1, Optional ByVal startAt As Long = 1, Optional hexFormat As hexOutFormats = hoDump) As String
    Dim s() As String, chars As String, tmp As String
    On Error Resume Next
    Dim ary() As Byte
    Dim offset As Long
    Const LANG_US = &H409
    Dim i As Long, tt, h, x
    Dim hexOnly As Long
    
    offset = 0
    If hexFormat <> hoDump Then hexOnly = 1
    
    If TypeName(bAryOrStrData) = "Byte()" Then
        ary() = bAryOrStrData
    Else
        ary = StrConv(CStr(bAryOrStrData), vbFromUnicode, LANG_US)
    End If
    
    If startAt < 1 Then startAt = 1
    If length < 1 Then length = -1
    
    While startAt Mod 16 <> 0
        startAt = startAt - 1
    Wend
    
    startAt = startAt + 1
    
    chars = "   "
    For i = startAt To UBound(ary) + 1
        tt = Hex(ary(i - 1))
        If Len(tt) = 1 Then tt = "0" & tt
        tmp = tmp & tt & " "
        x = ary(i - 1)
        'chars = chars & IIf((x > 32 And x < 127) Or x > 191, Chr(x), ".") 'x > 191 causes \x0 problems on non us systems... asc(chr(x)) = 0
        chars = chars & IIf((x > 32 And x < 127), Chr(x), ".")
        If i > 1 And i Mod 16 = 0 Then
            h = Hex(offset)
            While Len(h) < 6: h = "0" & h: Wend
            If hexOnly = 0 Then
                push s, h & "   " & tmp & chars
            Else
                push s, tmp
            End If
            offset = offset + 16
            tmp = Empty
            chars = "   "
        End If
        If length <> -1 Then
            length = length - 1
            If length = 0 Then Exit For
        End If
    Next
    
    'if read length was not mod 16=0 then
    'we have part of line to account for
    If tmp <> Empty Then
        If hexOnly = 0 Then
            h = Hex(offset)
            While Len(h) < 6: h = "0" & h: Wend
            h = h & "   " & tmp
            While Len(h) <= 56: h = h & " ": Wend
            push s, h & chars
        Else
            push s, tmp
        End If
    End If
    
    hexDump = Join(s, vbCrLf)
    
    If hexOnly <> 0 Then
        If hexFormat = hoHexOnly Then hexDump = Replace(hexDump, " ", "")
        hexDump = Replace(hexDump, vbCrLf, "")
    End If
    
End Function

Public Function toBytes(ByVal hexstr, ByRef outVar, Optional ByVal inputformat As InputFormats = ifHex) As Boolean

'supports:
'11 22 33 44   spaced hex chars
'11223344      run together hex strings
'11,22,33,44   csv hex
'1,2,3,4       csv hex with no lead 0
'121,99,44,255 decimal csv or spaced values
'%xx%yy
'%uxxxx\u7766
'%u6162%63
'isDecimal flag requires csv or spaced values..
'ignores common C source prefixes and characters

    Dim ret As String, x As String, str As String
    Dim r() As Byte, b As Byte, b1 As Byte
    Dim foundDecimal As Boolean, tmp, i, a, a2
    Dim pos As Long, marker As String
    
    On Error GoTo hell
    
'    If inputformat = ifHexDump Then
'        x = ExtractHexFromDump(hexstr)      'returns just the hex string
'        If Not toBytes(x, r) Then GoTo hell 'now we convert it to actual bytes..
'        GoTo retNow
'    End If
    
    If inputformat = ifString Then
        r() = StrConv(hexstr, vbFromUnicode, LANG_US)
        GoTo retNow
    End If
    
    str = Replace(hexstr, vbCr, Empty)
    str = Replace(str, vbLf, Empty)
    str = Replace(str, vbTab, Empty)
    str = Replace(str, Chr(0), Empty)
    str = Replace(str, "{", Empty)
    str = Replace(str, "}", Empty)
    str = Replace(str, ";", Empty)
    str = Replace(str, "+", Empty)
    str = Replace(str, """""", Empty)
    str = Replace(str, "'", Empty)
    hexstr = str
    
    If InStr(hexstr, "\u") > 0 Then hexstr = Replace(hexstr, "\u", "%u")
    
    If InStr(hexstr, "%u") > 0 Then
        tmp = Split(hexstr, "%u")
        For i = 1 To UBound(tmp)
            a = InStr(tmp(i), "%")
            x = ""
            If a > 1 Then
                x = Mid(tmp(i), a)
                tmp(i) = Mid(tmp(i), 1, a - 1)
            End If
            If Len(tmp(i)) = 3 Then tmp(i) = "0" & tmp(i)
            If Len(tmp(i)) = 4 Then
                a = Mid(tmp(i), 1, 2)
                a2 = Mid(tmp(i), 3, 2)
                tmp(i) = a2 & a
            End If
            If Len(x) > 0 Then tmp(i) = tmp(i) & x
        Next
        hexstr = Join(tmp, "")
    End If
    
    If InStr(hexstr, "%") > 0 Then
        tmp = Split(hexstr, "%")
        For i = 1 To UBound(tmp)
            If Len(tmp(i)) < 2 Then
                tmp(i) = 0 & tmp(i)
            End If
        Next
        hexstr = Join(tmp, "")
    End If
    
    If Len(hexstr) > 4 Then
        pos = FirstOccurance(hexstr, " ,", marker)
        If pos > 0 And pos < 5 Then   'make sure all are double digit hex chars...(also account for decimal 1,11,111,
            tmp = Split(hexstr, marker)
            
            If inputformat = ifDecimal Then
                For i = 0 To UBound(tmp)
                    tmp(i) = Hex(CLng(tmp(i)))
                Next
            End If
            
            For i = 0 To UBound(tmp)
                If Len(tmp(i)) = 1 Then tmp(i) = "0" & tmp(i)
            Next
            
            hexstr = Join(tmp, "")
        End If
    End If
        
    str = Replace(hexstr, " ", Empty)
    str = Replace(str, "0x", Empty)
    str = Replace(str, ",", Empty)
    
    For i = 1 To Len(str) Step 2
        x = Mid(str, i, 2)
        If Not isHexChar(x, b) Then Exit Function
        bpush r(), b
    Next
    
retNow:
    If TypeName(outVar) = "Byte()" Then
        outVar = r
    Else
        outVar = StrConv(r, vbUnicode, LANG_US)
    End If
    
    toBytes = True
    Exit Function
    
hell:
    toBytes = False
    
End Function


Private Sub bpush(bAry() As Byte, b As Byte) 'this modifies parent ary object
    On Error GoTo init
    Dim x As Long
    
    x = UBound(bAry) '<-throws Error If Not initalized
    ReDim Preserve bAry(UBound(bAry) + 1)
    bAry(UBound(bAry)) = b
    
    Exit Sub

init:
    ReDim bAry(0)
    bAry(0) = b
    
End Sub
