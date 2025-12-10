"""Configuration utilities for the course."""

import os
from pathlib import Path

from dotenv import load_dotenv


def load_config() -> None:
    """Load environment variables from .env file."""
    env_path = Path(__file__).parent.parent / ".env"
    load_dotenv(env_path)


def get_api_key(key_name: str = "GOOGLE_API_KEY") -> str:
    """Get API key from environment variables.

    Args:
        key_name: Name of the environment variable containing the API key.

    Returns:
        The API key string.

    Raises:
        ValueError: If the API key is not found.
    """
    load_config()
    api_key = os.getenv(key_name)
    if not api_key:
        raise ValueError(
            f"{key_name} not found. Please set it in .env file or environment variables."
        )
    return api_key
