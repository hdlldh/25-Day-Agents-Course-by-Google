# Day 04: 基于源代码的部署

直接从源代码部署你的 Agent 到 Agent Engine —— 告别序列化的烦恼。

## 学习目标

- 将 ADK Agent 部署到 Vertex AI Agent Engine
- 使用 Agent Starter Pack 进行生产级部署
- 理解 source-based 与 cloudpickle 部署的区别
- 设置 CI/CD 流水线

## 前置条件

```bash
# 安装 UV 工具（如果还没装的话）
curl -LsSf https://astral.sh/uv/install.sh | sh

# 安装 Google Cloud CLI
# 参考: https://cloud.google.com/sdk/docs/install
```

## 序列化问题

传统的 Agent 部署使用 **cloudpickle** 序列化 Python 对象，经常会遇到问题：

| 问题 | 描述 |
|------|------|
| **版本不一致** | 开发和生产环境的 cloudpickle 版本不同 |
| **属性缺失** | `AttributeError: Can't get attribute '_class_setstate'` |
| **依赖冲突** | 复杂的依赖关系导致序列化失败 |
| **调试困难** | 序列化错误很难追踪定位 |

**基于源代码的部署** 直接部署你的源代码，而不是序列化后的对象，从根本上解决这些问题。

## 快速开始

### 方式一：新建项目

创建一个带 Agent Engine 部署配置的新项目：

```bash
uvx agent-starter-pack create my-agent -a adk_base -d agent_engine
cd my-agent
```

### 方式二：现有项目

为现有的 ADK Agent 添加部署能力：

```bash
# 进入包含你 agent 的父目录
cd /path/to/parent

# 添加部署配置
uvx agent-starter-pack enhance --adk -d agent_engine
```

## 项目结构

增强后的项目结构：

```
my-agent/
├── agent/
│   ├── __init__.py
│   ├── agent.py           # Agent 代码
│   └── root_agent.yaml    # Agent 配置
├── deployment/
│   ├── terraform/         # 基础设施即代码
│   └── cloudbuild.yaml    # CI/CD 流水线
├── Makefile               # 部署命令
├── pyproject.toml         # 依赖配置
└── README.md
```

## 部署到 Agent Engine

### 第一步：配置 Google Cloud

```bash
# 设置项目
export GOOGLE_CLOUD_PROJECT="your-project-id"
export GOOGLE_CLOUD_LOCATION="us-central1"
export STAGING_BUCKET="gs://your-staging-bucket"

# 认证
gcloud auth login
gcloud config set project $GOOGLE_CLOUD_PROJECT
```

### 第二步：使用 Make 部署

```bash
# 部署到 Agent Engine
make deploy
```

### 第三步：使用 ADK CLI 部署

也可以直接用 ADK 命令：

```bash
adk deploy agent_engine \
  --project $GOOGLE_CLOUD_PROJECT \
  --region $GOOGLE_CLOUD_LOCATION \
  --staging_bucket $STAGING_BUCKET \
  --trace_to_cloud \
  --display_name "my-agent" \
  --description "我的部署 Agent" \
  agent
```

## Agent Starter Pack 功能

Agent Starter Pack 提供：

| 功能 | 描述 |
|------|------|
| **CI/CD 流水线** | Cloud Build 或 GitHub Actions |
| **Terraform** | 基础设施即代码 |
| **OpenTelemetry** | 内置追踪和监控 |
| **会话管理** | 有状态对话 |
| **评估框架** | Agent 测试工具 |

## 支持的区域

Agent Engine 在以下区域可用：

- `us-central1` (爱荷华)
- `us-east1` (南卡罗来纳)
- `europe-west1` (比利时)
- `asia-northeast1` (东京)

## 示例：部署搜索 Agent

### 1. 创建 Agent

```yaml
# agent/root_agent.yaml
name: search_assistant
model: gemini-2.5-flash
description: 部署到 Agent Engine 的搜索助手
instruction: |
  你是一个有帮助的助手。
  使用 Google Search 获取时事和事实信息。
  总是引用你的信息来源。
tools:
  - name: google_search
```

### 2. 部署

```bash
adk deploy agent_engine \
  --project $GOOGLE_CLOUD_PROJECT \
  --region us-central1 \
  --staging_bucket $STAGING_BUCKET \
  --trace_to_cloud \
  agent
```

### 3. 测试

部署后，你可以通过以下方式与 Agent 交互：
- Google Cloud Console Agent Engine 界面
- REST API
- Python SDK

## Python SDK 使用

部署后，可以用代码调用你的 Agent：

```python
from google.cloud import aiplatform

# 初始化
aiplatform.init(
    project="your-project-id",
    location="us-central1"
)

# 获取已部署的 Agent
agent = aiplatform.Agent("projects/your-project/locations/us-central1/agents/your-agent-id")

# 创建会话
session = agent.create_session()

# 与 Agent 对话
response = session.chat("最近有什么 AI 新闻？")
print(response.text)
```

## 监控你的 Agent

### Cloud Console

在 [Agent Engine Console](https://console.cloud.google.com/vertex-ai/agent-engine) 查看：
- 监控对话
- 查看会话历史
- 追踪性能指标

### Cloud Trace

使用 `--trace_to_cloud` 参数可获得自动追踪：
- 请求延迟
- 工具执行时间
- 错误追踪

## 常见问题排查

### 常见错误

**1. Cloudpickle 版本不匹配**
```
AttributeError: Can't get attribute '_class_setstate'
```
解决方案：确保 `pyproject.toml` 中的 cloudpickle 版本一致

**2. 区域不支持**
```
InvalidArgument: Region not supported for Agent Engine
```
解决方案：使用支持的区域（us-central1, us-east1 等）

**3. 依赖缺失**
```
ModuleNotFoundError: No module named 'xxx'
```
解决方案：把所有依赖加到 `pyproject.toml`

### 先本地调试

部署前一定要先本地测试：

```bash
# 本地运行
adk web

# 测试你的 Agent
# 没问题了再部署
```

## Agent Engine vs Cloud Run

| 特性 | Agent Engine | Cloud Run |
|------|-------------|-----------|
| **会话管理** | 内置 | 需要自己实现 |
| **自动扩缩** | 自动 | 自动 |
| **自定义 UI** | 仅 REST API | 完全灵活 |
| **计费方式** | 按会话 | 按请求 |
| **A2A 协议** | REST API | 直接支持 |

选择 **Agent Engine** 如果：
- 想要快速部署
- 需要内置会话管理
- 需要生产监控

选择 **Cloud Run** 如果：
- 需要自定义 Web UI
- 需要 A2A 协议支持
- 需要更多基础设施控制

## 资源链接

### 官方文档
- [ADK 部署指南](https://google.github.io/adk-docs/deploy/)
- [Agent Engine 文档](https://google.github.io/adk-docs/deploy/agent-engine/)
- [Agent Starter Pack](https://github.com/GoogleCloudPlatform/agent-starter-pack)

### 教程
- [Source-Based Deployment 视频教程](https://youtu.be/8RjzMG3BKA0)
- [ADK + Agent Engine 多 Agent 应用 (Codelab)](https://codelabs.developers.google.com/multi-agent-app-with-adk)
- [部署多 Agent 系统 (Google Skills)](https://www.skills.google/course_templates/1275)

### 快速入门
- [快速入门：ADK + Agent Engine](https://cloud.google.com/agent-builder/agent-engine/quickstart-adk)
- [部署 Agent](https://cloud.google.com/vertex-ai/generative-ai/docs/agent-engine/deploy)

## 小结

Day 4 的核心是 **基于源代码的部署** —— 一种更干净的 Agent 部署方式，避免序列化带来的各种问题。Agent Starter Pack 让这个过程变得简单，提供了生产级的模板和 CI/CD 流水线。

关键命令：`uvx agent-starter-pack enhance --adk -d agent_engine` 可以为任何现有的 ADK 项目添加部署能力。
