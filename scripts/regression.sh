#!/usr/bin/env bash
# ****************************************************************************
# AXI4 UVM Verification
# Author      : Mirza Agha Malik Baig
# Updated     : October 2026
# Filename    : scripts/regression.sh
# Description : Runs the AXI4 test with five seeds and records results.
# ****************************************************************************


set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

if ! command -v vcs >/dev/null 2>&1; then
  echo "Error: Synopsys VCS is not available in PATH." >&2
  exit 127
fi

mkdir -p results/regression
vcs -full64 -sverilog -timescale=1ns/1ps -ntb_opts uvm-1.2 \
  -top top -f scripts/filelist.f -o simv \
  -l results/regression/compile.log

SEEDS=(1 10 25 50 100)
pass_count=0
fail_count=0
summary="results/regression/regression_summary.txt"
: > "$summary"

for seed in "${SEEDS[@]}"; do
  log="results/regression/axi_seed_${seed}.log"
  echo "===== AXI4 UVM seed ${seed} ====="
  if ./simv +UVM_TESTNAME=axi_test +ntb_random_seed="$seed" +UVM_NO_RELNOTES \
    2>&1 | tee "$log"; then
    sim_rc=0
  else
    sim_rc=$?
  fi

  if [[ "$sim_rc" -eq 0 ]] \
    && grep -Eq 'UVM_ERROR[[:space:]]*:[[:space:]]*0([[:space:]]|$)' "$log" \
    && grep -Eq 'UVM_FATAL[[:space:]]*:[[:space:]]*0([[:space:]]|$)' "$log" \
    && grep -q 'All AXI READ, WRITE, WRAP, FIXED and multi-beat INCR tests completed' "$log"; then
    echo "SEED $seed: PASS" | tee -a "$summary"
    pass_count=$((pass_count + 1))
  else
    echo "SEED $seed: FAIL (see $log)" | tee -a "$summary"
    fail_count=$((fail_count + 1))
  fi
done

printf 'PASS = %d\nFAIL = %d\n' "$pass_count" "$fail_count" | tee -a "$summary"
if (( fail_count > 0 )); then
  exit 1
fi
echo "REGRESSION PASS" | tee -a "$summary"
