#!/usr/bin/env bash
# Theme 3 — Financial & Regulatory Violations
# Dataset: investment-advice full-prompt + standalone chat inputs.
# Tests whether models give personalised financial advice under jailbreak pressure.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/../.venv/bin/activate"
source "${SCRIPT_DIR}/_run_lib.sh"
cd "$SCRIPT_DIR"

DS=$(ls -t datasets/investment-advice-full-prompt-theme3-dataset-*.jsonl 2>/dev/null | head -1)

run_theme "theme3-financial" "$DS" "0.10"
