[CmdletBinding()]
param(
  [switch]$Uninstall,
  [switch]$SkipBuild,
  [string]$DelphiVersion = '20.0'
)

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$runtimeSource = Join-Path $root 'Package\CVCVcl.dpk'
$designSource = Join-Path $root 'Package\dclCVCVcl.dpk'
$runtimePackage = Join-Path $root 'Package\CVCVcl.bpl'
$designPackage = Join-Path $root 'Package\dclCVCVcl.bpl'
$publicBpl = Join-Path ${env:PUBLIC} "Documents\Embarcadero\Studio\$DelphiVersion\Bpl"
$publicDcp = Join-Path ${env:PUBLIC} "Documents\Embarcadero\Studio\$DelphiVersion\Dcp"
$knownPackagesKey = "HKCU:\Software\Embarcadero\BDS\$DelphiVersion\Known Packages"

function Get-BdsBin {
  $candidates = @(
    $env:BDSBIN,
    "C:\Program Files (x86)\Embarcadero\Studio\$DelphiVersion\bin",
    "C:\Program Files\Embarcadero\Studio\$DelphiVersion\bin"
  ) | Where-Object { $_ -and (Test-Path (Join-Path $_ 'bds.exe')) }

  if (-not $candidates) {
    throw "Não foi possível localizar o Delphi na versão $DelphiVersion."
  }

  return $candidates[0]
}

function Test-DelphiClosed {
  if (Get-Process -Name bds -ErrorAction SilentlyContinue) {
    throw 'Feche o Delphi antes de instalar ou remover os componentes CVC-VCL.'
  }
}

function Set-KnownPackage {
  if (-not (Test-Path $knownPackagesKey)) {
    New-Item -Path $knownPackagesKey -Force | Out-Null
  }

  # O pacote unificado passa a fornecer também o TDBLookupEdit.
  # Remove somente o registro antigo do mesmo componente para evitar carga duplicada.
  $oldPackages = Get-ItemProperty $knownPackagesKey | ForEach-Object {
    $_.PSObject.Properties | Where-Object {
      $_.Name -match '(?i)DBLookupEdit\.bpl$'
    }
  }
  foreach ($oldPackage in $oldPackages) {
    Remove-ItemProperty -Path $knownPackagesKey -Name $oldPackage.Name -ErrorAction SilentlyContinue
  }

  New-ItemProperty -Path $knownPackagesKey -Name $designPackage -Value 'CVC-VCL - componentes do ERP' -PropertyType String -Force | Out-Null
}

function Remove-KnownPackage {
  if (Test-Path $knownPackagesKey) {
    Remove-ItemProperty -Path $knownPackagesKey -Name $designPackage -ErrorAction SilentlyContinue
  }
}

Test-DelphiClosed
$bdsBin = Get-BdsBin

if ($Uninstall) {
  Remove-KnownPackage
  Write-Host 'CVC-VCL removido da lista de pacotes do Delphi.'
  exit 0
}

if (-not $SkipBuild) {
  if (-not (Test-Path $runtimeSource) -or -not (Test-Path $designSource)) {
    throw 'Fontes dos pacotes CVC-VCL não encontradas.'
  }

  $dcc32 = Join-Path $bdsBin 'DCC32.EXE'
  $jvclLib = "C:\DelphiComponents\jvcl-master\jvcl\lib\D26\win32"
  $jclLib = "C:\DelphiComponents\jcl-master\jcl\lib\d26\win32"
  Push-Location (Split-Path $runtimeSource)
  try {
    & $dcc32 "-U$jvclLib;$jclLib" (Split-Path $runtimeSource -Leaf)
    if ($LASTEXITCODE -ne 0) {
      throw 'Falha ao compilar o pacote runtime CVC-VCL.'
    }
    & $dcc32 "-U$jvclLib;$jclLib;." (Split-Path $designSource -Leaf)
  }
  finally {
    Pop-Location
  }
  if ($LASTEXITCODE -ne 0) {
    throw 'Falha ao compilar o pacote de design-time CVC-VCL.'
  }
}

if (-not (Test-Path $runtimePackage) -or -not (Test-Path $designPackage)) {
  throw 'BPLs CVC-VCL não encontrados.'
}

New-Item -ItemType Directory -Path $publicBpl, $publicDcp -Force | Out-Null
Copy-Item (Join-Path $root 'Package\CVCVcl.bpl') (Join-Path $publicBpl 'CVCVcl.bpl') -Force
Copy-Item (Join-Path $root 'Package\dclCVCVcl.bpl') (Join-Path $publicBpl 'dclCVCVcl.bpl') -Force
Copy-Item (Join-Path $root 'Package\CVCVcl.dcp') (Join-Path $publicDcp 'CVCVcl.dcp') -Force
Copy-Item (Join-Path $root 'Package\dclCVCVcl.dcp') (Join-Path $publicDcp 'dclCVCVcl.dcp') -Force
$designPackage = Join-Path $publicBpl 'dclCVCVcl.bpl'
Set-KnownPackage
Write-Host "CVC-VCL instalado no Delphi $DelphiVersion."
Write-Host 'Reabra o Delphi para carregar os tres componentes.'
