# AXI4 UVM Verification Project

This repository contains a basic SystemVerilog/UVM testbench for a simple AXI4 memory-mapped slave. The project is being developed incrementally: the current goal is to run and understand the basic write/read path, then expand protocol coverage.

## Project goal

The testbench generates AXI4 transactions, drives them through an interface, observes completed bus transactions, and checks read data against a reference-memory model in the scoreboard.

The intended transaction flow is:

```text
Sequence → Sequencer → Driver → AXI Interface → DUT → Monitor → Scoreboard
```

## Verification architecture

- **Sequence** creates directed and constrained-random AXI transactions.
- **Sequencer** passes sequence items to the driver.
- **Driver** drives the AXI signals and collects responses.
- **Monitor** observes handshakes and publishes completed transactions.
- **Scoreboard** keeps reference memory and compares read data.
- **Agent** contains the sequencer, driver, and monitor.
- **Environment** builds the agent and scoreboard and connects the monitor analysis port.
- **Test** builds the environment, starts the sequence, and controls the UVM objection.
- **Top-level testbench** creates the clock and reset, configures the virtual interface, instantiates the DUT, and starts UVM.

## Current status

The current directed suite verifies basic read/write operation, two outstanding reads and writes, same-ID ordering, different-ID out-of-order completion, write readback, and a four-beat WRAP burst. The WRAP test starts at address `12` with `SIZE=2` and `LEN=3`, exercising the address order `12 -> 0 -> 4 -> 8`.

The monitor reconstructs completed transactions, the scoreboard maintains a byte-addressable reference memory, and write commits are kept in original AW/W order even when B responses return out of order across different IDs.

Protocol assertions now check VALID/payload stability during stalls, functional coverage samples completed transactions, and `regression.sh` runs the test across several seeds.

## Project files

- `tb_top.sv` — Top module, clock/reset, virtual-interface setup, DUT instance, and UVM startup. It includes the UVM testbench source files.
- `axi_if.sv` — AXI interface signals.
- `axi_mem_slave.sv` — Simple byte-addressable memory slave used as the DUT.
- `axi_txn.sv` — AXI transaction item.
- `axi_sequence.sv` — Directed and constrained-random stimulus.
- `axi_sequencer.sv` — UVM sequencer.
- `axi_driver.sv` — Drives AXI requests and accepts responses.
- `axi_monitor.sv` — Observes AXI handshakes and publishes transactions.
- `axi_scoreboard.sv` — Reference-memory model, WRAP address prediction, and read-data checks.
- `axi_assertions.sv` — AXI VALID/READY stall-stability assertions.
- `axi_coverage.sv` — Functional coverage subscriber for operation, burst, length, ID, and response behavior.
- `axi_agent.sv` — Groups the sequencer, driver, and monitor.
- `axi_env.sv` — Builds and connects the agent and scoreboard.
- `axi_test.sv` — Creates the environment and starts the sequence.
- `run_vcs.sh` — Compiles and runs the UVM test with Synopsys VCS.
- `docs/axi4_uvm_basic_test_result.png` — EDA Playground result screenshot.

## Run with Synopsys VCS

The project includes `run_vcs.sh`, which compiles the testbench with VCS and runs the `axi_test` UVM test. Run it from the repository root on a machine with Synopsys VCS and UVM support:

```bash
command -v vcs
vcs -ID
./run_vcs.sh
```

The script compiles `tb_top.sv` and `axi_mem_slave.sv`. The UVM source files are included by `tb_top.sv`, so they are not listed separately. Extra simulator arguments can be passed after the script name, for example:

```bash
./run_vcs.sh +UVM_VERBOSITY=UVM_HIGH
```

The script uses the VCS UVM 1.2 option. If the installed VCS setup uses another UVM version, update the option in `run_vcs.sh`.

## Current limitations

- The verification DUT is an educational memory slave, not a production AXI4 implementation.
- The implemented outstanding depth is intentionally limited to two reads and two writes.
- Directed INCR and WRAP scenarios are included. FIXED address behavior exists in the DUT/reference model, but a dedicated directed FIXED test is still a coverage hole.
- Narrow and unaligned transfers are outside the current completed scope.
- The AXI 4 KB boundary rule is not yet implemented.
- Error-response injection/negative testing is not yet part of the directed suite.
- The current regression is mostly directed, so changing the random seed does not yet create substantially different traffic.

## Next steps

1. Run `./regression.sh` and review the per-seed logs and functional-coverage report.
2. Add a small FIXED directed test if burst-type coverage closure is required.
3. Optionally add the 4 KB boundary rule if project time permits.
4. Capture final regression/coverage results for the project report and presentation.

1. Run the basic test with Synopsys VCS.
2. Add directed tests for more addresses, data values, and byte strobes.
3. Expand burst handling and scoreboard checks.
4. Add assertions, functional coverage, and regression tests.

## References

- [Arm AMBA AXI and ACE Protocol Specification](https://developer.arm.com/documentation/ihi0022/latest/)
- [AXI Protocol — VLSI Verify](https://vlsiverify.com/protocols/axi/)
