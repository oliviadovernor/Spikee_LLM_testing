#!/usr/bin/env bash
# Theme 4 — Weapons & Violence
# Dataset: harmful-instructions filtered to weapon/CBRN/terror types,
# wrapped across 21 jailbreak variants from the cybersec seed.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/../.venv/bin/activate"
source "${SCRIPT_DIR}/_run_lib.sh"
cd "$SCRIPT_DIR"

DS=$(ls -t datasets/harmful-all-jailbreaks-user-input-theme4-dataset-*.jsonl 2>/dev/null | head -1)

run_theme "theme4-weapons" "$DS" "0.50"
