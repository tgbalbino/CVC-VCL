unit CVCExtrasRegister;

interface

procedure Register;

implementation

uses
  System.Classes,
  CustomBtn,
  DBValueComboBox,
  DBPersonComboBox,
  DateBox;

procedure Register;
begin
  RegisterComponents('CVC-VCL', [TCustomBtn, TDBValueComboBox,
    TDBPersonComboBox, TDateBox]);
end;

end.
