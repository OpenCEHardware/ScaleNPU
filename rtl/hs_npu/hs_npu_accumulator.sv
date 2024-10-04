module hs_npu_accumulator
#(
    parameter int OUTPUT_DATA_WIDTH = 32  // Output data width (int32)
) (
    input logic clk,
    input logic rst_n,

    // Input data and control signals
    input logic [OUTPUT_DATA_WIDTH-1:0] input_data,  // Input data
    input logic valid_i,  // Valid signal to trigger output
    input logic [OUTPUT_DATA_WIDTH-1:0] bias_in,  // Bias input
    input logic bias_en,  // Enable signal for loading bias

    // Output signals
    output logic [OUTPUT_DATA_WIDTH-1:0] result,  // Accumulated result
    output logic valid_o  // Valid signal indicating result is valid
);

  // Flopped bias value
  logic [OUTPUT_DATA_WIDTH-1:0] bias;

  // Bias update logic (only updates when bias_en is asserted)
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // Reset bias value to zero
      bias <= '0;
    end else if (bias_en) begin
      // Load new bias when bias_en is asserted
      bias <= bias_in;
    end
  end

  // Combinational output and valid signal logic
  always_comb begin
    if (valid_i) begin
      // Sum input_data with the stored bias and output the result
      result = input_data + bias;
      valid_o = 1'b1;  // Assert valid_out when result is valid
    end else begin
      result = '0;
      valid_o = 1'b0;  // Deassert valid_out when no valid input
    end
  end

endmodule
