"""Day 01: Getting Started with Google AI Agents.

This is the first day of the 25-Day AI Agents Course.
"""

import sys
from pathlib import Path

# Add project root to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

from google import genai

from shared import get_api_key


def main():
    """Main entry point for Day 01."""
    api_key = get_api_key()
    client = genai.Client(api_key=api_key)

    # Example: Simple chat with Gemini
    response = client.models.generate_content(
        model="gemini-2.0-flash",
        contents="Hello! I'm starting the 25-Day AI Agents Course. What will I learn?",
    )
    print(response.text)


if __name__ == "__main__":
    main()
