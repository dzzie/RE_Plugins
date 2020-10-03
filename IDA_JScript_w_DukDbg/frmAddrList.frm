VERSION 5.00
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
   Begin Project1.ucFilterList lv 
      Height          =   6900
      Left            =   0
      TabIndex        =   0
      Top             =   45
      Width           =   3210
      _ExtentX        =   5662
      _ExtentY        =   12171
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
      Begin VB.Menu mnuTopMost 
         Caption         =   "TopMost"
      End
      Begin VB.Menu mnuDiv2 
         Caption         =   "-"
      End
      Begin VB.Menu mnuImport 
         Caption         =   "Import"
         Begin VB.Menu mnuImportXrefsTo 
            Caption         =   "IDA Xrefs To"
         End
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

Sub Clear()
    lv.ListItems.Clear
End Sub

Sub addAddr(addr, txt)
    On Error Resume Next
    Dim li As ListItem, index
    If IsNumeric(addr) Then addr = "0x" & Hex(addr)
    Set li = lv.ListItems.add(, , addr)
    li.subItems(2) = txt
    index = Form1.ida.funcIndexFromVA(addr)
    li.subItems(1) = Form1.ida.functionName(index)
End Sub

Sub showList()
    Me.Visible = True
End Sub

Sub hideList()
    Me.Visible = False
End Sub

Sub copyAll()
    lv.Copy , False, ","
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
    lv.SetColumnHeaders "Address,Func*,Text", "2400"
    lv.SetFont "Courier", 12
    lv.MultiSelect = True
    lv.AllowDelete = True
End Sub

Private Sub Form_Resize()
    On Error Resume Next
    lv.Move 0, 0, Me.ScaleWidth, Me.ScaleHeight
    'lv.ColumnHeaders(2).Width = lv.Width - lv.ColumnHeaders(1).Width
End Sub

Private Sub lv_ItemClick(ByVal Item As MSComctlLib.ListItem)
    On Error Resume Next
    Form1.ida.jump Item.Text
End Sub

Private Sub lv_MouseUp(Button As Integer, Shift As Integer, x As Single, y As Single)
    If Button = 2 Then PopupMenu mnuPopup
End Sub

Private Sub mnuClear_Click()
    lv.ListItems.Clear
End Sub

Private Sub mnuClearOnImport_Click()
    mnuClearOnImport.Checked = Not mnuClearOnImport.Checked
End Sub

Private Sub mnuCopyAll_Click()
    lv.Copy , False, ","
End Sub

Private Sub mnuCopySelected_Click()
    lv.Copy True, False, ","
End Sub

Private Sub mnuDelSel_Click()
    On Error Resume Next
    Dim li As ListItem, i
    For i = lv.currentLV.ListItems.Count To 1 Step -1
        Set li = lv.currentLV.ListItems(i)
        If li.selected Then lv.currentLV.ListItems.Remove i
    Next
End Sub

Private Sub mnuEditSel_Click()
    On Error Resume Next
    Dim li As ListItem, x As String
    Set li = lv.SelectedItem
    If li Is Nothing Then Exit Sub
    x = InputBox("Edit the CSV data: ", , li.Text & "," & li.subItems(1) & "," & li.subItems(2))
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
    If mnuClearOnImport.Checked Then lv.ListItems.Clear
    xx = Split(x, vbCrLf)
    For Each xxx In xx
         Set li = lv.ListItems.add()
         ImportItem li, CStr(xxx)
    Next
End Function

Function ImportItem(li As ListItem, csvData As String)
    On Error Resume Next
    Dim z() As String
    If Len(csvData) = 0 Then Exit Function
    If InStr(csvData, ",") > 0 Then
        z = Split(csvData, ",", 3)
        li.Text = z(0)
        li.subItems(1) = z(1)
        li.subItems(2) = z(2)
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

Private Sub mnuImportXrefsTo_Click()
    On Error Resume Next
    Dim v, tmp, addr, refs, li As ListItem, index
    v = InputBox("Enter 'address to get xrefs to")
    If Len(v) = 0 Then Exit Sub
    If InStr(1, v, "0x", vbTextCompare) < 1 Then v = "0x" & v
    With Form1.ida
        'tmp = .funcVAByName(v)
        'If tmp <> 0 Then v = tmp 'it was a name, standardize to address
        refs = Split(.xRefsTo(v), ",")
        For Each addr In refs
            Set li = lv.ListItems.add(, , .intToHex(addr))
            li.subItems(2) = .getAsm(addr)
            index = .funcIndexFromVA(addr)
            li.subItems(1) = .functionName(index)
        Next
    End With
End Sub

Private Sub mnuTopMost_Click()
    mnuTopMost.Checked = Not mnuTopMost.Checked
    TopMost Me, mnuTopMost.Checked
End Sub
