module hs_npu_mac
  import hs_npu_pkg::*;
(
    input  logic clk,        // Clock signal
    input  logic enable_in,  // Enable input signal for weights
    input  short a_in,       // Input for matrix A element (a_ij)
    input  short b_in,       // Input for matrix B element (b_ij)
    input  word  sum,        // Input for sum (C)
    output short a_out,      // Output for matrix A element (passed forward)
    output short b_out,      // Output for matrix B element (passed downward)
    output word  result      // Output for the result of A*B + C
);

  // Flip-flops to store inputs A and B
  short a_ff, b_ff;

  always_ff @(posedge clk) begin
    // Register the input A and the persistent B value
    a_ff <= a_in;
    if (enable_in) begin
      b_ff <= b_in;  // Register B only when enable_in is high
    end
    // Perform the multiply-accumulate operation and set the result
    result <= (a_in * b_ff) + sum;
  end


  // Pass forward the inputs to the outputs (these go to the next MAC units)
  assign a_out = a_ff;
  assign b_out = b_ff;

endmodule
