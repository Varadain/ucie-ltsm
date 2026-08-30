$ErrorActionPreference = 'Stop'
$questaHome = 'C:\intelFPGA_lite\questa_fse'
$vsim = Join-Path $questaHome 'win64\vsim.exe'
$seeds = @(101, 202, 303, 404, 505)
$logDir = Join-Path (Get-Location) 'verification\uvm\logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

foreach ($seed in $seeds) {
  $env:QUESTA_HOME = $questaHome
  $env:UVM_TESTNAME = 'sb_random_test'
  $env:SV_SEED = $seed
  $log = Join-Path $logDir "sb_random_seed_$seed.log"
  & $vsim -c -l $log -do scripts/run_uvm.do
  if ($LASTEXITCODE -ne 0) { throw "Seed ${seed}: Questa exited with $LASTEXITCODE" }
  $body = Get-Content -Raw $log
  if ($body -notmatch 'UVM_ERROR\s*:\s*0' -or $body -notmatch 'UVM_FATAL\s*:\s*0') {
    throw "Seed ${seed}: UVM errors detected; see $log"
  }
  Write-Host "PASS sb_random_test seed=$seed"
}
Write-Host "PASS: $($seeds.Count) random seeds, 40 transactions per seed"
