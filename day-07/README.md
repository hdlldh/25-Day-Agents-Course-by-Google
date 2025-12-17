# Day 7: LLM 可以执行代码 - 自主问题解决

> 探索 LLM 如何不仅能编写代码，还能自主执行、调试和优化代码，将其转变为强大的问题解决者。

## 今日要点

Day 7 讲的是 **Code Execution（代码执行）** 功能 - 让 AI Agent 能够在安全的沙箱环境中运行代码，从而实现自主问题解决。

## 什么是 Code Execution？

传统 LLM 只能**生成**代码，但不能**运行**代码。Code Execution 改变了这一点：

```
┌─────────────────────────────────────────────────────────────────────────┐
│                     没有 Code Execution                                  │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   用户: "计算 2024 年 1 月 1 日到今天有多少天？"                          │
│                                                                          │
│   AI: "让我算一下... 大约是 350 天左右"  ← 可能算错！                     │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                      有 Code Execution                                   │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   用户: "计算 2024 年 1 月 1 日到今天有多少天？"                          │
│                                                                          │
│   AI: [自动生成并执行 Python 代码]                                        │
│       ```python                                                          │
│       from datetime import date                                          │
│       days = (date.today() - date(2024, 1, 1)).days                     │
│       print(f"已经过了 {days} 天")                                       │
│       ```                                                                │
│       输出: "已经过了 351 天"  ← 精确计算！                               │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

## 核心优势

| 优势 | 说明 |
|------|------|
| **精确计算** | 数学运算由代码执行，避免 LLM 的计算错误 |
| **数据处理** | 可以处理 CSV、JSON 等数据文件 |
| **动态验证** | 生成代码后立即验证是否正确 |
| **迭代调试** | 如果出错，可以自动修复并重试 |

## 运行

```bash
# 打开 Jupyter notebook 学习
jupyter notebook day-07/code_execution.ipynb
```

## 资源

- [Code Execution on Vertex AI Agent Engine](https://cloud.google.com/vertex-ai/docs/agent-engine/code-execution)
- [Tutorial: Get Started with Code Execution](https://github.com/GoogleCloudPlatform/generative-ai/blob/main/agents/agent_engine/tutorial_get_started_with_code_execution.ipynb)
- [Retail AI Location Strategy (Case Study)](https://github.com/google/adk-samples/tree/main/python/agents/retail-ai-location-strategy)
- [视频](https://www.youtube.com/watch?v=QH9jK_RkbHc)
