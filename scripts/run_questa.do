onerror {quit -code 1}
if {[file exists work]} {vdel -lib work -all}
vlib work
vlog -sv rtl/ucie_ltsm_pkg.sv rtl/ucie_sb_sequencer.sv rtl/ucie_lfsr_training_engine.sv rtl/ucie_ltsm.sv verification/ucie_ltsm_sva.sv verification/tb_ucie_ltsm.sv
vsim -c -assertdebug work.tb_ucie_ltsm
run -all
quit -code 0
