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
'still a bunch of  'todo x64

Public ipc As CIpc
Attribute ipc.VB_VarHelpID = -1
Private tmp_x As New ULong64
Public is64BitMode As Boolean

Function funcMap(ByRef count As Long)  'not really for idajs, for integrating idacompare functionality
    Dim path As String, p As String
    'fprintf(fp, "%d,%s,0x%llx,0x%llx,0x%x,%d\n", i, name.c_str(), ua1, ua2, (fu->end_ea - fu->start_ea), fu->referers);
    path = fso.GetFreeFileName(Environ("temp"))
    p = Replace(path, ":", "_") 'tokinizer bs
    count = ipc.SendCmdRecvInt("funcmap:" & p)
    If count > 0 Then funcMap = path Else fso.deleteFile path
End Function

Function getSegs()
    getSegs = ipc.SendCmdRecvText("getsegs:" & Form1.hwnd)
End Function

Function delSeg(nameOrBase)
    delSeg = ipc.SendCmdRecvInt("delseg:" & nameOrBase)
End Function

Function segExists(nameOrBase)
    segExists = ipc.SendCmdRecvInt("segexists:" & nameOrBase)
End Function

Function addSegment(base, Size, Name)
        addSegment = ipc.SendCmdRecvInt("addseg:" & base & ":" & Size & ":" & Name)
End Function

Function importFile(va, path, optNewSegName)
    
    On Error GoTo hell
    
    path = Replace(path, "/", "\")
    If Not FileExists(CStr(path)) Then GoTo hell
    
    Dim b() As Byte, f As Long, ul As New ULong64, i As Long
    
    ul.use0x = True
    ul = va
    
    If Len(optNewSegName) > 0 Then
        If segExists(va) = 0 Then
            If addSegment(va, FileLen(path), optNewSegName) = 0 Then GoTo hell
        End If
    End If
     
    importFile = ipc.SendCmdRecvInt("importpatch:" & Replace(path, ":", "_") & ":" & ul.toString())
    
Exit Function
hell:
    importFile = 0
End Function

'Function importFile(va, path, optNewSegName)
'
'    On Error GoTo hell
'
'    path = Replace(path, "/", "\")
'    If Not FileExists(CStr(path)) Then GoTo hell
'
'    Dim b() As Byte, f As Long, ul As New ULong64, i As Long
'
'    ul.use0x = True
'    ul = va
'
'    f = FreeFile
'    Open path For Binary As f
'    ReDim b(LOF(f) - 1)
'    Get f, , b()
'    Close f
'
'    If Len(optNewSegName) > 0 Then
'        If segExists(va) = 0 Then
'            If addSegment(va, UBound(b), optNewSegName) = 0 Then GoTo hell
'        End If
'    End If
'
'    For i = 0 To UBound(b)
'        patchByte ul.toString(), b(i)
'        ul = ul.add(1)
'    Next
'
'    importFile = 1
'
'Exit Function
'hell:
'    importFile = 0
'End Function


Function add_enum(Name) As Long
    add_enum = ipc.SendCmdRecvInt("addenum:" & Name)
End Function

Function get_enum(Name) As Long
    get_enum = ipc.SendCmdRecvInt("getenum:" & Name)
End Function

Function add_enum_member(id, Name, val) As Long
    'addenummem:enumid:value:name
    add_enum_member = ipc.SendCmdRecvInt("addenummem:" & id & ":" & val & ":" & Name)
End Function

Function immvals(ea)
    immvals = ipc.SendCmdRecvText("immvals:" & ea & ":" & Form1.hwnd)
    MsgBox immvals
End Function

'Function getopn(ea)
'    getopn = ipc.SendCmdRecvInt("getopn:" & ea)
'End Function

Function getopv(ea, n)
    getopv = ipc.SendCmdRecvText("getopv:" & ea & ":" & n & ":" & Form1.hwnd)
End Function

Function dumpFunc(i, flags)
    Dim p As String, r As Long
    p = fso.GetFreeFileName(Environ("temp"))
    r = ipc.SendCmdRecvInt("dumpfunc:" & i & ":" & flags & ":" & Replace(p, ":", "_")) 'strtok :(
    If r = 1 Then dumpFunc = fso.readFile(p)
    fso.deleteFile p
End Function

Function dumpFuncBytes(i)
    Dim p As String, r As Long
    p = fso.GetFreeFileName(Environ("temp"))
    r = ipc.SendCmdRecvInt("dumpfuncbytes:" & i & ":" & Replace(p, ":", "_"))
    If r = 1 Then dumpFuncBytes = fso.readFile(p)
    fso.deleteFile p
End Function

Private Sub Class_Initialize()
    Set ipc = New CIpc
    ipc.FindClient "IDA_SERVER2"
    ipc.Listen Form1.hwnd
    tmp_x.use0x = True
    tmp_x.useTick = False
End Sub

Property Get timeout()
    timeout = Form1.txtjs.timeout
End Property

Property Let timeout(v)
    On Error Resume Next
    Form1.txtjs.timeout = CLng(v)
End Property

Property Get is32Bit() As Boolean
    is32Bit = Not is64BitMode
End Property

Property Get isUp() As Boolean
    isUp = IIf(IsWindow(ipc.RemoteHWND) = 1, True, False)
End Property

Function targetIs_x86() As Boolean
    If ipc.quickCall(qcmIsX64Disasm) = 0 Then
        targetIs_x86 = True
        is64BitMode = False
    Else
        is64BitMode = True
        targetIs_x86 = False
    End If
End Function

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

Property Let caption(msg)
    Form1.caption = msg
    Form1.refresh
    DoEvents
End Property

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

Function makeUnk(va, Size)
    ipc.Send "makeunk:" & va & ":" & Size
End Function

Property Get loadedFile() As String
    loadedFile = ipc.SendCmdRecvText("loadedfile:" & Form1.hwnd)
End Property

Sub t(Data)
    Form1.Text1.Text = Form1.Text1.Text & vbCrLf & Data
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



Function intToHex(X)
    On Error Resume Next
     
    'keep it 32bit if we can... (-1 went to full 64bit)
    intToHex = Hex(CLng(Replace(X, "0x", "&h")))
    
    If Err.Number = 0 Then
        If Len(intToHex) = 1 Then intToHex = "0" & intToHex
        intToHex = "0x" & intToHex
        Exit Function
    End If
    
    If Not tmp_x.fromString(X) Then
        Form1.List1.AddItem "Failed to convert x: " & X
        Exit Function
    End If
    
    intToHex = tmp_x.toString(mHex)

End Function

Function getAsm(va)
    getAsm = ipc.SendCmdRecvText("getasm:" & va & ":" & Form1.hwnd)
End Function

Function instSize(offset)
    instSize = ipc.SendCmdRecvInt("decodeins:" & offset) ' quickCall(qcmInstLen, CLng(offset))
End Function

Function isCode(offset)
    isCode = ipc.SendCmdRecvInt("iscode:" & offset) 'quickCall(qcmIsCode, CLng(offset))
End Function

Function isData(offset)
    isData = ipc.SendCmdRecvInt("isdata:" & offset) 'quickCall(qcmIsData, CLng(offset))
End Function

Private Function csvToHex(csv) As String
    On Error Resume Next
    Dim tmp() As String, X, Y()
    tmp = Split(csv, ",")
    For Each X In tmp
        push Y, tmp_x.setVal(X).toString(mHex)
    Next
    csvToHex = Join(Y, ",")
End Function

Function xRefsTo(offset) 'returns CSV list
    Dim tmp
    tmp = ipc.SendCmdRecvText("refsto:" & offset & ":" & Form1.hwnd)
    If Right(tmp, 1) = "," Then tmp = Mid(tmp, 1, Len(tmp) - 1)
    If is64BitMode Then
        xRefsTo = csvToHex(tmp)
    Else
       'tmp = Split(tmp, ",") javascript cant deal with string() must be variant()?
       xRefsTo = tmp
    End If
End Function

Function xRefsFrom(offset) 'returns CSV list
    Dim tmp
    tmp = ipc.SendCmdRecvText("refsfrom:" & offset & ":" & Form1.hwnd)
    If Right(tmp, 1) = "," Then tmp = Mid(tmp, 1, Len(tmp) - 1)
    If is64BitMode Then
        xRefsFrom = csvToHex(tmp)
    Else
        'tmp = Split(tmp, ",") javascript cant deal with string() must be variant()?
        xRefsFrom = tmp
    End If
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
    Dim X, i As Long
    
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
    Dim X, i As Long
    
    If offset < 1 Or endAt < 1 Then
        MsgBox "Address would go negative", vbInformation
        Exit Function
    End If
    
    For i = offset To endAt
        showEA i
    Next
    
    refresh
End Function

Sub setname(offset, Name)
    ipc.Send "setname:" & offset & ":" & CStr(Name)
 End Sub

Sub addComment(offset, comment)
    ipc.Send "addcomment:" & offset & ":" & comment
End Sub

Function getComment(offset)
    getComment = ipc.SendCmdRecvText("getcomment:" & offset & ":" & Form1.hwnd)
    If getComment = "NULL" Then getComment = Empty
End Function

 'todo x64
 Sub addCodeXRef(offset, tova)
    ipc.Send "addcodexref:" & offset & ":" & tova
 End Sub
 
  'todo x64
  Sub addDataXRef(offset, tova)
    ipc.Send "adddataxref:" & offset & ":" & tova
 End Sub
 
  'todo x64
 Sub delCodeXRef(offset, tova)
    ipc.Send "delcodexref:" & offset & ":" & tova
 End Sub
 
  'todo x64
 Sub delDataXRef(offset, tova)
    ipc.Send "deldataxref:" & offset & ":" & tova
 End Sub
 
 'todo x64
Function funcVAByName(Name)
    If Not is64BitMode Then
        funcVAByName = ipc.SendCmdRecvInt("name_va:" & Name)
    Else
        funcVAByName = ipc.SendCmdRecvText("name_va:" & Name & ":" & Form1.hwnd)
        funcVAByName = tmp_x.setVal(funcVAByName).toString(mHex)
    End If
End Function

Function renameFunc(oldname, newName) As Boolean
    renameFunc = IIf(ipc.SendCmdRecvInt("rename:" & oldname & ":" & newName) = 1, True, False)
End Function

 'todo x64
Function find(startEa, endea, hexstr) '-1 if fail
    'findcode:start:end:hexstr
    find = ipc.SendCmdRecvInt("findcode:" & startEa & ":" & endea & ":" & hexstr)
End Function

Function decompile(va) As String
    Dim pth As String, r As Long
    
    pth = Environ("temp")
    pth = fso.GetFreeFileName(pth)
                                                        'its our token we will need to replace it latter :-\ foresight denied!
    r = ipc.SendCmdRecvInt("decompile:" & va & ":" & Replace(pth, ":", "_"))
    
    If r = 1 And fso.FileExists(pth) Then
        decompile = fso.readFile(pth)
    End If
    
End Function



'--------------[ QUICK CALLS ]----------------------------------------

'x86 is unchanged with quickcalls because
' 1) already debugged, 2) 3x faster,
' --> 3) it lets JS deal with results as numbers normally and not make everything an x64 string! <--
' yes I hate the extra code and special cases js (and vb) problem...

Function jump(va)
    On Error Resume Next
    
    If Not is64BitMode Then
        ipc.quickCall qcmJmpAddr_32, cCLng(va)
    Else
        If Not tmp_x.fromString(va) Then
            Form1.List1.AddItem "Failed to convert va: " & va
            Exit Function
        End If
        ipc.Send "jmp:" & tmp_x.toString(mHex)
    End If
    
End Function

Function jumpRVA(rva)
    On Error Resume Next
    ipc.quickCall qcmJmpRVA, cCLng(rva)
End Function

Function refresh()
    ipc.quickCall qcmRefresh
End Function

Function undefine(va)
    On Error Resume Next
    If Not is64BitMode Then
        ipc.quickCall qcmUndef_32, cCLng(va)
    Else
        If Not tmp_x.fromString(va) Then
            Form1.List1.AddItem "Failed to convert va: " & va
            Exit Function
        End If
        ipc.Send "undefine:" & tmp_x.toString(mHex)
    End If
End Function

Function showEA(va)
    On Error Resume Next
    If Not is64BitMode Then
        ipc.quickCall qcmShow_32, cCLng(va)
    Else
        If Not tmp_x.fromString(va) Then
            Form1.List1.AddItem "Failed to convert va: " & va
            Exit Function
        End If
        ipc.Send "show:" & tmp_x.toString(mHex)
    End If
End Function

Function hideEA(va)
    On Error Resume Next
    If Not is64BitMode Then
        ipc.quickCall qcmHide_32, cCLng(va)
    Else
        If Not tmp_x.fromString(va) Then
            Form1.List1.AddItem "Failed to convert va: " & va
            Exit Function
        End If
        ipc.Send "hide:" & tmp_x.toString(mHex)
    End If
End Function

 Sub removeName(va)
    On Error Resume Next
    If Not is64BitMode Then
        ipc.quickCall qcmRemName_32, cCLng(va)
    Else
        If Not tmp_x.fromString(va) Then
            Form1.List1.AddItem "Failed to convert va: " & va
            Exit Sub
        End If
        ipc.Send "remname:" & tmp_x.toString(mHex)
    End If
 End Sub

Sub makeCode(va)
    On Error Resume Next
    If Not is64BitMode Then
        ipc.quickCall qcmMakeCode_32, cCLng(va)
    Else
        If Not tmp_x.fromString(va) Then
            Form1.List1.AddItem "Failed to convert va: " & va
            Exit Sub
        End If
        ipc.Send "makecode:" & tmp_x.toString(mHex)
    End If
End Sub

Function funcIndexFromVA(va)
    On Error Resume Next
    If Not is64BitMode Then
        funcIndexFromVA = ipc.quickCall(qcmFuncIdx_32, cCLng(va))
    Else
        If Not tmp_x.fromString(va) Then
            Form1.List1.AddItem "Failed to convert va: " & va
            Exit Function
        End If
        funcIndexFromVA = ipc.SendCmdRecvInt("funcindex:" & tmp_x.toString(mHex))
    End If
End Function

Function nextEA(va)
    On Error Resume Next
    If Not is64BitMode Then
        nextEA = ipc.quickCall(qcmNextEa_32, cCLng(va))
    Else
        If Not tmp_x.fromString(va) Then
            Form1.List1.AddItem "Failed to convert va: " & va
            Exit Function
        End If
        nextEA = ipc.SendCmdRecvText("nextea:" & tmp_x.toString(mHex) & ":" & Form1.hwnd)
        nextEA = tmp_x.setVal(nextEA).toString(mHex)
    End If
End Function

Function prevEA(va)
    On Error Resume Next
    If Not is64BitMode Then
        prevEA = ipc.quickCall(qcmPrevEa_32, cCLng(va))
    Else
        If Not tmp_x.fromString(va) Then
            Form1.List1.AddItem "Failed to convert va: " & va
            Exit Function
        End If
        prevEA = ipc.SendCmdRecvText("prevea:" & tmp_x.toString(mHex) & ":" & Form1.hwnd)
        prevEA = tmp_x.setVal(prevEA).toString(mHex)
    End If
End Function

Function funcCount() As Long 'alias for numfuncs for intellisense which is sorted alphabetically..
    funcCount = numFuncs()
End Function

 Function numFuncs() As Long
    numFuncs = ipc.quickCall(qcmNumFuncs)
 End Function

 Function functionStart(functionIndex)
     On Error Resume Next
     If Not is64BitMode Then
        functionStart = ipc.quickCall(qcmFuncStart_32, cCLng(functionIndex))
     Else
        functionStart = ipc.SendCmdRecvText("funcstart:" & functionIndex & ":" & Form1.hwnd)
        functionStart = tmp_x.setVal(functionStart).toString(mHex)
     End If
 End Function

 Function functionEnd(functionIndex)
     On Error Resume Next
     If Not is64BitMode Then
        functionEnd = ipc.quickCall(qcmFuncEnd_32, cCLng(functionIndex))
     Else
        functionEnd = ipc.SendCmdRecvText("funcend:" & functionIndex & ":" & Form1.hwnd)
        functionEnd = tmp_x.setVal(functionEnd).toString(mHex)
     End If
 End Function
  
 Function readByte(va)
     On Error Resume Next
     If Not is64BitMode Then
        readByte = CByte(ipc.quickCall(qcmReadByte_32, cCLng(va)))
     Else
        If Not tmp_x.fromString(va) Then
            Form1.List1.AddItem "Failed to convert va: " & va
            Exit Function
        End If
        readByte = ipc.SendCmdRecvText("readbyte:" & tmp_x.toString(mHex) & ":" & Form1.hwnd)
        readByte = Right(readByte, 2)
     End If
End Function

Function readLong(va)
    On Error Resume Next
    If Not is64BitMode Then
         If va = 0 Or va = -1 Then Exit Function
         readLong = CLng(ipc.quickCall(qcmReadLong_32, cCLng(va)))
    Else
        If Not tmp_x.fromString(va) Then
            Form1.List1.AddItem "Failed to convert va: " & va
            Exit Function
        End If
        readLong = ipc.SendCmdRecvInt("getlong:" & tmp_x.toString(mHex)) ' & ":" & Form1.hwnd)
    End If
End Function

Function readQWord(va)
    On Error Resume Next
    If Not tmp_x.fromString(va) Then
        Form1.List1.AddItem "Failed to convert va: " & va
        Exit Function
    End If
    readQWord = ipc.SendCmdRecvText("getx64:" & tmp_x.toString(mHex) & ":" & Form1.hwnd)
End Function

Function readShort(va)
    On Error Resume Next
    If Not is64BitMode Then
         If va = 0 Or va = -1 Then Exit Function
         readShort = CLng(ipc.quickCall(qcmReadShort_32, cCLng(va)))
    Else
        If Not tmp_x.fromString(va) Then
            Form1.List1.AddItem "Failed to convert va: " & va
            Exit Function
        End If
        readShort = ipc.SendCmdRecvInt("getword:" & tmp_x.toString(mHex)) '& ":" & Form1.hwnd)
    End If
End Function

Function originalByte(va)
    On Error Resume Next
    
    If Not is64BitMode Then
         If va = 0 Or va = -1 Then Exit Function
         originalByte = CByte(ipc.quickCall(qcmOrgByte_32, cCLng(va)))
    Else
        If Not tmp_x.fromString(va) Then
            Form1.List1.AddItem "Failed to convert va: " & va
            Exit Function
        End If
        originalByte = ipc.SendCmdRecvInt("orgbyte:" & tmp_x.toString(mHex))
        originalByte = Right(originalByte, 2)
    End If
End Function

Function imageBase()
    If Not is64BitMode Then
         imageBase = ipc.quickCall(qcmImgBase_32)
    Else
        imageBase = ipc.SendCmdRecvText("imgbase:" & Form1.hwnd)
        imageBase = tmp_x.setVal(imageBase).toString(mHex)
    End If
End Function

Function screenEA()
    If Not is64BitMode Then
        screenEA = ipc.quickCall(qcmScreenEA_32)
    Else
        screenEA = ipc.SendCmdRecvText("screenea:" & Form1.hwnd)
        screenEA = tmp_x.setVal(screenEA).toString(mHex)
    End If
End Function

Function enableIDADebugMessages(Optional enabled As Boolean = True)
    ipc.quickCall qcmDebugMessages, IIf(enabled, 1, 0)
End Function

Function quickCall(msg, Optional arg1 = 0) As Long
    On Error Resume Next
    quickCall = ipc.quickCall(cCLng(msg), cCLng(arg1))
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

Function FileExists(path) As Boolean
  On Error GoTo hell
  Dim tmp As String
  tmp = Replace(path, "'", Empty)
  tmp = Replace(tmp, """", Empty)
  If Len(tmp) = 0 Then Exit Function
  If Dir(tmp, vbHidden Or vbNormal Or vbReadOnly Or vbSystem) <> "" Then FileExists = True
  Exit Function
hell: FileExists = False
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

Function setClipboard(X)
    Clipboard.Clear
    Clipboard.SetText X
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

Function hexDump(X) As String
    hexDump = Module1.hexDump(CStr(X), , , hoDump)
End Function

Function hexstr(X) As String
    hexstr = Module1.hexDump(CStr(X), , , hoHexOnly)
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
