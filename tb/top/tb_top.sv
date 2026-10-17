/******************************************************************************
*** AXI4 UVM Verification                                                 ***
*** Author: Mirza Agha Malik Baig                                         ***
*** Updated: October 2026                                                 ***
*** Filename: tb_top.sv                                                   ***
*** Description: Instantiates DUT, interface, clock, reset, and UVM test. ***
******************************************************************************/

`timescale 1ns/1ps
`include "uvm_macros.svh"
import uvm_pkg::*;

// AXI UVM files

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

module top;

  logic clk = 0;
  logic resetn;

  // Clock
  always #5 clk = ~clk;

  // interface
  axi_if axi0 (
    .aclk    (clk),
    .aresetn (resetn)
  );

  // memory slave DUT
  axi_mem_slave dut (
    .axi (axi0)
  );

  // basic AXI protocol checks
  axi_assertions axi_assertions_i (
    .axi (axi0)
  );

  initial begin

    resetn = 0;

    repeat (2)
      @(posedge clk);

    resetn = 1;

  end

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
