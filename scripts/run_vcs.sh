#!/usr/bin/env bash
# ****************************************************************************
# AXI4 UVM Verification
# Author      : Mirza Agha Malik Baig
# Updated     : October 2026
# Filename    : scripts/run_vcs.sh
# Description : Compiles and runs the AXI4 UVM test on Synopsys VCS.
# ****************************************************************************


set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

if ! command -v vcs >/dev/null 2>&1; then
  echo "Error: Synopsys VCS is not available in PATH." >&2
  exit 127
fi

mkdir -p results/logs
vcs -full64 -sverilog -timescale=1ns/1ps -ntb_opts uvm-1.2 \
  -top top -f scripts/filelist.f -o simv \
  -l results/logs/compile.log

./simv +UVM_TESTNAME=axi_test -l results/logs/simulation.log "$@"
