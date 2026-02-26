# E1 练习：Design Twitter Feed — Requirement Gathering

## 目标

在 5 分钟内完成需求澄清（Requirement Gathering），并给出可落地的功能边界，为后续 High-Level Diagram 和 Deep Dive 做决策输入。

---

## Clarifying Questions（5 个）

| 问题 | 为什么要问（会影响什么设计） |
|---|---|
| 1. 预期 DAU/峰值 QPS（每秒请求数）大概是多少？ | 影响限流（Rate Limiting，限流）、重试（Retry，重试）和 Exponential Backoff（指数退避）策略 |
| 2. 用户网络环境是否以弱网/高延迟地区为主？ | 影响缓存（Cache，缓存）激进程度、资源体积控制、失败兜底策略 |
| 3. Feed 只支持文字，还是要支持图片/视频？ | 影响媒体链路：Image Loading（图片加载）、CDN、预取（Prefetching，预加载）和存储成本 |
| 4. 时间线更新方式是 Pull（客户端拉取）还是 Push（服务端推送）？ | 影响通道选择：HTTP 轮询、SSE（服务器发送事件）或 WebSocket（双向长连接） |
| 5. 数据一致性要求多高？可否接受短暂旧数据？ | 影响 Cache-Aside（旁路缓存）/SWR（先返回旧数据并后台刷新）/Optimistic Update（乐观更新）选择 |

面试口述模板（30 秒）：

> 我先确认 5 件事：规模、网络环境、媒体类型、更新机制和一致性目标。因为这 5 个问题会直接决定缓存策略、分页方式、实时通道和失败重试策略。

---

## Functional Requirements（3 个）

1. 用户可以无限滚动浏览 Home Timeline（首页时间线），支持分页（Pagination，分页）。
2. 用户可以对推文点赞/取消点赞（Like/Unlike）。
3. 用户可以查看评论列表（只读即可，写评论可后续扩展）。

---

## Non-Functional Requirements（3 个）

1. 在弱网下仍可快速首屏展示，优先返回本地缓存（Cache，缓存）再后台刷新。
2. 用户离线时可查看已浏览内容（Offline Read，离线可读）。
3. 控制资源消耗：降低带宽、CPU、内存和电量开销（Resource Optimization，资源优化）。

---

## Out of Scope（本轮不做）

- 登录与账号体系
- 关注关系管理
- 发推/删推完整写路径
- 转发（Retweet）与复杂通知系统

---

## Coach Feedback（润色后汇总）

### 做得好的点

- 已从“代码实现细节”转向“系统决策输入”。
- Functional Requirements 聚焦读取链路，符合 45 分钟面试时间分配。
- 能把一致性与更新频率转化为具体技术选择（例如 SWR、Optimistic Update）。

### 还要持续强化的点

- 每个问题都要跟一个 trade-off（取舍）绑定，避免“只提问题不落地”。
- 回答尽量使用“场景 + 选择 + 不选原因”的三段式。

三段式模板：

> 场景是 __。我选择 __，因为 __。不选 __，因为它在这个场景下会带来 __ 成本。

---

## 学习 Q&A

### Q1: 什么是 Data Sharding（数据分片）？这题要讲吗？

Data Sharding（数据分片）是把大表按规则拆到多台数据库（例如按 `user_id % N`）。

在 Mobile System Design 面试里，一般不需要深挖分片细节。你只需说明：

> 这是后端存储层决策。客户端只关心 API 契约稳定、分页有序和失败可恢复。

如果被追问，可补一句：

> 若后端分片导致返回顺序波动，客户端需按游标（Cursor，游标）或时间戳做稳定排序。

---

### Q2: 什么是 QPS（每秒请求数）？iOS 工程师需要会算吗？

不要求你精算，但要会把 QPS 压力映射到客户端行为：

| 服务端信号 | 客户端动作 |
|---|---|
| `429 Too Many Requests` | 启用 Exponential Backoff（指数退避）和重试上限 |
| 峰值流量上升 | 减少重复请求，提升缓存命中率 |
| 接口抖动 | 做降级（Degrade，降级）与 stale-if-error（失败时用旧数据） |

Alamofire（网络库）可用 `RequestInterceptor`（请求拦截器）+ `RetryPolicy`（重试策略）统一管理重试与退避。

---

### Q3: SQL vs NoSQL 和 SQLite / Core Data / Realm 的关系？

| iOS 技术 | 类型 | 说明 |
|---|---|---|
| SQLite | SQL（关系型） | 结构化查询强，适合复杂过滤/关联 |
| Core Data | ORM（对象关系映射）+ 常见 SQLite 存储后端 | 用对象模型管理数据，底层通常仍是 SQLite |
| Realm | Object Store（对象存储） | 建模直观，移动端使用成本低 |
| UserDefaults | Key-Value（键值存储） | 仅适合少量配置，不适合 Feed 主数据 |

面试里建议说法：

> 客户端本地以 Core Data/Realm 做 SSOT（Single Source of Truth，单一数据真源）；服务端 DB 选型不是客户端主责，按 API 契约协作即可。

---

### Q4: 什么是 Cache TTL（缓存生存时间）？

TTL（Time To Live，生存时间）是缓存可直接使用的有效时长。

- TTL 长：命中率高、省流量省电，但可能看到旧数据。
- TTL 短：数据更“新鲜”，但网络请求更多。

Kingfisher（图片库）示例：头像可用更长 TTL，活动 Banner 用短 TTL。
HTTP 层对应 `Cache-Control: max-age=...`。

---

### Q5: 为什么要问“更新频率”和“一致性要求”？

这两个问题分别决定两条主轴：

1. 更新频率高低 → Pull/Push 选择 + TTL 策略
2. 一致性要求高低 → Optimistic/Pessimistic（悲观更新）选择

典型判断：

- Feed 点赞：可接受短暂不一致，适合 Optimistic Update（乐观更新）。
- 支付余额：强一致要求高，必须服务端确认后再更新 UI。

---

### Q6: SSE vs WebSocket 怎么选？

| 维度 | SSE（服务器发送事件） | WebSocket（双向长连接） |
|---|---|---|
| 通信方向 | 单向（Server → Client） | 双向（Server ↔ Client） |
| 复杂度 | 低 | 高 |
| 典型场景 | Feed 更新通知、行情推送 | 聊天、协作编辑、实时对战 |

Twitter Feed 场景通常优先“通知式推送 + 客户端拉取详情”，而不是把所有动态都做成高频双向通道。

---

### Q7: 什么是 Repository Pattern（仓储模式）和 Coordinator Pattern（协调器模式）？

- Repository Pattern（仓储模式）：统一封装远端 API 和本地存储，ViewModel 不关心数据来源。
- Coordinator Pattern（协调器模式）：把页面跳转从 ViewController/View 抽离，降低耦合。

简化示意：

- ViewModel → Repository（拿数据）
- View/VC → Coordinator（做导航）

面试表达重点：

> Repository 负责“数据路径解耦”，Coordinator 负责“导航路径解耦”。二者关注点不同，但都服务于可维护性与可测试性。

---

## 这份 E1 的完成标准（Checklist）

- [x] 能在 5 分钟内提出 5 个高价值澄清问题
- [x] 能区分 Functional / Non-Functional / Out of Scope
- [x] 每个关键选择都能说出 trade-off（取舍）
- [x] 口述时不陷入 UI 组件或代码细节

下一步：进入 E2，基于本页结论画 High-Level Diagram。
