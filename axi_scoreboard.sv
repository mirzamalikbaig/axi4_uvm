/******************************************************************************
 * Project     : AXI4 UVM Verification
 * File        : axi_scoreboard.sv
 * Author      : Mirza Agha Malik Baig
 * Description : Maintains reference memory and checks observed AXI read
 *               data.
 *****************************************************************************/

class axi_scoreboard extends uvm_scoreboard;

  `uvm_component_utils(axi_scoreboard)


  uvm_analysis_imp #(
    axi_txn,
    axi_scoreboard
  ) imp;


  // =========================================================
  // REFERENCE MEMORY
  // =========================================================

  logic [7:0] ref_mem [0:64*1024-1];


  // =========================================================
  // OUT-OF-ORDER WRITE COMPLETION
  // =========================================================

  axi_txn completed_writes[int unsigned];

  int unsigned next_wr_commit = 0;


  // =========================================================
  // CONSTRUCTOR
  // =========================================================

  function new(
    string name = "axi_scoreboard",
    uvm_component parent = null
  );

    super.new(name, parent);

    imp = new("imp", this);

  endfunction


  // =========================================================
  // ADDRESS CALCULATION
  //
  // Independent reference-model calculation.
  // =========================================================

  function automatic logic [31:0]
    calc_next_addr(

      input logic [31:0] current_addr,
      input logic [7:0]  len,
      input logic [2:0]  size,
      input axi_txn::axi_burst_e burst

    );


    longint unsigned bytes_per_beat;

    longint unsigned beats;

    longint unsigned total_bytes;

    longint unsigned wrap_base;

    longint unsigned wrap_limit;

    longint unsigned next_address;


    bytes_per_beat =
      (1 << size);


    case (burst)


      // -----------------------------------------------------
      // FIXED
      // -----------------------------------------------------

      axi_txn::FIXED: begin

        next_address =
          current_addr;

      end


      // -----------------------------------------------------
      // INCR
      // -----------------------------------------------------

      axi_txn::INCR: begin

        next_address =
          current_addr +
          bytes_per_beat;

      end


      // -----------------------------------------------------
      // WRAP
      // -----------------------------------------------------

      axi_txn::WRAP: begin


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


        if (
          next_address >=
          wrap_limit
        )

          next_address =
            wrap_base;


      end


      default: begin


        next_address =
          current_addr;


      end


    endcase


    calc_next_addr =
      next_address[31:0];


  endfunction


  // =========================================================
  // APPLY WRITE TO REFERENCE MEMORY
  // =========================================================

  function void apply_write(
    axi_txn txn
  );


    logic [31:0] current_addr;


    current_addr =
      txn.addr;


    for (
      int beat = 0;
      beat <= txn.len;
      beat++
    ) begin


      if (
        txn.wstrb[beat][0]
      )

        ref_mem[
          current_addr + 0
        ] =
          txn.write_data[
            beat
          ][7:0];


      if (
        txn.wstrb[beat][1]
      )

        ref_mem[
          current_addr + 1
        ] =
          txn.write_data[
            beat
          ][15:8];


      if (
        txn.wstrb[beat][2]
      )

        ref_mem[
          current_addr + 2
        ] =
          txn.write_data[
            beat
          ][23:16];


      if (
        txn.wstrb[beat][3]
      )

        ref_mem[
          current_addr + 3
        ] =
          txn.write_data[
            beat
          ][31:24];


      current_addr =
        calc_next_addr(

          current_addr,

          txn.len,

          txn.size,

          txn.burst

        );


    end


  endfunction


  // =========================================================
  // WRITE()
  // =========================================================

  function void write(
    axi_txn txn
  );


    logic [31:0] current_addr;

    logic [31:0] expected_data;

    axi_txn wr_txn;


    // =======================================================
    // WRITE TRANSACTION
    // =======================================================

    if (
      txn.op ==
      axi_txn::AXI_WRITE
    ) begin


      // -----------------------------------------------------
      // BRESP
      // -----------------------------------------------------

      if (
        txn.bresp !=
        axi_txn::OKAY
      ) begin


        `uvm_error(
          "SCB",
          $sformatf(
            "WRITE response error: ID=%0d ADDR=%0d BRESP=%0b",
            txn.id,
            txn.addr,
            txn.bresp
          )
        )


      end


      // -----------------------------------------------------
      // Store transaction using original AW order.
      //
      // B responses may arrive out-of-order.
      // -----------------------------------------------------

      completed_writes[
        txn.wr_seq
      ] = txn;


      // -----------------------------------------------------
      // Commit writes in original AW/W order.
      // -----------------------------------------------------

      while (
        completed_writes.exists(
          next_wr_commit
        )
      ) begin


        wr_txn =
          completed_writes[
            next_wr_commit
          ];


        apply_write(
          wr_txn
        );


        `uvm_info(
          "SCB",
          $sformatf(
            "WRITE COMMIT: SEQ=%0d ID=%0d ADDR=%0d BURST=%0d BRESP=%0b",
            wr_txn.wr_seq,
            wr_txn.id,
            wr_txn.addr,
            wr_txn.burst,
            wr_txn.bresp
          ),
          UVM_LOW
        )


        completed_writes.delete(
          next_wr_commit
        );


        next_wr_commit++;


      end


    end


    // =======================================================
    // READ TRANSACTION
    // =======================================================

    else if (
      txn.op ==
      axi_txn::AXI_READ
    ) begin


      current_addr =
        txn.addr;


      for (
        int beat = 0;
        beat <= txn.len;
        beat++
      ) begin


        // ---------------------------------------------------
        // Build expected 32-bit value
        // ---------------------------------------------------

        expected_data = {

          ref_mem[current_addr + 3],

          ref_mem[current_addr + 2],

          ref_mem[current_addr + 1],

          ref_mem[current_addr + 0]

        };


        // ---------------------------------------------------
        // RRESP CHECK
        // ---------------------------------------------------

        if (
          txn.rresp[beat] !=
          axi_txn::OKAY
        ) begin


          `uvm_error(
            "SCB",
            $sformatf(
              "Unexpected RRESP: ID=%0d ADDR=%0d BEAT=%0d RRESP=%0b",
              txn.id,
              current_addr,
              beat,
              txn.rresp[beat]
            )
          )


        end


        // ---------------------------------------------------
        // RDATA CHECK
        // ---------------------------------------------------

        if (
          expected_data ==
          txn.read_data[beat]
        ) begin


          `uvm_info(
            "SCB",
            $sformatf(
              "READ PASS: ID=%0d ADDR=%0d BEAT=%0d BURST=%0d EXPECTED=%0d ACTUAL=%0d",
              txn.id,
              current_addr,
              beat,
              txn.burst,
              expected_data,
              txn.read_data[beat]
            ),
            UVM_LOW
          )


        end


        else begin


          `uvm_error(
            "SCB",
            $sformatf(
              "READ FAIL: ID=%0d ADDR=%0d BEAT=%0d BURST=%0d EXPECTED=%0d ACTUAL=%0d",
              txn.id,
              current_addr,
              beat,
              txn.burst,
              expected_data,
              txn.read_data[beat]
            )
          )


        end


        // ---------------------------------------------------
        // Next expected address
        // ---------------------------------------------------

        current_addr =
          calc_next_addr(

            current_addr,

            txn.len,

            txn.size,

            txn.burst

          );


      end


    end


    else begin


      `uvm_error(
        "SCB",
        "Unknown AXI transaction operation"
      )


    end


  endfunction


endclass
