[CmdletBinding()]
param(
  [switch]$Uninstall,
  [switch]$SkipBuild,
  [string]$DelphiVersion = '20.0',
  [string]$JvclLib = 'C:\DelphiComponents\jvcl-master\jvcl\lib\D26\win32',
  [string]$JclLib = 'C:\DelphiComponents\jcl-master\jcl\lib\d26\win32'
)

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$runtimeSource = Join-Path $root 'Package\CVCVcl.dpk'
$designSource = Join-Path $root 'Package\dclCVCVcl.dpk'
$extrasRuntimeSource = Join-Path $root 'Package\CVCExtras.dpk'
$extrasDesignSource = Join-Path $root 'Package\dclCVCExtras.dpk'
$runtimePackage = Join-Path $root 'Package\CVCVcl.bpl'
$designPackage = Join-Path $root 'Package\dclCVCVcl.bpl'
$extrasRuntimePackage = Join-Path $root 'Package\CVCExtras.bpl'
$extrasDesignPackage = Join-Path $root 'Package\dclCVCExtras.bpl'
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
  New-ItemProperty -Path $knownPackagesKey -Name $extrasDesignPackage -Value 'CVC-VCL - componentes pessoais' -PropertyType String -Force | Out-Null
}

function Remove-KnownPackage {
  if (Test-Path $knownPackagesKey) {
    Remove-ItemProperty -Path $knownPackagesKey -Name $designPackage -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path $knownPackagesKey -Name $extrasDesignPackage -ErrorAction SilentlyContinue
  }
}

function Remove-InstalledPackages {
  $files = @(
    (Join-Path $publicBpl 'CVCVcl.bpl'),
    (Join-Path $publicBpl 'dclCVCVcl.bpl'),
    (Join-Path $publicBpl 'CVCExtras.bpl'),
    (Join-Path $publicBpl 'dclCVCExtras.bpl'),
    (Join-Path $publicDcp 'CVCVcl.dcp'),
    (Join-Path $publicDcp 'dclCVCVcl.dcp'),
    (Join-Path $publicDcp 'CVCExtras.dcp'),
    (Join-Path $publicDcp 'dclCVCExtras.dcp')
  )

  foreach ($file in $files) {
    Remove-Item -LiteralPath $file -Force -ErrorAction SilentlyContinue
  }
}

Test-DelphiClosed

if ($Uninstall) {
  Remove-KnownPackage
  Remove-InstalledPackages
  Write-Host 'CVC-VCL removido da lista de pacotes do Delphi.'
  exit 0
}

$bdsBin = Get-BdsBin

if (-not $SkipBuild) {
  if (-not (Test-Path $runtimeSource) -or -not (Test-Path $designSource) -or
      -not (Test-Path $extrasRuntimeSource) -or -not (Test-Path $extrasDesignSource)) {
    throw 'Fontes dos pacotes CVC-VCL não encontradas.'
  }

  $dcc32 = Join-Path $bdsBin 'DCC32.EXE'
  if (-not (Test-Path $JvclLib)) {
    throw "Biblioteca JVCL não encontrada: $JvclLib"
  }
  if (-not (Test-Path $JclLib)) {
    throw "Biblioteca JCL não encontrada: $JclLib"
  }
  $sourcePaths = @(
    (Join-Path $root 'Source'),
    (Join-Path $root 'Source\CustomBtn'),
    (Join-Path $root 'Source\DbCombo'),
    (Join-Path $root 'Source\EditDialogFireDAC'),
    (Join-Path $root 'Source\PersonDbComboBox'),
    (Join-Path $root 'Source\TTBDateBox'),
    (Join-Path $root 'Package'),
    $JvclLib,
    $JclLib
  ) -join ';'
  Push-Location (Split-Path $runtimeSource)
  try {
    & $dcc32 "-U$sourcePaths" (Split-Path $runtimeSource -Leaf)
    if ($LASTEXITCODE -ne 0) {
      throw 'Falha ao compilar o pacote runtime CVC-VCL.'
    }
    & $dcc32 "-U$sourcePaths" (Split-Path $designSource -Leaf)
    if ($LASTEXITCODE -ne 0) {
      throw 'Falha ao compilar o pacote de design-time CVC-VCL.'
    }
    & $dcc32 "-U$sourcePaths" (Split-Path $extrasRuntimeSource -Leaf)
    if ($LASTEXITCODE -ne 0) {
      throw 'Falha ao compilar o pacote runtime dos componentes pessoais.'
    }
    & $dcc32 "-U$sourcePaths" (Split-Path $extrasDesignSource -Leaf)
  }
  finally {
    Pop-Location
  }
  if ($LASTEXITCODE -ne 0) {
    throw 'Falha ao compilar o pacote de design-time CVC-VCL.'
  }
}

if (-not (Test-Path $runtimePackage) -or -not (Test-Path $designPackage) -or
    -not (Test-Path $extrasRuntimePackage) -or -not (Test-Path $extrasDesignPackage)) {
  throw 'BPLs CVC-VCL não encontrados.'
}

New-Item -ItemType Directory -Path $publicBpl, $publicDcp -Force | Out-Null
Copy-Item (Join-Path $root 'Package\CVCVcl.bpl') (Join-Path $publicBpl 'CVCVcl.bpl') -Force
Copy-Item (Join-Path $root 'Package\dclCVCVcl.bpl') (Join-Path $publicBpl 'dclCVCVcl.bpl') -Force
Copy-Item $extrasRuntimePackage (Join-Path $publicBpl 'CVCExtras.bpl') -Force
Copy-Item $extrasDesignPackage (Join-Path $publicBpl 'dclCVCExtras.bpl') -Force
Copy-Item (Join-Path $root 'Package\CVCVcl.dcp') (Join-Path $publicDcp 'CVCVcl.dcp') -Force
Copy-Item (Join-Path $root 'Package\dclCVCVcl.dcp') (Join-Path $publicDcp 'dclCVCVcl.dcp') -Force
Copy-Item (Join-Path $root 'Package\CVCExtras.dcp') (Join-Path $publicDcp 'CVCExtras.dcp') -Force
Copy-Item (Join-Path $root 'Package\dclCVCExtras.dcp') (Join-Path $publicDcp 'dclCVCExtras.dcp') -Force
$designPackage = Join-Path $publicBpl 'dclCVCVcl.bpl'
Set-KnownPackage
Write-Host "CVC-VCL instalado no Delphi $DelphiVersion."
Write-Host 'Reabra o Delphi para carregar os componentes CVC-VCL.'
