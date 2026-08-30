onerror {quit -code 1}
if {[file exists work]} {vdel -lib work -all}
vlib work
vlog -sv +incdir+$env(QUESTA_HOME)/verilog_src/uvm-1.1d/src \
  rtl/ucie_ltsm_pkg.sv rtl/ucie_sb_sequencer.sv rtl/ucie_ltsm.sv verification/ucie_ltsm_sva.sv \
  verification/uvm/ucie_ltsm_if.sv verification/uvm/ucie_ltsm_uvm_pkg.sv \
  verification/uvm/tb_ucie_ltsm_uvm.sv
set test nominal_test
if {[info exists env(UVM_TESTNAME)]} {set test $env(UVM_TESTNAME)}
quietly set seed 1
if {[info exists env(SV_SEED)]} {quietly set seed $env(SV_SEED)}
echo "=== Running $test ==="
vsim -c -sv_seed $seed work.tb_ucie_ltsm_uvm +UVM_TESTNAME=$test +UVM_VERBOSITY=UVM_LOW +UVM_NO_RELNOTES
run -all
