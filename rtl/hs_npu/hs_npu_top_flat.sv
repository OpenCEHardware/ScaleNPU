module hs_npu_top_flat
  import hs_npu_pkg::*, hs_npu_ctrlstatus_regs_pkg::*;
(
    input logic clk_npu,
    input logic rst_n,

    output logic irq,

    // Flattened axi4lite_intf master signals
    output logic csr_awready,
    input logic csr_awvalid,
    input logic [15:0] csr_awaddr,
    input logic [2:0] csr_awprot,

    output logic csr_wready,
    input logic csr_wvalid,
    input logic [31:0] csr_wdata,
    input logic [3:0] csr_wstrb,

    input logic csr_bready,
    output logic csr_bvalid,
    output logic [1:0] csr_bresp,

    output logic csr_arready,
    input logic csr_arvalid,
    input logic [15:0] csr_araddr,
    input logic [2:0] csr_arprot,

    input logic csr_rready,
    output logic csr_rvalid,
    output logic [31:0] csr_rdata,
    output logic [1:0] csr_rresp,

    // Flattened axib_if master signals
    input logic mem_awready,
    output logic mem_awvalid,
    output logic [7:0] mem_awid,
    output logic [7:0] mem_awlen,
    output logic [31:0] mem_awaddr,
    output logic [2:0] mem_awsize,
    output logic [1:0] mem_awburst,
    output logic [2:0] mem_awprot,

    input logic mem_wready,
    output logic mem_wvalid,
    output logic [31:0] mem_wdata,
    output logic mem_wlast,
    output logic [3:0] mem_wstrb,

    output logic mem_bready,
    input logic mem_bvalid,
    input logic [7:0] mem_bid,
    input logic [1:0] mem_bresp,

    input logic mem_arready,
    output logic mem_arvalid,
    output logic [7:0] mem_arid,
    output logic [7:0] mem_arlen,
    output logic [31:0] mem_araddr,
    output logic [2:0] mem_arsize,
    output logic [1:0] mem_arburst,
    output logic [2:0] mem_arprot,

    output logic mem_rready,
    input logic mem_rvalid,
    input logic [7:0] mem_rid,
    input logic [31:0] mem_rdata,
    input logic [1:0] mem_rresp,
    input logic mem_rlast
);

  // Instantiate the interfaces
  axi4lite_intf #(.ADDR_WIDTH(HS_NPU_CTRLSTATUS_REGS_MIN_ADDR_WIDTH)) csr ();
  axib_if mem ();

  //
  assign mem_awprot = 3'b010;
  assign mem_arprot = 3'b010;

  // Map the flattened signals to the interface signals
  assign csr_awready = csr.master.AWREADY;
  assign csr.master.AWVALID = csr_awvalid;
  assign csr.master.AWADDR  = csr_awaddr[HS_NPU_CTRLSTATUS_REGS_MIN_ADDR_WIDTH - 1:0];
  assign csr.master.AWPROT  = csr_awprot;

  assign csr_wready = csr.master.WREADY;
  assign csr.master.WVALID = csr_wvalid;
  assign csr.master.WDATA  = csr_wdata;
  assign csr.master.WSTRB  = csr_wstrb;

  assign csr.master.BREADY = csr_bready;
  assign csr_bvalid = csr.master.BVALID;
  assign csr_bresp  = csr.master.BRESP;

  assign csr_arready = csr.master.ARREADY;
  assign csr.master.ARVALID = csr_arvalid;
  assign csr.master.ARADDR  = csr_araddr[HS_NPU_CTRLSTATUS_REGS_MIN_ADDR_WIDTH - 1:0];
  assign csr.master.ARPROT  = csr_arprot;

  assign csr.master.RREADY = csr_rready;
  assign csr_rvalid = csr.master.RVALID;
  assign csr_rdata  = csr.master.RDATA;
  assign csr_rresp  = csr.master.RRESP;

  // Map the flattened AXI4 full master interface signals
  assign mem.s.awready = mem_awready;
  assign mem_awvalid = mem.s.awvalid;
  assign mem_awid    = mem.s.awid;
  assign mem_awlen   = mem.s.awlen;
  assign mem_awaddr  = mem.s.awaddr;
  assign mem_awsize  = mem.s.awsize;
  assign mem_awburst = mem.s.awburst;

  assign mem.s.wready = mem_wready;
  assign mem_wvalid = mem.s.wvalid;
  assign mem_wdata  = mem.s.wdata;
  assign mem_wlast  = mem.s.wlast;
  assign mem_wstrb  = mem.s.wstrb;

  assign mem_bready = mem.s.bready;
  assign mem.s.bvalid = mem_bvalid;
  assign mem.s.bid    = mem_bid;
  assign mem.s.bresp  = mem_bresp;

  assign mem.s.arready = mem_arready;
  assign mem_arvalid = mem.s.arvalid;
  assign mem_arid    = mem.s.arid;
  assign mem_arlen   = mem.s.arlen;
  assign mem_araddr  = mem.s.araddr;
  assign mem_arsize  = mem.s.arsize;
  assign mem_arburst = mem.s.arburst;

  assign mem_rready = mem.s.rready;
  assign mem.s.rvalid = mem_rvalid;
  assign mem.s.rid    = mem_rid;
  assign mem.s.rdata  = mem_rdata;
  assign mem.s.rresp  = mem_rresp;
  assign mem.s.rlast  = mem_rlast;

  // Instantiate the original top module using the interfaces
  hs_npu_top hs_npu (
    .clk(clk_npu),
    .rst_n(rst_n),
    .irq_cpu(irq),
    .csr(csr.slave),
    .mem(mem.m)
  );

endmodule
