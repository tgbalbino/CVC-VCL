unit DBLookupEdit;

interface

uses
  System.SysUtils, System.Classes, System.Variants, Winapi.Windows,
  Winapi.Messages, Vcl.Controls, Vcl.StdCtrls, Vcl.Buttons, Vcl.Graphics,
  Data.DB, Vcl.DBCtrls, FireDAC.Comp.Client;

type
  TLabelPosition = (lpTop, lpLeft);

  TBeforeSelectRecordEvent = procedure(Sender: TObject; const Query: TFDQuery) of object;
  TDBLookupEditSearchButtonClick = procedure(Sender: TObject) of object;

  TDBLookupSettings = class(TPersistent)
  private
    FTabela: string;
    FCampoRetorno: string;
    FID: string;
    FOutrosCampos: string;
    FCaptionCampos: string;
    FSearchFilter: string;
  published
    property Tabela: string read FTabela write FTabela;
    property CampoRetorno: string read FCampoRetorno write FCampoRetorno;
    property ID: string read FID write FID;
    property OutrosCampos: string read FOutrosCampos write FOutrosCampos;
    property CaptionCampos: string read FCaptionCampos write FCaptionCampos;
    property SearchFilter: string read FSearchFilter write FSearchFilter;
  end;

  TDBLookupEdit = class(TCustomControl)
  private
    FUpdatingFromDataLink: Boolean;
    FSearching: Boolean;
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

    { Events }
    FOnBeforeSelectRecord: TBeforeSelectRecordEvent;
    FOnSearchButtonClick: TDBLookupEditSearchButtonClick;
    FOnAfterSelect: TNotifyEvent;

    FOldDescWndProc: TWndMethod;
    procedure DescEditWndProc(var Msg: TMessage);

    { Internal helpers }
    procedure ResizeControls;
    function BuildBaseSelect(const AFields, AWhere: string): string;
    procedure PrepareQuery(const ASql: string);
    procedure PrepareQueryByText;
    procedure PrepareQueryByID(const AValue: Variant);
    procedure PrepareSearchByID(const AValue: Variant);
    procedure FillFromQuery;
    procedure InternalLoadByID(const AID: Variant);
    procedure DoSearch;

    { Setters }
    procedure SetLookup(const Value: TDBLookupSettings);
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
    procedure WMKeyDown(var Msg: TWMKeyDown); message WM_KEYDOWN;
    procedure CMExit(var Message: TCMExit); message CM_EXIT;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
    procedure CMEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
    function GetHasValue: Boolean;
    function GetDescription: string;
    procedure DescEditChange(Sender: TObject);
    procedure DescEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure ClearSelectedID;
    function BuildSearchWhere(const AWhere: string): string;
    procedure UpdateEnabledAppearance;
  protected
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
    property Connection: TFDConnection read FConnection write FConnection;
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

    property OnBeforeSelectRecord: TBeforeSelectRecordEvent read FOnBeforeSelectRecord write FOnBeforeSelectRecord;
    property OnSearchButtonClick: TDBLookupEditSearchButtonClick read FOnSearchButtonClick write FOnSearchButtonClick;
    property OnAfterSelect: TNotifyEvent read FOnAfterSelect write FOnAfterSelect;

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

procedure Register;

implementation

uses
  uLookupForm;

procedure Register;
begin
  RegisterComponents('CVC-VCL', [TDBLookupEdit]);
end;

{ TDBLookupEdit }

constructor TDBLookupEdit.Create(AOwner: TComponent);
begin
  inherited;

  ControlStyle := ControlStyle + [csParentBackground];
  ParentColor := True;

  Width := 300;
  Height := 48;

  FIsValid := False;
  FSelectedIDValue := Null;
  FShowSearchButton := True;
  FIDWidth := 50;
  FLabelMargin := 4;
  FLabelPosition := lpTop;

  FLookup := TDBLookupSettings.Create;

  FQuery := TFDQuery.Create(Self);

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
  //FIDEdit.Enabled := False;
  FIDEdit.ReadOnly := True;
  FIDEdit.Enabled := True;        // mantém fonte preta
  FIDEdit.TabStop := False;       // não entra no TAB
  FIDEdit.Color := clBtnFace;     // aparência de desabilitado
  FIDEdit.Ctl3D := False;
  FIDEdit.ParentCtl3D := False;
  FIDEdit.Cursor := crArrow;      // não parece editável

  FDescEdit := TEdit.Create(Self);
  FDescEdit.Parent := Self;
  FDescEdit.AutoSize := False;    // permite fixar a altura manualmente
  FDescEdit.Ctl3D := False;
  FDescEdit.ParentCtl3D := False;
  FDescEdit.OnDblClick := EventDoSearch;
  FDescEdit.OnChange := DescEditChange;
  FDescEdit.OnKeyDown := DescEditKeyDown;
  FOldDescWndProc := FDescEdit.WindowProc;
  FDescEdit.WindowProc := DescEditWndProc;

  FSearchButton := TSpeedButton.Create(Self);
  FSearchButton.Parent := Self;
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

procedure TDBLookupEdit.DescEditKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key = VK_RETURN) then
  begin
    Key := 0;
    DoSearch;
  end;
end;

procedure TDBLookupEdit.DescEditWndProc(var Msg: TMessage);
begin
  FOldDescWndProc(Msg);

  if Msg.Msg = CM_EXIT then
  begin
    if not (csDestroying in ComponentState) and
       not FLookupOpened and
       (Trim(FDescEdit.Text) <> '') and
       (not FIsValid) then
      DoSearch;
  end;
end;

destructor TDBLookupEdit.Destroy;
begin
  FLabelFont.Free;
  FLookup.Free;
  FDataLink.Free;
  inherited;
end;

procedure TDBLookupEdit.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited;
  if (Operation = opRemove) and (AComponent = FDataSource) then
    DataSource := nil;
end;

procedure TDBLookupEdit.SetLookup(const Value: TDBLookupSettings);
begin
  FLookup.Assign(Value);
end;

procedure TDBLookupEdit.SetDataSource(const Value: TDataSource);
begin
  FDataSource := Value;
  FDataLink.DataSource := Value;
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
{  if VarSameValue(GetSelectedID, Value) then
    Exit;

  if VarIsNull(Value) or VarIsEmpty(Value) then
  begin
    Clear;
    Exit;
  end;

  InternalLoadByID(Value);  }


  if VarIsNull(Value) or VarIsEmpty(Value) then
  begin
    Clear;
    Exit;
  end;

  if Assigned(FDataLink.Field) and FDataLink.DataSource.DataSet.Active then
  begin
    if not (FDataLink.DataSource.DataSet.State in dsEditModes) then
      FDataLink.DataSource.DataSet.Edit;

    FDataLink.Field.Value := Value;
  end;

  InternalLoadByID(Value);
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
  if not Assigned(FConnection) then
    raise Exception.Create('Conexão não definida.');

  PrepareQueryByID(AID);

  if FQuery.IsEmpty then
  begin
    Clear;
    Exit;
  end;

  // ATUALIZA SOMENTE OS CONTROLES VISUAIS
  FillFromQuery;
end;

function TDBLookupEdit.BuildBaseSelect(const AFields, AWhere: string): string;
begin
  Result := Format('SELECT %s FROM %s WHERE %s', [AFields, FLookup.Tabela, AWhere]);
end;

procedure TDBLookupEdit.PrepareQuery(const ASql: string);
begin
  FQuery.Close;
  FQuery.Connection := FConnection;

  // Só reatribui o SQL se mudou, evitando que o FireDAC precise
  // reanalisar/repreparar o comando a cada busca com o mesmo Lookup.
  if FQuery.SQL.Text <> ASql then
    FQuery.SQL.Text := ASql;
end;

procedure TDBLookupEdit.PrepareQueryByID(const AValue: Variant);
begin
  PrepareQuery(BuildBaseSelect(FLookup.ID + ', ' + FLookup.CampoRetorno, FLookup.ID + ' = :ID'));

  FQuery.ParamByName('ID').Value := AValue;
  FQuery.Open;
end;

procedure TDBLookupEdit.FillFromQuery;
begin
  FUpdatingFromDataLink := True;
  try
    FIDEdit.Text := FQuery.FieldByName(FLookup.ID).AsString;
    FDescEdit.Text := FQuery.FieldByName(FLookup.CampoRetorno).AsString;
    FLastDescText := FDescEdit.Text;
    FSelectedIDValue := FQuery.FieldByName(FLookup.ID).Value;
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
begin
   if FSearching then
    Exit;

  FSearching := True;
  try
    if Trim(FDescEdit.Text) = '' then
    begin
      Clear;
      Exit;
    end;

    FIsValid := False;

    if TryStrToInt(Trim(FDescEdit.Text), IDCandidate) then
    begin
      PrepareSearchByID(IDCandidate);

      if not FQuery.IsEmpty then
      begin
        SetSelectedID(FQuery.FieldByName(FLookup.ID).Value);
        FIsValid := True;
        Exit;
      end;
    end;

    PrepareQueryByText;

    if FQuery.IsEmpty then
    begin
      ClearSelectedID;
      Exit;
    end;

    if FQuery.RecordCount > 1 then
    begin
      FLookupOpened := True;
      try
        if not TfrmLookup.Execute(FQuery, FLookup.CaptionCampos, HiddenFields) then
          Exit;
      finally
        FLookupOpened := false;
      end;

      if Assigned(FOnBeforeSelectRecord) then
        FOnBeforeSelectRecord(Self, FQuery);
    end;

    SetSelectedID(FQuery.FieldByName(FLookup.ID).Value);
    FIsValid := True;
  finally
    FSearching := False;
  end;
end;

procedure TDBLookupEdit.PrepareQueryByText;
var
  Campos: string;
begin
  Campos := FLookup.ID + ', ' + FLookup.CampoRetorno;
  if FLookup.OutrosCampos <> '' then
    Campos := Campos + ',' + FLookup.OutrosCampos;

  PrepareQuery(BuildBaseSelect(Campos, BuildSearchWhere(FLookup.CampoRetorno + ' LIKE :P')));

  FQuery.ParamByName('P').AsString := '%' + FDescEdit.Text + '%';
  FQuery.Open;
end;

procedure TDBLookupEdit.PrepareSearchByID(const AValue: Variant);
begin
  PrepareQuery(BuildBaseSelect(FLookup.ID + ', ' + FLookup.CampoRetorno,
    BuildSearchWhere(FLookup.ID + ' = :ID')));

  FQuery.ParamByName('ID').Value := AValue;
  FQuery.Open;
end;

procedure TDBLookupEdit.EventDoSearch(Sender: TObject);
begin
  DoSearch;
end;

procedure TDBLookupEdit.EventDoSearchButton(Sender: TObject);
begin
  if Assigned(FOnSearchButtonClick) then
    FOnSearchButtonClick(Self)
  else
    DoSearch;
end;

procedure TDBLookupEdit.WMKeyDown(var Msg: TWMKeyDown);
begin
  inherited;
  if Msg.CharCode = VK_RETURN then
  begin
    //FEnterPressed := True;
    DoSearch;
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
      if not (FDataLink.DataSource.DataSet.State in dsEditModes) then
        FDataLink.DataSource.DataSet.Edit;

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

procedure TDBLookupEdit.UpdateEnabledAppearance;
var
  AColor: TColor;
  AFontColor: TColor;
begin
  if not Assigned(FIDEdit) or not Assigned(FDescEdit) or
     not Assigned(FSearchButton) then
    Exit;

  FIDEdit.Enabled := Enabled;
  FDescEdit.Enabled := Enabled;
  FSearchButton.Enabled := Enabled;

  if Enabled then
  begin
    AColor := clWindow;
    AFontColor := Font.Color;
  end
  else
  begin
    // Mantém o mesmo padrão do TDBEdit desabilitado usado nas telas do ERP.
    AColor := clSilver;
    AFontColor := clWindowText;
  end;

  FIDEdit.Color := AColor;
  FDescEdit.Color := AColor;
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

