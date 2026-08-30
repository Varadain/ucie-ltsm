onerror {quit -code 1}
if {[file exists work]} {vdel -lib work -all}
vlib work
vlog -sv rtl/ucie_lfsr_training_engine.sv verification/tb_ucie_lfsr_training_engine.sv
vsim -c -assertdebug work.tb_ucie_lfsr_training_engine
run -all
quit -code 0
