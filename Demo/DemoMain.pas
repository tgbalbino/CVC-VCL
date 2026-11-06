unit DemoMain;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Variants,
  Vcl.Forms, Vcl.Controls, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.DBCtrls,
  Vcl.Dialogs, Vcl.Graphics,
  Data.DB, FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error,
  FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool,
  FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Phys.FB, FireDAC.Phys.FBDef,
  FireDAC.Comp.Client, FireDAC.Comp.DataSet, FireDAC.DApt,
  DBLookupEdit, CVCVisualSettings;

type
  TfrmDBLookupEditDemo = class(TForm)
  private
    FConnection: TFDConnection;
    FMem: TFDMemTable;
    FSource: TDataSource;
    FLkpTipo: TDBLookupEdit;
    FEdId: TDBEdit;
    FEdServidor: TEdit;
    FEdBanco: TEdit;
    FEdUsuario: TEdit;
    FEdSenha: TEdit;
    FMemo: TMemo;
    FBtnConectar: TButton;
    FBtnNovo: TButton;
    FBtnLimpar: TButton;
    FBtnCarregar: TButton;
    FBtnCor: TButton;
    procedure CriarInterface;
    procedure ConfigurarMemoria;
    procedure ConectarClick(Sender: TObject);
    procedure NovoClick(Sender: TObject);
    procedure LimparClick(Sender: TObject);
    procedure CarregarClick(Sender: TObject);
    procedure CorClick(Sender: TObject);
    procedure LookupAfterSelect(Sender: TObject);
    procedure Registrar(const AMensagem: string);
    function SenhaPadrao: string;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  frmDBLookupEditDemo: TfrmDBLookupEditDemo;

implementation

constructor TfrmDBLookupEditDemo.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  Caption := 'Demo - DBLookupEdit';
  Position := poScreenCenter;
  Width := 760;
  Height := 520;
  Constraints.MinWidth := 700;
  Constraints.MinHeight := 460;

  FConnection := TFDConnection.Create(Self);
  FConnection.LoginPrompt := False;
  FMem := TFDMemTable.Create(Self);
  FSource := TDataSource.Create(Self);
  FSource.DataSet := FMem;

  ConfigurarMemoria;
  CriarInterface;
end;

destructor TfrmDBLookupEditDemo.Destroy;
begin
  if FConnection.Connected then
    FConnection.Close;
  inherited;
end;

procedure TfrmDBLookupEditDemo.ConfigurarMemoria;
begin
  FMem.FieldDefs.Add('IDTIPO', ftInteger);
  FMem.CreateDataSet;
  FMem.Append;
  FMem.FieldByName('IDTIPO').Clear;
  FMem.Post;
end;

function TfrmDBLookupEditDemo.SenhaPadrao: string;
begin
  Result := GetEnvironmentVariable('CVC_LOOKUP_DB_PASSWORD');
  if Result = '' then
    Result := 'masterkey';
end;

procedure TfrmDBLookupEditDemo.CriarInterface;
var
  P: TPanel;
  L: TLabel;
begin
  P := TPanel.Create(Self);
  P.Parent := Self;
  P.Align := alTop;
  P.Height := 128;
  P.BevelOuter := bvNone;

  L := TLabel.Create(P); L.Parent := P; L.Left := 12; L.Top := 12; L.Caption := 'Servidor';
  FEdServidor := TEdit.Create(P); FEdServidor.Parent := P; FEdServidor.Left := 90; FEdServidor.Top := 8; FEdServidor.Width := 150; FEdServidor.Text := 'localhost';
  L := TLabel.Create(P); L.Parent := P; L.Left := 255; L.Top := 12; L.Caption := 'Banco';
  FEdBanco := TEdit.Create(P); FEdBanco.Parent := P; FEdBanco.Left := 300; FEdBanco.Top := 8; FEdBanco.Width := 420; FEdBanco.Text := 'C:\ControleVendas\DATA\DATA.FDB';
  L := TLabel.Create(P); L.Parent := P; L.Left := 12; L.Top := 48; L.Caption := 'Usuário';
  FEdUsuario := TEdit.Create(P); FEdUsuario.Parent := P; FEdUsuario.Left := 90; FEdUsuario.Top := 44; FEdUsuario.Width := 150; FEdUsuario.Text := 'sysdba';
  L := TLabel.Create(P); L.Parent := P; L.Left := 255; L.Top := 48; L.Caption := 'Senha';
  FEdSenha := TEdit.Create(P); FEdSenha.Parent := P; FEdSenha.Left := 300; FEdSenha.Top := 44; FEdSenha.Width := 150; FEdSenha.PasswordChar := '*'; FEdSenha.Text := SenhaPadrao;
  FBtnConectar := TButton.Create(P); FBtnConectar.Parent := P; FBtnConectar.Left := 470; FBtnConectar.Top := 42; FBtnConectar.Width := 120; FBtnConectar.Caption := 'Conectar'; FBtnConectar.OnClick := ConectarClick;

  L := TLabel.Create(Self); L.Parent := Self; L.Left := 20; L.Top := 148; L.Caption := 'Tipo de saída (digite texto/código, Enter, Tab ou use a lupa)';
  FLkpTipo := TDBLookupEdit.Create(Self);
  FLkpTipo.Parent := Self;
  FLkpTipo.Left := 20;
  FLkpTipo.Top := 170;
  FLkpTipo.Width := 430;
  FLkpTipo.Connection := FConnection;
  FLkpTipo.DataSource := FSource;
  FLkpTipo.DataField := 'IDTIPO';
  FLkpTipo.LabelCaption := 'Tipo';
  FLkpTipo.Lookup.Tabela := 'TIPO_SAIDA';
  FLkpTipo.Lookup.ID := 'IDTIPO';
  FLkpTipo.Lookup.CampoRetorno := 'TIPO';
  FLkpTipo.Lookup.DisplayFields := 'IDTIPO,TIPO';
  FLkpTipo.Lookup.CaptionCampos := 'Código,Tipo';
  FLkpTipo.Lookup.SearchFilter := 'ATIVO = ''S''';
  FLkpTipo.OnAfterSelect := LookupAfterSelect;

  L := TLabel.Create(Self); L.Parent := Self; L.Left := 470; L.Top := 178; L.Caption := 'ID gravado:';
  FEdId := TDBEdit.Create(Self); FEdId.Parent := Self; FEdId.Left := 545; FEdId.Top := 174; FEdId.Width := 100; FEdId.DataSource := FSource; FEdId.DataField := 'IDTIPO'; FEdId.ReadOnly := True;

  FBtnNovo := TButton.Create(Self); FBtnNovo.Parent := Self; FBtnNovo.Left := 20; FBtnNovo.Top := 235; FBtnNovo.Caption := 'Novo registro'; FBtnNovo.OnClick := NovoClick;
  FBtnLimpar := TButton.Create(Self); FBtnLimpar.Parent := Self; FBtnLimpar.Left := 140; FBtnLimpar.Top := 235; FBtnLimpar.Caption := 'Limpar'; FBtnLimpar.OnClick := LimparClick;
  FBtnCarregar := TButton.Create(Self); FBtnCarregar.Parent := Self; FBtnCarregar.Left := 220; FBtnCarregar.Top := 235; FBtnCarregar.Caption := 'Carregar ID 4'; FBtnCarregar.OnClick := CarregarClick;
  FBtnCor := TButton.Create(Self); FBtnCor.Parent := Self; FBtnCor.Left := 340; FBtnCor.Top := 235; FBtnCor.Caption := 'Cor desabilitado'; FBtnCor.OnClick := CorClick;

  FMemo := TMemo.Create(Self);
  FMemo.Parent := Self;
  FMemo.Align := alBottom;
  FMemo.Height := 190;
  FMemo.ScrollBars := ssVertical;
  FMemo.ReadOnly := True;
  Registrar('Pronto. Conecte ao Firebird e teste texto, código, Enter, Tab e lupa.');
end;

procedure TfrmDBLookupEditDemo.Registrar(const AMensagem: string);
begin
  FMemo.Lines.Add(FormatDateTime('hh:nn:ss', Now) + '  ' + AMensagem);
end;

procedure TfrmDBLookupEditDemo.ConectarClick(Sender: TObject);
begin
  try
    if FConnection.Connected then
      FConnection.Close;
    FConnection.Params.Clear;
    FConnection.Params.Values['DriverID'] := 'FB';
    FConnection.Params.Values['Protocol'] := 'TCPIP';
    FConnection.Params.Values['Server'] := Trim(FEdServidor.Text);
    FConnection.Params.Values['Database'] := Trim(FEdBanco.Text);
    FConnection.Params.Values['User_Name'] := Trim(FEdUsuario.Text);
    FConnection.Params.Values['Password'] := FEdSenha.Text;
    FConnection.Open;
    Registrar('Conexão aberta.');
  except
    on E: Exception do
    begin
      Registrar('Erro de conexão: ' + E.Message);
      MessageDlg(E.Message, mtError, [mbOK], 0);
    end;
  end;
end;

procedure TfrmDBLookupEditDemo.NovoClick(Sender: TObject);
begin
  if not FMem.Active then Exit;
  FMem.Edit;
  FMem.FieldByName('IDTIPO').Clear;
  FMem.Post;
  FLkpTipo.Clear;
  Registrar('Registro limpo para novo teste.');
end;

procedure TfrmDBLookupEditDemo.LimparClick(Sender: TObject);
begin
  FLkpTipo.Clear;
  Registrar('Clear executado.');
end;

procedure TfrmDBLookupEditDemo.CarregarClick(Sender: TObject);
begin
  if not FConnection.Connected then
  begin
    Registrar('Conecte antes de carregar.');
    Exit;
  end;
  try
    FLkpTipo.LoadByID(4);
    Registrar('LoadByID(4) executado.');
  except
    on E: Exception do Registrar('Erro em LoadByID: ' + E.Message);
  end;
end;

procedure TfrmDBLookupEditDemo.CorClick(Sender: TObject);
begin
  SetCVCDisabledColor(clInfoBk);
  Registrar('Cor global de desabilitado alterada.');
end;

procedure TfrmDBLookupEditDemo.LookupAfterSelect(Sender: TObject);
begin
  Registrar('OnAfterSelect: ID=' + VarToStr(FLkpTipo.SelectedID) +
    ', texto="' + FLkpTipo.Description + '"');
end;

end.
