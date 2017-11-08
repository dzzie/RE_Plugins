VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "CIDA"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
'see IDA_JSCript for more this is a quick adaption for the demo..


Function ShowServers() As Long
    Form2.Show
End Function
 

Property Get LoadedFile() As String
    LoadedFile = SendCmdRecvText("loadedfile:" & Form1.hwnd)
End Property

Function NumFuncs() As Long
    NumFuncs = SendCmdRecvLong("numfuncs")
End Function

Function FuncAddrFromName(funcName As String) As Long
   FuncAddrFromName = SendCMD("name_va:" & funcName)
End Function

Function FunctionStart(functionIndex)
    FunctionStart = SendCmdRecvLong("funcstart:" & functionIndex)
End Function

Function FunctionEnd(functionIndex)
    FunctionEnd = SendCmdRecvLong("funcend:" & functionIndex)
End Function
 
Function FunctionName(functionIndex)
    FunctionName = SendCmdRecvText("funcname:" & functionIndex & ":" & Form1.hwnd)
End Function

Function GetAsm(va)
    GetAsm = SendCmdRecvText("getasm:" & va & ":" & Form1.hwnd)
End Function

Function Jump(va As Long)
   SendCMD "jmp:" & va
End Function

'will find last opened instance if still active
Function FindClient() As Boolean
    Dim hwnd As Long
    
    On Error Resume Next
    
    hwnd = CLng(GetSetting("IPC", "Handles", "IDA_SERVER", 0))
    If hwnd <> 0 Then
        If IsWindow(hwnd) = 1 Then
            FindClient = True
            Module1.IDA_HWND = hwnd
        Else
            SaveSetting "IPC", "Handles", "IDA_SERVER", 0
            Module1.IDA_HWND = 0
            FindClient = False
        End If
    End If
    
End Function

Function pythonTest(cmd)
    'since we use : as a token and so does python..we might need to transpose it with it another character...
    cmd = Replace(cmd, ":", Chr(5))
    SendCMD "pycmd:" & Form1.hwnd & ":" & cmd
    pythonTest = ResponseBuffer
End Function

