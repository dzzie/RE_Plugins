VERSION 5.00
Begin VB.Form Form1 
   Caption         =   "VB6 IDASrvr Example"
   ClientHeight    =   5385
   ClientLeft      =   60
   ClientTop       =   345
   ClientWidth     =   10620
   LinkTopic       =   "Form1"
   ScaleHeight     =   5385
   ScaleWidth      =   10620
   StartUpPosition =   2  'CenterScreen
   Begin VB.CommandButton Command1 
      Caption         =   "Connect to Active IDA Windows"
      Height          =   405
      Left            =   7620
      TabIndex        =   1
      Top             =   4800
      Width           =   2955
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
      Height          =   4620
      Left            =   30
      TabIndex        =   0
      Top             =   30
      Width           =   10515
   End
   Begin VB.Label Label1 
      Caption         =   "If only one window open it will auto connect, if multiple then you can select"
      BeginProperty Font 
         Name            =   "Courier New"
         Size            =   8.25
         Charset         =   0
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      Height          =   495
      Left            =   60
      TabIndex        =   2
      Top             =   4770
      Width           =   7455
   End
End
Attribute VB_Name = "Form1"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Private Declare Function IsWindow Lib "user32" (ByVal hwnd As Long) As Long

Dim ida As New cIDAClient

Private Sub Command1_Click()
    ida.ActiveIDA = ida.SelectServer()
    SampleAPI
End Sub

Private Sub Form_Load()

    Dim windows As Long
    Dim hwnd As Long
    Dim servers As Collection
    
    Me.Visible = True
    
    ida.Listen Me.hwnd
    List1.AddItem "Listening for messages on hwnd: " & Me.hwnd

    'ida.FindClient() this will load the last open IDASrvr, below we show how to detect multiple windows and select one..
    
    windows = ida.EnumIDAWindows()
    Set servers = ida.ActiveServers
    
    Me.Refresh
    DoEvents
    
    If windows = 0 Then
        List1.AddItem "No open IDA Windows detected."
        Exit Sub
    ElseIf windows = 1 Then
        ida.ActiveIDA = servers(1)
    Else
        hwnd = ida.SelectServer(False)
        If hwnd = 0 Then Exit Sub
        ida.ActiveIDA = hwnd
    End If
        
    SampleAPI
    
    
End Sub

Sub SampleAPI()

    Dim va As Long
    Dim hwnd As Long
    Dim a As Long
    Dim b As Long
    Dim r As Long
    
    List1.Clear
    
    If IsWindow(ida.ActiveIDA) = 0 Then
        List1.AddItem "Currently set IDA window was closed? hwnd: " & ida.ActiveIDA
        Exit Sub
    End If
    
    List1.AddItem "Decompiler plugin is active? " & ida.DecompilerActive
    List1.AddItem "Loaded idb: " & ida.LoadedFile()
    
    a = ida.BenchMark()
    r = ida.NumFuncs()
    b = ida.BenchMark()
    
    List1.AddItem "NumFuncs: " & r & " (org " & b - a & " ticks)"
    
    va = ida.FunctionStart(0)
    List1.AddItem "Func[0].start: " & Hex(va)
    List1.AddItem "Func[0].end: " & Hex(ida.FunctionEnd(0))
    List1.AddItem "Func[0].name: " & ida.FunctionName(0)
    List1.AddItem "1st inst: " & ida.GetAsm(va)
    
    List1.AddItem "VA For Func 'start': " & Hex(ida.FuncVAByName("start"))
    
    List1.AddItem "Jumping to 1st inst"
    ida.Jump va
    
    r = ida.ReadLong(&H4110A4)
    List1.AddItem "4 byte value at 4110A4 = " & Hex(r)
    
    r = ida.ReadShort(&H4110A4)
    List1.AddItem "2 byte value at 4110A4 = " & Hex(r)
    
    
End Sub

 

