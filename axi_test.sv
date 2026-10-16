/******************************************************************************
 * Project     : AXI4 UVM Verification
 * File        : axi_test.sv
 * Author      : Mirza Agha Malik Baig
 * Description : Builds the environment, starts stimulus, and manages the
 *               run-phase objection.
 *****************************************************************************/

class axi_test extends uvm_test;

  `uvm_component_utils(axi_test)


  axi_env env;


  // =========================================================
  // CONSTRUCTOR
  // =========================================================

  function new(
    string name = "axi_test",
    uvm_component parent = null
  );

    super.new(name, parent);

  endfunction


  // =========================================================
  // BUILD
  // =========================================================

  function void build_phase(
    uvm_phase phase
  );


    super.build_phase(phase);


    env =
      axi_env::type_id::create(
        "env",
        this
      );


  endfunction


  // =========================================================
  // TOPOLOGY
  // =========================================================

  function void end_of_elaboration_phase(
    uvm_phase phase
  );


    super.end_of_elaboration_phase(
      phase
    );


    uvm_top.print_topology();


  endfunction


  // =========================================================
  // RUN
  // =========================================================

  task run_phase(
    uvm_phase phase
  );


    axi_sequence seq;


    phase.raise_objection(this);


    // =======================================================
    // CREATE ONE SEQUENCE OBJECT
    // =======================================================

    seq =
      axi_sequence::type_id::create(
        "seq"
      );


    // =======================================================
    // 1. MEMORY SETUP
    // =======================================================

    `uvm_info(
      "TEST",
      "Starting memory setup",
      UVM_LOW
    )


    seq.scenario =
      axi_sequence::MEM_SETUP;


    seq.start(
      env.agent.sequencer
    );


    env.agent.driver.
      wait_for_writes_done();


    // =======================================================
    // 2. DIFFERENT-ID READ
    // =======================================================

    `uvm_info(
      "TEST",
      "Starting different-ID READ test",
      UVM_LOW
    )


    seq.scenario =
      axi_sequence::DIFF_ID_READ;


    seq.start(
      env.agent.sequencer
    );


    env.agent.driver.
      wait_for_reads_done();


    `uvm_info(
      "TEST",
      "Different-ID READ test completed",
      UVM_LOW
    )


    // =======================================================
    // 3. SAME-ID READ
    // =======================================================

    `uvm_info(
      "TEST",
      "Starting same-ID READ test",
      UVM_LOW
    )


    seq.scenario =
      axi_sequence::SAME_ID_READ;


    seq.start(
      env.agent.sequencer
    );


    env.agent.driver.
      wait_for_reads_done();


    `uvm_info(
      "TEST",
      "Same-ID READ test completed",
      UVM_LOW
    )


    // =======================================================
    // 4. DIFFERENT-ID WRITE
    // =======================================================

    `uvm_info(
      "TEST",
      "Starting different-ID WRITE test",
      UVM_LOW
    )


    seq.scenario =
      axi_sequence::DIFF_ID_WRITE;


    seq.start(
      env.agent.sequencer
    );


    env.agent.driver.
      wait_for_writes_done();


    `uvm_info(
      "TEST",
      "Different-ID WRITE test completed",
      UVM_LOW
    )


    // =======================================================
    // 5. SAME-ID WRITE
    // =======================================================

    `uvm_info(
      "TEST",
      "Starting same-ID WRITE test",
      UVM_LOW
    )


    seq.scenario =
      axi_sequence::SAME_ID_WRITE;


    seq.start(
      env.agent.sequencer
    );


    env.agent.driver.
      wait_for_writes_done();


    `uvm_info(
      "TEST",
      "Same-ID WRITE test completed",
      UVM_LOW
    )


    // =======================================================
    // 6. READ BACK OUTSTANDING WRITES
    // =======================================================

    `uvm_info(
      "TEST",
      "Starting WRITE readback test",
      UVM_LOW
    )


    seq.scenario =
      axi_sequence::WRITE_READBACK;


    seq.start(
      env.agent.sequencer
    );


    env.agent.driver.
      wait_for_reads_done();


    `uvm_info(
      "TEST",
      "WRITE readback test completed",
      UVM_LOW
    )


    // =======================================================
    // 7. WRAP WRITE
    //
    // Writes:
    //
    // addr12 = 10
    // addr0  = 20
    // addr4  = 30
    // addr8  = 40
    // =======================================================

    `uvm_info(
      "TEST",
      "Starting WRAP WRITE test",
      UVM_LOW
    )


    seq.scenario =
      axi_sequence::WRAP_WRITE;


    seq.start(
      env.agent.sequencer
    );


    env.agent.driver.
      wait_for_writes_done();


    `uvm_info(
      "TEST",
      "WRAP WRITE completed",
      UVM_LOW
    )


    // =======================================================
    // 8. WRAP READ
    // =======================================================

    `uvm_info(
      "TEST",
      "Starting WRAP READ test",
      UVM_LOW
    )


    seq.scenario =
      axi_sequence::WRAP_READ;


    seq.start(
      env.agent.sequencer
    );


    env.agent.driver.
      wait_for_reads_done();


    `uvm_info(
      "TEST",
      "WRAP READ completed",
      UVM_LOW
    )


    // =======================================================
    // FINISHED
    // =======================================================

    `uvm_info(
      "TEST",
      "All AXI READ, WRITE and WRAP tests completed",
      UVM_LOW
    )


    phase.drop_objection(this);


  endtask


endclass
