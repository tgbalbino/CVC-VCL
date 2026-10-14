unit CVCCRegister;

interface

procedure Register;

implementation

uses
  System.Classes, CVCDBEdit, CVCDateEdit, CVCValidateEdit;

procedure Register;
begin
  RegisterComponents('CVC-VCL', [TCVCDBEdit, TCVCDateEdit, TCVCValidateEdit]);
end;

end.
