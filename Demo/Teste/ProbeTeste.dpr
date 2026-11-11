program ProbeTeste;
{$APPTYPE CONSOLE}
uses
  System.SysUtils, System.Classes, Data.DB,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf,
  FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async,
  FireDAC.Phys, FireDAC.Phys.FB, FireDAC.Phys.FBDef, FireDAC.Comp.Client,
  FireDAC.DApt, FireDAC.ConsoleUI.Wait;
var
  C: TFDConnection; Q: TFDQuery; L: TStringList; F: TField; N: string; I: Integer;
  Nomes: TArray<string>;
begin
  L := TStringList.Create;
  C := TFDConnection.Create(nil); Q := TFDQuery.Create(nil);
  try
    C.LoginPrompt := False;
    C.Params.Values['DriverID'] := 'FB'; C.Params.Values['Protocol'] := 'TCPIP';
    C.Params.Values['Server'] := 'localhost';
    C.Params.Values['Database'] := 'C:\Bancos\CONTROLEVENDAS\VMTESTE2\VM-TESTE2.FDB';
    C.Params.Values['User_Name'] := 'SYSDBA'; C.Params.Values['Password'] := 'masterkey';
    C.Open;
    Q.Connection := C;
    Q.SQL.Text := 'select * from entrada where identrada = -1';
    Q.Open;
    Nomes := ['NF', 'SERIE', 'IDFORNECEDOR', 'DT_EMISSAO', 'IDENTRADA', 'VR_ENTRADA'];
    for I := 0 to High(Nomes) do
    begin
      N := Nomes[I];
      F := Q.FindField(N);
      if F = nil then L.Add(N + ': nao existe')
      else L.Add(Format('%s: Required=%s ReadOnly=%s AutoGen=%d Size=%d', [N, BoolToStr(F.Required, True), BoolToStr(F.ReadOnly, True), Ord(F.AutoGenerateValue), F.Size]));
    end;
  except
    on E: Exception do L.Add('ERRO ' + E.Message);
  end;
  L.SaveToFile(ChangeFileExt(ParamStr(0), '.txt'));
  L.Free;
end.
