# AXI4 UVM Verification

A SystemVerilog/UVM verification environment for an educational **AXI4 memory-mapped slave**. The project implements an AXI4 master-side UVM testbench, a memory-slave DUT, protocol stability assertions, functional coverage, and a reference-memory scoreboard. The completed directed suite contains **12 verification scenarios**.

**Status:** Completed at the defined project scope. The testbench was successfully simulated with **Synopsys VCS (UVM 1.2)** on October 16, 2026.

## Verified results

| Measurement | Recorded result |
| --- | --- |
| Functional coverage (SystemVerilog covergroup) | **98.15%** |
| UVM errors / warnings / fatals | **0 / 0 / 0** |
| URG module-definition coverage score | **66.04%** |
| URG line coverage | **91.79%** |
| URG condition / branch / toggle coverage | **68.66% / 74.51% / 34.13%** |
| URG assertion coverage | **61.11%** |
| Completed directed scenarios | **12** |

The functional-coverage percentage and the URG score are **different metrics**. These results are from the completed VCS run, not evidence of a multi-seed regression. The regression script is supplied for repeatable runs.

## Verification architecture

```text
                        AXI4 UVM Test
                              |
                           Sequence
                              |
                           Sequencer
                              |
                            Driver
                              |
                        AXI Interface  <------>  AXI4 Memory Slave (DUT)
                              |
                            Monitor
                              |
                 +------------+-------------+
                 |                          |
             Scoreboard               Functional Coverage
         (reference memory)              (covergroups)
```

The test configures a virtual AXI interface. The **sequencer** sends transaction items to the **driver**; the driver performs bus handshakes with the memory slave. The **monitor** independently reconstructs accepted transactions and broadcasts them to the **scoreboard** and the **coverage subscriber**.

## Implemented features

- AXI4 **AW, W, B, AR, and R** channels with VALID/READY handshakes.
- 32-bit data bus with 32-bit addresses and 4-bit transaction IDs.
- Byte-addressable memory and byte-lane writes controlled by **WSTRB**.
- **FIXED, INCR, and WRAP** burst-address generation; single- and multi-beat transfers.
- Up to **two outstanding reads and two outstanding writes**.
- Same-ID ordering and different-ID out-of-order completion in the educational slave model.
- AXI4 write data associated with the oldest pending write address (there is no WID in AXI4).
- Independent scoreboard reference memory, per-beat read-data comparisons, and checks of OKAY responses.
- Write commits held in original AW/W order even when B responses arrive out of order.
- Assertions checking payload/VALID stability on AW, W, AR, B, and R channels when stalled.
- Functional coverpoints and crosses for operation, burst type, burst length, ID range, size, and response.

## Completed test scenarios

| # | Scenario | What the test demonstrates |
| --- | --- | --- |
| 1 | Memory setup | Two writes initialize known memory values. |
| 2 | Different-ID read | Two outstanding reads can return in a different ID order. |
| 3 | Same-ID read | Responses with the same ID preserve request ordering. |
| 4 | Different-ID write | Two writes can return B responses out of order across IDs. |
| 5 | Same-ID write | B responses for the same ID remain ordered. |
| 6 | Write readback | Reads match previously written data. |
| 7 | WRAP write | Four beats visit addresses 12, 0, 4, and 8. |
| 8 | WRAP read | The scoreboard verifies each WRAP read beat. |
| 9 | FIXED write | Four writes target one address; a single-beat FIXED write also runs. |
| 10 | FIXED read | Repeated-address data and the single-beat FIXED result are checked. |
| 11 | Multi-beat INCR write | Four beats write addresses 900, 904, 908, and 912. |
| 12 | Multi-beat INCR read | Four returned words match the reference memory. |

All 12 scenarios completed in the recorded VCS simulation with zero UVM errors. The 12 scenarios are executed by one `axi_test` class through the `axi_sequence` scenario selector.

## Repository structure

```text
axi4_uvm/
├── rtl/                       AXI4 memory slave DUT
│   └── axi_mem_slave.sv
├── tb/
│   ├── agents/                Transaction, agent, sequencer, driver, monitor
│   ├── coverages/             Functional coverage collector
│   ├── env/                   Environment and reference-memory scoreboard
│   ├── interfaces/            AXI4 signal interface
│   ├── sequences/             All twelve stimulus scenarios
│   ├── sva/                   AXI protocol assertions
│   ├── tests/                 UVM test class
│   └── top/                   Clock, reset, DUT, and UVM top
├── scripts/
│   ├── filelist.f             VCS compilation file list
│   ├── run_vcs.sh             Compile and run test
│   ├── regression.sh          Five-seed regression
│   └── coverage.sh            Collect coverage and generate URG HTML
├── docs/                      Project screenshots
├── run_vcs.sh                 Easy command from repository root
├── regression.sh              Easy command from repository root
├── coverage.sh                Easy command from repository root
└── README.md
```

## Run with Synopsys VCS

Run the following **from the repository root**, on a host with Synopsys VCS/UVM 1.2 enabled:

```bash
./run_vcs.sh
```

The script saves compilation and simulation logs to `results/logs/`. You may also pass simulator plusargs to `./run_vcs.sh`.

For a five-seed regression (seeds 1, 10, 25, 50, 100):

```bash
./regression.sh
cat results/regression/regression_summary.txt
```

For VCS and URG coverage:

```bash
./coverage.sh
```

The URG HTML report is generated at `results/reports/coverage/dashboard.html`. Open the report **after extracting the full report folder** so its linked files load. The generated `results/` directory and VCS build files are excluded from Git.

## Project evidence and source

- [Basic simulation screenshot](docs/axi4_uvm_basic_test_result.png)
- Detailed bus checking: `tb/env/axi_scoreboard.sv`
- Directed scenarios: `tb/sequences/axi_sequence.sv`
- Functional coverage: `tb/coverages/axi_coverage.sv`
- Assertions: `tb/sva/axi_assertions.sv`

**Author:** Mirza Agha Malik Baig

**Reference:** Arm AMBA AXI/ACE protocol specification (AXI4).
