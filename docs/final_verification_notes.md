# Final verification additions — VCS validation pending

This review branch adds the two focused checks identified in Chapter 7.3 of the preliminary report.

## 1. Partial WSTRB

At word-aligned address 1000, the UVM test writes and reads back after every step. The scoreboard compares full 32-bit values:

| Step | Write data | WSTRB | Expected read |
|---|---|---|---|
| 0 | AABBCCDD | 1111 | AABBCCDD |
| 1 | 11223344 | 0001 | AABBCC44 |
| 2 | 55667788 | 0110 | AA667744 |
| 3 | 99AABBCC | 1000 | 99667744 |

This exercises the existing byte-write behavior without changing the scoreboard.

## 2. Five-channel VALID/READY backpressure

- AW, W and AR: the driver raises VALID, while a test-only `tb_stall_ready` interface control makes the educational memory DUT hold READY low for three cycles, then releases it. This is a test control, **not an AXI4 protocol signal**.
- B and R: during a final directed write/read, the driver collector deasserts BREADY/RREADY and holds each low after VALID appears, then accepts the response.
- Existing `a_*_stable` assertions check payload stability. New `c_*_stall` cover properties detect whether each channel really experienced a VALID=1/READY=0 cycle.

The original twelve directed scenarios run first with backpressure disabled. The two additions run at the end.

## Validation instructions

On a Linux machine with Synopsys VCS/UVM 1.2:

```bash
git fetch origin
git switch final-wstrb-backpressure-tests
./run_vcs.sh
./coverage.sh
./regression.sh
```

Review `results/logs/simulation.log` and `results/logs/coverage_simulation.log` for zero UVM errors/fatals and all test-completion messages; open `results/reports/coverage/dashboard.html` and inspect the user-defined assertions and cover properties.

**Not yet validated:** This review branch has not been compiled or simulated in VCS here. Do not update the preliminary report's results (98.15% functional coverage, original assertion evidence, or scenario counts) until a fresh VCS run confirms the changes.
