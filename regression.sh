#!/usr/bin/env bash
set -euo pipefail

# run from this repo even if the script is called somewhere else
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if ! command -v vcs >/dev/null 2>&1; then
  echo "Error: Synopsys VCS is not available in PATH." >&2
  echo "Load the VCS environment, then run this script again." >&2
  exit 127
fi

mkdir -p logs

echo "Compiling AXI4 UVM regression..."
vcs -full64 -sverilog -ntb_opts uvm-1.2 -top top \
  tb_top.sv axi_mem_slave.sv -o simv

SEEDS=(1 10 25 50 100)
PASS_COUNT=0
FAIL_COUNT=0

for seed in "${SEEDS[@]}"; do
  log="logs/axi_seed_${seed}.log"
  echo
  echo "========================================"
  echo "Running AXI regression seed ${seed}"
  echo "========================================"

  if ./simv +UVM_TESTNAME=axi_test +ntb_random_seed="${seed}" +UVM_NO_RELNOTES | tee "$log"; then
    sim_rc=0
  else
    sim_rc=$?
  fi

  if [ "$sim_rc" -ne 0 ] || grep -Eq 'UVM_(ERROR|FATAL)[[:space:]]*:[[:space:]]*[1-9][0-9]*' "$log"; then
    echo "SEED ${seed}: FAIL"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  else
    echo "SEED ${seed}: PASS"
    PASS_COUNT=$((PASS_COUNT + 1))
  fi
done

echo
echo "========================================"
echo "AXI REGRESSION SUMMARY"
echo "========================================"
echo "PASS = ${PASS_COUNT}"
echo "FAIL = ${FAIL_COUNT}"

if [ "$FAIL_COUNT" -ne 0 ]; then
  exit 1
fi

echo "REGRESSION PASS"
