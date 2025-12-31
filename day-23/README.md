# Day 23: 使用 Google ADK + Restate 构建持久化弹性 Agent

## 核心问题：大多数 Agent 都是脆弱的

```
传统 Agent 的致命问题：

┌─────────────────────────────────────────────────────────┐
│                   普通 Agent 执行流程                    │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  LLM调用 ──▶ 工具调用 ──▶ LLM调用 ──▶ 💥 崩溃!         │
│     ✓          ✓           ✓         (丢失所有状态)     │
│                                                         │
│  重启后: 必须从头开始，重复所有 LLM 调用（浪费成本！）    │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

**问题场景：**
- 网络波动导致进程崩溃 → 所有上下文丢失
- 需要等待人类审批（可能是几小时或几天）→ 无法保持状态
- 长时间运行的工作流 → 随时可能中断
- 多步骤任务 → 中间失败需要全部重来

---

## 解决方案：Durable Execution（持久化执行）

### Restate 是什么？

[Restate](https://restate.dev) 是一个开源的持久化执行平台，它让你的 Agent：

```
┌─────────────────────────────────────────────────────────┐
│                  Restate 持久化执行模式                   │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  LLM调用 ──▶ 工具调用 ──▶ LLM调用 ──▶ 💥 崩溃!         │
│     ✓          ✓           ✓                            │
│   [记录]      [记录]      [记录]                        │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │           Restate 持久化日志                      │   │
│  │  { step1: result1, step2: result2, step3: ... } │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  重启后: 从日志恢复状态，继续执行！（零浪费）            │
│         ───────────────────▶ 继续后续步骤              │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### 核心概念

| 概念 | 说明 | 类比 |
|------|------|------|
| **Durable Journal** | 持久化日志，记录每个步骤的结果 | 游戏存档点 |
| **Replay** | 恢复时重放日志而不是重新执行 | 读取存档而非重玩 |
| **Suspendable** | 可暂停/恢复的执行 | 按暂停键 |
| **Durable Promises** | 可跨重启的 Promise | 异步等待人类审批 |

---

## 架构：Google ADK + Restate

```
┌─────────────────────────────────────────────────────────────┐
│                     完整架构图                                │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   ┌──────────────┐         ┌──────────────────────────┐    │
│   │   Client     │ ──────▶ │    Restate Server        │    │
│   │   请求       │         │    (状态协调器)           │    │
│   └──────────────┘         └───────────┬──────────────┘    │
│                                        │                    │
│                                        ▼                    │
│   ┌─────────────────────────────────────────────────────┐  │
│   │                  Durable Agent                       │  │
│   │  ┌───────────────────────────────────────────────┐  │  │
│   │  │             Google ADK Agent                  │  │  │
│   │  │  ┌─────────┐  ┌─────────┐  ┌─────────┐       │  │  │
│   │  │  │  LLM    │  │  Tools  │  │  State  │       │  │  │
│   │  │  │  Calls  │  │  调用   │  │  管理   │       │  │  │
│   │  │  └────┬────┘  └────┬────┘  └────┬────┘       │  │  │
│   │  │       │            │            │             │  │  │
│   │  │       ▼            ▼            ▼             │  │  │
│   │  │  ┌─────────────────────────────────────────┐  │  │  │
│   │  │  │      Restate SDK (ctx.run / ctx.call)   │  │  │  │
│   │  │  │            自动持久化每个步骤             │  │  │  │
│   │  │  └─────────────────────────────────────────┘  │  │  │
│   │  └───────────────────────────────────────────────┘  │  │
│   └─────────────────────────────────────────────────────┘  │
│                                                             │
│   ┌──────────────────────────────────────────────────────┐ │
│   │  Restate UI (http://localhost:9070)                  │ │
│   │  实时查看执行轨迹、状态、错误                         │ │
│   └──────────────────────────────────────────────────────┘ │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 实战示例：保险理赔处理 Agent

### 场景描述

保险理赔是一个典型的长时间、多步骤工作流：

```
用户提交理赔 ──▶ AI分析 ──▶ 文档验证 ──▶ 人工审批 ──▶ 支付
    │              │           │          │(等待数天)    │
    ▼              ▼           ▼          ▼            ▼
  [需要持久化] [需要持久化] [需要持久化] [需要持久化] [需要持久化]
```

### 项目结构

```
restate-google-adk-example/
├── pyproject.toml          # 项目依赖
├── claims_agent/
│   ├── __init__.py
│   ├── agent.py            # Google ADK Agent 定义
│   ├── tools.py            # Agent 工具
│   └── durable.py          # Restate 持久化包装
└── restate_service.py      # Restate 服务入口
```

### 核心代码模式

#### 1. 定义 Google ADK Agent

```python
from google.adk import Agent, Tool

# 定义工具
@tool
def analyze_claim(claim_data: dict) -> dict:
    """使用 AI 分析理赔申请"""
    # LLM 分析逻辑
    return {"risk_score": 0.3, "recommendation": "approve"}

@tool
def verify_documents(doc_ids: list[str]) -> dict:
    """验证提交的文档"""
    return {"verified": True, "issues": []}

@tool
def process_payment(claim_id: str, amount: float) -> dict:
    """处理支付"""
    return {"transaction_id": "TXN123", "status": "completed"}

# 创建 Agent
claims_agent = Agent(
    name="ClaimsProcessor",
    model="gemini-2.0-flash",
    instruction="""你是一个保险理赔处理专家。
    分析用户的理赔申请，验证文档，并在获得审批后处理支付。""",
    tools=[analyze_claim, verify_documents, process_payment]
)
```

#### 2. 使用 Restate 包装实现持久化

```python
from restate import Service, Context
from restate.serde import JsonSerde

claims_service = Service("claims")

@claims_service.handler()
async def process_claim(ctx: Context, claim_data: dict) -> dict:
    """
    持久化的理赔处理工作流
    每个 ctx.run() 调用都会被记录到持久化日志
    """

    # Step 1: AI 分析 (持久化)
    analysis = await ctx.run(
        "analyze_claim",
        lambda: claims_agent.tools.analyze_claim(claim_data)
    )

    # Step 2: 文档验证 (持久化)
    verification = await ctx.run(
        "verify_documents",
        lambda: claims_agent.tools.verify_documents(claim_data["doc_ids"])
    )

    # Step 3: 等待人工审批 (持久化 Promise)
    # 这里可以暂停数天！进程可以终止，状态保持
    approval_promise = ctx.awakeable()
    await ctx.run(
        "notify_reviewer",
        lambda: send_approval_request(
            claim_id=claim_data["id"],
            callback_id=approval_promise.id
        )
    )

    # 暂停执行，等待外部触发
    approval = await approval_promise

    if not approval["approved"]:
        return {"status": "rejected", "reason": approval["reason"]}

    # Step 4: 处理支付 (持久化)
    payment = await ctx.run(
        "process_payment",
        lambda: claims_agent.tools.process_payment(
            claim_data["id"],
            claim_data["amount"]
        )
    )

    return {
        "status": "completed",
        "analysis": analysis,
        "verification": verification,
        "payment": payment
    }
```

#### 3. 外部触发审批回调

```python
# 当人工审批完成时，调用 Restate 唤醒等待的 Promise
import httpx

async def complete_approval(awakeable_id: str, approved: bool, reason: str = None):
    """人工审批完成后的回调"""
    async with httpx.AsyncClient() as client:
        await client.post(
            f"http://localhost:8080/restate/awakeables/{awakeable_id}/resolve",
            json={"approved": approved, "reason": reason}
        )
```

---

## 关键能力对比

| 能力 | 传统 Agent | Restate + ADK |
|------|------------|---------------|
| 崩溃恢复 | ❌ 从头开始 | ✅ 从断点继续 |
| 长时间等待 | ❌ 无法暂停 | ✅ 可暂停数天 |
| 重复执行 | ❌ 重复 LLM 调用 | ✅ 从日志读取 |
| 成本控制 | ❌ 失败=浪费 | ✅ 零重复成本 |
| 调试追踪 | ❌ 日志分散 | ✅ 统一执行轨迹 |
| 人工介入 | ❌ 复杂实现 | ✅ 原生支持 |

---

## 快速开始

### 1. 克隆示例仓库

```bash
git clone https://github.com/restatedev/restate-google-adk-example
cd restate-google-adk-example
```

### 2. 设置 API Key

```bash
export GOOGLE_API_KEY="your-key-here"
```

### 3. 启动 Agent（使用 uv）

```bash
# 安装依赖并启动 Agent
uv run .
```

### 4. 启动 Restate Server（使用 Docker）

```bash
# 在新终端中运行
docker run --name restate --rm \
  -p 8080:8080 \
  -p 9070:9070 \
  --add-host host.docker.internal:host-gateway \
  docker.restate.dev/restatedev/restate:latest
```

### 5. 打开 Restate UI

访问 http://localhost:9070 查看：
- 实时执行轨迹
- 每个步骤的状态
- 错误和重试记录
- 等待中的 Promise

---

## Restate SDK 核心 API

### `ctx.run()` - 持久化执行

```python
# 任何副作用都应该包装在 ctx.run 中
result = await ctx.run(
    "step_name",           # 步骤名称（用于日志）
    lambda: some_function() # 要执行的函数
)
# 如果崩溃后重启，会从日志读取 result 而不是重新执行
```

### `ctx.awakeable()` - 可等待的 Promise

```python
# 创建一个可被外部触发的 Promise
promise = ctx.awakeable()
print(f"等待外部触发: {promise.id}")

# 进程可以终止，Promise 状态保持
result = await promise  # 可能等待数天
```

### `ctx.sleep()` - 持久化休眠

```python
# 休眠 1 小时（进程可以终止，时间到了自动恢复）
await ctx.sleep(timedelta(hours=1))
```

### `ctx.call()` - 调用其他服务

```python
# 调用另一个持久化服务
result = await ctx.call(other_service.handler, {"data": "value"})
```

---

## 最佳实践

### 1. 幂等性设计

```python
# ✅ 好：使用确定性 ID
await ctx.run("create_order", lambda: create_order(
    order_id=f"{claim_id}-order",  # 确定性 ID
    amount=amount
))

# ❌ 避免：使用随机 ID
await ctx.run("create_order", lambda: create_order(
    order_id=uuid.uuid4(),  # 重放时会生成不同 ID
    amount=amount
))
```

### 2. 细粒度步骤划分

```python
# ✅ 好：细粒度步骤
analysis = await ctx.run("analyze", lambda: analyze(data))
enrichment = await ctx.run("enrich", lambda: enrich(analysis))
result = await ctx.run("decide", lambda: decide(enrichment))

# ❌ 避免：粗粒度步骤（浪费恢复机会）
result = await ctx.run("do_everything", lambda: (
    decide(enrich(analyze(data)))
))
```

### 3. 错误处理

```python
try:
    result = await ctx.run("risky_operation", lambda: risky_op())
except TerminalError as e:
    # 不重试的错误
    return {"status": "failed", "error": str(e)}
except Exception as e:
    # 会自动重试
    raise
```

---

## 官方示例代码解析

我们已经克隆了官方示例仓库到 `restate-google-adk-example/` 目录。让我们分析核心代码。

### 项目结构

```
restate-google-adk-example/
├── __main__.py      # 服务启动入口
├── agent.py         # Agent 定义和工具
├── pyproject.toml   # 依赖配置
└── doc/            # 文档和截图
```

### 核心代码分析：agent.py

```python
import restate
from google.adk import Runner
from google.adk.agents.llm_agent import Agent
from restate.ext.adk import RestatePlugin, RestateSessionService, restate_object_context

# =====================================================
# 工具定义：普通工具 + 人工审批工具
# =====================================================

async def check_eligibility(date: str, amount: float, category: str, reason: str) -> bool:
    """检查理赔资格 - 使用 ctx.run 持久化"""

    async def is_eligible() -> bool:
        # 实际实现：调用外部系统或数据库
        return True

    # 🔑 关键：使用 run_typed 持久化执行
    return await restate_object_context().run_typed("Check eligibility", is_eligible)


async def human_approval(date: str, amount: float, category: str, reason: str) -> str:
    """人工审批工具 - 使用 Awakeable 等待外部触发"""

    # 🔑 关键：创建 Awakeable（可等待的 Promise）
    approval_id, approval_promise = restate_object_context().awakeable(type_hint=str)

    # 通知审批人（持久化）
    def request_review():
        print(f"🔔 Review requested. Approve via:")
        print(f"   curl localhost:8080/restate/awakeables/{approval_id}/resolve --json 'true'")

    await restate_object_context().run_typed("Request review", request_review)

    # 🔑 关键：等待人工审批（可跨进程重启）
    return await approval_promise


# =====================================================
# Agent 定义
# =====================================================

agent = Agent(
    model="gemini-2.5-flash",
    name="claim_approval_agent",
    description="Insurance claim evaluation agent",
    instruction="""你是一个保险理赔评估 Agent。规则：
    - 金额 > 1000: 使用 human_approval 工具请求人工审批
    - 金额 < 1000: 使用 check_eligibility 检查后自行决定""",
    tools=[human_approval, check_eligibility],
)

# 🔑 关键：使用 RestatePlugin 集成持久化能力
app = App(name="agents", root_agent=agent, plugins=[RestatePlugin()])
runner = Runner(app=app, session_service=RestateSessionService())

# =====================================================
# Restate 服务定义
# =====================================================

agent_service = restate.VirtualObject("ClaimAgent")

@agent_service.handler()
async def run(ctx: restate.ObjectContext, message: ChatMessage) -> str | None:
    """处理用户消息 - 每个 key (customer_id) 有独立状态"""
    events = runner.run_async(
        user_id=ctx.key(),
        session_id=message.session_id,
        new_message=Content(role="user", parts=[Part.from_text(text=message.message)]),
    )

    final_response = None
    async for event in events:
        if event.is_final_response() and event.content:
            final_response = event.content.parts[0].text
    return final_response
```

### 关键集成点

| 组件 | 作用 | 代码 |
|------|------|------|
| `RestatePlugin` | 让 ADK Agent 具备持久化能力 | `plugins=[RestatePlugin()]` |
| `RestateSessionService` | 持久化会话状态 | `session_service=RestateSessionService()` |
| `restate_object_context()` | 获取当前执行上下文 | `ctx = restate_object_context()` |
| `ctx.run_typed()` | 持久化执行一个步骤 | `await ctx.run_typed(name, fn)` |
| `ctx.awakeable()` | 创建可等待的 Promise | `id, promise = ctx.awakeable()` |
| `VirtualObject` | 有状态的服务（按 key 隔离） | `restate.VirtualObject("ClaimAgent")` |

---

## 参考资源

- [Restate 官方文档](https://docs.restate.dev)
- [Restate AI Agent 指南](https://docs.restate.dev/ai)
- [Google ADK 文档](https://google.github.io/adk-docs/)
- [示例仓库](https://github.com/restatedev/restate-google-adk-example)
- [Restate GitHub](https://github.com/restatedev/restate)
- [Restate AI Serverless Agents 博客](https://www.restate.dev/blog/resilient-serverless-agents)

---

## 思考题

1. **为什么 LLM 调用需要持久化？**
   - 提示：考虑成本和确定性

2. **Awakeable 与传统的 Webhook 有什么区别？**
   - 提示：考虑状态管理和恢复能力

3. **在什么场景下持久化执行最有价值？**
   - 提示：长时间运行、多步骤、需要人工介入
