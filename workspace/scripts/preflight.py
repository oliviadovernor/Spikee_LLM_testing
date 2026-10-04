#!/usr/bin/env python3
"""
Pre-flight check for a single model.
Usage: python3 scripts/preflight.py groq/openai/gpt-oss-120b

Exit 0 — model is reachable (PASS or non-quota error)
Exit 1 — quota exhausted (429), skip this model today
"""
import os
import sys

try:
    from dotenv import load_dotenv
    load_dotenv(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".env"))
except ImportError:
    pass

try:
    from openai import OpenAI
except ImportError:
    sys.exit(0)  # can't check, let spikee try

PROVIDERS = {
    "groq":    ("https://api.groq.com/openai/v1", "GROQ_API_KEY"),
    "mistral": ("https://api.mistral.ai/v1",      "MISTRAL_API_KEY"),
}

model_str = sys.argv[1] if len(sys.argv) > 1 else ""
parts = model_str.split("/", 1)
provider = parts[0]
model_id = parts[1] if len(parts) > 1 else parts[0]

if provider not in PROVIDERS:
    sys.exit(0)

base_url, key_env = PROVIDERS[provider]
api_key = os.getenv(key_env)
if not api_key:
    sys.exit(0)

try:
    client = OpenAI(api_key=api_key, base_url=base_url)
    client.chat.completions.create(
        model=model_id,
        messages=[{"role": "user", "content": "Hi"}],
        max_tokens=4,
        timeout=15,
    )
    sys.exit(0)
except Exception as e:
    sys.exit(1 if "429" in str(e) else 0)
