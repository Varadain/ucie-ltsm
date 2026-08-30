onerror {quit -code 1}
if {[file exists work]} {vdel -lib work -all}
file mkdir build/waves
vlib work
vlog -sv rtl/ucie_lfsr_training_engine.sv verification/tb_ucie_lfsr_training_engine.sv
vsim -c -voptargs=+acc work.tb_ucie_lfsr_training_engine
vcd file build/waves/datatrain_lfsr.vcd
vcd add sim:/tb_ucie_lfsr_training_engine/rst_n
vcd add sim:/tb_ucie_lfsr_training_engine/start
vcd add sim:/tb_ucie_lfsr_training_engine/abort
vcd add sim:/tb_ucie_lfsr_training_engine/rx_valid
vcd add sim:/tb_ucie_lfsr_training_engine/threshold
vcd add sim:/tb_ucie_lfsr_training_engine/rx_pattern
vcd add sim:/tb_ucie_lfsr_training_engine/tx_valid
vcd add sim:/tb_ucie_lfsr_training_engine/tx_pattern
vcd add sim:/tb_ucie_lfsr_training_engine/busy
vcd add sim:/tb_ucie_lfsr_training_engine/done
vcd add sim:/tb_ucie_lfsr_training_engine/pass
vcd add sim:/tb_ucie_lfsr_training_engine/errors
run -all
vcd flush
quit -code 0
