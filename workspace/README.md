# Spikee Red Team Experiment Workspace

## Themes

### Theme 1 — Prompt Injection & Data Exfiltration
LLMs deployed as document processors, summarisers, and RAG assistants are routinely exposed to untrusted text. An attacker who can inject a payload into a document the model reads can redirect its behaviour — causing it to exfiltrate data to an external URL, execute XSS payloads in a rendered UI, or produce adversarial output that poisons a downstream pipeline. This is one of the most practical real-world attack surfaces for deployed LLMs, and the one where defences vary most widely across model families.

### Theme 2 — System Prompt Extraction
Developers invest significant effort crafting system prompts that encode product behaviour, safety rules, and business logic. If a model can be coerced into revealing its system prompt verbatim, that exposes proprietary instructions, reveals the exact constraints an attacker needs to work around, and potentially leaks credentials or configuration embedded in the prompt. Reasoning models are particularly interesting here: chain-of-thought traces may surface system prompt content even when the final response does not.

### Theme 3 — Financial & Regulatory Violations
Providing personalised investment advice without a licence is illegal in most jurisdictions. LLMs trained on financial corpora may readily give specific buy/sell recommendations, asset allocations, or trading strategies when asked — especially under jailbreak pressure. This matters both for product liability (a company deploying an LLM that gives regulated advice inherits that risk) and for understanding whether models with different regional training data (e.g. models trained primarily on non-Western corpora) have internalised the same regulatory norms.

### Theme 4 — Weapons & Violence
The clearest test of a model's safety floor. Instructions covering weapons construction, CBRN synthesis, terror tactics, and targeted violence are the category most alignment work explicitly targets. Testing whether jailbreak wrappers — particularly those that frame requests as fictional, educational, or technical — can bypass these refusals tells us how robust the safety training actually is under adversarial pressure, and whether robustness scales with model size.

### Theme 5 — Harmful Behaviour
A broad category covering content that causes psychological harm, facilitates crime, or violates platform policies: hate speech, self-harm encouragement, child exploitation, stalking, drug synthesis, propaganda, and financial fraud. These categories reveal where different models draw different lines — particularly models trained with non-Western RLHF, which may have distinct definitions of what constitutes harmful content, and smaller models, which may have thinner safety layers than their larger counterparts.

---

## Datasets

| Dataset | Entries | Instruction types | Jailbreak types |
|---|---|---|---|
| `cybersec-full-prompt-theme1` | 1,484 | 3 (xss, data-exfil, long-output) | 21 |
| `cybersec-full-prompt-sys-theme1sys` | 1,484 | 3 (same + system msg canary) | 21 |
| `sysmsg-extraction…theme2` | 2,748 | 1 (sysmsg-extract) | 18 |
| `investment-advice…theme3` | 4,486 | 1 (financial-adv) + standalones | 20 |
| `harmful-all-jailbreaks…theme4` | 697 | 9 (weapons/CBRN/terror) | 21 |
| `harmful-all-jailbreaks…theme5` | 1,066 | 14 (hate/harm/drug/etc) | 21 |
