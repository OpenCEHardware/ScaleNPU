module hs_npu_top_flat
  import hs_npu_pkg::*;
(
    input logic clk,
    input logic rst_n,

    output logic irq_cpu,

    // Flattened axi4lite_intf master signals
    output logic csr_AWREADY,
    input logic csr_AWVALID,
    input logic [31:0] csr_AWADDR,
    input logic [2:0] csr_AWPROT,

    output logic csr_WREADY,
    input logic csr_WVALID,
    input logic [31:0] csr_WDATA,
    input logic [3:0] csr_WSTRB,

    input logic csr_BREADY,
    output logic csr_BVALID,
    output logic [1:0] csr_BRESP,

    output logic csr_ARREADY,
    input logic csr_ARVALID,
    input logic [31:0] csr_ARADDR,
    input logic [2:0] csr_ARPROT,

    input logic csr_RREADY,
    output logic csr_RVALID,
    output logic [31:0] csr_RDATA,
    output logic [1:0] csr_RRESP,

    // Flattened axib_if master signals
    input logic mem_awready,
    output logic mem_awvalid,
    output logic [7:0] mem_awid,
    output logic [7:0] mem_awlen,
    output logic [31:0] mem_awaddr,
    output logic [2:0] mem_awsize,
    output logic [1:0] mem_awburst,

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

    output logic mem_rready,
    input logic mem_rvalid,
    input logic [7:0] mem_rid,
    input logic [31:0] mem_rdata,
    input logic [1:0] mem_rresp,
    input logic mem_rlast
);

  // Instantiate the interfaces
  axi4lite_intf csr ();
  axib_if mem ();

  // Map the flattened signals to the interface signals
  assign csr_AWREADY = csr.master.AWREADY;
  assign csr.master.AWVALID = csr_AWVALID;
  assign csr.master.AWADDR  = csr_AWADDR;
  assign csr.master.AWPROT  = csr_AWPROT;

  assign csr_WREADY = csr.master.WREADY;
  assign csr.master.WVALID = csr_WVALID;
  assign csr.master.WDATA  = csr_WDATA;
  assign csr.master.WSTRB  = csr_WSTRB;

  assign csr.master.BREADY = csr_BREADY;
  assign csr_BVALID = csr.master.BVALID;
  assign csr_BRESP  = csr.master.BRESP;

  assign csr_ARREADY = csr.master.ARREADY;
  assign csr.master.ARVALID = csr_ARVALID;
  assign csr.master.ARADDR  = csr_ARADDR;
  assign csr.master.ARPROT  = csr_ARPROT;

  assign csr.master.RREADY = csr_RREADY;
  assign csr_RVALID = csr.master.RVALID;
  assign csr_RDATA  = csr.master.RDATA;
  assign csr_RRESP  = csr.master.RRESP;

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

  assign mem_rready = mem.m.rready;
  assign mem.s.rvalid = mem_rvalid;
  assign mem.s.rid    = mem_rid;
  assign mem.s.rdata  = mem_rdata;
  assign mem.s.rresp  = mem_rresp;
  assign mem.s.rlast  = mem_rlast;

  // Instantiate the original top module using the interfaces
  hs_npu_top hs_npu (
    .clk(clk),
    .rst_n(rst_n),
    .irq_cpu(irq_cpu),
    .csr(csr.slave),
    .mem(mem.m)
  );

endmodule
