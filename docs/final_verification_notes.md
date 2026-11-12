# Final verification additions

**Source:** `main` branch, November 2026. These additions follow the two tests identified in Chapter 7.3 of the graduate project's preliminary report. The updated source has been reported as validated with Synopsys VCS on the university Linux environment. **Fresh detailed final-run coverage numbers are not checked into this repository**; the figures in `result/coverage_summary.md` are historical results from October 16, 2026.

## 1. Partial WSTRB test

At word-aligned address 1000, `axi_test` performs a write and complete-word readback at every step. The existing scoreboard verifies byte enables without changing its reference memory logic.

| Step | Write data | WSTRB | Expected readback |
| --- | --- | --- | --- |
| 0 | `AABBCCDD` | `1111` | `AABBCCDD` |
| 1 | `11223344` | `0001` | `AABBCC44` |
| 2 | `55667788` | `0110` | `AA667744` |
| 3 | `99AABBCC` | `1000` | `99667744` |

The sequence selectors are `PARTIAL_STROBE_WRITE` and `PARTIAL_STROBE_READ`. `strobe_step` selects the write pattern.

## 2. Five-channel VALID/READY backpressure

- **AW, W, AR:** the driver asserts VALID and holds it while a test-only `tb_stall_ready` control lowers the corresponding READY outputs of the educational memory-slave DUT for several cycles. This control is **not a standard AXI4 signal**.
- **B, R:** the driver holds BREADY and RREADY low while the slave presents the response, then releases them to finish the transfer.
- **Stability checks:** the five existing `a_*_stable` assertions check VALID and payload stability across stalled cycles. New `c_aw_stall`, `c_w_stall`, `c_ar_stall`, `c_b_stall`, and `c_r_stall` cover properties record actual stalls.

The selectors are `BACKPRESSURE_WRITE` and `BACKPRESSURE_READ`. The original twelve scenarios run first, with deliberate stalls disabled; the final tests run afterward.

## Run and collect evidence on the university server

From the repository root on a machine with Synopsys VCS/UVM 1.2 installed:

```bash
git pull --ff-only origin main
./run_vcs.sh
./coverage.sh
./regression.sh
```

- Simulation logs: `results/logs/simulation.log` (single-run script) and `results/logs/coverage_simulation.log` (coverage script).
- URG report: `results/reports/coverage/dashboard.html`.
- Final-test log markers: `Partial WSTRB test completed`, `Five-channel backpressure test completed`, and `All AXI tests including partial WSTRB and backpressure completed`.
- Review the UVM summary for errors/fatals and inspect the assertion report for non-vacuous successes and stall cover hits.

## Evidence scope

The repository's `result/coverage_summary.md`, `result/regression_summary.md`, and `result/simulation_excerpt.log` preserve the **October 16 baseline**: 12 directed scenarios, 98.15% functional coverage, and 61.11% URG aggregate assertion coverage. **Those numbers must not be presented as measurements from the updated final tests.**

The final report should use separately saved, dated VCS and URG output for the updated source when quoting final coverage percentages and assertion counts.
