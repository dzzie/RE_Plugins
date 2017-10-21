VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "cIDAClient"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
'allot of these are variant args because they come from IDA_JScript and scripting clients are best used with variants

'other than switching to IDASRVR2 this one should be unchanged and functional..
'if I did my job right anyway! test me fully

Option Explicit

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
    qcmDecompilerActive = 39
    qcmFlushDecomp = 40 'flush cached decompiler results
    qcmIDAHwnd = 41     'gets main IDA Window HWND
    qcmGetVersion = 42  'version of interface
    qcmSetFocusSelectLine = 43 'bring IDA to forefront and select current line
    qcmIsCode = 44
    qcmIsData = 45
    qcmInstLen = 46
    qcmReadLong = 47
    qcmReadShort = 48
    qcmIs64 = 49
End Enum

Function is64Bit()
    is64Bit = QuickCall(qcmIs64)
End Function

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
 
Function SendCmdRecvText(cmd As String, Optional ByVal hwnd As Long) As String
    SendCMD cmd, hwnd
    SendCmdRecvText = ResponseBuffer
End Function

Function SendCmdRecvLong(cmd As String, Optional ByVal hwnd As Long) As Long
    SendCmdRecvLong = SendCMD(cmd, hwnd)
End Function

Function QuickCall(msg As quickCallMessages, Optional arg1 As Long = 0, Optional ByVal hwnd As Long = 0) As Long
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

Function MakeStr(va, Optional ascii As Boolean = True)
    If va = 0 Or va = -1 Then Exit Function
    SendCMD "makestring:" & va & ":" & IIf(ascii, "ascii", "unicode")
End Function

Function MakeUnk(va, size)
    If va = 0 Or va = -1 Then Exit Function
    SendCMD "makeunk:" & va & ":" & size
End Function

Function LoadedFile(Optional ByVal hwnd As Long = 0) As String
    LoadedFile = SendCmdRecvText("loadedfile:" & SUBCLASSED_HWND, hwnd)
End Function

Function PatchString(va, str, Optional isUnicode = False)
    
    If va = 0 Or va = -1 Then Exit Function
    
    Dim b() As Byte, i As Long
    b() = StrConv(str, vbFromUnicode)
    For i = 0 To UBound(b)
        PatchByte va, b(i)
        If isUnicode Then PatchByte va + 1, 0
        va = IIf(isUnicode, va + 2, va + 1)
    Next
    
End Function

Function PatchByte(va, newVal)
    If va = 0 Or va = -1 Then Exit Function
    If CInt(newVal) > 255 Or CInt(newVal) < 0 Then Err.Raise 1, "PatchByte", "byte value must be 0-254"
    SendCMD "patchbyte:" & va & ":" & newVal
End Function



Function intToHex(x)
    On Error Resume Next
    intToHex = Hex(x)
    If Len(intToHex) = 1 Then intToHex = "0" & intToHex
    If Err.Number <> 0 Then intToHex = x 'hex can throw overflow bleh...
End Function

Function GetAsm(va)
    If va = 0 Or va = -1 Then Exit Function
    GetAsm = SendCmdRecvText("getasm:" & va & ":" & SUBCLASSED_HWND)
End Function

Function instSize(offset)
    instSize = QuickCall(qcmInstLen, CLng(offset))
End Function

Function isCode(offset)
    isCode = QuickCall(qcmIsCode, CLng(offset))
End Function

Function isData(offset)
    isData = QuickCall(qcmIsData, CLng(offset))
End Function

Function XRefsTo(offset) 'returns CSV list
    Dim tmp
    tmp = SendCmdRecvText("refsto:" & offset & ":" & SUBCLASSED_HWND)
    If Right(tmp, 1) = "," Then tmp = Mid(tmp, 1, Len(tmp) - 1)
    'tmp = Split(tmp, ",") javascript cant deal with string() must be variant()?
    XRefsTo = tmp
End Function

Function XRefsFrom(offset) 'returns CSV list
    Dim tmp
    tmp = SendCmdRecvText("refsfrom:" & offset & ":" & SUBCLASSED_HWND)
    If Right(tmp, 1) = "," Then tmp = Mid(tmp, 1, Len(tmp) - 1)
    'tmp = Split(tmp, ",") javascript cant deal with string() must be variant()?
    XRefsFrom = tmp
End Function


Function GetName(offset)
    GetName = SendCmdRecvText("getname:" & offset & ":" & SUBCLASSED_HWND)
    If GetName = "NULL" Then GetName = ""
End Function

 Function FunctionName(functionIndex)
    If functionIndex < 0 Then Exit Function
    FunctionName = SendCmdRecvText("funcname:" & functionIndex & ":" & SUBCLASSED_HWND)
 End Function

'
Function HideBlock(offset, leng)
    Dim x, i As Long
    x = offset + leng
    For i = offset To x
        HideEA i
    Next
    refresh
End Function

Function ShowBlock(offset, leng)
    Dim x, i As Long
    x = offset + leng
    For i = offset To x
        ShowEA i
    Next
    refresh
End Function

Sub Setname(offset, name)
    If Len(name) = 0 Then Exit Sub
    SendCMD "setname:" & offset & ":" & CStr(name)
 End Sub

Sub AddComment(offset, comment)
    SendCMD "addcomment:" & offset & ":" & comment
End Sub

Function GetComment(offset)
    GetComment = SendCmdRecvText("getcomment:" & offset & ":" & SUBCLASSED_HWND)
    If GetComment = "NULL" Then GetComment = Empty
End Function


 Sub AddCodeXRef(offset, tova)
    SendCMD "addcodexref:" & offset & ":" & tova
 End Sub
 
  Sub AddDataXRef(offset, tova)
    SendCMD "adddataxref:" & offset & ":" & tova
 End Sub
 
 Sub DelCodeXRef(offset, tova)
    SendCMD "delcodexref:" & offset & ":" & tova
 End Sub
 
 Sub DelDataXRef(offset, tova)
    SendCMD "deldataxref:" & offset & ":" & tova
 End Sub
 
Function FuncVAByName(name)
    If Len(name) = 0 Then Exit Function
    FuncVAByName = SendCmdRecvLong("name_va:" & name)
End Function

Function RenameFunc(oldname, newName) As Boolean
    If Len(oldname) = 0 Or Len(newName) = 0 Then Exit Function
    RenameFunc = IIf(SendCmdRecvLong("rename:" & oldname & ":" & newName) = 1, True, False)
End Function

Function Find(startea, endea, hexstr) '-1 if fail
    If startea = 0 Or startea = -1 Then Exit Function
    If endea = 0 Or endea = -1 Then Exit Function
    If Len(hexstr) = 0 Then Exit Function
    Find = SendCmdRecvLong("findcode:" & startea & ":" & endea & ":" & hexstr)
End Function

Function Decompile(va) As String
    Dim pth As String, r As Long
    
    If va = 0 Or va = -1 Then Exit Function
    
    pth = Environ("temp")
    pth = GetFreeFileName(pth)
                                                        'its our token we will need to replace it latter :-\ foresight denied!
    r = SendCmdRecvLong("decompile:" & va & ":" & Replace(pth, ":", "_"))
    
    If r = 1 And FileExists(pth) Then
        Decompile = ReadFile(pth)
    End If
    
End Function



'--------------[ QUICK CALLS ]----------------------------------------

Function Jump(va As Long, Optional ByVal hwnd As Long = 0)
    If va = 0 Or va = -1 Then Exit Function
    QuickCall qcmJmpAddr, va, hwnd
End Function

Function JumpRVA(rva As Long)
    If rva = 0 Or rva = -1 Then Exit Function
    QuickCall qcmJmpRVA, rva
End Function

Function refresh()
    QuickCall qcmRefresh
End Function

Function Undefine(offset)
    QuickCall qcmUndef, CLng(offset)
End Function

Function ShowEA(offset)
    QuickCall qcmShow, CLng(offset)
End Function

Function HideEA(offset)
    QuickCall qcmHide, CLng(offset)
End Function

 Sub RemoveName(offset)
    QuickCall qcmRemName, CLng(offset)
 End Sub

Sub MakeCode(offset)
    QuickCall qcmMakeCode, CLng(offset)
End Sub

Function FuncIndexFromVA(va)
    If va = 0 Or va = -1 Then Exit Function
    FuncIndexFromVA = QuickCall(qcmFuncIdx, CLng(va))
End Function

Function NextEA(va)
    If va = 0 Or va = -1 Then Exit Function
    NextEA = QuickCall(qcmNextEa, CLng(va))
End Function

Function PrevEA(va)
    If va = 0 Or va = -1 Then Exit Function
    PrevEA = QuickCall(qcmPrevEa, CLng(va))
End Function

Function funcCount() As Long 'alias for numfuncs for intellisense which is sorted alphabetically..
    funcCount = NumFuncs()
End Function

 Function NumFuncs() As Long
    NumFuncs = QuickCall(qcmNumFuncs)
 End Function

 Function FunctionStart(functionIndex)
    If functionIndex < 0 Then Exit Function
    FunctionStart = QuickCall(qcmFuncStart, CLng(functionIndex))
 End Function

 Function FunctionEnd(functionIndex)
    If functionIndex < 0 Then Exit Function
    FunctionEnd = QuickCall(qcmFuncEnd, CLng(functionIndex))
 End Function
  
Function ReadByte(va)
    If va = 0 Or va = -1 Then Exit Function
    ReadByte = CByte(QuickCall(qcmReadByte, CLng(va)))
End Function

Function ReadLong(va) As Long
    If va = 0 Or va = -1 Then Exit Function
    ReadLong = CLng(QuickCall(qcmReadLong, CLng(va)))
End Function

Function ReadShort(va) As Long
    If va = 0 Or va = -1 Then Exit Function
    ReadShort = CLng(QuickCall(qcmReadShort, CLng(va)))
End Function

Function OriginalByte(va)
    If va = 0 Or va = -1 Then Exit Function
    OriginalByte = CByte(QuickCall(qcmOrgByte, CLng(va)))
End Function

Function ImageBase() As Long
    ImageBase = QuickCall(qcmImgBase)
End Function

Function ScreenEA() As Long
    ScreenEA = QuickCall(qcmScreenEA)
End Function

Function EnableIDADebugMessages(Optional enabled As Boolean = True)
    QuickCall qcmDebugMessages, IIf(enabled, 1, 0)
End Function


Function BenchMark() As Long
    Dim i As LARGE_INTEGER
    QueryPerformanceCounter i
    BenchMark = i.lowpart
End Function

 
