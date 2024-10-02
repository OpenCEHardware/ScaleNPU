module hs_npu_gatekeeper
  import hs_npu_pkg::*;
#(
    parameter int DATA_WIDTH = 32  // Parameter for the size of input_data and output_data
) (
    input  logic                  clk,
    input  logic                  rst_n,
    input  logic [DATA_WIDTH-1:0] input_data,
    input  uword                  enable_cycles_in,
    input  logic                  start_in,
    output logic [DATA_WIDTH-1:0] output_data,
    output logic                  start_out,
    output logic                  active // This signal serves as either a ready or a valid
);
  // Internal variables
  uword enable_cycles;

  // Combinational logic for data flow when active is asserted
  always_comb begin
    if (active) begin
      output_data = input_data;
    end else begin
      output_data = '0;
    end
  end

  // Combinational logic for active signal
  always_comb begin
    if (enable_cycles > 0) begin
      active = 1;
    end else begin
      active = 0;
    end
  end

  // State initialization and enable cycle handling
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      enable_cycles <= '0;
    end else begin
      // If start_in is asserted, update enable_cycles
      if (start_in) begin
        enable_cycles <= enable_cycles_in;
      end

      // Enable cycles decrement
      if (enable_cycles > 0) begin
        enable_cycles <= enable_cycles - 1;
      end

      // Pass previous start signal to the next keeper
      start_out <= start_in;
    end
  end
endmodule
