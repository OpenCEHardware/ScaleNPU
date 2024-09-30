// AXI4-Lite, sin wstrb ni axprot
interface axil_if #(
    int WIDTH = 32
);

  logic                   awvalid;
  logic                   awready;
  logic [    WIDTH - 1:0] awaddr;

  logic                   wvalid;
  logic                   wready;
  logic [    WIDTH - 1:0] wdata;
  logic [WIDTH / 8 - 1:0] wstrb;

  logic                   bvalid;
  logic                   bready;
  logic [            1:0] bresp;

  logic                   arvalid;
  logic                   arready;
  logic [    WIDTH - 1:0] araddr;

  logic                   rvalid;
  logic                   rready;
  logic [    WIDTH - 1:0] rdata;
  logic [            1:0] rresp;

  modport m(
      input awready, wready, bvalid, bresp, arready, rvalid, rdata, rresp,

      output awvalid, awaddr, wvalid, wdata, wstrb, bready, arvalid, araddr, rready
  );

  modport s(
      input awvalid, awaddr, wvalid, wdata, wstrb, bready, arvalid, araddr, rready,

      output awready, wready, bvalid, bresp, arready, rvalid, rdata, rresp
  );
endinterface
