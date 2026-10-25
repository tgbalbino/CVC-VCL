unit CustomBtn;

interface

uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.Graphics,
  Vcl.Imaging.pngimage, Winapi.Windows, Winapi.Messages;

type
  TCustomBtn = class(TCustomControl)
  private
    FPng: TPngImage;
    FCaption: string;
    FOnClick: TNotifyEvent;
    procedure SetCaption(const Value: string);
    procedure SetPng(const Value: TPngImage);
  protected
    procedure Paint; override;
    procedure Click; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure LoadPngFromFile(const FileName: string);
  published
    property Caption: string read FCaption write SetCaption;
    property Png: TPngImage read FPng write SetPng;
    property Align;
    property Anchors;
    property Color;
    property Font;
    property ParentFont;
    property Visible;
    property OnClick: TNotifyEvent read FOnClick write FOnClick;
  end;

implementation

{ TPngButton }

constructor TCustomBtn.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPng := TPngImage.Create;
  Width := 100;
  Height := 30;
  Color := clBtnFace;
end;

destructor TCustomBtn.Destroy;
begin
  FPng.Free;
  inherited;
end;

procedure TCustomBtn.Click;
begin
  if Enabled and Assigned(FOnClick) then
    FOnClick(Self);
end;

procedure TCustomBtn.LoadPngFromFile(const FileName: string);
begin
  FPng.LoadFromFile(FileName);
  Invalidate;
end;

procedure TCustomBtn.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  Invalidate;
end;

procedure TCustomBtn.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  Invalidate;
end;

procedure TCustomBtn.Paint;
var
  R: TRect;
begin
  inherited;

  Canvas.Brush.Color := Color;
  Canvas.FillRect(ClientRect);

  // Desenhar imagem PNG no lado esquerdo
  if Assigned(FPng) and not FPng.Empty then
    Canvas.Draw(5, (Height - FPng.Height) div 2, FPng);

  // Texto
  Canvas.Font := Font;
  if not Enabled then
    Canvas.Font.Color := clGrayText;
  R := Rect(5 + FPng.Width + 5, 0, Width - 5, Height);
  DrawText(Canvas.Handle, PChar(FCaption), -1, R, DT_VCENTER or DT_SINGLELINE or DT_LEFT);
end;

procedure TCustomBtn.SetCaption(const Value: string);
begin
  if FCaption <> Value then
  begin
    FCaption := Value;
    Invalidate;
  end;
end;

procedure TCustomBtn.SetPng(const Value: TPngImage);
begin
  FPng.Assign(Value);
  Invalidate;
end;

end.


