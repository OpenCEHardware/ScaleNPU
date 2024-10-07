module hs_npu_memory_ordering
  import hs_npu_pkg::*;
#(
    parameter int SIZE = 8,  // Number of rows and columns of the systolic array
    parameter int BUFFER_SIZE = 16,  // Maximum number of inferences the system cand hold
    parameter int OUTPUT_DATA_WIDTH = 32,
    parameter int WORDS_PER_LINE = SIZE * 8 / 32  // SYS_SIZE x INT8 / WORD_LENGHT
) (
    input logic clk,
    input logic rst_n,

    input  exec_valid_i,
    output exec_ready_o,

    input  mem_valid_i,
    output mem_read_ready_o,
    output mem_write_valid_o,

    // Input and weight matrices dimesions from CPU
    input uword num_input_rows_in,
    input uword num_input_columns_in,
    input uword num_weight_rows_in,
    input uword num_weight_columns_in,

    // Layer control signals from CPU
    input logic reuse_inputs_in,
    input logic reuse_weights_in,
    input logic save_outputs_in,
    input logic use_bias_in,
    input logic use_sum_in,
    input uword shift_amount_in,
    input logic activation_select_in,
    input uword base_address_in,
    input uword result_address_in,

    // Data matrices from memory
    input  uword memory_data_in [WORDS_PER_LINE],
    output uword memory_data_out[WORDS_PER_LINE],
    output uword request_address,

    // Control signals for matrix multiplication unit and fifos
    output logic flush_input_fifos,
    output logic input_fifo_valid_o,
    input  logic input_fifo_ready_i[SIZE],

    output logic flush_weight_fifos,
    output logic weight_fifo_valid_o,
    input  logic weight_fifo_ready_i[SIZE],

    output logic flush_output_fifos,
    input  logic output_fifo_valid_i[SIZE],
    output logic output_fifo_ready_o,
    output logic output_fifo_reread,

    output logic bias_enable,
    output logic weight_enable,
    output logic start_input_gatekeeper,
    output logic start_output_gatekeeper,
    output uword enable_cycles_gatekeeper,
    output logic activation_select_out,


    output logic [INPUT_DATA_WIDTH-1:0] output_weights[SIZE],
    output logic [INPUT_DATA_WIDTH-1:0] output_inputs[SIZE],
    output logic [OUTPUT_DATA_WIDTH-1:0] output_bias[SIZE],
    output logic [OUTPUT_DATA_WIDTH-1:0] output_sums[SIZE],

    input logic [ACTIVATION_OUTPUT_WIDTH-1:0] inference_result[SIZE]  // Final output from inference

);


  logic in_progress;

  // Floped layer control signals from CPU
  uword num_input_rows;
  uword num_input_columns;
  uword num_weight_rows;
  uword num_weight_columns;

  logic reuse_inputs;
  logic reuse_weights;
  logic save_outputs;
  uword shift_amount;
  logic activation_select;
  uword base_address;
  uword result_address;
  logic use_bias;
  logic use_sum;

  // Operation flux control signals
  //uword operation_cycles;
  loading_state_t state;
  uword computation_cycles;

  uword current_i;
  uword current_j;

  logic [OUTPUT_DATA_WIDTH-1:0] sums[SIZE];
  logic [OUTPUT_DATA_WIDTH-1:0] bias[SIZE];

  // Prepare for new calculation and reset
  always_ff @(posedge clk or negedge rst_n) begin : set_up

    if (!rsr_n) begin
      in_progress <= 0;

      num_input_rows <= '0;
      num_input_columns <= '0;
      num_weight_rows <= '0;
      num_weight_columns <= '0;

      reuse_inputs <= 0;
      reuse_weights <= 0;
      save_outputs <= 0;
      shift_amount <= 0;
      activation_select <= 0;
      base_address <= '0;
      result_address <= '0;
      use_bias <= 0;
      use_sum <= 0;

      //operation_cycles <= 0;
      state <= IDLE;
      computation_cycles <= '0;

      current_i <= 0;
      current_j <= 0;

      sums <= '0;
      bias <= '0;

    end

    // Flop all layer signal values
    if (!in_progress && exec_valid_i) begin

      in_progress <= 1;

      num_input_rows <= num_input_rows_in;
      num_input_columns <= num_input_columns_in;
      num_weight_rows <= num_weight_rows_in;
      num_weight_columns <= num_weight_columns_in;

      reuse_inputs <= reuse_inputs_in;
      reuse_weights <= reuse_weights_in;
      save_outputs <= save_outputs_in;
      shift_amount <= shift_amount_in;
      activation_select <= activation_select_in;
      base_address <= base_address_in;
      result_address <= result_address_in;
      use_bias <= use_bias_in;
      use_sum <= use_sum_in;

      computation_cycles <= '0;

      current_i <= 0;
      current_j <= 0;

      // We always start with the weights
      //operation_cycles <= 1;
      state <= LOADING_WEIGHTS;
    end
  end


  always_ff @(posedge clk) begin : trivial_cases

    if (in_progress) begin

      if (reuse_weights && state == LOADING_WEIGHTS) begin
        state <= LOADING_INPUTS;
      end

      // Input has no trivial case, it will always have to be moved o loaded
      if (reuse_inputs && state == LOADING_INPUTS) begin
        output_fifo_ready_o <= 1;
      end

      if (!use_bias && state == LOADING_BIAS) begin
        bias <= '0;
        current_i <= 0;
        current_j <= 0;
        state <= LOADING_SUMS;
      end

      if (!use_sum && state == LOADING_SUMS) begin
        sums  <= '0;
        state <= READY_TO_COMPUTE;
      end
    end
  end


  // Keep asking for data
  assign mem_read_ready_o = state == LOADING_WEIGHTS || state == LOADING_INPUTS || state == LOADING_BIAS || state == LOADING_SUMS;

  logic moving_inputs;
  assign moving_inputs = state == LOADING_INPUTS && reuse_inputs;

  always_ff @(posedge clk) begin : loading_loop

    // Flop all layer signal values
    if (in_progress) begin

      // Check if memory has answered our request
      if (mem_valid_i || moving_inputs) begin

        if (current_i < num_weight_rows) begin
          // Iterate over memory_data_in to extract weights
          for (int bundle_idx = 0; bundle_idx < WORDS_PER_LINE; bundle_idx++) begin
            for (
                int weight_idx = 0; weight_idx < 4; weight_idx++
            ) begin  // int8 weights are enforced here
              // Extract each 8-bit weight from memory_data_in and load into weight FIFO
              output_weights[weight_idx + (bundle_idx * 4)] <= memory_data_in[bundle_idx][8 * weight_idx +: 8];
            end
          end
        end else begin
          output_weights <= '0;
        end

        if (!reuse_inputs) begin
          // Iterate over memory_data_in to extract input
          for (int bundle_idx = 0; bundle_idx < WORDS_PER_LINE; bundle_idx++) begin
            for (
                int input_idx = 0; input_idx < 4; input_idx++
            ) begin  // int8 inputs are enforced here
              // Extract each 8-bit input from memory_data_in and load into input FIFO
              output_inputs[input_idx+(bundle_idx*4)] <= memory_data_in[bundle_idx][8*bundle_idx+:8];
            end
          end
        end else begin
          // Iterate over past_result to extract input
          for (
              int input_idx = 0; input_idx < SIZE; input_idx++
          ) begin  // int8 inputs are enforced here
            output_inputs[SIZE-num_input_columns+input_idx] <= inference_result[input_idx];
          end
        end

        if (state == LOADING_WEIGHTS) begin
          if (current_i >= num_weight_rows) begin
            current_i <= 0;
            //current_j <= 0;
            weight_fifo_valid_o <= 0;
            state <= LOADING_INPUTS;
            // Here one could set the enable signals for weights to start loading.
            // One would have to independently track a SIZE amount of cycles before turing it
            // down again, failing to do so would overwrite weights and corrupt the result
            // This is why it is handled whitin the computing state below, even tho this is a SIZE
            // amount of cycles lost. Since for this application SIZE=8, the loss is prefered to favor order.
          end else begin
            weight_fifo_valid_o <= 1;
            current_i <= current_i + 1;
            //current_j <= current_j + (4 * WORDS_PER_LINE);
          end
        end


        if (state == LOADING_INPUTS) begin
          if (current_i >= num_input_rows) begin
            current_i <= 0;
            input_fifo_valid_o <= 0;
            if (reuse_inputs) output_fifo_ready_o <= 0;
            state <= LOADING_BIAS;
          end else begin
            input_fifo_valid_o <= 1;
            current_i <= current_i + 1;
            //current_j <= current_j + (4 * WORDS_PER_LINE);
          end
        end

        if (state == LOADING_BIAS) begin
          if (current_i < num_weight_columns) begin // Because the number of colums in the weights will always match the number of biases
            // Iterate over memory_data_in to extract bias
            for (int bundle_idx = 0; bundle_idx < WORDS_PER_LINE; bundle_idx++) begin
              bias[current_i] <= memory_data_in[bundle_idx];
            end
          end else begin
            bias[current_i] <= '0;
          end
          if (current_i >= SIZE) begin
            current_i <= 0;
            bias_enable <= 1;
            state <= LOADING_SUMS;
          end else current_i <= current_i + WORDS_PER_LINE;
        end

        if (state == LOADING_SUMS) begin
          if (current_i < num_weight_columns) begin // Because the number of colums in the weights will always match the number of sums
            // Iterate over memory_data_in to extract sums
            for (int bundle_idx = 0; bundle_idx < WORDS_PER_LINE; bundle_idx++) begin
              sums[current_i] <= memory_data_in[bundle_idx];
            end
          end else begin
            sums[current_i] <= '0;
          end
          if (current_i >= SIZE) begin
            bias_enable <= 0;
            mem_read_ready_o <= 0;
            if (!reuse_weights)
              weight_enable <= 1;  // Start loading weights into the systolic array
            flush_output_fifos <= 1;
            state <= READY_TO_COMPUTE;
          end else current_i <= current_i + WORDS_PER_LINE;
        end

        // Increment address
        request_address <= request_address + (4 * WORDS_PER_LINE);

      end else begin
        weight_fifo_valid_o <= 0;
        input_fifo_valid_o  <= 0;
      end
    end
  end

  logic weights_loaded;
  // Viligamos ejecucion teniendo en cuenta los timings. Aqui se puede mandar un flush a cualquier dato basura que se
  // hay pedido en la ultima iteracion
  always_ff @(posedge clk) begin : execution

    if (in_progress && state == READY_TO_COMPUTE) begin

      flush_output_fifos <= 0;

      computation_cycles <= computation_cycles + 1;

      if (computation_cycles == SIZE) begin
        weight_enable <= 0;
        start_input_gatekeeper <= 1;
        weights_loaded <= 1;
      end

      if (start_input_gatekeeper) start_input_gatekeeper <= 0;

      if (computation_cycles == 2 * SIZE) begin
        start_output_gatekeeper <= 1;
      end

      if (start_output_gatekeeper) start_output_gatekeeper <= 0;

      if (computation_cycles == 3 * SIZE + num_input_rows) begin
        flush_weight_fifos <= 1;
        flush_input_fifos  <= 1;
        if (save_outputs) begin
          mem_write_valid_o <= 1;
          output_fifo_ready_o <= 1;
          current_i <= 0;
        end
        state <= SAVING;
      end
    end
  end

  // Cerramos, guardamos resultados y quedamos en modo de espera

  always_ff @(posedge clk) begin : saving

    if (in_progress && state == SAVING) begin

      flush_weight_fifos <= 0;
      flush_input_fifos  <= 0;

      if (!save_outputs) begin
        state <= IDLE;
        in_progress <= 0;
      end else begin
        // Iterate over past_result to extract input
        if (mem_valid_i) begin
          for (int output_idx = 0; output_idx < SIZE; output_idx++) begin
            memory_data_out[output_idx] <= inference_result[output_idx];
          end
          output_fifo_ready_o <= 1;
          current_i <= current_i + 1;
        end else begin
          output_fifo_ready_o <= 0;
        end
      end

      if (current_i >= num_input_rows) begin
        output_fifo_ready_o <= 0;
        output_fifo_reread <= 1;
        state <= IDLE;
      end
    end
  end

  assign activation_select_out = activation_select_in;
  assign enable_cycles_gatekeeper = num_input_rows;
  assign exec_ready_o = !in_progress && state == IDLE;

endmodule
