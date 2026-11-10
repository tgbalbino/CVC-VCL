unit TesteMain;

{ Bateria automatica do TDBLookupEdit contra uma base Firebird propria
  (Demo\Teste\criar-base-demo.sql: tabelas PESSOA e PRODUTO).
  Foco: comportamento do Enter, da grade de selecao e do DataLink.
  Executar com /auto para rodar sem interface e devolver o numero de falhas
  como codigo de saida. Resultado tambem em resultado.txt. }

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  System.Variants, System.IOUtils, Vcl.Forms, Vcl.Controls, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.Buttons, Vcl.DBCtrls, Vcl.Dialogs, Vcl.Graphics,
  Data.DB, FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error,
  FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool,
  FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Phys.FB, FireDAC.Phys.FBDef,
  FireDAC.Comp.Client, FireDAC.Comp.DataSet, FireDAC.DApt,
  FireDAC.VCLUI.Wait, FireDAC.Comp.UI,
  DBLookupEdit, uLookupForm, CVCVisualSettings;

type
  TGradeAcao = (gaCancelar, gaOk);

  TfrmTeste = class(TForm)
  private
    FConn: TFDConnection;
    FMem: TFDMemTable;
    FSource: TDataSource;
    FCli, FVen, FProd: TDBLookupEdit;
    FOutro: TEdit;
    FMemo: TMemo;
    FTimer: TTimer;
    FLog: TStringList;
    FFalhas: Integer;
    FTotal: Integer;
    // controle da grade de selecao (TfrmLookup) aberta pelo componente
    FGradeAcao: TGradeAcao;
    FGradeLinha: Integer;
    FGradeIdAlvo: Integer;
    FGradeCount: Integer;
    FGradePrimeiroId: Integer;
    FGradeEscolhidoId: Integer;
    FAbortou: Boolean;
    procedure CriarInterface;
    procedure ConfigurarLookups;
    procedure TimerGrade(Sender: TObject);
    procedure TimerAuto(Sender: TObject);
    procedure VendedorBeforeSelect(Sender: TObject; const Query: TFDQuery);
    procedure Escrever(const S: string);
    procedure Check(const Nome: string; Cond: Boolean; const Detalhe: string = '');
    procedure Info(const S: string);
    procedure Titulo(const S: string);
    function Inner(L: TDBLookupEdit): TEdit;
    function Lupa(L: TDBLookupEdit): TSpeedButton;
    function IdStr(L: TDBLookupEdit): string;
    function CampoMem(const Campo: string): string;
    procedure Preparar;
    procedure Digitar(L: TDBLookupEdit; const S: string);
    procedure IrPara(L: TDBLookupEdit);
    procedure Enter(L: TDBLookupEdit; Acao: TGradeAcao = gaCancelar;
      Linha: Integer = 1; IdAlvo: Integer = 0);
    function Avancou(L: TDBLookupEdit): Boolean;
    procedure Bombear;
    // cenarios
    procedure T01_SelecaoNaGrade;
    procedure T02_EnterSemAlteracao;
    procedure T03_AlterarTextoPesquisa;
    procedure T04_AlterarEReverter;
    procedure T05_CampoVazio;
    procedure T06_TextoUnico;
    procedure T07_BaseAlteradaDepois;
    procedure T08_Codigo;
    procedure T09_TextoInvalido;
    procedure T10_CancelarGrade;
    procedure T11_PesquisaExplicita;
    procedure T12_NavegacaoDataSet;
    procedure T13_NovoRegistro;
    procedure T14_LoadByIDeClear;
    procedure T15_PriorizaReferencia;
    procedure T16_VendedorInativo;
    procedure T17_SaidaDoCampo;
    procedure T18_SegundaTabela;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure ExecutarTudo;
    procedure AgendarAuto;
    property Falhas: Integer read FFalhas;
  end;

implementation

constructor TfrmTeste.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  Caption := 'Teste - DBLookupEdit (Enter)';
  Position := poScreenCenter;
  Width := 760;
  Height := 560;
  FLog := TStringList.Create;
  TFDGUIxWaitCursor.Create(Self);
  FConn := TFDConnection.Create(Self);
  FConn.LoginPrompt := False;
  FMem := TFDMemTable.Create(Self);
  FSource := TDataSource.Create(Self);
  FSource.DataSet := FMem;
  FTimer := TTimer.Create(Self);
  FTimer.Interval := 15;
  FTimer.OnTimer := TimerGrade;
  CriarInterface;
  Visible := True;
end;

destructor TfrmTeste.Destroy;
begin
  FLog.Free;
  inherited;
end;

procedure TfrmTeste.CriarInterface;
begin
  FCli := TDBLookupEdit.Create(Self);
  FCli.Parent := Self;
  FCli.SetBounds(10, 10, 600, 40);
  FCli.TabOrder := 0;
  FVen := TDBLookupEdit.Create(Self);
  FVen.Parent := Self;
  FVen.SetBounds(10, 60, 600, 40);
  FVen.TabOrder := 1;
  FProd := TDBLookupEdit.Create(Self);
  FProd.Parent := Self;
  FProd.SetBounds(10, 110, 600, 40);
  FProd.TabOrder := 2;
  FOutro := TEdit.Create(Self);
  FOutro.Parent := Self;
  FOutro.SetBounds(10, 160, 200, 24);
  FOutro.TabOrder := 3;
  FMemo := TMemo.Create(Self);
  FMemo.Parent := Self;
  FMemo.Align := alBottom;
  FMemo.Height := 330;
  FMemo.ScrollBars := ssBoth;
  FMemo.ReadOnly := True;
end;

procedure TfrmTeste.ConfigurarLookups;
begin
  FMem.FieldDefs.Add('IDCLIENTE', ftInteger);
  FMem.FieldDefs.Add('IDVENDEDOR', ftInteger);
  FMem.FieldDefs.Add('IDPRODUTO', ftInteger);
  FMem.CreateDataSet;

  FCli.Connection := FConn;
  FCli.DataSource := FSource;
  FCli.DataField := 'IDCLIENTE';
  FCli.Lookup.Tabela := 'PESSOA';
  FCli.Lookup.ID := 'IDCLIENTE';
  FCli.Lookup.CampoRetorno := 'NOME';
  FCli.Lookup.CampoPesquisaAlternativo := 'REFERENCIA';
  FCli.Lookup.SearchFilter := 'CLI=''S''';
  FCli.Lookup.OutrosCampos := 'STATUS,OUTROS';
  FCli.Lookup.CaptionCampos := 'Cod.Cliente,Referencia,Nome';
  FCli.Lookup.DisplayFields := 'IDCLIENTE,REFERENCIA,NOME';
  FCli.HiddenFields := 'STATUS,OUTROS';

  FVen.Connection := FConn;
  FVen.DataSource := FSource;
  FVen.DataField := 'IDVENDEDOR';
  FVen.Lookup.Tabela := 'PESSOA';
  FVen.Lookup.ID := 'IDCLIENTE';
  FVen.Lookup.CampoRetorno := 'NOME';
  FVen.Lookup.CampoPesquisaAlternativo := 'REFERENCIA';
  FVen.Lookup.SearchFilter := 'VEN=''S''';
  FVen.Lookup.OutrosCampos := 'ATIVO';
  FVen.Lookup.CaptionCampos := 'Codigo,Referencia,Nome';
  FVen.Lookup.DisplayFields := 'IDCLIENTE,REFERENCIA,NOME';
  FVen.OnBeforeSelectRecord := VendedorBeforeSelect;

  FProd.Connection := FConn;
  FProd.DataSource := FSource;
  FProd.DataField := 'IDPRODUTO';
  FProd.Lookup.Tabela := 'PRODUTO';
  FProd.Lookup.ID := 'IDPRODUTO';
  FProd.Lookup.CampoRetorno := 'NOME';
  FProd.Lookup.SearchFilter := 'ATIVO=''S''';
  FProd.Lookup.CaptionCampos := 'Codigo,Produto';
  FProd.Lookup.DisplayFields := 'IDPRODUTO,NOME';
end;

// Replica o uso real de ED_Vendedor na tela de venda (uLanSaida).
procedure TfrmTeste.VendedorBeforeSelect(Sender: TObject; const Query: TFDQuery);
begin
  if Query.FieldByName('ATIVO').AsString <> 'S' then
  begin
    (Sender as TDBLookupEdit).Clear;
    Abort;
  end;
end;

// Atua sobre a grade de selecao assim que ela abre (dentro do ShowModal).
procedure TfrmTeste.TimerGrade(Sender: TObject);
var
  I: Integer;
  Frm: TfrmLookup;
  DS: TDataSet;
begin
  for I := 0 to Screen.FormCount - 1 do
    if (Screen.Forms[I] is TfrmLookup) and (Screen.Forms[I].Tag = 0) then
    begin
      Frm := TfrmLookup(Screen.Forms[I]);
      Frm.Tag := 1;
      Inc(FGradeCount);
      DS := Frm.DBGrid1.DataSource.DataSet;
      DS.First;
      FGradePrimeiroId := DS.Fields[0].AsInteger;
      if FGradeIdAlvo > 0 then
      begin
        while (not DS.Eof) and (DS.Fields[0].AsInteger <> FGradeIdAlvo) do
          DS.Next;
      end
      else if FGradeLinha > 1 then
        DS.MoveBy(FGradeLinha - 1);
      FGradeEscolhidoId := DS.Fields[0].AsInteger;
      if FGradeAcao = gaOk then
        Frm.btnOk.Click
      else
        Frm.btnCancel.Click;
    end;
end;

procedure TfrmTeste.AgendarAuto;
begin
  with TTimer.Create(Self) do
  begin
    Interval := 500;
    OnTimer := TimerAuto;
  end;
end;

procedure TfrmTeste.TimerAuto(Sender: TObject);
begin
  TTimer(Sender).Enabled := False;
  try
    ExecutarTudo;
  except
    on E: Exception do
    begin
      TFile.AppendAllText(ChangeFileExt(ParamStr(0), '.erro.txt'), E.ClassName + ': ' + E.Message);
      Halt(998);
    end;
  end;
  Halt(FFalhas);
end;

procedure TfrmTeste.Escrever(const S: string);
begin
  FLog.Add(S);
  FMemo.Lines.Add(S);
  try
    with TStreamWriter.Create(ChangeFileExt(ParamStr(0), '.live.txt'), True) do
    try
      WriteLine(S);
    finally
      Free;
    end;
  except
  end;
end;

procedure TfrmTeste.Check(const Nome: string; Cond: Boolean; const Detalhe: string);
begin
  Inc(FTotal);
  if Cond then
    Escrever('  OK    ' + Nome)
  else
  begin
    Inc(FFalhas);
    begin
      if Detalhe <> '' then
        Escrever('  FALHA ' + Nome + ' -> ' + Detalhe)
      else
        Escrever('  FALHA ' + Nome);
    end;
  end;
end;

procedure TfrmTeste.Info(const S: string);
begin
  Escrever('  INFO  ' + S);
end;

procedure TfrmTeste.Titulo(const S: string);
begin
  Escrever('');
  Escrever(S);
end;

function TfrmTeste.Inner(L: TDBLookupEdit): TEdit;
var
  I: Integer;
begin
  for I := 0 to L.ControlCount - 1 do
    if (L.Controls[I] is TEdit) and not TEdit(L.Controls[I]).ReadOnly then
      Exit(TEdit(L.Controls[I]));
  raise Exception.Create('Editor interno nao encontrado');
end;

function TfrmTeste.Lupa(L: TDBLookupEdit): TSpeedButton;
var
  I: Integer;
begin
  for I := 0 to L.ControlCount - 1 do
    if L.Controls[I] is TSpeedButton then
      Exit(TSpeedButton(L.Controls[I]));
  raise Exception.Create('Botao de pesquisa nao encontrado');
end;

function TfrmTeste.IdStr(L: TDBLookupEdit): string;
begin
  Result := VarToStr(L.SelectedID);
end;

function TfrmTeste.CampoMem(const Campo: string): string;
begin
  Result := FMem.FieldByName(Campo).AsString;
end;

procedure TfrmTeste.Bombear;
begin
  Application.ProcessMessages;
  Application.ProcessMessages;
end;

procedure TfrmTeste.Preparar;
begin
  if FMem.State in dsEditModes then
    FMem.Post;
  FMem.EmptyDataSet;
  FMem.Append;
  FCli.Clear;
  FVen.Clear;
  FProd.Clear;
  FMem.Post;
  FMem.Edit;
  FMem.Post;
  FGradeCount := 0;
  FAbortou := False;
  ActiveControl := FOutro;
  Bombear;
end;

procedure TfrmTeste.Digitar(L: TDBLookupEdit; const S: string);
begin
  ActiveControl := Inner(L);
  Inner(L).Text := S;
end;

procedure TfrmTeste.IrPara(L: TDBLookupEdit);
begin
  ActiveControl := Inner(L);
  Bombear;
end;

procedure TfrmTeste.Enter(L: TDBLookupEdit; Acao: TGradeAcao; Linha, IdAlvo: Integer);
begin
  FGradeAcao := Acao;
  FGradeLinha := Linha;
  FGradeIdAlvo := IdAlvo;
  FGradeCount := 0;
  FAbortou := False;
  try
    Inner(L).Perform(WM_KEYDOWN, VK_RETURN, 0);
  except
    on EAbort do FAbortou := True;
  end;
  Bombear;
end;

function TfrmTeste.Avancou(L: TDBLookupEdit): Boolean;
begin
  Result := ActiveControl <> Inner(L);
end;

{ ---------------------------------------------------------------- cenarios }

procedure TfrmTeste.T01_SelecaoNaGrade;
begin
  Titulo('T01 Selecao na grade: o registro escolhido e o gravado');
  Preparar;
  Digitar(FCli, 'CLIENTE 1');
  Enter(FCli, gaOk, 4);
  Check('grade abriu 1 vez', FGradeCount = 1, 'abriu ' + IntToStr(FGradeCount));
  Check('4a linha difere da 1a (premissa do teste)', FGradeEscolhidoId <> FGradePrimeiroId);
  Check('ID selecionado = linha escolhida na grade',
    IdStr(FCli) = IntToStr(FGradeEscolhidoId),
    'escolhido=' + IntToStr(FGradeEscolhidoId) + ' gravado=' + IdStr(FCli));
  Check('campo do dataset = linha escolhida',
    CampoMem('IDCLIENTE') = IntToStr(FGradeEscolhidoId));
  Check('foco avancou', Avancou(FCli));
end;

procedure TfrmTeste.T02_EnterSemAlteracao;
var
  Id: string;
  I: Integer;
begin
  Titulo('T02 Voltar ao campo e dar Enter sem alterar nao pesquisa de novo');
  Preparar;
  Digitar(FCli, 'CLIENTE 1');
  Enter(FCli, gaOk, 3);
  Id := IdStr(FCli);
  for I := 1 to 3 do
  begin
    IrPara(FCli);
    Enter(FCli, gaCancelar);
    Check('Enter #' + IntToStr(I) + ' nao abriu a grade', FGradeCount = 0,
      'abriu ' + IntToStr(FGradeCount));
    Check('Enter #' + IntToStr(I) + ' manteve o ID', IdStr(FCli) = Id);
    Check('Enter #' + IntToStr(I) + ' continua valido', FCli.IsValid);
    Check('Enter #' + IntToStr(I) + ' avancou o foco', Avancou(FCli));
  end;
end;

procedure TfrmTeste.T03_AlterarTextoPesquisa;
begin
  Titulo('T03 Alterar o texto volta a pesquisar');
  Preparar;
  Digitar(FCli, 'CLIENTE 1');
  Enter(FCli, gaOk, 5);
  IrPara(FCli);
  Inner(FCli).Text := 'CLIENTE 2';
  Check('apos editar deixa de ser valido', not FCli.IsValid);
  Enter(FCli, gaOk, 1);
  Check('grade abriu 1 vez', FGradeCount = 1, 'abriu ' + IntToStr(FGradeCount));
  Check('selecionou a linha 1', IdStr(FCli) = IntToStr(FGradeEscolhidoId));
  Check('valido de novo', FCli.IsValid);
end;

procedure TfrmTeste.T04_AlterarEReverter;
begin
  Titulo('T04 Alterar e voltar ao texto original: pesquisa porque o ID foi limpo');
  Preparar;
  Digitar(FCli, 'CLIENTE 12');
  Enter(FCli, gaOk, 1);
  Check('selecionou CLIENTE 12 (unico)', IdStr(FCli) = '12', 'id=' + IdStr(FCli));
  IrPara(FCli);
  Inner(FCli).Text := 'CLIENTE 1';
  Inner(FCli).Text := 'CLIENTE 12';
  Check('ID limpo ao editar', IdStr(FCli) = '');
  Check('invalido ao editar', not FCli.IsValid);
  Enter(FCli, gaCancelar);
  Check('Enter pesquisou e restaurou o ID 12', IdStr(FCli) = '12', 'id=' + IdStr(FCli));
  Check('valido', FCli.IsValid);
end;

procedure TfrmTeste.T05_CampoVazio;
begin
  Titulo('T05 Campo vazio + Enter limpa e avanca sem grade');
  Preparar;
  Digitar(FCli, 'CLIENTE 12');
  Enter(FCli, gaOk);
  IrPara(FCli);
  Inner(FCli).Text := '';
  Enter(FCli);
  Check('sem grade', FGradeCount = 0);
  Check('ID limpo', IdStr(FCli) = '');
  Check('dataset limpo', CampoMem('IDCLIENTE') = '');
  Check('avancou', Avancou(FCli));
  // Enter em campo ja vazio e recem preparado
  IrPara(FCli);
  Enter(FCli);
  Check('Enter em vazio: sem grade e avanca', (FGradeCount = 0) and Avancou(FCli));
end;

procedure TfrmTeste.T06_TextoUnico;
var
  Texto: string;
begin
  Titulo('T06 Texto com resultado unico resolve sem grade e depois nao repesquisa');
  Preparar;
  Digitar(FCli, 'MARIA');
  Enter(FCli);
  Check('sem grade', FGradeCount = 0);
  Check('ID 100', IdStr(FCli) = '100');
  Texto := FCli.Description;
  Check('texto normalizado', Texto = 'MARIA DAS DORES', Texto);
  Check('avancou', Avancou(FCli));
  IrPara(FCli);
  Enter(FCli);
  Check('segundo Enter sem grade', FGradeCount = 0);
  Check('segundo Enter mantem ID e texto',
    (IdStr(FCli) = '100') and (FCli.Description = Texto));
  Check('segundo Enter avanca', Avancou(FCli));
end;

procedure TfrmTeste.T07_BaseAlteradaDepois;
begin
  Titulo('T07 Registro alterado na base apos a selecao (efeito colateral aceito)');
  Preparar;
  Digitar(FCli, 'MARIA');
  Enter(FCli);
  FConn.ExecSQL('UPDATE PESSOA SET NOME = ''MARIA ALTERADA'' WHERE IDCLIENTE = 100');
  try
    IrPara(FCli);
    Enter(FCli);
    Info('Enter sem editar mantem o texto antigo: "' + FCli.Description + '"');
    Check('Enter sem editar nao reconsulta (texto antigo permanece)',
      FCli.Description = 'MARIA DAS DORES');
    Check('continua valido e avanca', FCli.IsValid and Avancou(FCli));
    // mudar o texto sempre consulta a base atual
    IrPara(FCli);
    Inner(FCli).Text := 'MARIA ALT';
    Enter(FCli);
    Check('editar o texto consulta a base atual',
      FCli.Description = 'MARIA ALTERADA', FCli.Description);
  finally
    FConn.ExecSQL('UPDATE PESSOA SET NOME = ''MARIA DAS DORES'' WHERE IDCLIENTE = 100');
  end;
end;

procedure TfrmTeste.T08_Codigo;
begin
  Titulo('T08 Codigo numerico');
  Preparar;
  Digitar(FCli, '7');
  Enter(FCli);
  Check('codigo 7 resolve CLIENTE 7 sem grade',
    (IdStr(FCli) = '7') and (FCli.Description = 'CLIENTE 7') and (FGradeCount = 0),
    IdStr(FCli) + '/' + FCli.Description);
  IrPara(FCli);
  Enter(FCli);
  Check('segundo Enter sem grade e ID mantido', (FGradeCount = 0) and (IdStr(FCli) = '7'));
  IrPara(FCli);
  Inner(FCli).Text := '8';
  Enter(FCli);
  Check('trocar para 8 resolve CLIENTE 8', IdStr(FCli) = '8', IdStr(FCli));
end;

procedure TfrmTeste.T09_TextoInvalido;
begin
  Titulo('T09 Texto inexistente: nao avanca e continua pesquisando');
  Preparar;
  Digitar(FCli, 'ZZZ');
  Enter(FCli);
  Check('sem grade', FGradeCount = 0);
  Check('invalido, ID vazio', (not FCli.IsValid) and (IdStr(FCli) = ''));
  Check('nao avancou', not Avancou(FCli));
  Enter(FCli);
  Check('segundo Enter continua invalido e no campo',
    (not FCli.IsValid) and (not Avancou(FCli)));
  Inner(FCli).Text := 'CLIENTE 3';
  Enter(FCli);
  Check('corrigir o texto resolve', (IdStr(FCli) = '3') and Avancou(FCli), IdStr(FCli));
end;

procedure TfrmTeste.T10_CancelarGrade;
begin
  Titulo('T10 Cancelar a grade nao deixa o campo "validado"');
  Preparar;
  Digitar(FCli, 'CLIENTE 1');
  Enter(FCli, gaCancelar);
  Check('grade abriu', FGradeCount = 1);
  Check('invalido, ID vazio, no campo',
    (not FCli.IsValid) and (IdStr(FCli) = '') and (not Avancou(FCli)));
  Enter(FCli, gaCancelar);
  Check('novo Enter reabre a grade', FGradeCount = 1, 'abriu ' + IntToStr(FGradeCount));
  Enter(FCli, gaOk, 2);
  Check('escolher na grade valida e avanca',
    FCli.IsValid and (IdStr(FCli) = IntToStr(FGradeEscolhidoId)) and Avancou(FCli));
end;

procedure TfrmTeste.T11_PesquisaExplicita;
var
  Id: string;
begin
  Titulo('T11 Pesquisa explicita (duplo clique e lupa) continua abrindo a grade');
  Preparar;
  Digitar(FCli, 'CLIENTE 1');
  Enter(FCli, gaOk, 1);
  Id := IdStr(FCli);
  IrPara(FCli);
  FGradeAcao := gaOk; FGradeLinha := 1; FGradeIdAlvo := 0; FGradeCount := 0;
  Inner(FCli).OnDblClick(Inner(FCli));
  Bombear;
  Check('duplo clique abre a grade mesmo com valor valido', FGradeCount = 1);
  Check('duplo clique seleciona a linha escolhida na grade', IdStr(FCli) = IntToStr(FGradeEscolhidoId));
  FGradeAcao := gaOk; FGradeLinha := 1; FGradeCount := 0;
  Lupa(FCli).Click;
  Bombear;
  Check('lupa abre a grade mesmo com valor valido', FGradeCount = 1);
  // cancelar uma pesquisa explicita deixa o campo marcado como nao validado
  FGradeAcao := gaCancelar; FGradeCount := 0;
  Id := IdStr(FCli);
  Inner(FCli).OnDblClick(Inner(FCli));
  Bombear;
  Info('apos cancelar a pesquisa explicita: IsValid=' + BoolToStr(FCli.IsValid, True) +
    ', ID=' + IdStr(FCli) + ', texto="' + FCli.Description + '"');
  IrPara(FCli);
  Enter(FCli, gaOk, 1);
  Check('Enter depois do cancelamento nao deixa o campo em estado inconsistente',
    FCli.IsValid and (IdStr(FCli) <> ''), IdStr(FCli));
end;

procedure TfrmTeste.T12_NavegacaoDataSet;
begin
  Titulo('T12 Navegacao no dataset (DataLink) + Enter');
  if FMem.State in dsEditModes then FMem.Post;
  FMem.EmptyDataSet;
  FMem.Append; FMem.FieldByName('IDCLIENTE').AsInteger := 3;
  FMem.FieldByName('IDVENDEDOR').AsInteger := 201; FMem.FieldByName('IDPRODUTO').AsInteger := 1; FMem.Post;
  FMem.Append; FMem.FieldByName('IDCLIENTE').AsInteger := 7;
  FMem.FieldByName('IDVENDEDOR').AsInteger := 202; FMem.FieldByName('IDPRODUTO').AsInteger := 2; FMem.Post;
  FMem.First;
  Bombear;
  Check('registro 1 carregou CLIENTE 3', FCli.Description = 'CLIENTE 3', FCli.Description);
  Check('registro 1 carregou VENDEDOR ANA', FVen.Description = 'VENDEDOR ANA', FVen.Description);
  IrPara(FCli);
  Enter(FCli, gaCancelar);
  Check('Enter no registro 1 sem grade e valido',
    (FGradeCount = 0) and FCli.IsValid and (IdStr(FCli) = '3'));
  FMem.Next;
  Bombear;
  Check('registro 2 carregou CLIENTE 7', FCli.Description = 'CLIENTE 7', FCli.Description);
  IrPara(FCli);
  Enter(FCli, gaCancelar);
  Check('Enter no registro 2 sem grade e valido',
    (FGradeCount = 0) and FCli.IsValid and (IdStr(FCli) = '7'));
  Check('dataset segue o lookup', CampoMem('IDCLIENTE') = '7');
  FMem.Prior;
  Bombear;
  IrPara(FCli);
  Enter(FCli, gaCancelar);
  Check('voltar ao registro 1: Enter sem grade, ID 3',
    (FGradeCount = 0) and (IdStr(FCli) = '3'));
  Check('voltar ao registro 1: vendedor e produto intactos',
    (CampoMem('IDVENDEDOR') = '201') and (CampoMem('IDPRODUTO') = '1'));
end;

procedure TfrmTeste.T13_NovoRegistro;
begin
  Titulo('T13 Registro novo (campo nulo) herda texto antigo? Enter nao pode validar sem ID');
  if FMem.State in dsEditModes then FMem.Post;
  FMem.First;
  Bombear;
  FMem.Append;
  Bombear;
  Info('novo registro: IsValid=' + BoolToStr(FCli.IsValid, True) +
    ', ID="' + IdStr(FCli) + '", texto="' + FCli.Description + '"');
  Check('com campo nulo o lookup nao esta valido', not FCli.IsValid);
  IrPara(FCli);
  Enter(FCli, gaOk, 1);
  Check('Enter nunca deixa texto sem ID quando avanca',
    (not Avancou(FCli)) or (IdStr(FCli) <> '') or (Trim(FCli.Description) = ''),
    'texto="' + FCli.Description + '" id=' + IdStr(FCli));
  Check('campo do dataset coerente com o lookup',
    CampoMem('IDCLIENTE') = IdStr(FCli), CampoMem('IDCLIENTE') + ' x ' + IdStr(FCli));
  FMem.Cancel;
end;

procedure TfrmTeste.T14_LoadByIDeClear;
begin
  Titulo('T14 LoadByID e Clear');
  Preparar;
  FCli.LoadByID(5);
  Bombear;
  Check('LoadByID(5) carregou', (IdStr(FCli) = '5') and FCli.IsValid and
    (FCli.Description = 'CLIENTE 5'));
  IrPara(FCli);
  Enter(FCli, gaCancelar);
  Check('Enter apos LoadByID: sem grade', (FGradeCount = 0) and (IdStr(FCli) = '5') and Avancou(FCli));
  FCli.Clear;
  Check('Clear zera tudo', (IdStr(FCli) = '') and (FCli.Description = '') and (not FCli.IsValid));
  IrPara(FCli);
  Enter(FCli, gaCancelar);
  Check('Enter apos Clear: sem grade e avanca', (FGradeCount = 0) and Avancou(FCli));
end;

procedure TfrmTeste.T15_PriorizaReferencia;
var
  Texto: string;
begin
  Titulo('T15 PriorizaCampoAlternativo (exibe "REFERENCIA - NOME")');
  PriorizaCampoAlternativo := True;
  try
    Preparar;
    Digitar(FCli, '1003');
    Enter(FCli, gaCancelar);
    Texto := FCli.Description;
    Check('referencia 1003 resolveu CLIENTE 3', (IdStr(FCli) = '3') and (FGradeCount = 0), IdStr(FCli));
    Check('texto no formato REFERENCIA - NOME', Texto = '1003 - CLIENTE 3', Texto);
    IrPara(FCli);
    Enter(FCli, gaCancelar);
    Check('segundo Enter: sem grade, texto e ID mantidos',
      (FGradeCount = 0) and (FCli.Description = Texto) and (IdStr(FCli) = '3'));
    IrPara(FCli);
    Inner(FCli).Text := 'CLIENTE 3';
    Enter(FCli, gaCancelar);
    Check('editar para texto livre pesquisa e reaplica o formato',
      (IdStr(FCli) = '3') and (FCli.Description = Texto), FCli.Description);
  finally
    PriorizaCampoAlternativo := False;
  end;
end;

procedure TfrmTeste.T16_VendedorInativo;
begin
  Titulo('T16 Vendedor: OnBeforeSelectRecord rejeita inativo (tela de venda)');
  Preparar;
  Digitar(FVen, 'VENDEDOR');
  Enter(FVen, gaOk, 1, 203);
  Check('grade abriu', FGradeCount = 1);
  Check('inativo rejeitado: abortou, limpo, sem ID',
    FAbortou and (IdStr(FVen) = '') and (FVen.Description = '') and (not FVen.IsValid),
    'abortou=' + BoolToStr(FAbortou, True) + ' id=' + IdStr(FVen));
  Check('campo do dataset limpo', CampoMem('IDVENDEDOR') = '');
  Digitar(FVen, 'VENDEDOR');
  Enter(FVen, gaOk, 1, 201);
  Check('ativo aceito', (IdStr(FVen) = '201') and FVen.IsValid);
  IrPara(FVen);
  Enter(FVen, gaOk, 1, 203);
  Check('Enter sem alterar no vendedor valido: sem grade', (FGradeCount = 0) and (IdStr(FVen) = '201'));
end;

procedure TfrmTeste.T17_SaidaDoCampo;
begin
  Titulo('T17 Sair do campo (SearchOnExit)');
  Preparar;
  Digitar(FCli, 'CLIENTE 3');
  Enter(FCli);
  IrPara(FCli);
  FGradeCount := 0;
  ActiveControl := FOutro;
  Bombear;
  Check('sair de campo valido nao pesquisa', FGradeCount = 0);
  Check('continua valido', FCli.IsValid and (IdStr(FCli) = '3'));
  IrPara(FCli);
  Inner(FCli).Text := 'CLIENTE 2';
  FGradeAcao := gaOk; FGradeLinha := 1; FGradeIdAlvo := 0; FGradeCount := 0;
  ActiveControl := FOutro;
  Bombear;
  Info('sair com texto alterado: grade abriu ' + IntToStr(FGradeCount) + ' vez(es), ID=' + IdStr(FCli) +
    ' (depende de o aplicativo estar em primeiro plano)');
  Check('sair com texto alterado nao deixa texto sem ID e sem aviso',
    (FGradeCount = 1) and FCli.IsValid or (not FCli.IsValid) and (IdStr(FCli) = ''));
end;

procedure TfrmTeste.T18_SegundaTabela;
begin
  Titulo('T18 Segunda tabela (PRODUTO)');
  Preparar;
  Digitar(FProd, 'CAMIS');
  Enter(FProd, gaOk, 2);
  Check('2 candidatos: grade abriu e selecionou a 2a linha',
    (FGradeCount = 1) and (IdStr(FProd) = IntToStr(FGradeEscolhidoId)) and
    (IdStr(FProd) <> IntToStr(FGradePrimeiroId)));
  IrPara(FProd);
  Enter(FProd, gaCancelar);
  Check('Enter sem alterar: sem grade', (FGradeCount = 0) and FProd.IsValid);
  IrPara(FProd);
  Inner(FProd).Text := 'CALC';
  Enter(FProd);
  Check('texto novo resolve CALCA', IdStr(FProd) = '3', IdStr(FProd));
  IrPara(FProd);
  Inner(FProd).Text := '4';
  Enter(FProd);
  Check('codigo 4 resolve BONE', FProd.Description = 'BONE', FProd.Description);
end;

procedure TfrmTeste.ExecutarTudo;
var
  Senha: string;
begin
  DeleteFile(ChangeFileExt(ParamStr(0), '.live.txt'));
  Escrever('DBLookupEdit - bateria do Enter  ' + FormatDateTime('dd/mm/yyyy hh:nn:ss', Now));
  Senha := GetEnvironmentVariable('CVC_LOOKUP_DB_PASSWORD');
  if Senha = '' then
    Senha := 'masterkey';
  FConn.Params.Clear;
  FConn.Params.Values['DriverID'] := 'FB';
  FConn.Params.Values['Protocol'] := 'TCPIP';
  FConn.Params.Values['Server'] := 'localhost';
  FConn.Params.Values['Database'] := 'C:\Bancos\DBLOOKUPDEMO\DEMO.FDB';
  FConn.Params.Values['User_Name'] := 'SYSDBA';
  FConn.Params.Values['Password'] := Senha;
  try
    FConn.Open;
  except
    on E: Exception do
    begin
      Escrever('ERRO de conexao: ' + E.Message);
      FFalhas := 999;
      FLog.SaveToFile(ChangeFileExt(ParamStr(0), '.txt'));
      Exit;
    end;
  end;
  ConfigurarLookups;

  try
    T01_SelecaoNaGrade;
    T02_EnterSemAlteracao;
    T03_AlterarTextoPesquisa;
    T04_AlterarEReverter;
    T05_CampoVazio;
    T06_TextoUnico;
    T07_BaseAlteradaDepois;
    T08_Codigo;
    T09_TextoInvalido;
    T10_CancelarGrade;
    T11_PesquisaExplicita;
    T12_NavegacaoDataSet;
    T13_NovoRegistro;
    T14_LoadByIDeClear;
    T15_PriorizaReferencia;
    T16_VendedorInativo;
    T17_SaidaDoCampo;
    T18_SegundaTabela;
  except
    on E: Exception do
    begin
      Inc(FFalhas);
      Escrever('EXCECAO nao tratada: ' + E.ClassName + ': ' + E.Message);
    end;
  end;

  Escrever('');
  Escrever(Format('Resultado: %d verificacoes, %d falha(s)', [FTotal, FFalhas]));
  FLog.SaveToFile(ChangeFileExt(ParamStr(0), '.txt'));
end;

end.
