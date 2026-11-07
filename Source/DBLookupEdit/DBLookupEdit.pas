unit DBLookupEdit;

interface

uses
  System.SysUtils, System.Classes, System.Variants, Winapi.Windows,
  Winapi.Messages, Vcl.Controls, Vcl.StdCtrls, Vcl.Buttons, Vcl.Graphics,
  Vcl.Forms, Data.DB, Vcl.DBCtrls, FireDAC.Comp.Client, CVCVisualSettings;

type
  TLabelPosition = (lpTop, lpLeft);

  TBeforeSelectRecordEvent = procedure(Sender: TObject; const Query: TFDQuery) of object;
  TDBLookupEditSearchButtonClick = procedure(Sender: TObject) of object;
  TDBLookupEditErrorEvent = procedure(Sender: TObject; const E: Exception) of object;

  TDBLookupSettings = class(TPersistent)
  private
    FTabela: string;
    FCampoRetorno: string;
    FID: string;
    FOutrosCampos: string;
    FCaptionCampos: string;
    FDisplayFields: string;
    FSearchFilter: string;
    FCampoPesquisaAlternativo: string;
  published
    property Tabela: string read FTabela write FTabela;
    property CampoRetorno: string read FCampoRetorno write FCampoRetorno;
    property ID: string read FID write FID;
    property OutrosCampos: string read FOutrosCampos write FOutrosCampos;
    property CaptionCampos: string read FCaptionCampos write FCaptionCampos;
    property DisplayFields: string read FDisplayFields write FDisplayFields;
    property SearchFilter: string read FSearchFilter write FSearchFilter;
    property CampoPesquisaAlternativo: string read FCampoPesquisaAlternativo write FCampoPesquisaAlternativo;
  end;

  TDBLookupEdit = class(TCustomControl, ICVCDisabledColorAware)
  private
    FDisabledColor: TColor;
    FDisabledColorOverridden: Boolean;
    procedure SetDisabledColor(const Value: TColor);
    procedure CVCDisabledColorChanged;
  private
    FUpdatingFromDataLink: Boolean;
    FSearching: Boolean;
    FHandlingExit: Boolean;
    FSearchOnExit: Boolean;
    FLookupOpened: Boolean;
    { Visual }
    FLabel: TLabel;
    FLabelFont: TFont;
    FLabelCaption: string;
    FLabelPosition: TLabelPosition;
    FLabelMargin: Integer;

    FIDEdit: TEdit;
    FDescEdit: TEdit;
    FSearchButton: TSpeedButton;

    { Data }
    FConnection: TFDConnection;
    FQuery: TFDQuery;
    FLoadQuery: TFDQuery;
    FLookup: TDBLookupSettings;
    FDataSource: TDataSource;
    FDataLink: TFieldDataLink;
    FDataField: string;

    { State }
    FIsValid: Boolean;
    FSelectedIDValue: Variant;
    FLastDescText: string;
    FHiddenFields: string;
    FShowSearchButton: Boolean;
    FIDWidth: Integer;
    FAdvanceFocusOnEnter: Boolean;

    { Events }
    FOnBeforeSelectRecord: TBeforeSelectRecordEvent;
    FOnSearchButtonClick: TDBLookupEditSearchButtonClick;
    FOnAfterSelect: TNotifyEvent;
    FOnLookupError: TDBLookupEditErrorEvent;

    FOldDescWndProc: TWndMethod;
    procedure DescEditWndProc(var Msg: TMessage);

    { Internal helpers }
    procedure ResizeControls;
    function BuildBaseSelect(const AFields, AWhere: string): string;
    procedure PrepareQuery(AQuery: TFDQuery; const ASql: string);
    procedure PrepareQueryByText(AQuery: TFDQuery);
    procedure PrepareQueryByID(AQuery: TFDQuery; const AValue: Variant);
    procedure PrepareSearchByField(AQuery: TFDQuery; const AField, AParamName: string; const AValue: Variant);
    procedure PrepareSearchByID(AQuery: TFDQuery; const AValue: Variant);
    function LookupFields: string;
    procedure FillFromQuery(AQuery: TFDQuery);
    procedure InternalLoadByID(const AID: Variant);
    procedure DoSearch;

    { Setters }
    procedure SetLookup(const Value: TDBLookupSettings);
    procedure SetConnection(const Value: TFDConnection);
    procedure SetDataSource(const Value: TDataSource);
    procedure SetDataField(const Value: string);
    procedure SetLabelCaption(const Value: string);
    procedure SetLabelPosition(const Value: TLabelPosition);
    procedure SetLabelMargin(const Value: Integer);
    procedure SetLabelFont(const Value: TFont);
    procedure SetShowSearchButton(const Value: Boolean);
    procedure SetIDWidth(const Value: Integer);
    procedure SetSelectedID(const Value: Variant);

    { Getters }
    function GetSelectedID: Variant;

    { DataLink }
    procedure DataChange(Sender: TObject);
    procedure UpdateData(Sender: TObject);

    { Events }
    procedure EventDoSearch(Sender: TObject);
    procedure EventDoSearchButton(Sender: TObject);
    procedure OnLabelFontChanged(Sender: TObject);

    { Messages }
    procedure CMExit(var Message: TCMExit); message CM_EXIT;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
    procedure CMEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
    function GetHasValue: Boolean;
    function GetDescription: string;
    procedure DescEditChange(Sender: TObject);
    procedure DescEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure AdvanceFocusAfterEnter;
    procedure ClearSelectedID;
    function BuildSearchWhere(const AWhere: string): string;
    procedure UpdateEnabledAppearance;
    procedure ValidateLookupConfiguration;
    procedure ValidateIdentifierList(const AValue, AName: string; AAllowEmpty: Boolean);
  protected
    procedure SetEnabled(Value: Boolean); override;
    procedure Resize; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure Loaded; override;

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Clear;
    procedure LoadByID(const AID: Variant);

    property IsValid: Boolean read FIsValid;
    property Description: string read GetDescription;

  published
    property Connection: TFDConnection read FConnection write SetConnection;
    property Lookup: TDBLookupSettings read FLookup write SetLookup;

    property DataSource: TDataSource read FDataSource write SetDataSource;
    property DataField: string read FDataField write SetDataField;

    property SelectedID: Variant read GetSelectedID write SetSelectedID;

    property LabelCaption: string read FLabelCaption write SetLabelCaption;
    property LabelPosition: TLabelPosition read FLabelPosition write SetLabelPosition default lpTop;
    property LabelMargin: Integer read FLabelMargin write SetLabelMargin default 4;
    property LabelFont: TFont read FLabelFont write SetLabelFont;

    property IDWidth: Integer read FIDWidth write SetIDWidth default 50;
    property ShowSearchButton: Boolean read FShowSearchButton write SetShowSearchButton default True;
    property HiddenFields: string read FHiddenFields write FHiddenFields;
    property DisabledColor: TColor read FDisabledColor write SetDisabledColor default clSilver;
    property AdvanceFocusOnEnter: Boolean read FAdvanceFocusOnEnter
      write FAdvanceFocusOnEnter default True;
    property SearchOnExit: Boolean read FSearchOnExit write FSearchOnExit default True;

    property OnBeforeSelectRecord: TBeforeSelectRecordEvent read FOnBeforeSelectRecord write FOnBeforeSelectRecord;
    property OnSearchButtonClick: TDBLookupEditSearchButtonClick read FOnSearchButtonClick write FOnSearchButtonClick;
    property OnAfterSelect: TNotifyEvent read FOnAfterSelect write FOnAfterSelect;
    property OnLookupError: TDBLookupEditErrorEvent read FOnLookupError write FOnLookupError;

    property Align;
    property Anchors;
    property Enabled;
    property Font;
    property ParentFont;
    property TabOrder;
    property TabStop;
    property Visible;
    property HasValue: Boolean read GetHasValue;
    property IsValidLookup: Boolean read FIsValid;
  end;

var
  PriorizaCampoAlternativo: Boolean;

implementation

uses
  uLookupForm;

{ TDBLookupEdit }

constructor TDBLookupEdit.Create(AOwner: TComponent);
begin
  inherited;

  FDisabledColor := GetCVCDisabledColor;
  RegisterCVCDisabledColorControl(Self);

  ControlStyle := ControlStyle + [csParentBackground];
  ParentColor := True;

  Width := 300;
  Height := 48;

  FIsValid := False;
  FSelectedIDValue := Null;
  FShowSearchButton := True;
  FIDWidth := 50;
  FAdvanceFocusOnEnter := True;
  FSearchOnExit := True;
  FLabelMargin := 4;
  FLabelPosition := lpTop;

  FLookup := TDBLookupSettings.Create;

  FQuery := TFDQuery.Create(Self);
  FLoadQuery := TFDQuery.Create(Self);

  FDataLink := TFieldDataLink.Create;
  FDataLink.Control := Self;
  FDataLink.OnDataChange := DataChange;
 // FDataLink.OnUpdateData := UpdateData;

  FLabel := TLabel.Create(Self);
  FLabel.Parent := Self;
  FLabel.Transparent := True;

  FLabelFont := TFont.Create;
  FLabelFont.Assign(FLabel.Font);
  FLabelFont.OnChange := OnLabelFontChanged;

  FIDEdit := TEdit.Create(Self);
  FIDEdit.Parent := Self;
  FIDEdit.AutoSize := False;      // permite fixar a altura manualmente
  FIDEdit.ReadOnly := True;       // o código é preenchido pela seleção
  FIDEdit.Enabled := True;        // o código permanece visualmente habilitado
  FIDEdit.TabStop := False;       // não entra no TAB
  FIDEdit.ParentColor := False;
  FIDEdit.StyleElements := [];
  FIDEdit.Color := FDisabledColor; // codigo fica sempre bloqueado
  FIDEdit.Ctl3D := False;
  FIDEdit.ParentCtl3D := False;
  FIDEdit.Cursor := crArrow;      // não parece editável

  FDescEdit := TEdit.Create(Self);
  FDescEdit.Parent := Self;
  FDescEdit.AutoSize := False;    // permite fixar a altura manualmente
  FDescEdit.ParentColor := False;
  FDescEdit.StyleElements := [];
  FDescEdit.Ctl3D := False;
  FDescEdit.ParentCtl3D := False;
  FDescEdit.OnDblClick := EventDoSearch;
  FDescEdit.OnChange := DescEditChange;
  FDescEdit.OnKeyDown := DescEditKeyDown;
  FOldDescWndProc := FDescEdit.WindowProc;
  FDescEdit.WindowProc := DescEditWndProc;

  FSearchButton := TSpeedButton.Create(Self);
  FSearchButton.Parent := Self;
  FSearchButton.StyleElements := [];
  FSearchButton.Caption := '...';
  FSearchButton.OnClick := EventDoSearchButton;
  FSearchButton.Flat := True;

  UpdateEnabledAppearance;
end;

procedure TDBLookupEdit.DescEditChange(Sender: TObject);
begin
  // Ignora alterações feitas pelo próprio componente
  if FUpdatingFromDataLink then
    Exit;

  if FDescEdit.Text <> FLastDescText then
     ClearSelectedID;
end;

procedure TDBLookupEdit.AdvanceFocusAfterEnter;
var
  Form: TCustomForm;
begin
  if not FAdvanceFocusOnEnter or
     ((not FIsValid) and (Trim(FDescEdit.Text) <> '')) then
    Exit;

  Form := GetParentForm(Self);
  if Assigned(Form) then
    PostMessage(Form.Handle, WM_NEXTDLGCTL, 0, 0);
end;

procedure TDBLookupEdit.DescEditKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key = VK_RETURN) then
  begin
    Key := 0;
    DoSearch;
    { Campo vazio não exige pesquisa, mas o Enter continua tendo o mesmo
      significado de Tab. Texto inválido permanece no campo para correção. }
    if FIsValid or (Trim(FDescEdit.Text) = '') then
      AdvanceFocusAfterEnter;
  end;
end;

procedure TDBLookupEdit.DescEditWndProc(var Msg: TMessage);
begin
  { O procedimento original pode movimentar o foco e gerar outro CM_EXIT.
    A guarda precisa cobrir também essa chamada; ativá-la somente depois
    deixava uma janela para reentrada recursiva. }
  if (Msg.Msg = CM_EXIT) and not FHandlingExit then
  begin
    FHandlingExit := True;
    try
      FOldDescWndProc(Msg);
      if not (csDestroying in ComponentState) and
         not FLookupOpened and
         FSearchOnExit and
         (Trim(FDescEdit.Text) <> '') and
         (not FIsValid) then
        DoSearch;
    finally
      FHandlingExit := False;
    end;
  end
  else
  begin
    FOldDescWndProc(Msg);
  end;
end;

destructor TDBLookupEdit.Destroy;
begin
  UnregisterCVCDisabledColorControl(Self);
  FLabelFont.Free;
  FLookup.Free;
  FDataLink.Free;
  inherited;
end;

procedure TDBLookupEdit.SetDisabledColor(const Value: TColor);
begin
  FDisabledColor := Value;
  FDisabledColorOverridden := True;
  UpdateEnabledAppearance;
end;

procedure TDBLookupEdit.CVCDisabledColorChanged;
begin
  if not FDisabledColorOverridden then
  begin
    FDisabledColor := GetCVCDisabledColor;
    UpdateEnabledAppearance;
  end;
end;

procedure TDBLookupEdit.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited;
  if Operation <> opRemove then
    Exit;
  if AComponent = FDataSource then
    DataSource := nil
  else if AComponent = FConnection then
    FConnection := nil;
end;

procedure TDBLookupEdit.SetLookup(const Value: TDBLookupSettings);
begin
  FLookup.Assign(Value);
end;

procedure TDBLookupEdit.SetConnection(const Value: TFDConnection);
begin
  if FConnection = Value then
    Exit;
  if Assigned(FConnection) then
    FConnection.RemoveFreeNotification(Self);
  FConnection := Value;
  if Assigned(FConnection) then
    FConnection.FreeNotification(Self);
end;

procedure TDBLookupEdit.SetDataSource(const Value: TDataSource);
begin
  if FDataSource = Value then
    Exit;
  if Assigned(FDataSource) then
    FDataSource.RemoveFreeNotification(Self);
  FDataSource := Value;
  FDataLink.DataSource := Value;
  if Assigned(FDataSource) then
    FDataSource.FreeNotification(Self);
end;

procedure TDBLookupEdit.SetDataField(const Value: string);
begin
  FDataField := Value;
  FDataLink.FieldName := Value;
end;

procedure TDBLookupEdit.SetLabelCaption(const Value: string);
begin
  FLabelCaption := Value;
  FLabel.Caption := Value;
  ResizeControls;
end;

procedure TDBLookupEdit.SetLabelPosition(const Value: TLabelPosition);
begin
  FLabelPosition := Value;
  ResizeControls;
end;

procedure TDBLookupEdit.SetLabelMargin(const Value: Integer);
begin
  FLabelMargin := Value;
  ResizeControls;
end;

procedure TDBLookupEdit.SetLabelFont(const Value: TFont);
begin
  FLabelFont.Assign(Value);
end;

procedure TDBLookupEdit.OnLabelFontChanged(Sender: TObject);
begin
  FLabel.Font.Assign(FLabelFont);
  ResizeControls;
end;

procedure TDBLookupEdit.SetShowSearchButton(const Value: Boolean);
begin
  FShowSearchButton := Value;
  FSearchButton.Visible := Value;
  ResizeControls;
end;

procedure TDBLookupEdit.SetIDWidth(const Value: Integer);
begin
  FIDWidth := Value;
  ResizeControls;
end;

function TDBLookupEdit.BuildSearchWhere(const AWhere: string): string;
begin
  Result := AWhere;

  if Trim(FLookup.SearchFilter) <> '' then
    Result := Result + ' AND (' + FLookup.SearchFilter + ')';
end;

procedure TDBLookupEdit.ValidateIdentifierList(const AValue, AName: string;
  AAllowEmpty: Boolean);
var
  Lista: TStringList;
  I, J: Integer;
  Item: string;
begin
  if AAllowEmpty and (Trim(AValue) = '') then
    Exit;
  Lista := TStringList.Create;
  try
    Lista.StrictDelimiter := True;
    Lista.Delimiter := ',';
    Lista.DelimitedText := AValue;
    if Lista.Count = 0 then
      raise EInvalidOp.Create('DBLookupEdit: ' + AName + ' não configurado.');
    for I := 0 to Lista.Count - 1 do
    begin
      Item := Trim(Lista[I]);
      if Item = '' then
        raise EInvalidOp.Create('DBLookupEdit: ' + AName + ' contém campo vazio.');
      for J := 1 to Length(Item) do
        if not CharInSet(Item[J], ['A'..'Z', 'a'..'z', '0'..'9', '_', '$']) then
          raise EInvalidOp.CreateFmt('DBLookupEdit: identificador inválido em %s: %s',
            [AName, Item]);
    end;
  finally
    Lista.Free;
  end;
end;

procedure TDBLookupEdit.ValidateLookupConfiguration;
begin
  if not Assigned(FConnection) then
    raise EInvalidOp.Create('DBLookupEdit: Connection não configurada.');
  if Trim(FLookup.Tabela) = '' then
    raise EInvalidOp.Create('DBLookupEdit: Lookup.Tabela não configurada.');
  if Trim(FLookup.ID) = '' then
    raise EInvalidOp.Create('DBLookupEdit: Lookup.ID não configurado.');
  if Trim(FLookup.CampoRetorno) = '' then
    raise EInvalidOp.Create('DBLookupEdit: Lookup.CampoRetorno não configurado.');
  ValidateIdentifierList(FLookup.Tabela, 'Lookup.Tabela', False);
  ValidateIdentifierList(FLookup.ID, 'Lookup.ID', False);
  ValidateIdentifierList(FLookup.CampoRetorno, 'Lookup.CampoRetorno', False);
  ValidateIdentifierList(FLookup.CampoPesquisaAlternativo,
    'Lookup.CampoPesquisaAlternativo', True);
  ValidateIdentifierList(FLookup.OutrosCampos, 'Lookup.OutrosCampos', True);
  ValidateIdentifierList(FLookup.DisplayFields, 'Lookup.DisplayFields', True);
end;

procedure TDBLookupEdit.Clear;
begin
  if Assigned(FDataLink.Field) and FDataLink.Edit then
    FDataLink.Field.Clear;

  FIDEdit.Clear;
  FDescEdit.Clear;
  FLastDescText := '';
  FIsValid := False;
  FSelectedIDValue := Null;
end;

procedure TDBLookupEdit.LoadByID(const AID: Variant);
begin
  if VarIsNull(AID) or VarIsEmpty(AID) or (VarToStr(AID) = '') then
    Exit;

  // Sem DataSet vinculado (uso "standalone", ex.: filtros de relatório):
  // apenas atualiza os controles visuais / SelectedID.
  if not Assigned(FDataLink.Field) then
  begin
    InternalLoadByID(AID);
    Exit;
  end;

  if not FDataLink.Edit then Exit;

  FUpdatingFromDataLink := True;
  try
    // Atualiza o campo do dataset
    FDataLink.Field.Value := AID;

    // Atualiza o visual
    InternalLoadByID(AID);
  finally
    FUpdatingFromDataLink := False;
  end;
end;

procedure TDBLookupEdit.SetSelectedID(const Value: Variant);
begin
  if VarIsNull(Value) or VarIsEmpty(Value) then
  begin
    Clear;
    Exit;
  end;

  if Assigned(FDataLink.Field) and FDataLink.DataSource.DataSet.Active then
  begin
    if not VarSameValue(GetSelectedID, Value) then
    begin
      // Atualizar o campo dispara DataChange. Marcar a origem da alteração
      // evita que o próprio lookup reentre durante o BeforePost.
      FUpdatingFromDataLink := True;
      try
        if FDataLink.Edit then
          FDataLink.Field.Value := Value;
      finally
        FUpdatingFromDataLink := False;
      end;
    end;
  end;

  // Durante DoSearch a linha já está aberta em FQuery. Reconsultar a mesma
  // chave aqui faz o DataLink disparar DataChange enquanto a busca ainda está
  // no ciclo de edição e pode causar reentrada/stack overflow.
  if not (FQuery.Active and
    SameText(VarToStr(FQuery.FieldByName(FLookup.ID).Value), VarToStr(Value))) then
    InternalLoadByID(Value)
  else
    FillFromQuery(FQuery);
end;

function TDBLookupEdit.GetHasValue: Boolean;
begin
  Result := Trim(FDescEdit.Text) <> '';
end;

function TDBLookupEdit.GetDescription: string;
begin
  Result := FDescEdit.Text;
end;

function TDBLookupEdit.GetSelectedID: Variant;
begin
  if FIDEdit.Text = '' then
    Result := Null
  else if not VarIsNull(FSelectedIDValue) and not VarIsEmpty(FSelectedIDValue) then
    Result := FSelectedIDValue
  else
    Result := FIDEdit.Text;
end;

procedure TDBLookupEdit.InternalLoadByID(const AID: Variant);
begin
  ValidateLookupConfiguration;
  if not Assigned(FConnection) then
    raise Exception.Create('Conexão não definida.');

  PrepareQueryByID(FLoadQuery, AID);
  try
    if FLoadQuery.IsEmpty then
    begin
      Clear;
      Exit;
    end;

    // ATUALIZA SOMENTE OS CONTROLES VISUAIS
    FillFromQuery(FLoadQuery);
  finally
    FLoadQuery.Close;
  end;
end;

function TDBLookupEdit.BuildBaseSelect(const AFields, AWhere: string): string;
begin
  Result := Format('SELECT %s FROM %s WHERE %s', [AFields, FLookup.Tabela, AWhere]);
end;

procedure TDBLookupEdit.PrepareQuery(AQuery: TFDQuery; const ASql: string);
begin
  AQuery.Close;
  AQuery.Connection := FConnection;

  // Só reatribui o SQL se mudou, evitando que o FireDAC precise
  // reanalisar/repreparar o comando a cada busca com o mesmo Lookup.
  if AQuery.SQL.Text <> ASql then
    AQuery.SQL.Text := ASql;
end;

procedure TDBLookupEdit.PrepareQueryByID(AQuery: TFDQuery; const AValue: Variant);
begin
  PrepareSearchByField(AQuery, FLookup.ID, 'ID', AValue);
end;

procedure TDBLookupEdit.PrepareSearchByField(AQuery: TFDQuery; const AField, AParamName: string;
  const AValue: Variant);
begin
  PrepareQuery(AQuery, BuildBaseSelect(LookupFields,
    BuildSearchWhere(AField + ' = :' + AParamName)));

  AQuery.ParamByName(AParamName).Value := AValue;
  AQuery.Open;
end;

function TDBLookupEdit.LookupFields: string;
var
  Campos: TStringList;

  procedure AdicionarCampos(const ALista: string);
  var
    I: Integer;
    Campo: string;
    Lista: TStringList;
  begin
    Lista := TStringList.Create;
    try
      Lista.StrictDelimiter := True;
      Lista.Delimiter := ',';
      Lista.DelimitedText := ALista;
      for I := 0 to Lista.Count - 1 do
      begin
        Campo := Trim(Lista[I]);
        if (Campo <> '') and (Campos.IndexOf(Campo) < 0) then
          Campos.Add(Campo);
      end;
    finally
      Lista.Free;
    end;
  end;

begin
  Campos := TStringList.Create;
  try
    Campos.StrictDelimiter := True;
    Campos.Delimiter := ',';
    Campos.CaseSensitive := False;
    Campos.Sorted := False;

    { Estes campos continuam disponíveis para a seleção e para a gravação,
      mesmo quando não fazem parte da apresentação do Grid. }
    AdicionarCampos(FLookup.ID);
    AdicionarCampos(FLookup.CampoRetorno);
    AdicionarCampos(FLookup.CampoPesquisaAlternativo);
    AdicionarCampos(FLookup.OutrosCampos);
    AdicionarCampos(FLookup.DisplayFields);
    Result := StringReplace(Campos.CommaText, ',', ', ', [rfReplaceAll]);
  finally
    Campos.Free;
  end;
end;

procedure TDBLookupEdit.FillFromQuery(AQuery: TFDQuery);
var
  Nome: string;
  Referencia: string;
begin
  FUpdatingFromDataLink := True;
  try
    FIDEdit.Text := AQuery.FieldByName(FLookup.ID).AsString;
    Nome := AQuery.FieldByName(FLookup.CampoRetorno).AsString;
    FDescEdit.Text := Nome;

    { Nos lookups de cliente, quando a preferência pela referência estiver
      ativa, o valor selecionado também deve ficar visível no padrão
      "REFERENCIA - NOME". O ID continua sendo gravado normalmente. }
    if PriorizaCampoAlternativo and
       SameText(FLookup.Tabela, 'PESSOA') and
       SameText(FLookup.CampoRetorno, 'NOME') and
       SameText(FLookup.CampoPesquisaAlternativo, 'REFERENCIA') and
       (Pos('CLI', UpperCase(FLookup.SearchFilter)) > 0) and
       Assigned(AQuery.FindField('REFERENCIA')) then
    begin
      Referencia := Trim(AQuery.FieldByName('REFERENCIA').AsString);
      if Referencia <> '' then
        FDescEdit.Text := Referencia + ' - ' + Nome;
    end;

    FLastDescText := FDescEdit.Text;
    FSelectedIDValue := AQuery.FieldByName(FLookup.ID).Value;
    FIsValid := True;

  finally
    FUpdatingFromDataLink := False;
  end;

  if Assigned(FOnAfterSelect) then
    FOnAfterSelect(Self);
end;

procedure TDBLookupEdit.DataChange(Sender: TObject);
var
  V: Variant;
begin
  if FUpdatingFromDataLink then Exit;
  if not Assigned(FDataLink.Field) then Exit;

  V := FDataLink.Field.Value;

  FUpdatingFromDataLink := True;
  try
    if VarIsNull(V) or VarIsEmpty(V) then
    begin
      FIDEdit.Clear;
      FIsValid := False;
      FSelectedIDValue := Null;
      //Clear
    end
    else
      InternalLoadByID(V);
  finally
    FUpdatingFromDataLink := False;
  end;
end;

procedure TDBLookupEdit.UpdateData(Sender: TObject);
begin
  if Assigned(FDataLink.Field) then
    FDataLink.Field.Value := GetSelectedID;
end;

procedure TDBLookupEdit.DoSearch;
var
  IDCandidate: Integer;
  SelectedID: Variant;
begin
   if FSearching then
    Exit;

  ValidateLookupConfiguration;

  FSearching := True;
  try
    try
    if Trim(FDescEdit.Text) = '' then
    begin
      Clear;
      Exit;
    end;

    FIsValid := False;

    if TryStrToInt(Trim(FDescEdit.Text), IDCandidate) then
    begin
      if PriorizaCampoAlternativo and
        (Trim(FLookup.CampoPesquisaAlternativo) <> '') then
      begin
        PrepareSearchByField(FQuery, FLookup.CampoPesquisaAlternativo, 'ALT', IDCandidate);

        if not FQuery.IsEmpty then
        begin
          SelectedID := FQuery.FieldByName(FLookup.ID).Value;
          FQuery.Close;
          SetSelectedID(SelectedID);
          FIsValid := True;
          Exit;
        end;
      end;

      PrepareSearchByID(FQuery, IDCandidate);

      if not FQuery.IsEmpty then
      begin
        SelectedID := FQuery.FieldByName(FLookup.ID).Value;
        FQuery.Close;
        SetSelectedID(SelectedID);
        FIsValid := True;
        Exit;
      end;

      if (not PriorizaCampoAlternativo) and
        (Trim(FLookup.CampoPesquisaAlternativo) <> '') then
      begin
        PrepareSearchByField(FQuery, FLookup.CampoPesquisaAlternativo, 'ALT', IDCandidate);

        if not FQuery.IsEmpty then
        begin
          SelectedID := FQuery.FieldByName(FLookup.ID).Value;
          FQuery.Close;
          SetSelectedID(SelectedID);
          FIsValid := True;
          Exit;
        end;
      end;
    end;

    PrepareQueryByText(FQuery);

    if FQuery.IsEmpty then
    begin
      ClearSelectedID;
      Exit;
    end;

    // FetchAll torna a leitura determinística; RecordCount pode variar com o
    // modo de fetch do FireDAC e não deve decidir se a grade será aberta.
    FQuery.FetchAll;
    FQuery.First;
    FQuery.Next;
    if not FQuery.Eof then
    begin
      FQuery.First;
      FLookupOpened := True;
      try
        if not TfrmLookup.Execute(FQuery, FLookup.CaptionCampos, HiddenFields,
          FLookup.DisplayFields) then
          Exit;
      finally
        FLookupOpened := false;
      end;

      if Assigned(FOnBeforeSelectRecord) then
        FOnBeforeSelectRecord(Self, FQuery);
    end;
    FQuery.First;

    SelectedID := FQuery.FieldByName(FLookup.ID).Value;
    FQuery.Close;
    SetSelectedID(SelectedID);
    FIsValid := True;
  except
    on E: Exception do
    begin
      FIsValid := False;
      if Assigned(FOnLookupError) then
        FOnLookupError(Self, E)
      else
        raise;
    end;
    end;
  finally
    FSearching := False;
    // Cada lookup usa a conexão compartilhada do aplicativo. Manter a
    // consulta interna aberta depois da resolução impede outro lookup de
    // consultar a mesma conexão e deixa a interface aparentemente travada.
    if FQuery.Active then
      FQuery.Close;
  end;
end;

procedure TDBLookupEdit.PrepareQueryByText(AQuery: TFDQuery);
begin
  // A base de dados pode armazenar descrições em maiúsculas, enquanto o
  // usuário normalmente pesquisa usando qualquer combinação de caixa.
  // Normalizar os dois lados evita que a busca dependa da capitalização.
  if Trim(FLookup.CampoPesquisaAlternativo) <> '' then
    PrepareQuery(AQuery, BuildBaseSelect(LookupFields,
      BuildSearchWhere('(UPPER(' + FLookup.CampoRetorno + ') LIKE UPPER(:P)' +
        ' OR CAST(' + FLookup.CampoPesquisaAlternativo + ' AS VARCHAR(30)) LIKE :P)')))
  else
    PrepareQuery(AQuery, BuildBaseSelect(LookupFields,
      BuildSearchWhere('UPPER(' + FLookup.CampoRetorno + ') LIKE UPPER(:P)')));

  AQuery.ParamByName('P').DataType := ftString;
  AQuery.ParamByName('P').Size := 255;
  AQuery.ParamByName('P').AsString := '%' + FDescEdit.Text + '%';
  AQuery.Open;
end;

procedure TDBLookupEdit.PrepareSearchByID(AQuery: TFDQuery; const AValue: Variant);
begin
  PrepareQuery(AQuery, BuildBaseSelect(LookupFields,
    BuildSearchWhere(FLookup.ID + ' = :ID')));

  AQuery.ParamByName('ID').Value := AValue;
  AQuery.Open;
end;

procedure TDBLookupEdit.EventDoSearch(Sender: TObject);
begin
  DoSearch;
end;

procedure TDBLookupEdit.EventDoSearchButton(Sender: TObject);
begin
  if FSearching then
    Exit;

  { O callback pode abrir uma pesquisa modal usando a mesma conexão do
    lookup. Feche qualquer cursor interno antes de entregar o controle ao
    formulário chamador; caso contrário o FireDAC fica esperando a consulta
    anterior e a janela aparenta travar. A guarda também evita reentrada se o
    callback devolver o foco ao editor. }
  FSearching := True;
  try
    if FQuery.Active then
      FQuery.Close;
    if FLoadQuery.Active then
      FLoadQuery.Close;

    if Assigned(FOnSearchButtonClick) then
      FOnSearchButtonClick(Self)
    else
      DoSearch;
  finally
    FSearching := False;
  end;
end;

procedure TDBLookupEdit.ClearSelectedID;
begin
{  FIDEdit.Clear;
  FIsValid := False;

  if Assigned(FDataLink.Field) then
  begin
    if not (FDataLink.DataSource.DataSet.State in dsEditModes) then
      FDataLink.DataSource.DataSet.Edit;

    FDataLink.Field.Clear;
  end;
  }
  FIDEdit.Clear;
  FIsValid := False;

  if Assigned(FDataLink.Field) then
  begin
    FUpdatingFromDataLink := True;
    try
      if FDataLink.Edit then
        FDataLink.Field.Clear;
    finally
      FUpdatingFromDataLink := False;
    end;
  end;
end;

procedure TDBLookupEdit.CMExit(var Message: TCMExit);
begin
 { inherited;

  if FLookupOpened then
    Exit;

  if not FIsValid then
  begin
    if Assigned(FDataLink.Field) then
    begin
      if not (FDataLink.DataSource.DataSet.State in dsEditModes) then
        FDataLink.DataSource.DataSet.Edit;

      FDataLink.Field.Clear;
    end;
  end;  }

  inherited;

  //PostMessage(Handle, WM_LOOKUP_SEARCH, 0, 0);
end;

procedure TDBLookupEdit.Resize;
begin
  inherited;
  ResizeControls;
end;

procedure TDBLookupEdit.Loaded;
begin
  inherited;
  // Recalcula o layout após o Font/ParentFont serem totalmente resolvidos
  // pelo container real (o valor usado em design-time pode diferir do
  // font efetivo em tempo de execução, especialmente com VCL Styles).
  ResizeControls;
end;

procedure TDBLookupEdit.CMFontChanged(var Message: TMessage);
begin
  inherited;
  UpdateEnabledAppearance;
  ResizeControls;
end;

procedure TDBLookupEdit.CMEnabledChanged(var Message: TMessage);
begin
  inherited;
  UpdateEnabledAppearance;
end;

procedure TDBLookupEdit.SetEnabled(Value: Boolean);
begin
  inherited;
  UpdateEnabledAppearance;
end;

procedure TDBLookupEdit.UpdateEnabledAppearance;
var
  AColor: TColor;
  AFontColor: TColor;
begin
  if not Assigned(FIDEdit) or not Assigned(FDescEdit) or
     not Assigned(FSearchButton) then
    Exit;

  // O código é somente informativo: permanece sempre desabilitado e somente
  // leitura, independentemente do estado da descrição.
  // O código continua não editável (ReadOnly e sem foco), mas fica Enabled
  // para que o componente consiga aplicar exatamente a mesma cor dos
  // demais campos bloqueados, inclusive quando o Delphi usa tema visual.
  FIDEdit.Enabled := True;
  // Mantemos o subcampo habilitado apenas para o VCL respeitar a cor
  // configurada; quando o lookup estiver bloqueado ele continua somente
  // leitura e sem possibilidade de foco/edição.
  FDescEdit.Enabled := True;
  FDescEdit.ReadOnly := not Enabled;
  FDescEdit.TabStop := Enabled;
  FSearchButton.Enabled := Enabled;

  AColor := clWindow;
  AFontColor := Font.Color;
  if not Enabled then
  begin
    AColor := FDisabledColor;
    AFontColor := clWindowText;
  end;

  // O campo de código permanece sempre com a aparência de desabilitado.
  FIDEdit.Color := FDisabledColor;
  FDescEdit.Color := AColor;
  FIDEdit.ParentColor := False;
  FDescEdit.ParentColor := False;
  FIDEdit.StyleElements := [];
  FDescEdit.StyleElements := [];
  FIDEdit.Font.Assign(Font);
  FDescEdit.Font.Assign(Font);
  FSearchButton.Font.Assign(Font);
  FIDEdit.Font.Color := AFontColor;
  FDescEdit.Font.Color := AFontColor;
  FSearchButton.Font.Color := AFontColor;
end;

procedure TDBLookupEdit.ResizeControls;
var
  Padding, BtnWidth: Integer;
  TopOffset, LeftOffset: Integer;
  LabelW, LabelH: Integer;
  EditH: Integer;
  ExtraWidth: Integer;
begin
  Padding := 4;
  BtnWidth := 25;

  Canvas.Font.Assign(FIDEdit.Font);
  EditH := Canvas.TextHeight('Ág') + 8;

  TopOffset := 0;
  LeftOffset := 0;
  ExtraWidth := 0;

  { --- LABEL --- }
  if FLabelCaption <> '' then
  begin
    Canvas.Font.Assign(FLabel.Font);
    // Sem folga extra: o espaçamento até o edit é controlado só por FLabelMargin,
    // então com FLabelMargin = 0 a label fica colada no edit.
    LabelW := Canvas.TextWidth(FLabelCaption);
    LabelH := Canvas.TextHeight(FLabelCaption) + 4;

    if FLabelPosition = lpTop then
    begin
      FLabel.SetBounds(Padding, 0, Width - Padding * 2, LabelH);
      TopOffset := LabelH + FLabelMargin;
    end
    else // lpLeft
    begin
      FLabel.SetBounds(Padding, Padding, LabelW, EditH);
      LeftOffset := LabelW + FLabelMargin;
    end;
  end
  else
    FLabel.SetBounds(0, 0, 0, 0);

  { --- BOTÃO --- }
  if FShowSearchButton then
    ExtraWidth := BtnWidth + Padding
  else
    ExtraWidth := 0;

  { --- ID --- }
  FIDEdit.SetBounds(
    LeftOffset + Padding,
    TopOffset,
    FIDWidth,
    EditH
  );

  { --- DESCRIÇÃO --- }
  FDescEdit.SetBounds(
    FIDEdit.Left + FIDWidth + Padding,
    TopOffset,
    Width - (FIDEdit.Left + FIDWidth + Padding * 2) - ExtraWidth,
    EditH
  );

  { --- BOTÃO ---
    Usa a altura real do FDescEdit (AutoSize desligado, então é sempre EditH)
    para garantir que o botão fique exatamente do mesmo tamanho do edit. }
  if FShowSearchButton then
    FSearchButton.SetBounds(
      Width - Padding - BtnWidth,
      FDescEdit.Top,
      BtnWidth,
      FDescEdit.Height
    )
  else
    FSearchButton.SetBounds(0, 0, 0, 0);
end;

end.

