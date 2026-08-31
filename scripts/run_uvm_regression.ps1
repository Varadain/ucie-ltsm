$ErrorActionPreference = 'Stop'
$questaHome = 'C:\intelFPGA_lite\questa_fse'
$vsim = Join-Path $questaHome 'win64\vsim.exe'
$tests = @('nominal_test','timeout_test','recovery_test','pm_test',
           'sb_success_test','sb_retry_test','sb_error_test','sb_exhaust_test',
           'recovery_closure_test')
$logDir = Join-Path (Get-Location) 'verification\uvm\logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

foreach ($test in $tests) {
  $env:QUESTA_HOME = $questaHome
  $env:UVM_TESTNAME = $test
  $log = Join-Path $logDir "$test.log"
  & $vsim -c -l $log -do scripts/run_uvm.do
  if ($LASTEXITCODE -ne 0) { throw "${test}: Questa exited with $LASTEXITCODE" }
  $body = Get-Content -Raw $log
  if ($body -notmatch 'UVM_ERROR\s*:\s*0' -or $body -notmatch 'UVM_FATAL\s*:\s*0') {
    throw "${test}: UVM errors detected; see $log"
  }
  Write-Host "PASS $test"
}
Write-Host "PASS: all $($tests.Count) UVM tests"
