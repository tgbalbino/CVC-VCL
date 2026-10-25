unit CVCExtrasRegister;

interface

procedure Register;

implementation

uses
  System.Classes,
  CustomBtn,
  DBPersonComboBox,
  DateBox;

procedure Register;
begin
  RegisterComponents('CVC-VCL', [TCustomBtn, TDBPersonComboBox, TDateBox]);
end;

end.
