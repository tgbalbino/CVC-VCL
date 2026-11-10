# Compila e roda todas as baterias do DBLookupEdit / Enter / validacao.
# Precisa de sessao com area de trabalho (PowerShell normal, nao o Git Bash).
param([switch]$SemCompilar)
$t = $PSScriptRoot
$d = Join-Path $t 'Win32\Debug'
if (-not $SemCompilar) {
  foreach ($b in 'b','bv','bval') { cmd /c "`"$t\$b.bat`"" | Select-String ' error ' }
}
function Rodar([string]$Exe, [string]$Args1, [string]$Saida) {
  $arq = Join-Path $d $Saida
  if (Test-Path $arq) { Remove-Item $arq }
  if ($Args1) { $p = Start-Process (Join-Path $d "$Exe.exe") -ArgumentList $Args1 -PassThru -WorkingDirectory $d }
  else { $p = Start-Process (Join-Path $d "$Exe.exe") -PassThru -WorkingDirectory $d }
  if (-not $p.WaitForExit(120000)) { $p.Kill(); "$Exe TRAVOU" }
  $r = (Get-Content $arq -ErrorAction SilentlyContinue | Select-String 'Resultado|RESULTADO|FALHA|EXCE') -join ' | '
  "{0} {1} exit={2}  {3}" -f $Exe, $Args1, $p.ExitCode, $r
}
Rodar 'DBLookupEditEnterTeste' '/auto' 'DBLookupEditEnterTeste.live.txt'
Rodar 'ValidTeste' '' 'ValidTeste.txt'
foreach ($m in '/embed /fix','/embed /entrada /fix','/fix','/entrada /fix') {
  Rodar 'VendaEnterTeste' "/auto $m" 'VendaEnterTeste.venda.txt'
}
