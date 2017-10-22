VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "cIDAClient64"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
'allot of these are variant args because they come from IDA_JScript and scripting clients are best used with variants
'
'all 64bit address arguments are variant type which accept
'64bit number as string (hex, signed, unsigned), long, or a ULong64 class type

Option Explicit

 'quick call offers about 3x performance boost over original..
 'commented out ones are only available to a 64bit calling process
 '(32bit SendMessage API has a limitation in arg size)
 
Public Enum quickCallMessages64
'    qcmJmpAddr = 1    ' jmp:lngAdr
    qcm64JmpRVA = 7     ' jmp_rva:lng_rva
'    qcmImgBase = 8    ' imgbase
'    qcmReadByte = 10  ' readbyte:lngva
'    qcmOrgByte = 11   ' orgbyte:lngva
    qcm64Refresh = 12   ' refresh
    qcm64NumFuncs = 13  ' numfuncs
'    qcmFuncStart = 14 ' funcstart:funcIndex
'    qcmFuncEnd = 15   ' funcend:funcIndex
'    qcmUndef = 20     ' undefine:offset
'    qcmHide = 22      ' hide:offset
'    qcmShow = 23      ' show:offset
'    qcmRemName = 24   ' remname:offset
'    qcmMakeCode = 25  ' makecode:offset
'    qcmFuncIdx = 32   ' funcindex:va
'    qcmNextEa = 33    ' nextea:va
'    qcmPrevEa = 34    ' prevea:va
'    qcmScreenEA = 37  ' screenea:
    qcm64DebugMessages = 38
    qcm64DecompilerActive = 39
    qcm64FlushDecomp = 40 'flush cached decompiler results
    qcm64IDAHwnd = 41     'gets main IDA Window HWND
    qcm64GetVersion = 42  'version of interface
    qcm64SetFocusSelectLine = 43 'bring IDA to forefront and select current line
'    qcmIsCode = 44
'    qcmIsData = 45
'    qcmInstLen = 46
'    qcmReadLong = 47
'    qcmReadShort = 48
     qcm64Is64 = 49
End Enum

Property Get ActiveIDA() As Long
    ActiveIDA = IDA_HWND
End Property

Property Let ActiveIDA(v As Long)
    IDA_HWND = v
End Property

Public Sub Listen(onHwnd As Long)
    Hook onHwnd
End Sub

Private Sub Class_Terminate()
    Unhook
End Sub

Function FindHwndForIDB(filename As String, Optional refresh As Boolean = False) As Long
    
    Dim h, idb As String
    Dim curHwnd As Long
    
    If refresh Then EnumIDAWindows
    
    curHwnd = IDA_HWND
    
    
    For Each h In Servers
        idb = LoadedFile(CLng(h))
        If InStr(1, idb, filename, vbTextCompare) > 0 Then
            FindHwndForIDB = CLng(h)
            Exit For
        End If
    Next
    
    IDA_HWND = curHwnd
    
End Function

'will find last opened instance if still active
Function FindClient() As Boolean
    Dim hwnd As Long
    
    On Error Resume Next
    
    hwnd = CLng(GetSetting("IPC", "Handles", "IDA_SERVER2", 0))
    If hwnd <> 0 Then
        If IsWindow(hwnd) = 1 Then
            FindClient = True
            Module1.IDA_HWND = hwnd
        Else
            SaveSetting "IPC", "Handles", "IDA_SERVER2", 0
            Module1.IDA_HWND = 0
            FindClient = False
        End If
    End If
    
End Function

Property Get ActiveServers() As Collection
    Set ActiveServers = Servers
End Property

Function SelectServer(Optional refresh As Boolean = True) As Long
    SelectServer = Form2.SelectIDAInstance(Me, refresh)
End Function

Function EnumIDAWindows() As Long
    EnumIDAWindows = FindActiveIDAWindows()
End Function
 
'hwnd refers to ida window to target..
Function SendCmdRecvText(cmd As String, Optional ByVal hwnd As Long) As String
    SendCMD cmd, hwnd
    SendCmdRecvText = ResponseBuffer
End Function

'hwnd refers to ida window to target..
Function SendCmdRecvLong(cmd As String, Optional ByVal hwnd As Long) As ULong64
    Dim u As New ULong64, tmp As String
    tmp = SendCmdRecvText(cmd, hwnd)
    u.fromString tmp, mUnsigned
    Set SendCmdRecvLong = u
End Function

Function QuickCall(msg As quickCallMessages64, Optional arg1 As Long = 0, Optional ByVal hwnd As Long = 0) As Long
    If hwnd = 0 Then hwnd = IDA_HWND
    QuickCall = SendMessageByVal(hwnd, IDA_QUICKCALL_MESSAGE, msg, arg1)
End Function

Property Get isUp() As Boolean
    isUp = IIf(IsWindow(IDA_HWND) = 1, True, False)
End Property

Function DecompilerActive(Optional hwnd As Long) As Boolean
    DecompilerActive = IIf(QuickCall(qcmDecompilerActive, , hwnd) = 1, True, False)
End Function

Sub JumpName(name As String, Optional hwnd As Long)
    If Len(name) = 0 Then Exit Sub
    SendCMD "jmp_name:" & name, hwnd
End Sub

Function Message(msg As String)
    If Len(msg) = 0 Then Exit Function
    SendCMD "msg:" & msg
End Function

Function MakeStr(v, Optional ascii As Boolean = True)
    Dim va As New ULong64
    Set va = UlongFromVar(v)
    If va = 0 Or va = -1 Then Exit Function
    SendCMD "makestring:" & va.toString(mUnsigned) & ":" & IIf(ascii, "ascii", "unicode")
End Function

Function MakeUnk(v, size)
    Dim va As New ULong64
    Set va = UlongFromVar(v)
    If va = 0 Or va = -1 Then Exit Function
    SendCMD "makeunk:" & va.toString(mUnsigned) & ":" & size
End Function

Function LoadedFile(Optional ByVal hwnd As Long = 0) As String
    LoadedFile = SendCmdRecvText("loadedfile:" & SUBCLASSED_HWND, hwnd)
End Function

'Function PatchString(va As ULong64, str, Optional isUnicode = False)
'
'    If va = 0 Or va = -1 Then Exit Function
'
'    Dim b() As Byte, i As Long
'    b() = StrConv(str, vbFromUnicode)
'    For i = 0 To UBound(b)
'        PatchByte va, b(i)
'        If isUnicode Then PatchByte va + 1, 0
'        va = IIf(isUnicode, va + 2, va + 1)
'    Next
'
'End Function

Function PatchByte(v, newVal)
    Dim va As New ULong64
    Set va = UlongFromVar(v)
    If va = 0 Or va = -1 Then Exit Function
    If CInt(newVal) > 255 Or CInt(newVal) < 0 Then Err.Raise 1, "PatchByte", "byte value must be 0-254"
    SendCMD "patchbyte:" & va.toString(mUnsigned) & ":" & newVal
End Function



Function intToHex(x)
    On Error Resume Next
    intToHex = Hex(x)
    If Len(intToHex) = 1 Then intToHex = "0" & intToHex
    If Err.Number <> 0 Then intToHex = x 'hex can throw overflow bleh...
End Function

Function GetAsm(v)
    Dim va As New ULong64
    Set va = UlongFromVar(v)
    If va = 0 Or va = -1 Then Exit Function
    GetAsm = SendCmdRecvText("getasm:" & va.toString(mUnsigned) & ":" & SUBCLASSED_HWND)
End Function

Function XRefsTo(v) 'returns CSV list
    Dim tmp
    Dim va As New ULong64
    Set va = UlongFromVar(v)
    tmp = SendCmdRecvText("refsto:" & va.toString(mUnsigned) & ":" & SUBCLASSED_HWND)
    If Right(tmp, 1) = "," Then tmp = Mid(tmp, 1, Len(tmp) - 1)
    'tmp = Split(tmp, ",") javascript cant deal with string() must be variant()?
    XRefsTo = tmp
End Function

Function XRefsFrom(v) 'returns CSV list
    Dim tmp
    Dim va As New ULong64
    Set va = UlongFromVar(v)
    tmp = SendCmdRecvText("refsfrom:" & va.toString(mUnsigned) & ":" & SUBCLASSED_HWND)
    If Right(tmp, 1) = "," Then tmp = Mid(tmp, 1, Len(tmp) - 1)
    'tmp = Split(tmp, ",") javascript cant deal with string() must be variant()?
    XRefsFrom = tmp
End Function


Function GetName(v)
    Dim va As New ULong64
    Set va = UlongFromVar(v)
    GetName = SendCmdRecvText("getname:" & va.toString(mUnsigned) & ":" & SUBCLASSED_HWND)
    If GetName = "NULL" Then GetName = ""
End Function

 Function FunctionName(functionIndex)
    If functionIndex < 0 Then Exit Function
    FunctionName = SendCmdRecvText("funcname:" & functionIndex & ":" & SUBCLASSED_HWND)
 End Function

'
'Function HideBlock(offset, leng)
'    Dim x, i As Long
'    x = offset + leng
'    For i = offset To x
'        HideEA i
'    Next
'    refresh
'End Function

'Function ShowBlock(offset, leng)
'    Dim x, i As Long
'    x = offset + leng
'    For i = offset To x
'        ShowEA i
'    Next
'    refresh
'End Function

Sub Setname(v, name)
    Dim va As New ULong64
    Set va = UlongFromVar(v)
    If Len(name) = 0 Then Exit Sub
    SendCMD "setname:" & va.toString(mUnsigned) & ":" & CStr(name)
 End Sub

Sub AddComment(v, comment)
    Dim va As New ULong64
    Set va = UlongFromVar(v)
    SendCMD "addcomment:" & va.toString(mUnsigned) & ":" & comment
End Sub

Function GetComment(v)
    Dim va As New ULong64
    Set va = UlongFromVar(v)
    GetComment = SendCmdRecvText("getcomment:" & va.toString(mUnsigned) & ":" & SUBCLASSED_HWND)
    If GetComment = "NULL" Then GetComment = Empty
End Function


 Sub AddCodeXRef(v, tova)
    Dim va As New ULong64
    Set va = UlongFromVar(v)
    SendCMD "addcodexref:" & va.toString(mUnsigned) & ":" & tova
 End Sub
 
  Sub AddDataXRef(v, tova)
    Dim va As New ULong64
    Set va = UlongFromVar(v)
    SendCMD "adddataxref:" & va.toString(mUnsigned) & ":" & tova
 End Sub
 
 Sub DelCodeXRef(v, tova)
    Dim va As New ULong64
    Set va = UlongFromVar(v)
    SendCMD "delcodexref:" & va.toString(mUnsigned) & ":" & tova
 End Sub
 
 Sub DelDataXRef(v, tova)
    Dim va As New ULong64
    Set va = UlongFromVar(v)
    SendCMD "deldataxref:" & va.toString(mUnsigned) & ":" & tova
 End Sub
 
Function FuncVAByName(name)
    If Len(name) = 0 Then Exit Function
    Set FuncVAByName = SendCmdRecvLong("name_va:" & name)
End Function

Function RenameFunc(oldname, newName) As Boolean
    If Len(oldname) = 0 Or Len(newName) = 0 Then Exit Function
    RenameFunc = IIf(SendCmdRecvLong("rename:" & oldname & ":" & newName) = 1, True, False)
End Function

Function Find(vstartea, vendea, hexstr)   '-1 if fail
    Dim startea As New ULong64, endea  As New ULong64
    
    Set startea = UlongFromVar(vstartea)
    Set endea = UlongFromVar(vendea)
    
    If startea = 0 Or startea = -1 Then Exit Function
    If endea = 0 Or endea = -1 Then Exit Function
    If Len(hexstr) = 0 Then Exit Function
    Find = SendCmdRecvLong("findcode:" & startea.toString(mUnsigned) & ":" & endea.toString(mUnsigned) & ":" & hexstr)
End Function

Function Decompile(v) As String
    Dim pth As String, r As Long
    Dim va As New ULong64
    Set va = UlongFromVar(v)
    
    If va = 0 Or va = -1 Then Exit Function
    
    pth = Environ("temp")
    pth = GetFreeFileName(pth)
                                                        'its our token we will need to replace it latter :-\ foresight denied!
    r = SendCmdRecvLong("decompile:" & va.toString(mUnsigned) & ":" & Replace(pth, ":", "_"))
    
    If r = 1 And FileExists(pth) Then
        Decompile = ReadFile(pth)
    End If
    
End Function

'--------------[ previously were quick calls port me] --------------------

Function instSize(v)
    Dim va As New ULong64
    Set va = UlongFromVar(v)
    instSize = SendCMD("decodeins:" & va.toString(mUnsigned))
End Function

Function isCode(v)
    Dim va As New ULong64
    Set va = UlongFromVar(v)
    isCode = SendCMD("iscode:" & va.toString(mUnsigned))
End Function

Function isData(v)
    Dim va As New ULong64
    Set va = UlongFromVar(v)
    isData = SendCMD("isdata:" & va.toString(mUnsigned))
End Function

Function UlongFromVar(v) As ULong64
    Dim ua As New ULong64, t As String
    
    t = TypeName(v)
    
    If t = "ULong64" Then
        Set UlongFromVar = v
    ElseIf t = "String" Then
        If InStr(v, "-") > 0 Then
            If Not ua.fromString(v, mSigned) Then Err.Raise 1, "UlongFromVar", "Failed to convert string: " & v
        Else
            If Not ua.fromString(v) Then
               If Not ua.fromString(v, mUnsigned) Then Err.Raise 1, "UlongFromVar", "Failed to convert unsigned string: " & v
            End If
        End If
        Set UlongFromVar = ua
    ElseIf t = "Long" Or t = "Integer" Or t = "Short" Or t = "Byte" Then
        ua.SetLongs 0, CLng(v)
    Else
        Err.Raise 1, "UlongFromVar", "Unsupported input type: " & t
    End If
    
End Function


Function ReadByte(v)
    Dim va As New ULong64
    Set va = UlongFromVar(v)
    If va = 0 Or va = -1 Then Exit Function
    ReadByte = CByte(SendCMD("readbyte:" & va.toString(mUnsigned)))
End Function

Function ReadLong(v) As Long
    Dim va As New ULong64
    Set va = UlongFromVar(v)
    If va = 0 Or va = -1 Then Exit Function
    ReadLong = CLng(SendCMD("getlong:" & va.toString(mUnsigned)))
End Function

Function ReadShort(v) As Long
    Dim va As New ULong64
    Set va = UlongFromVar(v)
    If va = 0 Or va = -1 Then Exit Function
    ReadShort = CLng(SendCMD("getword:" & va.toString(mUnsigned)))
End Function

Function OriginalByte(v)
    Dim va As New ULong64
    Set va = UlongFromVar(v)
    If va = 0 Or va = -1 Then Exit Function
    OriginalByte = CByte(SendCMD("orgbyte:" & va.toString(mUnsigned)))
End Function

Function Jump(v, Optional ByVal hwnd As Long = 0)
    Dim va As New ULong64
    Set va = UlongFromVar(v)
    If va = 0 Or va = -1 Then Exit Function
    SendCMD "jmp:" & va.toString(mUnsigned)
End Function

Function Undefine(v)
    Dim va As New ULong64
    Set va = UlongFromVar(v)
    SendCMD "undefine:" & va.toString(mUnsigned)
End Function

Function ShowEA(v)
    Dim va As New ULong64
    Set va = UlongFromVar(v)
   SendCMD "show:" & va.toString(mUnsigned)
End Function

Function HideEA(v)
    Dim va As New ULong64
    Set va = UlongFromVar(v)
    SendCMD "hide:" & va.toString(mUnsigned)
End Function

 Sub RemoveName(v)
    Dim va As New ULong64
    Set va = UlongFromVar(v)
    SendCMD "remname:" & va.toString(mUnsigned)
 End Sub

Sub MakeCode(v)
    Dim va As New ULong64
    Set va = UlongFromVar(v)
    SendCMD "makecode:" & va.toString(mUnsigned)
End Sub

Function FuncIndexFromVA(v)
    Dim va As New ULong64
    Set va = UlongFromVar(v)
    If va = 0 Or va = -1 Then Exit Function
    FuncIndexFromVA = SendCMD("funcindex" & va.toString(mUnsigned))
End Function


'these ones all return a new x64 address...
Function ImageBase() As ULong64
    Set ImageBase = SendCmdRecvLong("imgbase:" & SUBCLASSED_HWND)
End Function

Function ScreenEA() As ULong64
    Set ScreenEA = SendCmdRecvLong("screenea:" & SUBCLASSED_HWND)
End Function

Function NextEA(v) As ULong64
    Dim va As New ULong64
    Set va = UlongFromVar(v)
    Set NextEA = SendCmdRecvLong("nextea:" & va.toString(mUnsigned) & ":" & SUBCLASSED_HWND)
End Function

Function PrevEA(v) As ULong64
    Dim va As New ULong64
    Set va = UlongFromVar(v)
    Set PrevEA = SendCmdRecvLong("prevea:" & va.toString(mUnsigned) & ":" & SUBCLASSED_HWND)
End Function

Function FunctionStart(functionIndex) As ULong64
    Set FunctionStart = SendCmdRecvLong("funcstart:" & functionIndex & ":" & SUBCLASSED_HWND)
End Function

Function FunctionEnd(functionIndex) As ULong64
    Set FunctionEnd = SendCmdRecvLong("funcend:" & functionIndex & ":" & SUBCLASSED_HWND)
End Function








'--------------[ QUICK CALLS ]----------------------------------------

Function JumpRVA(rva As Long)
    If rva = 0 Or rva = -1 Then Exit Function
    QuickCall qcmJmpRVA, rva
End Function

Function refresh()
    QuickCall qcmRefresh
End Function

Function funcCount() As Long 'alias for numfuncs for intellisense which is sorted alphabetically..
    funcCount = NumFuncs()
End Function

 Function NumFuncs() As Long
    NumFuncs = QuickCall(qcmNumFuncs)
 End Function

Function EnableIDADebugMessages(Optional enabled As Boolean = True)
    QuickCall qcmDebugMessages, IIf(enabled, 1, 0)
End Function

Function is64Bit() As Long
    is64Bit = QuickCall(qcmIs64)
End Function

Function BenchMark() As Long
    Dim i As LARGE_INTEGER
    QueryPerformanceCounter i
    BenchMark = i.lowpart
End Function

 
