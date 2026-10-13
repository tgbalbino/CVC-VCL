unit uLookupForm;

interface

uses
  System.Classes, Vcl.Forms, Vcl.Controls, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.DBGrids, Data.DB, Vcl.Buttons, Vcl.Grids, System.Math, System.SysUtils;

type
  TfrmLookup = class(TForm)
    Panel1: TPanel;
    DBGrid1: TDBGrid;
    btnOk: TBitBtn;
    btnCancel: TBitBtn;
    procedure btnOkClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure DBGrid1DblClick(Sender: TObject);
    procedure DBGrid1KeyPress(Sender: TObject; var Key: Char);
  private
    FResult: Boolean;
    FDataSource: TDataSource;
  //  FDataSource: TDataSource;
    FHiddenFields: TStringList;
    function SplitStr(const Str, Delimiter: string): TArray<string>;
    procedure HideGridColumns;
  public
    class function Execute(ADataSet: TDataSet; ACaptionCampos: string; HiddenFields: string = ''): Boolean;
  end;

implementation

{$R *.dfm}

procedure TfrmLookup.btnCancelClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TfrmLookup.btnOkClick(Sender: TObject);
begin
  FResult := true;
  ModalResult := mrOk;
end;

procedure TfrmLookup.DBGrid1DblClick(Sender: TObject);
begin
  btnOk.Click;
end;

procedure TfrmLookup.DBGrid1KeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then
    btnOk.Click;
end;

class function TfrmLookup.Execute(ADataSet: TDataSet; ACaptionCampos: string; HiddenFields: string = ''): Boolean;
var
  frm: TfrmLookup;
  Colunas: TArray<string>;
  i: Integer;
begin
  frm := TfrmLookup.Create(nil);
  try
    frm.FDataSource.DataSet := ADataSet;
    frm.DBGrid1.DataSource := frm.FDataSource;

    frm.FHiddenFields.DelimitedText := HiddenFields;
    // Monta os títulos das colunas se CaptionCampos foi passado
    if ACaptionCampos <> '' then
    begin
      Colunas := frm.SplitStr(ACaptionCampos, ',');
      for i := 0 to Min(High(Colunas), frm.DBGrid1.Columns.Count - 1) do
        frm.DBGrid1.Columns[i].Title.Caption := Trim(Colunas[i]);
    end;

    frm.HideGridColumns;
    frm.FResult := False;
    frm.ShowModal;
    Result := frm.FResult;
  finally
    frm.Free;
  end;
end;

procedure TfrmLookup.FormCreate(Sender: TObject);
begin
  FHiddenFields := TStringList.Create;
  FDataSource := TDataSource.Create(nil);
end;

procedure TfrmLookup.FormDestroy(Sender: TObject);
begin
  FHiddenFields.Free;
  FDataSource.Free;
end;

procedure TfrmLookup.HideGridColumns;
var
  i: Integer;
  FieldName: string;
begin
  for i := 0 to DBGrid1.Columns.Count - 1 do
  begin
    FieldName := DBGrid1.Columns[i].Field.FieldName;
    if FHiddenFields.IndexOf(FieldName) >= 0 then
      DBGrid1.Columns[i].Visible := False
    else
      DBGrid1.Columns[i].Visible := True;
  end;
end;

function TfrmLookup.SplitStr(const Str, Delimiter: string): TArray<string>;
var
  S: string;
  P: Integer;
begin
  S := Str;
  SetLength(Result, 0);
  while S <> '' do
  begin
    P := Pos(Delimiter, S);
    if P > 0 then
    begin
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := Trim(Copy(S, 1, P - 1));
      Delete(S, 1, P);
    end
    else
    begin
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := Trim(S);
      S := '';
    end;
  end;
end;

end.
