unit uSenhaEdit;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, Vcl.Graphics, Vcl.Controls,
  Vcl.Forms, Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.Buttons, Vcl.ImgList;

type
  TSenhaEdit = class(TCustomPanel)
  private
    FEdit: TEdit;
    FMostrar: TSpeedButton;
    FTimer: TTimer;
    FImages: TCustomImageList;
    FText: string;
    FMaxLength: Integer;
    FPasswordChar: Char;
    FShowImageIndex: Integer;
    FHideImageIndex: Integer;
    FAutoHideMilliseconds: Cardinal;
    FOnChange: TNotifyEvent;
    function GetText: string;
    function GetMaxLength: Integer;
    procedure SetText(const AValue: string);
    procedure SetMaxLength(const AValue: Integer);
    procedure SetPasswordChar(const AValue: Char);
    procedure SetImages(const AValue: TCustomImageList);
    procedure SetShowImageIndex(const AValue: Integer);
    procedure SetHideImageIndex(const AValue: Integer);
    procedure SetAutoHideMilliseconds(const AValue: Cardinal);
    procedure RedimensionarControles;
    procedure CriarControlesInternos;
    procedure AtualizarIcone;
    procedure AlternarVisibilidade(Sender: TObject);
    procedure OcultarSenha(Sender: TObject);
    procedure EditChange(Sender: TObject);
  protected
    procedure CreateWnd; override;
    procedure Resize; override;
    procedure SetEnabled(Value: Boolean); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Clear;
  published
    property Text: string read GetText write SetText;
    property PasswordChar: Char read FPasswordChar write SetPasswordChar;
    property MaxLength: Integer read GetMaxLength write SetMaxLength;
    property Images: TCustomImageList read FImages write SetImages;
    property ShowImageIndex: Integer read FShowImageIndex write SetShowImageIndex;
    property HideImageIndex: Integer read FHideImageIndex write SetHideImageIndex;
    property AutoHideMilliseconds: Cardinal read FAutoHideMilliseconds
      write SetAutoHideMilliseconds;
    property Align;
    property Anchors;
    property Color;
    property Enabled;
    property Font;
    property Height;
    property Hint;
    property Left;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property ShowHint;
    property TabOrder;
    property TabStop;
    property Top;
    property Visible;
    property Width;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property OnClick;
    property OnEnter;
    property OnExit;
  end;

implementation

constructor TSenhaEdit.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  BevelOuter := bvNone;
  ParentBackground := False;
  Color := clWhite;
  Height := 30;
  Width := 190;
  FPasswordChar := '*';
  FShowImageIndex := -1;
  FHideImageIndex := -1;
  FAutoHideMilliseconds := 5000;
end;

procedure TSenhaEdit.CreateWnd;
begin
  inherited CreateWnd;
  CriarControlesInternos;
end;

procedure TSenhaEdit.CriarControlesInternos;
begin
  if not Assigned(FEdit) then
  begin
    FEdit := TEdit.Create(Self);
    FEdit.Parent := Self;
    FEdit.PasswordChar := FPasswordChar;
    FEdit.MaxLength := FMaxLength;
    FEdit.Text := FText;
    FEdit.BorderStyle := bsSingle;
    FEdit.Color := clWhite;
    FEdit.OnChange := EditChange;
    FEdit.OnEnter := OnEnter;
    FEdit.OnExit := OnExit;
  end;
  if not Assigned(FMostrar) then
  begin
    FMostrar := TSpeedButton.Create(Self);
    FMostrar.Parent := Self;
    FMostrar.Cursor := crHandPoint;
    FMostrar.Flat := True;
    FMostrar.Margin := 0;
    FMostrar.Spacing := 0;
    FMostrar.Caption := '';
    FMostrar.Hint := 'Mostrar ou ocultar a senha';
    FMostrar.ShowHint := True;
    FMostrar.OnClick := AlternarVisibilidade;
  end;
  if not Assigned(FTimer) then
  begin
    FTimer := TTimer.Create(Self);
    FTimer.Enabled := False;
    FTimer.Interval := FAutoHideMilliseconds;
    FTimer.OnTimer := OcultarSenha;
  end;
  FEdit.Parent := Self;
  FMostrar.Parent := Self;
  RedimensionarControles;
  AtualizarIcone;
end;

procedure TSenhaEdit.Resize;
begin
  inherited Resize;
  RedimensionarControles;
end;

procedure TSenhaEdit.RedimensionarControles;
const
  LARGURA_BOTAO = 28;
begin
  if not Assigned(FEdit) or not Assigned(FMostrar) then
    Exit;
  FMostrar.SetBounds(ClientWidth - LARGURA_BOTAO, 0, LARGURA_BOTAO,
    ClientHeight);
  FEdit.SetBounds(0, 0, ClientWidth - LARGURA_BOTAO, ClientHeight);
  if (FEdit.Parent = Self) and (FMostrar.Parent = Self) then
    FMostrar.BringToFront;
end;

procedure TSenhaEdit.SetEnabled(Value: Boolean);
begin
  inherited SetEnabled(Value);
  if Assigned(FEdit) then
    FEdit.Enabled := Value;
  if Assigned(FMostrar) then
    FMostrar.Enabled := Value;
end;

function TSenhaEdit.GetText: string;
begin
  if Assigned(FEdit) then
    Result := FEdit.Text
  else
    Result := FText;
end;

function TSenhaEdit.GetMaxLength: Integer;
begin
  if Assigned(FEdit) then
    Result := FEdit.MaxLength
  else
    Result := FMaxLength;
end;

procedure TSenhaEdit.SetText(const AValue: string);
begin
  FText := AValue;
  if Assigned(FEdit) then
    FEdit.Text := AValue;
end;

procedure TSenhaEdit.SetMaxLength(const AValue: Integer);
begin
  FMaxLength := AValue;
  if Assigned(FEdit) then
    FEdit.MaxLength := AValue;
end;

procedure TSenhaEdit.EditChange(Sender: TObject);
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TSenhaEdit.SetPasswordChar(const AValue: Char);
begin
  FPasswordChar := AValue;
  if Assigned(FEdit) and (FEdit.PasswordChar <> #0) then
    FEdit.PasswordChar := AValue;
end;

procedure TSenhaEdit.SetImages(const AValue: TCustomImageList);
begin
  FImages := AValue;
  AtualizarIcone;
end;

procedure TSenhaEdit.SetShowImageIndex(const AValue: Integer);
begin
  FShowImageIndex := AValue;
  AtualizarIcone;
end;

procedure TSenhaEdit.SetHideImageIndex(const AValue: Integer);
begin
  FHideImageIndex := AValue;
  AtualizarIcone;
end;

procedure TSenhaEdit.SetAutoHideMilliseconds(const AValue: Cardinal);
begin
  FAutoHideMilliseconds := AValue;
  if Assigned(FTimer) then
    FTimer.Interval := AValue;
end;

procedure TSenhaEdit.AtualizarIcone;
var
  Bitmap: TBitmap;
  Indice: Integer;
begin
  if not Assigned(FEdit) or not Assigned(FMostrar) or not Assigned(FImages) then
    Exit;

  if FEdit.PasswordChar = #0 then
    Indice := FHideImageIndex
  else
    Indice := FShowImageIndex;
  if Indice < 0 then
    Exit;

  Bitmap := TBitmap.Create;
  try
    FImages.GetBitmap(Indice, Bitmap);
    FMostrar.Glyph.Assign(Bitmap);
    FMostrar.NumGlyphs := 1;
  finally
    Bitmap.Free;
  end;
end;

procedure TSenhaEdit.AlternarVisibilidade(Sender: TObject);
begin
  if FEdit.PasswordChar = #0 then
  begin
    FEdit.PasswordChar := FPasswordChar;
    FTimer.Enabled := False;
  end
  else
  begin
    FEdit.PasswordChar := #0;
    FTimer.Enabled := FAutoHideMilliseconds > 0;
  end;
  AtualizarIcone;
end;

procedure TSenhaEdit.OcultarSenha(Sender: TObject);
begin
  FTimer.Enabled := False;
  FEdit.PasswordChar := FPasswordChar;
  AtualizarIcone;
end;

procedure TSenhaEdit.Clear;
begin
  FText := '';
  if Assigned(FEdit) then
    FEdit.Clear;
end;

end.
