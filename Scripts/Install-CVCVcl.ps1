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
$publicHpp = Join-Path ${env:PUBLIC} "Documents\Embarcadero\Studio\$DelphiVersion\hpp\Win32"
$publicLib = Join-Path ${env:PUBLIC} "Documents\Embarcadero\Studio\$DelphiVersion\lib\Win32"
$knownPackagesKey = "HKCU:\Software\Embarcadero\BDS\$DelphiVersion\Known Packages"
$disabledPackagesKey = "HKCU:\Software\Embarcadero\BDS\$DelphiVersion\Disabled Packages"
$envOptionsPath = Join-Path ${env:APPDATA} "Embarcadero\BDS\$DelphiVersion\EnvOptions.proj"
$cvcSourcePaths = @(
  (Join-Path $root 'Source'),
  (Join-Path $root 'Source\CVCDBEdit'),
  (Join-Path $root 'Source\CVCDateEdit'),
  (Join-Path $root 'Source\CVCValidateEdit'),
  (Join-Path $root 'Source\CpfCnpjDBEdit'),
  (Join-Path $root 'Source\DBLookupEdit'),
  (Join-Path $root 'Source\CustomBtn'),
  (Join-Path $root 'Source\DbCombo'),
  (Join-Path $root 'Source\EditDialogFireDAC'),
  (Join-Path $root 'Source\DBPersonComboBox'),
  (Join-Path $root 'Source\DateBox')
) -join ';'

function Get-BdsBin {
  $candidates = @(
    $env:BDSBIN,
    "C:\Program Files (x86)\Embarcadero\Studio\$DelphiVersion\bin",
    "C:\Program Files\Embarcadero\Studio\$DelphiVersion\bin"
  ) | Where-Object { $_ -and (Test-Path (Join-Path $_ 'bds.exe')) }

  if (-not $candidates) {
    throw "Não foi possível localizar o Delphi na versão $DelphiVersion."
  }

  # Em PowerShell 7 uma string escalar indexada por [0] retorna o primeiro
  # caractere ("C"), e não o primeiro item do conjunto de candidatos.
  return @($candidates)[0]
}

function Test-DelphiClosed {
  if (Get-Process -Name bds -ErrorAction SilentlyContinue) {
    throw 'Feche o Delphi antes de instalar ou remover os componentes CVC-VCL.'
  }
}

function Update-DelphiLibraryPath {
  if (-not (Test-Path -LiteralPath $envOptionsPath)) {
    return
  }

  $bytes = [IO.File]::ReadAllBytes($envOptionsPath)
  $hasBom = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and
    $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
  $encoding = [Text.UTF8Encoding]::new($hasBom)
  $content = if ($hasBom) {
    $encoding.GetString($bytes, 3, $bytes.Length - 3)
  } else {
    [Text.Encoding]::UTF8.GetString($bytes)
  }

  foreach ($legacyPath in @(
    'C:\DelphiComponents\TTBDateBox',
    'C:\DelphiComponents\Person\PesonDbCombobox',
    'C:\DelphiComponents\DBLookupEditComponent\Source',
    'C:\DelphiComponents\CustomBtn',
    'C:\DelphiComponents\DbCombo'
  )) {
    $content = $content.Replace("$legacyPath;", '').Replace($legacyPath, '')
  }

  $content = [regex]::Replace($content, '(?s)(<DelphiLibraryPath>)(.*?)(</DelphiLibraryPath>)', {
    param($match)
    $paths = $match.Groups[2].Value
    if ($paths -notmatch [regex]::Escape((Join-Path $root 'Source'))) {
      $paths = "$cvcSourcePaths;$paths"
    }
    "$($match.Groups[1].Value)$paths$($match.Groups[3].Value)"
  })

  [IO.File]::WriteAllText($envOptionsPath, $content, [Text.UTF8Encoding]::new($true))
}

function Set-KnownPackage {
  if (-not (Test-Path $knownPackagesKey)) {
    New-Item -Path $knownPackagesKey -Force | Out-Null
  }

  # TTBDateBox foi substituido pelo componente DateBox do CVC-VCL.
  # Limpa referencias do pacote antigo para o Delphi nao tentar carrega-lo
  # ao abrir um projeto ou reconstruir a paleta de componentes.
  $legacyPackageNames = @(
    'DateBox.bpl',
    'dclDateBox.bpl',
    'TTBDateBox.bpl',
    'dclTTBDateBox.bpl',
    'PK_PERSONDBCOMBOBOX.bpl',
    'dclPK_PERSONDBCOMBOBOX.bpl',
    'CpfCnpjDBEdit.bpl',
    'dclCpfCnpjDBEdit.bpl',
    'CustomBTN.bpl',
    'dclCustomBTN.bpl',
    'VclValueCombobox.bpl',
    'dclVclValueCombobox.bpl',
    'DBLookupEdit.bpl',
    'dclDBLookupEdit.bpl'
  )
  $knownProperties = Get-ItemProperty $knownPackagesKey | ForEach-Object {
    $_.PSObject.Properties | Where-Object {
      $legacyPackageNames -contains [IO.Path]::GetFileName($_.Name)
    }
  }
  foreach ($legacyPackage in $knownProperties) {
    Remove-ItemProperty -Path $knownPackagesKey -Name $legacyPackage.Name -ErrorAction SilentlyContinue
  }

  # O Delphi também mantém uma lista separada dos pacotes que falharam ao
  # carregar. Se ela conservar um BPL antigo, a IDE tenta carregá-lo de novo
  # na próxima inicialização, mesmo que Known Packages esteja correto.
  if (Test-Path $disabledPackagesKey) {
    $disabledProperties = Get-ItemProperty $disabledPackagesKey | ForEach-Object {
      $_.PSObject.Properties | Where-Object {
        $legacyPackageNames -contains [IO.Path]::GetFileName($_.Name)
      }
    }
    foreach ($disabledPackage in $disabledProperties) {
      Remove-ItemProperty -Path $disabledPackagesKey -Name $disabledPackage.Name -ErrorAction SilentlyContinue
    }
  }

  $packageCacheKey = "HKCU:\Software\Embarcadero\BDS\$DelphiVersion\Package Cache"
  foreach ($legacyPackageName in $legacyPackageNames) {
    Remove-Item -LiteralPath (Join-Path $packageCacheKey $legacyPackageName) -Recurse -Force -ErrorAction SilentlyContinue
  }

  # O cache também precisa apontar para os BPLs públicos; caso contrário o
  # Delphi pode reintroduzir a cópia do repositório na próxima inicialização.
  $extrasCacheKey = Join-Path $packageCacheKey 'dclCVCExtras.bpl'
  if (Test-Path $extrasCacheKey) {
    $packageGroup = [string](Get-ItemProperty $extrasCacheKey).'Package Group'
    $packageGroup = $packageGroup -replace [regex]::Escape((Join-Path $root 'Package\dclCVCExtras.bpl')), (Join-Path $publicBpl 'dclCVCExtras.bpl')
    Set-ItemProperty -Path $extrasCacheKey -Name 'Package Group' -Value $packageGroup
  }

  $paletteCacheKey = "HKCU:\Software\Embarcadero\BDS\$DelphiVersion\Palette\Cache"
  foreach ($legacyPackageName in $legacyPackageNames) {
    Remove-Item -LiteralPath (Join-Path $paletteCacheKey $legacyPackageName) -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath (Join-Path $paletteCacheKey $legacyPackageName.ToLowerInvariant()) -Recurse -Force -ErrorAction SilentlyContinue
  }

  # CVCVcl.bpl e pacote de runtime; seus componentes nao podem ficar
  # registrados tambem no cache do pacote de design.
  Remove-Item -LiteralPath (Join-Path $packageCacheKey 'CVCVcl.bpl\Components') -Recurse -Force -ErrorAction SilentlyContinue
  Remove-Item -LiteralPath (Join-Path $paletteCacheKey 'CVCVcl.bpl') -Recurse -Force -ErrorAction SilentlyContinue
  Remove-Item -LiteralPath (Join-Path $paletteCacheKey 'cvcvcl.bpl') -Recurse -Force -ErrorAction SilentlyContinue

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

  # Mantém somente uma entrada para cada pacote de design-time. Durante as
  # instalações anteriores o mesmo dclCVCExtras.bpl podia ficar registrado
  # tanto na pasta do repositório quanto na pasta pública do Delphi.
  $currentDesignPackageNames = @('dclCVCVcl.bpl', 'dclCVCExtras.bpl')
  $duplicateDesignPackages = Get-ItemProperty $knownPackagesKey | ForEach-Object {
    $_.PSObject.Properties | Where-Object {
      $currentDesignPackageNames -contains [IO.Path]::GetFileName($_.Name)
    }
  }
  foreach ($duplicateDesignPackage in $duplicateDesignPackages) {
    Remove-ItemProperty -Path $knownPackagesKey -Name $duplicateDesignPackage.Name -ErrorAction SilentlyContinue
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
  $legacyArtifactNames = @('DateBox', 'TTBDateBox', 'PK_PERSONDBCOMBOBOX', 'CpfCnpjDBEdit', 'CustomBTN', 'VclValueCombobox', 'DBLookupEdit')
  foreach ($directory in @($publicDcp, $publicHpp, $publicLib)) {
    foreach ($legacyArtifactName in $legacyArtifactNames) {
      Get-ChildItem -LiteralPath $directory -File -Filter "$legacyArtifactName*" -ErrorAction SilentlyContinue |
        Remove-Item -Force -ErrorAction SilentlyContinue
    }
  }

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
    (Join-Path $root 'Source\DBPersonComboBox'),
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
$extrasDesignPackage = Join-Path $publicBpl 'dclCVCExtras.bpl'
Update-DelphiLibraryPath
Set-KnownPackage
Write-Host "CVC-VCL instalado no Delphi $DelphiVersion."
Write-Host 'Reabra o Delphi para carregar os componentes CVC-VCL.'
