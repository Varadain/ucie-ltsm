param(
  [string]$QuartusBin = 'C:\intelFPGA_lite\23.1std\quartus\bin64',
  [ValidatePattern('^v[0-9]+\.[0-9]+-[a-z0-9-]+$')]
  [string]$Version = 'v0.1-basic-ltssm',
  [ValidateSet('ucie_ltsm', 'ucie_ltsm_fpga')]
  [string]$Project = 'ucie_ltsm',
  [string]$OutputName
)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($OutputName)) {
  $OutputName = if ($Project -eq 'ucie_ltsm_fpga') {
    'ucie_ltsm_fpga_wrapper.vo'
  } else {
    'ucie_ltsm.vo'
  }
}
if ($OutputName -notmatch '^[A-Za-z0-9_.-]+\.vo$') {
  throw "OutputName must be a simple .vo filename: $OutputName"
}
$repoRoot = Split-Path -Parent $PSScriptRoot
$projectDir = Join-Path $repoRoot 'quartus'
$targetDir = Join-Path $repoRoot (Join-Path 'synthesis\quartus\netlists' $Version)
$tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
$stagingDir = Join-Path $tempRoot ("ucie_ltsm_netlist_" + [guid]::NewGuid().ToString('N'))

$quartusSh = Join-Path $QuartusBin 'quartus_sh.exe'
$quartusEda = Join-Path $QuartusBin 'quartus_eda.exe'
foreach ($tool in @($quartusSh, $quartusEda)) {
  if (-not (Test-Path -LiteralPath $tool)) {
    throw "Required Quartus executable not found: $tool"
  }
}

New-Item -ItemType Directory -Force -Path $targetDir, $stagingDir | Out-Null
try {
  Push-Location $projectDir
  try {
    & $quartusSh --flow compile $Project
    if ($LASTEXITCODE -ne 0) { throw "Quartus compilation failed with exit code $LASTEXITCODE" }

    $edaOutput = $stagingDir.Replace('\', '/')
    & $quartusEda --read_settings_files=on --write_settings_files=off $Project --simulation=on --tool=questa_oem --format=verilog --functional=on --output_directory=$edaOutput
    if ($LASTEXITCODE -ne 0) { throw "Quartus netlist export failed with exit code $LASTEXITCODE" }
  } finally {
    Pop-Location
  }

  $generated = Join-Path $stagingDir "$Project.vo"
  if (-not (Test-Path -LiteralPath $generated)) { throw "Expected netlist was not generated: $generated" }
  Copy-Item -LiteralPath $generated -Destination (Join-Path $targetDir $OutputName) -Force
  Write-Output "Exported: $(Join-Path $targetDir $OutputName)"
} finally {
  $resolvedStaging = [IO.Path]::GetFullPath($stagingDir)
  if ($resolvedStaging.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase) -and
      (Split-Path -Leaf $resolvedStaging).StartsWith('ucie_ltsm_netlist_', [StringComparison]::Ordinal)) {
    Remove-Item -LiteralPath $resolvedStaging -Recurse -Force -ErrorAction SilentlyContinue
  }
}
