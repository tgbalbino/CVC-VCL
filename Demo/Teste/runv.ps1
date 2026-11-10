# Uso: runv.ps1 [-Exe VendaEnterTeste|VendaEnterOrig] [-Embed]
param([string]$Exe = 'VendaEnterTeste', [switch]$Embed, [switch]$Entrada, [switch]$Fix)
$d = Join-Path $PSScriptRoot 'Win32\Debug'
Remove-Item "$d\$Exe.venda.txt" -ErrorAction SilentlyContinue
$args = @('/auto'); if ($Embed) { $args += '/embed' }; if ($Entrada) { $args += '/entrada' }; if ($Fix) { $args += '/fix' }
$p = Start-Process "$d\$Exe.exe" -ArgumentList $args -PassThru -WorkingDirectory $d
if (-not $p.WaitForExit(90000)) { $p.Kill(); 'TRAVOU (timeout)' }
Get-Content "$d\$Exe.venda.txt" -ErrorAction SilentlyContinue
"exit=$($p.ExitCode)"
