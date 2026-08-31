onerror {quit -code 1}
if {[file exists work]} {vdel -lib work -all}
vlib work
vlog -sv rtl/ucie_ltsm_pkg.sv rtl/ucie_error_manager.sv verification/tb_ucie_error_manager.sv
vsim -c -assertdebug work.tb_ucie_error_manager
run -all
quit -code 0
