$ErrorActionPreference='Stop'
$questaHome='C:\intelFPGA_lite\questa_fse';$vsim=Join-Path $questaHome 'win64\vsim.exe'
$seeds=@(1701,1802,1903,2004,2105)
$logDir=Join-Path (Get-Location) 'verification\uvm\logs'
New-Item -ItemType Directory -Force -Path $logDir|Out-Null
foreach($seed in $seeds){
  $env:QUESTA_HOME=$questaHome;$env:SV_SEED=$seed
  $log=Join-Path $logDir "integrated_random_seed_$seed.log"
  & $vsim -c -l $log -do scripts/run_integrated_uvm.do
  if($LASTEXITCODE -ne 0){throw "Seed $seed Questa exit $LASTEXITCODE"}
  $body=Get-Content -Raw $log
  if($body -notmatch 'UVM_ERROR\s*:\s*0' -or $body -notmatch 'UVM_FATAL\s*:\s*0'){throw "Seed $seed UVM errors"}
  Write-Host "PASS integrated_test seed=$seed"
}
Write-Host "PASS: $($seeds.Count) integrated seeds, 36 trials per seed"
