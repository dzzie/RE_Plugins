VERSION 5.00
Object = "{248DD890-BB45-11CF-9ABC-0080C7E7B78D}#1.0#0"; "MSWINSCK.OCX"
Begin VB.Form Form1 
   Caption         =   "IDASrvr - OllySync UDP Bridge (listens on port 3333)"
   ClientHeight    =   4860
   ClientLeft      =   60
   ClientTop       =   345
   ClientWidth     =   9975
   LinkTopic       =   "Form1"
   ScaleHeight     =   4860
   ScaleWidth      =   9975
   StartUpPosition =   2  'CenterScreen
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
      Height          =   285
      Left            =   540
      TabIndex        =   5
      Top             =   3735
      Width           =   7890
   End
   Begin VB.CommandButton Command2 
      Caption         =   "rebind port"
      Height          =   420
      Left            =   495
      TabIndex        =   3
      Top             =   4275
      Width           =   1275
   End
   Begin VB.CommandButton cmdclear 
      Caption         =   "Clear list"
      Height          =   420
      Left            =   2115
      TabIndex        =   2
      Top             =   4275
      Width           =   1410
   End
   Begin VB.CommandButton Command1 
      Caption         =   "Reconnect IDA"
      Height          =   330
      Left            =   8505
      TabIndex        =   1
      Top             =   3735
      Width           =   1410
   End
   Begin VB.ListBox List1 
      BeginProperty Font 
         Name            =   "Courier New"
         Size            =   12
         Charset         =   0
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      Height          =   3570
      Left            =   45
      TabIndex        =   0
      Top             =   45
      Width           =   9870
   End
   Begin MSWinsockLib.Winsock sck 
      Left            =   0
      Top             =   4230
      _ExtentX        =   741
      _ExtentY        =   741
      _Version        =   393216
      Protocol        =   1
   End
   Begin VB.Label Label1 
      Caption         =   "Idb"
      Height          =   285
      Left            =   90
      TabIndex        =   4
      Top             =   3735
      Width           =   420
   End
End
Attribute VB_Name = "Form1"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Dim ida As New CIDAClient2 'updated to v2 ida7 10.3.20

Private Declare Function IsWindow Lib "user32" (ByVal hwnd As Long) As Long

Private Sub cmdclear_Click()
    List1.Clear
End Sub

Private Sub Command1_Click()

    ida.ipc.FindActiveIDAWindows
    If ida.ipc.Servers.Count = 0 Then
        List1.Clear
        List1.AddItem "No open IDA instances found. Do you have IDASrvr plugin installed?"
    ElseIf ida.ipc.Servers.Count = 1 Then
        ida.ActiveIDA = ida.ipc.Servers(1)
    Else
        ida.ActiveIDA = ida.SelectServer(True)
    End If
    Text1 = ida.loadedFile
    
End Sub

Private Sub Command2_Click()
    On Error Resume Next
    
    sck.Close
    Err.Clear
    
    sck.LocalPort = 3333
    sck.Bind
    
    If Err.Number <> 0 Then
        List1.AddItem "Failed to bind to udp 3333"
    Else
        List1.AddItem "Now listening for IDA commands on udp 3333"
    End If
    
End Sub

Private Sub Form_Load()

    On Error Resume Next
    Dim c As String, a As Long, autoConnectHWND As Long, t As String
    
    sck.LocalPort = 3333
    sck.Bind
    
    If Err.Number <> 0 Then
        List1.AddItem "Failed to bind to udp 3333"
    Else
        List1.AddItem "Now listening for IDA commands on udp 3333 "
    End If
    
    ida.ipc.Listen Me.hwnd

    c = Command
    a = InStr(c, "/hwnd=")
    If a > 0 Then
        t = Mid(c, a)
        c = Trim(Replace(c, t, Empty))
        t = Trim(Replace(t, "/hwnd=", Empty))
        autoConnectHWND = CLng(t)
        If IsWindow(autoConnectHWND) = 0 Then autoConnectHWND = 0
    End If
    
    If autoConnectHWND <> 0 Then
        ida.ActiveIDA = autoConnectHWND
        Text1 = ida.loadedFile
    Else
        Command1_Click
    End If
        
End Sub



Function FileNameFromPath(fullpath) As String
    If InStr(fullpath, "\") > 0 Then
        tmp = Split(fullpath, "\")
        FileNameFromPath = CStr(tmp(UBound(tmp)))
    End If
End Function

Private Sub sck_DataArrival(ByVal bytesTotal As Long)
    
    On Error Resume Next
    
    Dim tmp As String
    Dim args() As String
    
    sck.GetData tmp
    List1.AddItem tmp
    
    If InStr(tmp, " ") < 1 Then
        args = Split(tmp, ":")
    Else
        args = Split(tmp, " ") 'original style is default..
    End If
    
    Select Case args(0)
        Case "jmp": ida.jump args(1)
                    '"0x6B380663" or 1798833763 or 0x1122334455667788
                    
        Case "jmpfunc": ida.jump ida.funcVAByName(args(1))
                        'ida.QuickCall qcmSetFocusSelectLine
                        
        Case "jmp_rva": ida.jumpRVA args(1)
                        'ida.QuickCall qcmSetFocusSelectLine
'        Case "curidb":
'                        sck.RemoteHost = sck.RemoteHostIP
'                        sck.RemotePort = 4444
'                        sck.SendData "curidb " & ida.LoadedFile & vbCrLf
    End Select
    
End Sub

