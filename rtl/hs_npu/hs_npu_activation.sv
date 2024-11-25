module hs_npu_activation #(
    // Input data width
    parameter int DATA_WIDTH   = 32,
    // Output data width (only the first OUTPUT_WIDTH bits of result)
    parameter int OUTPUT_WIDTH = 16
) (
    input logic [DATA_WIDTH-1:0] input_data,  // Input data from accumulator
    input logic valid_i,  // Valid input signal
    input logic relu_en,  // Enable signal for ReLU
    input logic [DATA_WIDTH-1:0] shift_amount,  // Input shift amount

    // Output signals
    // Output after ReLU and shift (truncated to OUTPUT_WIDTH bits)
    output logic [OUTPUT_WIDTH-1:0] result,
    output logic valid_o  // Valid output signal
);

  // Declare intermediate signals outside of the always_comb block
  logic [DATA_WIDTH-1:0] relu_result;
  logic [DATA_WIDTH-1:0] shifted_result;

  // ReLU and shift logic
  always_comb begin
    // Default assignments to prevent latch inference
    relu_result = '0;
    shifted_result = '0;
    result = '0;
    valid_o = 1'b0;

    if (valid_i) begin
      // Apply ReLU only if relu_en is asserted
      if (relu_en) begin
        // ReLU: max(input_data, 0)
        relu_result = (input_data[DATA_WIDTH-1] == 1'b0) ? input_data : '0;
      end else begin
        // If ReLU is disabled, pass input_data directly
        relu_result = input_data;
      end

      // Apply arithmetic right shift
      shifted_result = $signed(relu_result) >>> shift_amount;

      // Truncate to OUTPUT_WIDTH bits and assign to result
      result = shifted_result[OUTPUT_WIDTH-1:0];

      // Assert valid output
      valid_o = 1'b1;
    end
  end

endmodule
