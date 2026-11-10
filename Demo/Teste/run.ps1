# Compila (Debug) e executa a bateria; mostra o resultado.
param([switch]$SemCompilar)
$d = Join-Path $PSScriptRoot 'Win32\Debug'
if (-not $SemCompilar) { cmd /c "`"$PSScriptRoot\b.bat`"" | Select-String ' error ' }
Remove-Item "$d\*.txt" -ErrorAction SilentlyContinue
$p = Start-Process "$d\DBLookupEditEnterTeste.exe" -ArgumentList '/auto' -PassThru -WorkingDirectory $d
if (-not $p.WaitForExit(120000)) { $p.Kill(); 'TRAVOU (timeout)' }
Get-Content "$d\DBLookupEditEnterTeste.live.txt" -ErrorAction SilentlyContinue
"exit=$($p.ExitCode)"
