/******************************************************************************
*** AXI4 UVM Verification                                                 ***
*** Author: Mirza Agha Malik Baig                                         ***
*** Updated: October 2026                                                 ***
*** Filename: axi_assertions.sv                                           ***
*** Description: Checks payload stability during VALID/READY stalls.      ***
******************************************************************************/

module axi_assertions(axi_if axi);

  // keep AW stable while the slave is not ready
  property p_aw_stable;
    @(posedge axi.aclk) disable iff (!axi.aresetn)
      axi.awvalid && !axi.awready
      |=> axi.awvalid &&
          $stable({axi.awid, axi.awaddr, axi.awlen, axi.awsize, axi.awburst});
  endproperty

  a_aw_stable: assert property (p_aw_stable);

  // keep W stable while the slave is not ready
  property p_w_stable;
    @(posedge axi.aclk) disable iff (!axi.aresetn)
      axi.wvalid && !axi.wready
      |=> axi.wvalid &&
          $stable({axi.wdata, axi.wstrb, axi.wlast});
  endproperty

  a_w_stable: assert property (p_w_stable);

  // keep AR stable while the slave is not ready
  property p_ar_stable;
    @(posedge axi.aclk) disable iff (!axi.aresetn)
      axi.arvalid && !axi.arready
      |=> axi.arvalid &&
          $stable({axi.arid, axi.araddr, axi.arlen, axi.arsize, axi.arburst});
  endproperty

  a_ar_stable: assert property (p_ar_stable);

  // keep R stable until the master accepts it
  property p_r_stable;
    @(posedge axi.aclk) disable iff (!axi.aresetn)
      axi.rvalid && !axi.rready
      |=> axi.rvalid &&
          $stable({axi.rid, axi.rdata, axi.rresp, axi.rlast});
  endproperty

  a_r_stable: assert property (p_r_stable);

  // keep B stable until the master accepts it
  property p_b_stable;
    @(posedge axi.aclk) disable iff (!axi.aresetn)
      axi.bvalid && !axi.bready
      |=> axi.bvalid &&
          $stable({axi.bid, axi.bresp});
  endproperty

  a_b_stable: assert property (p_b_stable);

endmodule
