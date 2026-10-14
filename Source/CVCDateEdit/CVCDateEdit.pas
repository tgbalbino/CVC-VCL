unit CVCDateEdit;

interface

uses
  Winapi.Messages, System.Classes, Vcl.Controls, Vcl.Graphics, JvToolEdit;

type
  TCVCDateEdit = class(TJvDateEdit)
  private
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
    property DisabledColor default clSilver;
    property DisabledFontColor: TColor read FDisabledFontColor write FDisabledFontColor default clWindowText;
    property DisabledCtl3D: Boolean read FDisabledCtl3D write FDisabledCtl3D default False;
  end;

implementation

constructor TCVCDateEdit.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  DisabledColor := clSilver;
  DisabledTextColor := clWindowText;
  FDisabledFontColor := clWindowText;
  FDisabledCtl3D := False;
end;

procedure TCVCDateEdit.CMEnabledChanged(var Message: TMessage);
begin
  inherited;
  ApplyEnabledAppearance;
end;

procedure TCVCDateEdit.ApplyEnabledAppearance;
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
end;

end.
