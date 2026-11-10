unit ValidMain;

{ Testa a marca vermelha do TValidador (uAlertaBootstrap real do ERP):
  aparece na falha de validacao e some ao cancelar, fechar, salvar, trocar de
  registro, desabilitar o campo ou alterar o conteudo. Sem teclado do sistema. }

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  System.Variants, Vcl.Graphics, Vcl.Forms, Vcl.Controls, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.DBCtrls, Vcl.Dialogs, Data.DB,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error,
  FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool,
  FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Phys.FB, FireDAC.Phys.FBDef,
  FireDAC.Comp.Client, FireDAC.Comp.DataSet, FireDAC.DApt,
  FireDAC.VCLUI.Wait, FireDAC.Comp.UI,
  DBLookupEdit, CVCDBEdit, uAlertaBootstrap, uObrigatorios;

type
  TfrmValid = class(TForm)
  private
    FConn: TFDConnection;
    FMem: TFDMemTable;
    FSource: TDataSource;
    FPnl: TPanel;
    FNumero: TCVCDBEdit;      // campo ligado a dados
    FSerie: TDBEdit;          // campo ligado a dados (VCL puro)
    FFornec: TDBLookupEdit;   // lookup ligado a dados
    FLivre: TEdit;            // sem ligacao a dados
    FTimer: TTimer;
    FLog: TStringList;
    FFalhas: Integer;
    FTotal: Integer;
    procedure TimerFecharAlerta(Sender: TObject);
    procedure TimerAuto(Sender: TObject);
    procedure Escrever(const S: string);
    procedure Check(const Nome: string; Cond: Boolean);
    function MarcaVisivel(C: TWinControl): Boolean;
    function TodasMarcadas: Boolean;
    function NenhumaMarcada: Boolean;
    procedure Pausa(Ms: Integer);
    procedure Novo;
    procedure Validar;
    procedure Executar;
    procedure ExecutarObrigatorios;
  public
    constructor Create(AOwner: TComponent); override;
    procedure AgendarAuto;
  end;

implementation

constructor TfrmValid.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  Caption := 'Teste - marca de validacao';
  SetBounds(120, 120, 700, 300);
  FLog := TStringList.Create;
  TFDGUIxWaitCursor.Create(Self);
  FConn := TFDConnection.Create(Self);
  FConn.LoginPrompt := False;
  FConn.Params.Values['DriverID'] := 'FB';
  FConn.Params.Values['Protocol'] := 'TCPIP';
  FConn.Params.Values['Server'] := 'localhost';
  FConn.Params.Values['Database'] := 'C:\Bancos\DBLOOKUPDEMO\DEMO.FDB';
  FConn.Params.Values['User_Name'] := 'SYSDBA';
  FConn.Params.Values['Password'] := GetEnvironmentVariable('CVC_LOOKUP_DB_PASSWORD');
  if FConn.Params.Values['Password'] = '' then
    FConn.Params.Values['Password'] := 'masterkey';
  FConn.Open;

  FMem := TFDMemTable.Create(Self);
  FSource := TDataSource.Create(Self);
  FSource.DataSet := FMem;
  FMem.FieldDefs.Add('NUMERO', ftString, 10);
  FMem.FieldDefs.Add('SERIE', ftString, 5);
  FMem.FieldDefs.Add('IDFORNEC', ftInteger);
  FMem.CreateDataSet;

  FPnl := TPanel.Create(Self);
  FPnl.Parent := Self;
  FPnl.Align := alClient;
  FNumero := TCVCDBEdit.Create(Self);
  FNumero.Parent := FPnl;
  FNumero.SetBounds(20, 20, 120, 24);
  FNumero.DataSource := FSource;
  FNumero.DataField := 'NUMERO';
  FSerie := TDBEdit.Create(Self);
  FSerie.Parent := FPnl;
  FSerie.SetBounds(180, 20, 60, 24);
  FSerie.DataSource := FSource;
  FSerie.DataField := 'SERIE';
  FFornec := TDBLookupEdit.Create(Self);
  FFornec.Parent := FPnl;
  FFornec.SetBounds(20, 70, 500, 40);
  FFornec.Connection := FConn;
  FFornec.DataSource := FSource;
  FFornec.DataField := 'IDFORNEC';
  FFornec.Lookup.Tabela := 'PESSOA';
  FFornec.Lookup.ID := 'IDCLIENTE';
  FFornec.Lookup.CampoRetorno := 'NOME';
  FFornec.Lookup.DisplayFields := 'IDCLIENTE,NOME';
  FLivre := TEdit.Create(Self);
  FLivre.Parent := FPnl;
  FLivre.SetBounds(20, 140, 200, 24);

  FTimer := TTimer.Create(Self);
  FTimer.Interval := 20;
  FTimer.OnTimer := TimerFecharAlerta;
  Visible := True;
end;

// Fecha a janela modal do alerta (MostrarAlerta) assim que ela abre.
procedure TfrmValid.TimerFecharAlerta(Sender: TObject);
var
  I: Integer;
begin
  for I := 0 to Screen.FormCount - 1 do
    if (Screen.Forms[I] <> Self) and (fsModal in Screen.Forms[I].FormState) then
      Screen.Forms[I].ModalResult := mrOk;
end;

procedure TfrmValid.AgendarAuto;
begin
  with TTimer.Create(Self) do
  begin
    Interval := 700;
    OnTimer := TimerAuto;
  end;
end;

procedure TfrmValid.TimerAuto(Sender: TObject);
begin
  TTimer(Sender).Enabled := False;
  try
    Executar;
  except
    on E: Exception do
    begin
      Inc(FFalhas);
      Escrever('EXCECAO: ' + E.ClassName + ': ' + E.Message);
    end;
  end;
  Escrever(Format('Resultado: %d verificacoes, %d falha(s)', [FTotal, FFalhas]));
  Halt(FFalhas);
end;

procedure TfrmValid.Escrever(const S: string);
begin
  FLog.Add(S);
  FLog.SaveToFile(ChangeFileExt(ParamStr(0), '.txt'));
end;

procedure TfrmValid.Check(const Nome: string; Cond: Boolean);
begin
  Inc(FTotal);
  if Cond then
    Escrever('  OK    ' + Nome)
  else
  begin
    Inc(FFalhas);
    Escrever('  FALHA ' + Nome);
  end;
end;

procedure TfrmValid.Pausa(Ms: Integer);
var
  T: Cardinal;
begin
  T := GetTickCount;
  while GetTickCount - T < Cardinal(Ms) do
  begin
    Application.ProcessMessages;
    Sleep(5);
  end;
end;

// A marca e um TPanel vermelho (RGB 220,53,69) atras do campo, filho do mesmo pai.
function TfrmValid.MarcaVisivel(C: TWinControl): Boolean;
var
  I: Integer;
  P: TControl;
begin
  Result := False;
  for I := 0 to C.Parent.ControlCount - 1 do
  begin
    P := C.Parent.Controls[I];
    if (P is TPanel) and (TPanel(P).Color = RGB(220, 53, 69)) and P.Visible and
       (P.Left = C.Left - 2) and (P.Top = C.Top - 2) then
      Exit(True);
  end;
end;

function TfrmValid.TodasMarcadas: Boolean;
begin
  Result := MarcaVisivel(FNumero) and MarcaVisivel(FSerie) and
    MarcaVisivel(FFornec) and MarcaVisivel(FLivre);
end;

function TfrmValid.NenhumaMarcada: Boolean;
begin
  Result := (not MarcaVisivel(FNumero)) and (not MarcaVisivel(FSerie)) and
    (not MarcaVisivel(FFornec)) and (not MarcaVisivel(FLivre));
end;

procedure TfrmValid.Novo;
begin
  if FMem.Active and (FMem.State in dsEditModes) then
    FMem.Cancel;
  if not FMem.Active then
    FMem.Open;
  FMem.EmptyDataSet;
  FFornec.Clear;
  FLivre.Text := '';
  FLivre.Enabled := True;
  FNumero.Enabled := True;
  FSerie.Enabled := True;
  FFornec.Enabled := True;
  FMem.Append;
  Pausa(50);
end;

// Mesmo uso das telas: todos os campos vazios falham e a mensagem aborta.
procedure TfrmValid.Validar;
var
  V: TValidador;
begin
  V := TValidador.Create;
  try
    V.Exigir(Trim(FNumero.Text) <> '', FNumero, 'Informe o numero.', 'Numero');
    V.Exigir(Trim(FSerie.Text) <> '', FSerie, 'Informe a serie.', 'Serie');
    V.Exigir(FFornec.HasValue, FFornec, 'Selecione o fornecedor.', 'Fornecedor');
    V.Exigir(Trim(FLivre.Text) <> '', FLivre, 'Informe o campo livre.', 'Livre');
    try
      V.ConcluirOuAbortar('Nao foi possivel salvar');
    except
      on EAbort do ;
    end;
  finally
    V.Free;
  end;
  Pausa(50);
end;

procedure TfrmValid.Executar;
begin
  Escrever('Marca de validacao - ' + FormatDateTime('dd/mm/yyyy hh:nn:ss', Now));

  Escrever('');
  Escrever('M1 Falha de validacao marca todos os campos');
  Novo;
  Validar;
  Check('todos os campos marcados', TodasMarcadas);

  Escrever('');
  Escrever('M2 Cancelar o registro (Cancel) limpa as marcas dos campos ligados a dados');
  FMem.Cancel;
  Pausa(50);
  Check('campos ligados a dados sem marca',
    (not MarcaVisivel(FNumero)) and (not MarcaVisivel(FSerie)) and (not MarcaVisivel(FFornec)));
  Check('campo livre (sem dataset) ainda marcado, ate LimparMarcasErro', MarcaVisivel(FLivre));
  LimparMarcasErro(FPnl);
  Check('LimparMarcasErro limpa o campo livre', NenhumaMarcada);

  Escrever('');
  Escrever('M3 Fechar o dataset (cancelar da venda) limpa as marcas');
  Novo;
  Validar;
  Check('marcadas de novo apos nova falha', TodasMarcadas);
  FMem.Close;
  Pausa(50);
  Check('dataset fechado: campos ligados sem marca',
    (not MarcaVisivel(FNumero)) and (not MarcaVisivel(FSerie)) and (not MarcaVisivel(FFornec)));
  FMem.Open;

  Escrever('');
  Escrever('M4 Campos desabilitados (modo consulta) limpam a marca, inclusive no lookup');
  Novo;
  Validar;
  Check('marcadas', TodasMarcadas);
  FNumero.Enabled := False;
  FSerie.Enabled := False;
  FFornec.Enabled := False;
  FLivre.Enabled := False;
  Pausa(50);
  Check('desabilitar limpa todas as marcas', NenhumaMarcada);
  FNumero.Enabled := True;
  FSerie.Enabled := True;
  FFornec.Enabled := True;
  FLivre.Enabled := True;

  Escrever('');
  Escrever('M5 Salvar (Post) e navegar limpam as marcas');
  Novo;
  Validar;
  Check('marcadas', TodasMarcadas);
  FMem.FieldByName('NUMERO').AsString := '1';
  FMem.FieldByName('SERIE').AsString := '1';
  FMem.Post;
  Pausa(50);
  Check('apos salvar, campos ligados sem marca',
    (not MarcaVisivel(FNumero)) and (not MarcaVisivel(FSerie)) and (not MarcaVisivel(FFornec)));
  Novo;
  Validar;
  FMem.Cancel;
  FMem.Append;
  FMem.Post; // primeiro registro
  FMem.Append;
  FMem.Post; // segundo registro (fica posicionado nele)
  Validar;
  Check('marcadas', TodasMarcadas);
  FMem.First;
  Pausa(50);
  Check('mudar de registro limpa as marcas dos campos ligados',
    (not MarcaVisivel(FNumero)) and (not MarcaVisivel(FSerie)) and (not MarcaVisivel(FFornec)));
  LimparMarcasErro(FPnl);

  Escrever('');
  Escrever('M6 Comportamento existente continua: editar o campo limpa a marca; nova falha remarca');
  Novo;
  Validar;
  Check('marcadas', TodasMarcadas);
  FLivre.Text := 'x';
  Pausa(50);
  Check('texto alterado limpa so o campo editado',
    (not MarcaVisivel(FLivre)) and MarcaVisivel(FNumero) and MarcaVisivel(FSerie));
  FLivre.Text := '';
  Validar;
  Check('nova validacao remarca', TodasMarcadas);
  FMem.Cancel;
  LimparMarcasErro(FPnl);
  Check('limpo no final', NenhumaMarcada);

  Escrever('');
  Escrever('M7 Durante a edicao, alterar um campo nao apaga as marcas dos outros');
  Novo;
  Validar;
  Check('marcadas', TodasMarcadas);
  FMem.FieldByName('SERIE').AsString := '1';
  Pausa(50);
  Check('campo alterado sem marca', not MarcaVisivel(FSerie));
  Check('os demais continuam marcados',
    MarcaVisivel(FNumero) and MarcaVisivel(FFornec) and MarcaVisivel(FLivre));
  FMem.Cancel;

  ExecutarObrigatorios;
end;

// Asteriscos vermelhos ("*") a direita do controle (os do componente e os manuais).
function ContarAsteriscos(C: TWinControl): Integer;
var
  I: Integer;
  X: TControl;
begin
  Result := 0;
  for I := 0 to C.Parent.ControlCount - 1 do
  begin
    X := C.Parent.Controls[I];
    if (X is TLabel) and (TLabel(X).Caption = '*') and X.Visible and
       (X.Left >= C.Left + C.Width - 6) and (X.Left <= C.Left + C.Width + 48) and
       (X.Top >= C.Top - 8) and (X.Top <= C.Top + C.Height) then
      Inc(Result);
  end;
end;

procedure TfrmValid.ExecutarObrigatorios;
var
  Mem: TFDMemTable;
  Src: TDataSource;
  Pnl: TPanel;
  Numero, Serie, Codigo: TCVCDBEdit;
  Fornec: TDBLookupEdit;
  Livre, Extra: TEdit;
  Manual: TLabel;

  function Erros: Integer;
  var
    V: TValidador;
  begin
    V := TValidador.Create;
    try
      TCamposObrigatorios.Exigir(V, Pnl);
      Result := V.TotalErros;
    finally
      V.Free;
    end;
  end;

begin
  Escrever('');
  Escrever('=== Campos obrigatorios dinamicos ===');

  Mem := TFDMemTable.Create(Self);
  Src := TDataSource.Create(Self);
  Src.DataSet := Mem;
  Mem.FieldDefs.Add('NUMERO', ftString, 10, True);   // NOT NULL
  Mem.FieldDefs.Add('SERIE', ftString, 5);           // aceita nulo
  Mem.FieldDefs.Add('CODIGO', ftInteger, 0, True);   // NOT NULL, preenchido por codigo
  Mem.FieldDefs.Add('IDFORNEC', ftInteger, 0, True); // NOT NULL (lookup)

  Pnl := TPanel.Create(Self);
  Pnl.Parent := Self;
  Pnl.SetBounds(0, 170, 700, 130);
  Numero := TCVCDBEdit.Create(Self);
  Numero.Parent := Pnl;
  Numero.SetBounds(20, 10, 120, 24);
  Numero.DataSource := Src;
  Numero.DataField := 'NUMERO';
  Serie := TCVCDBEdit.Create(Self);
  Serie.Parent := Pnl;
  Serie.SetBounds(220, 10, 60, 24);
  Serie.DataSource := Src;
  Serie.DataField := 'SERIE';
  Codigo := TCVCDBEdit.Create(Self);
  Codigo.Parent := Pnl;
  Codigo.SetBounds(320, 10, 80, 24);
  Codigo.DataSource := Src;
  Codigo.DataField := 'CODIGO';
  Codigo.TabStop := False;
  Fornec := TDBLookupEdit.Create(Self);
  Fornec.Parent := Pnl;
  Fornec.SetBounds(20, 50, 400, 40);
  Fornec.Connection := FConn;
  Fornec.DataSource := Src;
  Fornec.DataField := 'IDFORNEC';
  Fornec.LabelCaption := 'Fornecedor.:';
  Fornec.LabelPosition := lpLeft;
  Fornec.Lookup.Tabela := 'PESSOA';
  Fornec.Lookup.ID := 'IDCLIENTE';
  Fornec.Lookup.CampoRetorno := 'NOME';
  Fornec.Lookup.DisplayFields := 'IDCLIENTE,NOME';
  Livre := TEdit.Create(Self);
  Livre.Parent := Pnl;
  Livre.SetBounds(480, 10, 150, 24);
  Livre.Name := 'edtLivre';
  Livre.Text := ''; // TEdit assume o Name como texto inicial

  Escrever('');
  Escrever('O1 Dataset ainda fechado: so o registrado aparece; abrir o dataset atualiza sozinho');
  TCamposObrigatorios.Registrar(Livre, 'Campo livre');
  TCamposObrigatorios.Indicar(Pnl);
  Check('antes de abrir: campo registrado marcado', ContarAsteriscos(Livre) = 1);
  Check('antes de abrir: campos NOT NULL ainda desconhecidos', ContarAsteriscos(Numero) = 0);
  Mem.CreateDataSet;
  Pausa(50);
  Check('apos abrir: NUMERO (NOT NULL) marcado', ContarAsteriscos(Numero) = 1);
  Check('apos abrir: lookup NOT NULL marcado', ContarAsteriscos(Fornec) = 1);
  Check('SERIE (aceita nulo) sem asterisco', ContarAsteriscos(Serie) = 0);
  Check('CODIGO (TabStop falso, preenchido por codigo) sem asterisco', ContarAsteriscos(Codigo) = 0);

  Escrever('');
  Escrever('O2 Indicar e idempotente');
  TCamposObrigatorios.Indicar(Pnl);
  TCamposObrigatorios.Indicar(Pnl);
  Check('um unico asterisco por campo',
    (ContarAsteriscos(Numero) = 1) and (ContarAsteriscos(Fornec) = 1) and
    (ContarAsteriscos(Livre) = 1));

  Escrever('');
  Escrever('O3 Validacao: vazios entram no validador; preenchidos saem');
  Mem.Append;
  Pausa(30);
  Escrever('  (diagnostico) pendencias=' + IntToStr(Erros) + ' numeroVazio=' + BoolToStr(TCamposObrigatorios.EstaVazio(Numero), True) + ' obrNumero=' + BoolToStr(TCamposObrigatorios.EhObrigatorio(Numero), True) + ' fornecVazio=' + BoolToStr(TCamposObrigatorios.EstaVazio(Fornec), True) + ' obrFornec=' + BoolToStr(TCamposObrigatorios.EhObrigatorio(Fornec), True) + ' livreVazio=' + BoolToStr(TCamposObrigatorios.EstaVazio(Livre), True) + ' numeroEnabled=' + BoolToStr(Numero.Enabled, True));
  Check('3 obrigatorios vazios (numero, fornecedor, livre)', Erros = 3);
  Numero.Text := '123';
  Check('numero preenchido: 2 pendencias', Erros = 2);
  Livre.Text := 'x';
  Check('livre preenchido: 1 pendencia', Erros = 1);
  Check('nome do campo vem do rotulo do lookup',
    TCamposObrigatorios.NomeDoCampo(Fornec) = 'Fornecedor');
  Fornec.LoadByID(100);
  Pausa(30);
  Check('lookup preenchido: nenhuma pendencia', Erros = 0);
  Fornec.Clear;
  Check('lookup limpo: volta a pendencia', Erros = 1);

  Escrever('');
  Escrever('O4 Campo desabilitado ou escondido nao e cobrado');
  Livre.Text := '';
  Livre.Enabled := False;
  Check('desabilitado nao entra', Erros = 1);
  Livre.Enabled := True;
  Livre.Parent.Visible := True;
  Numero.Text := '';
  Check('3 de novo', Erros = 3);
  Numero.Visible := False;
  Pausa(30);
  Check('escondido nao entra', Erros = 2);
  Check('asterisco acompanha a visibilidade', ContarAsteriscos(Numero) = 0);
  Numero.Visible := True;
  Pausa(30);
  Check('asterisco volta junto', ContarAsteriscos(Numero) = 1);

  Escrever('');
  Escrever('O5 Dispensar e Registrar');
  TCamposObrigatorios.Dispensar(Numero);
  TCamposObrigatorios.Indicar(Pnl);
  Check('dispensado: sem asterisco e sem cobranca',
    (ContarAsteriscos(Numero) = 0) and (Erros = 2));
  TCamposObrigatorios.Registrar(Serie, 'Serie da nota', 'Informe a serie da nota.');
  TCamposObrigatorios.Indicar(Pnl);
  Check('registrado: asterisco e cobranca', (ContarAsteriscos(Serie) = 1) and (Erros = 3));

  Escrever('');
  Escrever('O6 Asterisco digitado a mao no .dfm nao e duplicado');
  Extra := TEdit.Create(Self);
  Extra.Parent := Pnl;
  Extra.SetBounds(480, 60, 100, 24);
  Extra.Text := '';
  Manual := TLabel.Create(Self);
  Manual.Parent := Pnl;
  Manual.Caption := '*';
  Manual.Font.Color := clRed;
  Manual.SetBounds(Extra.Left + Extra.Width + 4, Extra.Top, 9, 19);
  TCamposObrigatorios.Registrar(Extra, 'Extra');
  TCamposObrigatorios.Indicar(Pnl);
  Check('continua um unico asterisco (o manual)', ContarAsteriscos(Extra) = 1);

  Escrever('');
  Escrever('O7 Integracao com o TValidador: mensagem unica e marca vermelha');
  Mem.Cancel;
  Mem.Append;
  Numero.Text := '';
  TCamposObrigatorios.Registrar(Numero, 'Numero NF');
  Pausa(30);
  begin
    var V := TValidador.Create;
    try
      TCamposObrigatorios.Exigir(V, Pnl);
      Check('mensagens geradas pelo Exigir', V.TotalErros >= 3);
      try
        V.ConcluirOuAbortar('Nao foi possivel salvar');
      except
        on EAbort do ;
      end;
    finally
      V.Free;
    end;
  end;
  Pausa(50);
  Check('campo obrigatorio vazio recebeu a marca vermelha', MarcaVisivel(Numero));
  Mem.Cancel;
  Pausa(50);
  Check('cancelar limpa a marca (fase 1)', not MarcaVisivel(Numero));
end;

end.
