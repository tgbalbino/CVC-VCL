unit CVCDBEdit;

interface

uses
  Winapi.Messages, System.Classes, Vcl.Controls, Vcl.DBCtrls, Vcl.Graphics;

type
  TCVCDBEdit = class(TDBEdit)
  private
    FDisabledColor: TColor;
    FDisabledFontColor: TColor;
    FDisabledCtl3D: Boolean;
    FWasDisabled: Boolean;
    FColorBeforeDisable: TColor;
    FFontColorBeforeDisable: TColor;
    FCtl3DBeforeDisable: Boolean;
    procedure CMEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
    procedure ApplyEnabledAppearance;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property DisabledColor: TColor read FDisabledColor write FDisabledColor default clSilver;
    property DisabledFontColor: TColor read FDisabledFontColor write FDisabledFontColor default clWindowText;
    property DisabledCtl3D: Boolean read FDisabledCtl3D write FDisabledCtl3D default False;
  end;

implementation

constructor TCVCDBEdit.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FDisabledColor := clSilver;
  FDisabledFontColor := clWindowText;
  FDisabledCtl3D := False;
end;

procedure TCVCDBEdit.CMEnabledChanged(var Message: TMessage);
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
