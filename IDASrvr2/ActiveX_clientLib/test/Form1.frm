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
Dim ida64 As New cIDAClient64

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

    Dim va64 As ULong64
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
    List1.AddItem "IDASRVR version: " & ida.QuickCall(qcmGetVersion)
    List1.AddItem "is64Bit: " & ida.is64Bit()
    
    a = ida.BenchMark()
    r = ida.NumFuncs()
    b = ida.BenchMark()
    
    List1.AddItem "NumFuncs: " & r & " (org " & b - a & " ticks)"
    
    If ida.is64Bit() = 0 Then
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
    Else
    
        Set va64 = ida64.FunctionStart(0)
        List1.AddItem "Func[0].start: " & va64.toString()
        List1.AddItem "Func[0].end: " & ida64.FunctionEnd(0).toString()
        List1.AddItem "Func[0].name: " & ida64.FunctionName(0)
        List1.AddItem "1st inst: " & ida64.GetAsm(va64)
        
        List1.AddItem "VA For Func 'start': " & ida64.FuncVAByName("start").toString()
        
        List1.AddItem "Jumping to 1st inst"
        ida64.Jump va64
        
        r = ida64.ReadLong("180001000")
        List1.AddItem "4 byte value at 180001000 = " & Hex(r)
       
        'r = ida.ReadShort(&H180001000)
        'List1.AddItem "2 byte value at 4110A4 = " & Hex(r)
    
    
    End If
    
    
    
End Sub

 

