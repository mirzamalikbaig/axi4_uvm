#!/usr/bin/env bash
set -euo pipefail

# Run from the repository directory, even when called from elsewhere.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if ! command -v vcs >/dev/null 2>&1; then
  echo "Error: Synopsys VCS is not available in PATH." >&2
  echo "Load the VCS environment for this machine, then run this script again." >&2
  exit 127
fi

vcs -full64 -sverilog -timescale=1ns/1ps -ntb_opts uvm-1.2 -top top \
  tb_top.sv axi_mem_slave.sv -o simv

./simv +UVM_TESTNAME=axi_test "$@"
