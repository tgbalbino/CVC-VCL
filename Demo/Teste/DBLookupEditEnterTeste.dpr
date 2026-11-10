program DBLookupEditEnterTeste;

uses
  Vcl.Forms,
  System.SysUtils,
  TesteMain in 'TesteMain.pas';

{$R *.res}

var
  Frm: TfrmTeste;

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmTeste, Frm);
  if FindCmdLineSwitch('auto') then
  begin
    Frm.AgendarAuto;
  end;
  Application.Run;
end.
