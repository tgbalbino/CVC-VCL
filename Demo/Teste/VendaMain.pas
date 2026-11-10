unit VendaMain;

{ Reproducao do fluxo de Enter do cabecalho da tela de venda com TECLAS REAIS
  (keybd_event): formulario com KeyPreview e as mesmas rotinas FormKeyDown /
  FormKeyPress / FocoEmLookup do FLancamento/uLanSaida, mesma ordem de
  tabulacao (barra de botoes antes do cabecalho) e campo de data TCVCDateEdit
  (JVCL). Precisa de sessao com area de trabalho. }

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  System.Variants, Vcl.Forms, Vcl.Controls, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.DBCtrls, Vcl.Mask, Vcl.ComCtrls, Data.DB,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error,
  FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool,
  FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Phys.FB, FireDAC.Phys.FBDef,
  FireDAC.Comp.Client, FireDAC.Comp.DataSet, FireDAC.DApt,
  FireDAC.VCLUI.Wait, FireDAC.Comp.UI,
  DBLookupEdit, CVCDateEdit, CVCDBEdit, uLookupForm;

type
  TfrmVenda = class(TForm)
  private
    FConn: TFDConnection;
    FMem: TFDMemTable;
    FSource: TDataSource;
    FPnlTopo, FPnlBotoes, FPnlCab: TPanel;
    FB1, FB2, FB3: TButton;
    FCli, FVen: TDBLookupEdit;
    FData: TCVCDateEdit;
    FDesc, FObs: TCVCDBEdit;
    FTimer: TTimer;
    FLog: TStringList;
    FGrades: Integer;
    FFalhas: Integer;
    FHold: Integer;
    FEntrada: Boolean; // FormKeyPress como o da Entrada (sem o else pendente)
    FCorrigido: Boolean; // FormKeyDown corrigido (SelectNext a partir do foco real)
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    function FocoEmLookup: Boolean;
    procedure TimerGrade(Sender: TObject);
    procedure TimerAuto(Sender: TObject);
    procedure Escrever(const S: string);
    function Nome(C: TControl): string;
    function Atual: string;
    procedure Tecla(VK: Word; Espera: Integer = 400);
    procedure Esperar(Ms: Integer);
    procedure Traz;
    procedure Focar(C: TWinControl);
    procedure Preparar(ComVendedor: Boolean);
    procedure Rodar(const Titulo: string; ComVendedor: Boolean; AInicio: TWinControl;
      const Esperado: array of string);
  public
    constructor Create(AOwner: TComponent); override;
    procedure Embutir(AParent: TWinControl);
    procedure Modo(AEntrada, ACorrigido: Boolean);
    procedure AgendarAuto;
    procedure Executar;
    property Falhas: Integer read FFalhas;
  end;

  THostAbas = class(TForm)
  public
    Paginas: TPageControl;
    Aba: TTabSheet;
    constructor Create(AOwner: TComponent); override;
  end;

implementation

constructor THostAbas.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  Caption := 'Host de abas';
  SetBounds(100, 100, 920, 480);
  Paginas := TPageControl.Create(Self);
  Paginas.Parent := Self;
  Paginas.Align := alClient;
  Aba := TTabSheet.Create(Self);
  Aba.PageControl := Paginas;
  Aba.Caption := 'Nova venda';
  Paginas.ActivePage := Aba;
end;

procedure TfrmVenda.Embutir(AParent: TWinControl);
begin
  // mesmo tratamento de uWorkspaceAbas.AdicionarForm
  Visible := False;
  BorderStyle := bsNone;
  BorderIcons := [];
  FormStyle := fsNormal;
  Position := poDesigned;
  Align := alClient;
  Parent := AParent;
  Show;
end;

constructor TfrmVenda.Create(AOwner: TComponent);
var
  Senha: string;
begin
  inherited CreateNew(AOwner);
  Caption := 'Teste - fluxo de Enter da venda';
  Width := 900;
  Height := 420;
  Position := poScreenCenter;
  KeyPreview := True;
  OnKeyDown := FormKeyDown;
  OnKeyPress := FormKeyPress;
  FLog := TStringList.Create;
  TFDGUIxWaitCursor.Create(Self);
  FConn := TFDConnection.Create(Self);
  FConn.LoginPrompt := False;
  Senha := GetEnvironmentVariable('CVC_LOOKUP_DB_PASSWORD');
  if Senha = '' then
    Senha := 'masterkey';
  FConn.Params.Values['DriverID'] := 'FB';
  FConn.Params.Values['Protocol'] := 'TCPIP';
  FConn.Params.Values['Server'] := 'localhost';
  FConn.Params.Values['Database'] := 'C:\Bancos\DBLOOKUPDEMO\DEMO.FDB';
  FConn.Params.Values['User_Name'] := 'SYSDBA';
  FConn.Params.Values['Password'] := Senha;
  FConn.Open;

  FMem := TFDMemTable.Create(Self);
  FSource := TDataSource.Create(Self);
  FSource.DataSet := FMem;
  FMem.FieldDefs.Add('IDCLIENTE', ftInteger);
  FMem.FieldDefs.Add('IDVENDEDOR', ftInteger);
  FMem.FieldDefs.Add('DESCONTO', ftFloat);
  FMem.FieldDefs.Add('OBSERVACAO', ftString, 60);
  FMem.CreateDataSet;

  // mesma ordem de TabOrder da tela real: 0 titulo, 1 barra de botoes, 2 cabecalho
  FPnlTopo := TPanel.Create(Self);
  FPnlTopo.Parent := Self;
  FPnlTopo.SetBounds(0, 0, 900, 30);
  FPnlTopo.TabOrder := 0;
  FPnlTopo.Caption := 'Nova venda';
  FPnlBotoes := TPanel.Create(Self);
  FPnlBotoes.Parent := Self;
  FPnlBotoes.SetBounds(0, 30, 900, 40);
  FPnlBotoes.TabOrder := 1;
  FB1 := TButton.Create(Self);
  FB1.Parent := FPnlBotoes;
  FB1.SetBounds(5, 5, 60, 28);
  FB1.Caption := 'Incluir';
  FB1.TabOrder := 0;
  FB2 := TButton.Create(Self);
  FB2.Parent := FPnlBotoes;
  FB2.SetBounds(70, 5, 60, 28);
  FB2.Caption := 'Salvar';
  FB2.TabOrder := 1;
  FB3 := TButton.Create(Self);
  FB3.Parent := FPnlBotoes;
  FB3.SetBounds(135, 5, 60, 28);
  FB3.Caption := 'Cancelar';
  FB3.TabOrder := 2;
  FPnlCab := TPanel.Create(Self);
  FPnlCab.Parent := Self;
  FPnlCab.SetBounds(0, 70, 900, 300);
  FPnlCab.TabOrder := 2;

  FCli := TDBLookupEdit.Create(Self);
  FCli.Parent := FPnlCab;
  FCli.SetBounds(10, 10, 600, 40);
  FCli.TabOrder := 0;
  FCli.LabelCaption := 'Cliente.:';
  FCli.LabelPosition := lpLeft;
  FVen := TDBLookupEdit.Create(Self);
  FVen.Parent := FPnlCab;
  FVen.SetBounds(10, 55, 600, 40);
  FVen.TabOrder := 1;
  FVen.LabelCaption := 'Vendedor.:';
  FVen.LabelPosition := lpLeft;
  FData := TCVCDateEdit.Create(Self);
  FData.Parent := FPnlCab;
  FData.SetBounds(124, 100, 110, 26);
  FData.TabOrder := 2;
  FData.CheckOnExit := True;
  FData.ShowNullDate := False;
  FDesc := TCVCDBEdit.Create(Self);
  FDesc.Parent := FPnlCab;
  FDesc.SetBounds(124, 135, 110, 24);
  FDesc.TabOrder := 3;
  FDesc.DataSource := FSource;
  FDesc.DataField := 'DESCONTO';
  FObs := TCVCDBEdit.Create(Self);
  FObs.Parent := FPnlCab;
  FObs.SetBounds(124, 165, 374, 24);
  FObs.TabOrder := 4;
  FObs.DataSource := FSource;
  FObs.DataField := 'OBSERVACAO';

  FCli.Connection := FConn;
  FCli.DataSource := FSource;
  FCli.DataField := 'IDCLIENTE';
  FCli.Lookup.Tabela := 'PESSOA';
  FCli.Lookup.ID := 'IDCLIENTE';
  FCli.Lookup.CampoRetorno := 'NOME';
  FCli.Lookup.CampoPesquisaAlternativo := 'REFERENCIA';
  FCli.Lookup.SearchFilter := 'CLI=''S''';
  FCli.Lookup.DisplayFields := 'IDCLIENTE,REFERENCIA,NOME';
  FVen.Connection := FConn;
  FVen.DataSource := FSource;
  FVen.DataField := 'IDVENDEDOR';
  FVen.Lookup.Tabela := 'PESSOA';
  FVen.Lookup.ID := 'IDCLIENTE';
  FVen.Lookup.CampoRetorno := 'NOME';
  FVen.Lookup.CampoPesquisaAlternativo := 'REFERENCIA';
  FVen.Lookup.SearchFilter := 'VEN=''S''';
  FVen.Lookup.DisplayFields := 'IDCLIENTE,REFERENCIA,NOME';

  FTimer := TTimer.Create(Self);
  FTimer.Interval := 15;
  FTimer.OnTimer := TimerGrade;
  Visible := True;
end;

{ ---- copia fiel de FLancamento.FormKeyDown / uLanSaida.FormKeyPress ---- }

function TfrmVenda.FocoEmLookup: Boolean;
var
  Pai: TControl;
begin
  Result := False;
  Pai := ActiveControl;
  while Assigned(Pai) do
  begin
    if Pai is TDBLookupEdit then
      Exit(True);
    Pai := Pai.Parent;
  end;
end;

procedure TfrmVenda.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  Controle, Pai: TControl;
begin
  if Key <> VK_RETURN then
    Exit;
  Controle := FindControl(GetFocus);
  Pai := Controle;
  while Assigned(Pai) do
  begin
    if Pai is TDBLookupEdit then
      Exit;
    Pai := Pai.Parent;
  end;
  if not (Controle is TCustomEdit) then
    Exit;
  Key := 0;
  Escrever(Format('    [KeyDown Enter] controle=%s proximo=%s foco(VCL ActiveControl)=%s',
    [Nome(Controle), Nome(FindNextControl(TWinControl(Controle), True, True, False)),
     Nome(ActiveControl)]));
  if FCorrigido then
    // Tela embutida: o ActiveControl do form fica vazio e WM_NEXTDLGCTL partiria
    // do primeiro controle (barra de botoes). Avanca do controle com foco real.
    SelectNext(TWinControl(Controle), True, True)
  else
    PostMessage(Handle, WM_NEXTDLGCTL, 0, 0);
end;

// Saida: else pendente (o ramo do Enter nunca executa). Entrada: ramo ativo.
procedure TfrmVenda.FormKeyPress(Sender: TObject; var Key: Char);
begin
  if FEntrada then
  begin
    if Key = #13 then
    begin
      Key := #0;
      if FCorrigido then
        Exit; // o KeyDown ja avancou
      if not FocoEmLookup then
        Perform(WM_NEXTDLGCTL, 0, 0);
    end;
    Exit;
  end;
  if (Key = #27) and (FGrades < 0) then
    Exit
  else if (Key = #27) then
    if Assigned(FTimer.OnTimer) then
      Exit
    else if Key = #13 then
    begin
      Key := #0;
      if not FocoEmLookup then
        Perform(WM_NEXTDLGCTL, 0, 0);
    end;
end;

procedure TfrmVenda.Modo(AEntrada, ACorrigido: Boolean);
begin
  FEntrada := AEntrada;
  FCorrigido := ACorrigido;
end;

{ ---- infraestrutura do teste ---- }

procedure TfrmVenda.TimerGrade(Sender: TObject);
var
  I: Integer;
begin
  for I := 0 to Screen.FormCount - 1 do
    if (Screen.Forms[I] is TfrmLookup) and (Screen.Forms[I].Tag = 0) then
    begin
      Screen.Forms[I].Tag := 1;
      Inc(FGrades);
      TfrmLookup(Screen.Forms[I]).btnOk.Click;
    end;
end;

procedure TfrmVenda.Escrever(const S: string);
begin
  FLog.Add(S);
  FLog.SaveToFile(ChangeFileExt(ParamStr(0), '.venda.txt'));
end;

function TfrmVenda.Nome(C: TControl): string;
begin
  if C = nil then
    Exit('(nenhum)');
  if C = FCli then Exit('Cliente');
  if C = FVen then Exit('Vendedor');
  if C = FData then Exit('Data');
  if C = FDesc then Exit('Desconto');
  if C = FObs then Exit('Observacao');
  if C = FB1 then Exit('Botao Incluir');
  if C = FB2 then Exit('Botao Salvar');
  if C = FB3 then Exit('Botao Cancelar');
  if C.Parent is TDBLookupEdit then
    Exit(Nome(C.Parent));
  Result := C.ClassName + '/' + C.Name;
end;

function TfrmVenda.Atual: string;
begin
  Result := Nome(FindControl(GetFocus));
end;

procedure TfrmVenda.Esperar(Ms: Integer);
var
  T: Cardinal;
begin
  T := GetTickCount;
  while GetTickCount - T < Cardinal(Ms) do
  begin
    Application.ProcessMessages;
    Sleep(10);
  end;
end;

procedure TfrmVenda.Traz;
var
  FG: HWND;
  T1, T2: Cardinal;
begin
  FG := GetForegroundWindow;
  T1 := GetWindowThreadProcessId(FG, nil);
  T2 := GetCurrentThreadId;
  if T1 <> T2 then
    AttachThreadInput(T2, T1, True);
  SetForegroundWindow(GetParentForm(Self).Handle);
  BringWindowToTop(GetParentForm(Self).Handle);
  if T1 <> T2 then
    AttachThreadInput(T2, T1, False);
  Esperar(300);
end;

procedure TfrmVenda.Tecla(VK: Word; Espera: Integer);
var
  H: HWND;
  Scan: LPARAM;
begin
  // Injeta as mensagens direto na fila desta aplicacao, na mesma ordem em que
  // o Windows entrega (KeyDown, Char, ... KeyUp apos o tempo de tecla
  // pressionada). Nao usa o teclado do sistema: nao interfere em outros apps.
  H := GetFocus;
  Scan := LPARAM(MapVirtualKey(VK, 0)) shl 16;
  PostMessage(H, WM_KEYDOWN, VK, Scan or 1);
  if VK = VK_RETURN then
    PostMessage(H, WM_CHAR, 13, Scan or 1);
  Esperar(FHold);
  PostMessage(GetFocus, WM_KEYUP, VK, Scan or 1 or LPARAM($C0000000));
  Esperar(Espera);
end;

procedure TfrmVenda.Focar(C: TWinControl);
var
  K: Integer;
begin
  if C is TDBLookupEdit then
  begin
    for K := 0 to C.ControlCount - 1 do
      if (C.Controls[K] is TEdit) and not TEdit(C.Controls[K]).ReadOnly then
      begin
        try
          TWinControl(C.Controls[K]).SetFocus; // como FocusFirstEditableControl
        except
          on E: Exception do
            Escrever(Format('  focar %s: %s (Enabled=%s Visible=%s CanFocus=%s FormEnabled=%s)',
              [C.Controls[K].ClassName, E.Message, BoolToStr(C.Controls[K].Enabled, True),
               BoolToStr(C.Controls[K].Visible, True),
               BoolToStr(TWinControl(C.Controls[K]).CanFocus, True), BoolToStr(Enabled, True)]));
        end;
        Break;
      end;
  end
  else
    C.SetFocus;
  Esperar(300);
end;

procedure TfrmVenda.Preparar(ComVendedor: Boolean);
begin
  if FMem.State in dsEditModes then
    FMem.Post;
  FMem.EmptyDataSet;
  FMem.Append;
  FCli.Clear;
  FVen.Clear;
  FData.Date := Date;
  if ComVendedor then
  begin
    FCli.LoadByID(1);
    FVen.LoadByID(201);
  end;
  Esperar(100);
end;

procedure TfrmVenda.Rodar(const Titulo: string; ComVendedor: Boolean;
  AInicio: TWinControl; const Esperado: array of string);
var
  I: Integer;
  Obtido, Extra: string;
  Ok: Boolean;
begin
  Escrever('');
  Escrever(Titulo);
  Preparar(ComVendedor);
  Focar(AInicio);
  Escrever('  foco inicial: ' + Atual);
  Ok := True;
  for I := 0 to High(Esperado) do
  begin
    FGrades := 0;
    Tecla(VK_RETURN);
    Obtido := Atual;
    Extra := '';
    if FGrades > 0 then
      Extra := '  [grade abriu ' + IntToStr(FGrades) + 'x]';
    if Obtido <> Esperado[I] then
    begin
      Ok := False;
      Extra := Extra + '  <== DIFERENTE';
    end;
    Escrever(Format('  Enter %d -> %s (esperado %s)%s', [I + 1, Obtido, Esperado[I], Extra]));
  end;
  if Ok then
    Escrever('  RESULTADO: OK')
  else
  begin
    Inc(FFalhas);
    Escrever('  RESULTADO: FALHA');
  end;
end;

procedure TfrmVenda.AgendarAuto;
begin
  with TTimer.Create(Self) do
  begin
    Interval := 800;
    OnTimer := TimerAuto;
  end;
end;

procedure TfrmVenda.TimerAuto(Sender: TObject);
begin
  TTimer(Sender).Enabled := False;
  try
    Executar;
  except
    on E: Exception do
    begin
      Escrever('EXCECAO: ' + E.ClassName + ': ' + E.Message);
      Inc(FFalhas);
    end;
  end;
  Halt(FFalhas);
end;

procedure TfrmVenda.Executar;
begin
  Traz;
  Escrever('Primeiro plano: ' + BoolToStr(GetForegroundWindow = GetParentForm(Self).Handle, True));
  Escrever(Format('Estado: Visible=%s Showing=%s ParentVisible=%s CliVisible=%s CliShowing=%s',
    [BoolToStr(Visible, True), BoolToStr(Showing, True), BoolToStr(Parent <> nil, True),
     BoolToStr(FCli.Visible, True), BoolToStr(FCli.Showing, True)]));
  FHold := 100;
  Escrever(Format('Modo: Entrada=%s Corrigido=%s', [BoolToStr(FEntrada, True), BoolToStr(FCorrigido, True)]));
  Escrever('Tecla segurada ' + IntToStr(FHold) + ' ms');
  Rodar('V1 Cliente e Vendedor ja preenchidos: Enter em cada campo', True, FCli,
    ['Vendedor', 'Data', 'Desconto', 'Observacao']);
  Rodar('V2 Enter a partir da Data', True, FData, ['Desconto', 'Observacao']);
  Rodar('V3 Enter a partir do Desconto', True, FDesc, ['Observacao']);
end;

end.
