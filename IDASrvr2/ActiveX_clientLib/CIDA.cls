VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "CIDAClient2"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
'from IDAJScript 10.3.20  for IdaSrv2 grumble grumble

Option Explicit

Public ipc As CIPC
Private tmp_x As New ULong64
Public is64BitMode As Boolean

Function is64Bit()
    is64Bit = ipc.quickCall(qcmIsX64Disasm)
End Function

Property Get ActiveIDA() As Long
    ActiveIDA = ipc.RemoteHWND
End Property

Property Let ActiveIDA(v As Long)
    ipc.RemoteHWND = v
End Property

Function FindHwndForIDB(filename As String, Optional refresh As Boolean = False) As Long
    
    Dim h, idb As String
    Dim curHwnd As Long
    
    If refresh Then ipc.FindActiveIDAWindows
    
    curHwnd = ipc.RemoteHWND
    
    For Each h In ipc.Servers
        idb = Me.loadedFile()
        If InStr(1, idb, filename, vbTextCompare) > 0 Then
            FindHwndForIDB = CLng(h)
            Exit For
        End If
    Next
    
    ipc.RemoteHWND = curHwnd
    
End Function

'will find last opened instance if still active
Function FindClient() As Boolean
    Dim hwnd As Long
    
    On Error Resume Next
    
    hwnd = CLng(GetSetting("IPC", "Handles", "IDA_SERVER2", 0))
    If hwnd <> 0 Then
        If IsWindow(hwnd) = 1 Then
            FindClient = True
            ipc.RemoteHWND = hwnd
        Else
            SaveSetting "IPC", "Handles", "IDA_SERVER2", 0
            ipc.RemoteHWND = 0
            FindClient = False
        End If
    End If
    
End Function

Function SelectServer(Optional refresh As Boolean = True) As Long
    SelectServer = Form2.SelectIDAInstance(Me, refresh)
End Function

 
'-----------------------------------------------
'from idajscript 10.3.20 - stripped fso. calls, 'form1.hwnd -> ipc.ClientHwnd(new)
'-----------------------------------------------

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
    immvals = ipc.SendCmdRecvText("immvals:" & ea & ":" & ipc.ClientHwnd)
    MsgBox immvals
End Function

'Function getopn(ea)
'    getopn = ipc.SendCmdRecvInt("getopn:" & ea)
'End Function

Function getopv(ea, n)
    getopv = ipc.SendCmdRecvText("getopv:" & ea & ":" & n & ":" & ipc.ClientHwnd)
End Function

Function dumpFunc(i, flags)
    Dim p As String, r As Long
    p = GetFreeFileName(Environ("temp"))
    r = ipc.SendCmdRecvInt("dumpfunc:" & i & ":" & flags & ":" & Replace(p, ":", "_")) 'strtok :(
    If r = 1 Then dumpFunc = ReadFile(p)
    DeleteFile p
End Function

Function dumpFuncBytes(i)
    Dim p As String, r As Long
    p = GetFreeFileName(Environ("temp"))
    r = ipc.SendCmdRecvInt("dumpfuncbytes:" & i & ":" & Replace(p, ":", "_"))
    If r = 1 Then dumpFuncBytes = ReadFile(p)
    DeleteFile p
End Function

Private Sub Class_Initialize()
    Set ipc = New CIPC
    ipc.FindClient "IDA_SERVER2"
    ipc.Listen ipc.ClientHwnd
    tmp_x.use0x = True
    tmp_x.useTick = False
End Sub

'Property Get timeout()
'    timeout = 'form1.txtjs.timeout
'End Property
'
'Property Let timeout(v)
'    On Error Resume Next
'    'form1.txtjs.timeout = CLng(v)
'End Property

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

'Sub die(msg)
'    'form1.txtjs.timeout = 1
'    'form1.txtjs.StopExecution
'    t msg
'End Sub

Sub clearDecompilerCache()
    Me.quickCall 40, 0
End Sub

'Property Let caption(msg)
'    'form1.caption = msg
'    'form1.refresh
'    DoEvents
'End Property

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
    loadedFile = ipc.SendCmdRecvText("loadedfile:" & ipc.ClientHwnd)
End Property

'Sub t(data)
'    'form1.Text1.Text = 'form1.Text1.Text & vbCrLf & data
'    'form1.Text1.SelStart = Len('form1.Text1.Text)
'    DoEvents
'End Sub

'Sub clearLog()
'    'form1.Text1.Text = Empty
'End Sub

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
     
    'keep it 32bit if we can... (-1 went to full 64bit)
    intToHex = Hex(CLng(Replace(x, "0x", "&h")))
    
    If Err.Number = 0 Then
        If Len(intToHex) = 1 Then intToHex = "0" & intToHex
        intToHex = "0x" & intToHex
        Exit Function
    End If
    
    If Not tmp_x.fromString(x) Then
        ''form1.List1.AddItem "Failed to convert x: " & x
        Exit Function
    End If
    
    intToHex = tmp_x.toString(mHex)

End Function

Function getAsm(va)
    getAsm = ipc.SendCmdRecvText("getasm:" & va & ":" & ipc.ClientHwnd)
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
    Dim tmp() As String, x, y()
    tmp = Split(csv, ",")
    For Each x In tmp
        push y, tmp_x.setVal(x).toString(mHex)
    Next
    csvToHex = Join(y, ",")
End Function

Function xRefsTo(offset) 'returns CSV list
    Dim tmp
    tmp = ipc.SendCmdRecvText("refsto:" & offset & ":" & ipc.ClientHwnd)
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
    tmp = ipc.SendCmdRecvText("refsfrom:" & offset & ":" & ipc.ClientHwnd)
    If Right(tmp, 1) = "," Then tmp = Mid(tmp, 1, Len(tmp) - 1)
    If is64BitMode Then
        xRefsFrom = csvToHex(tmp)
    Else
        'tmp = Split(tmp, ",") javascript cant deal with string() must be variant()?
        xRefsFrom = tmp
    End If
End Function


Function getName(offset)
    getName = ipc.SendCmdRecvText("getname:" & offset & ":" & ipc.ClientHwnd)
    If getName = "NULL" Then getName = ""
End Function

 Function functionName(functionIndex)
    functionName = ipc.SendCmdRecvText("funcname:" & functionIndex & ":" & ipc.ClientHwnd)
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

Sub setname(offset, Name)
    ipc.Send "setname:" & offset & ":" & CStr(Name)
 End Sub

Sub addComment(offset, comment)
    ipc.Send "addcomment:" & offset & ":" & comment
End Sub

Function getComment(offset)
    getComment = ipc.SendCmdRecvText("getcomment:" & offset & ":" & ipc.ClientHwnd)
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
        funcVAByName = ipc.SendCmdRecvText("name_va:" & Name & ":" & ipc.ClientHwnd)
        funcVAByName = tmp_x.setVal(funcVAByName).toString(mHex)
    End If
End Function

Function renameFunc(oldname, newName) As Boolean
    renameFunc = IIf(ipc.SendCmdRecvInt("rename:" & oldname & ":" & newName) = 1, True, False)
End Function

 'todo x64
Function find(startea, endea, hexstr) '-1 if fail
    'findcode:start:end:hexstr
    find = ipc.SendCmdRecvInt("findcode:" & startea & ":" & endea & ":" & hexstr)
End Function

Function decompile(va) As String
    Dim pth As String, r As Long
    
    pth = Environ("temp")
    pth = GetFreeFileName(pth)
                                                        'its our token we will need to replace it latter :-\ foresight denied!
    r = ipc.SendCmdRecvInt("decompile:" & va & ":" & Replace(pth, ":", "_"))
    
    If r = 1 And FileExists(pth) Then
        decompile = ReadFile(pth)
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
            ''form1.List1.AddItem "Failed to convert va: " & va
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
            'form1.List1.AddItem "Failed to convert va: " & va
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
            'form1.List1.AddItem "Failed to convert va: " & va
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
            'form1.List1.AddItem "Failed to convert va: " & va
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
            'form1.List1.AddItem "Failed to convert va: " & va
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
            'form1.List1.AddItem "Failed to convert va: " & va
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
            'form1.List1.AddItem "Failed to convert va: " & va
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
            'form1.List1.AddItem "Failed to convert va: " & va
            Exit Function
        End If
        nextEA = ipc.SendCmdRecvText("nextea:" & tmp_x.toString(mHex) & ":" & ipc.ClientHwnd)
        nextEA = tmp_x.setVal(nextEA).toString(mHex)
    End If
End Function

Function prevEA(va)
    On Error Resume Next
    If Not is64BitMode Then
        prevEA = ipc.quickCall(qcmPrevEa_32, cCLng(va))
    Else
        If Not tmp_x.fromString(va) Then
            'form1.List1.AddItem "Failed to convert va: " & va
            Exit Function
        End If
        prevEA = ipc.SendCmdRecvText("prevea:" & tmp_x.toString(mHex) & ":" & ipc.ClientHwnd)
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
        functionStart = ipc.SendCmdRecvText("funcstart:" & functionIndex & ":" & ipc.ClientHwnd)
        functionStart = tmp_x.setVal(functionStart).toString(mHex)
     End If
 End Function

 Function functionEnd(functionIndex)
     On Error Resume Next
     If Not is64BitMode Then
        functionEnd = ipc.quickCall(qcmFuncEnd_32, cCLng(functionIndex))
     Else
        functionEnd = ipc.SendCmdRecvText("funcend:" & functionIndex & ":" & ipc.ClientHwnd)
        functionEnd = tmp_x.setVal(functionEnd).toString(mHex)
     End If
 End Function
  
 Function readByte(va)
     On Error Resume Next
     If Not is64BitMode Then
        readByte = CByte(ipc.quickCall(qcmReadByte_32, cCLng(va)))
     Else
        If Not tmp_x.fromString(va) Then
            'form1.List1.AddItem "Failed to convert va: " & va
            Exit Function
        End If
        readByte = ipc.SendCmdRecvText("readbyte:" & tmp_x.toString(mHex) & ":" & ipc.ClientHwnd)
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
            'form1.List1.AddItem "Failed to convert va: " & va
            Exit Function
        End If
        readLong = ipc.SendCmdRecvInt("getlong:" & tmp_x.toString(mHex)) ' & ":" & ipc.ClientHwnd)
    End If
End Function

Function readQWord(va)
    On Error Resume Next
    If Not tmp_x.fromString(va) Then
        'form1.List1.AddItem "Failed to convert va: " & va
        Exit Function
    End If
    readQWord = ipc.SendCmdRecvText("getx64:" & tmp_x.toString(mHex) & ":" & ipc.ClientHwnd)
End Function

Function readShort(va)
    On Error Resume Next
    If Not is64BitMode Then
         If va = 0 Or va = -1 Then Exit Function
         readShort = CLng(ipc.quickCall(qcmReadShort_32, cCLng(va)))
    Else
        If Not tmp_x.fromString(va) Then
            'form1.List1.AddItem "Failed to convert va: " & va
            Exit Function
        End If
        readShort = ipc.SendCmdRecvInt("getword:" & tmp_x.toString(mHex)) '& ":" & ipc.ClientHwnd)
    End If
End Function

Function originalByte(va)
    On Error Resume Next
    
    If Not is64BitMode Then
         If va = 0 Or va = -1 Then Exit Function
         originalByte = CByte(ipc.quickCall(qcmOrgByte_32, cCLng(va)))
    Else
        If Not tmp_x.fromString(va) Then
            'form1.List1.AddItem "Failed to convert va: " & va
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
        imageBase = ipc.SendCmdRecvText("imgbase:" & ipc.ClientHwnd)
        imageBase = tmp_x.setVal(imageBase).toString(mHex)
    End If
End Function

Function screenEA()
    If Not is64BitMode Then
        screenEA = ipc.quickCall(qcmScreenEA_32)
    Else
        screenEA = ipc.SendCmdRecvText("screenea:" & ipc.ClientHwnd)
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
'
'Function askValue(Optional prompt, Optional defVal) As String
'    askValue = InputBox(prompt, , defVal)
'End Function
'
'Sub exec(cmd)
'   On Error Resume Next
'   Shell cmd, vbNormalFocus
'End Sub

'Function ReadFile(filename) As Variant
'  Dim f As Long
'  Dim Temp As Variant
'
'  On Error Resume Next
'
'  If InStr(1, filename, "%sp%", vbTextCompare) > 0 Then
'        If Len('form1.loadedFile) = 0 Then
'            MsgBox "can not use %sp variable yet in file path file not saved!"
'            Exit Function
'        End If
'
'        Temp = GetParentFolder('form1.loadedFile)
'        filename = Replace(filename, "%sp%", Temp, , , vbTextCompare)
'  End If
'
'  'todo support %desktop%
'
'  f = FreeFile
'  Temp = ""
'   Open filename For Binary As #f        ' Open file.(can be text or image)
'     Temp = Input(FileLen(filename), #f) ' Get entire Files data
'   Close #f
'   ReadFile = Temp
'End Function
'
'Sub WriteFile(path, it)
'    On Error Resume Next
'
'    Dim Temp As String
'
'    If InStr(1, path, "%sp%", vbTextCompare) > 0 Then
'
'        If Len('form1.loadedFile) = 0 Then
'            MsgBox "can not use %sp variable yet in file path file not saved!"
'            Exit Sub
'        End If
'
'        Temp = GetParentFolder('form1.loadedFile)
'        path = Replace(path, "%sp%", Temp, , , vbTextCompare)
'
'    End If
'
'    Dim f As Long
'    f = FreeFile
'    Open path For Output As #f
'    Print #f, it
'    Close f
'
'End Sub
'
'Sub AppendFile(path, it)
'    Dim f As Long
'    f = FreeFile
'    Open path For Append As #f
'    Print #f, it
'    Close f
'End Sub
'
'Function FileExists(path) As Boolean
'  On Error GoTo hell
'  Dim tmp As String
'  tmp = Replace(path, "'", Empty)
'  tmp = Replace(tmp, """", Empty)
'  If Len(tmp) = 0 Then Exit Function
'  If Dir(tmp, vbHidden Or vbNormal Or vbReadOnly Or vbSystem) <> "" Then FileExists = True
'  Exit Function
'hell: FileExists = False
'End Function
'
'Function DeleteFile(fpath) As Boolean
' On Error GoTo hadErr
'    Kill fpath
'    DeleteFile = True
' Exit Function
'hadErr:
''MsgBox "DeleteFile Failed" & vbCrLf & vbCrLf & fpath
'DeleteFile = False
'End Function
'
'Function getClipboard()
'    getClipboard = Clipboard.GetText()
'End Function
'
'Function setClipboard(x)
'    Clipboard.Clear
'    Clipboard.SetText x
'End Function
'
'Function openFileDialog() As String
'    openFileDialog = dlg.OpenDialog(AllFiles)
'End Function
'
'Function saveFileDialog() As String
'    saveFileDialog = dlg.SaveDialog(AllFiles)
'End Function

'Function benchMark() As Long
'    Dim i As LARGE_INTEGER
'    QueryPerformanceCounter i
'    benchMark = i.lowpart
'End Function
'
'Function hexDump(x) As String
'    hexDump = Module1.hexDump(CStr(x), , , hoDump)
'End Function
'
'Function hexstr(x) As String
'    hexstr = Module1.hexDump(CStr(x), , , hoHexOnly)
'End Function
'
'Function toBytes(hexstr) As String
'    Dim out As String
'    If Module1.toBytes(CStr(hexstr), out) Then toBytes = out
'End Function



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

