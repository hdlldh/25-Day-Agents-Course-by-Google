# Day 03: Gemini 3 + ADK

Build a powerful AI Agent using Gemini 3 and ADK with native support for Google Search grounding, computer use, and real-time streaming.

## Learning Goals

- Use Google Search tool for real-time information grounding
- Understand Gemini 3's native tool capabilities
- Build agents that can access current information
- Learn about search result display requirements

## Prerequisites

```bash
pip install google-adk
```

## Quick Start

### 1. Create Agent with Google Search

```yaml
# root_agent.yaml
name: search_agent
model: gemini-2.5-flash
description: An assistant with Google Search capability.
instruction: |
  You are a helpful assistant that can search the web.
  Use Google Search for current events and factual information.
tools:
  - name: google_search
```

### 2. Run Your Agent

```bash
cd day-03
adk web
```

## Google Search Tool

### Overview

The `google_search` tool enables agents to perform web searches using Google Search. This provides **grounding** - the ability to access real-time information beyond the model's training data.

### Key Features

| Feature | Description |
|---------|-------------|
| **Real-time data** | Access current news, prices, events |
| **Grounding** | Reduce hallucinations with factual sources |
| **Citations** | Responses include source URLs |
| **Gemini 2+ only** | Requires Gemini 2 or later models |

### Python Configuration

```python
from google.adk.agents import Agent
from google.adk.tools import google_search

agent = Agent(
    name="search_assistant",
    model="gemini-2.5-flash",
    instruction="You are a helpful assistant. Use Google Search when needed.",
    tools=[google_search]
)
```

### YAML Configuration

```yaml
name: search_assistant
model: gemini-2.5-flash
description: An assistant that can search the web.
instruction: |
  You are a helpful assistant.
  Use Google Search for current events and factual information.
tools:
  - name: google_search
```

## Important Limitations

### Tool Mixing Rules

1. **Built-in tools** (like `google_search`) only work with Gemini models
2. **Cannot mix** built-in tools with custom Python tools in the same agent
3. **One built-in tool** per agent (use sub-agents for multiple)

### Display Requirements

When using Google Search grounding in production:
- You must display search suggestions returned in the response
- The UI code (HTML) is in `renderedContent` field
- Follow Google's display policies

## Multi-Agent Pattern

For agents that need both Google Search and custom tools:

```yaml
# root_agent.yaml - Coordinator
name: coordinator
model: gemini-2.5-flash
description: Coordinates between search and tools.
instruction: |
  Use the search_agent for current information.
  Use the calculator_agent for calculations.

sub_agents:
  - name: search_agent
    model: gemini-2.5-flash
    description: Searches the web.
    instruction: Use Google Search to find information.
    tools:
      - name: google_search

  - name: calculator_agent
    model: gemini-2.5-flash
    description: Performs calculations.
    instruction: Help with math calculations.
    tools:
      - tools.calculate
```

## Example: News Agent

```yaml
name: news_agent
model: gemini-2.5-flash
description: A news assistant that provides current information.
instruction: |
  You are a news assistant.

  When users ask about:
  - Current events: Use Google Search
  - Weather: Use Google Search
  - Stock prices: Use Google Search
  - Sports scores: Use Google Search

  Always cite your sources and provide links when available.
  Present information in a clear, organized format.
tools:
  - name: google_search
```

## Resources

### Official Documentation
- [ADK Built-in Tools](https://google.github.io/adk-docs/tools/built-in-tools/)
- [Grounding with Google Search](https://ai.google.dev/gemini-api/docs/grounding)
- [ADK Python Repository](https://github.com/google/adk-python)

### Tutorials
- [Build an AI Agent with Gemini 3 (Video)](https://www.youtube.com/watch?v=9EGtawwvINs&list=PLOU2XLYxmsIJCVXV1bLV7qnT5hilN3YJ7&index=4&t=1s)
- [Gemini 3 Agent Demo (GitHub)](https://github.com/GoogleCloudPlatform/devrel-demos/tree/main/ai-ml/agent-labs/gemini-3-pro-agent-demo)
- [Google Codelabs: Empowering with Tools](https://codelabs.developers.google.com/devsite/codelabs/build-agents-with-adk-empowering-with-tools)

### Announcements
- [Gemini 3 Announcement](https://blog.google/products/gemini-3/#gemini-3)
- [Agent Development Kit Blog](https://developers.googleblog.com/en/agent-development-kit-easy-to-build-multi-agent-applications/)

## Notes

Day 3 introduces the Google Search tool, enabling your agents to access real-time information. This is essential for building agents that can answer questions about current events, prices, weather, and other time-sensitive data.
