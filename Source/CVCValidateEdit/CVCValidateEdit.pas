unit CVCValidateEdit;

interface

uses
  Winapi.Messages, System.Classes, Vcl.Controls, Vcl.Graphics, Vcl.Forms,
  JvValidateEdit, CVCVisualSettings;

type
  TCVCValidateEdit = class(TJvValidateEdit, ICVCDisabledColorAware)
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
    procedure SetDisabledColor(const Value: TColor);
    procedure CVCDisabledColorChanged;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property DisabledColor: TColor read FDisabledColor write SetDisabledColor default clSilver;
    property DisabledFontColor: TColor read FDisabledFontColor write FDisabledFontColor default clWindowText;
    property DisabledCtl3D: Boolean read FDisabledCtl3D write FDisabledCtl3D default False;
  end;

implementation

constructor TCVCValidateEdit.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ParentColor := False;
  StyleElements := [];
  Color := clWindow;
  Flat := False;
  ParentFlat := False;
  BorderStyle := bsSingle;
  ParentCtl3D := False;
  Ctl3D := False;
  FDisabledColor := GetCVCDisabledColor;
  RegisterCVCDisabledColorControl(Self);
  FDisabledFontColor := clWindowText;
  FDisabledCtl3D := False;
end;

destructor TCVCValidateEdit.Destroy;
begin
  UnregisterCVCDisabledColorControl(Self);
  inherited;
end;

procedure TCVCValidateEdit.SetDisabledColor(const Value: TColor);
begin
  FDisabledColor := Value;
  FDisabledColorOverridden := True;
  ApplyEnabledAppearance;
end;

procedure TCVCValidateEdit.CVCDisabledColorChanged;
begin
  if not FDisabledColorOverridden then
  begin
    FDisabledColor := GetCVCDisabledColor;
    ApplyEnabledAppearance;
  end;
end;

procedure TCVCValidateEdit.CMEnabledChanged(var Message: TMessage);
begin
  inherited;
  ApplyEnabledAppearance;
end;

procedure TCVCValidateEdit.SetEnabled(Value: Boolean);
begin
  inherited;
  ApplyEnabledAppearance;
end;

procedure TCVCValidateEdit.WMPaint(var Message: TWMPaint);
var
  Canvas: TControlCanvas;
begin
  inherited;

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

procedure TCVCValidateEdit.ApplyEnabledAppearance;
begin
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

  Ctl3D := False;
end;

end.
