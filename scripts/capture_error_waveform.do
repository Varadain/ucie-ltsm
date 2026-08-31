onerror {quit -code 1}
if {[file exists work]} {vdel -lib work -all}
file mkdir build/waves
vlib work
vlog -sv rtl/ucie_ltsm_pkg.sv rtl/ucie_error_manager.sv verification/tb_ucie_error_manager.sv
vsim -c -voptargs=+acc work.tb_ucie_error_manager
vcd file build/waves/error_recovery.vcd
vcd add sim:/tb_ucie_error_manager/rst_n
vcd add sim:/tb_ucie_error_manager/state_timeout
vcd add sim:/tb_ucie_error_manager/sb_error
vcd add sim:/tb_ucie_error_manager/fatal
vcd add sim:/tb_ucie_error_manager/ack
vcd add sim:/tb_ucie_error_manager/clear
vcd add sim:/tb_ucie_error_manager/state
vcd add sim:/tb_ucie_error_manager/pending
vcd add sim:/tb_ucie_error_manager/request
vcd add sim:/tb_ucie_error_manager/hs_timeout
vcd add sim:/tb_ucie_error_manager/enter
vcd add sim:/tb_ucie_error_manager/cause
vcd add sim:/tb_ucie_error_manager/count
run 260 ns
vcd flush
vcd off
run -all
quit -code 0
