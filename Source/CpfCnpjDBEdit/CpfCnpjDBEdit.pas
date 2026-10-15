{
 TCpfCnpjDBEdit Component Feito para o Delphi 10.3 não testado em outras versões
 Componente para Mascarar e Gravar em campo de Dataset/Query automaticament um CPF OU CNPJ apos digitar informação
 Atenção o componente salva no Cliente ou Query somente os valores sem a formatação ou seja a mesma é só visual
 First Version: 2023
 by: Thiago Balbino
 Data: 10/03/2013

 Possiveis futuras implementaões
   * Isvalid ( validar se o documento informado é válido)
   * Type ( tdCpf, tdCPNJ, tdCpfCnpj) propriedade só aceite digitar um CPF ou CNPJ com padrão tdCpfCnpj
   * Validar ao Colar(Ctrl + V) um conteudo e aceitar somente números.

   Sugestoes e melhorias são bem vindas: tecnologiaminas@gmail.com
}

unit CpfCnpjDBEdit;

interface

uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.StdCtrls, Vcl.Mask,
  Vcl.DBCtrls, Data.DB, Winapi.Windows, Winapi.Messages, System.Variants,
  Vcl.Graphics, Vcl.Forms, Vcl.Dialogs, Vcl.Clipbrd;

type
  TCpfCnpjDBEdit = class(TDBEdit)
   procedure WMPaint(var Message: TWMPaint); message WM_PAINT;
    procedure CMTextChanged(var Message: TMessage); message CM_TEXTCHANGED;
    procedure WMKEYUP(var Message: TWMPaint); message WM_KEYUP;
  private
    FIsUnMask: Boolean;
    FFirst: Boolean;
    FRaiseExcepOnValidade: Boolean;
    FPaintedRed: Boolean;
    FRequired: Boolean;
    procedure CheckForInvalidate;
    function HasLinked: Boolean;
    procedure Mask;
    function hasMask: Boolean;
    procedure unMaskIfNeed;
    procedure removeMask;
    function ValidarLenCNPJCPF(Const AValue: String): boolean;
    class function ValidarCNPJCPFInterno(Const AValue: String): boolean;
    procedure ValidateAndPaste;

    { Private declarations }
  protected
    procedure WMPaste(var Msg: TWMPaste); message WM_PASTE;
    procedure Change; override;
    procedure DoExit; override;
    procedure DoEnter; override;
    procedure KeyPress(var Key: Char); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
//   property Mask: String read FMask write FMask;
    procedure WndProc(var Msg: TMessage); override;
    { Protected declarations }
  public
    constructor Create(AOwner: TComponent); override;
    function IsValid: boolean;
    class function ValidarCNPJCPF(const ADocumento: string): Boolean; static;
    class function CharToBase36(C: Char): Integer;
    { Public declarations }
  published
    Property Required: Boolean read FRequired Write FRequired;
    { Published declarations }
  end;

Const
  MascaraCPF_ = '###\.###\.###\-##;0;_';
  MascaraCNPJ_ = 'AA\.AAA\.AAA\/AAAA\-00;0;_';


procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Samples', [TCpfCnpjDBEdit]);
end;

function CharIsNum(const C: Char): Boolean;
begin
  Result := CharInSet( C, ['0'..'9'] ) ;
end;

function CharToDigit(C: Char): Integer;
begin
  if CharInSet(C, ['0'..'9']) then
    Result := Ord(C) - Ord('0')
  else
    Result := -1;
end;

function CharToValue(C: Char): Integer;
begin
  C := UpCase(C);

  if CharInSet(C, ['0'..'9']) then
    Result := Ord(C) - Ord('0')
  else if CharInSet(C, ['A'..'Z']) then
    Result := Ord(C) - 48
  else
    Result := -1;
end;

function OnlyAlphaNum(const AValue: String): String;
var
  C: Char;
begin
  Result := '';
  for C in AValue do
    if CharInSet(UpCase(C), ['0'..'9','A'..'Z']) then
      Result := Result + UpCase(C);
end;

function OnlyNumber(const AValue: String): String;
Var
  I : Integer ;
  LenValue : Integer;
begin
  Result   := '' ;
  LenValue := Length( AValue ) ;
  for I := 1 to LenValue  do
  begin
    if CharIsNum( AValue[I] ) then
        Result := Result + AValue[I];
  end;
end;

function StrIsNumber(const S: String): Boolean;
Var
  A, LenStr : Integer ;
begin
  LenStr := Length( S ) ;
  Result := (LenStr > 0) ;
  A      := 1 ;
  while Result and ( A <= LenStr )  do
  begin
    Result := CharIsNum(S[A]);
    Inc(A);
  end;
end;

function RemoveChar(const Texto: string): string;
var
  I: Integer;
begin
  Result := '';
  for I := 1 to Length(Texto) do
    if CharInSet(UpCase(Texto[I]), ['0'..'9','A'..'Z']) then
      Result := Result + UpCase(Texto[I]);
end;

{ TCpfCnpjDBEdit }

procedure TCpfCnpjDBEdit.Change;
begin
  OutputDebugString(Pchar('Change'));

  {if (FIsUnMask) then
  Exit;

  //if (hasMask) then
  //unMaskIfNeed;

  //Aplicar mascara ao criar Objeto
  if (Self.FFirst) and (RemoveChar(TStringField(Self.DataSource.DataSet.FieldByName(Self.DataField)).Value) <> '') then
  begin
    Self.FFirst:= False;
    Mask;
  end;  }

  if FIsUnMask then Exit;

  inherited;
end;

class function TCpfCnpjDBEdit.CharToBase36(C: Char): Integer;
begin
  C := UpCase(C);

  if CharInSet(C, ['0'..'9']) then
    Result := Ord(C) - Ord('0')
  else if CharInSet(C, ['A'..'Z']) then
    Result := Ord(C) - 48
  else
    Result := -1;
end;

procedure TCpfCnpjDBEdit.CheckForInvalidate;
begin
  if  Required and (Length(Trim(Text)) = 0) then
  begin
    if not FPaintedRed then
      Invalidate;
  end
  else if FPaintedRed then
    Invalidate;
end;

procedure TCpfCnpjDBEdit.CMTextChanged(var Message: TMessage);
begin
  inherited;

  CheckForInvalidate;

  //quando o dataset mudar o valor do campo
  //if not (csLoading in ComponentState) then
  //  Mask;

//  CheckForInvalidate;
end;

constructor TCpfCnpjDBEdit.Create(AOwner: TComponent);
begin
  Self.FFirst:= true;
  Self.FIsUnMask:= False;
  OutputDebugString(Pchar('Create'));

  inherited;
end;

procedure TCpfCnpjDBEdit.DoEnter;
begin
  try
    if HasLinked  then
      removeMask;
  except
    //no error message
  end;

 inherited;
end;

procedure TCpfCnpjDBEdit.DoExit;
begin
  Mask;
  inherited;
end;

function TCpfCnpjDBEdit.HasLinked: Boolean;
begin
  Result := (Self.DataSource <> nil) and (Self.DataField <> '');
end;

function TCpfCnpjDBEdit.hasMask: Boolean;
begin
  Result := (Self.DataSource <> nil) and
            (Self.DataField <> '')  and
            (TStringField(Self.DataSource.DataSet.FieldByName(Self.DataField)).EditMask <> '');
end;

function TCpfCnpjDBEdit.IsValid: boolean;
begin
  Result := ValidarCNPJCPFInterno(Self.Text);

  if (not Result) and FRaiseExcepOnValidade then
    raise Exception.Create('CPF ou CNPJ Inválido.');
end;

procedure TCpfCnpjDBEdit.KeyDown(var Key: Word;
  Shift: TShiftState);
begin
  inherited;
  if ((ssCtrl in Shift) AND (Key = ord('V'))) then
  begin
    //if Clipboard.HasFormat(CF_TEXT) then ClipBoard.Clear;
    //if ( Clipboard.ToString) then
    OutputDebugString(Pchar('KeyDown'));

   // Edit1.SelText := '"Colar" DESATIVADO!';
  end;
end;

procedure TCpfCnpjDBEdit.KeyPress(var Key: Char);
begin
  //if not CharInSet(key, ['0'..'9', #13, #8]) then
 {  if not (Key in ['0'..'9', #8, #9, #13, #27, #$16]) then
    Key := #0;

  inherited; }

 if not CharInSet(UpCase(Key),
    ['0'..'9', 'A'..'Z',
     #1,   // Ctrl+A
     #3,   // Ctrl+C
     #8,   // Backspace
     #9,   // Tab
     #13,  // Enter
     #22,  // Ctrl+V
     #24,  // Ctrl+X
     #26,  // Ctrl+Z
     #27]) // Esc
  then
    Key := #0;

  if Key >= #32 then
    Key := UpCase(Key);

  inherited;
end;

procedure TCpfCnpjDBEdit.Mask;
var
  Doc: String;
  Fld: TStringField;
begin
  if FIsUnMask then
    Exit;

  if not HasLinked then
    Exit;

  try
    Fld := TStringField(DataSource.DataSet.FieldByName(DataField));

    Doc := OnlyAlphaNum(Fld.AsString);

    if Length(Doc) = 11 then
      Fld.EditMask := MascaraCPF_
    else if Length(Doc) = 14 then
      Fld.EditMask := MascaraCNPJ_
    else
      Fld.EditMask := '';
  except
  end;
end;

{procedure TCpfCnpjDBEdit.Mask;
var
  val: String;
begin
  try
    if (HasLinked) then
    begin
      Val := OnlyAlphaNum(TStringField(Self.DataSource.DataSet.FieldByName(Self.DataField)).Value);

      if Length(Val) = 11 then
        TStringField(Self.DataSource.DataSet.FieldByName(Self.DataField)).EditMask := MascaraCPF_
      else if Length(Val) = 14 then
        TStringField(Self.DataSource.DataSet.FieldByName(Self.DataField)).EditMask := MascaraCNPJ_
      else
        TStringField(Self.DataSource.DataSet.FieldByName(Self.DataField)).EditMask := '';
    end;
  except
    //no error message
  end;
end; }

procedure TCpfCnpjDBEdit.removeMask;
begin
  FIsUnMask := true;
  TStringField(Self.DataSource.DataSet.FieldByName(Self.DataField)).EditMask := '';
  OutputDebugString(Pchar('removeMask.Mask: ' + TStringField(Self.DataSource.DataSet.FieldByName(Self.DataField)).EditMask));
  FIsUnMask := False;
end;

procedure TCpfCnpjDBEdit.unMaskIfNeed;
begin
  if hasMask then
    removeMask;
end;

class function TCpfCnpjDBEdit.ValidarCNPJCPF(const ADocumento: string): Boolean;
begin
  Result := TCpfCnpjDBEdit.ValidarCNPJCPFInterno(ADocumento);
end;

class function TCpfCnpjDBEdit.ValidarCNPJCPFInterno(Const AValue: String): Boolean;

  function ValidarCPF(Const ACPF: string): Boolean;
  var
    n1,n2,n3,n4,n5,n6,n7,n8,n9: Integer;
    d1,d2: Integer;
    digitado, calculado, strCPF: string;

    function CharToDigit(C: Char): Integer;
    begin
      if CharInSet(C, ['0'..'9']) then
        Result := Ord(C) - Ord('0')
      else
        Result := -1;
    end;

  begin
    Result := False;

    strCPF := RemoveChar(ACPF);

    if Length(strCPF) <> 11 then
      Exit;

    n1 := CharToDigit(strCPF[1]);
    n2 := CharToDigit(strCPF[2]);
    n3 := CharToDigit(strCPF[3]);
    n4 := CharToDigit(strCPF[4]);
    n5 := CharToDigit(strCPF[5]);
    n6 := CharToDigit(strCPF[6]);
    n7 := CharToDigit(strCPF[7]);
    n8 := CharToDigit(strCPF[8]);
    n9 := CharToDigit(strCPF[9]);

    if (n1<0) or (n2<0) or (n3<0) or (n4<0) or (n5<0) or
       (n6<0) or (n7<0) or (n8<0) or (n9<0) then
       Exit;

    d1 := n9*2 + n8*3 + n7*4 + n6*5 + n5*6 + n4*7 + n3*8 + n2*9 + n1*10;
    d1 := 11 - (d1 mod 11);

    if d1 >= 10 then
      d1 := 0;

    d2 := d1*2 + n9*3 + n8*4 + n7*5 + n6*6 + n5*7 + n4*8 + n3*9 + n2*10 + n1*11;
    d2 := 11 - (d2 mod 11);

    if d2 >= 10 then
      d2 := 0;

    calculado := IntToStr(d1) + IntToStr(d2);
    digitado := strCPF[10] + strCPF[11];

    Result := calculado = digitado;
  end;

  function ValidarCNPJ(Const ACNPJ: string): Boolean;
  var
    CNPJ: string;
    I: Integer;
    Soma: Integer;
    Peso: Integer;
    Dig1, Dig2: Integer;
    DV1, DV2: Integer;
  begin
    Result := False;

    CNPJ := OnlyAlphaNum(ACNPJ);

    if Length(CNPJ) <> 14 then
      Exit;

    for I := 1 to 12 do
      if CharToBase36(CNPJ[I]) < 0 then
        Exit;

    DV1 := CharToDigit(CNPJ[13]);
    DV2 := CharToDigit(CNPJ[14]);

    if (DV1 < 0) or (DV2 < 0) then
      Exit;

    Soma := 0;
    Peso := 5;

    for I := 1 to 12 do
    begin
      Soma := Soma + (CharToBase36(CNPJ[I]) * Peso);

      Dec(Peso);

      if Peso < 2 then
        Peso := 9;
    end;

    Dig1 := 11 - (Soma mod 11);

    if Dig1 >= 10 then
      Dig1 := 0;

    Soma := 0;
    Peso := 6;

    for I := 1 to 12 do
    begin
      Soma := Soma + (CharToBase36(CNPJ[I]) * Peso);

      Dec(Peso);

      if Peso < 2 then
        Peso := 9;
    end;

    Soma := Soma + (Dig1 * 2);

    Dig2 := 11 - (Soma mod 11);

    if Dig2 >= 10 then
      Dig2 := 0;

    Result :=
      (Dig1 = DV1) and
      (Dig2 = DV2);
  end;
var
  DOC: String;
begin
  Doc := OnlyAlphaNum(AValue);

  if Length(Doc) = 11 then
    Result := ValidarCPF(Doc)
  else if Length(Doc) = 14 then
    Result := ValidarCNPJ(Doc)
  else
    Result := False;
end;

function TCpfCnpjDBEdit.ValidarLenCNPJCPF(const AValue: String): boolean;
var
  Doc: string;
begin
  Doc := OnlyAlphaNum(AValue);

  Result := Length(Doc) in [11,14];
end;

procedure TCpfCnpjDBEdit.ValidateAndPaste;
var
  ClipText: string;
begin
  ClipText := OnlyAlphaNum(Clipboard.AsText);

  //if (ClipText.IsEmpty or not ClipText.IsNumeric) then
  if ((ClipText.IsEmpty) or
      (not ValidarLenCNPJCPF(ClipText)) or
      (not ValidarCNPJCPFInterno(ClipText)))  then
    raise Exception.Create('CPF/CNPJ colado é inválido.');

  Self.Text := ClipText;
end;

procedure TCpfCnpjDBEdit.WMKEYUP(var Message: TWMPaint);
begin
  CheckForInvalidate;
end;

procedure TCpfCnpjDBEdit.WMPaint(var Message: TWMPaint);
var
  CC: TControlCanvas;
begin
  // Aplica máscara somente quando o controle não está em edição
  if not Focused then
    Mask;

  inherited;

  if (Required) and (Length(Trim(Text)) = 0) then
  begin
    FPaintedRed := True;

    CC := TControlCanvas.Create;
    try
      CC.Control := Self;
      CC.Pen.Color := clRed;
      CC.Pen.Width := 1;
      CC.Rectangle(ClientRect);
    finally
      CC.Free;
    end;
  end
  else
    FPaintedRed := False;
end;

procedure TCpfCnpjDBEdit.WMPaste(var Msg: TWMPaste);
begin
  OutputDebugString(Pchar('TCpfCnpjDBEdit.WMPaste'));
 // if True then
 // else
  inherited;
end;

procedure TCpfCnpjDBEdit.WndProc(var Msg: TMessage);
begin
  if (Msg.Msg = WM_PASTE) then
  begin
    ValidateAndPaste; // Call the custom paste handler
    Msg.Result := 0;
  end
  else
    inherited;
end;

end.
