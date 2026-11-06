program DBLookupEditDemo;

uses
  Vcl.Forms,
  DemoMain in 'DemoMain.pas' {frmDBLookupEditDemo};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmDBLookupEditDemo, frmDBLookupEditDemo);
  Application.Run;
end.
