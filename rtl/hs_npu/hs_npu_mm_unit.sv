module hs_npu_mm_unit
  import hs_npu_pkg::*;
#(
    parameter int SIZE = 8,  // Size of the systolic array (default 8x8)
    parameter int INPUT_DATA_WIDTH = 16,  // Input data width (int8)
    parameter int OUTPUT_DATA_WIDTH = 32,  // Output data width (int32)
    parameter int WEIGHT_DATA_WIDTH = 16,  // Weight data width (int8)
    parameter int INPUT_FIFO_DEPTH = 10,  // Depth of input FIFOs
    parameter int WEIGHT_FIFO_DEPTH = 8    // Depth of weight FIFOs (same or more than the systolic array size)
) (
    input logic clk,
    input logic rst_n,
    input logic flush_input_fifos,
    input logic flush_weight_fifos,

    // Input FIFO sink signals
    input logic [INPUT_DATA_WIDTH-1:0] input_matrix_row[SIZE],  // Row of the input matrix
    input logic input_fifo_valid_i,
    output logic input_fifo_ready_o[SIZE],

    // Weight FIFO sink signals
    input logic [WEIGHT_DATA_WIDTH-1:0] weight_matrix_row[SIZE],  // Row of the weight matrix
    input logic weight_fifo_valid_i,
    output logic weight_fifo_ready_o[SIZE],

    // Output source signals
    output logic [OUTPUT_DATA_WIDTH-1:0] output_data[SIZE],  // Output data from systolic array
    output logic valid_o[SIZE],

    // Initial sums for systolic array computation
    input logic [OUTPUT_DATA_WIDTH-1:0] input_sums[SIZE],  // Initial sum values
    input logic enable_weights,  // Enable weights input to the systolic array

    // Gatekeeper control signals
    input logic start_input_gatekeeper,  // Start signal for the first input gatekeeper
    input logic start_output_gatekeeper,  // Start signal for the first output gatekeeper
    input uword enable_cycles_in  // Enable cycles for gatekeeper synchronization
);

  // Internal signals for FIFO, gatekeeper and systolic array connections
  logic [INPUT_DATA_WIDTH-1:0] input_fifo_out[SIZE];  // Output data from input FIFOs
  logic [WEIGHT_DATA_WIDTH-1:0] weight_fifo_out[SIZE];  // Output data from weight FIFOs

  logic [INPUT_DATA_WIDTH-1:0] input_systolic[SIZE];  // Input data to systolic array (delayed input matrix)
  logic [OUTPUT_DATA_WIDTH-1:0] output_systolic[SIZE];  // Output data from systolic array (delayed results)

  logic input_keeper_active[SIZE];  // Gatekeeper active signal for input FIFOs

  logic start_input_out[SIZE];  // Start signal for cascading input gatekeepers
  logic start_output_out[SIZE];  // Start signal for cascading output gatekeepers

  // Generate input FIFO and gatekeeper logic
  genvar i;
  generate
    for (i = 0; i < SIZE; i++) begin : gen_fifo_gatekeeper_input
      // Input pipeline: FIFO -> Gatekeeper -> Systolic array input
      hs_fifo #(
          .WIDTH(INPUT_DATA_WIDTH),
          .DEPTH(INPUT_FIFO_DEPTH)
      ) input_fifo (
          .clk_core  (clk),
          .rst_core_n(rst_n),
          .flush     (flush_input_fifos),
          .reread    (0),
          .ready_o   (input_fifo_ready_o[i]),   // FIFO ready signal
          .valid_i   (input_fifo_valid_i),      // Input FIFO valid signal
          .in        (input_matrix_row[i]),     // Input matrix row data
          .ready_i   (input_keeper_active[i]),  // Ready signal from gatekeeper
          .valid_o   (),                        // Valid signal from FIFO to gatekeeper, not used
          .out       (input_fifo_out[i])        // FIFO output data
      );

      // Input gatekeeper: controls data flow from FIFO to systolic array, creates diagonal delay
      hs_npu_gatekeeper #(
          .DATA_WIDTH(INPUT_DATA_WIDTH)
      ) input_gatekeeper (
          .clk(clk),
          .rst_n(rst_n),
          .input_data(input_fifo_out[i]),  // Input data from FIFO
          .enable_cycles_in(enable_cycles_in),
          .start_in(i == 0 ? start_input_gatekeeper : start_input_out[i-1]),  // First gatekeeper starts externally, others cascade
          .output_data(input_systolic[i]),  // Output data to systolic array
          .start_out(start_input_out[i]),  // Cascaded start signal
          .active(input_keeper_active[i])  // Active signal to control FIFO ready signal
      );
    end

    // Generate weight FIFO logic (no gatekeeper needed, direct to systolic array)
    for (i = 0; i < SIZE; i++) begin : gen_fifo_weight
      hs_fifo #(
          .WIDTH(WEIGHT_DATA_WIDTH),
          .DEPTH(WEIGHT_FIFO_DEPTH)
      ) weight_fifo (
          .clk_core  (clk),
          .rst_core_n(rst_n),
          .flush     (flush_weight_fifos),
          .reread    (0),
          .ready_o   (weight_fifo_ready_o[i]),  // Ready signal from weight FIFO
          .valid_i   (weight_fifo_valid_i),     // Valid signal for weight FIFO
          .in        (weight_matrix_row[i]),    // Weight matrix row data
          .ready_i   (enable_weights),          // Ready signal for systolic array weight
          .valid_o   (),                        // Valid signal to systolic array, not used
          .out       (weight_fifo_out[i])       // FIFO output data to systolic array
      );
    end
  endgenerate

  // Systolic array instantiation
  hs_npu_systolic #(
      .SIZE(SIZE)
  ) systolic_array (
      .clk      (clk),
      .enable_in(enable_weights),   // Enable signal for systolic array
      .matrixA  (input_systolic),   // Matrix A input from gatekeepers
      .matrixB  (weight_fifo_out),  // Matrix B input from weight FIFOs
      .sum_in   (input_sums),       // Initial sums input for computation
      .result   (output_systolic)   // Computation result
  );

  // Generate output FIFO and gatekeeper logic
  generate
    for (i = 0; i < SIZE; i++) begin : gen_fifo_gatekeeper_output
      // Output pipeline: Systolic array output -> Gatekeeper
      hs_npu_gatekeeper #(
          .DATA_WIDTH(OUTPUT_DATA_WIDTH)
      ) gatekeeper_out (
          .clk(clk),
          .rst_n(rst_n),
          .input_data(output_systolic[i]),  // Input from systolic array
          .enable_cycles_in(enable_cycles_in),
          .start_in(i == 0 ? start_output_gatekeeper : start_output_out[i-1]),  // First output gatekeeper starts externally, others cascade
          .output_data(output_data[i]),  // Output data to output FIFO
          .start_out(start_output_out[i]),  // Cascaded start signal
          .active(valid_o[i])  // Active signal
      );
    end
  endgenerate

endmodule
