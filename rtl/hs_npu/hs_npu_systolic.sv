module hs_npu_systolic
  import hs_npu_pkg::*;
#(
    parameter int SIZE = 8  // Parameter for the size of the array (default 8)
) (
    input  logic clk,              // Clock signal
    input  logic enable_in,        // Enable signal for the systolic array
    input  short matrixA  [SIZE],  // Input values for matrix A (one per column)
    input  short matrixB  [SIZE],  // Input values for matrix B (one per row)
    input  word  sum_in   [SIZE],  // Input sums for the first row
    output word  result   [SIZE]   // Output values from the last row
);

  logic signed [15:0] a_wire  [SIZE][SIZE];  // Wires for A values passing to the right
  logic signed [15:0] b_wire  [SIZE][SIZE];  // Wires for B values passing downward
  logic signed [31:0] sum_wire[SIZE][SIZE];  // Wires for sum values

  genvar i, j;
  generate
    for (i = 0; i < SIZE; i++) begin : gen_col
      for (j = 0; j < SIZE; j++) begin : gen_row
        // Connect inputs and outputs for each MAC unit
        hs_npu_mac mac_unit (
            .clk(clk),
            .enable_in(enable_in),
            .a_in(i == 0 ? matrixA[j] : a_wire[i-1][j]),   // First row gets inputs from matrix A, others from previous column
            .b_in(j == 0 ? matrixB[i] : b_wire[i][j-1]),   // First column gets inputs from matrix B, others from previous row
            .sum(j == 0 ? sum_in[i] : sum_wire[i][j-1]),   // First column gets initial sum, others from previous row
            .a_out(a_wire[i][j]),  // Forward A to the next MAC unit in the same row
            .b_out(b_wire[i][j]),  // Pass B downward to the next MAC unit in the same column
            .result(sum_wire[i][j])  // Internal result wire
        );
      end
    end
  endgenerate

  // Collect results from the last row of MAC units
  generate
    for (j = 0; j < SIZE; j++) begin : gen_results
      assign result[j] = sum_wire[j][SIZE-1];
    end
  endgenerate

endmodule
