unit CVCCRegister;

interface

procedure Register;

implementation

uses
  System.Classes, CVCDBEdit, CVCDateEdit, CVCValidateEdit, DBLookupEdit,
  DBValueComboBox, CpfCnpjDBEdit;

procedure Register;
begin
  RegisterComponents('CVC-VCL', [TCVCDBEdit, TCVCDateEdit, TCVCValidateEdit,
    TDBLookupEdit, TDBValueComboBox, TCpfCnpjDBEdit]);
end;

end.
