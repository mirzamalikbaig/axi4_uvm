/******************************************************************************
*** AXI4 UVM Verification                                                 ***
*** Author: Mirza Agha Malik Baig                                         ***
*** Updated: October 2026                                                 ***
*** Filename: axi_mem_slave.sv                                            ***
*** Description: Implements the AXI4 byte-addressable memory slave DUT.   ***
******************************************************************************/

module axi_mem_slave #(

  parameter ADDR_WIDTH = 32,
  parameter DATA_WIDTH = 32,
  parameter ID_WIDTH   = 4,
  parameter MEM_BYTES  = 64*1024

)(
  axi_if axi
);

  // BYTE-ADDRESSABLE MEMORY

  logic [7:0] mem [0:MEM_BYTES-1];

  // WRITE SLOTS

  // Maximum 2 outstanding writes.

  logic [ID_WIDTH-1:0] wr_id    [0:1];

  logic [7:0]          wr_len   [0:1];

  logic [2:0]          wr_size  [0:1];

  logic [1:0]          wr_burst [0:1];

  logic [ADDR_WIDTH-1:0] wr_addr [0:1];

  logic [7:0]          wr_beat  [0:1];

  logic                wr_valid [0:1];

  logic                wr_data_done [0:1];

  logic [15:0]         wr_seq [0:1];

  logic [15:0]         wr_next_seq;

  // Which write currently owns W channel?

  logic wr_w_sel;

  logic wr_w_sel_valid;

  // Which slot owns current B response?

  logic b_sel;

  int unsigned wr_wait_count;

  localparam int WR_SINGLE_WAIT_CYCLES = 4;

  // READ SLOTS

  // Maximum 2 outstanding reads.

  logic [ID_WIDTH-1:0] rd_id    [0:1];

  logic [7:0]          rd_len   [0:1];

  logic [2:0]          rd_size  [0:1];

  logic [1:0]          rd_burst [0:1];

  logic [ADDR_WIDTH-1:0] rd_addr [0:1];

  logic [7:0]          rd_beat  [0:1];

  logic                rd_valid [0:1];

  logic [15:0]         rd_seq [0:1];

  logic [15:0]         rd_next_seq;

  // Slot currently driving R channel

  logic r_sel;

  int unsigned rd_wait_count;

  localparam int RD_SINGLE_WAIT_CYCLES = 2;

  // ADDRESS CALCULATION

  // Handles:

  // FIXED
  // INCR
  // WRAP

  function automatic logic [ADDR_WIDTH-1:0]
    calc_next_addr(

      input logic [ADDR_WIDTH-1:0] current_addr,
      input logic [7:0]            len,
      input logic [2:0]            size,
      input logic [1:0]            burst

    );

    longint unsigned bytes_per_beat;

    longint unsigned beats;

    longint unsigned total_bytes;

    longint unsigned wrap_base;

    longint unsigned wrap_limit;

    longint unsigned next_address;

    bytes_per_beat = (1 << size);

    case (burst)

      // FIXED

      2'b00: begin

        next_address =
          current_addr;

      end

      // INCR

      2'b01: begin

        next_address =
          current_addr +
          bytes_per_beat;

      end

      // WRAP

      2'b10: begin

        beats = len;

        beats = beats + 1;

        total_bytes =
          bytes_per_beat *
          beats;

        wrap_base =
          (current_addr / total_bytes) *
          total_bytes;

        wrap_limit =
          wrap_base +
          total_bytes;

        next_address =
          current_addr +
          bytes_per_beat;

        if (next_address >= wrap_limit)

          next_address =
            wrap_base;

      end

      // RESERVED

      default: begin

        next_address =
          current_addr;

      end

    endcase

    calc_next_addr =
      next_address[ADDR_WIDTH-1:0];

  endfunction

  // MEMORY READ HELPER

  function automatic logic [31:0]
    read_word(

      input logic [ADDR_WIDTH-1:0] address

    );

    read_word = {

      mem[address + 3],

      mem[address + 2],

      mem[address + 1],

      mem[address + 0]

    };

  endfunction

  // W CHANNEL OWNER

  // AXI4 has NO WID.

  // Therefore the oldest AW whose W burst is unfinished
  // owns the next W burst.

  always_comb begin

    wr_w_sel       = 1'b0;

    wr_w_sel_valid = 1'b0;

    // Two writes waiting for WDATA

    if (
      wr_valid[0] &&
      !wr_data_done[0] &&
      wr_valid[1] &&
      !wr_data_done[1]
    ) begin

      wr_w_sel_valid = 1'b1;

      if (wr_seq[0] <= wr_seq[1])

        wr_w_sel = 1'b0;

      else

        wr_w_sel = 1'b1;

    end

    // Only slot 0 needs WDATA

    else if (
      wr_valid[0] &&
      !wr_data_done[0]
    ) begin

      wr_w_sel_valid = 1'b1;

      wr_w_sel       = 1'b0;

    end

    // Only slot 1 needs WDATA

    else if (
      wr_valid[1] &&
      !wr_data_done[1]
    ) begin

      wr_w_sel_valid = 1'b1;

      wr_w_sel       = 1'b1;

    end

  end

  // READY SIGNALS

  always_comb begin

    // Free write slot exists

    axi.awready =
      axi.aresetn &&
      (
        !wr_valid[0] ||
        !wr_valid[1]
      );

    // At least one accepted AW needs WDATA

    axi.wready =
      axi.aresetn &&
      wr_w_sel_valid;

    // Free read slot exists

    axi.arready =
      axi.aresetn &&
      (
        !rd_valid[0] ||
        !rd_valid[1]
      );

  end

  // MAIN STATE MACHINE

  always_ff @(
    posedge axi.aclk or
    negedge axi.aresetn
  ) begin

    // RESET

    if (!axi.aresetn) begin

      wr_valid[0] <= 1'b0;
      wr_valid[1] <= 1'b0;

      wr_data_done[0] <= 1'b0;
      wr_data_done[1] <= 1'b0;

      wr_beat[0] <= '0;
      wr_beat[1] <= '0;

      wr_next_seq <= '0;

      wr_wait_count <= 0;

      axi.bvalid <= 1'b0;
      axi.bid    <= '0;
      axi.bresp  <= 2'b00;

      b_sel <= 1'b0;

      rd_valid[0] <= 1'b0;
      rd_valid[1] <= 1'b0;

      rd_beat[0] <= '0;
      rd_beat[1] <= '0;

      rd_next_seq <= '0;

      rd_wait_count <= 0;

      axi.rvalid <= 1'b0;

      axi.rid    <= '0;

      axi.rdata  <= '0;

      axi.rresp  <= 2'b00;

      axi.rlast  <= 1'b0;

      r_sel <= 1'b0;

    end

    else begin

      // AW HANDSHAKE

      if (
        axi.awvalid &&
        axi.awready
      ) begin

        // use slot 0

        if (!wr_valid[0]) begin

          wr_valid[0] <= 1'b1;

          wr_data_done[0] <= 1'b0;

          wr_id[0] <=
            axi.awid;

          wr_addr[0] <=
            axi.awaddr;

          wr_len[0] <=
            axi.awlen;

          wr_size[0] <=
            axi.awsize;

          wr_burst[0] <=
            axi.awburst;

          wr_beat[0] <=
            0;

          wr_seq[0] <=
            wr_next_seq;

        end

        // use slot 1

        else begin

          wr_valid[1] <= 1'b1;

          wr_data_done[1] <= 1'b0;

          wr_id[1] <=
            axi.awid;

          wr_addr[1] <=
            axi.awaddr;

          wr_len[1] <=
            axi.awlen;

          wr_size[1] <=
            axi.awsize;

          wr_burst[1] <=
            axi.awburst;

          wr_beat[1] <=
            0;

          wr_seq[1] <=
            wr_next_seq;

        end

        wr_next_seq <=
          wr_next_seq + 1;

      end

      // W HANDSHAKE

      if (
        axi.wvalid &&
        axi.wready
      ) begin

        // Byte lane 0

        if (axi.wstrb[0])

          mem[
            wr_addr[wr_w_sel] + 0
          ] <=
            axi.wdata[7:0];

        // Byte lane 1

        if (axi.wstrb[1])

          mem[
            wr_addr[wr_w_sel] + 1
          ] <=
            axi.wdata[15:8];

        // Byte lane 2

        if (axi.wstrb[2])

          mem[
            wr_addr[wr_w_sel] + 2
          ] <=
            axi.wdata[23:16];

        // Byte lane 3

        if (axi.wstrb[3])

          mem[
            wr_addr[wr_w_sel] + 3
          ] <=
            axi.wdata[31:24];

        // last W beat

        if (
          wr_beat[wr_w_sel] ==
          wr_len[wr_w_sel]
        ) begin

          wr_data_done[wr_w_sel] <=
            1'b1;

        end

        // more beats left

        else begin

          wr_beat[wr_w_sel] <=
            wr_beat[wr_w_sel] + 1;

          wr_addr[wr_w_sel] <=
            calc_next_addr(

              wr_addr[wr_w_sel],

              wr_len[wr_w_sel],

              wr_size[wr_w_sel],

              wr_burst[wr_w_sel]

            );

        end

      end

      // B RESPONSE

      // keep this response until BREADY

      if (axi.bvalid) begin

        if (axi.bready) begin

          axi.bvalid <=
            1'b0;

          // this write is done

          wr_valid[b_sel] <=
            1'b0;

          wr_data_done[b_sel] <=
            1'b0;

          wr_wait_count <=
            0;

        end

      end

      // no B response active
      // Select one.

      else begin

        // BOTH WRITE TRANSACTIONS READY FOR B

        if (
          wr_valid[0] &&
          wr_data_done[0] &&
          wr_valid[1] &&
          wr_data_done[1]
        ) begin

          // SAME ID

          // same ID has to stay in order

          if (
            wr_id[0] ==
            wr_id[1]
          ) begin

            if (
              wr_seq[0] <=
              wr_seq[1]
            ) begin

              b_sel <=
                1'b0;

              axi.bid <=
                wr_id[0];

            end

            else begin

              b_sel <=
                1'b1;

              axi.bid <=
                wr_id[1];

            end

          end

          // DIFFERENT IDs

          // newer one first here so I can see out-of-order completion

          else begin

            if (
              wr_seq[0] >
              wr_seq[1]
            ) begin

              b_sel <=
                1'b0;

              axi.bid <=
                wr_id[0];

            end

            else begin

              b_sel <=
                1'b1;

              axi.bid <=
                wr_id[1];

            end

          end

          axi.bresp <=
            2'b00;

          axi.bvalid <=
            1'b1;

          wr_wait_count <=
            0;

        end

        // ONLY SLOT 0 READY

        else if (
          wr_valid[0] &&
          wr_data_done[0]
        ) begin

          if (
            wr_wait_count >=
            WR_SINGLE_WAIT_CYCLES
          ) begin

            b_sel <=
              1'b0;

            axi.bid <=
              wr_id[0];

            axi.bresp <=
              2'b00;

            axi.bvalid <=
              1'b1;

            wr_wait_count <=
              0;

          end

          else begin

            wr_wait_count <=
              wr_wait_count + 1;

          end

        end

        // ONLY SLOT 1 READY

        else if (
          wr_valid[1] &&
          wr_data_done[1]
        ) begin

          if (
            wr_wait_count >=
            WR_SINGLE_WAIT_CYCLES
          ) begin

            b_sel <=
              1'b1;

            axi.bid <=
              wr_id[1];

            axi.bresp <=
              2'b00;

            axi.bvalid <=
              1'b1;

            wr_wait_count <=
              0;

          end

          else begin

            wr_wait_count <=
              wr_wait_count + 1;

          end

        end

        else begin

          wr_wait_count <=
            0;

        end

      end

      // AR HANDSHAKE

      if (
        axi.arvalid &&
        axi.arready
      ) begin

        // use slot 0

        if (!rd_valid[0]) begin

          rd_valid[0] <=
            1'b1;

          rd_id[0] <=
            axi.arid;

          rd_addr[0] <=
            axi.araddr;

          rd_len[0] <=
            axi.arlen;

          rd_size[0] <=
            axi.arsize;

          rd_burst[0] <=
            axi.arburst;

          rd_beat[0] <=
            0;

          rd_seq[0] <=
            rd_next_seq;

        end

        // use slot 1

        else begin

          rd_valid[1] <=
            1'b1;

          rd_id[1] <=
            axi.arid;

          rd_addr[1] <=
            axi.araddr;

          rd_len[1] <=
            axi.arlen;

          rd_size[1] <=
            axi.arsize;

          rd_burst[1] <=
            axi.arburst;

          rd_beat[1] <=
            0;

          rd_seq[1] <=
            rd_next_seq;

        end

        rd_next_seq <=
          rd_next_seq + 1;

      end

      // R CHANNEL

      // finish the current R beat first

      if (axi.rvalid) begin

        if (axi.rready) begin

          axi.rvalid <=
            1'b0;

          // last read beat

          if (axi.rlast) begin

            rd_valid[r_sel] <=
              1'b0;

          end

          // more beats left

          else begin

            rd_beat[r_sel] <=
              rd_beat[r_sel] + 1;

            rd_addr[r_sel] <=
              calc_next_addr(

                rd_addr[r_sel],

                rd_len[r_sel],

                rd_size[r_sel],

                rd_burst[r_sel]

              );

          end

        end

      end

      // no R beat active
      // Select transaction.

      else begin

        // TWO READS PENDING

        if (
          rd_valid[0] &&
          rd_valid[1]
        ) begin

          // SAME ID

          // older request goes first for the same ID

          if (
            rd_id[0] ==
            rd_id[1]
          ) begin

            if (
              rd_seq[0] <=
              rd_seq[1]
            ) begin

              r_sel <=
                1'b0;

              axi.rid <=
                rd_id[0];

              axi.rdata <=
                read_word(
                  rd_addr[0]
                );

              axi.rlast <=
                (
                  rd_beat[0] ==
                  rd_len[0]
                );

            end

            else begin

              r_sel <=
                1'b1;

              axi.rid <=
                rd_id[1];

              axi.rdata <=
                read_word(
                  rd_addr[1]
                );

              axi.rlast <=
                (
                  rd_beat[1] ==
                  rd_len[1]
                );

            end

          end

          // DIFFERENT IDs

          // newer one first here so I can see out-of-order completion

          else begin

            if (
              rd_seq[0] >
              rd_seq[1]
            ) begin

              r_sel <=
                1'b0;

              axi.rid <=
                rd_id[0];

              axi.rdata <=
                read_word(
                  rd_addr[0]
                );

              axi.rlast <=
                (
                  rd_beat[0] ==
                  rd_len[0]
                );

            end

            else begin

              r_sel <=
                1'b1;

              axi.rid <=
                rd_id[1];

              axi.rdata <=
                read_word(
                  rd_addr[1]
                );

              axi.rlast <=
                (
                  rd_beat[1] ==
                  rd_len[1]
                );

            end

          end

          axi.rresp <=
            2'b00;

          axi.rvalid <=
            1'b1;

          rd_wait_count <=
            0;

        end

        // ONLY SLOT 0

        else if (rd_valid[0]) begin

          if (
            rd_wait_count >=
            RD_SINGLE_WAIT_CYCLES
          ) begin

            r_sel <=
              1'b0;

            axi.rid <=
              rd_id[0];

            axi.rdata <=
              read_word(
                rd_addr[0]
              );

            axi.rresp <=
              2'b00;

            axi.rlast <=
              (
                rd_beat[0] ==
                rd_len[0]
              );

            axi.rvalid <=
              1'b1;

            rd_wait_count <=
              0;

          end

          else begin

            rd_wait_count <=
              rd_wait_count + 1;

          end

        end

        // ONLY SLOT 1

        else if (rd_valid[1]) begin

          if (
            rd_wait_count >=
            RD_SINGLE_WAIT_CYCLES
          ) begin

            r_sel <=
              1'b1;

            axi.rid <=
              rd_id[1];

            axi.rdata <=
              read_word(
                rd_addr[1]
              );

            axi.rresp <=
              2'b00;

            axi.rlast <=
              (
                rd_beat[1] ==
                rd_len[1]
              );

            axi.rvalid <=
              1'b1;

            rd_wait_count <=
              0;

          end

          else begin

            rd_wait_count <=
              rd_wait_count + 1;

          end

        end

        else begin

          rd_wait_count <=
            0;

        end

      end

    end

  end

endmodule
