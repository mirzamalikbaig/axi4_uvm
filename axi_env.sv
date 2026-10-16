/******************************************************************************
 * Project     : AXI4 UVM Verification
 * File        : axi_env.sv
 * Author      : Mirza Agha Malik Baig
 * Description : Builds the AXI agent and scoreboard and connects monitor
 *               analysis output.
 *****************************************************************************/

class axi_env extends uvm_env;

  `uvm_component_utils(axi_env)

  axi_agent      agent;
  axi_scoreboard scoreboard;
  axi_coverage   coverage;


  function new(string name = "axi_env",
               uvm_component parent = null);

    super.new(name, parent);

  endfunction


  function void build_phase(uvm_phase phase);

    super.build_phase(phase);

    agent =
      axi_agent::type_id::create("agent", this);

    scoreboard =
      axi_scoreboard::type_id::create("scoreboard", this);

    coverage =
      axi_coverage::type_id::create("coverage", this);

  endfunction


  function void connect_phase(uvm_phase phase);

    super.connect_phase(phase);

    // Monitor publishes completed transactions
    // Scoreboard receives them through analysis_imp
    agent.monitor.ap.connect(scoreboard.imp);
    agent.monitor.ap.connect(coverage.analysis_export);

  endfunction

endclass
