unit CVCCRegister;

interface

procedure Register;

implementation

uses
  System.Classes, CVCDBEdit, CVCDateEdit, CVCValidateEdit, CpfCnpjDBEdit;

procedure Register;
begin
  RegisterComponents('CVC-VCL', [TCVCDBEdit, TCVCDateEdit, TCVCValidateEdit,
    TCpfCnpjDBEdit]);
end;

end.
