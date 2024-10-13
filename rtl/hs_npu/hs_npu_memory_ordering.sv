module hs_npu_memory_ordering
  import hs_npu_pkg::*;
#(
    parameter int SIZE = 8,  // Number of rows and columns of the systolic array
    parameter int BUFFER_SIZE = 16,  // Maximum number of inferences the system can hold
    parameter int OUTPUT_DATA_WIDTH = 32,
    parameter int INPUT_DATA_WIDTH = 16,
    parameter int WORDS_PER_LINE = SIZE * 8 / 32  // SYS_SIZE x INT8 / WORD_LENGTH
) (
    input logic clk,
    input logic rst_n,

    // Executive control signals
    input  exec_valid_i,
    output exec_ready_o,
    output finished,

    // Memory control signals
    input  mem_valid_i,
    input  mem_ready_i,
    output mem_read_ready_o,
    output mem_write_valid_o,
    output mem_reset,

    // Data matrices from memory
    input  uword memory_data_in [WORDS_PER_LINE],
    output uword memory_data_out[WORDS_PER_LINE],
    output uword request_address,

    // Input and weight matrices dimensions from CPU
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

    // Control signals for matrix multiplication unit and FIFOs
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
    output uword shift_amount_out,

    output logic [INPUT_DATA_WIDTH-1:0] output_weights[SIZE],
    output logic [INPUT_DATA_WIDTH-1:0] output_inputs[SIZE],
    output logic [OUTPUT_DATA_WIDTH-1:0] output_bias[SIZE],
    output logic [OUTPUT_DATA_WIDTH-1:0] output_sums[SIZE],

    input logic [INPUT_DATA_WIDTH-1:0] inference_result[SIZE]  // Final output from inference
);

  // States for the state machine
  typedef enum logic [2:0] {
    IDLE,
    LOADING_WEIGHTS,
    LOADING_INPUTS,
    LOADING_BIAS,
    LOADING_SUMS,
    READY_TO_COMPUTE,
    SAVING
  } loading_state_t;

  loading_state_t state;

  // Registers for control and operation
  logic in_progress;
  uword num_input_rows, num_input_columns, num_weight_rows, num_weight_columns;
  logic reuse_inputs, reuse_weights, save_outputs, use_bias, use_sum, activation_select;
  uword shift_amount, result_address;
  uword computation_cycles, current_i, request_addr;
  logic write_valid_aux, read_ready_aux;
  logic [OUTPUT_DATA_WIDTH-1:0] sums[SIZE], bias[SIZE];
  logic [OUTPUT_DATA_WIDTH-1:0] results[SIZE];
  uword output_counter;

  // Unified always_ff block for state transitions and operations
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // Reset logic
      in_progress <= 0;
      state <= IDLE;

      num_input_rows <= '0;
      num_input_columns <= '0;
      num_weight_rows <= '0;
      num_weight_columns <= '0;

      reuse_inputs <= 0;
      reuse_weights <= 0;
      save_outputs <= 0;
      shift_amount <= 0;
      activation_select <= 0;
      result_address <= '0;
      use_bias <= 0;
      use_sum <= 0;

      current_i <= 0;
      computation_cycles <= '0;
      request_addr <= '0;
      output_counter <= 0;
      write_valid_aux <= 0;
      read_ready_aux <= 0;

      finished <= 0;

      for (int i = 0; i < SIZE; i++) begin
        sums[i] <= '0;
        bias[i] <= '0;
        results[i] <= '0;
      end
    end else begin
      // Flop control signals and progress
      case (state)
        IDLE: begin
          finished <= 0;
          if (exec_valid_i && !in_progress) begin
            // Capture the layer control signals
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
            result_address <= result_address_in;
            use_bias <= use_bias_in;
            use_sum <= use_sum_in;

            current_i <= 0;
            computation_cycles <= 0;
            request_addr <= base_address_in;
            output_counter <= 0;
            write_valid_aux <= 0;
            read_ready_aux <= 1;
            state <= LOADING_WEIGHTS;
          end
        end

        LOADING_WEIGHTS: begin
          if (mem_valid_i && current_i <= num_weight_rows && !reuse_weights) begin
            // Load weights into output_weights
            for (int bundle_idx = 0; bundle_idx < WORDS_PER_LINE; bundle_idx++) begin
              for (int weight_idx = 0; weight_idx < 4; weight_idx++) begin
                output_weights[weight_idx+(bundle_idx*4)] <= {
                  {8{memory_data_in[bundle_idx][8*weight_idx+7]}},
                  memory_data_in[bundle_idx][8*weight_idx+:8]
                };
              end
            end
            weight_fifo_valid_o <= 1;
            current_i <= current_i + 1;
            request_addr <= request_addr + (4 * WORDS_PER_LINE);
          end else begin
            weight_fifo_valid_o <= 0;
            if (current_i == 0 && !reuse_weights) begin
              current_i <= current_i + 1;
              request_addr <= request_addr + (4 * WORDS_PER_LINE);
            end
          end
          if (current_i > num_weight_rows) begin
            state <= LOADING_INPUTS;
            current_i <= 0;
            weight_fifo_valid_o <= 0;
            if (reuse_inputs) read_ready_aux <= 0;
            else read_ready_aux <= 1;
          end
          if (reuse_weights) begin
            state <= LOADING_INPUTS;
            current_i <= 0;
            weight_fifo_valid_o <= 0;
            if (reuse_inputs) read_ready_aux <= 0;
            else read_ready_aux <= 1;
          end
        end

        LOADING_INPUTS: begin
          if (mem_valid_i || reuse_inputs) begin
            if (!reuse_inputs) begin
              // Load inputs from memory
              for (int bundle_idx = 0; bundle_idx < WORDS_PER_LINE; bundle_idx++) begin
                for (int input_idx = 0; input_idx < 4; input_idx++) begin
                  output_inputs[input_idx+(bundle_idx*4)] <= {
                    {8{memory_data_in[bundle_idx][8*input_idx+7]}},
                    memory_data_in[bundle_idx][8*input_idx+:8]
                  };
                end
              end
              request_addr <= request_addr + (4 * WORDS_PER_LINE);
            end else begin
              // Load inputs from past inference results
              for (int input_idx = 0; input_idx < SIZE; input_idx++) begin
                output_inputs[SIZE - num_input_columns + input_idx] <= inference_result[input_idx][15:0];
              end
            end
            input_fifo_valid_o <= 1;
            current_i <= current_i + 1;
          end else begin
            input_fifo_valid_o <= 0;
          end
          if (current_i >= num_input_rows - 1) begin
            if (!use_bias & !use_sum) read_ready_aux <= 0;
            else read_ready_aux <= 1;
          end
          if (current_i >= num_input_rows) begin
            state <= LOADING_BIAS;
            current_i <= 0;
            input_fifo_valid_o <= 0;
          end
        end

        LOADING_BIAS: begin
          if (use_bias) begin
            if (mem_valid_i && current_i < SIZE) begin
              for (int bundle_idx = 0; bundle_idx < WORDS_PER_LINE; bundle_idx++) begin
                bias[current_i+bundle_idx] <= memory_data_in[bundle_idx];
              end
              current_i <= current_i + WORDS_PER_LINE;
              request_addr <= request_addr + (4 * WORDS_PER_LINE);
            end else begin
              if (current_i >= SIZE) begin
                state <= LOADING_SUMS;
                current_i <= 0;
                if (!use_sum) read_ready_aux <= 0;
                else read_ready_aux <= 1;
              end
            end
            if (current_i == SIZE - WORDS_PER_LINE && !use_sum) read_ready_aux <= 0;
          end else begin
            // Skip loading bias if not in use
            for (int i = 0; i < SIZE; i++) begin
              bias[i] <= '0;
            end
            state <= LOADING_SUMS;
            if (!use_sum) read_ready_aux <= 0;
            else read_ready_aux <= 1;
          end
        end

        LOADING_SUMS: begin
          if (use_sum) begin
            if (mem_valid_i && current_i < SIZE) begin
              for (int bundle_idx = 0; bundle_idx < WORDS_PER_LINE; bundle_idx++) begin
                sums[current_i+bundle_idx] <= memory_data_in[bundle_idx];
              end
              current_i <= current_i + WORDS_PER_LINE;
              request_addr <= request_addr + (4 * WORDS_PER_LINE);
            end else begin
              if (current_i == SIZE - WORDS_PER_LINE) read_ready_aux <= 0;
              if (current_i >= SIZE) begin
                state <= READY_TO_COMPUTE;
              end
            end
          end else begin
            // Skip loading sums if not in use
            for (int i = 0; i < SIZE; i++) begin
              sums[i] <= '0;
            end
            state <= READY_TO_COMPUTE;
          end
        end

        READY_TO_COMPUTE: begin
          computation_cycles <= computation_cycles + 1;

          if (computation_cycles == 0 && !reuse_weights) begin
            weight_enable <= 1;
          end

          if (computation_cycles == SIZE) begin
            weight_enable <= 0;
            start_input_gatekeeper <= 1;
          end

          if (computation_cycles == SIZE + 1) begin
            start_input_gatekeeper <= 0;
          end

          if (computation_cycles == 2 * SIZE) begin
            start_output_gatekeeper <= 1;
          end

          if (computation_cycles == 2 * SIZE + 1) begin
            start_output_gatekeeper <= 0;
          end

          if (computation_cycles == 3 * SIZE + num_input_rows) begin
            request_addr <= result_address;
            current_i <= -1;
            state <= SAVING;
          end
        end

        SAVING: begin
          // Save the final results into memory or CPU, based on save_outputs
          if (save_outputs) begin
            if (current_i == -1) begin
              for (int idx = 0; idx < SIZE; idx++) begin
                results[idx] <= {{16{inference_result[idx][15]}}, inference_result[idx]};
                output_counter <= output_counter + 1;
                current_i <= 0;
              end
            end else begin
              if (mem_ready_i && current_i <= SIZE) begin
                // Logic to save output results
                for (int bundle_idx = 0; bundle_idx < WORDS_PER_LINE; bundle_idx++) begin
                  memory_data_out[bundle_idx] <= results[current_i+bundle_idx];
                end
                write_valid_aux <= 1;
                current_i <= current_i + WORDS_PER_LINE;
                request_addr <= request_addr + (4 * WORDS_PER_LINE);
              end
              if (current_i > SIZE) begin
                current_i <= -1;
                write_valid_aux <= 0;
              end
            end
            if (output_counter > num_input_rows) begin
              state <= IDLE;
              in_progress <= 0;
              finished <= 1;
            end
          end else begin
            // No save required, return to IDLE
            state <= IDLE;
            current_i <= 0;
            computation_cycles <= 0;
            output_counter <= 0;
            write_valid_aux <= 0;
            in_progress <= 0;
            finished <= 1;
          end
        end

        default: state <= IDLE;
      endcase
    end
  end

  // Memory interface logic
  assign request_address = request_addr;

  // Input/output ready/valid signals
  assign exec_ready_o = (state == IDLE);
  assign mem_read_ready_o = ( state == LOADING_WEIGHTS || state == LOADING_INPUTS && !reuse_inputs || state == LOADING_BIAS || state == LOADING_SUMS) && read_ready_aux;
  assign mem_write_valid_o = (state == SAVING && current_i != -1 && output_counter <= num_input_rows && write_valid_aux);
  assign mem_reset = (state == IDLE);

  assign flush_input_fifos = (state == SAVING);
  assign flush_weight_fifos = (state == SAVING);
  assign flush_output_fifos = (state == LOADING_BIAS);

  assign output_fifo_ready_o = ((state == SAVING && current_i == -1) || (state == LOADING_INPUTS && reuse_inputs) || (state == LOADING_WEIGHTS && current_i > num_weight_rows && reuse_inputs));
  assign output_fifo_reread = (state == IDLE);

  assign activation_select_out = activation_select;
  assign shift_amount_out = shift_amount;
  assign bias_enable = (state == LOADING_BIAS);
  assign enable_cycles_gatekeeper = num_input_rows;

  assign output_bias = bias;
  assign output_sums = sums;

endmodule
