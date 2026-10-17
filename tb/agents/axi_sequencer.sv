/******************************************************************************
*** AXI4 UVM Verification                                                 ***
*** Author: Mirza Agha Malik Baig                                         ***
*** Updated: October 2026                                                 ***
*** Filename: axi_sequencer.sv                                            ***
*** Description: Passes AXI sequence items to the driver.                 ***
******************************************************************************/

class axi_sequencer extends uvm_sequencer #(axi_txn);

  `uvm_component_utils(axi_sequencer)

  function new(string name = "axi_sequencer",
               uvm_component parent = null);
    super.new(name, parent);
  endfunction

endclass
