program ValidTeste;

uses
  Vcl.Forms,
  System.SysUtils,
  ValidMain in 'ValidMain.pas';

{$R *.res}

var
  Frm: TfrmValid;
begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmValid, Frm);
  Frm.AgendarAuto;
  Application.Run;
end.
