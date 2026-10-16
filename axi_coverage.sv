/******************************************************************************
 * Project     : AXI4 UVM Verification
 * File        : axi_coverage.sv
 * Author      : Mirza Agha Malik Baig
 * Description : Functional coverage sampled from completed monitor
 *               transactions.
 *****************************************************************************/

class axi_coverage extends uvm_subscriber #(axi_txn);

  `uvm_component_utils(axi_coverage)

  bit       sample_op;
  bit [1:0] sample_burst;
  bit [2:0] sample_size;
  bit [7:0] sample_len;
  bit [3:0] sample_id;
  bit [1:0] sample_resp;

  covergroup axi_cg;
    option.per_instance = 1;

    cp_op: coverpoint sample_op {
      bins READ  = {0};
      bins WRITE = {1};
    }

    cp_burst: coverpoint sample_burst {
      bins FIXED = {2'b00};
      bins INCR  = {2'b01};
      bins WRAP  = {2'b10};
      illegal_bins RESERVED = {2'b11};
    }

    cp_size: coverpoint sample_size {
      bins WORD_32BIT = {2};
      ignore_bins NARROW_OUT_OF_SCOPE = {0, 1};
    }

    cp_len: coverpoint sample_len {
      bins SINGLE = {0};
      bins MULTI  = {[1:255]};
    }

    cp_id: coverpoint sample_id {
      bins LOW_IDS  = {[0:7]};
      bins HIGH_IDS = {[8:15]};
    }

    cp_resp: coverpoint sample_resp {
      bins OKAY = {2'b00};
      ignore_bins ERROR_RESPONSES_OUT_OF_SCOPE = {2'b01, 2'b10, 2'b11};
    }

    op_x_burst: cross cp_op, cp_burst;
    burst_x_len: cross cp_burst, cp_len;

  endgroup

  function new(string name = "axi_coverage",
               uvm_component parent = null);
    super.new(name, parent);
    axi_cg = new();
  endfunction

  function void write(axi_txn txn);
    sample_op    = txn.op;
    sample_burst = txn.burst;
    sample_size  = txn.size;
    sample_len   = txn.len;
    sample_id    = txn.id;

    if (txn.op == axi_txn::AXI_WRITE)
      sample_resp = txn.bresp;
    else if (txn.rresp.size() > 0)
      sample_resp = txn.rresp[txn.rresp.size()-1];
    else
      sample_resp = axi_txn::OKAY;

    axi_cg.sample();
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("COV",
      $sformatf("AXI functional coverage = %0.2f%%",
                axi_cg.get_inst_coverage()),
      UVM_LOW)
  endfunction

endclass
