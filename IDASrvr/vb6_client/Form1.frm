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
      Height          =   315
      Left            =   7680
      TabIndex        =   2
      Top             =   2400
      Width           =   2955
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
      Left            =   60
      TabIndex        =   1
      Top             =   2820
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
      Height          =   2220
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
      Left            =   120
      TabIndex        =   3
      Top             =   2280
      Width           =   7455
   End
End
Attribute VB_Name = "Form1"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
'http://support.microsoft.com/kb/176058
'this uses inline subclassing code, I would recommend using a library such as
'my spSubclass or VBaccelerator's subclass lib for stability when running in the IDE.
'ps dont hit end from within IDE or it will crash as subclass isnt cleaned up.

Public ida As New CIDA

Private Sub Command1_Click()
    
    IDA_HWND = Form2.SelectIDAInstance
    SampleAPI
    
End Sub

Private Sub Form_Load()

    Dim windows As Long
    Dim hwnd As Long
    
    Me.Visible = True
    
    Hook Me.hwnd
    List1.AddItem "Listening for messages on hwnd: " & Me.hwnd

    'ida.FindClient() this will load the last open IDASrvr, below we show how to detect multiple windows and select one..
    
    windows = FindActiveIDAWindows()
    Me.refresh
    DoEvents
    
    If windows = 0 Then
        List1.AddItem "No open IDA Windows detected."
        Exit Sub
    ElseIf windows = 1 Then
        IDA_HWND = Servers(1)
    Else
        hwnd = Form2.SelectIDAInstance(False)
        If hwnd = 0 Then Exit Sub
        IDA_HWND = hwnd
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
    List2.Clear
    
    If IsWindow(IDA_HWND) = 0 Then
        List1.AddItem "No Ida Windows detected"
        Exit Sub
    End If
    
    List1.AddItem "Loaded idb: " & ida.LoadedFile()
    
    a = BenchMark()
    r = ida.NumFuncs()
    b = BenchMark()
    
    List1.AddItem "NumFuncs: " & r & " (org " & b - a & " ticks)"
    
    a = BenchMark()
    r = QuickCall(qcmNumFuncs)
    b = BenchMark()
    
    List1.AddItem "NumFuncs: " & r & " (quickcall " & b - a & " ticks)"
    
    
    va = ida.FunctionStart(0)
    List1.AddItem "Func[0].start: " & Hex(va)
    List1.AddItem "Func[0].end: " & Hex(ida.FunctionEnd(0))
    List1.AddItem "Func[0].name: " & ida.FunctionName(0)
    List1.AddItem "1st inst: " & ida.GetAsm(va)
    
    List1.AddItem "VA For Func 'start': " & Hex(ida.FuncAddrFromName("start"))
    
    List1.AddItem "Jumping to 1st inst"
    ida.Jump va
    
    ida.pythonTest "print 'test python command from IDASrvr Client!'"
    ida.pythonTest "print 'Is IDA Api available without import? BegineEA='+ hex(BeginEA())"
    ida.pythonTest "import idasrvr" & vbCrLf & "print 'idasrvr.test = ' + str(idasrvr.test())"
    resp = ida.pythonTest("reply(123)")
    resp = ida.pythonTest("reply('A'*1001)")
    List1.AddItem "Python len(retVal) = " & Len(resp) & " value = " & resp
    
    
End Sub

Private Sub Form_Unload(Cancel As Integer)
    Unhook
End Sub
 

