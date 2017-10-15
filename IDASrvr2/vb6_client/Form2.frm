VERSION 5.00
Begin VB.Form Form2 
   Caption         =   "Active IDA Servers"
   ClientHeight    =   3195
   ClientLeft      =   60
   ClientTop       =   345
   ClientWidth     =   8670
   LinkTopic       =   "Form2"
   ScaleHeight     =   3195
   ScaleWidth      =   8670
   StartUpPosition =   2  'CenterScreen
   Begin VB.CommandButton cmdSelect 
      Caption         =   "Select"
      Height          =   375
      Left            =   7320
      TabIndex        =   1
      Top             =   2640
      Width           =   1215
   End
   Begin VB.ListBox List1 
      BeginProperty Font 
         Name            =   "Courier New"
         Size            =   11.25
         Charset         =   0
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      Height          =   2355
      Left            =   60
      TabIndex        =   0
      Top             =   60
      Width           =   8535
   End
End
Attribute VB_Name = "Form2"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
 

Public Function SelectIDAInstance(Optional refresh As Boolean = True) As Long
    
    Dim x
    Dim cnt As Long
    Dim pth As String
    
    On Error Resume Next
    
    If refresh Then
        cnt = FindActiveIDAWindows
    Else
        cnt = Servers.Count
    End If
    
    If cnt = 0 Then
        SelectIDAInstance = 0
        Unload Me
        Exit Function
        
    ElseIf cnt = 1 Then
        SelectIDAInstance = Servers(1)
        Unload Me
        Exit Function
        
    Else
       For Each x In Servers 'remove any that arent still valid..
            If IsWindow(x) = 0 Then
                Servers.Remove "hwnd:" & x
            Else
                IDA_HWND = CLng(x)
                pth = Form1.ida.LoadedFile
                pth = fso.FileNameFromPath(pth)
                List1.AddItem x & ": " & pth
            End If
        Next
        List1.ListIndex = 0
    End If
    
    Me.Show 1, Form1
    
    Dim sel
    sel = List1.List(List1.ListIndex)
    a = InStr(sel, ":")
    If a > 0 Then
        sel = Mid(sel, 1, a - 1)
    End If
    
    SelectIDAInstance = CLng(sel)
    Unload Me
    
End Function

Private Sub cmdSelect_Click()
    Me.Hide
End Sub


