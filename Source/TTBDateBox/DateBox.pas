unit DateBox;

interface

uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.StdCtrls, JvToolEdit, JvTypes;

type
  TGdb = (Firebird, MSSQL, Oracle);
  TDateBox = class(TGroupBox)
  private
    FDateField: String;
    FGdb: TGdb;
    FQuotedDate: boolean;
    Label1: TLabel;
    Label2: TLabel;
    EdDateStart: TJvDateEdit;
    EdDateEnd: TJvDateEdit;
    CbIgnore: TCheckBox;

    procedure CbIgnoreClick(Sender: TObject);
    { Private declarations }
  protected
    function GetDateFormated(EdData: TJvDateEdit ): String;
    { Protected declarations }
  public
    function GetDateIntervalSql: String;
    function GetDateStarSql: String;
    function GetDateStartSql: String;
    function GetDateEndSql: String;
    function GetDateStart: String;
    function GetDateEnd: String;
    constructor Create(AOwner: TComponent); override;
    { Public declarations }
  published
    property DateField: string read FDateField write FDateField;
    property GDB: TGdb read FGdb write FGdb;
    property QuotedDate: Boolean read FQuotedDate write FQuotedDate;
    { Published declarations }
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Samples', [TDateBox]);
end;

{ TDateBox }

procedure TDateBox.CbIgnoreClick(Sender: TObject);
begin
  EdDateStart.Enabled := not CbIgnore.Checked;
  EdDateEnd.Enabled   := not CbIgnore.Checked;
  Label1.Enabled   := not CbIgnore.Checked;
  Label2.Enabled   := not CbIgnore.Checked;
end;

constructor TDateBox.Create(AOwner: TComponent);
begin
  inherited;

  Label1        := TLabel.Create(Self);
  Label1.Parent := Self;
  Label2        := TLabel.Create(Self);
  Label2.Parent := Self;

  Label1.Caption := 'Período: ';
  Label1.Left := 5;

  EdDateStart        := TJvDateEdit.Create(Self);
  EdDateStart.Top    := EdDateStart.Height - 4;
  EdDateStart.Left   := Label1.Left + Label1.Width + 3;
  EdDateStart.Parent := Self;
  EdDateStart.StartOfWeek := Sun;
  EdDateStart.YearDigits  := dyFour;

  Label1.Top  := EdDateStart.Top + 4;

  EdDateEnd   := TJvDateEdit.Create(Self);
  EdDateEnd.Parent := Self;
  EdDateEnd.Top  := EdDateStart.Top;
  EdDateEnd.StartOfWeek := Sun;
  EdDateEnd.YearDigits := dyFour;

  Label2.Top     := Label1.Top;
  Label2.Caption := 'a';
  Label2.Left    := EdDateStart.Left + EdDateStart.Width + 5;

  EdDateEnd.Left := EdDateStart.Left + EdDateStart.Width + 15;

  CbIgnore := TCheckBox.Create(Self);
  CbIgnore.Parent  := Self;
  CbIgnore.Align   := alBottom;
  CbIgnore.Caption := 'Ignorar data';

  CbIgnore.AlignWithMargins := True;
  CbIgnore.Checked := True;
  CbIgnore.OnClick := CbIgnoreClick;
end;

function TDateBox.GetDateIntervalSql: String;
begin
  Result := '';
  if (FDateField <> '') and (not CbIgnore.Checked) then
    Result := FDateField  + ' between ' + GetDateFormated(EdDateStart) + ' and ' +
                                          GetDateFormated(EdDateEnd);
end;

function TDateBox.GetDateEnd: String;
begin
  Result := GetDateFormated(EdDateEnd);
end;

function TDateBox.GetDateEndSql: String;
begin
  Result := '';
  if FDateField <> '' then
  Result := FDateField  + ' = ' + GetDateFormated(EdDateEnd);
end;

function TDateBox.GetDateStarSql: String;
begin
  Result := GetDateStartSql;
end;

function TDateBox.GetDateStartSql: String;
begin
  Result := '';
  if FDateField <> '' then
  Result := FDateField  + ' = ' + GetDateFormated(EdDateStart);
end;

function TDateBox.GetDateStart: String;
begin
  Result := GetDateFormated(EdDateStart);
end;

function TDateBox.GetDateFormated(EdData: TJvDateEdit): String;
  function getFormat: string;
  begin
    case FGdb of
      Firebird:  Result := 'yyyy.MM.dd';
      MSSQL:  Result := '';
      Oracle:  Result := '';
    end;
  end;

begin
  try
    Result := FormatDateTime(getFormat, EdData.Date);

    if QuotedDate then
    Result := QuotedStr(Result);
  except
    Result := '';
    raise Exception.Create('TDateBox.GetDateFormated: Erro ao formatar data.');
  end;
end;

end.
