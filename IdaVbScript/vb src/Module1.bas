Attribute VB_Name = "Module1"
Option Explicit
'dzzie@yahoo
'http://sandsprite.com
 
Global clsSect As New CSections
Global cIda As New CIDAScript
Global IDASCK As New CIDASocket

Global gdlg As New clsCmnDlg
Global gfso As New clsFileSystem

'Global hash As New CWinHash

Public Declare Sub HideEA Lib "idavbscript.plw" (ByVal addr As Long)
Public Declare Sub ShowEA Lib "idavbscript.plw" (ByVal addr As Long)

Public Declare Function NextAddr Lib "idavbscript.plw" (ByVal addr As Long) As Long
Public Declare Function PrevAddr Lib "idavbscript.plw" (ByVal addr As Long) As Long

Public Declare Function OriginalByte Lib "idavbscript.plw" (ByVal addr As Long) As Byte
Public Declare Function IDAFilePath Lib "idavbscript.plw" Alias "FilePath" (ByVal buf_maxpath As String) As Long
Public Declare Function RootFileName Lib "idavbscript.plw" (ByVal buf_maxpath As String) As Long
Public Declare Function ProcessState Lib "idavbscript.plw" () As Long

Public Declare Function FuncIndex Lib "idavbscript.plw" (ByVal addr As Long) As Long
Public Declare Function FuncArgSize Lib "idavbscript.plw" (ByVal Index As Long) As Long
Public Declare Function FuncColor Lib "idavbscript.plw" (ByVal Index As Long) As Colors
Public Declare Sub PatchByte Lib "idavbscript.plw" (ByVal addr As Long, ByVal valu As Byte)
Public Declare Sub PatchWord Lib "idavbscript.plw" (ByVal addr As Long, ByVal valu As Long)
Public Declare Sub DelFunc Lib "idavbscript.plw" (ByVal addr As Long)
Public Declare Sub AddComment Lib "idavbscript.plw" (ByVal cmt As String)
Public Declare Sub AddProgramComment Lib "idavbscript.plw" (ByVal cmt As String)
Public Declare Sub AddCodeXRef Lib "idavbscript.plw" (ByVal start As Long, ByVal endd As Long)
Public Declare Sub DelCodeXRef Lib "idavbscript.plw" (ByVal start As Long, ByVal endd As Long)
Public Declare Sub AddDataXRef Lib "idavbscript.plw" (ByVal start As Long, ByVal endd As Long)
Public Declare Sub DelDataXRef Lib "idavbscript.plw" (ByVal start As Long, ByVal endd As Long)
Public Declare Sub MessageUI Lib "idavbscript.plw" (ByVal msg As String)
 

Public Declare Sub MakeCode Lib "idavbscript.plw" (ByVal addr As Long)
Public Declare Sub Undefine Lib "idavbscript.plw" (ByVal addr As Long)
Public Declare Sub AnalyzeArea Lib "idavbscript.plw" (ByVal startat As Long, ByVal endat As Long)
Public Declare Sub aGetName Lib "idavbscript.plw" Alias "GetName" (ByVal addr As Long, ByVal buf As String, ByVal bufsize As Long)
 
Public Declare Function SetComment Lib "idavbscript.plw" (ByVal addr As Long, ByVal comment As String) As Long
Private Declare Function GetComment Lib "idavbscript.plw" (ByVal addr As Long, ByVal comment As String) As Long
Private Declare Function GetRComment Lib "idavbscript.plw" (ByVal addr As Long, ByVal comment As String) As Long


Public Declare Function NumFuncs Lib "idavbscript.plw" () As Long
Public Declare Function FunctionStart Lib "idavbscript.plw" (ByVal functionIndex As Long) As Long
Public Declare Function FunctionEnd Lib "idavbscript.plw" (ByVal functionIndex As Long) As Long
Public Declare Sub Jump Lib "idavbscript.plw" (ByVal offset As Long)
Public Declare Sub RemvName Lib "idavbscript.plw" (ByVal offset As Long)
Public Declare Sub Setname Lib "idavbscript.plw" (ByVal offset As Long, ByVal Name As String)
Public Declare Sub aRefresh Lib "idavbscript.plw" Alias "Refresh" ()
Public Declare Function ScreenEA Lib "idavbscript.plw" () As Long
Public Declare Sub SelBounds Lib "idavbscript.plw" (selstart As Long, selend As Long)
Public Declare Function GetBytes Lib "idavbscript.plw" (ByVal offset As Long, buf As Byte, ByVal Length As Long) As Long
Private Declare Sub FuncName Lib "idavbscript.plw" (ByVal offset As Long, ByVal buf As String, ByVal bufsize As Long)
Private Declare Function GetAsm Lib "idavbscript.plw" (ByVal offset As Long, ByVal buf As String, ByVal Length As Long) As Long

'int __stdcall SearchTextStart(int addr, char* buf){
Declare Function SearchText Lib "idavbscript.plw" (ByVal offset As Long, ByVal buf As String, Optional ByVal stype As Searchtype = 1, Optional ByVal ddebug As Long = 0) As Long

Private Declare Function GetRefsTo Lib "idavbscript.plw" (ByVal offset As Long, ByVal callback As Long) As Long
Private Declare Function GetRefsFrom Lib "idavbscript.plw" (ByVal offset As Long, ByVal callback As Long) As Long

Private RefsTo As Collection
Private RefsFrom As Collection

Enum Searchtype
    SEARCH_UP = 0
    SEARCH_DOWN = 1
    SEARCH_NEXT = 2
End Enum
 
 
Enum Colors
        COLOR_DEFAULT = &H1           ' Default
        COLOR_REGCMT = &H2            ' Regular comment
        COLOR_RPTCMT = &H3            ' Repeatable comment (comment defined somewhere else)
        COLOR_AUTOCMT = &H4           ' Automatic comment
        COLOR_INSN = &H5              ' Instruction
        'COLOR_DATNAME = &H6           ' Dummy Data Name
        'COLOR_DNAME = &H7             ' Regular Data Name
        'COLOR_DEMNAME = &H8           ' Demangled Name
        'COLOR_SYMBOL = &H9            ' Punctuation
        'COLOR_CHAR = &HA              ' Char constant in instruction
        'COLOR_STRING = &HB            ' String constant in instruction
        'COLOR_NUMBER = &HC            ' Numeric constant in instruction
        'COLOR_VOIDOP = &HD            ' Void operand
        'COLOR_CREF = &HE              ' Code reference
        'COLOR_DREF = &HF              ' Data reference
        'COLOR_CREFTAIL = &H10         ' Code reference to tail byte
        'COLOR_DREFTAIL = &H11         ' Data reference to tail byte
        COLOR_ERROR = &H12            ' Error or problem
        COLOR_PREFIX = &H13           ' Line prefix
        COLOR_BINPREF = &H14          ' Binary line prefix bytes
        COLOR_EXTRA = &H15            ' Extra line
        COLOR_ALTOP = &H16            ' Alternative operand
        'COLOR_HIDNAME = &H17          ' Hidden name
        COLOR_LIBNAME = &H18          ' Library function name
        COLOR_LOCNAME = &H19          ' Local variable name
        COLOR_CODNAME = &H1A          ' Dummy code name
        COLOR_ASMDIR = &H1B           ' Assembler directive
        'COLOR_MACRO = &H1C            ' Macro
        COLOR_DSTR = &H1D             ' String constant in data directive
        COLOR_DCHAR = &H1E            ' Char constant in data directive
        COLOR_DNUM = &H1F             ' Numeric constant in data directive
        COLOR_KEYWORD = &H20          ' Keywords
        'COLOR_REG = &H21              ' Register name
        COLOR_IMPNAME = &H22          ' Imported name
        'COLOR_SEGNAME = &H23          ' Segment name
        'COLOR_UNKNAME = &H24          ' Dummy unknown name
        COLOR_CNAME = &H25            ' Regular code name
        'COLOR_UNAME = &H26            ' Regular unknown name
        'COLOR_COLLAPSED = &H27        ' Collapsed line
        'COLOR_FG_MAX = &H28           ' Max color number
End Enum


Type ImgDosHeader
    stuff(1 To 60) As Byte 'soak up uneeded fields
    pOptHeader As Long
End Type

Type ImgOptHeader
    Signature As String * 4      '\
    Machine As Integer           ' \_ 128
    NumberOfSections As Integer  ' /
    stuff(1 To 120) As Byte      '/
    pImportTable As Long    'datadir(Import_Table).rvaAddress
    ImportSize As Long      'datadir(Import_Table).size
    ddRemainder(1 To 112) As Byte
End Type

Type SECTION_HEADER
    nameSec As String * 8
    'PhisicalAddress As Integer
    VirtualSize As Long
    VirtualAddress As Long
    SizeOfRawData As Long
    PointerToRawData As Long
    stuff(1 To 12) As Byte
    Characteristics As Long
End Type

Public Declare Function SetParent Lib "User32" (ByVal hWndChild As Long, ByVal hWndNewParent As Long) As Long
Public Declare Function ShowWindow Lib "User32" (ByVal hWnd As Long, ByVal nCmdShow As Long) As Long



Function GetFName(offset As Long) As String
    Dim buf As String
    Dim l As Long
    
    buf = String(257, Chr(0))
    
    FuncName offset, buf, Len(buf)
    
    l = InStr(buf, Chr(0))
    If l > 1 Then buf = Mid(buf, 1, l)
    
    GetFName = buf
    
End Function

Function GetHex(x As Byte) As String
    Dim y As String
    y = Hex(x)
    If x < &H10 Then y = "0" & y
    GetHex = y
End Function

Function GetAsmCode(offset) As String
    Dim buf As String
    Dim sLen As Long
    
    buf = String(257, Chr(0))
    
    sLen = GetAsm(offset, buf, Len(buf))
    
    If sLen > 1 Then
        GetAsmCode = Mid(buf, 1, sLen)
    End If
    
End Function

Function Set_Comment(offset, comm As String)
    On Error Resume Next
    Dim buf As String
    buf = comm
    Set_Comment = SetComment(CLng(offset), buf)
End Function


Function Get_Comment(offset)
    On Error Resume Next
    Dim buf As String
    Dim sz As Long
    buf = String(511, " ")
    sz = GetComment(CLng(offset), buf)
    If sz > 0 Then buf = Trim(Mid(buf, 1, sz))
    Get_Comment = buf
End Function

Function Get_RComment(offset)
    On Error Resume Next
    Dim buf As String
    Dim sz As Long
    buf = String(511, " ")
    sz = GetRComment(CLng(offset), buf)
    If sz > 0 Then buf = Trim(Mid(buf, 1, sz))
    Get_RComment = buf
End Function

'this is soooo crude!
Function InstructionLength(offset As Long) As Long
    Dim x As String, tmp As String, i As Long, n As String
    Dim firstea As Long, secondea As Long
    Dim leng As Long
    
    leng = 40
    firstea = 0
    secondea = 0
    For i = 0 To leng - 1
        tmp = GetAsmCode(offset + i)
        If Len(tmp) > 0 Then
            If firstea = 0 Then
                firstea = offset + i
            ElseIf secondea = 0 Then
                 secondea = offset + i
            End If
            If firstea > 0 And secondea > 0 Then Exit For
        End If
    Next
    
    InstructionLength = secondea - firstea
    
    
End Function

Function ScanForInstruction(offset As Long, find_inst As String, scan_x_lines As Long) As Long
    
    Dim bufsize As Long
    Dim tmp() As String
    Dim x
    Dim count As Long
    
    bufsize = scan_x_lines * 16 'each line of asm can be max of 16 bytes
    tmp = Split(GetAsmRange(offset, bufsize), vbCrLf)
    
    For Each x In tmp
        If count > scan_x_lines Then Exit For
        
        While InStr(x, "  ") > 0
            x = Replace(x, "  ", " ")
        Wend
        
        If InStr(1, x, find_inst, vbTextCompare) > 0 Then
            x = Mid(x, 1, InStr(x, " "))
            ScanForInstruction = CLng("&h" & x)
            Exit For
        End If
        count = count + 1
    Next
    
End Function


Function GetAsmRange(start As Long, leng As Long, Optional asmOnly As Integer = 0) As String
    Dim x As String, tmp As String, i As Long, n As String
    
    For i = 0 To leng - 1
        
        tmp = GetAsmCode(start + i)
        If Len(tmp) > 0 Then
            
            If i <> 0 Then 'add in local labels...bug not the function name (offset 0)
                n = GetName(start + i)
                If Len(n) > 0 Then x = x & vbCrLf & IIf(asmOnly = 0, vbTab, "") & n & ":" & vbCrLf
            End If
                 
            If asmOnly > 0 Then
                 x = x & tmp & vbCrLf
            Else
                x = x & Hex(start + i) & "  " & InstructionLength(start + i) & "  " & tmp & vbCrLf
            End If
        End If
        
                
    Next
    
    GetAsmRange = x
    
End Function

Function HexDumpBytes(start As Long, leng As Long) As String
    Dim buf() As Byte, i As Integer, x As String
    
    ReDim buf(1 To leng)
    GetBytes start, buf(1), leng
    
    For i = 1 To leng
        x = x & GetHex(buf(i)) & " "
    Next
    
    HexDumpBytes = x
    
End Function

Function GetName(offset) As String
    Dim buf As String, x
    buf = String(257, Chr(0))
    
    aGetName CLng(offset), buf, 257
    
    x = InStr(buf, Chr(0))
    If x = 1 Then
        buf = ""
    ElseIf x > 2 Then
        buf = Mid(buf, 1, x - 1)
    End If
    
    GetName = buf

End Function

Sub push(ary, value) 'this modifies parent ary object
    On Error GoTo init
    Dim x As Long
    x = UBound(ary) '<-throws Error If Not initalized
    ReDim Preserve ary(UBound(ary) + 1)
    ary(UBound(ary)) = value
    Exit Sub
init:     ReDim ary(0): ary(0) = value
End Sub

Function FileExists(path) As Boolean
  If Len(path) = 0 Then Exit Function
  If Dir(path, vbHidden Or vbNormal Or vbReadOnly Or vbSystem) <> "" Then FileExists = True
End Function


Function loadedFile() As String
    Dim buf As String
    Dim retlen As Long
    buf = String(256, Chr(0))
    
    retlen = IDAFilePath(buf)
    loadedFile = Mid(buf, 1, retlen)
End Function

Function GetHextxt(t As TextBox, v As Long) As Boolean
    
    On Error Resume Next
    v = CLng("&h" & t)
    If Err.Number > 0 Then
        MsgBox "Error " & t.Text & " is not valid hex number", vbInformation
        Exit Function
    End If
    
    GetHextxt = True
    
End Function

Function GetFuncOffset(function_name) As Long
    Dim cnt As Long
    Dim offset As Long
    Dim i As Long
    Dim fname As String
    On Error Resume Next
    
    cnt = NumFuncs
    'MessageUI "Num funcs=" & cnt
    For i = 0 To cnt - 1 'NumFuncs ary 0 based
        offset = FunctionStart(i)
        fname = Replace(LCase(Trim(GetFName(offset))), Chr(0), Empty)
        'MessageUI "on: " & fname
        If LCase(function_name) = fname Then
            GetFuncOffset = offset
            MessageUI "Match found"
            Exit For
        End If
    Next
        
End Function

Sub Enable(t As TextBox, Optional enabled = True)
    t.BackColor = IIf(enabled, vbWhite, &H80000004)
    t.enabled = enabled
    t.Text = Empty
End Sub

Function GetXRefTo(offset As Long) As Collection
    Set RefsTo = New Collection
    Dim cnt As Long
    cnt = GetRefsTo(offset, AddressOf CallBackXrefTo)
    'MsgBox "Count: " & cnt
    Set GetXRefTo = RefsTo
End Function

Function GetXRefFrom(offset As Long) As Collection
    Dim cnt As Long
    Set RefsFrom = New Collection
    cnt = GetRefsFrom(offset, AddressOf CallBackXrefFrom)
    'MsgBox "Count: " & cnt
    Set GetXRefFrom = RefsFrom
End Function

Function CallBackXrefTo(ByVal offset As Long, ByVal xref_to As Long) As Long
    RefsTo.Add xref_to
    'MsgBox "Callback to " & Hex(offset) & " " & Hex(xref_to)
    CallBackXrefTo = 1 'return -1 to stop
End Function

Function CallBackXrefFrom(ByVal offset As Long, ByVal xref_from As Long) As Long
    RefsFrom.Add xref_from
    'MsgBox "Callback from " & Hex(offset) & " " & Hex(xref_from)
    CallBackXrefFrom = 1 'return -1 to stop
End Function

Function FunctionAtVA(va As Long) As CFunction

    On Error Resume Next
    Dim f As CFunction
    
    For Each f In frmPluginSample.Functions
        If va >= f.StartEA And va <= f.EndEA Then
            Set FunctionAtVA = f
            Exit Function
        End If
    Next
    
    Set f = New CFunction
    Set FunctionAtVA = f  'return an empty object (error friendly)
    
End Function
