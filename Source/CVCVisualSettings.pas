unit CVCVisualSettings;

interface

uses
  System.SysUtils, System.Generics.Collections, Vcl.Graphics;

type
  ICVCDisabledColorAware = interface
    ['{E6FD3D89-77AF-4C10-9D83-4B5B0A77FD64}']
    procedure CVCDisabledColorChanged;
  end;

procedure RegisterCVCDisabledColorControl(AControl: TObject);
procedure UnregisterCVCDisabledColorControl(AControl: TObject);
procedure SetCVCDisabledColor(const Value: TColor);
function GetCVCDisabledColor: TColor;

var
  CVCDisabledColor: TColor = clSilver;

implementation

var
  GRegisteredControls: TList<TObject>;

procedure RegisterCVCDisabledColorControl(AControl: TObject);
begin
  if Assigned(AControl) and (GRegisteredControls.IndexOf(AControl) < 0) then
    GRegisteredControls.Add(AControl);
end;

procedure UnregisterCVCDisabledColorControl(AControl: TObject);
begin
  if Assigned(GRegisteredControls) then
    GRegisteredControls.Remove(AControl);
end;

procedure SetCVCDisabledColor(const Value: TColor);
var
  I: Integer;
  AConsumer: ICVCDisabledColorAware;
begin
  if CVCDisabledColor = Value then
    Exit;

  CVCDisabledColor := Value;

  for I := GRegisteredControls.Count - 1 downto 0 do
    if Supports(GRegisteredControls[I], ICVCDisabledColorAware, AConsumer) then
      AConsumer.CVCDisabledColorChanged;
end;

function GetCVCDisabledColor: TColor;
begin
  Result := CVCDisabledColor;
end;

initialization
  GRegisteredControls := TList<TObject>.Create;

finalization
  GRegisteredControls.Free;

end.
