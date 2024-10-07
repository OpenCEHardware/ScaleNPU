package hs_npu_pkg;

  typedef logic signed [31:0] word;
  typedef logic signed [15:0] short;
  typedef logic [31:0] uword;


  typedef enum logic [2:0] {
    IDLE = 3'b000,
    LOADING_WEIGHTS = 3'b001,
    LOADING_INPUTS = 3'b010,
    LOADING_BIAS = 3'b011,
    LOADING_SUMS = 3'b100,
    READY_TO_COMPUTE = 3'b101,
    COMPUTING = 3'b110,
    SAVING = 3'b111
  } loading_state_t;


endpackage : hs_npu_pkg
