program RelLogoTeste;

{ Renderiza o cabecalho do relatorio (so a logo) em PNG com varias estrategias
  e grava em Saida\. Uso: RelLogoTeste.exe <logo.png> }

uses
  Vcl.Forms,
  System.SysUtils,
  System.Classes,
  Vcl.Graphics,
  Vcl.Imaging.pngimage,
  Winapi.GDIPAPI,
  Winapi.GDIPOBJ,
  Winapi.ActiveX,
  ppReport, ppBands, ppCtrls, ppPrnabl, ppClass, ppCache, ppProd, ppComm,
  ppRelatv, ppTypes, ppDevice, ppImageDevice, ppDrwCmd;

const
  CAIXA_L = 2.1;   // largura maxima da caixa, polegadas
  CAIXA_A = 0.7;   // altura maxima da caixa, polegadas

var
  Logo, Pasta: string;

// Reduz/amplia com filtro bicubico de alta qualidade (GDI+), mantendo alfa.
function Reamostrar(const AArquivo: string; ALarg, AAlt: Integer): TPngImage;
var
  Origem: TGPBitmap;
  Destino: TGPBitmap;
  G: TGPGraphics;
  Fluxo: TMemoryStream;
  Adaptador: TStreamAdapter;
  Clsid: TGUID;
  N, Tam: Cardinal;
  Codecs, Pc: PImageCodecInfo;
  I: Integer;
begin
  Origem := TGPBitmap.Create(AArquivo);
  Destino := TGPBitmap.Create(ALarg, AAlt, PixelFormat32bppARGB);
  try
    G := TGPGraphics.Create(Destino);
    try
      G.SetInterpolationMode(InterpolationModeHighQualityBicubic);
      G.SetSmoothingMode(SmoothingModeHighQuality);
      G.SetPixelOffsetMode(PixelOffsetModeHighQuality);
      G.DrawImage(Origem, 0, 0, ALarg, AAlt);
    finally
      G.Free;
    end;
    GetImageEncodersSize(N, Tam);
    GetMem(Codecs, Tam);
    try
      GetImageEncoders(N, Tam, Codecs);
      Pc := Codecs;
      for I := 0 to Integer(N) - 1 do
      begin
        if string(Pc^.MimeType) = 'image/png' then
          Clsid := Pc^.Clsid;
        Inc(Pc);
      end;
    finally
      FreeMem(Codecs);
    end;
    Fluxo := TMemoryStream.Create;
    try
      Adaptador := TStreamAdapter.Create(Fluxo);
      Destino.Save(Adaptador, Clsid);
      Fluxo.Position := 0;
      Result := TPngImage.Create;
      Result.LoadFromStream(Fluxo);
    finally
      Fluxo.Free;
    end;
  finally
    Destino.Free;
    Origem.Free;
  end;
end;

procedure Gerar(ANome: string; AAspecto: Boolean; ADirectDraw: Boolean;
  AManter: Boolean; APixelsPorPolegada: Integer);
var
  R: TppReport;
  Titulo: TppTitleBand;
  Det: TppDetailBand;
  Img: TppImage;
  Png: TPngImage;
  Original: TPngImage;
  L, A: Double;
  Prop: Double;
begin
  Original := TPngImage.Create;
  try
    Original.LoadFromFile(Logo);
    Prop := Original.Width / Original.Height;
  finally
    Original.Free;
  end;

  L := CAIXA_L;
  A := CAIXA_A;
  if AAspecto then
  begin
    // caixa na proporcao real da logo, dentro de 2,1 x 0,7
    A := L / Prop;
    if A > CAIXA_A then
    begin
      A := CAIXA_A;
      L := A * Prop;
    end;
  end;

  R := TppReport.Create(nil);
  try
    R.DeviceType := 'PNG';
    R.TextFileName := Pasta + ANome + '.png';
    R.ShowPrintDialog := False;
    R.PrinterSetup.PaperName := 'Letter';
    Titulo := TppTitleBand(R.AddBand(btTitle, 0));
    Titulo.Height := 1.1;
    Det := TppDetailBand(R.AddBand(btDetail, 0));
    Det.Height := 0.3;

    Img := TppImage.Create(R);
    Img.Band := Titulo;
    Img.Left := 0.225;
    Img.Top := 0.0301;
    Img.Width := L;
    Img.Height := A;
    Img.Stretch := True;
    Img.MaintainAspectRatio := AManter;
    Img.DirectDraw := ADirectDraw;

    if APixelsPorPolegada > 0 then
    begin
      Png := Reamostrar(Logo, Round(L * APixelsPorPolegada), Round(A * APixelsPorPolegada));
      try
        Img.Picture.Graphic := Png;
      finally
        Png.Free;
      end;
    end
    else
      Img.Picture.LoadFromFile(Logo);

    R.Print;
  finally
    R.Free;
  end;
end;

begin
  Application.Initialize;
  Logo := ParamStr(1);
  Pasta := ExtractFilePath(ParamStr(0)) + 'Saida\';
  ForceDirectories(Pasta);
  try
    Gerar('v0_atual',            False, False, False, 0);
    Gerar('v1_proporcao',        True,  False, True,  0);
    Gerar('v2_proporcao_direct', True,  True,  True,  0);
    Gerar('v3_prescaled_192',    True,  False, True,  192);
    Gerar('v4_prescaled_384',    True,  False, True,  384);
    Gerar('v5_prescaled_192_direct', True, True, True, 192);
  except
    on E: Exception do
    begin
      with TStringList.Create do
      try
        Add(E.ClassName + ': ' + E.Message);
        SaveToFile(Pasta + 'erro.txt');
      finally
        Free;
      end;
      Halt(1);
    end;
  end;
end.
