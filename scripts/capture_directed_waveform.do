onerror {quit -code 1}
if {[file exists work]} {vdel -lib work -all}
file mkdir build/waves
vlib work
vlog -sv rtl/ucie_ltsm_pkg.sv rtl/ucie_sb_sequencer.sv rtl/ucie_ltsm.sv verification/ucie_ltsm_sva.sv verification/tb_ucie_ltsm.sv
vsim -c -voptargs=+acc -assertdebug work.tb_ucie_ltsm
vcd file build/waves/directed_training.vcd
vcd add sim:/tb_ucie_ltsm/clk
vcd add sim:/tb_ucie_ltsm/rst_n
vcd add sim:/tb_ucie_ltsm/link_train_trigger
vcd add sim:/tb_ucie_ltsm/phase_done
vcd add sim:/tb_ucie_ltsm/rdi_active
vcd add sim:/tb_ucie_ltsm/retrain_req
vcd add sim:/tb_ucie_ltsm/retrain_target
vcd add sim:/tb_ucie_ltsm/fatal_error
vcd add sim:/tb_ucie_ltsm/error_handshake_done
vcd add sim:/tb_ucie_ltsm/state
vcd add sim:/tb_ucie_ltsm/mbi
vcd add sim:/tb_ucie_ltsm/mbt
vcd add sim:/tb_ucie_ltsm/timeout
vcd add sim:/tb_ucie_ltsm/link_up
run -all
vcd flush
quit -code 0
