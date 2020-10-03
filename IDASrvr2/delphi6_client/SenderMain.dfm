object SenderMainForm: TSenderMainForm
  Left = 1314
  Top = 196
  Width = 533
  Height = 375
  Caption = 'CopyData Sender'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = OnCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 8
    Top = 168
    Width = 81
    Height = 13
    Caption = 'Debug Messages'
  end
  object ListBox1: TListBox
    Left = 8
    Top = 184
    Width = 513
    Height = 161
    ItemHeight = 13
    TabOrder = 0
  end
  object ListBox2: TListBox
    Left = 8
    Top = 0
    Width = 513
    Height = 153
    ItemHeight = 13
    TabOrder = 1
  end
end
