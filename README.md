# 25-Day AI Agents Course by Google

A hands-on learning journey through Google's AI Agents capabilities.

## Setup

### Prerequisites

- Python 3.11+
- [uv](https://github.com/astral-sh/uv) package manager

### Installation

```bash
# Install dependencies
uv sync

# Create .env file and add your API key
cp .env.example .env
# Edit .env and add your GOOGLE_API_KEY
```

## Project Structure

```
.
├── day-01/                 # Day 1: Introduction
├── day-02/                 # Day 2: ...
├── ...
├── shared/                 # Shared utilities
│   ├── __init__.py
│   └── config.py          # Configuration helpers
├── pyproject.toml         # Project dependencies
└── README.md
```

## Daily Progress

| Day | Topic | Status |
|-----|-------|--------|
| 01 | Introduction to AI Agents | 🚧 In Progress |
| 02 | TBD | ⏳ Pending |
| ... | ... | ... |

## Running Daily Exercises

```bash
# Run day 1 exercises
uv run python day-01/main.py

# Run with dev dependencies (for testing)
uv sync --dev
uv run pytest
```

## Resources

- [Google AI Studio](https://aistudio.google.com/)
- [Gemini API Documentation](https://ai.google.dev/docs)
