unit CVCDBEdit;

interface

uses
  Winapi.Messages, System.Classes, Vcl.Controls, Vcl.DBCtrls, Vcl.Graphics,
  CVCVisualSettings;

type
  TCVCDBEdit = class(TDBEdit, ICVCDisabledColorAware)
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

constructor TCVCDBEdit.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ParentColor := False;
  StyleElements := [];
  Color := clWindow;
  FDisabledColor := GetCVCDisabledColor;
  RegisterCVCDisabledColorControl(Self);
  FDisabledFontColor := clWindowText;
  FDisabledCtl3D := False;
end;

destructor TCVCDBEdit.Destroy;
begin
  UnregisterCVCDisabledColorControl(Self);
  inherited;
end;

procedure TCVCDBEdit.SetDisabledColor(const Value: TColor);
begin
  FDisabledColor := Value;
  FDisabledColorOverridden := True;
  ApplyEnabledAppearance;
end;

procedure TCVCDBEdit.CVCDisabledColorChanged;
begin
  if not FDisabledColorOverridden then
  begin
    FDisabledColor := GetCVCDisabledColor;
    ApplyEnabledAppearance;
  end;
end;

procedure TCVCDBEdit.CMEnabledChanged(var Message: TMessage);
begin
  inherited;
  ApplyEnabledAppearance;
end;

procedure TCVCDBEdit.SetEnabled(Value: Boolean);
begin
  inherited;
  ApplyEnabledAppearance;
end;

procedure TCVCDBEdit.ApplyEnabledAppearance;
begin
  if not Enabled then
  begin
    if not FWasDisabled then
    begin
      FColorBeforeDisable := Color;
      FFontColorBeforeDisable := Font.Color;
      FCtl3DBeforeDisable := Ctl3D;
      FWasDisabled := True;
    end;

    Color := FDisabledColor;
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
end;

end.
