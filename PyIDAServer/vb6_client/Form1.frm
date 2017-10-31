VERSION 5.00
Begin VB.Form Form1 
   Caption         =   "VB6 IDASrvr Example"
   ClientHeight    =   7245
   ClientLeft      =   60
   ClientTop       =   345
   ClientWidth     =   10665
   LinkTopic       =   "Form1"
   ScaleHeight     =   7245
   ScaleWidth      =   10665
   StartUpPosition =   2  'CenterScreen
   Begin VB.CommandButton Command4 
      Caption         =   "Clear"
      Height          =   330
      Left            =   3465
      TabIndex        =   8
      Top             =   6795
      Width           =   1275
   End
   Begin VB.CommandButton Command3 
      Caption         =   "reconnect"
      Height          =   375
      Left            =   2025
      TabIndex        =   7
      Top             =   6795
      Width           =   1050
   End
   Begin VB.CommandButton Command2 
      Caption         =   "Shutdown"
      Height          =   330
      Left            =   135
      TabIndex        =   6
      Top             =   6795
      Width           =   1095
   End
   Begin VB.OptionButton Option2 
      Caption         =   "exec"
      Height          =   240
      Left            =   7785
      TabIndex        =   5
      Top             =   6840
      Value           =   -1  'True
      Width           =   1140
   End
   Begin VB.OptionButton Option1 
      Caption         =   "eval"
      Height          =   240
      Left            =   6660
      TabIndex        =   4
      Top             =   6840
      Width           =   915
   End
   Begin VB.CommandButton Command1 
      Caption         =   "send"
      Height          =   285
      Left            =   9270
      TabIndex        =   3
      Top             =   6795
      Width           =   1230
   End
   Begin VB.TextBox Text1 
      BeginProperty Font 
         Name            =   "Courier"
         Size            =   12
         Charset         =   0
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      Height          =   2625
      Left            =   0
      MultiLine       =   -1  'True
      ScrollBars      =   3  'Both
      TabIndex        =   2
      Text            =   "Form1.frx":0000
      Top             =   4005
      Width           =   10455
   End
   Begin VB.ListBox List2 
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
      Left            =   0
      TabIndex        =   1
      Top             =   1485
      Width           =   10455
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
      Height          =   1260
      Left            =   0
      TabIndex        =   0
      Top             =   30
      Width           =   10515
   End
End
Attribute VB_Name = "Form1"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False

 'will find last opened instance if still active
Function FindClient() As Boolean
    Dim hwnd As Long
    
    On Error Resume Next
    
    hwnd = CLng(GetSetting("IPC", "Handles", "PIDA_SERVER", 0))
    If hwnd <> 0 Then
        If IsWindow(hwnd) = 1 Then
            FindClient = True
            Module1.IDA_HWND = hwnd
        Else
            SaveSetting "IPC", "Handles", "PIDA_SERVER", 0
            Module1.IDA_HWND = 0
            FindClient = False
        End If
    End If
    
End Function



Private Sub Command1_Click()
        
    If IsWindow(IDA_HWND) = 0 Then
        If Not FindClient() Then
            d "No open PIDASrvr window"
            Exit Sub
        End If
    End If
        
    If Option1.Value Then
        SendCMD "EVAL:" & Me.hwnd & ":" & Text1.Text
    ElseIf Option2.Value Then
        SendCMD "EXEC:" & Me.hwnd & ":" & Text1.Text
    Else
        MsgBox "?"
    End If
    
End Sub

Private Sub Command2_Click()
    SendCMD "SHUTDOWN"
End Sub

Private Sub Command3_Click()
    
    If Not FindClient() Then 'this will load the last open IDASrvr, below we show how to detect multiple windows and select one..
        d "No open PIDA servers up..."
    Else
        d "Found open PIDA server @ hwnd: " & Module1.IDA_HWND
    End If
    
End Sub

Private Sub Command4_Click()
    List1.Clear
    List2.Clear
End Sub

Private Sub Form_Load()

    Dim windows As Long
    Dim hwnd As Long
    
    Me.Visible = True
    
    Hook Me.hwnd
    d "Listening for messages on hwnd: " & Me.hwnd

    If Not FindClient() Then 'this will load the last open IDASrvr, below we show how to detect multiple windows and select one..
        d "No open PIDA servers up..."
        Exit Sub
    Else
        d "Found open PIDA server @ hwnd: " & Module1.IDA_HWND
    End If
        
    
End Sub

 

Private Sub Form_Unload(Cancel As Integer)
    Unhook
End Sub
 

