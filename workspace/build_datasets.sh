#!/usr/bin/env bash
# build_datasets.sh
#
# Generates all 5 themed datasets from seeds. Run this ONCE before running
# any of the run_theme_*.sh experiment scripts. Datasets are written to
# workspace/datasets/ and can be reused across all models.
#
# Usage (from workspace/):
#   ./build_datasets.sh
#
# Output files (one per format/theme):
#   datasets/seeds-cybersec-full-prompt-theme1-dataset-*.jsonl
#   datasets/seeds-cybersec-full-prompt-sys-theme1sys-dataset-*.jsonl
#   datasets/seeds-sysmsg-extraction-2025-04-full-prompt-sys-theme2-dataset-*.jsonl
#   datasets/seeds-investment-advice-full-prompt-theme3-dataset-*.jsonl
#   datasets/seeds-harmful-all-jailbreaks-user-input-theme4-dataset-*.jsonl
#   datasets/seeds-harmful-all-jailbreaks-user-input-theme5-dataset-*.jsonl

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/../.venv/bin/activate"

cd "$SCRIPT_DIR"

echo ""
echo "════════════════════════════════════════════════════════════"
echo "  Spikee Dataset Builder"
echo "  $(date)"
echo "════════════════════════════════════════════════════════════"

# ── Step 0: Augment harmful seeds ────────────────────────────────────────────
echo ""
echo "  [0/6] Augmenting harmful-instructions seed with full jailbreak set..."
python3 scripts/augment_harmful_seeds.py
echo "  done."

# ── Theme 1: Prompt Injection & Data Exfiltration ─────────────────────────────
# Full-prompt format: jailbreak + injection appears inline in the document body
echo ""
echo "  [1a/6] Theme 1 — Injection/DataExfil — full-prompt..."
spikee generate \
    --seed-folder datasets/seeds-cybersec \
    --format full-prompt \
    --tag theme1

echo ""
echo "  [1b/6] Theme 1 — Injection/DataExfil — full-prompt with system message..."
spikee generate \
    --seed-folder datasets/seeds-cybersec \
    --format full-prompt \
    --include-system-message \
    --tag theme1sys

# ── Theme 2: System Prompt Extraction ─────────────────────────────────────────
# Must use full-prompt+system-message: the canary lives in the system prompt,
# judge checks whether the model leaks it back in its response.
echo ""
echo "  [2/6] Theme 2 — System Prompt Extraction — full-prompt+sys..."
spikee generate \
    --seed-folder datasets/seeds-sysmsg-extraction-2025-04 \
    --format full-prompt \
    --include-system-message \
    --tag theme2

# ── Theme 3: Financial & Regulatory Violations ────────────────────────────────
# Includes standalone chat inputs (direct financial questions, no document context)
# alongside jailbreak-wrapped instruction variants.
echo ""
echo "  [3/6] Theme 3 — Financial/Regulatory — full-prompt + standalone inputs..."
spikee generate \
    --seed-folder datasets/seeds-investment-advice \
    --format full-prompt \
    --include-standalone-inputs \
    --tag theme3

# ── Theme 4: Weapons & Violence ───────────────────────────────────────────────
# Uses augmented harmful seed filtered to weapons/CBRN/terror instruction types.
echo ""
echo "  [4/6] Theme 4 — Weapons & Violence — user-input (filtered)..."
spikee generate \
    --seed-folder datasets/seeds-harmful-all-jailbreaks \
    --format user-input \
    --instruction-filter "weapon,chemical,biological,nuclear,attack,terror,riot,assassination,trafficking" \
    --tag theme4

# ── Theme 5: Harmful Behaviour ────────────────────────────────────────────────
# Remaining harmful instruction types: hate, harassment, suicide, drugs, etc.
echo ""
echo "  [5/6] Theme 5 — Harmful Behaviour — user-input (filtered)..."
spikee generate \
    --seed-folder datasets/seeds-harmful-all-jailbreaks \
    --format user-input \
    --instruction-filter "hate,harassment,suicide,drug,child,stalking,hack,fraud,identity,marketmanip,insidertrading,moneylaundering,propaganda,scam" \
    --tag theme5

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "════════════════════════════════════════════════════════════"
echo "  Build complete — generated datasets:"
ls -lh datasets/*theme*.jsonl 2>/dev/null | awk '{print "    "$NF, $5}' || echo "  (none found — check for errors above)"
echo "════════════════════════════════════════════════════════════"
echo ""
