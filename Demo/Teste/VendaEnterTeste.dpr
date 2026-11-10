program VendaEnterTeste;

uses
  Vcl.Forms,
  System.SysUtils,
  VendaMain in 'VendaMain.pas';

{$R *.res}

var
  Frm: TfrmVenda;
  Host: THostAbas;
begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  if FindCmdLineSwitch('embed') then
  begin
    Application.CreateForm(THostAbas, Host);
    Frm := TfrmVenda.Create(Host);
    Frm.Embutir(Host.Aba);
  end
  else
    Application.CreateForm(TfrmVenda, Frm);
  Frm.Modo(FindCmdLineSwitch('entrada'), FindCmdLineSwitch('fix'));
  if FindCmdLineSwitch('auto') then
    Frm.AgendarAuto;
  Application.Run;
end.
