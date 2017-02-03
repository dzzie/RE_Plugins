VERSION 5.00
Begin VB.Form Form1 
   Caption         =   "Embed memory dump into 32bit dll husk for quick disassembly at proper VA"
   ClientHeight    =   3375
   ClientLeft      =   60
   ClientTop       =   345
   ClientWidth     =   9315
   LinkTopic       =   "Form1"
   ScaleHeight     =   3375
   ScaleWidth      =   9315
   StartUpPosition =   2  'CenterScreen
   Begin VB.CommandButton Command2 
      Caption         =   "?"
      Height          =   405
      Left            =   210
      TabIndex        =   6
      Top             =   810
      Width           =   525
   End
   Begin VB.TextBox Text2 
      Height          =   330
      Left            =   5985
      TabIndex        =   4
      Top             =   180
      Width           =   1365
   End
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
      Top             =   180
      Width           =   4470
   End
   Begin VB.Label Label2 
      Caption         =   "File"
      Height          =   285
      Left            =   90
      TabIndex        =   5
      Top             =   225
      Width           =   600
   End
   Begin VB.Label Label1 
      Caption         =   "base"
      Height          =   285
      Left            =   5445
      TabIndex        =   3
      Top             =   225
      Width           =   465
   End
End
Attribute VB_Name = "Form1"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Dim dummy As String

Private Sub Command1_Click()

    Dim files() As String
    Dim f
    Dim success As Long
    
    On Error GoTo hell
    
    List1.Clear
    
    If Not FileExists(Text1) And Not FolderExists(Text1) Then
        MsgBox "You must specify a file or folder to process...", vbCritical
        Exit Sub
    End If
    
    If FileExists(Text1) Then

        If Len(Text2) = 0 Then
            Text2 = BaseFromFileName(Text1)
            If Len(Text2) = 0 Then
                List1.AddItem "Could not extract base address from file name. "
                List1.AddItem "  Skipping " & FileNameFromPath(f)
                Exit Sub
            End If
        End If
            
        If Not isHex(Text2) Then
            MsgBox "Base address not valid hex string", vbCritical
            Exit Sub
        End If
    
        WrapFile Text1, True
    
    Else
        
        files() = GetFolderFiles(Text1, ".mem")
        
        For Each f In files
            Text2 = BaseFromFileName(f)
            If Len(Text2) = 0 Then
                List1.AddItem "Could not extract base address from file name. "
                List1.AddItem "  Skipping " & FileNameFromPath(f)
            Else
                If Not WrapFile(f, False) Then
                    List1.AddItem "Failed to wrap file " & FileNameFromPath(f)
                Else
                   List1.AddItem "Success: " & FileNameFromPath(f)
                   inc success
                End If
            End If
         Next
         
         List1.AddItem success & "/" & (UBound(files) + 1) & " files processed successfully."
    
    End If
    
    Exit Sub
hell:
    
    List1.AddItem "Error:: " & Err.Description
    
End Sub
    
Sub inc(ByRef v As Long)
    v = v + 1
End Sub

Function WrapFile(pth, Optional displayInfo As Boolean = True) As Boolean
    
    On Error GoTo hell
    
    If displayInfo Then List1.Clear
    
    Dim b() As Byte
    Dim f As Long
    
    If Not FileExists(pth) Then Exit Function
    If FileLen(pth) < 2 Then Exit Function
    
    f = FreeFile
    Open pth For Binary As f
    ReDim b(LOF(f) + 1)
    Get f, , b()
    Close f
    
    Dim outFile As String
    outFile = GetParentFolder(pth) & "\" & Text2 & "_dmp.dll"
    If displayInfo Then List1.AddItem "Generating " & outFile
    
    If FileExists(outFile) Then
        If displayInfo Then List1.AddItem "Deleting old file.."
        Kill outFile
    End If
    
    If b(0) = Asc("M") And b(1) = Asc("Z") Then
        If displayInfo Then List1.AddItem "Memory dump already has a MZ header, just copying"
        FileCopy pth, outFile
        WrapFile = True
        Exit Function
    End If
        
    If displayInfo Then List1.AddItem "Copying dummy.dll to new file.."
    FileCopy dummy, outFile
    
    If displayInfo Then List1.AddItem "Appending memory dump.."
    f = FreeFile
    Open outFile For Binary As f
    Put f, LOF(f) + 1, b() 'append the memory dump to dummy header..
    
    While LOF(f) Mod &H10 <> 0 'file and section alignment has been set to 0x10..
        Put f, , CByte(0)
    Wend
    
    'imgsz = A....140
    'ep = D.......118
    'imgbase = C..124
    'vsz/rsz = B..1f0/1f8
    
    If displayInfo Then List1.AddItem "Fixing up PE attributes for easy disassembly.."
    Put f, &H140 + 1, CLng(LOF(f)) + 1 'image size
    Put f, &H124 + 1, CLng("&h" & Text2)  'image base
    Put f, &H1F0 + 1, CLng(UBound(b)) + 1 'virtual size
    Put f, &H1F8 + 1, CLng(UBound(b)) + 1 'raw size
    
    Close f
    
    If displayInfo Then List1.AddItem "Complete!"
    If displayInfo Then List1.AddItem ""
    If displayInfo Then List1.AddItem "You can manually set entry point it is 0 for now.."
    
    WrapFile = True
    
    Exit Function
    
hell:
    List1.AddItem "Error processing " & pth
    List1.AddItem "   Description:" & Err.Description
    
End Function



Private Sub Command2_Click()
    Const msg = "drag and drop file or folder to main textbox to load.\n" & _
                "supports [pid]_[hexbase].mem or hexbase.mem\n" & _
                "for single files will auto parse out base\n\n" & _
                "this will add the file(s) to a new pe image and output one 32bit dll"
    MsgBox Replace(msg, "\n", vbCrLf)
End Sub

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
        If Not isHex(BaseFromFileName) Then BaseFromFileName = Empty
    Else
        'may its just base.mem
        BaseFromFileName = Replace(base, ".mem", "")
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



Sub push(ary, value) 'this modifies parent ary object
    On Error GoTo init
    x = UBound(ary) '<-throws Error If Not initalized
    ReDim Preserve ary(UBound(ary) + 1)
    ary(UBound(ary)) = value
    Exit Sub
init:     ReDim ary(0): ary(0) = value
End Sub

Function GetParentFolder(path) As String
    tmp = Split(path, "\")
    ub = tmp(UBound(tmp))
    GetParentFolder = Replace(Join(tmp, "\"), "\" & ub, "")
End Function

