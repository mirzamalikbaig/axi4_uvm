#!/usr/bin/env bash
# ****************************************************************************
# AXI4 UVM Verification
# Author      : Agha Malik Baig Mirza
# Updated     : October 2026
# Filename    : coverage.sh
# Description : Root entry point for the URG coverage report.
# ****************************************************************************


set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/scripts/coverage.sh" "$@"
