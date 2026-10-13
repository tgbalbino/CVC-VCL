unit CVCCRegister;

interface

procedure Register;

implementation

uses
  System.Classes, CVCDBEdit, CVCDateEdit, CpfCnpjDBEdit, DBLookupEdit;

procedure Register;
begin
  RegisterComponents('CVC-VCL', [TDBLookupEdit, TCVCDBEdit, TCVCDateEdit,
    TCpfCnpjDBEdit]);
end;

end.
