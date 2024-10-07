module hs_npu_inference
  import hs_npu_pkg::*;
#(
    parameter int SIZE                    = 8,   // Number of rows and columns of the systolic array
    parameter int INPUT_DATA_WIDTH        = 16,
    parameter int OUTPUT_DATA_WIDTH       = 32,
    parameter int WEIGHT_DATA_WIDTH       = 16,  // Should be the same as input data width
    parameter int INPUT_FIFO_DEPTH        = 10,
    parameter int WEIGHT_FIFO_DEPTH       = 8,
    parameter int ACTIVATION_OUTPUT_WIDTH = 16,  // Output width of the activation module, should be same as input data width
    parameter int OUTPUT_FIFO_DEPTH       = 10   // Should be same as input depth
) (
    input logic clk,
    input logic rst_n,

    // Inputs for matrix multiplication unit
    input logic flush_input_fifos,
    input logic flush_weight_fifos,
    input logic flush_output_fifos,

    input logic [INPUT_DATA_WIDTH-1:0] input_matrix_row[SIZE],
    input logic input_fifo_valid_i,
    output logic input_fifo_ready_o[SIZE],

    input logic [WEIGHT_DATA_WIDTH-1:0] weight_matrix_row[SIZE],
    input logic weight_fifo_valid_i,
    output logic weight_fifo_ready_o[SIZE],

    input logic [OUTPUT_DATA_WIDTH-1:0] input_sums[SIZE],  // Initial sum values

    input logic enable_weights,
    input logic start_input_gatekeeper,
    input logic start_output_gatekeeper,
    input uword enable_cycles_in,

    // Inputs for accumulator and activation
    input logic [OUTPUT_DATA_WIDTH-1:0] bias_values[SIZE],  // Bias values for each accumulator
    input logic bias_en,  // Enable signal for loading bias (per accumulator)
    input uword shift_amount,  // Shift amount for all activations
    input logic relu_enable,  // Enable signal for ReLU

    // Output fifo source signals
    output logic [ACTIVATION_OUTPUT_WIDTH-1:0] inference_result[SIZE],  // Final output from activation
    output logic output_fifo_valid_o[SIZE],
    input logic output_fifo_ready_i,
    input logic output_fifo_reread
);

  // Internal signals for connecting the MM unit, accumulator, and activation modules
  logic [OUTPUT_DATA_WIDTH-1:0] mm_unit_output[SIZE];  // Output from the MM unit (systolic array)
  logic [OUTPUT_DATA_WIDTH-1:0] acc_output[SIZE];  // Output from each accumulator
  logic [ACTIVATION_OUTPUT_WIDTH-1:0] act_output[SIZE];  // Output from each activation
  logic mm_valid[SIZE];  // Valid signal from MM unit
  logic acc_valid[SIZE];  // Valid signal from accumulators
  logic act_valid[SIZE];  // Valid signal from activations

  // Instantiate the matrix multiplication unit (MMU)
  hs_npu_mm_unit #(
      .SIZE(SIZE),
      .INPUT_DATA_WIDTH(INPUT_DATA_WIDTH),
      .OUTPUT_DATA_WIDTH(OUTPUT_DATA_WIDTH),
      .WEIGHT_DATA_WIDTH(WEIGHT_DATA_WIDTH),
      .INPUT_FIFO_DEPTH(INPUT_FIFO_DEPTH),
      .WEIGHT_FIFO_DEPTH(WEIGHT_FIFO_DEPTH)
  ) mm_unit (
      .clk(clk),
      .rst_n(rst_n),
      .flush_input_fifos(flush_input_fifos),
      .flush_weight_fifos(flush_weight_fifos),
      .input_matrix_row(input_matrix_row),
      .input_fifo_valid_i(input_fifo_valid_i),
      .input_fifo_ready_o(input_fifo_ready_o),
      .weight_matrix_row(weight_matrix_row),
      .weight_fifo_valid_i(weight_fifo_valid_i),
      .weight_fifo_ready_o(weight_fifo_ready_o),
      .output_data(mm_unit_output),
      .valid_o(mm_valid),
      .input_sums(input_sums),
      .enable_weights(enable_weights),
      .start_input_gatekeeper(start_input_gatekeeper),
      .start_output_gatekeeper(start_output_gatekeeper),
      .enable_cycles_in(enable_cycles_in)
  );

  // Instantiate accumulator and activation units for each row in the systolic array
  genvar i;
  generate
    for (i = 0; i < SIZE; i++) begin : gen_inference_pipeline
      // Accumulator: adds bias to MMU output
      hs_npu_accumulator #(
          .OUTPUT_DATA_WIDTH(OUTPUT_DATA_WIDTH)
      ) accumulator (
          .clk       (clk),
          .rst_n     (rst_n),
          .input_data(mm_unit_output[i]),  // Output from the MMU
          .valid_i   (mm_valid[i]),        // Valid signal from MMU
          .bias_in   (bias_values[i]),     // Bias value per row
          .bias_en   (bias_en),            // Enable signal for bias loading
          .result    (acc_output[i]),      // Output after bias addition
          .valid_o   (acc_valid[i])        // Valid signal after accumulation
      );

      // Activation: applies ReLU and shift to the accumulator result
      hs_npu_activation #(
          .DATA_WIDTH  (OUTPUT_DATA_WIDTH),
          .OUTPUT_WIDTH(ACTIVATION_OUTPUT_WIDTH)
      ) activation (
          .input_data  (acc_output[i]),  // Output from the accumulator
          .valid_i     (acc_valid[i]),   // Valid signal from accumulator
          .relu_en     (relu_enable),    // ReLU enable
          .shift_amount(shift_amount),   // Shift amount (same for all rows)
          .result      (act_output[i]),  // Output after activation and quantization
          .valid_o     (act_valid[i])    // Valid signal after activation
      );

    end
  endgenerate

  generate
    for (i = 0; i < SIZE; i++) begin : gen_fifo_output
      hs_fifo #(
          .WIDTH(INPUT_DATA_WIDTH),
          .DEPTH(OUTPUT_FIFO_DEPTH)
      ) input_fifo (
          .clk_core  (clk),
          .rst_core_n(rst_n),
          .flush     (flush_output_fifos),
          .reread    (output_fifo_reread),
          .ready_o   (),                        // Not used
          .valid_i   (act_valid[i]),            // Activation valid signal
          .in        (act_output[i]),           // Activation data
          .ready_i   (output_fifo_ready_i),     // Ready signal from gatekeeper
          .valid_o   (output_fifo_valid_o[i]),  // Valid signal from output FIFO
          .out       (inference_result[i])      // Final output
      );
    end
  endgenerate

endmodule
