#!/usr/bin/env bash
# run_experiments.sh
#
# Continuously rotates through every dataset × every model.
# Each model run samples a random slice of the dataset so daily quotas
# are never exhausted in a single pass — coverage builds up over time.
#
# Usage (from workspace/):
#   ./run_experiments.sh          # one full pass then exit
#   ./run_experiments.sh --loop   # keep looping until Ctrl-C
#
# Prerequisites (.env):
#   GOOGLE_API_KEY=...
#   GROQ_API_KEY=...
#   MISTRAL_API_KEY=...

set -euo pipefail

LOOP=false
[[ "${1:-}" == "--loop" ]] && LOOP=true

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Activate the venv so spikee is on PATH regardless of how this script is launched.
source "${SCRIPT_DIR}/../.venv/bin/activate"

# ---------------------------------------------------------------------------
# Datasets — paths relative to workspace/
# Each entry: "path  label"
# ---------------------------------------------------------------------------
DATASETS=(
    "datasets/old/datasets/cybersec-full-prompt-dataset-1791128433.jsonl      full-prompt"
    "datasets/old/datasets/cybersec-full-prompt-sys-dataset-1791133571.jsonl  full-prompt-sys"
    "datasets/old/datasets/cybersec-user-input-dataset-1791111907.jsonl       user-input"
    "datasets/old/datasets/cybersec-dataexfil-dataset-1791112471.jsonl        dataexfil-only"
)

# ---------------------------------------------------------------------------
# Model matrix — each entry: "provider/model  threads  throttle  sample  label"
#
# Throttle formula: ceil(60 * threads / RPM) + buffer
#
# Provider   Model                   Free RPM  Free RPD   threads  throttle  sample
# ─────────────────────────────────────────────────────────────────────────────────
# Google     gemini-2.5-pro            5        25         1        14        0.05
# Google     gemini-2.5-flash         10       500         1         7        0.20
# Google     gemini-2.0-flash         15      1500         1         5        0.25
# Google     gemini-1.5-flash         15      1500         2        10        0.30
# Groq       llama-3.3-70b            30      1000         2         5        0.40
# Groq       llama-3.1-8b             30     14400         2         5        1.00
# Groq       gemma2-9b                30     14400         2         5        0.50
# Mistral    mistral-small-latest     60       n/a         4         5        0.50
# Mistral    open-mistral-nemo        60       n/a         4         5        0.50
# Mistral    open-mistral-7b          60       n/a         4         5        0.40
# Mistral    open-mixtral-8x7b        60       n/a         3         7        0.40
# Mistral    codestral-latest         60       n/a         4         5        0.40
# ---------------------------------------------------------------------------
MODEL_MATRIX=(
    # Google — Gemini 3 family (older Gemini 2.x all deprecated as of Oct 2026)
    "google/gemini-3.1-pro                              1  14  0.05  google-gemini31-pro"
    "google/gemini-3.1-flash                            1   7  0.20  google-gemini31-flash"
    "google/gemini-3-flash                              1   5  0.25  google-gemini3-flash"
    "google/gemini-3.8-flash                            1   5  0.25  google-gemini38-flash"
    # Groq — Llama 4 family (llama-3.x and gemma2 all decommissioned as of Oct 2026)
    "groq/meta-llama/llama-4-maverick-17b-128e-instruct 2   5  0.40  groq-llama4-maverick"
    "groq/meta-llama/llama-4-scout-17b-16e-instruct     2   5  0.50  groq-llama4-scout"
    # Mistral — confirmed working (hitting rate limits = alive)
    "mistral/mistral-small-latest                       4   5  0.50  mistral-small"
    "mistral/open-mistral-nemo                          4   5  0.50  mistral-nemo-12b"
    "mistral/open-mistral-7b                            4   5  0.40  mistral-7b-legacy"
    "mistral/open-mixtral-8x7b                          3   7  0.40  mixtral-8x7b-legacy"
    "mistral/codestral-latest                           4   5  0.40  mistral-codestral"
)

# ---------------------------------------------------------------------------

run_model() {
    local dataset="$1" model="$2" threads="$3" throttle="$4" sample="$5" label="$6"

    echo ""
    echo "  ┌─ [$(date '+%H:%M:%S')] $label"
    echo "  │  dataset=${dataset##*/}  sample=${sample}  threads=${threads}  throttle=${throttle}s"

    spikee test \
        --dataset "$dataset" \
        --target llm_provider \
        --target-options "model=${model}" \
        --threads "$threads" \
        --throttle "$throttle" \
        --max-retries 2 \
        --sample "$sample" \
        --sample-seed random \
        --no-auto-resume \
        --tag "$label" \
        && echo "  └─ done" \
        || echo "  └─ [WARN] exited non-zero — likely hit daily cap. Continuing."
}

run_pass() {
    local pass="$1"
    echo ""
    echo "════════════════════════════════════════════════════════════"
    echo "  Pass ${pass} started at $(date)"
    echo "  ${#DATASETS[@]} datasets × ${#MODEL_MATRIX[@]} models = $((${#DATASETS[@]} * ${#MODEL_MATRIX[@]})) runs"
    echo "════════════════════════════════════════════════════════════"

    for ds_entry in "${DATASETS[@]}"; do
        read -r ds_path ds_label <<< "$ds_entry"
        ds_abs="${SCRIPT_DIR}/${ds_path}"

        if [[ ! -f "$ds_abs" ]]; then
            echo "  [SKIP] Dataset not found: $ds_abs"
            continue
        fi

        echo ""
        echo "  ════ Dataset: ${ds_label} (${ds_path##*/}) ════"

        for model_entry in "${MODEL_MATRIX[@]}"; do
            read -r model threads throttle sample mlabel <<< "$model_entry"
            run_model "$ds_abs" "$model" "$threads" "$throttle" "$sample" "${ds_label}-${mlabel}"
        done
    done

    echo ""
    echo "════════════════════════════════════════════════════════════"
    echo "  Pass ${pass} complete at $(date)"
    echo "════════════════════════════════════════════════════════════"
}

pass=1
if $LOOP; then
    while true; do
        run_pass "$pass"
        ((pass++))
        echo "  Sleeping 60s before next pass..."
        sleep 60
    done
else
    run_pass "$pass"
fi
