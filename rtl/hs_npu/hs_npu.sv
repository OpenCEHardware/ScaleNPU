module hs_npu
  import hs_npu_pkg::*;
#(
    parameter int SIZE                    = 8,   // Number of rows and columns of the systolic array
    parameter int INPUT_DATA_WIDTH        = 16,
    parameter int OUTPUT_DATA_WIDTH       = 32,
    parameter int WEIGHT_DATA_WIDTH       = 16,
    parameter int BUFFER_SIZE             = 16,  // Maximum inferences to hold
    parameter int WORDS_PER_LINE          = SIZE * 8 / 32, // SYS_SIZE x INT8 / WORD_LENGTH
    parameter int INPUT_FIFO_DEPTH        = 10,
    parameter int WEIGHT_FIFO_DEPTH       = 8,
    parameter int ACTIVATION_OUTPUT_WIDTH = 16,  // Same as input data width
    parameter int OUTPUT_FIFO_DEPTH       = 10
) (
    input logic clk,
    input logic rst_n,

    // Execution control signals
    input  logic exec_valid_i,
    output logic exec_ready_o,

    // CPU input and weight matrix dimensions
    input uword num_input_rows_in,
    input uword num_input_columns_in,
    input uword num_weight_rows_in,
    input uword num_weight_columns_in,

    // CPU layer control signals
    input logic reuse_inputs_in,
    input logic reuse_weights_in,
    input logic save_outputs_in,
    input logic use_bias_in,
    input logic use_sum_in,
    input uword shift_amount_in,
    input logic activation_select_in,
    input uword base_address_in,
    input uword result_address_in,

    // Memory interface signals
    input  logic mem_valid_i,
    output logic mem_read_ready_o,
    output logic mem_write_valid_o,

    // Data  from/to memory
    input  uword memory_data_in[WORDS_PER_LINE],
    output uword memory_data_out[WORDS_PER_LINE],
    output uword request_address
);

    // Internal signals connecting the memory ordering and inference modules
    logic flush_input_fifos, flush_weight_fifos, flush_output_fifos;
    logic [INPUT_DATA_WIDTH-1:0] output_weights[SIZE], output_inputs[SIZE];
    logic [OUTPUT_DATA_WIDTH-1:0] output_bias[SIZE], output_sums[SIZE];
    logic weight_enable, start_input_gatekeeper, start_output_gatekeeper;
    uword enable_cycles_gatekeeper;
    logic activation_select_out;
    uword shift_amount_out;
    logic [ACTIVATION_OUTPUT_WIDTH-1:0] inference_result[SIZE];
    logic output_fifo_valid_o[SIZE];
    logic output_fifo_ready_i;
    logic output_fifo_reread;
    logic weight_fifo_valid, input_fifo_valid;
    logic bias_enable;
    logic mem_ready_i;
    logic mem_reset;

    // Instantiate hs_npu_memory_ordering
    hs_npu_memory_ordering #(
        .SIZE(SIZE),
        .BUFFER_SIZE(BUFFER_SIZE),
        .OUTPUT_DATA_WIDTH(OUTPUT_DATA_WIDTH),
        .INPUT_DATA_WIDTH(INPUT_DATA_WIDTH),
        .WORDS_PER_LINE(WORDS_PER_LINE)
    ) memory_ordering (
        .clk(clk),
        .rst_n(rst_n),
        .exec_valid_i(exec_valid_i),
        .exec_ready_o(exec_ready_o),
        .mem_valid_i(mem_valid_i),
        .mem_ready_i(mem_ready_i),
        .mem_read_ready_o(mem_read_ready_o),
        .mem_write_valid_o(mem_write_valid_o),
        .mem_reset(mem_reset),
        .num_input_rows_in(num_input_rows_in),
        .num_input_columns_in(num_input_columns_in),
        .num_weight_rows_in(num_weight_rows_in),
        .num_weight_columns_in(num_weight_columns_in),
        .reuse_inputs_in(reuse_inputs_in),
        .reuse_weights_in(reuse_weights_in),
        .save_outputs_in(save_outputs_in),
        .use_bias_in(use_bias_in),
        .use_sum_in(use_sum_in),
        .shift_amount_in(shift_amount_in),
        .activation_select_in(activation_select_in),
        .base_address_in(base_address_in),
        .result_address_in(result_address_in),
        .memory_data_in(memory_data_in),
        .memory_data_out(memory_data_out),
        .request_address(request_address),
        .flush_input_fifos(flush_input_fifos),
        .input_fifo_valid_o(input_fifo_valid),
        .input_fifo_ready_i(),
        .flush_weight_fifos(flush_weight_fifos),
        .weight_fifo_valid_o(weight_fifo_valid),
        .weight_fifo_ready_i(),
        .flush_output_fifos(flush_output_fifos),
        .output_fifo_ready_o(output_fifo_ready_i),
        .output_fifo_valid_i(output_fifo_valid_o),
        .output_fifo_reread(output_fifo_reread),
        .bias_enable(bias_enable),
        .weight_enable(weight_enable),
        .start_input_gatekeeper(start_input_gatekeeper),
        .start_output_gatekeeper(start_output_gatekeeper),
        .enable_cycles_gatekeeper(enable_cycles_gatekeeper),
        .activation_select_out(activation_select_out),
        .shift_amount_out(shift_amount_out),
        .output_weights(output_weights),
        .output_inputs(output_inputs),
        .output_bias(output_bias),
        .output_sums(output_sums),
        .inference_result(inference_result)
    );

    // Instantiate hs_npu_inference
    hs_npu_inference #(
        .SIZE(SIZE),
        .INPUT_DATA_WIDTH(INPUT_DATA_WIDTH),
        .OUTPUT_DATA_WIDTH(OUTPUT_DATA_WIDTH),
        .WEIGHT_DATA_WIDTH(WEIGHT_DATA_WIDTH),
        .INPUT_FIFO_DEPTH(INPUT_FIFO_DEPTH),
        .WEIGHT_FIFO_DEPTH(WEIGHT_FIFO_DEPTH),
        .ACTIVATION_OUTPUT_WIDTH(ACTIVATION_OUTPUT_WIDTH),
        .OUTPUT_FIFO_DEPTH(OUTPUT_FIFO_DEPTH)
    ) inference (
        .clk(clk),
        .rst_n(rst_n),
        .flush_input_fifos(flush_input_fifos),
        .flush_weight_fifos(flush_weight_fifos),
        .flush_output_fifos(flush_output_fifos),
        .input_matrix_row(output_inputs),
        .input_fifo_valid_i(input_fifo_valid),
        .input_fifo_ready_o(),
        .weight_matrix_row(output_weights),
        .weight_fifo_valid_i(weight_fifo_valid),
        .weight_fifo_ready_o(),
        .input_sums(output_sums),
        .enable_weights(weight_enable),
        .start_input_gatekeeper(start_input_gatekeeper),
        .start_output_gatekeeper(start_output_gatekeeper),
        .enable_cycles_in(enable_cycles_gatekeeper),
        .bias_values(output_bias),
        .bias_en(bias_enable),
        .shift_amount(shift_amount_out),
        .relu_enable(activation_select_out),
        .inference_result(inference_result),
        .output_fifo_valid_o(output_fifo_valid_o),
        .output_fifo_ready_i(output_fifo_ready_i),
        .output_fifo_reread(output_fifo_reread)
    );

endmodule
