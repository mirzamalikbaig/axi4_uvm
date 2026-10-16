class axi_sequence extends uvm_sequence #(axi_txn);

  `uvm_object_utils(axi_sequence)

  // TEST SCENARIOS

  typedef enum {

    MEM_SETUP,

    DIFF_ID_READ,

    SAME_ID_READ,

    DIFF_ID_WRITE,

    SAME_ID_WRITE,

    WRITE_READBACK,

    WRAP_WRITE,

    WRAP_READ,

    FIXED_WRITE,

    FIXED_READ,

    INCR_MULTI_WRITE,

    INCR_MULTI_READ

  } scenario_e;

  scenario_e scenario;

  // CONSTRUCTOR

  function new(
    string name = "axi_sequence"
  );

    super.new(name);

  endfunction

  // HELPER:
  // SINGLE-BEAT WRITE

  // req_id / req_addr / req_data are intentionally named
  // differently from transaction fields.

  task send_single_write(

    string req_name,

    bit [3:0] req_id,

    bit [31:0] req_addr,

    bit [31:0] req_data

  );

    axi_txn txn;

    txn =
      axi_txn::type_id::create(
        req_name
      );

    start_item(txn);

    assert(
      txn.randomize() with {

        op ==
          axi_txn::AXI_WRITE;

        id ==
          req_id;

        addr ==
          req_addr;

        len ==
          0;

        size ==
          2;

        burst ==
          axi_txn::INCR;

        write_data[0] ==
          req_data;

        wstrb[0] ==
          4'b1111;

      }
    );

    finish_item(txn);

  endtask

  // HELPER:
  // SINGLE-BEAT READ

  task send_single_read(

    string req_name,

    bit [3:0] req_id,

    bit [31:0] req_addr

  );

    axi_txn txn;

    txn =
      axi_txn::type_id::create(
        req_name
      );

    start_item(txn);

    assert(
      txn.randomize() with {

        op ==
          axi_txn::AXI_READ;

        id ==
          req_id;

        addr ==
          req_addr;

        len ==
          0;

        size ==
          2;

        burst ==
          axi_txn::INCR;

      }
    );

    finish_item(txn);

  endtask

  // BODY

  task body();

    axi_txn txn;

    case (scenario)

      // 1. MEMORY SETUP

      // addr100 = 50
      // addr200 = 75

      MEM_SETUP: begin

        send_single_write(
          "setup_wr_1",
          4'd0,
          32'd100,
          32'd50
        );

        send_single_write(
          "setup_wr_2",
          4'd1,
          32'd200,
          32'd75
        );

      end

      // 2. DIFFERENT-ID READ

      // AR request order:

      // ID6 addr100
      // ID3 addr200

      // DUT intentionally allows:

      // RID3 first
      // RID6 second

      DIFF_ID_READ: begin

        send_single_read(
          "diff_rd_1",
          4'd6,
          32'd100
        );

        send_single_read(
          "diff_rd_2",
          4'd3,
          32'd200
        );

      end

      // 3. SAME-ID READ

      // Both ID5.

      // Must preserve request order.

      SAME_ID_READ: begin

        send_single_read(
          "same_rd_1",
          4'd5,
          32'd100
        );

        send_single_read(
          "same_rd_2",
          4'd5,
          32'd200
        );

      end

      // 4. DIFFERENT-ID WRITE

      // AW:

      // ID6 addr300 = 30
      // ID3 addr400 = 40

      // WDATA still follows AW order because AXI4 has no WID.

      // B responses may complete:

      // BID3
      // BID6

      DIFF_ID_WRITE: begin

        send_single_write(
          "diff_wr_1",
          4'd6,
          32'd300,
          32'd30
        );

        send_single_write(
          "diff_wr_2",
          4'd3,
          32'd400,
          32'd40
        );

      end

      // 5. SAME-ID WRITE

      // Both ID5.

      // B responses must preserve order.

      SAME_ID_WRITE: begin

        send_single_write(
          "same_wr_1",
          4'd5,
          32'd500,
          32'd55
        );

        send_single_write(
          "same_wr_2",
          4'd5,
          32'd600,
          32'd65
        );

      end

      // 6. WRITE READBACK

      // Verify:

      // addr300 = 30
      // addr400 = 40
      // addr500 = 55
      // addr600 = 65

      WRITE_READBACK: begin

        send_single_read(
          "rd_300",
          4'd8,
          32'd300
        );

        send_single_read(
          "rd_400",
          4'd9,
          32'd400
        );

        send_single_read(
          "rd_500",
          4'd10,
          32'd500
        );

        send_single_read(
          "rd_600",
          4'd11,
          32'd600
        );

      end

      // 7. WRAP WRITE

      // ADDR  = 12
      // SIZE  = 2

      // bytes per beat = 4

      // LEN = 3

      // beats = LEN + 1 = 4

      // total wrap window =

      // 4 bytes * 4 beats = 16 bytes

      // Address sequence:

      // 12 -> 0 -> 4 -> 8

      // Data:

      // addr12 = 10
      // addr0  = 20
      // addr4  = 30
      // addr8  = 40

      WRAP_WRITE: begin

        txn =
          axi_txn::type_id::create(
            "wrap_write"
          );

        start_item(txn);

        assert(
          txn.randomize() with {

            op ==
              axi_txn::AXI_WRITE;

            id ==
              4'd2;

            addr ==
              32'd12;

            len ==
              3;

            size ==
              2;

            burst ==
              axi_txn::WRAP;

            write_data[0] ==
              32'd10;

            write_data[1] ==
              32'd20;

            write_data[2] ==
              32'd30;

            write_data[3] ==
              32'd40;

            wstrb[0] ==
              4'b1111;

            wstrb[1] ==
              4'b1111;

            wstrb[2] ==
              4'b1111;

            wstrb[3] ==
              4'b1111;

          }
        );

        finish_item(txn);

      end

      // 8. WRAP READ

      // Same WRAP:

      // beat0 -> addr12 -> 10
      // beat1 -> addr0  -> 20
      // beat2 -> addr4  -> 30
      // beat3 -> addr8  -> 40

      WRAP_READ: begin

        txn =
          axi_txn::type_id::create(
            "wrap_read"
          );

        start_item(txn);

        assert(
          txn.randomize() with {

            op ==
              axi_txn::AXI_READ;

            id ==
              4'd4;

            addr ==
              32'd12;

            len ==
              3;

            size ==
              2;

            burst ==
              axi_txn::WRAP;

          }
        );

        finish_item(txn);

      end

      // 9. FIXED WRITE

      // Four beats target the SAME address.
      // Final memory value at addr800 becomes 44.

      FIXED_WRITE: begin

        txn = axi_txn::type_id::create("fixed_write");

        start_item(txn);

        assert(
          txn.randomize() with {
            op    == axi_txn::AXI_WRITE;
            id    == 4'd12;
            addr  == 32'd800;
            len   == 3;
            size  == 2;
            burst == axi_txn::FIXED;

            write_data[0] == 32'd11;
            write_data[1] == 32'd22;
            write_data[2] == 32'd33;
            write_data[3] == 32'd44;

            wstrb[0] == 4'b1111;
            wstrb[1] == 4'b1111;
            wstrb[2] == 4'b1111;
            wstrb[3] == 4'b1111;
          }
        );

        finish_item(txn);

        // also check a one-beat FIXED transfer
        txn = axi_txn::type_id::create("fixed_single_write");
        start_item(txn);

        assert(
          txn.randomize() with {
            op            == axi_txn::AXI_WRITE;
            id            == 4'd7;
            addr          == 32'd820;
            len           == 0;
            size          == 2;
            burst         == axi_txn::FIXED;
            write_data[0] == 32'd77;
            wstrb[0]      == 4'b1111;
          }
        );

        finish_item(txn);

      end

      // 10. FIXED READ

      // All four beats read addr800.
      // Expected data on every beat = 44.

      FIXED_READ: begin

        txn = axi_txn::type_id::create("fixed_read");

        start_item(txn);

        assert(
          txn.randomize() with {
            op    == axi_txn::AXI_READ;
            id    == 4'd13;
            addr  == 32'd800;
            len   == 3;
            size  == 2;
            burst == axi_txn::FIXED;
          }
        );

        finish_item(txn);

        // read back the one-beat FIXED write
        txn = axi_txn::type_id::create("fixed_single_read");
        start_item(txn);

        assert(
          txn.randomize() with {
            op    == axi_txn::AXI_READ;
            id    == 4'd7;
            addr  == 32'd820;
            len   == 0;
            size  == 2;
            burst == axi_txn::FIXED;
          }
        );

        finish_item(txn);

      end

      // 11. MULTI-BEAT INCR WRITE

      // Address sequence:
      // 900 -> 904 -> 908 -> 912

      INCR_MULTI_WRITE: begin

        txn = axi_txn::type_id::create("incr_multi_write");

        start_item(txn);

        assert(
          txn.randomize() with {
            op    == axi_txn::AXI_WRITE;
            id    == 4'd14;
            addr  == 32'd900;
            len   == 3;
            size  == 2;
            burst == axi_txn::INCR;

            write_data[0] == 32'd101;
            write_data[1] == 32'd102;
            write_data[2] == 32'd103;
            write_data[3] == 32'd104;

            wstrb[0] == 4'b1111;
            wstrb[1] == 4'b1111;
            wstrb[2] == 4'b1111;
            wstrb[3] == 4'b1111;
          }
        );

        finish_item(txn);

      end

      // 12. MULTI-BEAT INCR READ

      // Expected:
      // 900=101, 904=102, 908=103, 912=104

      INCR_MULTI_READ: begin

        txn = axi_txn::type_id::create("incr_multi_read");

        start_item(txn);

        assert(
          txn.randomize() with {
            op    == axi_txn::AXI_READ;
            id    == 4'd15;
            addr  == 32'd900;
            len   == 3;
            size  == 2;
            burst == axi_txn::INCR;
          }
        );

        finish_item(txn);

      end

      // UNKNOWN SCENARIO

      default: begin

        `uvm_error(
          "SEQ",
          "Unknown sequence scenario"
        )

      end

    endcase

  endtask

endclass
