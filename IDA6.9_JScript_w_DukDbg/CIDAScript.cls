VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "CIDAScript"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Public ipc As CIpc
Attribute ipc.VB_VarHelpID = -1

Private Sub Class_Initialize()
    Set ipc = New CIpc
    ipc.FindClient "IDA_SERVER"
    ipc.Listen Form1.hwnd
End Sub

Property Get timeout()
    timeout = Form1.txtjs.timeout
End Property

Property Let timeout(v)
    On Error Resume Next
    Form1.txtjs.timeout = CLng(v)
End Property

Property Get isUp() As Boolean
    isUp = IIf(IsWindow(ipc.RemoteHWND) = 1, True, False)
End Property

Sub do_events()
    DoEvents
End Sub

Sub die(msg)
    Form1.txtjs.timeout = 1
    Form1.txtjs.StopExecution
    t msg
End Sub

Sub clearDecompilerCache()
    Me.quickCall 40, 0
End Sub

Sub caption(msg)
    Form1.caption = msg
    Form1.refresh
    DoEvents
End Sub

Function alert(msg)
    If IsArray(msg) Then
        MsgBox "Array: " & vbCrLf & vbCrLf & Join(msg, vbCrLf), vbInformation, "IDAJScript"
    Else
        MsgBox msg, vbInformation, "IDAJScript"
    End If
End Function

Function message(msg)
    ipc.Send "msg:" & msg
End Function

Function makeStr(va, Optional ascii As Boolean = True)
    ipc.Send "makestring:" & va & ":" & IIf(ascii, "ascii", "unicode")
End Function

Function makeUnk(va, size)
    ipc.Send "makeunk:" & va & ":" & size
End Function

Property Get loadedFile() As String
    loadedFile = ipc.SendCmdRecvText("loadedfile:" & Form1.hwnd)
End Property

Sub t(data)
    Form1.Text1.Text = Form1.Text1.Text & vbCrLf & data
    Form1.Text1.SelStart = Len(Form1.Text1.Text)
    DoEvents
End Sub

Sub clearLog()
    Form1.Text1.Text = Empty
End Sub

Function patchString(va, str, Optional isUnicode = False)
    
    Dim b() As Byte, i As Long
    b() = StrConv(str, vbFromUnicode)
    For i = 0 To UBound(b)
        patchByte va, b(i)
        If isUnicode Then patchByte va + 1, 0
        va = IIf(isUnicode, va + 2, va + 1)
    Next
    
End Function

Function patchByte(va, newVal)
    If CInt(newVal) > 255 Then Err.Raise 1, "PatchByte", "byte value must be 0-254"
    ipc.Send "patchbyte:" & va & ":" & newVal
End Function



Function intToHex(x)
    On Error Resume Next
    intToHex = Hex(x)
    If Len(intToHex) = 1 Then intToHex = "0" & intToHex
    If Err.Number <> 0 Then intToHex = x 'hex can throw overflow bleh...
End Function

Function getAsm(va)
    getAsm = ipc.SendCmdRecvText("getasm:" & va & ":" & Form1.hwnd)
End Function

Function instSize(offset)
    instSize = quickCall(qcmInstLen, CLng(offset))
End Function

Function isCode(offset)
    isCode = quickCall(qcmIsCode, CLng(offset))
End Function

Function isData(offset)
    isData = quickCall(qcmIsData, CLng(offset))
End Function

Function xRefsTo(offset) 'returns CSV list
    Dim tmp
    tmp = ipc.SendCmdRecvText("refsto:" & offset & ":" & Form1.hwnd)
    If Right(tmp, 1) = "," Then tmp = Mid(tmp, 1, Len(tmp) - 1)
    'tmp = Split(tmp, ",") javascript cant deal with string() must be variant()?
    xRefsTo = tmp
End Function

Function xRefsFrom(offset) 'returns CSV list
    Dim tmp
    tmp = ipc.SendCmdRecvText("refsfrom:" & offset & ":" & Form1.hwnd)
    If Right(tmp, 1) = "," Then tmp = Mid(tmp, 1, Len(tmp) - 1)
    'tmp = Split(tmp, ",") javascript cant deal with string() must be variant()?
    xRefsFrom = tmp
End Function


Function getName(offset)
    getName = ipc.SendCmdRecvText("getname:" & offset & ":" & Form1.hwnd)
    If getName = "NULL" Then getName = ""
End Function

 Function functionName(functionIndex)
    functionName = ipc.SendCmdRecvText("funcname:" & functionIndex & ":" & Form1.hwnd)
 End Function

'
Function hideBlock(offset, endAt)
    Dim x, i As Long
    
    If offset < 1 Or endAt < 1 Then
        MsgBox "Address would go negative", vbInformation
        Exit Function
    End If
    
    For i = offset To endAt
        hideEA i
    Next
    
    refresh
End Function

Function showBlock(offset, endAt)
    Dim x, i As Long
    
    If offset < 1 Or endAt < 1 Then
        MsgBox "Address would go negative", vbInformation
        Exit Function
    End If
    
    For i = offset To endAt
        showEA i
    Next
    
    refresh
End Function

Sub setname(offset, name)
    ipc.Send "setname:" & offset & ":" & CStr(name)
 End Sub

Sub addComment(offset, comment)
    ipc.Send "addcomment:" & offset & ":" & comment
End Sub

Function getComment(offset)
    getComment = ipc.SendCmdRecvText("getcomment:" & offset & ":" & Form1.hwnd)
    If getComment = "NULL" Then getComment = Empty
End Function


 Sub addCodeXRef(offset, tova)
    ipc.Send "addcodexref:" & offset & ":" & tova
 End Sub
 
  Sub addDataXRef(offset, tova)
    ipc.Send "adddataxref:" & offset & ":" & tova
 End Sub
 
 Sub delCodeXRef(offset, tova)
    ipc.Send "delcodexref:" & offset & ":" & tova
 End Sub
 
 Sub delDataXRef(offset, tova)
    ipc.Send "deldataxref:" & offset & ":" & tova
 End Sub
 
Function funcVAByName(name)
    funcVAByName = ipc.SendCmdRecvInt("name_va:" & name)
End Function

Function renameFunc(oldname, newName) As Boolean
    renameFunc = IIf(ipc.SendCmdRecvInt("rename:" & oldname & ":" & newName) = 1, True, False)
End Function

Function find(startea, endea, hexstr) '-1 if fail
    'findcode:start:end:hexstr
    find = ipc.SendCmdRecvInt("findcode:" & startea & ":" & endea & ":" & hexstr)
End Function

Function decompile(va) As String
    Dim pth As String, r As Long
    
    pth = Environ("temp")
    pth = fso.GetFreeFileName(pth)
                                                        'its our token we will need to replace it latter :-\ foresight denied!
    r = ipc.SendCmdRecvInt("decompile:" & va & ":" & Replace(pth, ":", "_"))
    
    If r = 1 And fso.fileExists(pth) Then
        decompile = fso.readFile(pth)
    End If
    
End Function



'--------------[ QUICK CALLS ]----------------------------------------

Function jump(va)
    On Error Resume Next
    ipc.quickCall qcmJmpAddr, CLng(va)
End Function

Function jumpRVA(rva)
    On Error Resume Next
    ipc.quickCall qcmJmpRVA, CLng(rva)
End Function

Function refresh()
    ipc.quickCall qcmRefresh
End Function

Function undefine(offset)
    On Error Resume Next
    ipc.quickCall qcmUndef, CLng(offset)
End Function

Function showEA(offset)
    On Error Resume Next
    ipc.quickCall qcmShow, CLng(offset)
End Function

Function hideEA(offset)
    On Error Resume Next
    ipc.quickCall qcmHide, CLng(offset)
End Function

 Sub removeName(offset)
    On Error Resume Next
    ipc.quickCall qcmRemName, CLng(offset)
 End Sub

Sub makeCode(offset)
    On Error Resume Next
    ipc.quickCall qcmMakeCode, CLng(offset)
End Sub

Function funcIndexFromVA(va)
    On Error Resume Next
    funcIndexFromVA = ipc.quickCall(qcmFuncIdx, CLng(va))
End Function

Function nextEA(va)
    On Error Resume Next
    nextEA = ipc.quickCall(qcmNextEa, CLng(va))
End Function

Function prevEA(va)
    On Error Resume Next
    prevEA = ipc.quickCall(qcmPrevEa, CLng(va))
End Function

Function funcCount() As Long 'alias for numfuncs for intellisense which is sorted alphabetically..
    funcCount = numFuncs()
End Function

 Function numFuncs() As Long
    numFuncs = ipc.quickCall(qcmNumFuncs)
 End Function

 Function functionStart(functionIndex)
     On Error Resume Next
    functionStart = ipc.quickCall(qcmFuncStart, CLng(functionIndex))
 End Function

 Function functionEnd(functionIndex)
     On Error Resume Next
    functionEnd = ipc.quickCall(qcmFuncEnd, CLng(functionIndex))
 End Function
  
 Function readByte(va)
     On Error Resume Next
    readByte = CByte(ipc.quickCall(qcmReadByte, CLng(va)))
End Function

Function readLong(va)
    On Error Resume Next
    If va = 0 Or va = -1 Then Exit Function
    readLong = CLng(ipc.quickCall(qcmReadLong, CLng(va)))
End Function

Function readShort(va)
    On Error Resume Next
    If va = 0 Or va = -1 Then Exit Function
    readShort = CLng(ipc.quickCall(qcmReadShort, CLng(va)))
End Function

Function originalByte(va)
    On Error Resume Next
    originalByte = CByte(ipc.quickCall(qcmOrgByte, CLng(va)))
End Function

Function imageBase()
    imageBase = ipc.quickCall(qcmImgBase)
End Function

Function screenEA() As Long
    screenEA = ipc.quickCall(qcmScreenEA)
End Function

Function enableIDADebugMessages(Optional enabled As Boolean = True)
    ipc.quickCall qcmDebugMessages, IIf(enabled, 1, 0)
End Function

Function quickCall(msg, Optional arg1 = 0) As Long
    On Error Resume Next
    quickCall = ipc.quickCall(CLng(msg), CLng(arg1))
End Function


' Sub DelFunc(addr)
'    Module1.DelFunc CLng(addr)
' End Sub
'
'Sub AddProgramComment(cmt)
'   Module1.AddProgramComment CStr(cmt)
'End Sub
'
' Function ScreenEA()
'    ScreenEA = Module1.ScreenEA
' End Function
'


'Function GetAsmBlock(start, leng)
'    GetAsmBlock = GetAsmRange(CLng(start), CLng(leng))
'End Function
'
'
'Function GetBytes(start, leng)
'    Dim b() As Byte, ret(), i As Integer
'
'    ReDim b(leng)
'    ReDim ret(leng)
'
'    Module1.GetBytes CLng(start), b(0), CLng(leng)
'
'    For i = 0 To leng
'        ret(i) = b(i)
'    Next
'
'    GetBytes = ret()
'
'End Function
'
'

'
'
'Sub AnalyzeArea(startat, endat)
'    Module1.AnalyzeArea CLng(startat), CLng(endat)
'End Sub
'

Function askValue(Optional prompt, Optional defVal) As String
    askValue = InputBox(prompt, , defVal)
End Function

Sub exec(cmd)
   On Error Resume Next
   Shell cmd, vbNormalFocus
End Sub

Function readFile(filename) As Variant
  Dim f As Long
  Dim temp As Variant
  
  On Error Resume Next
   
  If InStr(1, filename, "%sp%", vbTextCompare) > 0 Then
        If Len(Form1.loadedFile) = 0 Then
            MsgBox "can not use %sp variable yet in file path file not saved!"
            Exit Function
        End If
        
        temp = fso.GetParentFolder(Form1.loadedFile)
        filename = Replace(filename, "%sp%", temp, , , vbTextCompare)
  End If
  
  'todo support %desktop%
  
  f = FreeFile
  temp = ""
   Open filename For Binary As #f        ' Open file.(can be text or image)
     temp = Input(FileLen(filename), #f) ' Get entire Files data
   Close #f
   readFile = temp
End Function

Sub writeFile(path, it)
    On Error Resume Next
    
    Dim temp As String
    
    If InStr(1, path, "%sp%", vbTextCompare) > 0 Then
    
        If Len(Form1.loadedFile) = 0 Then
            MsgBox "can not use %sp variable yet in file path file not saved!"
            Exit Sub
        End If
        
        temp = fso.GetParentFolder(Form1.loadedFile)
        path = Replace(path, "%sp%", temp, , , vbTextCompare)
      
    End If
  
    Dim f As Long
    f = FreeFile
    Open path For Output As #f
    Print #f, it
    Close f
    
End Sub

Sub appendFile(path, it)
    Dim f As Long
    f = FreeFile
    Open path For Append As #f
    Print #f, it
    Close f
End Sub

Function fileExists(path) As Boolean
  On Error GoTo hell
  Dim tmp As String
  tmp = Replace(path, "'", Empty)
  tmp = Replace(tmp, """", Empty)
  If Len(tmp) = 0 Then Exit Function
  If Dir(tmp, vbHidden Or vbNormal Or vbReadOnly Or vbSystem) <> "" Then fileExists = True
  Exit Function
hell: fileExists = False
End Function

Function deleteFile(fpath) As Boolean
 On Error GoTo hadErr
    Kill fpath
    deleteFile = True
 Exit Function
hadErr:
'MsgBox "DeleteFile Failed" & vbCrLf & vbCrLf & fpath
deleteFile = False
End Function

Function getClipboard()
    getClipboard = Clipboard.GetText()
End Function

Function setClipboard(x)
    Clipboard.Clear
    Clipboard.SetText x
End Function

Function openFileDialog() As String
    openFileDialog = dlg.OpenDialog(AllFiles)
End Function

Function saveFileDialog() As String
    saveFileDialog = dlg.SaveDialog(AllFiles)
End Function

Function benchMark() As Long
    Dim i As LARGE_INTEGER
    QueryPerformanceCounter i
    benchMark = i.lowpart
End Function

Function hexDump(x) As String
    hexDump = Module1.hexDump(CStr(x), , , hoDump)
End Function

Function hexstr(x) As String
    hexstr = Module1.hexDump(CStr(x), , , hoHexOnly)
End Function

Function toBytes(hexstr) As String
    Dim out As String
    If Module1.toBytes(CStr(hexstr), out) Then toBytes = out
End Function


'Function refListToArray(x) As Long() 'no way to use a vb6 array in js?
'    On Error Resume Next
'    Dim i As Long, y() As Long
'    x = Split(x, ",")
'    ReDim y(UBound(x) - 1)
'    For i = 0 To UBound(x) - 1
'        y(i) = CLng(x(i))
'    Next
'    refListToArray = y
'End Function
 
'Function InstSize(offset)
'    'there has to be a real way to do this
'    Dim x As String, tmp As String, i As Long, n As String
'    Dim firstea As Long, secondea As Long
'    Dim leng As Long
'
'    leng = 40
'    firstea = 0
'    secondea = 0
'    For i = 0 To leng - 1
'        tmp = GetAsm(offset + i)
'        If tmp = "Fail" Then tmp = Empty
'        If Len(tmp) > 0 Then
'            If firstea = 0 Then
'                firstea = offset + i
'            ElseIf secondea = 0 Then
'                 secondea = offset + i
'            End If
'            If firstea > 0 And secondea > 0 Then Exit For
'        End If
'    Next
'
'    InstSize = secondea - firstea
'
'End Function
