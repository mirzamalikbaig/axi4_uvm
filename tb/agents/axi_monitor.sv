/******************************************************************************
*** AXI4 UVM Verification                                                 ***
*** Author: Mirza Agha Malik Baig                                         ***
*** Updated: October 2026                                                 ***
*** Filename: axi_monitor.sv                                              ***
*** Description: Reconstructs observed AXI bus transactions.              ***
******************************************************************************/

class axi_monitor extends uvm_monitor;

  `uvm_component_utils(axi_monitor)

  virtual axi_if vif;

  uvm_analysis_port #(axi_txn) ap;

  // WRITE TRACKING

  // AW-order queue.

  // W has no WID, so WDATA always belongs to
  // the oldest transaction in this queue.

  axi_txn write_data_q[$];

  // Writes that finished receiving WDATA and are waiting
  // for B response.

  // Key = BID/AWID.

  // Queue per ID preserves same-ID ordering.

  axi_txn pending_b[int][$];

  int wr_beat_idx = 0;

  int unsigned next_wr_seq = 0;

  // READ TRACKING

  axi_txn pending_reads[int][$];

  int rd_beat_idx[int];

  function new(
    string name = "axi_monitor",
    uvm_component parent = null
  );

    super.new(name, parent);

    ap = new("ap", this);

  endfunction

  function void build_phase(uvm_phase phase);

    super.build_phase(phase);

    if (!uvm_config_db#(virtual axi_if)::get(
          this,
          "",
          "vif",
          vif
        ))

      `uvm_fatal(
        "MON",
        "virtual interface not found"
      )

  endfunction

  // RUN

  task run_phase(uvm_phase phase);

    axi_txn new_wr_txn;

    axi_txn current_wr_txn;

    axi_txn completed_wr_txn;

    axi_txn new_rd_txn;

    axi_txn current_rd_txn;

    int bid;

    int rid;

    wait(vif.aresetn == 1'b1);

    forever begin

      @(posedge vif.aclk);

      // AW HANDSHAKE

      if (
        vif.awvalid &&
        vif.awready
      ) begin

        new_wr_txn =
          axi_txn::type_id::create(
            "new_wr_txn"
          );

        new_wr_txn.op =
          axi_txn::AXI_WRITE;

        new_wr_txn.id =
          vif.awid;

        new_wr_txn.addr =
          vif.awaddr;

        new_wr_txn.len =
          vif.awlen;

        new_wr_txn.size =
          vif.awsize;

        new_wr_txn.burst =
          axi_txn::axi_burst_e'(
            vif.awburst
          );

        new_wr_txn.write_data =
          new[vif.awlen + 1];

        new_wr_txn.wstrb =
          new[vif.awlen + 1];

        // Remember original AW order.
        new_wr_txn.wr_seq =
          next_wr_seq;

        next_wr_seq++;

        // W has no WID.

        // Therefore AW-order queue determines
        // which write owns incoming WDATA.

        write_data_q.push_back(
          new_wr_txn
        );

      end

      // W HANDSHAKE

      if (
        vif.wvalid &&
        vif.wready
      ) begin

        if (write_data_q.size() == 0) begin

          `uvm_error(
            "MON",
            "W beat observed without pending AW transaction"
          )

        end

        else begin

          // Oldest AW owns the current W burst.
          current_wr_txn =
            write_data_q[0];

          current_wr_txn.write_data[
            wr_beat_idx
          ] = vif.wdata;

          current_wr_txn.wstrb[
            wr_beat_idx
          ] = vif.wstrb;

          // WLAST checking

          if (
            wr_beat_idx ==
            current_wr_txn.len
          ) begin

            if (!vif.wlast)

              `uvm_error(
                "MON",
                "Missing WLAST on final write beat"
              )

            // W burst finished.

            // Move transaction from W-order queue into
            // BID waiting queue.

            pending_b[
              current_wr_txn.id
            ].push_back(
              current_wr_txn
            );

            write_data_q.pop_front();

            wr_beat_idx = 0;

          end

          else begin

            if (vif.wlast)

              `uvm_error(
                "MON",
                "WLAST asserted before final write beat"
              )

            wr_beat_idx++;

          end

        end

      end

      // B HANDSHAKE

      if (
        vif.bvalid &&
        vif.bready
      ) begin

        bid = vif.bid;

        if (
          !pending_b.exists(bid) ||
          pending_b[bid].size() == 0
        ) begin

          `uvm_error(
            "MON",
            $sformatf(
              "BID=%0d has no matching completed write",
              bid
            )
          )

        end

        else begin

          // Same BID:
          // oldest transaction with this ID completes first.

          completed_wr_txn =
            pending_b[bid][0];

          completed_wr_txn.bresp =
            axi_txn::axi_resp_e'(
              vif.bresp
            );

          `uvm_info(
            "MON",
            $sformatf(
              "WRITE COMPLETE: BID=%0d WR_SEQ=%0d ADDR=%0d BRESP=%0b",
              bid,
              completed_wr_txn.wr_seq,
              completed_wr_txn.addr,
              vif.bresp
            ),
            UVM_LOW
          )

          // Send completed write to scoreboard.
          ap.write(
            completed_wr_txn
          );

          pending_b[bid].pop_front();

          if (
            pending_b[bid].size() == 0
          )

            pending_b.delete(bid);

        end

      end

      // AR HANDSHAKE

      if (
        vif.arvalid &&
        vif.arready
      ) begin

        new_rd_txn =
          axi_txn::type_id::create(
            "new_rd_txn"
          );

        new_rd_txn.op =
          axi_txn::AXI_READ;

        new_rd_txn.id =
          vif.arid;

        new_rd_txn.addr =
          vif.araddr;

        new_rd_txn.len =
          vif.arlen;

        new_rd_txn.size =
          vif.arsize;

        new_rd_txn.burst =
          axi_txn::axi_burst_e'(
            vif.arburst
          );

        new_rd_txn.read_data =
          new[vif.arlen + 1];

        new_rd_txn.rresp =
          new[vif.arlen + 1];

        // Only initialize beat count when this ID
        // does not already have an active transaction.

        if (
          !pending_reads.exists(
            vif.arid
          )
        )

          rd_beat_idx[
            vif.arid
          ] = 0;

        pending_reads[
          vif.arid
        ].push_back(
          new_rd_txn
        );

      end

      // R HANDSHAKE

      if (
        vif.rvalid &&
        vif.rready
      ) begin

        rid = vif.rid;

        if (
          !pending_reads.exists(rid) ||
          pending_reads[rid].size() == 0
        ) begin

          `uvm_error(
            "MON",
            $sformatf(
              "RID=%0d has no matching AR request",
              rid
            )
          )

        end

        else begin

          // Oldest request with this RID.
          current_rd_txn =
            pending_reads[rid][0];

          current_rd_txn.read_data[
            rd_beat_idx[rid]
          ] = vif.rdata;

          current_rd_txn.rresp[
            rd_beat_idx[rid]
          ] =
            axi_txn::axi_resp_e'(
              vif.rresp
            );

          // FINAL EXPECTED BEAT

          if (
            rd_beat_idx[rid] ==
            current_rd_txn.len
          ) begin

            if (!vif.rlast)

              `uvm_error(
                "MON",
                "Missing RLAST on final read beat"
              )

            ap.write(
              current_rd_txn
            );

            pending_reads[rid].pop_front();

            if (
              pending_reads[rid].size()
              == 0
            ) begin

              pending_reads.delete(rid);

              rd_beat_idx.delete(rid);

            end

            else begin

              rd_beat_idx[rid] = 0;

            end

          end

          else begin

            if (vif.rlast)

              `uvm_error(
                "MON",
                "RLAST asserted before final read beat"
              )

            rd_beat_idx[rid]++;

          end

        end

      end

    end

  endtask

endclass
