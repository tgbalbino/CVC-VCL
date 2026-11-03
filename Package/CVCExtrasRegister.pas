unit CVCExtrasRegister;

interface

procedure Register;

implementation

uses
  System.Classes,
  CustomBtn,
  DBPersonComboBox,
  DateBox,
  uSenhaEdit;

procedure Register;
begin
  RegisterComponents('CVC-VCL', [TCustomBtn, TDBPersonComboBox, TDateBox, TSenhaEdit]);
end;

end.
