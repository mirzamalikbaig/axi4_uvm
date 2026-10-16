/******************************************************************************
 * Project     : AXI4 UVM Verification
 * File        : axi_assertions.sv
 * Author      : Mirza Agha Malik Baig
 * Description : Cycle-level AXI VALID/READY stability assertions.
 *****************************************************************************/

module axi_assertions(axi_if axi);

  // A source must keep AWVALID and the AW payload stable while stalled.
  property p_aw_stable;
    @(posedge axi.aclk) disable iff (!axi.aresetn)
      axi.awvalid && !axi.awready
      |=> axi.awvalid &&
          $stable({axi.awid, axi.awaddr, axi.awlen, axi.awsize, axi.awburst});
  endproperty

  a_aw_stable: assert property (p_aw_stable);

  // A source must keep WVALID and the W payload stable while stalled.
  property p_w_stable;
    @(posedge axi.aclk) disable iff (!axi.aresetn)
      axi.wvalid && !axi.wready
      |=> axi.wvalid &&
          $stable({axi.wdata, axi.wstrb, axi.wlast});
  endproperty

  a_w_stable: assert property (p_w_stable);

  // A source must keep ARVALID and the AR payload stable while stalled.
  property p_ar_stable;
    @(posedge axi.aclk) disable iff (!axi.aresetn)
      axi.arvalid && !axi.arready
      |=> axi.arvalid &&
          $stable({axi.arid, axi.araddr, axi.arlen, axi.arsize, axi.arburst});
  endproperty

  a_ar_stable: assert property (p_ar_stable);

  // The slave must hold the read response stable until the master accepts it.
  property p_r_stable;
    @(posedge axi.aclk) disable iff (!axi.aresetn)
      axi.rvalid && !axi.rready
      |=> axi.rvalid &&
          $stable({axi.rid, axi.rdata, axi.rresp, axi.rlast});
  endproperty

  a_r_stable: assert property (p_r_stable);

  // The slave must hold the write response stable until the master accepts it.
  property p_b_stable;
    @(posedge axi.aclk) disable iff (!axi.aresetn)
      axi.bvalid && !axi.bready
      |=> axi.bvalid &&
          $stable({axi.bid, axi.bresp});
  endproperty

  a_b_stable: assert property (p_b_stable);

endmodule
