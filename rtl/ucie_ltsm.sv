module ucie_ltsm #(
  parameter int unsigned CLK_HZ       = 80_000_000,
  parameter int unsigned RESET_MIN_US = 4_000,
  parameter int unsigned TIMEOUT_US   = 8_000,
  parameter int unsigned SB_RESPONSE_TIMEOUT_CYCLES = 256,
  parameter int unsigned SB_MAX_RETRIES = 1,
  parameter int unsigned DATATRAIN_SAMPLE_COUNT = 4096
) (
  input  logic clk_i,
  input  logic rst_ni,

  input  logic supplies_stable_i,
  input  logic sideband_clk_ok_i,
  input  logic internal_clks_ok_i,
  input  logic firmware_reset_i,
  input  logic link_train_trigger_i,
  input  logic phase_done_i,
  input  logic stall_i,
  input  logic fatal_error_i,
  input  logic error_handshake_done_i,
  input  logic error_escalated_i,
  input  logic sideband_tx_idle_i,
  input  logic rdi_active_i,
  input  logic retrain_req_i,
  input  ucie_ltsm_pkg::retrain_target_e retrain_target_i,
  input  logic pm_l1_req_i,
  input  logic pm_l2_req_i,
  input  logic pm_exit_i,
  input  logic clear_error_log_i,

  output logic                   sb_tx_valid_o,
  output ucie_ltsm_pkg::sb_msg_e sb_tx_message_o,
  input  logic                   sb_tx_ready_i,
  input  logic                   sb_rx_valid_i,
  input  ucie_ltsm_pkg::sb_msg_e sb_rx_message_i,
  output logic                   sb_busy_o,
  output logic                   sb_protocol_error_o,
  output logic                   sb_retry_o,

  output logic        train_tx_valid_o,
  output logic [15:0] train_tx_pattern_o,
  input  logic        train_rx_valid_i,
  input  logic [15:0] train_rx_pattern_i,
  input  logic [15:0] train_error_threshold_i,
  output logic        train_busy_o,
  output logic        train_done_o,
  output logic        train_pass_o,
  output logic [15:0] train_error_count_o,

  output logic error_pending_o,
  output logic trainerror_handshake_request_o,
  output logic error_handshake_timeout_o,
  output ucie_ltsm_pkg::ltsm_error_cause_e error_cause_o,
  output logic [15:0] error_event_count_o,

  output ucie_ltsm_pkg::ltsm_state_e state_o,
  output ucie_ltsm_pkg::mbinit_state_e mbinit_state_o,
  output ucie_ltsm_pkg::mbtrain_state_e mbtrain_state_o,
  output logic timeout_o,
  output logic link_up_o,
  output logic mainband_tristate_o,
  output logic sideband_enable_o
);
  import ucie_ltsm_pkg::*;

  localparam longint unsigned RESET_TICKS_RAW = (longint'(CLK_HZ) * RESET_MIN_US) / 1_000_000;
  localparam longint unsigned TIMEOUT_TICKS_RAW = (longint'(CLK_HZ) * TIMEOUT_US) / 1_000_000;
  localparam longint unsigned RESET_TICKS = (RESET_TICKS_RAW < 1) ? 1 : RESET_TICKS_RAW;
  localparam longint unsigned TIMEOUT_TICKS = (TIMEOUT_TICKS_RAW < 1) ? 1 : TIMEOUT_TICKS_RAW;
  localparam int unsigned TIMER_W = $clog2(((RESET_TICKS > TIMEOUT_TICKS) ? RESET_TICKS : TIMEOUT_TICKS) + 1);

  ltsm_state_e state_q, state_d;
  mbinit_state_e mbi_q, mbi_d;
  mbtrain_state_e mbt_q, mbt_d;
  logic [TIMER_W-1:0] timer_q;
  logic state_changed, substate_changed, timeout_enable, reset_min_met;
  logic sb_start, sb_done;
  logic train_start;
  logic enter_trainerror;

  assign sb_start = (state_q == LTSM_SBINIT) && !sb_busy_o && !sb_done;

  ucie_sb_sequencer #(
    .RESPONSE_TIMEOUT_CYCLES(SB_RESPONSE_TIMEOUT_CYCLES),
    .MAX_RETRIES(SB_MAX_RETRIES)
  ) u_sb_sequencer (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .start_i(sb_start),
    .abort_i(state_q != LTSM_SBINIT),
    .request_i(SB_MSG_SBINIT_DONE_REQ),
    .expected_response_i(SB_MSG_SBINIT_DONE_RESP),
    .tx_valid_o(sb_tx_valid_o),
    .tx_message_o(sb_tx_message_o),
    .tx_ready_i(sb_tx_ready_i),
    .rx_valid_i(sb_rx_valid_i),
    .rx_message_i(sb_rx_message_i),
    .busy_o(sb_busy_o),
    .done_o(sb_done),
    .protocol_error_o(sb_protocol_error_o),
    .retry_o(sb_retry_o)
  );

  assign train_start = (state_q == LTSM_MBTRAIN) &&
                       (mbt_q == MBT_DATATRAINCENTER1) &&
                       !train_busy_o && !train_done_o;

  ucie_lfsr_training_engine #(
    .SAMPLE_COUNT(DATATRAIN_SAMPLE_COUNT)
  ) u_lfsr_training_engine (
    .clk_i(clk_i), .rst_ni(rst_ni), .start_i(train_start),
    .abort_i((state_q != LTSM_MBTRAIN) || (mbt_q != MBT_DATATRAINCENTER1)),
    .error_threshold_i(train_error_threshold_i),
    .tx_valid_o(train_tx_valid_o), .tx_pattern_o(train_tx_pattern_o),
    .rx_valid_i(train_rx_valid_i), .rx_pattern_i(train_rx_pattern_i),
    .busy_o(train_busy_o), .done_o(train_done_o), .pass_o(train_pass_o),
    .error_count_o(train_error_count_o)
  );

  ucie_error_manager #(
    .HANDSHAKE_TIMEOUT_CYCLES(TIMEOUT_TICKS)
  ) u_error_manager (
    .clk_i(clk_i), .rst_ni(rst_ni), .state_i(state_q),
    .state_timeout_i(timeout_o), .sideband_protocol_error_i(sb_protocol_error_o),
    .local_fatal_error_i(fatal_error_i), .handshake_done_i(error_handshake_done_i),
    .clear_log_i(clear_error_log_i), .pending_o(error_pending_o),
    .handshake_request_o(trainerror_handshake_request_o),
    .handshake_timeout_o(error_handshake_timeout_o),
    .enter_trainerror_o(enter_trainerror), .cause_o(error_cause_o),
    .event_count_o(error_event_count_o)
  );

  assign state_o = state_q;
  assign mbinit_state_o = mbi_q;
  assign mbtrain_state_o = mbt_q;
  assign state_changed = (state_q != state_d);
  assign substate_changed = (mbi_q != mbi_d) || (mbt_q != mbt_d);
  assign reset_min_met = (timer_q >= RESET_TICKS-1);
  assign timeout_enable = (state_q != LTSM_RESET) && (state_q != LTSM_ACTIVE) &&
                          (state_q != LTSM_L1L2) && (state_q != LTSM_TRAINERROR);
  assign timeout_o = timeout_enable && (timer_q >= TIMEOUT_TICKS-1);
  assign link_up_o = (state_q == LTSM_ACTIVE);
  assign mainband_tristate_o = (state_q == LTSM_RESET) || (state_q == LTSM_SBINIT) ||
                               (state_q == LTSM_TRAINERROR) || (state_q == LTSM_L1L2);
  assign sideband_enable_o = (state_q != LTSM_RESET) || sideband_clk_ok_i;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      state_q <= LTSM_RESET;
      mbi_q   <= MBI_PARAM;
      mbt_q   <= MBT_VALVREF;
      timer_q <= '0;
    end else begin
      state_q <= state_d;
      mbi_q   <= mbi_d;
      mbt_q   <= mbt_d;
      if (state_changed || substate_changed || stall_i)
        timer_q <= '0;
      else if (timer_q != {TIMER_W{1'b1}})
        timer_q <= timer_q + 1'b1;
    end
  end

  always_comb begin
    state_d = state_q;
    mbi_d = mbi_q;
    mbt_d = mbt_q;

    if (enter_trainerror) begin
      state_d = LTSM_TRAINERROR;
    end else begin
      unique case (state_q)
        LTSM_RESET: begin
          mbi_d = MBI_PARAM;
          mbt_d = MBT_VALVREF;
          if (reset_min_met && supplies_stable_i && sideband_clk_ok_i &&
              internal_clks_ok_i && !firmware_reset_i && link_train_trigger_i)
            state_d = LTSM_SBINIT;
        end
        LTSM_SBINIT: if (phase_done_i || sb_done) begin
          state_d = LTSM_MBINIT;
          mbi_d = MBI_PARAM;
        end
        LTSM_MBINIT: if (phase_done_i && !stall_i) begin
          unique case (mbi_q)
            MBI_PARAM:     mbi_d = MBI_CAL;
            MBI_CAL:       mbi_d = MBI_REPAIRCLK;
            MBI_REPAIRCLK: mbi_d = MBI_REPAIRVAL;
            MBI_REPAIRVAL: mbi_d = MBI_REVERSALMB;
            MBI_REVERSALMB:mbi_d = MBI_REPAIRMB;
            default: begin state_d = LTSM_MBTRAIN; mbt_d = MBT_VALVREF; end
          endcase
        end
        LTSM_MBTRAIN: if (phase_done_i ||
                          ((mbt_q == MBT_DATATRAINCENTER1) && train_done_o && train_pass_o)) begin
          unique case (mbt_q)
            MBT_VALVREF:          mbt_d = MBT_DATAVREF;
            MBT_DATAVREF:         mbt_d = MBT_SPEEDIDLE;
            MBT_SPEEDIDLE:        mbt_d = MBT_TXSELFCAL;
            MBT_TXSELFCAL:        mbt_d = MBT_RXCLKCAL;
            MBT_RXCLKCAL:         mbt_d = MBT_VALTRAINCENTER;
            MBT_VALTRAINCENTER:   mbt_d = MBT_VALTRAINVREF;
            MBT_VALTRAINVREF:     mbt_d = MBT_DATATRAINCENTER1;
            MBT_DATATRAINCENTER1: mbt_d = MBT_DATATRAINVREF;
            MBT_DATATRAINVREF:    mbt_d = MBT_RXDESKEW;
            MBT_RXDESKEW:         mbt_d = MBT_DATATRAINCENTER2;
            MBT_DATATRAINCENTER2: mbt_d = MBT_LINKSPEED;
            MBT_LINKSPEED:        mbt_d = MBT_REPAIR;
            default:              state_d = LTSM_LINKINIT;
          endcase
        end
        LTSM_LINKINIT: if (rdi_active_i) state_d = LTSM_ACTIVE;
        LTSM_ACTIVE: begin
          if (retrain_req_i) state_d = LTSM_PHYRETRAIN;
          else if (pm_l1_req_i || pm_l2_req_i) state_d = LTSM_L1L2;
        end
        LTSM_PHYRETRAIN: if (phase_done_i) begin
          state_d = LTSM_MBTRAIN;
          unique case (retrain_target_i)
            RETRAIN_SPEEDIDLE: mbt_d = MBT_SPEEDIDLE;
            RETRAIN_REPAIR:    mbt_d = MBT_REPAIR;
            default:           mbt_d = MBT_TXSELFCAL;
          endcase
        end
        LTSM_TRAINERROR:
          if (!error_escalated_i && sideband_tx_idle_i) state_d = LTSM_RESET;
        LTSM_L1L2: if (pm_exit_i) begin
          if (pm_l2_req_i) state_d = LTSM_RESET;
          else begin state_d = LTSM_MBTRAIN; mbt_d = MBT_SPEEDIDLE; end
        end
        default: state_d = LTSM_RESET;
      endcase
    end
  end
endmodule
