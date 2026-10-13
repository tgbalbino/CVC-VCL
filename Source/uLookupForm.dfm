object frmLookup: TfrmLookup
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Selecione um Registro'
  ClientHeight = 400
  ClientWidth = 600
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = True
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 360
    Width = 600
    Height = 40
    Align = alBottom
    TabOrder = 0
    object btnOk: TBitBtn
      AlignWithMargins = True
      Left = 440
      Top = 4
      Width = 75
      Height = 32
      Align = alRight
      Caption = 'OK'
      TabOrder = 0
      OnClick = btnOkClick
      ExplicitLeft = 377
      ExplicitTop = -4
    end
    object btnCancel: TBitBtn
      AlignWithMargins = True
      Left = 521
      Top = 4
      Width = 75
      Height = 32
      Align = alRight
      Caption = 'Cancelar'
      TabOrder = 1
      OnClick = btnCancelClick
      ExplicitLeft = 500
      ExplicitTop = 8
      ExplicitHeight = 25
    end
  end
  object DBGrid1: TDBGrid
    Left = 0
    Top = 0
    Width = 600
    Height = 360
    Align = alClient
    Options = [dgTitles, dgIndicator, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgConfirmDelete, dgCancelOnExit, dgTitleClick, dgTitleHotTrack]
    ReadOnly = True
    TabOrder = 1
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'Tahoma'
    TitleFont.Style = []
    OnDblClick = DBGrid1DblClick
    OnKeyPress = DBGrid1KeyPress
  end
end
