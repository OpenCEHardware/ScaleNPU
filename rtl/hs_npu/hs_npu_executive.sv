module hs_npu_executive
  import hs_npu_pkg::*;
(

    input logic clk,
    input logic rst_n,

    // CSR interface
    output hs_npu_ctrlstatus_regs_pkg::hs_npu_ctrlstatus_regs__in_t hwif_in,
    input hs_npu_ctrlstatus_regs_pkg::hs_npu_ctrlstatus_regs__out_t hwif_out,
    output irq,

    // Memory ordering unit control signals
    input  logic memory_ordering_ready_i,
    output logic memory_ordering_valid_o,
    input  logic finished,

    // CPU input and weight matrix dimensions
    output uword num_input_rows_out,
    output uword num_input_columns_out,
    output uword num_weight_rows_out,
    output uword num_weight_columns_out,

    // CPU layer control flags
    output logic reuse_inputs_out,
    output logic reuse_weights_out,
    output logic save_outputs_out,
    output logic use_bias_out,
    output logic use_sum_out,
    output uword shift_amount_out,
    output logic activation_select_out,

    output uword base_address_out,
    output uword result_address_out
);

  // Matrix dimensions
  assign num_input_rows_out = hwif_out.DIMS.INROWS.ROWS.value;
  assign num_input_columns_out = hwif_out.DIMS.INCOLS.COLS.value;
  assign num_weight_rows_out = hwif_out.DIMS.WGHTROWS.ROWS.value;
  assign num_weight_columns_out = hwif_out.DIMS.WGHTCOLS.COLS.value;

  assign reuse_inputs_out = hwif_out.CTRL.REINPUTS.REUSE.value;
  assign reuse_weights_out = hwif_out.CTRL.REWEIGHTS.REUSE.value;
  assign save_outputs_out = hwif_out.CTRL.SAVEOUT.SAVE.value;
  assign use_bias_out = hwif_out.CTRL.USEBIAS.USE.value;
  assign use_sum_out = hwif_out.CTRL.USESUMM.USE.value;
  assign shift_amount_out = hwif_out.CTRL.SHIFTAMT.AMOUNT.value;
  assign activation_select_out = hwif_out.CTRL.ACTFN.SELECT.value;

  assign base_address_out = hwif_out.MEMADDRS.BASE.ADDR.value;
  assign result_address_out = hwif_out.MEMADDRS.RESULT.ADDR.value;

  assign irq = finished;
  assign hwif_in.MAINCTRL.INIT.VALUE.hwclr = finished;
  assign hwif_in.MAINCTRL.EXITCODE.CODE.next = 1;  // This arch version doesn't check for errors yet

  always_ff @(posedge clk) begin

    // Validar datos y/o enviar error

    if (memory_ordering_ready_i) memory_ordering_valid_o <= hwif_out.MAINCTRL.INIT.VALUE.swmod;
    else memory_ordering_valid_o <= 0;
    if (memory_ordering_valid_o) memory_ordering_valid_o <= 0;

  end

endmodule

