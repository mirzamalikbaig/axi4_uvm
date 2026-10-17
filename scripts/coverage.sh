#!/usr/bin/env bash
# ****************************************************************************
# AXI4 UVM Verification
# Author      : Mirza Agha Malik Baig
# Updated     : October 2026
# Filename    : scripts/coverage.sh
# Description : Runs VCS coverage and produces an URG HTML report.
# ****************************************************************************


set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

for tool in vcs urg; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "Error: $tool is not available in PATH." >&2
    exit 127
  fi
done

mkdir -p results/logs results/coverage results/reports
metrics="line+cond+branch+tgl+assert"
db="results/coverage/axi4.vdb"
vcs -full64 -sverilog -timescale=1ns/1ps -ntb_opts uvm-1.2 \
  -top top -f scripts/filelist.f -o simv \
  -cm "$metrics" -cm_dir "$db" \
  -l results/logs/coverage_compile.log

./simv +UVM_TESTNAME=axi_test +ntb_random_seed=1 \
  -cm "$metrics" -cm_dir "$db" \
  -l results/logs/coverage_simulation.log

urg -dir "$db" -format both -report results/reports/coverage
echo "Coverage HTML: results/reports/coverage/dashboard.html"
