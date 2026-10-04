import os

from spikee.providers.custom import AnyLLMCustomProvider


class AnyLLMMistralProvider(AnyLLMCustomProvider):
    """AnyLLM provider for Mistral models (via OpenAI-compatible API).

    Requires MISTRAL_API_KEY in .env.
    Codestral uses the same key but a separate endpoint — set CODESTRAL_API_KEY
    and use the 'mistral-codestral' provider alias defined in run_experiments.sh,
    or override via MISTRAL_API_URL if you want to point at a different base.
    """

    @property
    def default_model(self) -> str:
        return "mistral-small-latest"

    @property
    def models(self) -> dict[str, str]:
        return {
            # Ministral — compact edge models
            "ministral-3b-latest": "ministral-3b-latest",
            "ministral-8b-latest": "ministral-8b-latest",
            "ministral-14b-latest": "ministral-14b-latest",
            # Mistral Small / Medium
            "mistral-small-latest": "mistral-small-latest",
            "mistral-medium-latest": "mistral-medium-latest",
            "mistral-medium-3.5": "mistral-medium-3.5",
            # Magistral — reasoning model
            "magistral-small-latest": "magistral-small-latest",
            # Code-specialised
            "codestral-latest": "codestral-latest",
            # Open-weight legacy
            "open-mistral-nemo": "open-mistral-nemo",
            "open-mistral-7b": "open-mistral-7b",
            "open-mixtral-8x7b": "open-mixtral-8x7b",
            "open-mixtral-8x22b": "open-mixtral-8x22b",
        }

    @property
    def name(self) -> str:
        return "Mistral"

    @property
    def base_url(self) -> str:
        return os.getenv("MISTRAL_API_URL", "https://api.mistral.ai/v1")

    @property
    def api_key(self) -> str | None:
        return os.getenv("MISTRAL_API_KEY", None)
