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
 'todo: filter based on 32/64 bit? will work for x64 too using idaClient? should only used api shared in both..

Public Function SelectIDAInstance(ida As Object, Optional refresh As Boolean = True) As Long
    
    Dim x
    Dim cnt As Long
    Dim pth As String
    Dim curIDA As Long
    
    On Error Resume Next
    
    If refresh Then
        cnt = ida.EnumIDAWindows
    Else
        cnt = Servers.Count
    End If
    
    curIDA = IDA_HWND
    
    'If cnt = 0 Then
    '    SelectIDAInstance = 0
    '    Unload Me
    '    Exit Function
        
    'ElseIf cnt = 1 Then                 'they are expecting a dialog to show active..
    '    SelectIDAInstance = Servers(1)
    '    Unload Me
    '    Exit Function
        
    'Else
       For Each x In Servers 'remove any that arent still valid..
            If IsWindow(x) = 0 Then
                Servers.Remove "hwnd:" & x
            Else
                IDA_HWND = CLng(x)
                pth = ida.LoadedFile
                pth = FileNameFromPath(pth)
                If ida.is64Bit = 1 Then pth = pth & " *64"
                List1.AddItem x & ": " & pth
            End If
        Next
        List1.ListIndex = 0
    'End If
    
    IDA_HWND = curIDA
    Me.Show 1
    
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


Private Sub List1_DblClick()
    If List1.SelCount > 0 Then Me.Hide
End Sub
