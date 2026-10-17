/******************************************************************************
*** AXI4 UVM Verification                                                 ***
*** Author: Mirza Agha Malik Baig                                         ***
*** Updated: October 2026                                                 ***
*** Filename: axi_if.sv                                                   ***
*** Description: Declares AXI4 AW, W, B, AR, and R interface signals.     ***
******************************************************************************/

interface axi_if #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32,
    parameter int ID_WIDTH   = 4
)(
    input logic aclk,
    input logic aresetn
);

    // WRITE ADDRESS CHANNEL (AW)
    // Master -> Slave

    logic [ID_WIDTH-1:0]   awid;
    logic [ADDR_WIDTH-1:0] awaddr;
    logic [7:0]            awlen;
    logic [2:0]            awsize;
    logic [1:0]            awburst;
    logic                  awvalid;
    logic                  awready;

    // WRITE DATA CHANNEL (W)
    // Master -> Slave

    logic [DATA_WIDTH-1:0]   wdata;
    logic [(DATA_WIDTH/8)-1:0] wstrb;
    logic                    wlast;
    logic                    wvalid;
    logic                    wready;

    // WRITE RESPONSE CHANNEL (B)
    // Slave -> Master

    logic [ID_WIDTH-1:0] bid;
    logic [1:0]          bresp;
    logic                bvalid;
    logic                bready;

    // READ ADDRESS CHANNEL (AR)
    // Master -> Slave

    logic [ID_WIDTH-1:0]   arid;
    logic [ADDR_WIDTH-1:0] araddr;
    logic [7:0]            arlen;
    logic [2:0]            arsize;
    logic [1:0]            arburst;
    logic                  arvalid;
    logic                  arready;

    // READ DATA CHANNEL (R)
    // Slave -> Master

    logic [ID_WIDTH-1:0]   rid;
    logic [DATA_WIDTH-1:0] rdata;
    logic [1:0]            rresp;
    logic                  rlast;
    logic                  rvalid;
    logic                  rready;

endinterface
