VERSION 5.00
Object = "{831FDD16-0C5C-11D2-A9FC-0000F8754DA1}#2.0#0"; "MSCOMCTL.OCX"
Begin VB.Form frmAddrList 
   Caption         =   "Address List"
   ClientHeight    =   7005
   ClientLeft      =   165
   ClientTop       =   810
   ClientWidth     =   3255
   LinkTopic       =   "Form3"
   ScaleHeight     =   7005
   ScaleWidth      =   3255
   StartUpPosition =   3  'Windows Default
   Begin MSComctlLib.ListView lv 
      Height          =   6810
      Left            =   45
      TabIndex        =   0
      Top             =   45
      Width           =   3120
      _ExtentX        =   5503
      _ExtentY        =   12012
      View            =   3
      LabelEdit       =   1
      MultiSelect     =   -1  'True
      LabelWrap       =   -1  'True
      HideSelection   =   -1  'True
      FullRowSelect   =   -1  'True
      GridLines       =   -1  'True
      _Version        =   393217
      ForeColor       =   -2147483640
      BackColor       =   -2147483643
      BorderStyle     =   1
      Appearance      =   1
      BeginProperty Font {0BE35203-8F91-11CE-9DE3-00AA004BB851} 
         Name            =   "Courier"
         Size            =   12
         Charset         =   0
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      NumItems        =   2
      BeginProperty ColumnHeader(1) {BDD1F052-858B-11D1-B16A-00C0F0283628} 
         Text            =   "Addr"
         Object.Width           =   4410
      EndProperty
      BeginProperty ColumnHeader(2) {BDD1F052-858B-11D1-B16A-00C0F0283628} 
         SubItemIndex    =   1
         Text            =   "Text"
         Object.Width           =   2540
      EndProperty
   End
   Begin VB.Menu mnuPopup 
      Caption         =   "mnuPopup"
      Begin VB.Menu mnuCopyAll 
         Caption         =   "Copy All"
      End
      Begin VB.Menu mnuSelection 
         Caption         =   "Selection"
         Begin VB.Menu mnuCopySelected 
            Caption         =   "Copy"
         End
         Begin VB.Menu mnuDelSel 
            Caption         =   "Delete"
         End
         Begin VB.Menu mnuEditSel 
            Caption         =   "Edit"
         End
      End
      Begin VB.Menu mnuDiv1 
         Caption         =   "-"
      End
      Begin VB.Menu mnuClear 
         Caption         =   "Clear"
      End
      Begin VB.Menu mnuDiv2 
         Caption         =   "-"
      End
      Begin VB.Menu mnuImport 
         Caption         =   "Import"
         Begin VB.Menu mnuImportClip 
            Caption         =   "Clipboard"
         End
         Begin VB.Menu mnuImportFile 
            Caption         =   "File"
         End
         Begin VB.Menu mnuClearOnImport 
            Caption         =   "Clear on Import"
         End
      End
   End
End
Attribute VB_Name = "frmAddrList"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit
Public closing As Boolean

Sub clear()
    lv.ListItems.clear
End Sub

Sub addAddr(addr, txt)
    On Error Resume Next
    Dim li As ListItem
    If IsNumeric(addr) Then addr = "0x" & Hex(addr)
    Set li = lv.ListItems.add(, , addr)
    li.SubItems(1) = txt
End Sub

Sub showList()
    Me.Visible = True
End Sub

Sub hideList()
    Me.Visible = False
End Sub

Private Sub Form_Unload(Cancel As Integer)
    If Not closing Then
        Cancel = True
        Me.Visible = False
        Exit Sub
    End If
    FormPos Me, True, True
    Debug.Print "al unloaded"
End Sub

Private Sub Form_Load()
    On Error Resume Next
    FormPos Me, True
    Me.Visible = False
    mnuPopup.Visible = False
    Me.Icon = Form1.Icon
    mnuClearOnImport.Checked = True
End Sub

Private Sub Form_Resize()
    On Error Resume Next
    lv.Move 0, 0, Me.ScaleWidth, Me.ScaleHeight
    lv.ColumnHeaders(2).Width = lv.Width - lv.ColumnHeaders(1).Width
End Sub

Private Sub lv_ItemClick(ByVal Item As MSComctlLib.ListItem)
    On Error Resume Next
    Form1.ida.jump Item.Text
End Sub

Private Sub lv_MouseUp(Button As Integer, Shift As Integer, x As Single, y As Single)
    If Button = 2 Then PopupMenu mnuPopup
End Sub

Private Sub mnuClear_Click()
    lv.ListItems.clear
End Sub

Private Sub mnuClearOnImport_Click()
    mnuClearOnImport.Checked = Not mnuClearOnImport.Checked
End Sub

Private Sub mnuCopyAll_Click()
    Dim li As ListItem
    Dim x() As String
    For Each li In lv.ListItems
        push x, li.Text & "," & li.SubItems(1)
    Next
    Clipboard.clear
    Clipboard.SetText Join(x, vbCrLf)
End Sub

Private Sub mnuCopySelected_Click()
    Dim li As ListItem
    Dim x() As String
    For Each li In lv.ListItems
        If li.Selected Then
            push x, li.Text & "," & li.SubItems(1)
        End If
    Next
    Clipboard.clear
    Clipboard.SetText Join(x, vbCrLf)
End Sub

Private Sub mnuDelSel_Click()
    On Error Resume Next
    Dim li As ListItem, i
    For i = lv.ListItems.Count To 1 Step -1
        Set li = lv.ListItems(i)
        If li.Selected Then lv.ListItems.Remove i
    Next
End Sub

Private Sub mnuEditSel_Click()
    On Error Resume Next
    Dim li As ListItem, x As String
    Set li = lv.SelectedItem
    If li Is Nothing Then Exit Sub
    x = InputBox("Edit the CSV data: ", , li.Text & "," & li.SubItems(1))
    If Len(x) = 0 Then Exit Sub
    ImportItem li, x
End Sub

Private Sub mnuImportClip_Click()
    On Error Resume Next
    doImport Clipboard.GetText
End Sub

Function doImport(x)
    On Error Resume Next
    Dim xx() As String, a, b, xxx, li As ListItem, z() As String
    If mnuClearOnImport.Checked Then lv.ListItems.clear
    xx = Split(x, vbCrLf)
    For Each xxx In xx
         Set li = lv.ListItems.add()
         ImportItem li, CStr(xxx)
    Next
End Function

Function ImportItem(li As ListItem, csvData As String)
    On Error Resume Next
    Dim z() As String
    If InStr(csvData, ",") > 0 Then
        z = Split(csvData, ",", 2)
        li.Text = z(0)
        li.SubItems(1) = z(1)
    Else
        li.Text = csvData
    End If
End Function


Private Sub mnuImportFile_Click()
    On Error Resume Next
    Dim pth As String
    pth = dlg.OpenDialog(AllFiles)
    If Len(pth) = 0 Then Exit Sub
    doImport fso.readFile(pth)
End Sub
