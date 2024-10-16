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
    READ_WAIT,
    WRITE_WAIT,
    WAIT
  } state_t;
  state_t state, next_state;

  // Write and read data tracking
  // logic [31:0] write_data[BURST_SIZE];
  // logic [31:0] read_data[BURST_SIZE];
  logic [$clog2(BURST_LEN+1)-1:0] burst_counter;  // To track burst transfers
  logic [$clog2(BURST_LEN+1)-1:0] burst_counter_ff;  // To track burst transfers

  // Fixed AXI4 Burst signal
  localparam logic [1:0] INCR = 1;
  localparam logic [3:0] STRB = 4'b1111;

  assign axi.arburst = INCR;
  assign axi.awburst = INCR;
  assign axi.arsize  = BURST_SIZE;
  assign axi.awsize  = BURST_SIZE;
  assign axi.arlen   = BURST_LEN;
  assign axi.awlen   = BURST_LEN;
  assign axi.wstrb   = STRB;
  assign axi.bready  = 1;

  uword request_address_ff;
  logic read;
  logic mem_valid_o_comb;

  // Control logic for read/write requests and AXI interface handling
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= IDLE;
      request_address_ff <= request_address;
      burst_counter_ff <= '0;
      for (int i = 0; i < BURST_SIZE; i++) begin
        memory_data_out[i] <= '0;
      end
    end else begin
      state <= next_state;
      request_address_ff <= request_address;
      burst_counter_ff <= burst_counter;
      mem_valid_o <= mem_valid_o_comb;
      if (read) memory_data_out[burst_counter_ff] <= axi.rdata;
    end
  end

  always_comb begin
    // Default assignments to avoid latches
    mem_valid_o_comb = 0;
    mem_ready_o      = 1;
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
    next_state       = state;


    case (state)
      IDLE: begin
        if (mem_invalidate) begin
          // Invalidates any current read
          mem_valid_o_comb = 0;
        end
        mem_ready_o = 1;  // Memory interface is available

        // Handle read request
        if (mem_read_ready_i && !mem_write_valid_i) begin
          next_state = READ;
          // Handle write request
        end else if (mem_write_valid_i) begin
          next_state = WRITE;
        end
      end

      READ: begin
        if (mem_invalidate) begin
          // Invalidates any current read
          mem_valid_o_comb = 0;
          next_state = IDLE;
        end else if (axi.arready) begin
          // Initiate AXI burst read
          axi.araddr = request_address_ff;
          axi.arvalid = 1;
          burst_counter = 0;
          mem_ready_o = 0;  // Indicate busy
          read = 0;
          next_state = READ_WAIT;
        end
      end

      READ_WAIT: begin
        if (!mem_invalidate)begin
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
        if (axi.awready) begin
          // Initiate AXI burst write
          axi.awaddr = request_address_ff;
          axi.awvalid = 1;
          burst_counter = 0;
          mem_ready_o = 0;  // Indicate busy
          next_state = WRITE_WAIT;
        end
      end

      WRITE_WAIT: begin
        axi.awvalid = 0;

        if (axi.wready) begin
          axi.wdata  = memory_data_in[burst_counter_ff];
          axi.wvalid = 1;

          if ({{(8 - $clog2(BURST_LEN + 1)) {1'b0}}, burst_counter} == BURST_LEN) begin
            axi.wlast  = 1;  // Indicate this is the last transfer in the burst
            next_state = WAIT;  // Wait for the AXI response to complete the write
          end else begin
            axi.wlast = 0;  // Not the last transfer yet
            burst_counter = burst_counter + 1;
          end
        end
      end

      default: next_state = IDLE;
    endcase
  end
endmodule
