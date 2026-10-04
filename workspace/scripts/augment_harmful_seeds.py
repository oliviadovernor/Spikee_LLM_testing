#!/usr/bin/env python3
"""
Creates datasets/seeds-harmful-all-jailbreaks/ by combining:
  - All instructions from seeds-harmful-instructions-only
  - The rich 69-variant jailbreak set from seeds-cybersec
  - Base user input from seeds-harmful-instructions-only

This augmented seed is then split at generate time using --instruction-filter
to produce the Weapons & Violence dataset (theme 4) and Harmful Behaviour
dataset (theme 5).

Run from workspace/:
    python3 scripts/augment_harmful_seeds.py
"""

import json
import os
import shutil

WORKSPACE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC_INSTRUCTIONS = os.path.join(WORKSPACE, "datasets", "seeds-harmful-instructions-only")
SRC_JAILBREAKS   = os.path.join(WORKSPACE, "datasets", "seeds-cybersec")
OUT_DIR          = os.path.join(WORKSPACE, "datasets", "seeds-harmful-all-jailbreaks")

os.makedirs(OUT_DIR, exist_ok=True)

# Instructions — copy all 43 harmful instructions unchanged
shutil.copy(
    os.path.join(SRC_INSTRUCTIONS, "instructions.jsonl"),
    os.path.join(OUT_DIR, "instructions.jsonl"),
)
print(f"  instructions: copied from {SRC_INSTRUCTIONS}")

# Jailbreaks — use cybersec's rich 69-variant set instead of harmful's single no-jailbreak
shutil.copy(
    os.path.join(SRC_JAILBREAKS, "jailbreaks.jsonl"),
    os.path.join(OUT_DIR, "jailbreaks.jsonl"),
)
jb_count = sum(1 for _ in open(os.path.join(OUT_DIR, "jailbreaks.jsonl")))
print(f"  jailbreaks:   {jb_count} variants copied from seeds-cybersec")

# Base user inputs — harmful seed has a single placeholder document
shutil.copy(
    os.path.join(SRC_INSTRUCTIONS, "base_user_inputs.jsonl"),
    os.path.join(OUT_DIR, "base_user_inputs.jsonl"),
)
print(f"  base_user_inputs: copied from {SRC_INSTRUCTIONS}")

# Verify instruction type breakdown
import collections
types = collections.Counter()
with open(os.path.join(OUT_DIR, "instructions.jsonl")) as f:
    for line in f:
        e = json.loads(line)
        types[e.get("instruction_type", "?")] += 1

THEME4 = {"weapon","chemical","biological","nuclear","attack","terror","riot","assassination","trafficking"}
THEME5 = set(types.keys()) - THEME4

t4 = sum(v for k, v in types.items() if k in THEME4)
t5 = sum(v for k, v in types.items() if k in THEME5)

print(f"\n  Seed ready at: {OUT_DIR}")
print(f"  Theme 4 (Weapons & Violence):  {t4} instructions × {jb_count} jailbreaks = {t4 * jb_count} entries")
print(f"  Theme 5 (Harmful Behaviour):   {t5} instructions × {jb_count} jailbreaks = {t5 * jb_count} entries")
print(f"\n  instruction_type breakdown:")
for k, v in sorted(types.items(), key=lambda x: -x[1]):
    tag = "T4" if k in THEME4 else "T5"
    print(f"    [{tag}] {k}: {v}")
