module hs_npu_memory_interface
  import hs_npu_pkg::*;
#(
    parameter logic [2:0] BURST_SIZE = 2,  // 2^2 --> 4 bytes -> 32 bit words per transfers
    parameter logic [7:0] BURST_LEN  = 1   // 1+1 = 2, 32 bit word transfers
) (
    input logic clk,
    input logic rst_n,

    // Control signals from memory ordering
    output logic mem_valid_o,
    output logic mem_ready_o,
    input  logic mem_read_ready_i,
    input  logic mem_write_valid_i,
    input  logic mem_invalidate,

    // Data matrices to/from memory
    input  uword memory_data_in [BURST_SIZE],
    output uword memory_data_out[BURST_SIZE],
    input  uword request_address,

    // AXI4 burst interface
    axib_if.m axi
);

  // Internal registers and signals
  typedef enum logic [2:0] {
    IDLE,
    READ,
    WRITE,
    READ_WAIT
  } state_t;
  state_t state, next_state;

  // Write and read data tracking
  logic clear_done, aw_done, w_done;
  logic [$clog2(BURST_LEN+1)-1:0] burst_counter;  // To track burst transfers
  logic [$clog2(BURST_LEN+1)-1:0] burst_counter_ff;  // To track burst transfers

  // Fixed AXI4 Burst signal
  localparam logic [1:0] INCR = 1;
  localparam logic [3:0] STRB = 4'b1111;

  assign axi.arid    = '0;
  assign axi.awid    = '0;
  assign axi.arburst = INCR;
  assign axi.awburst = INCR;
  assign axi.arsize  = BURST_SIZE;
  assign axi.awsize  = BURST_SIZE;
  assign axi.arlen   = BURST_LEN;
  assign axi.awlen   = BURST_LEN;
  assign axi.wstrb   = STRB;
  assign axi.bready  = 1;

  logic read;
  logic mem_valid_o_comb;
  uword memory_data_in_ff  [BURST_SIZE];

  // Control logic for read/write requests and AXI interface handling
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= IDLE;
      burst_counter_ff <= '0;
      for (int i = 0; i < BURST_SIZE; i++) begin
        memory_data_out[i] <= '0;
      end
      for (int i = 0; i < BURST_SIZE; i++) begin
        memory_data_in_ff[i] <= '0;
      end
    end else begin
      state <= next_state;
      burst_counter_ff <= burst_counter;
      mem_valid_o <= mem_valid_o_comb;
      for (int i = 0; i < BURST_SIZE; i++) begin
        memory_data_in_ff[i] <= memory_data_in[i];
      end

      if (read) memory_data_out[burst_counter_ff] <= axi.rdata;

      if (axi.awready && axi.awvalid) aw_done <= 1;

      if (axi.wready && axi.wvalid && axi.wlast) w_done <= 1;

      if (clear_done) begin
        w_done  <= 0;
        aw_done <= 0;
      end
    end
  end

  always_comb begin
    // Default assignments to avoid latches
    mem_valid_o_comb = 0;
    mem_ready_o      = 0;
    axi.arvalid      = 0;
    axi.awvalid      = 0;
    axi.wvalid       = 0;
    axi.wlast        = 0;
    axi.rready       = 0;
    axi.araddr       = '0;
    burst_counter    = '0;
    axi.awaddr       = '0;
    axi.wdata        = '0;
    read             = 0;
    clear_done       = 0;
    next_state       = state;


    case (state)
      IDLE: begin
        if (mem_invalidate) begin
          // Invalidates any current read
          mem_valid_o_comb = 0;
        end

        clear_done  = 1;
        mem_ready_o = 1;  // Memory interface is available

        // Handle read request
        if (mem_read_ready_i && !mem_write_valid_i) begin
          next_state = READ;
          // Handle write request
        end else if (mem_write_valid_i) begin
          mem_ready_o = 0;  // Indicate busy
          next_state  = WRITE;
        end
      end

      READ: begin
        axi.araddr = request_address;

        if (mem_invalidate) begin
          // Invalidates any current read
          next_state = IDLE;
        end else begin
          axi.arvalid = 1;

          if (axi.arready) next_state = READ_WAIT;
        end
      end

      READ_WAIT: begin
        if (!mem_invalidate) begin
          axi.arvalid = 0;
          axi.rready = mem_read_ready_i;
          read = 0;
        end else begin
          axi.rready = 1;
        end
        if (axi.rvalid) begin
          read = 1;
          burst_counter = burst_counter + 1;

          if (axi.rlast) begin
            // Burst read complete
            mem_valid_o_comb = 1;  // Data is now valid
            next_state = IDLE;
          end
        end
      end

      WRITE: begin
        // Initiate AXI burst write
        axi.awaddr  = request_address;
        axi.awvalid = !aw_done;

        if (burst_counter_ff == 1) begin // TODO: Change this in case the burst is biiger than 2
          axi.wlast = 1;  // Indicate this is the last transfer in the burst
        end else begin
          axi.wlast = 0;  // Not the last transfer yet
        end

        axi.wdata = memory_data_in_ff[burst_counter_ff];
        axi.wvalid = !w_done;

        burst_counter = burst_counter_ff;
        if (axi.wvalid && axi.wready) burst_counter = burst_counter + 1;

        if (aw_done && w_done) begin
          next_state  = IDLE;  // Wait for the AXI response to complete the write
          mem_ready_o = 1;  // Indicate busy
        end
      end

      default: next_state = IDLE;
    endcase
  end

endmodule
