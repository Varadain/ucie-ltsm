$ErrorActionPreference='Stop'
$questaHome='C:\intelFPGA_lite\questa_fse'; $vsim=Join-Path $questaHome 'win64\vsim.exe'
$seeds=@(1201,1302,1403,1504,1605)
$logDir=Join-Path (Get-Location) 'verification\uvm\logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
foreach($seed in $seeds){
  $env:QUESTA_HOME=$questaHome;$env:UVM_TESTNAME='recovery_random_test';$env:SV_SEED=$seed
  $log=Join-Path $logDir "recovery_random_seed_$seed.log"
  & $vsim -c -l $log -do scripts/run_uvm.do
  if($LASTEXITCODE -ne 0){throw "Seed ${seed}: Questa exited with $LASTEXITCODE"}
  $body=Get-Content -Raw $log
  if($body -notmatch 'UVM_ERROR\s*:\s*0' -or $body -notmatch 'UVM_FATAL\s*:\s*0'){
    throw "Seed ${seed}: UVM errors detected; see $log"
  }
  Write-Host "PASS recovery_random_test seed=$seed"
}
Write-Host "PASS: $($seeds.Count) recovery seeds, 36 trials per seed"
