unit CVCCRegister;

interface

procedure Register;

implementation

uses
  System.Classes, CVCDBEdit, CVCDateEdit, CpfCnpjDBEdit;

procedure Register;
begin
  RegisterComponents('CVC-VCL', [TCVCDBEdit, TCVCDateEdit, TCpfCnpjDBEdit]);
end;

end.
