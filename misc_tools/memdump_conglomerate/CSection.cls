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
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
'dzzie@yahoo.com
'http://sandsprite.com

Public nameSec As String
'Public PhisicalAddress As Integer
Public VirtualSize As Long
Public VirtualAddress As Long
Public SizeOfRawData As Long
Public PointerToRawData As Long
Public PointerToRelocations As Long
Public PointerToLinenumbers As Long
Public NumberOfRelocations As Integer
Public NumberOfLinenumbers As Integer
Public Characteristics As Long
 
Public index As Long 'used for collection index



 Friend Function LoadStruc(sh As IMAGE_SECTION_HEADER)
    
    With sh
        nameSec = Replace(.nameSec, Chr(0), "") 'string *8 extra null
        'PhisicalAddress = .PhisicalAddress
        VirtualSize = .VirtualSize
        VirtualAddress = .VirtualAddress
        SizeOfRawData = .SizeOfRawData
        PointerToRawData = .PointerToRawData
        PointerToRelocations = .PointerToRelocations
        PointerToLinenumbers = .PointerToLinenumbers
        NumberOfRelocations = .NumberOfRelocations
        NumberOfLinenumbers = .NumberOfLinenumbers
        Characteristics = .Characteristics
    End With
    
 End Function

 Friend Function GetStruc() As IMAGE_SECTION_HEADER
    
    With GetStruc
        .nameSec = nameSec & Chr(0)
        '.PhisicalAddress = PhisicalAddress
        .VirtualSize = VirtualSize
        .VirtualAddress = VirtualAddress
        .SizeOfRawData = SizeOfRawData
        .PointerToRawData = PointerToRawData
        .PointerToRelocations = PointerToRelocations
        .PointerToLinenumbers = PointerToLinenumbers
        .NumberOfRelocations = NumberOfRelocations
        .NumberOfLinenumbers = NumberOfLinenumbers
        .Characteristics = Characteristics
    End With

 End Function
 
