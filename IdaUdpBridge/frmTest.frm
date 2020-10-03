VERSION 5.00
Object = "{248DD890-BB45-11CF-9ABC-0080C7E7B78D}#1.0#0"; "MSWINSCK.OCX"
Begin VB.Form Form1 
   Caption         =   "Form1"
   ClientHeight    =   3000
   ClientLeft      =   60
   ClientTop       =   405
   ClientWidth     =   4680
   LinkTopic       =   "Form1"
   ScaleHeight     =   3000
   ScaleWidth      =   4680
   StartUpPosition =   3  'Windows Default
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
      Height          =   1980
      Left            =   45
      TabIndex        =   5
      Top             =   900
      Width           =   4605
   End
   Begin MSWinsockLib.Winsock sck 
      Left            =   3420
      Top             =   0
      _ExtentX        =   741
      _ExtentY        =   741
      _Version        =   393216
      Protocol        =   1
   End
   Begin VB.CommandButton Command1 
      Caption         =   "Test"
      Height          =   375
      Left            =   3420
      TabIndex        =   4
      Top             =   495
      Width           =   1185
   End
   Begin VB.TextBox txtIP 
      BeginProperty Font 
         Name            =   "Courier"
         Size            =   12
         Charset         =   0
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      Height          =   285
      Left            =   1035
      TabIndex        =   3
      Text            =   "192.168.0.11"
      Top             =   90
      Width           =   2220
   End
   Begin VB.TextBox txtCmd 
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
      Left            =   1035
      TabIndex        =   2
      Text            =   "jmp 0x401000"
      Top             =   450
      Width           =   2220
   End
   Begin VB.Label cmd 
      Caption         =   "CMD"
      Height          =   240
      Left            =   0
      TabIndex        =   1
      Top             =   495
      Width           =   825
   End
   Begin VB.Label IP 
      Caption         =   "IP"
      Height          =   240
      Left            =   45
      TabIndex        =   0
      Top             =   135
      Width           =   870
   End
End
Attribute VB_Name = "Form1"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Private Sub Command1_Click()
    
    On Error Resume Next
    
    List1.Clear
    
    sck.RemoteHost = txtIP
    If Err.Number <> 0 Then List1.AddItem Err.Description
    
    sck.RemotePort = 3333
    If Err.Number <> 0 Then List1.AddItem Err.Description
    
    sck.SendData txtCmd
    If Err.Number <> 0 Then List1.AddItem Err.Description
    
End Sub
