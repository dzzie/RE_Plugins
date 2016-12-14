VERSION 5.00
Object = "{831FDD16-0C5C-11D2-A9FC-0000F8754DA1}#2.0#0"; "mscomctl.ocx"
Begin VB.Form frmAdressList 
   Caption         =   "Address Lists"
   ClientHeight    =   6030
   ClientLeft      =   60
   ClientTop       =   345
   ClientWidth     =   2835
   LinkTopic       =   "Form1"
   ScaleHeight     =   6030
   ScaleWidth      =   2835
   StartUpPosition =   3  'Windows Default
   Begin VB.TextBox txtStartIndex 
      Height          =   315
      Left            =   1020
      TabIndex        =   14
      Text            =   "0"
      Top             =   5640
      Width           =   555
   End
   Begin VB.CommandButton cmdPause 
      Caption         =   "Pause"
      Height          =   315
      Left            =   1920
      TabIndex        =   13
      Top             =   5640
      Width           =   795
   End
   Begin VB.CommandButton cmdAuto 
      Caption         =   "Auto"
      Height          =   315
      Left            =   60
      TabIndex        =   12
      Top             =   5640
      Width           =   795
   End
   Begin VB.Timer Timer1 
      Enabled         =   0   'False
      Interval        =   1000
      Left            =   2280
      Top             =   5580
   End
   Begin VB.CommandButton cmdExport 
      Caption         =   "Export"
      Height          =   315
      Left            =   0
      TabIndex        =   11
      Top             =   5220
      Width           =   2775
   End
   Begin VB.CommandButton cmdLoadList2 
      Caption         =   "Load CSV or CRLF Address List"
      Height          =   255
      Left            =   0
      TabIndex        =   10
      Top             =   4920
      Width           =   2775
   End
   Begin VB.CommandButton cmdManualAdd 
      Caption         =   "Manual Add"
      Height          =   255
      Left            =   0
      TabIndex        =   9
      Top             =   4320
      Width           =   2775
   End
   Begin VB.Frame Frame1 
      Caption         =   "Add Address"
      Height          =   1155
      Left            =   120
      TabIndex        =   3
      Top             =   1500
      Visible         =   0   'False
      Width           =   2655
      Begin VB.CommandButton cmdCancel 
         Caption         =   "Cancel"
         Height          =   255
         Left            =   1140
         TabIndex        =   8
         Top             =   840
         Width           =   675
      End
      Begin VB.CommandButton cmdAddit 
         Caption         =   "Done"
         Height          =   255
         Left            =   1860
         TabIndex        =   7
         Top             =   840
         Width           =   675
      End
      Begin VB.TextBox Text3 
         Height          =   285
         Left            =   540
         TabIndex        =   6
         Top             =   480
         Width           =   1935
      End
      Begin VB.TextBox Text2 
         Height          =   285
         Left            =   540
         TabIndex        =   5
         Top             =   180
         Width           =   1935
      End
      Begin VB.Label Label1 
         Caption         =   "Adr      Cmt"
         Height          =   555
         Left            =   120
         TabIndex        =   4
         Top             =   240
         Width           =   495
      End
   End
   Begin VB.CommandButton cmdHelp 
      Caption         =   "?"
      Height          =   255
      Left            =   2400
      TabIndex        =   2
      Top             =   4620
      Width           =   375
   End
   Begin VB.CommandButton cmdLoad 
      Caption         =   "Load IDA Xref List"
      Height          =   255
      Left            =   0
      TabIndex        =   1
      Top             =   4620
      Width           =   2355
   End
   Begin MSComctlLib.ListView lv 
      Height          =   4275
      Left            =   0
      TabIndex        =   0
      Top             =   30
      Width           =   2835
      _ExtentX        =   5001
      _ExtentY        =   7541
      View            =   3
      LabelEdit       =   1
      MultiSelect     =   -1  'True
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
         Text            =   "Adr"
         Object.Width           =   2540
      EndProperty
      BeginProperty ColumnHeader(2) {BDD1F052-858B-11D1-B16A-00C0F0283628} 
         SubItemIndex    =   1
         Text            =   "Text"
         Object.Width           =   2540
      EndProperty
   End
   Begin VB.Menu mnuPopup 
      Caption         =   "mnuPopup"
      Visible         =   0   'False
      Begin VB.Menu mnuPop 
         Caption         =   "Delete Selected"
         Index           =   0
      End
      Begin VB.Menu mnuPop 
         Caption         =   "Update Selected"
         Index           =   1
      End
      Begin VB.Menu mnuPop 
         Caption         =   "Save List"
         Index           =   2
      End
      Begin VB.Menu mnuPop 
         Caption         =   "Load List"
         Index           =   3
      End
      Begin VB.Menu mnuPop 
         Caption         =   "Clear"
         Index           =   4
      End
   End
End
Attribute VB_Name = "frmAdressList"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
'Option Explicit
Dim SelLi As ListItem
Dim selIndex As Long

Private Sub cmdAddit_Click()
    On Error GoTo hell
    
    adr = CLng("&h" & Text2)
    x = Text3
    
    Dim li As ListItem
    Set li = lv.ListItems.Add
    li.Text = Hex(adr)
    li.Tag = adr
    li.SubItems(1) = x
    
    Frame1.Visible = False
    
    Exit Sub
hell:
    MsgBox Err.Description
End Sub

Private Sub cmdAuto_Click()
    
    Timer1.enabled = True
End Sub

Private Sub cmdCancel_Click()
    Frame1.Visible = False
End Sub

Private Sub cmdExport_Click()
    On Error Resume Next
    Dim li As ListItem
    Dim t()
    
    For Each li In lv.ListItems
        push t, li.Text
    Next
    
    Clipboard.Clear
    Clipboard.SetText Join(t, vbCrLf)
    
    MsgBox UBound(t) & " entries copied", vbInformation
    
End Sub

Private Sub cmdhelp_Click()
    MsgBox "Designed to load xref lists from ida in format:" & vbCrLf & vbCrLf & _
            "Down r sub_77AFC6B1+F2  call    ds:__imp_wcscpy" & vbCrLf & vbCrLf & _
            "Paste such lists into lower textbox and hit load", vbInformation
End Sub

Private Sub cmdLoad_Click()
     
    Dim li As ListItem
    
    'todo: this sub is error prone fix me
    
     'ida 6.7 sample input:
    'Direction Type Address         Text
    '--------- ---- -------         ----
    '          p    sub_401EAE+86   call    calldecoder
    'Down      p    sub_401EAE+152  call    calldecoder
    'Down      p    loadinetapi+E   call    calldecoder
    
    t = Clipboard.GetText
    't = Text1

    On Error GoTo nextone
    errs = 0
    
    pos = InStr(t, "Address")
    If pos < 1 Then
        MsgBox "Does not look like an ida xref list?"
        Exit Sub
    End If
    
    x = Split(t, vbCrLf)
    For i = 0 To UBound(x)
        If left(x(i), Len("Direction")) = "Direction" Then GoTo nextone
        If left(x(i), 1) = "-" Then GoTo nextone
        If Len(x(i)) < pos Then GoTo nextone
        
        x(i) = Mid(x(i), pos)
        
        While InStr(x(i), "  ") > 0
            x(i) = Replace(x(i), "  ", " ")
        Wend
        
        y = Split(x(i), " ")
        k = y(0)
        adr = 0
        
        If InStr(k, ":") > 0 Then
            adr = Mid(k, InStr(k, ":") + 1)
            adr = CLng("&h" & adr)
        ElseIf InStr(k, "sub_") = 1 Then
            m = Mid(k, 5)
            If InStr(m, "+") > 0 Then
                a = Mid(m, InStr(m, "+") + 1)
                b = Mid(m, 1, InStr(m, "+") - 1)
                adr = CLng("&h" & b) + CLng("&h" & a)
            Else
                adr = CLng("&h" & m)
            End If
        Else 'it must be a function by name?
            a = InStr(k, "+")
            If a > 0 Then
                n = Trim(Mid(k, 1, a - 1))
                b = Mid(k, a + 1)
                a = GetFuncOffset(n)
                adr = a + CLng("&h" & b)
            End If
        End If
        
        Set li = lv.ListItems.Add
        li.Text = Hex(adr)
        li.Tag = adr
        li.SubItems(1) = Trim(Mid(x(i), Len(y(0)) + 1))
        
         
        
nextone:
        If Err.Number > 0 Then
            errs = errs + 1
            Err.Clear
        End If
        
    Next
    
    
    If errs > 0 Then
        MsgBox "Had " & errs & " import errors"
    End If
    
    
End Sub
 

Private Sub cmdLoadList2_Click()
    Dim li As ListItem
    Dim z As String
    
    On Error Resume Next
    errs = 0
    
    z = Clipboard.GetText
    If InStr(z, ",") > 0 Then
        x = Split(Clipboard.GetText, ",")
    ElseIf InStr(z, vbCrLf) > 0 Then
        x = Split(Clipboard.GetText, vbCrLf)
    Else
        MsgBox "Could not detect either crlf or csv list in clipboard?", vbInformation
        Exit Sub
    End If
    
    For i = 0 To UBound(x)
        
        If Len(Trim(x)) <> 0 Then
            adr = CLng("&h" & x(i))
            Set li = lv.ListItems.Add
            li.Text = Hex(adr)
            li.Tag = adr
        End If
        
        If Err.Number > 0 Then
            errs = errs + 1
            Err.Clear
        End If
        
    Next

    If errs > 0 Then
        MsgBox "Had " & errs & " import errors"
    End If
    
End Sub

Private Sub cmdManualAdd_Click()
    Frame1.Visible = True
End Sub

Private Sub cmdPause_Click()
    Timer1.enabled = Not Timer1.enabled
End Sub

Private Sub Form_Load()
    lv.ColumnHeaders(2).Width = lv.Width - lv.ColumnHeaders(2).left
End Sub

Private Sub lv_ItemClick(ByVal Item As MSComctlLib.ListItem)
    On Error Resume Next
    Set SelLi = Item
    Jump Item.Tag
    txtStartIndex.Text = Item.Index
    selIndex = Item.Index
    Me.SetFocus
    lv.SetFocus
End Sub

Private Sub lv_KeyDown(KeyCode As Integer, Shift As Integer)
    If KeyCode = vbKeyDelete Then
        For i = lv.ListItems.count To 1 Step -1
            If lv.ListItems(i).Selected Then lv.ListItems.Remove i
        Next
    End If
    Me.Caption = "Address list: " & lv.ListItems.count & " entries"
End Sub

Private Sub lv_MouseUp(Button As Integer, Shift As Integer, x As Single, y As Single)
    If Button = 2 Then PopupMenu mnuPopup
End Sub

Private Sub mnuPop_Click(Index As Integer)
    
    Dim li As ListItem
    
    Select Case Index
        Case 0:
                
                For i = lv.ListItems.count To 1 Step -1
                    If lv.ListItems(i).Selected Then
                        lv.ListItems.Remove i
                    End If
                Next
        
        Case 1:
                If SelLi Is Nothing Then Exit Sub
                x = InputBox("Enter new caption", , SelLi.SubItems(1))
                If Len(x) > 0 Then SelLi.SubItems(1) = x
                
        Case 2:
                
                Dim dlg As New clsCmnDlg
                x = dlg.SaveDialog(AllFiles)
                If Len(x) = 0 Then Exit Sub
                
                Dim k() As String
                For Each li In lv.ListItems
                    push k, li.Text & vbTab & li.SubItems(1)
                Next
                
                WriteFile x, Join(k, vbCrLf)
                
        Case 3:
                x = dlg.OpenDialog(AllFiles)
                If Not FileExists(x) Then
                    MsgBox "File not found"
                    Exit Sub
                Else
                   ' MsgBox x
                End If
                
                On Error GoTo hell
                
                lv.ListItems.Clear
2                j = Split(ReadFile(x), vbCrLf)
3                For i = 0 To UBound(j)
4                    If Len(j(i)) > 0 Then
5                        Set li = lv.ListItems.Add
6                        k = Split(j(i), vbTab)
7                        li.Text = k(0)
8                        li.Tag = CLng("&h" & k(0))
9                        li.SubItems(1) = k(1)
10                     End If
11                Next
                
        Case 4: lv.ListItems.Clear
    
    End Select
    
    
    Exit Sub
hell:
    MsgBox "Error on line: " & Erl & " " & Err.Description
    
End Sub



Sub WriteFile(path, it)
    f = FreeFile
    Open path For Output As #f
    Print #f, it
    Close f
End Sub



Function FileExists(path) As Boolean
  If Len(path) = 0 Then Exit Function
  If Dir(path, vbHidden Or vbNormal Or vbReadOnly Or vbSystem) <> "" Then FileExists = True _
  Else FileExists = False
End Function



Function ReadFile(filename)
  f = FreeFile
  temp = ""
   Open filename For Binary As #f        ' Open file.(can be text or image)
     temp = Input(FileLen(filename), #f) ' Get entire Files data
   Close #f
   ReadFile = temp
End Function

Private Sub Timer1_Timer()
    On Error Resume Next
    If selIndex > lv.ListItems.count Then
        Timer1.enabled = False
        Exit Sub
    End If
    selIndex = selIndex + 1
    Me.Caption = selIndex
    lv.ListItems(selIndex).Selected = True
    lv.SelectedItem.EnsureVisible
    lv_ItemClick lv.SelectedItem
End Sub
