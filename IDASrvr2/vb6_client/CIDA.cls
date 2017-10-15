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

Function FuncAddrFromName(funcName As String) As ULong64
   Set FuncAddrFromName = SendCmdRecvX64("name_va:" & funcName)
End Function

Function FunctionStart(functionIndex) As ULong64
    Set FunctionStart = SendCmdRecvX64("funcstart:" & functionIndex & ":" & Form1.hwnd)
End Function

Function FunctionEnd(functionIndex) As ULong64
    Set FunctionEnd = SendCmdRecvX64("funcend:" & functionIndex & ":" & Form1.hwnd)
End Function
 
Function FunctionName(functionIndex)
    FunctionName = SendCmdRecvText("funcname:" & functionIndex & ":" & Form1.hwnd)
End Function

Function GetAsm(va As ULong64)
    GetAsm = SendCmdRecvText("getasm:" & va.toString(mUnsigned) & ":" & Form1.hwnd)
End Function

Function Jump(va As ULong64)
   SendCMD "jmp:" & va.toString(mUnsigned)
End Function

'will find last opened instance if still active
Function FindClient() As Boolean
    Dim hwnd As Long
    
    On Error Resume Next
    
    hwnd = CLng(GetSetting("IPC", "Handles", "IDA_SERVER2", 0))
    If hwnd <> 0 Then
        If IsWindow(hwnd) = 1 Then
            FindClient = True
            Module1.IDA_HWND = hwnd
        Else
            SaveSetting "IPC", "Handles", "IDA_SERVER2", 0
            Module1.IDA_HWND = 0
            FindClient = False
        End If
    End If
    
End Function

 
