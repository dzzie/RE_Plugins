VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "CSection"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Public nameSec As String
'Public PhisicalAddress As Integer
Public VirtualSize As Long
Public VirtualAddress As Long
Public SizeOfRawData As Long
Public PointerToRawData As Long
Public Characteristics As Long
Private stuff(1 To 12) As Byte

Private i As Integer

Friend Sub LoadStruc(sh As SECTION_HEADER)
    
    With sh
        nameSec = .nameSec
        'PhisicalAddress = .PhisicalAddress
        VirtualSize = .VirtualSize
        VirtualAddress = .VirtualAddress
        SizeOfRawData = .SizeOfRawData
        PointerToRawData = .PointerToRawData
        Characteristics = .Characteristics
        For i = 1 To 12
            stuff(i) = .stuff(i)
        Next
    End With
    
End Sub

Friend Sub GetStruc(sh As SECTION_HEADER)

    With sh
        .nameSec = nameSec
        '.PhisicalAddress = PhisicalAddress
        .VirtualSize = VirtualSize
        .VirtualAddress = VirtualAddress
        .SizeOfRawData = SizeOfRawData
        .PointerToRawData = PointerToRawData
        .Characteristics = Characteristics
        For i = 1 To 12
            .stuff(i) = stuff(i)
        Next
    End With

End Sub
