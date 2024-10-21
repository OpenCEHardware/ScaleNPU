module hs_npu_fifo_keeper
  import hs_npu_pkg::*;
#(
    parameter int WIDTH = 32,  // Data width
    parameter int DEPTH = 4    // FIFO depth
) (
    input logic clk,   // Clock
    input logic rst_n, // Active-low reset

    // Interface with input FIFO
    input  logic [WIDTH-1:0] fifo_in_data,   // Data coming from FIFO input
    input  logic             fifo_in_valid,  // Data valid from input FIFO
    output logic             fifo_in_ready,  // Ready signal for input FIFO

    // Interface with output FIFO
    output logic [WIDTH-1:0] fifo_out_data,   // Data to output FIFO
    output logic             fifo_out_valid,  // Data valid for output FIFO
    output logic             fifo_out_ready,  // Ready signal from output FIFO

    // Control signals for gatekeeper
    input logic start_in,      // Start signal for the gatekeeper
    input uword enable_cycles  // Control for how long gatekeeper processes data
);

  // Internal signals
  logic [WIDTH-1:0] gatekeeper_data_in;
  logic [WIDTH-1:0] gatekeeper_data_out;
  logic gatekeeper_start, gatekeeper_active;

  // Instantiate the FIFO feeding into the gatekeeper
  hs_npu_fifo #(
      .WIDTH(WIDTH),
      .DEPTH(DEPTH)
  ) input_fifo (
      .clk_core  (clk),
      .rst_core_n(rst_n),
      .flush     (1'b0),           // No explicit flush control in this example
      .ready_o   (fifo_in_ready),
      .valid_i   (fifo_in_valid),
      .in        (fifo_in_data),

      .ready_i(gatekeeper_active),  // Gatekeeper is ready to receive data when active
      .valid_o(),
      .out(gatekeeper_data_in)
  );

  // Instantiate the NPU gatekeeper
  hs_npu_gatekeeper #(
      .DATA_WIDTH(WIDTH)
  ) gatekeeper (
      .clk(clk),
      .rst_n(rst_n),
      .input_data(gatekeeper_data_in),
      .enable_cycles_in(enable_cycles),
      .start_in(start_in),
      .output_data(gatekeeper_data_out),
      .start_out(gatekeeper_start),
      .active(gatekeeper_active)  // The ready signal for the gatekeeper input
  );

// Instantiate the NPU gatekeeper #2
  hs_npu_gatekeeper #(
      .DATA_WIDTH(WIDTH)
  ) gatekeeper2 (
      .clk(clk),
      .rst_n(rst_n),
      .input_data(gatekeeper_data_in),
      .enable_cycles_in(enable_cycles),
      .start_in(gatekeeper_start),
      .output_data(gatekeeper_data_out),
      .start_out(),
      .active(gatekeeper_active)  // The ready signal for the gatekeeper input
  );

  // Instantiate the FIFO receiving data from the gatekeeper
  hs_npu_fifo #(
      .WIDTH(WIDTH),
      .DEPTH(DEPTH)
  ) output_fifo (
      .clk_core  (clk),
      .rst_core_n(rst_n),
      .flush     (1'b0),              // No explicit flush control in this example
      .ready_o   (fifo_out_ready),
      .valid_i   (gatekeeper_active),
      .in        (gatekeeper_data_out),

      .ready_i(),
      .valid_o(fifo_out_valid),
      .out(fifo_out_data)
  );

endmodule
