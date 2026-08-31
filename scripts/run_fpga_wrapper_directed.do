onerror {quit -code 1}
if {[file exists work]} {vdel -lib work -all}
vlib work
vlog -sv rtl/ucie_ltsm_pkg.sv rtl/ucie_sb_sequencer.sv rtl/ucie_lfsr_training_engine.sv \
  rtl/ucie_error_manager.sv rtl/ucie_ltsm.sv rtl/ucie_ltsm_fpga_wrapper.sv \
  verification/tb_ucie_ltsm_fpga_wrapper.sv
vsim -c work.tb_ucie_ltsm_fpga_wrapper
run -all
quit -code 0
