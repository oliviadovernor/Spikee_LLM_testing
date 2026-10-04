#!/usr/bin/env python3
"""
Quick smoke-test: send a single "hello" to every model in the experiment matrix.
Prints PASS / FAIL / SKIP for each so you can confirm what's reachable before
running the full themed datasets.

Usage (from workspace/):
    python3 test_models.py
"""

import os
import sys
import time
from datetime import datetime

# .env lives alongside this script in workspace/
try:
    from dotenv import load_dotenv
    load_dotenv(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".env"))
except ImportError:
    pass

try:
    from openai import OpenAI
except ImportError:
    print("openai package not found — run: pip install openai")
    sys.exit(1)

# (provider_label, base_url, api_key_env, model_id, display_label)
MODELS = [
    # ── Groq ────────────────────────────────────────────────────────────────
    ("Groq", "https://api.groq.com/openai/v1", "GROQ_API_KEY", "openai/gpt-oss-120b",  "gpt-oss-120b"),
    ("Groq", "https://api.groq.com/openai/v1", "GROQ_API_KEY", "openai/gpt-oss-20b",   "gpt-oss-20b"),
    ("Groq", "https://api.groq.com/openai/v1", "GROQ_API_KEY", "qwen/qwen3.8-27b",     "qwen3-27b"),
    ("Groq", "https://api.groq.com/openai/v1", "GROQ_API_KEY", "allam-2-7b",           "allam-7b"),
    # ── Mistral ─────────────────────────────────────────────────────────────
    ("Mistral", "https://api.mistral.ai/v1", "MISTRAL_API_KEY", "ministral-3b-latest",      "ministral-3b"),
    ("Mistral", "https://api.mistral.ai/v1", "MISTRAL_API_KEY", "ministral-8b-latest",      "ministral-8b"),
    ("Mistral", "https://api.mistral.ai/v1", "MISTRAL_API_KEY", "mistral-medium-3.5",        "mistral-medium-3.5"),
    ("Mistral", "https://api.mistral.ai/v1", "MISTRAL_API_KEY", "magistral-small-latest",   "magistral-small"),
    ("Mistral", "https://api.mistral.ai/v1", "MISTRAL_API_KEY", "codestral-latest",         "codestral"),
]

PROMPT = "Reply with only the word HELLO."

GREEN  = "\033[32m"
RED    = "\033[31m"
YELLOW = "\033[33m"
BOLD   = "\033[1m"
RESET  = "\033[0m"


def probe(provider, base_url, api_key_env, model_id, label):
    api_key = os.getenv(api_key_env)
    if not api_key:
        return "SKIP", f"no {api_key_env} in .env"

    client = OpenAI(api_key=api_key, base_url=base_url)
    t0 = time.time()
    try:
        resp = client.chat.completions.create(
            model=model_id,
            messages=[{"role": "user", "content": PROMPT}],
            max_tokens=16,
            timeout=30,
        )
        elapsed = time.time() - t0
        content = (resp.choices[0].message.content or "").strip()[:60]
        return "PASS", f"{elapsed:.1f}s  → {content!r}"
    except Exception as e:
        elapsed = time.time() - t0
        msg = str(e)[:120]
        return "FAIL", f"{elapsed:.1f}s  {msg}"


def main():
    print(f"\n{BOLD}Spikee model probe — {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}{RESET}")
    print("─" * 70)

    results = []
    prev_provider = None

    for (provider, base_url, api_key_env, model_id, label) in MODELS:
        if provider != prev_provider:
            print(f"\n  {BOLD}── {provider} ──{RESET}")
            prev_provider = provider

        status, detail = probe(provider, base_url, api_key_env, model_id, label)

        icon = (
            f"{GREEN}✓ PASS{RESET}" if status == "PASS" else
            f"{YELLOW}– SKIP{RESET}" if status == "SKIP" else
            f"{RED}✗ FAIL{RESET}"
        )
        print(f"  {icon}  {label:<28} {detail}")
        results.append((status, label, detail))

    print("\n" + "─" * 70)
    passed  = sum(1 for s, *_ in results if s == "PASS")
    failed  = sum(1 for s, *_ in results if s == "FAIL")
    skipped = sum(1 for s, *_ in results if s == "SKIP")
    print(f"  {GREEN}{passed} passed{RESET}  {RED}{failed} failed{RESET}  {YELLOW}{skipped} skipped{RESET}\n")

    if failed:
        print(f"{RED}  Failed:{RESET}")
        for s, lbl, det in results:
            if s == "FAIL":
                print(f"    • {lbl}: {det}")
        print()


if __name__ == "__main__":
    main()
