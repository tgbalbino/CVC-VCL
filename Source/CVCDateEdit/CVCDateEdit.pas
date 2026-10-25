unit CVCDateEdit;

interface

uses
  Winapi.Messages, System.Classes, Vcl.Controls, Vcl.Graphics, Vcl.StdCtrls,
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
    procedure SetEnabled(Value: Boolean); override;
    procedure CMEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
    procedure WMPaint(var Message: TWMPaint); message WM_PAINT;
    procedure ApplyEnabledAppearance;
    procedure SetCVCDisabledColor(const Value: TColor);
    procedure CVCDisabledColorChanged;
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

procedure TCVCDateEdit.SetCVCDisabledColor(const Value: TColor);
begin
  FDisabledColor := Value;
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

procedure TCVCDateEdit.ApplyEnabledAppearance;
begin
  // Keep the border visible in both control states. TJvDateEdit can change
  // Flat/Ctl3D when Enabled changes, which otherwise hides the border.
  Flat := False;
  ParentFlat := False;
  BorderStyle := bsSingle;
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

    Color := DisabledColor;
    DisabledTextColor := FDisabledFontColor;
    Font.Color := FDisabledFontColor;
    Ctl3D := FDisabledCtl3D;
  end
  else if FWasDisabled then
  begin
    Color := FColorBeforeDisable;
    Font.Color := FFontColorBeforeDisable;
    Ctl3D := FCtl3DBeforeDisable;
    FWasDisabled := False;
  end;

  // TJvDateEdit can restore Ctl3D when it changes state; keep the explicit
  // single border visible in the enabled and disabled states.
  Ctl3D := False;
end;

end.
