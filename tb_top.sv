/******************************************************************************
 * Project     : AXI4 UVM Verification
 * File        : tb_top.sv
 * Author      : Mirza Agha Malik Baig
 * Description : Creates clock and reset, connects interface and DUT,
 *               configures UVM, and starts the test.
 *****************************************************************************/

`include "uvm_macros.svh"
import uvm_pkg::*;


// -------------------------------------------------
// AXI UVM files
// -------------------------------------------------

`include "axi_if.sv"
`include "axi_assertions.sv"
`include "axi_txn.sv"
`include "axi_sequence.sv"
`include "axi_sequencer.sv"
`include "axi_driver.sv"
`include "axi_monitor.sv"
`include "axi_scoreboard.sv"
`include "axi_coverage.sv"
`include "axi_agent.sv"
`include "axi_env.sv"
`include "axi_test.sv"


// =================================================
// TOP
// =================================================

module top;

  logic clk = 0;
  logic resetn;

  // Clock
  always #5 clk = ~clk;


  // Real AXI interface instance
  axi_if axi0 (
    .aclk    (clk),
    .aresetn (resetn)
  );


  // AXI memory slave DUT
  axi_mem_slave dut (
    .axi (axi0)
  );

  // Cycle-level AXI protocol checks
  axi_assertions axi_assertions_i (
    .axi (axi0)
  );


  // -------------------------------------------------
  // RESET THREAD
  // -------------------------------------------------

  initial begin

    resetn = 0;

    repeat (2)
      @(posedge clk);

    resetn = 1;

  end


  // -------------------------------------------------
  // UVM THREAD
  // -------------------------------------------------

  initial begin

    uvm_config_db#(virtual axi_if)::set(
      null,
      "*",
      "vif",
      axi0
    );

    run_test("axi_test");

  end

endmodule