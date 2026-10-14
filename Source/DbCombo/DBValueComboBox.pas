unit DBValueComboBox;

interface

uses
  System.SysUtils, System.Classes,
  Vcl.StdCtrls, Data.DB, Vcl.DBCtrls;

type
  TDBValueComboBox = class(TCustomComboBox)
  private
    FValues: TStringList;
    FDataLink: TFieldDataLink;
    procedure SetValues(const Value: TStringList);
    procedure DataChange(Sender: TObject);
    procedure UpdateData(Sender: TObject);
    function GetDataSource: TDataSource;
    procedure SetDataSource(Value: TDataSource);
    function GetDataField: string;
    procedure SetDataField(const Value: string);
    procedure ComboChanged(Sender: TObject);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property DataSource: TDataSource read GetDataSource write SetDataSource;
    property DataField: string read GetDataField write SetDataField;
    property Values: TStringList read FValues write SetValues;
    property Items;
    property Style default csDropDownList;
    property Align;
    property Anchors;
    property TabOrder;
    property TabStop;
    property Visible;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Samples', [TDBValueComboBox]);
end;

{ TDBValueComboBox }

constructor TDBValueComboBox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Style := csDropDownList;

  FValues := TStringList.Create;

  FDataLink := TFieldDataLink.Create;
  FDataLink.Control := Self;
  FDataLink.OnDataChange := DataChange;
  FDataLink.OnUpdateData := UpdateData;

  OnChange := ComboChanged; // aqui pegamos quando o usuário troca
end;

destructor TDBValueComboBox.Destroy;
begin
  FDataLink.Free;
  FValues.Free;
  inherited;
end;

procedure TDBValueComboBox.ComboChanged(Sender: TObject);
begin
  if (ItemIndex >= 0) then
  begin
    FDataLink.Edit;      // coloca dataset em modo edição
    FDataLink.Modified;  // marca como alterado para chamar UpdateData
    FDataLink.UpdateRecord;   // força gravar o valor no campo imediatamente
  end;
end;

procedure TDBValueComboBox.DataChange(Sender: TObject);
var
  idx: Integer;
begin
  if Assigned(FDataLink.Field) and (FValues.Count > 0) then
  begin
    idx := FValues.IndexOf(FDataLink.Field.AsString);
    if (idx >= 0) and (idx < Items.Count) then
      ItemIndex := idx
    else
      ItemIndex := -1;
  end
  else
    ItemIndex := -1;
end;

procedure TDBValueComboBox.UpdateData(Sender: TObject);
begin
  if Assigned(FDataLink.Field) and
     (ItemIndex >= 0) and (ItemIndex < FValues.Count) then
    FDataLink.Field.AsString := FValues[ItemIndex];
end;

function TDBValueComboBox.GetDataSource: TDataSource;
begin
  Result := FDataLink.DataSource;
end;

procedure TDBValueComboBox.SetDataSource(Value: TDataSource);
begin
  FDataLink.DataSource := Value;
end;

function TDBValueComboBox.GetDataField: string;
begin
  Result := FDataLink.FieldName;
end;

procedure TDBValueComboBox.SetDataField(const Value: string);
begin
  FDataLink.FieldName := Value;
end;

procedure TDBValueComboBox.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited;
  if (Operation = opRemove) and (AComponent = DataSource) then
    DataSource := nil;
end;

procedure TDBValueComboBox.SetValues(const Value: TStringList);
begin
  FValues.Assign(Value);
end;

end.

