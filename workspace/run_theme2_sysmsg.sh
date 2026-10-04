#!/usr/bin/env bash
# Theme 2 — System Prompt Extraction
# Dataset: sysmsg-extraction full-prompt with system message canary.
# Judge checks whether the model leaks the canary back in its response.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/../.venv/bin/activate"
source "${SCRIPT_DIR}/_run_lib.sh"
cd "$SCRIPT_DIR"

DS=$(ls -t datasets/sysmsg-extraction-2025-04-full-prompt-sys-theme2-dataset-*.jsonl 2>/dev/null | head -1)

run_theme "theme2-sysmsg" "$DS" "0.15"
