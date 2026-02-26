# 补充：HTTP 轮询与 SSE（基于 RFC）

## 学习目标

这份文档帮助你在 Mobile System Design 面试里讲清：

1. `Short Polling（短轮询）`、`Long Polling（长轮询）`、`SSE（Server-Sent Events，服务器推送事件）` 的区别
2. 每种方案在 HTTP 协议层的依据（RFC 条款）
3. iOS 端如何落地（`URLSession` / `Alamofire`）
4. 如何说出关键 trade-off，而不是只背名词

## 先有全局图（BFS）

| 方案 | 连接模型 | 延迟 | 服务器压力 | 客户端复杂度 | 典型场景 |
|---|---|---|---|---|---|
| Short Polling | 周期性请求-响应 | 中到高 | 高（请求频繁） | 低 | 低实时性状态刷新 |
| Long Polling | 请求挂起直到有事件/超时 | 中 | 中 | 中 | 聊天列表、通知角标 |
| SSE | 单向长连接流式下发 | 低 | 中 | 中 | 实时通知流、价格流 |

一句话：
- 数据更新不频繁，用 `Short Polling`。
- 需要“近实时”但不想上 WebSocket，用 `Long Polling`。
- 只需要 server -> client 推送，用 `SSE`。

## RFC 依据与可直接复述的结论

### 1) Short Polling vs Long Polling 的定义

- `RFC 6202 Section 2.1` 明确区分：
  - `short polling`：客户端固定频率拉取，没数据就空响应。
  - `long polling`：服务端先“hold open”请求，直到事件/状态/超时再返回。
- 这就是你在面试里说的“请求生命周期差异”。

### 2) Long Polling 的问题与边界

- `RFC 6202 Section 2.2` 指出：
  - 每次都是完整 HTTP 报文，`header overhead` 明显。
  - 仍有最大延迟（响应结束到下一次请求发出之间存在空窗）。
  - 服务端要长期占用连接与请求资源。
- 面试信号：你不是只会讲“长轮询更实时”，还会讲成本。

### 3) SSE 与 `text/event-stream`

- `RFC 6202 Section 4.3`：SSE 基于 HTTP streaming，数据编码为 `text/event-stream`。
- `RFC 8895` 给了非常具体的 SSE 交互样例（`Accept: text/event-stream` 与响应 `Content-Type: text/event-stream`）。
- 结论：SSE 是“协议上仍是 HTTP”，但语义是持续事件流。

### 4) 重试与过载控制

- `RFC 9110 Section 15.6.4`：`503 Service Unavailable` 表示临时不可用。
- `RFC 9110 Section 10.2.3`：可配 `Retry-After` 告诉客户端多久后再试。
- 这正好对应移动端的 backoff 策略。

### 5) 缓存控制（轮询/SSE 常见坑）

- `RFC 6202 Section 5.6` 建议长轮询请求/响应通常显式抑制缓存（`Cache-Control: no-cache`）。
- `RFC 9111 Section 5.2` 定义了 `Cache-Control` 指令语义；常用边界：
  - `no-cache`：可存但使用前需重验证。
  - `no-store`：不允许存储。
- 对“实时通道”通常至少要避免中间层缓存旧事件。

## 三段 HTTP 报文示例（面试可直接写）

### A. Short Polling

```http
GET /v1/notifications?since=1700000000 HTTP/1.1
Host: api.example.com
Authorization: Bearer <token>

HTTP/1.1 200 OK
Content-Type: application/json
Cache-Control: no-cache

{"items": []}
```

### B. Long Polling

```http
GET /v1/notifications/long-poll?cursor=abc HTTP/1.1
Host: api.example.com
Authorization: Bearer <token>
Cache-Control: no-cache

HTTP/1.1 200 OK
Content-Type: application/json

{"items":[{"id":"n_101","type":"mention"}],"nextCursor":"def"}
```

若服务端过载：

```http
HTTP/1.1 503 Service Unavailable
Retry-After: 15
```

### C. SSE

```http
GET /v1/notifications/stream HTTP/1.1
Host: api.example.com
Accept: text/event-stream
Cache-Control: no-cache

HTTP/1.1 200 OK
Content-Type: text/event-stream
Connection: keep-alive

id: 101
event: notification
data: {"type":"mention","tweetId":"t_1"}

```

## iOS 落地（URLSession / Alamofire）

### 1) Short Polling（定时拉取）

- 用 `Timer` 或 `async` loop 周期请求。
- 网络失败按指数退避（`exponential backoff`），并尊重 `Retry-After`。
- 适合低频状态（例如每 30~60 秒刷新一次非关键角标）。

### 2) Long Polling（请求挂起 + 立即续接）

- 单个请求超时建议高于普通 API（例如 30~120 秒，按网关能力调优）。
- 收到响应后立刻发起下一次请求，保持“几乎持续监听”。
- `Alamofire` 可用 `RequestInterceptor/RetryPolicy` 统一重试与退避策略。

### 3) SSE（流式解析）

- iOS 15+ 可用 `URLSession.bytes(for:)` 按字节流解析 `event/id/data` 行。
- 维护 `lastEventId`，断线重连时带上（通常通过 `Last-Event-ID`）。
- 服务器要发 heartbeat（注释行或轻量事件）减少中间层 idle timeout 断连。

## 常见追问与回答模板

### Q1: 为什么不用 Short Polling？

可答：
- 低实时要求时它最简单。
- 但请求频率一高，`header overhead` 和电量/流量成本会上升（`RFC 6202 Section 2.2`）。
- 所以中高实时场景更偏向 Long Polling 或 SSE。

### Q2: SSE 和 Long Polling 怎么选？

可答：
- 都基于 HTTP、对企业网络更友好。
- `SSE` 延迟更低、事件语义更自然，但需要流式解析与断线重连管理。
- `Long Polling` 实现更通用，服务端也更容易和现有 REST 栈融合。

### Q3: 什么时候该上 WebSocket？

可答：
- 当你需要高频双向通信（client <-> server）时。
- 若只是 server -> client 通知流，先用 SSE/Long Polling 往往更低成本。

## 30 秒面试口述版

我会先按实时性分层：低频刷新用 Short Polling，高一点用 Long Polling，只需单向推送就用 SSE。`RFC 6202` 定义了 short/long polling 及其开销，`RFC 6202` 和 `RFC 8895` 能支撑 SSE 的 `text/event-stream` 语义。过载时用 `503 + Retry-After`（`RFC 9110`）指导客户端退避，缓存层按 `Cache-Control`（`RFC 9111`）避免旧数据污染实时通道。iOS 端我会用 `URLSession` 或 `Alamofire` 做统一重试、超时和断线恢复。

## RFC 链接（原文）

- RFC 6202: [Known Issues and Best Practices for the Use of Long Polling and Streaming in Bidirectional HTTP](https://www.rfc-editor.org/rfc/rfc6202)
- RFC 8895: [Application-Layer Traffic Optimization (ALTO) Incremental Updates Using Server-Sent Events (SSE)](https://www.rfc-editor.org/rfc/rfc8895)
- RFC 9110: [HTTP Semantics](https://www.rfc-editor.org/rfc/rfc9110)
- RFC 9111: [HTTP Caching](https://www.rfc-editor.org/rfc/rfc9111)
