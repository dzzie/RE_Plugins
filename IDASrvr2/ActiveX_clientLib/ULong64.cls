VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "ULong64"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
'from http://github.com/dzzie/libs/vb6_utypes

Enum op
    op_add = 0
    op_sub = 1
    op_div = 2
    op_mul = 3
    op_mod = 4
    op_xor = 5
    op_and = 6
    op_or = 7
    op_rsh = 8
    op_lsh = 9
    op_gt = 10
    op_lt = 11
    op_gteq = 12
    op_lteq = 13
End Enum

Enum modes
    mUnsigned = 0
    mSigned = 1
    mHex = 2
End Enum

Public mode As modes
Public rawValue As Currency   'this is the default property of the class
Public padLeft As Boolean
Public useTick As Boolean
Public use0x As Boolean
Public def32bit As Boolean

'Currency (scaled integer) 8 bytes
'-922,337,203,685,477.5808 to 922,337,203,685,477.5807

Dim hLib As Long
Private Declare Function LoadLibrary Lib "kernel32" Alias "LoadLibraryA" (ByVal lpLibFileName As String) As Long

'unsigned math operations
Private Declare Function U64 Lib "utypes.dll" (ByVal v1 As Currency, ByVal v2 As Currency, ByVal operation As op) As Currency

'signed math for 64 bit numbers (necessary?)
Private Declare Function S64 Lib "utypes.dll" (ByVal v1 As Currency, ByVal v2 As Currency, ByVal operation As op) As Currency

'create 64 bit number from hi and lo longs
Private Declare Function toU64 Lib "utypes.dll" (ByVal v1 As Long, ByVal v2 As Long) As Currency

'create a 64 bit number from a string in specified base (16 for a hex string)
Private Declare Function Str264 Lib "utypes.dll" (ByVal s As String, Optional ByVal base As Long = 10) As Currency

'convert a 64 bit number to string in specified format
Private Declare Function U642Str Lib "utypes.dll" (ByVal v1 As Currency, ByVal buf As String, ByVal cBufferSize As Long, ByVal mode As modes) As Long

'get hi and lo longs from 64 numbers
Private Declare Sub fromU64 Lib "utypes.dll" (ByVal v0 As Currency, ByRef v1 As Long, ByRef v2 As Long)

Property Get Value()
Attribute Value.VB_UserMemId = 0
    Value = rawValue
End Property

'this is the default method of the class
Property Let Value(v)
    
    If TypeName(v) = "String" Then
        fromString v
    ElseIf TypeName(v) = "ULong64" Then
        rawValue = v.Value
    ElseIf TypeName(v) = "ULong" Or TypeName(v) = "UInt" Or TypeName(v) = "UByte" Then
        SetLongs 0, v.Value
    ElseIf TypeName(v) = "Long" Or TypeName(v) = "Byte" Or TypeName(v) = "Integer" Then
        SetLongs 0, CLng(v)
    Else
        Err.Raise 1, "ULong64.Value", "Unsupported conversion type to ULong64: " & TypeName(v)
    End If

End Property

'this way you can .setval(x).add(y)
Function setVal(v) As ULong64
    Set setVal = Me
    Value = v
End Function

Property Get MAX_SIGNED64() As String
     If useTick Then
        MAX_SIGNED64 = "7FFFFFFF`FFFFFFFF"
     Else
        MAX_SIGNED64 = "7FFFFFFFFFFFFFFF"
     End If
     If use0x Then MAX_SIGNED64 = "0x" & MAX_SIGNED64
End Property

Property Get MIN_SIGNED64() As String
    If useTick Then
        MIN_SIGNED64 = "80000000`00000000"
    Else
        MIN_SIGNED64 = "8000000000000000"
    End If
    If use0x Then MIN_SIGNED64 = "0x" & MIN_SIGNED64
End Property

Property Get MAX_UNSIGNED64() As String
    If useTick Then
        MAX_UNSIGNED64 = "FFFFFFFF`FFFFFFFF"
    Else
        MAX_UNSIGNED64 = "FFFFFFFFFFFFFFFF"
    End If
    If use0x Then MAX_UNSIGNED64 = "0x" & MAX_UNSIGNED64
End Property

Property Get is32BitSafe() As Boolean
    Dim hi As Long, lo As Long
    GetLongs hi, lo
    If hi = 0 Then is32BitSafe = True
End Property

Property Get isNegBitSet() As Boolean
    isNegBitSet = (Left(toString(mSigned), 1) = "-")
End Property

Property Get hi() As Long
    GetLongs hi
End Property

Property Let hi(x As Long)
    Dim a As Long, b As Long
    GetLongs a, b
    SetLongs x, b
End Property

Property Get lo() As Long
    GetLongs , lo
End Property

Property Let lo(x As Long)
    Dim a As Long, b As Long
    GetLongs a, b
    SetLongs a, x
End Property

Function toString(Optional m As modes = mHex) As String
    Dim tmp As String, i As Long, lo As String, hi As String, a As Long
    tmp = Space(64)
    i = U642Str(rawValue, tmp, 64, m)
    If i > 0 Then
        tmp = UCase(Mid(tmp, 1, i))
        If m = mHex Then
            If is32BitSafe() Then
                If padLeft Then
                    tmp = Right("00000000" & tmp, 8)
                End If
            Else
                If padLeft Then
                    tmp = Right("0000000000000000" & tmp, 16)
                End If
                If useTick Then
                    a = Len(tmp) - 8
                    If a > 0 Then
                        lo = Right(tmp, 8)
                        hi = Mid(tmp, 1, Len(tmp) - 8)
                        tmp = hi & "`" & lo
                    End If
                End If
            End If
            If use0x Then tmp = "0x" & tmp
        End If
        toString = tmp
    End If
End Function


Function fromString(ByVal s As String, Optional m As modes = mHex) As Boolean
    On Error GoTo hell
    s = Trim(s)
    s = Replace(s, "`", Empty)
    
    If Left(s, 1) = "-" Then m = mSigned
    
    If LCase(Left(s, 2)) = "0x" Or LCase(Left(s, 2)) = "&h" Or LCase(Left(s, 2)) = "\x" Then
        m = mHex
        s = Mid(s, 3)
    End If
    
    rawValue = Str264(s, IIf(m = mHex, 16, 10))
    
    fromString = True
    Exit Function
hell:
End Function

Sub SetLongs(Optional hi As Long, Optional lo As Long)
    rawValue = toU64(hi, lo)
End Sub

Sub GetLongs(Optional ByRef hi As Long, Optional ByRef lo As Long)
    fromU64 rawValue, hi, lo
End Sub

'this is left public so that once this goes into a binary compatiable dll
'you can still access new operations manually by passing in its op const
Function raw_op(operand2, operation As op) As ULong64
    Dim ret As New ULong64
    Dim tmp As New ULong64
    
    If TypeName(operand2) = "ULong64" Then
        Set tmp = operand2
    ElseIf TypeName(operand2) = "ULong" Then
        tmp.SetLongs 0, operand2.rawValue
    Else
        tmp.SetLongs 0, CLng(operand2)
    End If
    
    If mode = mSigned Then
        ret.rawValue = S64(rawValue, tmp.rawValue, operation)
    Else
        ret.rawValue = U64(rawValue, tmp.rawValue, operation)
    End If
    
    ret.mode = Me.mode
    ret.use0x = Me.useTick
    ret.use0x = Me.use0x
    ret.padLeft = Me.padLeft
    
    Set raw_op = ret
    
End Function


Private Sub Class_Initialize()
    hLib = LoadLibrary("UTypes.dll")
    If hLib = 0 Then hLib = LoadLibrary(App.path & "\UTypes.dll")
    If hLib = 0 Then hLib = LoadLibrary(App.path & "\..\UTypes.dll")
    If hLib = 0 Then hLib = LoadLibrary(App.path & "\..\..\UTypes.dll")
'    If ensureUTypes() Then hLib = modGeneral.hUTypes
    padLeft = True
    def32bit = True
    useTick = True
End Sub

'these stubs are for readability/ease of use
Function add(operand2) As ULong64
    Set add = raw_op(operand2, op_add)
End Function

Function subtract(operand2) As ULong64
    Set subtract = raw_op(operand2, op_sub)
End Function

Function divide(operand2) As ULong64
    Set divide = raw_op(operand2, op_div)
End Function

Function multiply(operand2) As ULong64
    Set multiply = raw_op(operand2, op_mul)
End Function

Function modulus(operand2) As ULong64
    Set modulus = raw_op(operand2, op_mod)
End Function

Function xor_(operand2) As ULong64
    Set xor_ = raw_op(operand2, op_xor)
End Function

Function and_(operand2) As ULong64
    Set and_ = raw_op(operand2, op_and)
End Function

Function or_(operand2) As ULong64
    Set or_ = raw_op(operand2, op_or)
End Function

Function rshift(operand2) As ULong64
    Set rshift = raw_op(operand2, op_rsh)
End Function

Function lshift(operand2) As ULong64
    Set lshift = raw_op(operand2, op_lsh)
End Function

Function greaterThan(operand2) As Boolean
    Dim a As ULong64
    Set a = raw_op(operand2, op_gt)
    greaterThan = (a.rawValue = 1)
End Function

Function lessThan(operand2) As Boolean
    Dim a As ULong64
    Set a = raw_op(operand2, op_lt)
    lessThan = (a.rawValue = 1)
End Function

Function greaterThanEqual(operand2) As Boolean
    Dim a As ULong64
    Set a = raw_op(operand2, op_gteq)
    greaterThanEqual = (a.rawValue = 1)
End Function

Function lessThanEqual(operand2) As Boolean
    Dim a As ULong64
    Set a = raw_op(operand2, op_lteq)
    lessThanEqual = (a.rawValue = 1)
End Function
