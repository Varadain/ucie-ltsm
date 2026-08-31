package ucie_ltsm_pkg;
  typedef enum logic [3:0] {
    LTSM_RESET      = 4'h0,
    LTSM_SBINIT     = 4'h1,
    LTSM_MBINIT     = 4'h2,
    LTSM_MBTRAIN    = 4'h3,
    LTSM_LINKINIT   = 4'h4,
    LTSM_ACTIVE     = 4'h5,
    LTSM_PHYRETRAIN = 4'h6,
    LTSM_TRAINERROR = 4'h7,
    LTSM_L1L2       = 4'h8
  } ltsm_state_e;

  typedef enum logic [2:0] {
    MBI_PARAM, MBI_CAL, MBI_REPAIRCLK, MBI_REPAIRVAL,
    MBI_REVERSALMB, MBI_REPAIRMB
  } mbinit_state_e;

  typedef enum logic [3:0] {
    MBT_VALVREF, MBT_DATAVREF, MBT_SPEEDIDLE, MBT_TXSELFCAL,
    MBT_RXCLKCAL, MBT_VALTRAINCENTER, MBT_VALTRAINVREF,
    MBT_DATATRAINCENTER1, MBT_DATATRAINVREF, MBT_RXDESKEW,
    MBT_DATATRAINCENTER2, MBT_LINKSPEED, MBT_REPAIR
  } mbtrain_state_e;

  typedef enum logic [1:0] {
    RETRAIN_TXSELFCAL = 2'd0,
    RETRAIN_SPEEDIDLE = 2'd1,
    RETRAIN_REPAIR    = 2'd2
  } retrain_target_e;

  // Transaction-level sideband messages implemented by the v0.2 checkpoint.
  // Additional UCIe training messages can be added without changing the
  // sequencer handshake.
  typedef enum logic [7:0] {
    SB_MSG_NOP              = 8'h00,
    SB_MSG_SBINIT_DONE_REQ  = 8'h01,
    SB_MSG_SBINIT_DONE_RESP = 8'h02,
    SB_MSG_DATACENTER1_START_REQ  = 8'h03,
    SB_MSG_DATACENTER1_START_RESP = 8'h04,
    SB_MSG_DATACENTER1_END_REQ    = 8'h05,
    SB_MSG_DATACENTER1_END_RESP   = 8'h06
  } sb_msg_e;

  typedef enum logic [1:0] {
    DATATRAIN_SB_START,
    DATATRAIN_PATTERN,
    DATATRAIN_SB_END
  } datatrain_phase_e;

  typedef enum logic [2:0] {
    LTSM_ERR_NONE,
    LTSM_ERR_STATE_TIMEOUT,
    LTSM_ERR_SIDEBAND_PROTOCOL,
    LTSM_ERR_LOCAL_FATAL
  } ltsm_error_cause_e;
endpackage
