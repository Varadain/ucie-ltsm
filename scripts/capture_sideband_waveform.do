onerror {quit -code 1}
if {[file exists work]} {vdel -lib work -all}
file mkdir build/waves
vlib work
vlog -sv rtl/ucie_ltsm_pkg.sv rtl/ucie_sb_sequencer.sv verification/tb_ucie_sb_sequencer.sv
vsim -c -voptargs=+acc -assertdebug work.tb_ucie_sb_sequencer
vcd file build/waves/sideband_sequencer.vcd
vcd add sim:/tb_ucie_sb_sequencer/rst_n
vcd add sim:/tb_ucie_sb_sequencer/start
vcd add sim:/tb_ucie_sb_sequencer/abort
vcd add sim:/tb_ucie_sb_sequencer/tx_valid
vcd add sim:/tb_ucie_sb_sequencer/tx_ready
vcd add sim:/tb_ucie_sb_sequencer/tx_message
vcd add sim:/tb_ucie_sb_sequencer/rx_valid
vcd add sim:/tb_ucie_sb_sequencer/rx_message
vcd add sim:/tb_ucie_sb_sequencer/busy
vcd add sim:/tb_ucie_sb_sequencer/retry
vcd add sim:/tb_ucie_sb_sequencer/done
vcd add sim:/tb_ucie_sb_sequencer/protocol_error
run -all
vcd flush
quit -code 0
