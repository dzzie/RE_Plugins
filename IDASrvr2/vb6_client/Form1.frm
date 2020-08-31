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
   Begin VB.TextBox Text1 
      Height          =   285
      Left            =   9225
      TabIndex        =   5
      Text            =   "Text1"
      Top             =   2610
      Width           =   960
   End
   Begin VB.CommandButton Command2 
      Caption         =   "Reg Find"
      Height          =   195
      Left            =   7695
      TabIndex        =   4
      Top             =   2610
      Width           =   1095
   End
   Begin VB.CommandButton Command1 
      Caption         =   "Connect to Active IDA Windows"
      Height          =   315
      Left            =   7650
      TabIndex        =   2
      Top             =   2250
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
'note both apps must be at same permission level to communicate over windows messages now..

Public ida As New CIDA
Dim sc As New cSubclass
Implements iSubclass

Const WM_COPYDATA = &H4A
 
Private Sub Command1_Click()
    IDA_HWND = Form2.SelectIDAInstance
    SampleAPI
End Sub

Private Sub Command2_Click()
    If ida.FindClient Then
        Text1 = Hex(IDA_HWND)
        SampleAPI
    Else
        List2.AddItem "Srvr2 window not found"
    End If
End Sub

Public Sub Hook(hWnd As Long)
     IDASRVR_BROADCAST_MESSAGE = RegisterWindowMessage(WINDOW_MSG_NAME)
     IDA_QUICKCALL_MESSAGE = RegisterWindowMessage(QUICKCALL_MSG_NAME)
     sc.Subclass hWnd, Me
     sc.AddMsg hWnd, IDASRVR_BROADCAST_MESSAGE, MSG_BEFORE
     sc.AddMsg hWnd, IDA_QUICKCALL_MESSAGE, MSG_BEFORE
     sc.AddMsg hWnd, WM_COPYDATA, MSG_BEFORE
 End Sub

 Public Sub Unhook()
     sc.Unsubclass Me.hWnd
 End Sub

Private Sub iSubclass_WndProc( _
    ByVal bBefore As Boolean, bHandled As Boolean, lReturn As Long, _
    ByVal hWnd As Long, ByVal uMsg As Long, ByVal wParam As Long, ByVal lParam As Long _
)
     
     If uMsg = IDASRVR_BROADCAST_MESSAGE Then
        If IsWindow(lParam) = 1 Then
            If Not KeyExistsInCollection(Servers, "hwnd:" & lParam) Then
                Servers.add lParam, "hwnd:" & lParam
                Form1.List2.AddItem "New IDASrvr registering itself hwnd= " & lParam
            End If
        End If
     End If
     
     If uMsg = WM_COPYDATA Then RecieveTextMessage lParam
      
End Sub
 

Private Sub Form_Load()

    Dim windows As Long
    Dim hWnd As Long
    
    Me.Visible = True
    
    Hook Me.hWnd
    List1.AddItem "Listening for messages on hwnd: " & Me.hWnd

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
        hWnd = Form2.SelectIDAInstance(False)
        If hWnd = 0 Then Exit Sub
        IDA_HWND = hWnd
    End If
        
    SampleAPI
    
    
End Sub

Sub SampleAPI()

    Dim va As ULong64
    Dim hWnd As Long
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
    
    
    Set va = ida.FunctionStart(1)
    List1.AddItem "Func[0].start: " & va.toString()
    List1.AddItem "Func[0].end: " & ida.FunctionEnd(1).toString()
    List1.AddItem "Func[0].name: " & ida.FunctionName(1)
    List1.AddItem "1st inst: " & ida.GetAsm(va)
    
    'List1.AddItem "VA For Func 'start': " & Hex(ida.FuncAddrFromName("start"))
    
    List1.AddItem "Jumping to 1st inst"
    ida.Jump va
    
End Sub

Private Sub Form_Unload(Cancel As Integer)
    Unhook
End Sub
 


