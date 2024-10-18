module hs_npu_top
  import hs_npu_pkg::*;
#(
    // Microarch
    parameter int SIZE = 8,  // Number of rows and columns of the systolic array
    // Arch
    parameter int INPUT_DATA_WIDTH = 16,
    parameter int WEIGHT_DATA_WIDTH = 16,
    parameter int OUTPUT_DATA_WIDTH = 32,
    parameter int ACTIVATION_OUTPUT_WIDTH = INPUT_DATA_WIDTH,
    // SDRAM limitation
    parameter int BUFFER_SIZE = 16,  // Maximum inferences to hold
    parameter int INPUT_FIFO_DEPTH = BUFFER_SIZE,
    parameter int OUTPUT_FIFO_DEPTH = BUFFER_SIZE,
    parameter int WEIGHT_FIFO_DEPTH = 8,
    // AXI RAM limitation
    parameter int BURST_SIZE = 2,  // 2^2 --> 4 bytes -> 32 bit words per transfers
    parameter int BURST_LEN = 1  // 1+1 = 2, 32 bit word transfers
) (
    input logic clk,
    input logic rst_n,

    output logic irq_cpu,

    axi4lite_intf.slave csr,
    axib_if.m mem
);

  hs_npu_ctrlstatus_regs_pkg::hs_npu_ctrlstatus_regs__in_t  hwif_in;
  hs_npu_ctrlstatus_regs_pkg::hs_npu_ctrlstatus_regs__out_t hwif_out;

  // Instantiate hs_npu_ctrlstatus_regs
  hs_npu_ctrlstatus_regs ctrlstatus_regs (
      .clk(clk),
      .arst_n(rst_n),
      .s_axil(csr),
      .hwif_in(hwif_in),
      .hwif_out(hwif_out)
  );

  logic executive_ready;
  logic executive_valid;
  logic finished;
  uword num_input_rows;
  uword num_input_columns;
  uword num_weight_rows;
  uword num_weight_columns;
  logic reuse_inputs;
  logic reuse_weights;
  logic save_outputs;
  logic use_bias;
  logic use_sum;
  uword shift_amount;
  logic activation_select;
  uword base_address;
  uword result_address;

  // Instantiate hs_npu_executive
  hs_npu_executive #(
      .BUFFER_SIZE(BUFFER_SIZE)
  ) executive (
      .clk(clk),
      .rst_n(rst_n),
      // CSRs
      .hwif_in(hwif_in),
      .hwif_out(hwif_out),
      .irq(irq_cpu),
      // Memory ordering
      .memory_ordering_ready_i(executive_ready),
      .memory_ordering_valid_o(executive_valid),
      .finished(finished),
      .num_input_rows_out(num_input_rows),
      .num_input_columns_out(num_input_columns),
      .num_weight_rows_out(num_weight_rows),
      .num_weight_columns_out(num_weight_columns),
      .reuse_inputs_out(reuse_inputs),
      .reuse_weights_out(reuse_weights),
      .save_outputs_out(save_outputs),
      .use_bias_out(use_bias),
      .use_sum_out(use_sum),
      .shift_amount_out(shift_amount),
      .activation_select_out(activation_select),
      .base_address_out(base_address),
      .result_address_out(result_address)
  );

  // Inference
  logic flush_input_fifos;
  logic flush_weight_fifos;
  logic flush_output_fifos;
  logic [INPUT_DATA_WIDTH-1:0] inputs[SIZE];
  logic input_fifo_valid;
  logic [WEIGHT_DATA_WIDTH-1:0] weights[SIZE];
  logic weight_fifo_valid;
  logic [OUTPUT_DATA_WIDTH-1:0] sums[SIZE];
  logic weight_enable;
  logic start_input_gatekeeper;
  logic start_output_gatekeeper;
  uword enable_cycles_gatekeeper;
  logic [OUTPUT_DATA_WIDTH-1:0] bias[SIZE];
  logic bias_enable;
  uword shift_amount_out;
  logic activation_select_out;
  logic [ACTIVATION_OUTPUT_WIDTH-1:0] inference_result[SIZE];
  logic output_fifo_ready;
  logic output_fifo_reread;
  // Memory Interface
  logic memory_interface_valid;
  logic memory_interface_ready;
  logic memory_interface_read_ready;
  logic memory_interface_write_valid;
  logic memory_interface_invalidate;
  uword memory_data_read[BURST_SIZE];
  uword memory_data_write[BURST_SIZE];
  uword request_address;

  // Instantiate hs_npu_memory_ordering
  hs_npu_memory_ordering #(
      .SIZE(SIZE),
      .OUTPUT_DATA_WIDTH(OUTPUT_DATA_WIDTH),
      .INPUT_DATA_WIDTH(INPUT_DATA_WIDTH),
      .BURST_SIZE(BURST_SIZE)
  ) memory_ordering (
      .clk(clk),
      .rst_n(rst_n),
      // Executive
      .exec_ready_o(executive_ready),
      .exec_valid_i(executive_valid),
      .finished(finished),
      .num_input_rows_in(num_input_rows),
      .num_input_columns_in(num_input_columns),
      .num_weight_rows_in(num_weight_rows),
      .num_weight_columns_in(num_weight_columns),
      .reuse_inputs_in(reuse_inputs),
      .reuse_weights_in(reuse_weights),
      .save_outputs_in(save_outputs),
      .use_bias_in(use_bias),
      .use_sum_in(use_sum),
      .shift_amount_in(shift_amount),
      .activation_select_in(activation_select),
      .base_address_in(base_address),
      .result_address_in(result_address),
      // Inference
      .flush_input_fifos(flush_input_fifos),
      .flush_weight_fifos(flush_weight_fifos),
      .flush_output_fifos(flush_output_fifos),
      .output_inputs(inputs),
      .input_fifo_valid_o(input_fifo_valid),
      .output_weights(weights),
      .weight_fifo_valid_o(weight_fifo_valid),
      .output_sums(sums),
      .weight_enable(weight_enable),
      .start_input_gatekeeper(start_input_gatekeeper),
      .start_output_gatekeeper(start_output_gatekeeper),
      .enable_cycles_gatekeeper(enable_cycles_gatekeeper),
      .output_bias(bias),
      .bias_enable(bias_enable),
      .shift_amount_out(shift_amount_out),
      .activation_select_out(activation_select_out),
      .inference_result(inference_result),
      .output_fifo_ready_o(output_fifo_ready),
      .output_fifo_reread(output_fifo_reread),
      // Memory Interface
      .mem_valid_i(memory_interface_valid),
      .mem_ready_i(memory_interface_ready),
      .mem_read_ready_o(memory_interface_read_ready),
      .mem_write_valid_o(memory_interface_write_valid),
      .mem_invalidate(memory_interface_invalidate),
      .memory_data_in(memory_data_read),
      .memory_data_out(memory_data_write),
      .request_address(request_address)
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
      // Memory ordering
      .flush_input_fifos(flush_input_fifos),
      .flush_weight_fifos(flush_weight_fifos),
      .flush_output_fifos(flush_output_fifos),
      .input_matrix_row(inputs),
      .input_fifo_valid_i(input_fifo_valid),
      .input_fifo_ready_o(),
      .weight_matrix_row(weights),
      .weight_fifo_valid_i(weight_fifo_valid),
      .weight_fifo_ready_o(),
      .input_sums(sums),
      .enable_weights(weight_enable),
      .start_input_gatekeeper(start_input_gatekeeper),
      .start_output_gatekeeper(start_output_gatekeeper),
      .enable_cycles_in(enable_cycles_gatekeeper),
      .bias_values(bias),
      .bias_en(bias_enable),
      .shift_amount(shift_amount_out),
      .relu_enable(activation_select_out),
      .inference_result(inference_result),
      .output_fifo_valid_o(),
      .output_fifo_ready_i(output_fifo_ready),
      .output_fifo_reread(output_fifo_reread)
  );

  // Instantiate hs_npu_memory_interface
  hs_npu_memory_interface #(
      .BURST_SIZE(BURST_SIZE),
      .BURST_LEN (BURST_LEN)
  ) memory_interface (
      .clk(clk),
      .rst_n(rst_n),
      // Memory ordering
      .mem_valid_o(memory_interface_valid),
      .mem_ready_o(memory_interface_ready),
      .mem_read_ready_i(memory_interface_read_ready),
      .mem_write_valid_i(memory_interface_write_valid),
      .mem_invalidate(memory_interface_invalidate),
      .memory_data_in(memory_data_write),
      .memory_data_out(memory_data_read),
      .request_address(request_address),
      // AXI4 burst interface
      .axi(mem)
  );

endmodule
