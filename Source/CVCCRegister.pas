unit CVCCRegister;

interface

procedure Register;

implementation

uses
  System.Classes, CVCDBEdit, CVCDateEdit, CVCValidateEdit, DBLookupEdit;

procedure Register;
begin
  RegisterComponents('CVC-VCL', [TCVCDBEdit, TCVCDateEdit, TCVCValidateEdit,
    TDBLookupEdit]);
end;

end.
