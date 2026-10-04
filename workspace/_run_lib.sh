#!/usr/bin/env bash
# _run_lib.sh — sourced by all run_theme_*.sh scripts
# Defines the shared MODEL_MATRIX and run_model() helper.

# ── Model matrix ─────────────────────────────────────────────────────────────
# Columns: "provider/model  threads  throttle  sample  label"
#
# Throttle is tuned to stay comfortably under each provider's free-tier RPM.
# Groq new-model RPM is unknown so we use conservative values (≈12 RPM).
# Mistral free tier is 60 RPM; we run at ≈26–48 RPM.
MODEL_MATRIX=(
    # Groq ── 2 threads × throttle → conservative until RPM is confirmed
    "groq/openai/gpt-oss-120b          2  10  0.30  groq-gpt-oss-120b"
    "groq/openai/gpt-oss-20b           2   7  0.30  groq-gpt-oss-20b"
    "groq/qwen/qwen3.8-27b             2   7  0.30  groq-qwen3-27b"
    "groq/allam-2-7b                   2   5  0.30  groq-allam-7b"
    # Mistral ── 60 RPM free tier
    "mistral/ministral-3b-latest       4   5  0.50  mistral-ministral-3b"
    "mistral/ministral-8b-latest       4   5  0.50  mistral-ministral-8b"
    "mistral/mistral-medium-3.5        3   7  0.30  mistral-medium35"
    "mistral/magistral-small-latest    3   7  0.30  mistral-magistral-sm"
    "mistral/codestral-latest          4   5  0.40  mistral-codestral"
)

# ── Quota check ───────────────────────────────────────────────────────────────
# Returns 0 (success) if the model run produced useful data.
# Returns 1 (quota exhausted) if ≥90% of entries are errors.
_check_quota() {
    local tag="$1"
    local result_file
    result_file=$(ls -t results/*_${tag}_*.jsonl 2>/dev/null | head -1)
    [[ -z "$result_file" ]] && return 0  # no file yet — treat as ok

    python3 - "$result_file" <<'PYEOF'
import json, sys
path = sys.argv[1]
try:
    data = [json.loads(l) for l in open(path) if l.strip()]
except Exception:
    sys.exit(0)
if not data:
    sys.exit(0)
errors = sum(1 for d in data if d.get("error"))
pct = errors / len(data)
print(f"  │  {errors}/{len(data)} entries errored ({pct:.0%})")
sys.exit(1 if pct >= 0.90 else 0)
PYEOF
}

# Path to this file's directory (works when sourced)
_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── run_model ─────────────────────────────────────────────────────────────────
# Args: dataset model threads throttle sample label
# Returns 0 on clean run, 1 if quota exhausted (caller should skip model).
run_model() {
    local dataset="$1" model="$2" threads="$3" throttle="$4" sample="$5" label="$6"

    echo ""
    echo "  ┌─ [$(date '+%H:%M:%S')] $label"
    echo "  │  model=${model}  sample=${sample}  threads=${threads}  throttle=${throttle}s"

    # Pre-flight: single call to confirm model is reachable before running dataset
    if ! python3 "${_LIB_DIR}/scripts/preflight.py" "$model" 2>/dev/null; then
        echo "  └─ QUOTA EXHAUSTED (pre-flight 429) — skipping, try again tomorrow"
        return 1
    fi

    spikee test \
        --dataset "$dataset" \
        --target llm_provider \
        --target-options "model=${model}" \
        --threads "$threads" \
        --throttle "$throttle" \
        --max-retries 1 \
        --sample "$sample" \
        --sample-seed random \
        --no-auto-resume \
        --tag "$label" \
        2>/dev/null
    local spikee_exit=$?

    if _check_quota "$label"; then
        echo "  └─ done"
        return 0
    else
        echo "  └─ QUOTA EXHAUSTED — skipping this model, try again tomorrow"
        return 1
    fi
}

# ── run_theme ─────────────────────────────────────────────────────────────────
# Iterates MODEL_MATRIX against a single pre-built dataset.
# Args: theme_name dataset_path sample_override(optional)
run_theme() {
    local theme_name="$1"
    local dataset="$2"
    local sample_override="${3:-}"  # optional per-theme sample rate

    if [[ ! -f "$dataset" ]]; then
        echo "  [ERROR] Dataset not found: $dataset"
        echo "  Run ./build_datasets.sh first."
        exit 1
    fi

    local entry_count
    entry_count=$(wc -l < "$dataset")

    echo ""
    echo "════════════════════════════════════════════════════════════"
    echo "  ${theme_name}"
    echo "  Dataset: ${dataset##*/} (${entry_count} entries)"
    echo "  Models:  ${#MODEL_MATRIX[@]}"
    echo "  Started: $(date)"
    echo "════════════════════════════════════════════════════════════"

    local skipped=0 succeeded=0

    for model_entry in "${MODEL_MATRIX[@]}"; do
        read -r model threads throttle sample mlabel <<< "$model_entry"
        local sample_rate="${sample_override:-$sample}"
        local tag="${theme_name}-${mlabel}"
        # Tags can only contain letters, numbers, dash, underscore
        tag="${tag//[^a-zA-Z0-9_-]/-}"

        if run_model "$dataset" "$model" "$threads" "$throttle" "$sample_rate" "$tag"; then
            ((succeeded++))
        else
            ((skipped++))
        fi
    done

    echo ""
    echo "════════════════════════════════════════════════════════════"
    echo "  ${theme_name} complete at $(date)"
    echo "  ${succeeded} models ran cleanly  |  ${skipped} skipped (quota)"
    if [[ $skipped -gt 0 ]]; then
        echo "  Skipped models had quota exhausted — re-run tomorrow."
    fi
    echo "════════════════════════════════════════════════════════════"
}
