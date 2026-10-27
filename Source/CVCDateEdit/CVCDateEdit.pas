unit CVCDateEdit;

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.UxTheme, System.Classes, Vcl.Controls, Vcl.Graphics, Vcl.StdCtrls,
  Vcl.Forms,
  JvToolEdit, CVCVisualSettings;

type
  TCVCDateEdit = class(TJvDateEdit, ICVCDisabledColorAware)
  private
    FDisabledColor: TColor;
    FDisabledColorOverridden: Boolean;
    FDisabledFontColor: TColor;
    FDisabledCtl3D: Boolean;
    FWasDisabled: Boolean;
    FColorBeforeDisable: TColor;
    FFontColorBeforeDisable: TColor;
    FCtl3DBeforeDisable: Boolean;
    FTemaRemovido: Boolean;
    procedure SetEnabled(Value: Boolean); override;
    procedure CMEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
    procedure CNCtlColor(var Message: TMessage); message CN_CTLCOLOREDIT;
    procedure WMPaint(var Message: TWMPaint); message WM_PAINT;
    function DoEraseBackground(Canvas: TCanvas; Param: LPARAM): Boolean; override;
    procedure ApplyEnabledAppearance;
    procedure SetCVCDisabledColor(const Value: TColor);
    procedure CVCDisabledColorChanged;
  protected
    procedure DestroyWnd; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property DisabledColor: TColor read FDisabledColor write SetCVCDisabledColor default clSilver;
    property DisabledFontColor: TColor read FDisabledFontColor write FDisabledFontColor default clWindowText;
    property DisabledCtl3D: Boolean read FDisabledCtl3D write FDisabledCtl3D default False;
  end;

implementation

constructor TCVCDateEdit.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ParentColor := False;
  StyleElements := [];
  Color := clWindow;
  BorderStyle := bsSingle;
  ParentCtl3D := False;
  Ctl3D := False;
  FDisabledColor := GetCVCDisabledColor;
  RegisterCVCDisabledColorControl(Self);
  DisabledTextColor := clWindowText;
  FDisabledFontColor := clWindowText;
  FDisabledCtl3D := False;
end;

destructor TCVCDateEdit.Destroy;
begin
  UnregisterCVCDisabledColorControl(Self);
  inherited;
end;

procedure TCVCDateEdit.DestroyWnd;
begin
  FTemaRemovido := False;
  inherited;
end;

procedure TCVCDateEdit.SetCVCDisabledColor(const Value: TColor);
begin
  FDisabledColor := Value;
  // TJvCustomComboEdit pinta a area desabilitada usando o campo interno da
  // classe base. O componente CVC possui uma propriedade homonima; manter os
  // dois valores sincronizados evita que a caixa interna permaneça branca.
  inherited SetDisabledColor(Value);
  FDisabledColorOverridden := True;
  ApplyEnabledAppearance;
end;

procedure TCVCDateEdit.CVCDisabledColorChanged;
begin
  if not FDisabledColorOverridden then
  begin
    FDisabledColor := GetCVCDisabledColor;
    ApplyEnabledAppearance;
  end;
end;

procedure TCVCDateEdit.CMEnabledChanged(var Message: TMessage);
begin
  inherited;
  ApplyEnabledAppearance;
end;

procedure TCVCDateEdit.SetEnabled(Value: Boolean);
begin
  inherited;
  ApplyEnabledAppearance;
end;

procedure TCVCDateEdit.WMPaint(var Message: TWMPaint);
var
  Canvas: TControlCanvas;
begin
  inherited;

  // TJvDateEdit paints the disabled edit through a custom path that can omit
  // the non-client frame. Draw the explicit single border after that paint so
  // it remains visible in both enabled and disabled states.
  if BorderStyle = bsSingle then
  begin
    Canvas := TControlCanvas.Create;
    try
      Canvas.Control := Self;
      Canvas.Brush.Style := bsSolid;
      Canvas.Brush.Color := clBlack;
      Canvas.FrameRect(ClientRect);
    finally
      Canvas.Free;
    end;
  end;
end;

function TCVCDateEdit.DoEraseBackground(Canvas: TCanvas; Param: LPARAM): Boolean;
begin
  // O tema do Windows pode ignorar FDisabledColor no caminho padrao do JVCL.
  // Pintar aqui garante que a area interna tambem use o cinza configurado.
  if not Enabled then
  begin
    // SetWindowTheme envia WM_THEMECHANGED, que repinta o controle e volta a
    // passar por aqui (WM_ERASEBKGND). Chamar a cada pintura gerava um laco
    // infinito de repaint com o campo desabilitado (pisca, CPU alta e
    // WM_PAINT dos demais controles da tela nunca eram entregues). So chama
    // uma vez por handle.
    if HandleAllocated and not FTemaRemovido then
    begin
      FTemaRemovido := True;
      SetWindowTheme(Handle, '', '');
    end;
    Canvas.Brush.Style := bsSolid;
    Canvas.Brush.Color := DisabledColor;
    Canvas.FillRect(ClientRect);
    Result := True;
  end
  else
    Result := inherited DoEraseBackground(Canvas, Param);
end;

procedure TCVCDateEdit.ApplyEnabledAppearance;
begin
  // Keep the border visible in both control states. TJvDateEdit can change
  // Flat/Ctl3D when Enabled changes, which otherwise hides the border.
  // So atribui quando o valor muda: Flat/Ctl3D/BorderStyle recriam o handle
  // (RecreateWnd) e o campo piscava varias vezes ao habilitar/desabilitar.
  // Flat := False equivale a Ctl3D := True, que era desfeito no fim do metodo
  // (duas recriacoes por chamada), por isso nao e mais usado.
  if BorderStyle <> bsSingle then
    BorderStyle := bsSingle;
  if ParentCtl3D then
    ParentCtl3D := False;

  if not Enabled then
  begin
    if not FWasDisabled then
    begin
      FColorBeforeDisable := Color;
      FFontColorBeforeDisable := Font.Color;
      FCtl3DBeforeDisable := Ctl3D;
      FWasDisabled := True;
    end;

    if Color <> DisabledColor then
      Color := DisabledColor;
    DisabledTextColor := FDisabledFontColor;
    if Font.Color <> FDisabledFontColor then
      Font.Color := FDisabledFontColor;
    if Ctl3D <> FDisabledCtl3D then
      Ctl3D := FDisabledCtl3D;
  end
  else if FWasDisabled then
  begin
    if Color <> FColorBeforeDisable then
      Color := FColorBeforeDisable;
    if Font.Color <> FFontColorBeforeDisable then
      Font.Color := FFontColorBeforeDisable;
    // Ctl3D nao e restaurado aqui: o valor capturado podia ser True e o
    // ajuste final forca False, o que gerava duas recriacoes de handle.
    FWasDisabled := False;
  end;

  // TJvDateEdit can restore Ctl3D when it changes state; keep the explicit
  // single border visible in the enabled and disabled states.
  if Ctl3D then
    Ctl3D := False;
end;

procedure TCVCDateEdit.CNCtlColor(var Message: TMessage);
var
  DC: HDC;
begin
  DC := HDC(Message.WParam);
  if not Enabled then
  begin
    SetDCBrushColor(DC, ColorToRGB(DisabledColor));
    SetBkColor(DC, ColorToRGB(DisabledColor));
    SetTextColor(DC, ColorToRGB(FDisabledFontColor));
    Message.Result := LRESULT(GetStockObject(DC_BRUSH));
  end
  else
    inherited;
end;

end.
