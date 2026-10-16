/******************************************************************************
 * Project     : AXI4 UVM Verification
 * File        : axi_driver.sv
 * Author      : Mirza Agha Malik Baig
 * Description : Drives AXI transactions and captures read data and write
 *               responses.
 *****************************************************************************/

class axi_driver extends uvm_driver #(axi_txn);

  `uvm_component_utils(axi_driver)

  virtual axi_if vif;

  axi_txn txn;


  // =========================================================
  // OUTSTANDING CONTROL
  // =========================================================

  int outstanding_reads  = 0;
  int outstanding_writes = 0;

  localparam int MAX_OUTSTANDING_READS  = 2;
  localparam int MAX_OUTSTANDING_WRITES = 2;


  function new(
    string name = "axi_driver",
    uvm_component parent = null
  );

    super.new(name, parent);

  endfunction


  // =========================================================
  // BUILD
  // =========================================================

  function void build_phase(uvm_phase phase);

    super.build_phase(phase);

    if (!uvm_config_db#(virtual axi_if)::get(
          this,
          "",
          "vif",
          vif
        ))

      `uvm_fatal(
        "DRV",
        "virtual interface not found"
      )

  endfunction


  // =========================================================
  // RUN
  // =========================================================

  task run_phase(uvm_phase phase);

    init_signals();

    wait(vif.aresetn == 1'b1);


    fork


      // -----------------------------------------------------
      // REQUEST THREAD
      // -----------------------------------------------------

      begin

        forever begin

          seq_item_port.get_next_item(txn);

          drive(txn);

          seq_item_port.item_done();

        end

      end


      // -----------------------------------------------------
      // READ RESPONSE THREAD
      // -----------------------------------------------------

      begin

        collect_read_responses();

      end


      // -----------------------------------------------------
      // WRITE RESPONSE THREAD
      // -----------------------------------------------------

      begin

        collect_write_responses();

      end


    join

  endtask


  // =========================================================
  // INITIAL SIGNAL VALUES
  // =========================================================

  task init_signals();

    vif.awvalid <= 1'b0;

    vif.wvalid  <= 1'b0;
    vif.wlast   <= 1'b0;

    vif.bready  <= 1'b0;


    vif.arvalid <= 1'b0;

    vif.rready  <= 1'b0;


    outstanding_reads  = 0;
    outstanding_writes = 0;

  endtask


  // =========================================================
  // DISPATCH TRANSACTION
  // =========================================================

  task drive(axi_txn txn);


    if (txn.op == axi_txn::AXI_WRITE) begin


      // Do not exceed supported write depth
      wait(
        outstanding_writes <
        MAX_OUTSTANDING_WRITES
      );


      drive_write(txn);

    end


    else begin


      // Do not exceed supported read depth
      wait(
        outstanding_reads <
        MAX_OUTSTANDING_READS
      );


      drive_read_addr(txn);


      // AR has now been accepted.
      outstanding_reads++;


      `uvm_info(
        "DRV",
        $sformatf(
          "AR accepted: ID=%0d ADDR=%0d OUTSTANDING_READS=%0d",
          txn.id,
          txn.addr,
          outstanding_reads
        ),
        UVM_LOW
      )

    end

  endtask


  // =========================================================
  // WRITE REQUEST
  //
  // IMPORTANT:
  //
  // We do:
  //
  // AW
  // ↓
  // mark transaction outstanding
  // ↓
  // W beats
  // ↓
  // return
  //
  // We DO NOT wait for B here.
  //
  // B is collected by a separate thread.
  // =========================================================

  task drive_write(axi_txn txn);


    // -------------------------------------------------------
    // AW CHANNEL
    // -------------------------------------------------------

    @(posedge vif.aclk);

    vif.awid    <= txn.id;
    vif.awaddr  <= txn.addr;
    vif.awlen   <= txn.len;
    vif.awsize  <= txn.size;
    vif.awburst <= txn.burst;

    vif.awvalid <= 1'b1;


    do begin

      @(posedge vif.aclk);

    end
    while (!vif.awready);


    vif.awvalid <= 1'b0;


    // AW accepted:
    // write is now outstanding.
    outstanding_writes++;


    `uvm_info(
      "DRV",
      $sformatf(
        "AW accepted: ID=%0d ADDR=%0d OUTSTANDING_WRITES=%0d",
        txn.id,
        txn.addr,
        outstanding_writes
      ),
      UVM_LOW
    )


    // -------------------------------------------------------
    // W CHANNEL
    //
    // No WID exists.
    //
    // Therefore W bursts follow AW order.
    // -------------------------------------------------------

    for (int beat = 0;
         beat <= txn.len;
         beat++) begin


      vif.wdata <= txn.write_data[beat];

      vif.wstrb <= txn.wstrb[beat];


      if (beat == txn.len)

        vif.wlast <= 1'b1;

      else

        vif.wlast <= 1'b0;


      vif.wvalid <= 1'b1;


      do begin

        @(posedge vif.aclk);

      end
      while (!vif.wready);

    end


    vif.wvalid <= 1'b0;

    vif.wlast  <= 1'b0;


    // IMPORTANT:
    //
    // Return here.
    //
    // Do NOT wait for B.
    //
    // This allows next AW/W transaction to start while
    // previous B response is still pending.

  endtask


  // =========================================================
  // READ ADDRESS
  // =========================================================

  task drive_read_addr(axi_txn txn);

    @(posedge vif.aclk);


    vif.arid    <= txn.id;

    vif.araddr  <= txn.addr;

    vif.arlen   <= txn.len;

    vif.arsize  <= txn.size;

    vif.arburst <= txn.burst;

    vif.arvalid <= 1'b1;


    do begin

      @(posedge vif.aclk);

    end
    while (!vif.arready);


    vif.arvalid <= 1'b0;

  endtask


  // =========================================================
  // READ RESPONSE COLLECTOR
  // =========================================================

  task collect_read_responses();

    vif.rready <= 1'b1;


    forever begin

      @(posedge vif.aclk);


      if (
        vif.rvalid &&
        vif.rready &&
        vif.rlast
      ) begin


        if (outstanding_reads > 0) begin

          outstanding_reads--;


          `uvm_info(
            "DRV",
            $sformatf(
              "R complete: RID=%0d OUTSTANDING_READS=%0d",
              vif.rid,
              outstanding_reads
            ),
            UVM_LOW
          )

        end


        else begin

          `uvm_error(
            "DRV",
            "R completed but no read was outstanding"
          )

        end

      end

    end

  endtask


  // =========================================================
  // WRITE RESPONSE COLLECTOR
  // =========================================================

  task collect_write_responses();

    vif.bready <= 1'b1;


    forever begin

      @(posedge vif.aclk);


      if (
        vif.bvalid &&
        vif.bready
      ) begin


        if (outstanding_writes > 0) begin

          outstanding_writes--;


          `uvm_info(
            "DRV",
            $sformatf(
              "B complete: BID=%0d OUTSTANDING_WRITES=%0d",
              vif.bid,
              outstanding_writes
            ),
            UVM_LOW
          )

        end


        else begin

          `uvm_error(
            "DRV",
            "B completed but no write was outstanding"
          )

        end

      end

    end

  endtask


  // =========================================================
  // SYNCHRONIZATION
  // =========================================================

  task wait_for_reads_done();

    wait(outstanding_reads == 0);

    @(posedge vif.aclk);

  endtask


  task wait_for_writes_done();

    wait(outstanding_writes == 0);

    @(posedge vif.aclk);

  endtask


  task wait_for_all_done();

    wait(
      outstanding_reads  == 0 &&
      outstanding_writes == 0
    );

    @(posedge vif.aclk);

  endtask


endclass
