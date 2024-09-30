module hs_fifo #(
    int WIDTH = 1,
    int DEPTH = 1
) (
    input logic clk_core,
    input logic rst_core_n,

    input logic flush,

    output logic               ready_o,
    input  logic               valid_i,
    input  logic [WIDTH - 1:0] in,

    input  logic               ready_i,
    output logic               valid_o,
    output logic [WIDTH - 1:0] out
);

  // Least number of bits required to represent integers from 0 to DEPTH - 1
  localparam int PtrBits = $clog2(DEPTH);

  logic can_read, can_write, out_stall, was_stalled;
  logic [WIDTH - 1:0] fifo[DEPTH], read_data, stall_data;
  logic [PtrBits - 1:0] read_ptr, read_ptr_next, write_ptr, write_ptr_next;

  // See the note below regarding read enables on Altera devices
  assign out = was_stalled ? stall_data : read_data;
  assign out_stall = ~ready_i & valid_o;

  assign can_read = read_ptr != write_ptr;
  assign can_write = write_ptr_next != read_ptr;

  assign ready_o = can_write;

  always_comb begin
    read_ptr_next  = read_ptr + 1;
    write_ptr_next = write_ptr + 1;

    // These checks are free if DEPTH is a power of two: they become
    // equivalent to 'if (ptr_next == 0) ptr_next = 0;'

    if (read_ptr_next == PtrBits'(DEPTH)) read_ptr_next = '0;

    if (write_ptr_next == PtrBits'(DEPTH)) write_ptr_next = '0;
  end

  always_ff @(posedge clk_core or negedge rst_core_n)
    if (~rst_core_n) begin
      read_ptr  <= '0;
      write_ptr <= '0;

      valid_o   <= 0;
    end else begin
      if (ready_o & valid_i) write_ptr <= write_ptr_next;

      if (~out_stall) begin
        valid_o <= can_read;
        if (can_read) read_ptr <= read_ptr_next;
      end

      if (flush) begin
        read_ptr  <= '0;
        write_ptr <= '0;

        valid_o   <= 0;
      end
    end

  always_ff @(posedge clk_core) begin
    if (can_write) fifo[write_ptr] <= in;

    // We can't put a similar 'if (ready_i & valid_o)' condition here
    // because block memories in Altera FPGAs can't infer read enables.
    // Instead, we read on every cycle and handle the stall case manually
    // on the next cycle.
    //
    // https://community.intel.com/t5/Programmable-Devices/Has-anyone-successfully-inferred-read-enable-ports-on-true-dual/m-p/146996
    read_data <= fifo[read_ptr];

    if (~was_stalled) stall_data <= read_data;

    was_stalled <= out_stall;
  end

endmodule
