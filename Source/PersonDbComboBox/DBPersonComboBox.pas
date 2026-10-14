unit DBPersonComboBox;

interface

uses
  System.Classes, Vcl.StdCtrls, Data.DB, Vcl.Controls, Vcl.DBCtrls;

type
  TDBPersonComboBox = class(TCustomComboBox)
  private
    FDataLink: TFieldDataLink; // Link de dados para sincronização
    FDisplayItems: TStringList; // Textos exibidos
    FValues: TStringList; // Valores associados
    procedure SetDisplayItems(const Value: TStringList);
    procedure SetValues(const Value: TStringList);
    function GetSelectedValue: string;
    procedure UpdateDisplayText;
    procedure DataChange(Sender: TObject);
    procedure UpdateData(Sender: TObject);
    procedure CMExit(var Message: TCMExit); message CM_EXIT;
    function GetDataSource: TDataSource;
    procedure SetDataSource(const Value: TDataSource);
    function GetDataField: string;
    procedure SetDataField(const Value: string);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure Change; override;
    procedure Loaded; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property SelectedValue: string read GetSelectedValue;
  published
    property DisplayItems: TStringList read FDisplayItems write SetDisplayItems; // Itens exibidos no combo
    property Values: TStringList read FValues write SetValues; // Valores associados
    property DataSource: TDataSource read GetDataSource write SetDataSource;
    property DataField: string read GetDataField write SetDataField;
    property Style; // Exibe o estilo padrão do combo box
    property TabOrder;
  end;

procedure Register;

implementation

uses
  System.SysUtils;

procedure Register;
begin
  RegisterComponents('Samples', [TDBPersonComboBox]);
end;

{ TDBPersonComboBox }

constructor TDBPersonComboBox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FDisplayItems := TStringList.Create;
  FValues := TStringList.Create;

  // Cria o DataLink para vinculação
  FDataLink := TFieldDataLink.Create;
  FDataLink.Control := Self;
  FDataLink.OnDataChange := DataChange;
  FDataLink.OnUpdateData := UpdateData;

  // Inicializa os itens no ComboBox
  Items.Clear;
end;

destructor TDBPersonComboBox.Destroy;
begin
  FDataLink.Free;
  FDisplayItems.Free;
  FValues.Free;
  inherited Destroy;
end;

procedure TDBPersonComboBox.Loaded;
begin
  inherited Loaded;
  Items.Assign(FDisplayItems);  // Atualiza os itens visíveis após o carregamento
end;

procedure TDBPersonComboBox.Change;
begin
  inherited Change;
  if FDataLink.Editing then
    FDataLink.Modified;
end;

procedure TDBPersonComboBox.CMExit(var Message: TCMExit);
begin
  try
    if FDataLink.Editing then
      FDataLink.UpdateRecord;
  except
    SetFocus;
    raise;
  end;
  inherited;
end;

function TDBPersonComboBox.GetDataSource: TDataSource;
begin
  Result := FDataLink.DataSource;
end;

procedure TDBPersonComboBox.SetDataSource(const Value: TDataSource);
begin
  FDataLink.DataSource := Value;
end;

function TDBPersonComboBox.GetDataField: string;
begin
  Result := FDataLink.FieldName;
end;

procedure TDBPersonComboBox.SetDataField(const Value: string);
begin
  FDataLink.FieldName := Value;
end;

procedure TDBPersonComboBox.DataChange(Sender: TObject);
begin
  UpdateDisplayText;
end;

procedure TDBPersonComboBox.UpdateData(Sender: TObject);
begin
  if (ItemIndex >= 0) and (ItemIndex < FValues.Count) and
     Assigned(FDataLink.Field) then
    FDataLink.Field.AsString := FValues[ItemIndex];
end;

procedure TDBPersonComboBox.SetDisplayItems(const Value: TStringList);
begin
  FDisplayItems.Assign(Value);
  Items.Assign(FDisplayItems);  // Atualiza os itens visíveis no combo box
end;

procedure TDBPersonComboBox.SetValues(const Value: TStringList);
begin
  FValues.Assign(Value);
end;

function TDBPersonComboBox.GetSelectedValue: string;
begin
  if (ItemIndex >= 0) and (ItemIndex < FValues.Count) then
    Result := FValues[ItemIndex]
  else
    Result := '';
end;

procedure TDBPersonComboBox.UpdateDisplayText;
var
  Field: TField;
  ValueIndex: Integer;
begin
  if FDataLink.Active and (FDataLink.Field <> nil) then
  begin
    Field := FDataLink.Field;
    ValueIndex := FValues.IndexOf(Field.AsString);
    if (ValueIndex >= 0) then
      ItemIndex := ValueIndex
    else
      ItemIndex := -1;
  end
  else
    ItemIndex := -1;
end;

procedure TDBPersonComboBox.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = DataSource) then
    DataSource := nil;
end;

end.

