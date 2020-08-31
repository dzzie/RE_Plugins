VERSION 5.00
Begin VB.Form Form2 
   Caption         =   "Select IDA Server to Connect to"
   ClientHeight    =   3195
   ClientLeft      =   60
   ClientTop       =   345
   ClientWidth     =   6150
   LinkTopic       =   "Form2"
   ScaleHeight     =   3195
   ScaleWidth      =   6150
   StartUpPosition =   2  'CenterScreen
   Begin VB.CommandButton cmdSelect 
      Caption         =   "Select"
      BeginProperty Font 
         Name            =   "Courier"
         Size            =   12
         Charset         =   0
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      Height          =   315
      Left            =   4500
      TabIndex        =   1
      Top             =   2700
      Width           =   1515
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
      Left            =   60
      TabIndex        =   0
      Top             =   60
      Width           =   6015
   End
End
Attribute VB_Name = "Form2"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
 

Public Function SelectIDAInstance(Optional refresh As Boolean = True, Optional autoSelectIfOnlyOne As Boolean = True) As Long
    
    Dim x
    Dim cnt As Long
    Dim pth As String
    
    On Error Resume Next
    
    If refresh Then
        cnt = Form1.ida.ipc.FindActiveIDAWindows()
    Else
        cnt = Form1.ida.ipc.Servers.Count
    End If
    
    If cnt = 0 Then
        SelectIDAInstance = 0
        Unload Me
        Exit Function
        
    ElseIf cnt = 1 And autoSelectIfOnlyOne Then
        SelectIDAInstance = Form1.ida.ipc.Servers(1)
        Unload Me
        Exit Function
        
    Else
       For Each x In Form1.ida.ipc.Servers 'remove any that arent still valid..
            If IsWindow(x) = 0 Then
                Form1.ida.ipc.Servers.Remove "hwnd:" & x
            Else
                Form1.ida.ipc.RemoteHWND = CLng(x)
                pth = Form1.ida.LoadedFile
                pth = fso.FileNameFromPath(pth)
                List1.AddItem x & ": " & pth
            End If
        Next
        List1.ListIndex = 0
    End If
    
    Me.Show 1, Form1 'modal - execution hangs here until this form is hidden
    
    Dim sel
    sel = List1.List(List1.ListIndex)
    a = InStr(sel, ":")
    If a > 0 Then
        sel = Mid(sel, 1, a - 1)
    End If
    
    SelectIDAInstance = CLng(sel)
    Unload Me
    
End Function

'Private Sub Form_Resize()
'    On Error Resume Next
'    List1.Width = Me.Width - List1.Left - 200
'    List1.Height = Me.Height - List1.Top - 200
'End Sub

Private Sub cmdSelect_Click()
    Me.Hide
End Sub

Private Sub Form_Load()
    On Error Resume Next
    Me.Icon = Form1.Icon
End Sub

Private Sub List1_DblClick()
    If List1.ListIndex >= 0 Then Me.Hide
End Sub
