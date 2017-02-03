VERSION 5.00
Begin VB.Form Form1 
   Caption         =   "Embed memory dumps into 32bit dll husk for quick disassembly at proper VA's"
   ClientHeight    =   3375
   ClientLeft      =   60
   ClientTop       =   345
   ClientWidth     =   9315
   LinkTopic       =   "Form1"
   ScaleHeight     =   3375
   ScaleWidth      =   9315
   StartUpPosition =   2  'CenterScreen
   Begin VB.ListBox List1 
      BeginProperty Font 
         Name            =   "Courier"
         Size            =   12
         Charset         =   0
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      Height          =   2460
      Left            =   810
      TabIndex        =   2
      Top             =   675
      Width           =   8340
   End
   Begin VB.CommandButton Command1 
      Caption         =   "Generate"
      Height          =   420
      Left            =   7605
      TabIndex        =   1
      Top             =   135
      Width           =   1590
   End
   Begin VB.TextBox Text1 
      Height          =   375
      Left            =   810
      OLEDropMode     =   1  'Manual
      TabIndex        =   0
      Text            =   " drop folder here.."
      Top             =   180
      Width           =   4470
   End
   Begin VB.Label Label2 
      Caption         =   "File"
      Height          =   285
      Left            =   90
      TabIndex        =   3
      Top             =   225
      Width           =   600
   End
End
Attribute VB_Name = "Form1"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Dim dummy As String
Dim sects As Collection 'of CSection
Dim lowestBase As Double

'https://support.microsoft.com/en-us/kb/189323
Private Const OFFSET_4 = 4294967296#
Private Const MAXINT_4 = 2147483647

Function UnsignedToLong(Value As Double) As Long
  If Value < 0 Or Value >= OFFSET_4 Then Error 6 ' Overflow
  If Value <= MAXINT_4 Then
    UnsignedToLong = Value
  Else
    UnsignedToLong = Value - OFFSET_4
  End If
End Function

Function LongToUnsigned(Value As Long) As Double
  If Value < 0 Then
    LongToUnsigned = Value + OFFSET_4
  Else
    LongToUnsigned = Value
  End If
End Function
      
Private Sub Command1_Click()

    Dim files() As String
    Dim f
    Dim success As Long
    Dim outFile As String
    Dim fOut As Long
    Dim sect As CSection
    Dim udtSect As IMAGE_SECTION_HEADER
    Dim sBase As String
    
    'On Error GoTo hell
    
    List1.Clear
    Set sects = New Collection
    
    If Not FolderExists(Text1) Then
        MsgBox "You must specify a file or folder to process...", vbCritical
        Exit Sub
    End If
    
    outFile = Text1 & "\conglomerated_dmp.dll"
    List1.AddItem "Generating " & outFile
    
    If FileExists(outFile) Then
        If displayInfo Then List1.AddItem "Deleting old file.."
        Kill outFile
    End If
    
    List1.AddItem "Copying dummy.dll to new file.."
    FileCopy dummy, outFile
    
    fOut = FreeFile
    Open outFile For Binary As fOut
     
    files() = GetFolderFiles(Text1, ".mem")
    
    If AryIsEmpty(files) Then
        files() = GetFolderFiles(Text1, ".bin")
    End If
    
    If AryIsEmpty(files) Then
        List1.AddItem "No .mem or .bin files to operate on!"
        Exit Sub
    End If
    
    Dim tmp As Double
    lowestBase = OFFSET_4 'max unsigned long..
    
    For Each f In files
        sBase = BaseFromFileName(f)
        If Len(sBase) > 0 Then
            tmp = LongToUnsigned(CLng("&h" & sBase))
            If tmp < lowestBase Then lowestBase = tmp
        End If
    Next
     
    lowestBase = lowestBase - &H1000 'for MZ and headers
    Put fOut, &H124 + 1, UnsignedToLong(lowestBase)  'image base
     
    For Each f In files
        sBase = BaseFromFileName(f)
        If Len(sBase) = 0 Then
            List1.AddItem "No Base?  Skipping " & FileNameFromPath(f)
        Else
            AppendFile f, fOut, CLng("&h" & sBase)
            inc success
        End If
     Next

     List1.AddItem "Embedding sections.."
     
     Seek fOut, &H1E8 + 1 'start of sections
     
     For Each sect In sects
         udtSect = sect.GetStruc()
         Put fOut, , udtSect
     Next
     
     List1.AddItem "Fixing up PE attributes for easy disassembly.."
     Put fOut, &H140 + 1, CLng(LOF(fOut)) + 1 'image size
     Put fOut, &HF6 + 1, CInt(sects.Count)    'number of sections
     
     Close fOut
     
     List1.AddItem success & "/" & (UBound(files) + 1) & " files processed successfully."
     
     
    Exit Sub
hell:
    
    List1.AddItem "Error:: " & Err.Description
    
End Sub
    
Sub inc(ByRef v As Long)
    v = v + 1
End Sub

Function AppendFile(pth, hOutFile As Long, baseAddr As Long)
    
    'On Error GoTo hell
    Dim b() As Byte
    Dim padding As Long
    Dim c As New CSection
    
    f = FreeFile
    Open pth For Binary As f
    ReDim b(LOF(f) + 1)
    Get f, , b()
    Close f
    
    List1.AddItem "Appending: " & FileNameFromPath(pth)
    
    Dim adjustedBase As Double
    adjustedBase = LongToUnsigned(baseAddr) - lowestBase
    
    c.nameSec = "s" & sects.Count + 1
    c.index = sects.Count + 1
    c.PointerToRawData = LOF(hOutFile)
    c.VirtualAddress = UnsignedToLong(adjustedBase)
 
    Put hOutFile, LOF(hOutFile) + 1, b() 'append the memory dump to dummy header..
    
    While LOF(hOutFile) Mod &H1000 <> 0 'file and section alignment has been set to 0x1000..
        Put hOutFile, , CByte(0)
        inc padding
    Wend
    
    c.SizeOfRawData = CLng(UBound(b)) + 1 '+ padding
    c.VirtualSize = c.SizeOfRawData
    
    'ReDim b(1 To &H10)
    'Put hOutFile, , b()
    sects.Add c
    
    Exit Function
    
hell:
    List1.AddItem "Error processing " & pth
    List1.AddItem "   Description:" & Err.Description
    
End Function



Private Sub Form_Load()
    
    dummy = App.path & "\dummy.dll"
    
    If Not FileExists(dummy) Then
        List1.AddItem "Dummy dll not found? must be in app.path"
        Command1.Enabled = False
    End If
    
End Sub

Private Sub Form_Resize()
    On Error Resume Next
    With List1
        .Width = Me.Width - .Left - 200
        .Height = Me.Height - .Top - 200
    End With
End Sub

Private Sub Text1_OLEDragDrop(Data As DataObject, Effect As Long, Button As Integer, Shift As Integer, x As Single, Y As Single)
    Text1 = Data.files(1)
    If FileExists(Text1) Then Text2 = BaseFromFileName(Text1) Else Text2 = Empty
End Sub

Function BaseFromFileName(x) As String
    Dim base As String
    base = FileNameFromPath(x)
    a = InStrRev(base, "_")
    If a > 0 Then
        BaseFromFileName = Mid(base, a + 1)
        BaseFromFileName = Replace(BaseFromFileName, ".mem", "")
        BaseFromFileName = Replace(BaseFromFileName, ".bin", "")
        If Not isHex(BaseFromFileName) Then BaseFromFileName = Empty
    Else
        BaseFromFileName = Replace(base, ".mem", "")
        BaseFromFileName = Replace(BaseFromFileName, ".bin", "")
        If Not isHex(BaseFromFileName) Then BaseFromFileName = Empty
    End If
End Function

Function isHex(x) As Boolean
    On Error GoTo hell
    Hex CLng("&h" & x)
    isHex = True
    Exit Function
hell:
End Function



Function FileNameFromPath(fullpath) As String
    If InStr(fullpath, "\") > 0 Then
        tmp = Split(fullpath, "\")
        FileNameFromPath = CStr(tmp(UBound(tmp)))
    End If
End Function


Function GetFolderFiles(folder, Optional filter = ".*", Optional retFullPath As Boolean = True) As String()
   Dim fnames() As String
   
   If Not FolderExists(folder) Then
        'returns empty array if fails
        GetFolderFiles = fnames()
        Exit Function
   End If
   
   folder = IIf(Right(folder, 1) = "\", folder, folder & "\")
   If Left(filter, 1) = "*" Then extension = Mid(filter, 2, Len(filter))
   If Left(filter, 1) <> "." Then filter = "." & filter
   
   fs = Dir(folder & "*" & filter, vbHidden Or vbNormal Or vbReadOnly Or vbSystem)
   While fs <> ""
     If fs <> "" Then push fnames(), IIf(retFullPath = True, folder & fs, fs)
     fs = Dir()
   Wend
   
   GetFolderFiles = fnames()
End Function

Function FolderExists(path) As Boolean
  If Len(path) = 0 Then Exit Function
  If Dir(path, vbDirectory) <> "" Then FolderExists = True _
  Else FolderExists = False
End Function

Function FileExists(path) As Boolean
  If Len(path) = 0 Then Exit Function
  If Dir(path, vbHidden Or vbNormal Or vbReadOnly Or vbSystem) <> "" Then FileExists = True _
  Else FileExists = False
End Function



Sub push(ary, Value) 'this modifies parent ary object
    On Error GoTo init
    x = UBound(ary) '<-throws Error If Not initalized
    ReDim Preserve ary(UBound(ary) + 1)
    ary(UBound(ary)) = Value
    Exit Sub
init:     ReDim ary(0): ary(0) = Value
End Sub

Function GetParentFolder(path) As String
    tmp = Split(path, "\")
    ub = tmp(UBound(tmp))
    GetParentFolder = Replace(Join(tmp, "\"), "\" & ub, "")
End Function

