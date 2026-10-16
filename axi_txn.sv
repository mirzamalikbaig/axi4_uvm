class axi_txn extends uvm_sequence_item;

  // Transaction type
  typedef enum bit {
    AXI_READ,
    AXI_WRITE
  } axi_op_e;

  // AXI burst encoding
  typedef enum bit [1:0] {
    FIXED    = 2'b00,
    INCR     = 2'b01,
    WRAP     = 2'b10,
    RESERVED = 2'b11
  } axi_burst_e;

  // AXI response encoding
  typedef enum bit [1:0] {
    OKAY   = 2'b00,
    EXOKAY = 2'b01,
    SLVERR = 2'b10,
    DECERR = 2'b11
  } axi_resp_e;

  // Request fields
  rand axi_op_e    op;
  rand bit [3:0]   id;
  rand bit [31:0]  addr;
  rand bit [7:0]   len;
  rand bit [2:0]   size;
  rand axi_burst_e burst;

  // Write burst data
  rand bit [31:0] write_data[];
  rand bit [3:0]  wstrb[];

  // Response data captured from the DUT
  bit [31:0] read_data[];
  axi_resp_e bresp;
  axi_resp_e rresp[];

  // Original AW acceptance order. The scoreboard uses this to
  // commit writes in W-channel order when B responses reorder by ID.
  int unsigned wr_seq;

  `uvm_object_utils_begin(axi_txn)
    `uvm_field_enum(axi_op_e, op, UVM_ALL_ON)

    `uvm_field_int(id,   UVM_ALL_ON)
    `uvm_field_int(addr, UVM_ALL_ON)
    `uvm_field_int(len,  UVM_ALL_ON)
    `uvm_field_int(size, UVM_ALL_ON)

    `uvm_field_enum(axi_burst_e, burst, UVM_ALL_ON)

    `uvm_field_array_int(write_data, UVM_ALL_ON)
    `uvm_field_array_int(wstrb,      UVM_ALL_ON)
    `uvm_field_array_int(read_data,  UVM_ALL_ON)

    `uvm_field_enum(axi_resp_e, bresp, UVM_ALL_ON)
    `uvm_field_array_enum(axi_resp_e, rresp, UVM_ALL_ON)
    `uvm_field_int(wr_seq, UVM_ALL_ON)
  `uvm_object_utils_end

  // A write needs one data and strobe entry per beat.
  // Read transactions do not use these arrays.
  constraint data_size_c {
    if (op == AXI_WRITE) {
      write_data.size() == len + 1;
      wstrb.size()      == len + 1;
    }
    else {
      write_data.size() == 0;
      wstrb.size()      == 0;
    }
  }

  // Burst length limits from the AXI4 protocol
  constraint len_c {
    burst != RESERVED;

    if (burst == FIXED)
      len inside {[0:15]};

    if (burst == INCR)
      len inside {[0:255]};

    if (burst == WRAP)
      len inside {1, 3, 7, 15};
  }

  // 32-bit data bus supports 1, 2, or 4 bytes per beat
  constraint size_c {
    size inside {[0:2]};
  }

  // WRAP bursts must start on a transfer-size boundary
  constraint addr_c {
    if (burst == WRAP)
      addr % (1 << size) == 0;
  }

  function new(string name = "axi_txn");
    super.new(name);
  endfunction

endclass
