onerror {quit -code 1}
if {[file exists work]} {vdel -lib work -all}
file mkdir build/waves
vlib work
vlog -sv rtl/ucie_ltsm_pkg.sv rtl/ucie_sb_sequencer.sv rtl/ucie_lfsr_training_engine.sv \
  rtl/ucie_error_manager.sv rtl/ucie_ltsm.sv rtl/ucie_ltsm_fpga_wrapper.sv \
  verification/tb_ucie_ltsm_fpga_wrapper.sv
vsim -c -voptargs=+acc work.tb_ucie_ltsm_fpga_wrapper
vcd file build/waves/fpga_csr_wrapper.vcd
vcd add sim:/tb_ucie_ltsm_fpga_wrapper/rst_ni
vcd add sim:/tb_ucie_ltsm_fpga_wrapper/fatal_error_i
vcd add sim:/tb_ucie_ltsm_fpga_wrapper/error_handshake_done_i
vcd add sim:/tb_ucie_ltsm_fpga_wrapper/sideband_tx_idle_i
vcd add sim:/tb_ucie_ltsm_fpga_wrapper/csr_valid_i
vcd add sim:/tb_ucie_ltsm_fpga_wrapper/csr_write_i
vcd add sim:/tb_ucie_ltsm_fpga_wrapper/csr_addr_i
vcd add sim:/tb_ucie_ltsm_fpga_wrapper/csr_wdata_i
vcd add sim:/tb_ucie_ltsm_fpga_wrapper/csr_rdata_o
vcd add sim:/tb_ucie_ltsm_fpga_wrapper/csr_ready_o
vcd add sim:/tb_ucie_ltsm_fpga_wrapper/dut/state
vcd add sim:/tb_ucie_ltsm_fpga_wrapper/dut/error_pending
vcd add sim:/tb_ucie_ltsm_fpga_wrapper/dut/handshake_request
vcd add sim:/tb_ucie_ltsm_fpga_wrapper/dut/error_cause
vcd add sim:/tb_ucie_ltsm_fpga_wrapper/dut/error_event_count
vcd add sim:/tb_ucie_ltsm_fpga_wrapper/dut/clear_error_log
run -all
vcd flush
quit -code 0
