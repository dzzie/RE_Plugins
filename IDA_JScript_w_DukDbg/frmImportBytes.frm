VERSION 5.00
Begin VB.Form frmImportBytes 
   Caption         =   "Import Patch"
   ClientHeight    =   1245
   ClientLeft      =   60
   ClientTop       =   405
   ClientWidth     =   7410
   LinkTopic       =   "Form3"
   ScaleHeight     =   1245
   ScaleWidth      =   7410
   StartUpPosition =   2  'CenterScreen
   Begin VB.TextBox txtSect 
      Height          =   330
      Left            =   1755
      TabIndex        =   7
      Top             =   360
      Width           =   1545
   End
   Begin VB.TextBox txtFile 
      Height          =   315
      Left            =   1740
      Locked          =   -1  'True
      OLEDropMode     =   1  'Manual
      TabIndex        =   3
      Text            =   "Drag & Drop file here"
      Top             =   0
      Width           =   4485
   End
   Begin VB.TextBox txtVA 
      Height          =   315
      Left            =   1755
      TabIndex        =   2
      Top             =   720
      Width           =   1035
   End
   Begin VB.CommandButton cmdImport 
      Caption         =   "Import"
      Height          =   375
      Left            =   5895
      TabIndex        =   1
      Top             =   675
      Width           =   1335
   End
   Begin VB.CommandButton cmdBrowse 
      Caption         =   "..."
      Height          =   315
      Left            =   6525
      TabIndex        =   0
      Top             =   45
      Width           =   675
   End
   Begin VB.Label Label3 
      Caption         =   "(optional)"
      Height          =   285
      Left            =   3510
      TabIndex        =   8
      Top             =   405
      Width           =   735
   End
   Begin VB.Label Label2 
      Caption         =   "New Sect"
      Height          =   240
      Left            =   900
      TabIndex        =   6
      Top             =   405
      Width           =   870
   End
   Begin VB.Label Label1 
      Caption         =   "File to Patch into IDB"
      Height          =   195
      Index           =   0
      Left            =   0
      TabIndex        =   5
      Top             =   60
      Width           =   1575
   End
   Begin VB.Label Label1 
      Caption         =   "VA  0x"
      Height          =   195
      Index           =   3
      Left            =   1125
      TabIndex        =   4
      Top             =   810
      Width           =   540
   End
End
Attribute VB_Name = "frmImportBytes"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Private Sub cmdBrowse_Click()
    Dim p As String
    p = dlg.OpenDialog(AllFiles)
    If Len(p) = 0 Then Exit Sub
    txtFile = p
End Sub

Private Sub cmdImport_Click()
    
    On Error Resume Next
    Dim va As Long, ret As Long
    Dim ul As New ULong64
    
    If Not fso.FileExists(txtFile) Then
        MsgBox "File does not exist", vbInformation
        Exit Sub
    End If
    
    ul.use0x = True
    If Not ul.fromString(txtVA, mHex) Then
        MsgBox "Va is not a valid hex number", vbInformation
        Exit Sub
    End If
    
    ret = Form1.ida.importFile(ul.toString(), txtFile, txtSect)
    If ret > 0 Then
        MsgBox "Import success!", vbInformation
    Else
        MsgBox "Import Failed Error:" & ret, vbInformation
    End If
    
End Sub

Private Sub Form_Load()
    On Error Resume Next
    Me.Icon = Form1.Icon
    cmdImport.enabled = Form1.ida.isUp
End Sub

Private Sub txtFile_OLEDragDrop(Data As DataObject, Effect As Long, Button As Integer, Shift As Integer, X As Single, Y As Single)
    On Error Resume Next
    txtFile = Data.Files(1)
End Sub
