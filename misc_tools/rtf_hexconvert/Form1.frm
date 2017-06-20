VERSION 5.00
Object = "{9A143468-B450-48DD-930D-925078198E4D}#1.1#0"; "hexed.ocx"
Object = "{831FDD16-0C5C-11D2-A9FC-0000F8754DA1}#2.0#0"; "mscomctl.ocx"
Begin VB.Form Form1 
   Caption         =   "Form1"
   ClientHeight    =   8910
   ClientLeft      =   60
   ClientTop       =   630
   ClientWidth     =   14325
   LinkTopic       =   "Form1"
   ScaleHeight     =   8910
   ScaleWidth      =   14325
   StartUpPosition =   2  'CenterScreen
   Begin VB.CommandButton Command1 
      Caption         =   "Save Mod Back to RTF"
      Height          =   240
      Left            =   11385
      TabIndex        =   11
      Top             =   900
      Width           =   2265
   End
   Begin VB.CommandButton cmdCollapse 
      Caption         =   "Collapse"
      Height          =   240
      Left            =   12735
      TabIndex        =   10
      Top             =   585
      Width           =   915
   End
   Begin VB.CommandButton cmdZero 
      Caption         =   "Zero out blocks"
      Height          =   240
      Left            =   11385
      TabIndex        =   8
      Top             =   585
      Width           =   1230
   End
   Begin VB.TextBox txtMod 
      BeginProperty Font 
         Name            =   "Courier"
         Size            =   12
         Charset         =   0
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      Height          =   330
      Left            =   810
      OLEDropMode     =   1  'Manual
      TabIndex        =   7
      Top             =   675
      Width           =   10365
   End
   Begin VB.CommandButton cmdBrowse 
      Caption         =   "..."
      Height          =   375
      Left            =   11340
      TabIndex        =   5
      Top             =   135
      Width           =   870
   End
   Begin rhexed.HexEd he 
      Height          =   7260
      Left            =   2970
      TabIndex        =   4
      Top             =   1260
      Width           =   11265
      _ExtentX        =   19870
      _ExtentY        =   12806
   End
   Begin VB.CommandButton cmdLoad 
      Caption         =   "Load"
      Height          =   375
      Left            =   12375
      TabIndex        =   3
      Top             =   135
      Width           =   1275
   End
   Begin VB.TextBox txtFile 
      BeginProperty Font 
         Name            =   "Courier"
         Size            =   12
         Charset         =   0
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      Height          =   330
      Left            =   585
      OLEDropMode     =   1  'Manual
      TabIndex        =   2
      Top             =   180
      Width           =   10590
   End
   Begin MSComctlLib.ListView lv 
      Height          =   7260
      Left            =   45
      TabIndex        =   0
      Top             =   1215
      Width           =   2805
      _ExtentX        =   4948
      _ExtentY        =   12806
      View            =   3
      LabelEdit       =   1
      LabelWrap       =   -1  'True
      HideSelection   =   0   'False
      FullRowSelect   =   -1  'True
      GridLines       =   -1  'True
      _Version        =   393217
      ForeColor       =   -2147483640
      BackColor       =   -2147483643
      BorderStyle     =   1
      Appearance      =   1
      NumItems        =   2
      BeginProperty ColumnHeader(1) {BDD1F052-858B-11D1-B16A-00C0F0283628} 
         Text            =   "Offset"
         Object.Width           =   2540
      EndProperty
      BeginProperty ColumnHeader(2) {BDD1F052-858B-11D1-B16A-00C0F0283628} 
         SubItemIndex    =   1
         Text            =   "Size"
         Object.Width           =   2540
      EndProperty
   End
   Begin VB.Label Label3 
      Caption         =   "?"
      BeginProperty Font 
         Name            =   "MS Sans Serif"
         Size            =   13.5
         Charset         =   0
         Weight          =   400
         Underline       =   -1  'True
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      ForeColor       =   &H00FF0000&
      Height          =   330
      Left            =   13950
      TabIndex        =   9
      Top             =   720
      Width           =   240
   End
   Begin VB.Label Label2 
      Caption         =   "ModFile"
      Height          =   240
      Left            =   135
      TabIndex        =   6
      Top             =   765
      Width           =   780
   End
   Begin VB.Label Label1 
      Caption         =   "File"
      Height          =   330
      Left            =   180
      TabIndex        =   1
      Top             =   225
      Width           =   330
   End
   Begin VB.Menu mnuPopup 
      Caption         =   "mnuPopup"
      Begin VB.Menu mnuSearchString 
         Caption         =   "Search String"
      End
      Begin VB.Menu mnuExport 
         Caption         =   "Export All To File"
      End
      Begin VB.Menu mnuBinExport 
         Caption         =   "Export Binaries to folder"
      End
   End
End
Attribute VB_Name = "Form1"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Dim r As New RegExp
Dim dlg As New clsCmnDlg2
Const LANG_US = &H409
Dim selItem As ListItem

Private Sub cmdBrowse_Click()
    txtFile = dlg.OpenDialog(AllFiles)
    If Len(txtFile.Text) <> 0 Then
        txtMod = txtFile & ".mod"
        'If FileExists(txtMod) Then Kill txtMod
        cmdLoad_Click
    End If
End Sub

Private Sub cmdCollapse_Click()
    
    Dim dat As String, li As ListItem
    Dim mm As MatchCollection, m As Match
    
    If Not FileExists(txtFile.Text) Then Exit Sub
    If Not FileExists(txtMod) Then FileCopy txtFile, txtMod
    
    Dim f As Long, b() As Byte
    Dim p As Long, i As Long
    
    f = FreeFile
    Open txtMod For Binary As f
    ReDim b(LOF(f))
    Get f, , b()
    Close f

    f = FreeFile
    Open txtMod & "2" For Binary As f
    
    dat = ReadFile(txtMod.Text)
    r.Pattern = "[\0\ff]{10,}" 'junk blocks
    r.Global = True
        
    Set mm = r.Execute(dat)
    For Each m In mm
        Do While i < m.FirstIndex
            Put f, , b(i)
            i = i + 1
        Loop
        i = i + m.Length
    Next
    
    Close f
    
    MsgBox "old file: " & Hex(FileLen(txtMod)) & vbCrLf & "new file: " & Hex(FileLen(txtMod & "2"))


End Sub

Private Sub cmdLoad_Click()
    
    Dim dat As String, li As ListItem
    Dim mm As MatchCollection, m As Match
    
    If Not FileExists(txtFile.Text) Then Exit Sub
    
    dat = ReadFile(txtFile.Text)
    r.Pattern = "[0-9a-fA-F\r\n]{10,}"
    r.Global = True
    
    lv.ListItems.Clear
    he.LoadString ""
    
    Set mm = r.Execute(dat)
    For Each m In mm
        Set li = lv.ListItems.Add(, , Hex(m.FirstIndex))
        li.SubItems(1) = m.Length
        Set li.Tag = m
    Next

    Me.Caption = mm.Count & " Hex encoded sections found in file - " & Now

End Sub


Function ReadFile(filename)
  f = FreeFile
  temp = ""
   Open filename For Binary As #f        ' Open file.(can be text or image)
     temp = Input(FileLen(filename), #f) ' Get entire Files data
   Close #f
   ReadFile = temp
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

Public Function HexStringUnescape(str, Optional stripWhite As Boolean = False, Optional noNulls As Boolean = False, Optional bailOnManyErrors As Boolean = False)

    Dim ret As String
    Dim x As String
    Dim errCount As Long
    Dim r() As Byte
    Dim b As Byte
    
    On Error Resume Next

    If stripWhite Then
        str = Replace(str, " ", Empty)
        str = Replace(str, vbCr, Empty)
        str = Replace(str, vbLf, Empty)
        str = Replace(str, vbTab, Empty)
        str = Replace(str, Chr(0), Empty)
    End If

    For i = 1 To Len(str) Step 2 'this is to agressive for headers...
        x = Mid(str, i, 2)
        If isHexChar(x, b) Then
            bpush r(), b
        Else
            errCount = errCount + 1
            s_bpush r(), x
        End If
    Next

    ret = StrConv(r(), vbUnicode, LANG_US)
    
    If noNulls Then ret = Replace(ret, Chr(0), Empty)
    
    If bailOnManyErrors And (errCount > 5) Then
        HexStringUnescape = str
    Else
        HexStringUnescape = ret
    End If
    
End Function

Private Sub s_bpush(bAry() As Byte, sValue As String)
    Dim tmp() As Byte
    Dim i As Long
    tmp() = StrConv(sValue, vbFromUnicode, LANG_US)
    For i = 0 To UBound(tmp)
        bpush bAry, tmp(i)
    Next
End Sub

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


Function FileExists(path) As Boolean
  If Len(path) = 0 Then Exit Function
  If Dir(path, vbHidden Or vbNormal Or vbReadOnly Or vbSystem) <> "" Then FileExists = True _
  Else FileExists = False
End Function


Private Sub cmdZero_Click()
    If Not FileExists(txtFile) Then Exit Sub
    If Not FileExists(txtMod) Then FileCopy txtFile, txtMod
    
    Dim f As Long
    Dim b() As Byte
    Dim m As Match
    Dim li As ListItem
    
    f = FreeFile
    Open txtMod For Binary As f
    
    For Each li In lv.ListItems
        Set m = li.Tag
        ReDim b(m.Length)
        Put f, m.FirstIndex - 1, b()
    Next
    
    Close f
    
    MsgBox "Complete", vbInformation
    
End Sub

Private Sub Command1_Click()
    On Error GoTo hell
    
    If selItem Is Nothing Then Exit Sub
    
    If Not he.IsDirty Then
        MsgBox "You have not modified the data yet"
        Exit Sub
    End If
    
    Dim m As Match
    Dim h As String
    Dim b() As Byte
    Dim s() As String
    
    Set m = selItem.Tag
    
    he.SelectAll
    tmp = he.SelTextAsHexCodes
    b() = StrConv(tmp, vbFromUnicode, LANG_US)
    
    If Not FileExists(txtMod) Then
        FileCopy txtFile, txtMod
    End If
    
    f = FreeFile
    Open txtMod For Binary As f
    Put f, m.FirstIndex - 1, b()
    Close f
    
    MsgBox "Binary data converted back to hexcodes and embedded at offset: " & Hex(m.FirstIndex) & _
            vbCrLf & vbCrLf & txtMod
    
    Exit Sub
hell:
    MsgBox Err.Description
    
End Sub

Private Sub Form_Load()
    Dim f As String
    mnuPopup.Visible = False
    f = GetSetting("rtf_convert", "settings", "lastPath", "")
    If FileExists(f) Then
        txtFile = f
        txtMod = txtFile & ".mod"
    End If
End Sub

Private Sub Form_Unload(Cancel As Integer)
    SaveSetting "rtf_convert", "settings", "lastPath", txtFile
End Sub

Private Sub Label3_Click()

    MsgBox "This feature is just to zero out these blocks in " & vbCrLf & _
            "the file to eliminate noise for viewing..not " & vbCrLf & _
            "fixing it up for running.." & vbCrLf & _
            "" & vbCrLf & _
            "Collapse will remove long null and 0xff blocks", vbInformation
            
End Sub

Private Sub lv_ItemClick(ByVal Item As MSComctlLib.ListItem)
    Dim m As Match
    Set m = Item.Tag
    he.LoadString HexStringUnescape(m.value, True), False
    Set selItem = Item
End Sub

Private Sub lv_MouseUp(Button As Integer, Shift As Integer, x As Single, y As Single)
    If Button = 2 Then PopupMenu mnuPopup
End Sub

Private Sub mnuBinExport_Click()
    Dim f As String
    Dim m As Match, li As ListItem
    Dim ff As Long
    Dim b() As Byte
    Dim tmp As String
    
    If lv.ListItems.Count = 0 Then Exit Sub
    
    f = dlg.FolderDialog()
    If Len(f) = 0 Then Exit Sub
    
    For Each li In lv.ListItems
        fp = f & "\" & li.Text & ".bin"
        If FileExists(fp) Then Kill fp
        
        Set m = li.Tag
        tmp = CStr(HexStringUnescape(m.value, True))
        b() = StrConv(tmp, vbFromUnicode, &H409)
        
        ff = FreeFile
        Open fp For Binary As ff
        Put ff, , b()
        Close ff
        
    Next
    
    MsgBox "complete!"
End Sub

Private Sub mnuExport_Click()
    Dim f As String
    Dim m As Match, li As ListItem
    Dim ff As Long
    
    If lv.ListItems.Count = 0 Then Exit Sub
    
    f = dlg.SaveDialog(AllFiles, , , , , "export.txt")
    If Len(f) = 0 Then Exit Sub
    
    ff = FreeFile
    Open f For Output As ff
    For Each li In lv.ListItems
        Set m = li.Tag
        Print #ff, CStr(HexStringUnescape(m.value, True))
    Next
    Close ff
    
    MsgBox "complete!"
End Sub

Private Sub mnuSearchString_Click()
    Dim li As ListItem
    Dim m As Match
    Dim dat As String, tmp As String, ret() As String
    Dim pos As Long
    
    If lv.ListItems.Count = 0 Then Exit Sub
    
    tmp = InputBox("Enter string to search for:")
    If Len(tmp) = 0 Then Exit Sub
    
    If FileExists(txtFile) Then
        dat = ReadFile(txtFile)
        pos = 1
        Do
            pos = InStr(pos, dat, tmp, vbTextCompare)
            If pos > 0 Then
                    push ret, "Raw parent file @ offset: 0x" & Hex(pos)
                    pos = pos + 1
            End If
        Loop While pos > 0
    End If
    
    For Each li In lv.ListItems
        Set m = li.Tag
        dat = HexStringUnescape(m.value, True)
        dat = Replace(dat, Chr(0), Empty) 'ascii or unicode..lazy
        If InStr(1, dat, tmp, vbTextCompare) > 0 Then
            push ret, "HexBlob: " & li.Text
        End If
    Next
    
    If AryIsEmpty(ret) Then
        MsgBox "No results found", vbInformation
    Else
        MsgBox Join(ret, vbCrLf), vbInformation
    End If
    
    
End Sub



Function AryIsEmpty(ary) As Boolean
  On Error GoTo oops
    i = UBound(ary)  '<- throws error if not initalized
    AryIsEmpty = False
  Exit Function
oops: AryIsEmpty = True
End Function

Private Sub txtFile_OLEDragDrop(Data As DataObject, Effect As Long, Button As Integer, Shift As Integer, x As Single, y As Single)
    Dim f As String
    On Error Resume Next
    f = Data.Files(1)
    If FileExists(f) Then
        txtFile = f
        txtMod = txtFile & ".mod"
        'If FileExists(txtMod) Then Kill txtMod
        cmdLoad_Click
    End If
End Sub

Sub push(ary, value) 'this modifies parent ary object
    On Error GoTo init
    x = UBound(ary) '<-throws Error If Not initalized
    ReDim Preserve ary(UBound(ary) + 1)
    ary(UBound(ary)) = value
    Exit Sub
init:     ReDim ary(0): ary(0) = value
End Sub



'    'tmp = Environ("temp") & "\tmp.bin"
'    he.Save
'    f = FreeFile
'    Open he.LoadedFile For Binary As f
'    ReDim b(LOF(f) - 1)
'    Get f, , b()
'    Close f
'
'    For i = 0 To UBound(b)
'       tmp = Hex(b(i))
'       If Len(tmp) = 1 Then tmp = "0" & tmp
'       push s, tmp
'    Next
'
'    f = FreeFile
'    Open he.LoadedFile For Binary As f
'    Put f, , CStr(Join(s, ""))
'    Close f
'
'    f = FreeFile
'    Open he.LoadedFile For Binary As f
'    ReDim b(LOF(f) - 1)
'    Get f, , b()
'    Close f
'
'    Kill he.LoadedFile
