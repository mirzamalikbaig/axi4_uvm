# AXI4 UVM Verification

A SystemVerilog/UVM verification environment for an educational **AXI4 memory-mapped slave**. The project implements an AXI4 master-side UVM testbench, a memory-slave DUT, protocol stability assertions, functional coverage, and a reference-memory scoreboard. The test contains **12 original directed scenarios**, followed by focused final checks for **partial write strobes (WSTRB)** and **VALID/READY backpressure on all five AXI4 channels**.

**Status:** Final verification additions were committed to `main` in November 2026. The updated code has been validated on the university VCS setup according to the project run; the latest detailed VCS/URG output has not been committed to this repository. The archived numerical results below are from the original October 16, 2026 simulation and must not be treated as the new final-run coverage.

For the implementation details and final-run checks, see [Final verification notes](docs/final_verification_notes.md).

## Archived measured results: October 16, 2026 baseline

| Measurement | Recorded result |
| --- | --- |
| Functional coverage (SystemVerilog covergroup) | **98.15%** |
| UVM errors / warnings / fatals | **0 / 0 / 0** |
| URG module-definition coverage score | **66.04%** |
| URG line coverage | **91.79%** |
| URG condition / branch / toggle coverage | **68.66% / 74.51% / 34.13%** |
| URG assertion coverage (18 total instrumented assertions) | **61.11%** |
| Completed baseline scenarios | **12** |

The functional-coverage percentage and the URG score are **different metrics**. Crucially, the baseline's **61.11% aggregate assertion figure did not mean the five AXI4 stability assertions had been exercised**: all five had zero non-vacuous successes because no stalls occurred. That gap motivated the additional backpressure test.

These measurements describe **only the 12-scenario October 16 run** (seed 1), not the November additions or a five-seed regression. The new final-run coverage percentage and assertion success counts should be copied from a saved fresh VCS/URG report, not inferred from the updated source code.

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
- Assertions checking payload/VALID stability on AW, W, AR, B, and R channels when stalled, plus **five assertion cover properties** that record actual stall conditions.
- Directed **partial WSTRB** writes with full-word readbacks after each write.
- Directed **backpressure** on AW, W, AR, B, and R. The educational DUT uses a test-only `tb_stall_ready` interface control to delay AWREADY, WREADY, and ARREADY; this is **not an AXI4 protocol signal**.
- Functional coverpoints and crosses for operation, burst type, burst length, ID range, size, and response.

## Original 12 directed scenarios

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

All 12 original scenarios completed in the archived October 16 VCS simulation with zero UVM errors. They remain the first twelve scenarios in the updated `axi_test`.

## Final verification additions (November 2026)

The updated `axi_test` runs these after the original scenarios:

| Addition | Stimulus and checking |
| --- | --- |
| **Partial WSTRB write/readback** | At address 1000, write `32'hAABBCCDD` with `1111`, then overwrite using `0001`, `0110`, and `1000`. Read back after each write; expected words are `AABBCCDD`, `AABBCC44`, `AA667744`, and `99667744`. The existing byte-addressable scoreboard checks each word. |
| **Five-channel backpressure** | The driver/DUT create short AW, W, and AR request stalls and B and R response stalls. The existing stability assertions check that VALID and payload do not change during a stall. Five `c_*_stall` cover properties record whether each channel was stalled. |

These are **two additional test groups** (implemented with four new sequence selectors: `PARTIAL_STROBE_WRITE`, `PARTIAL_STROBE_READ`, `BACKPRESSURE_WRITE`, and `BACKPRESSURE_READ`). They should not be included in the **old** 98.15% coverage measurement. See [final verification notes](docs/final_verification_notes.md) for details.

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
│   ├── sequences/             Original scenarios and final verification tests
│   ├── sva/                   AXI protocol assertions
│   ├── tests/                 UVM test class
│   └── top/                   Clock, reset, DUT, and UVM top
├── scripts/
│   ├── filelist.f             VCS compilation file list
│   ├── run_vcs.sh             Compile and run test
│   ├── regression.sh          Five-seed regression
│   └── coverage.sh            Collect coverage and generate URG HTML
├── docs/                      Screenshots and final verification notes
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

To verify the new test results, inspect `results/logs/simulation.log` for **`Partial WSTRB test completed`** and **`Five-channel backpressure test completed`** and check the UVM error/fatal totals. Inspect the newly generated URG assertion report for actual stall cover hits and non-vacuous successes. Do not quote the archived assertion percentage as the final-run value.

## Project evidence and source

- [Final verification implementation and validation notes](docs/final_verification_notes.md)
- [Archived October 16 coverage summary](result/coverage_summary.md)
- [Archived October 16 scenario summary](result/regression_summary.md)
- [Basic simulation screenshot](docs/axi4_uvm_basic_test_result.png)
- Detailed bus checking: `tb/env/axi_scoreboard.sv`
- Directed scenarios: `tb/sequences/axi_sequence.sv`
- Functional coverage: `tb/coverages/axi_coverage.sv`
- Assertions: `tb/sva/axi_assertions.sv`

**Author:** Agha Malik Baig Mirza

**Reference:** Arm AMBA AXI/ACE protocol specification (AXI4).
