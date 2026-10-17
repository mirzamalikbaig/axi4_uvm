# AXI4 UVM — Coverage Summary

**Tool:** Synopsys VCS / URG Y-2026.03-SP1  
**Evidence:** URG report generated October 16, 2026, using `results/coverage/fresh.vdb`.  
**Run:** 1 simulation of `axi_test`, random seed 1 (12 directed scenarios).

## Key results

| Measurement | Result | Visual |
|---|---:|:---:|
| **SystemVerilog functional coverage** (covergroup) | **98.15%** | 🟢 |
| **Module-definition coverage score** (URG) | **66.04%** | 🟡 |
| RTL / module-definition line coverage | 91.79% | 🟢 |
| Condition coverage | 68.66% | 🟡 |
| Branch coverage | 74.51% | 🟡 |
| Toggle coverage | 34.13% | 🔴 |
| Assertion coverage | 61.11% | 🟡 |
| UVM warnings / errors / fatals | **0 / 0 / 0** | 🟢 |

The URG **total dashboard score** is **71.39%**; the **module-definition score** is **66.04%**. These are different aggregations. Neither is interchangeable with the **98.15% functional covergroup coverage**.

## DUT-specific code coverage

| Module | Module score | Line | Condition | Branch | Toggle |
|---|---:|---:|---:|---:|---:|
| `axi_mem_slave` | 66.28% | 91.41% | 68.66% | 74.51% | 30.56% |
| `top` | 87.50% | 100.00% | — | — | 75.00% |

## Functional coverage model

The `axi_coverage::axi_cg` covergroup samples completed transactions and records READ/WRITE operation, FIXED/INCR/WRAP burst types, single/multi-beat length, high/low transaction-ID ranges, OKAY responses, and selected crosses.

## Assertion coverage interpretation

The URG report lists 18 assertions, of which 11 have recorded successes, 7 are uncovered, and 0 failed. The five user-defined AXI VALID/payload-stability assertions (`AW`, `W`, `AR`, `R`, `B`) are among the uncovered assertions; the completed run should **not** be described as comprehensive backpressure assertion coverage.

## Evidence and scope

- `simulation.log` — actual VCS/UVM simulation output and report summary.
- `regression_summary.txt` — scenario completion excerpts from **this one simulation** (not a multi-seed regression).
- The source archive contained the full Synopsys URG HTML report. To keep the repository tidy, this Markdown file records its key measurements instead of checking in many auto-generated HTML, JS, and CSS files.

**Project claim:** The defined 12-scenario suite ran successfully with 98.15% functional coverage and no UVM errors or warnings. This does not claim complete AXI4 compliance or 100% code coverage.
