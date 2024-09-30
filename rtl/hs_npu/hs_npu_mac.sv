module hs_npu_mac (
    input  logic               clk,        // Clock signal
    input  logic               enable_in,  // Enable input signal for weights
    input  logic signed [15:0] a_in,       // Input for matrix A element (a_ij)
    input  logic signed [15:0] b_in,       // Input for matrix B element (b_ij)
    input  logic signed [31:0] sum,        // Input for sum (C)
    output logic signed [15:0] a_out,      // Output for matrix A element (passed forward)
    output logic signed [15:0] b_out,      // Output for matrix B element (passed downward)
    output logic signed [31:0] result      // Output for the result of A*B + C
);

  // Flip-flops to store inputs A and B
  logic signed [15:0] a_ff, b_ff;

  // Flip-flop to store the result
  logic signed [31:0] result_ff;

  always_ff @(posedge clk) begin
    // Register the input A and the persistent B value
    a_ff <= a_in;
    if (enable_in) begin
      b_ff <= b_in;  // Register B only when enable_in is high
    end

    // Perform the multiply-accumulate operation and register the result
    result_ff <= (a_in * b_ff) + sum;
  end

  // Assign registered result to output
  assign result = result_ff;

  // Pass forward the inputs to the outputs (these go to the next MAC units)
  assign a_out  = a_ff;
  assign b_out  = b_ff;

endmodule
