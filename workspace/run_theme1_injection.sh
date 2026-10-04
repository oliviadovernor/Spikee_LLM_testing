#!/usr/bin/env bash
# Theme 1 — Prompt Injection & Data Exfiltration
# Datasets: cybersec full-prompt (with and without system message)
# Tests XSS, data-exfil-markdown, and long-output across 21 jailbreak types.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/../.venv/bin/activate"
source "${SCRIPT_DIR}/_run_lib.sh"
cd "$SCRIPT_DIR"

DS1=$(ls -t datasets/cybersec-full-prompt-theme1-dataset-*.jsonl 2>/dev/null | head -1)
DS2=$(ls -t datasets/cybersec-full-prompt-sys-theme1sys-dataset-*.jsonl 2>/dev/null | head -1)

run_theme "theme1-injection" "$DS1" "0.25"
run_theme "theme1sys-injection" "$DS2" "0.25"
