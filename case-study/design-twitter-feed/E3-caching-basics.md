# E3 练习：Caching 基础 — 设计多层缓存策略

## 练习目标

在 10-15 分钟内，针对「Design Twitter Feed」讲清楚缓存分层、缓存策略与 HTTP Cache 的设计，并能解释关键 Trade-off（权衡取舍）。

---
---

# 📝 Coach 教学

## 🎯 E3 的核心：Cache（缓存）不是只为“快”，而是为了“稳定体验”

很多 iOS 工程师谈缓存只会说“加速”。

**面试官真正要听的是：**

1. **离线可用**：网络差时还能看内容
2. **成本控制**：少打 API、少耗流量
3. **电量优化**：降低 `radio wakeups`（蜂窝/`Wi-Fi` 通信模块唤醒次数）
4. **一致性策略**：何时允许旧数据，何时必须最新

## Cache 三层思维（Mobile 版本）

```text
UI
  ↓
Repository（仓储层）
  ↓
L1 Memory Cache (NSCache)
  ↓ miss（未命中）
L2 Disk Cache (File/CoreData/Realm)
  ↓ miss（未命中） or expired（过期）
Network (API + HTTP Cache/ETag)
```

## 每层该放什么（iOS 对照）

| 层级 | 速度 | 持久性 | 放什么 | iOS 对应 |
|---|---|---|---|---|
| **L1 Memory Cache** | 最快 | App 被 kill 后消失 | 热数据、当前画面常用图片 | `NSCache`、Kingfisher memory storage |
| **L2 Disk Cache** | 中等 | 可跨重启 | JSON、图片、列表快照 | `FileManager`、CoreData、Realm、Kingfisher disk storage |
| **HTTP Cache** | 由协议控制 | 视 header | 可重验证的 API 响应 | `URLCache` + `Cache-Control`/`ETag` |

## 两个面试最高频策略

### 1) Cache-Aside（旁路缓存）

流程：
1. 先查 cache
2. hit（命中）直接返回
3. miss（未命中）打 API，写回 cache，再返回 UI

**适合**：一致性要求中等、逻辑清晰的一般数据加载。

### 2) Stale-While-Revalidate（先返回旧数据并后台刷新）

说明：`SWR` 是 `Stale-While-Revalidate` 的缩写。

流程：
1. 先返回旧数据（UI 秒开）
2. 后台打 API 拉新数据
3. 有新数据再刷新 UI

**适合**：Feed、Profile、内容流。  
**不适合**：支付、余额、库存等强一致场景。

## HTTP 协议内容已拆分（请配套阅读）

为了让这份 E3 主文档聚焦“缓存分层与策略决策”，HTTP 协议细节（`Cache-Control`、`ETag`、`304`、`Range Request`、`URLCache` 安全策略）已移动到：  
[E3-http-caching-protocol.md](/Users/sunset/Documents/Projects/mobile-system-design/case-study/design-twitter-feed/E3-http-caching-protocol.md)

## iOS 实战口条（用你熟悉的库）

- **Kingfisher**：Memory/Disk 两层缓存 + processor key（处理器键），对图片尺寸与解码成本友好。
- **Alamofire**：可结合 `URLSessionConfiguration.urlCache`；必要时用 interceptor（拦截器）控制重试与 revalidate（重新验证）。
- **Repository**：负责协调数据来源与策略，不直接耦合 UI 组件。

## 关键 Trade-off（权衡取舍，面试加分）

| 决策 | 好处 | 代价 |
|---|---|---|
| Memory cache 大 | 命中率高、滑动顺 | OOM 风险上升 |
| Disk cache 大 | 离线更完整 | I/O 变慢、清理更复杂 |
| Stale-While-Revalidate（SWR） | 体感快、低等待 | 短暂显示旧数据 |
| 强制每次拉新 | 一致性高 | 延迟高、耗流量耗电 |

## ⚠️ 常见错误

- ❌ 只说“快”，没提离线/成本/电量
- ❌ 把所有数据都塞进 Memory（忽略 OOM）
- ❌ 没有 invalidation（失效）规则（登出、下拉刷新、版本升级）
- ❌ 不了解 `304 Not Modified` 的意义
- ❌ 在强一致场景也套用 Stale-While-Revalidate（SWR）

## ❓ E3 Q&A

### Q1: 既然有 ETag，还需要 App 端 Disk Cache 吗？

需要。ETag 只能帮你“省下载量”，但每次仍可能要发请求等待 RTT。  
Disk Cache 能在离线或弱网时立即响应，两者是互补关系，不是替代关系。

### Q2: 登出时要清哪些 cache？

- 必清：与用户身份绑定的数据（个人资料、私信、token 关联缓存）
- 可保留：公开、匿名可见且不敏感的资源（例如通用图片）
- 原则：安全优先，其次再谈命中率

### Q3: 为什么 Feed 常用 Stale-While-Revalidate（SWR）？

因为 Feed 对“立刻可看”的要求通常高于“毫秒级最新”。  
先返回缓存再后台刷新，能把首屏等待降到最低。

### Q4: L1 Memory Cache 需要考虑过期时间吗？

需要，必须考虑。以 Kingfisher 为例：

- `MemoryStorage` 的每个对象都带过期时间，默认是 `StorageExpiration.seconds(300)`（约 5 分钟）。
- 读取时会先判断 `isExpired`，过期就当作不存在（等价于 miss）。
- 命中后默认会执行 `extendExpiration(.cacheTime)`，把热点数据继续保活。
- 另外还有定时清理（默认 `cleanInterval = 120` 秒）和系统内存告警清理（`didReceiveMemoryWarning` -> `clearMemoryCache`）。

结论：L1 不是“只看命中不看时效”，而是“命中 + 未过期”才算有效命中。

源码参考（Kingfisher）：

- `Reference/Kingfisher-master/Sources/Cache/MemoryStorage.swift:47-52`  
  说明内存缓存项都有过期时间，并有定时清理过期项。
- `Reference/Kingfisher-master/Sources/Cache/MemoryStorage.swift:164-172`  
  读取时检查 `isExpired`，过期返回 `nil`；命中后可延长过期时间。
- `Reference/Kingfisher-master/Sources/Cache/MemoryStorage.swift:224-225`  
  默认内存缓存过期时间是 `.seconds(300)`（5 分钟）。
- `Reference/Kingfisher-master/Sources/Cache/MemoryStorage.swift:296-303`  
  `extendExpiration` 机制：命中后延长过期时间（续期）。
- `Reference/Kingfisher-master/Sources/Cache/ImageCache.swift:204-207`  
  iOS 下监听 `didReceiveMemoryWarning`，触发 `clearMemoryCache`。

### Q5: L2 Disk Cache 需要考虑过期时间吗？

需要，同样必须考虑。以 Kingfisher 为例：

- Disk 写入时会记录过期信息，不会把“已过期策略”的对象写入磁盘。
- 读取时会先判断文件是否过期，过期直接返回 `nil`（等价于 miss）。
- 命中后会根据策略更新过期时间（延长有效期）。
- Disk 还会执行过期清理与容量清理（LRU），两者共同控制磁盘占用与数据新鲜度。

结论：L2 不是“持久化就永不过期”，而是“持久化 + 过期控制 + 淘汰策略”。

源码参考（Kingfisher）：

- `Reference/Kingfisher-master/Sources/Cache/DiskStorage.swift:160-163`  
  写入时应用 `expiration`，已过期策略不会入盘。
- `Reference/Kingfisher-master/Sources/Cache/DiskStorage.swift:273-275`  
  读取时判断 `meta.expired`，过期直接 miss。
- `Reference/Kingfisher-master/Sources/Cache/DiskStorage.swift:282-283`  
  命中后调用 `extendExpiration` 执行续期。
- `Reference/Kingfisher-master/Sources/Cache/DiskStorage.swift:513-514`  
  默认磁盘过期时间为 `.days(7)`。
- `Reference/Kingfisher-master/Sources/Cache/DiskStorage.swift:414-441`  
  提供 `removeExpiredValues` 清理过期文件。
- `Reference/Kingfisher-master/Sources/Cache/DiskStorage.swift:447-480`  
  超出容量时按 LRU 进行淘汰清理。

### Q6: Cache-Aside（旁路缓存）是不是一般用于数据一致性要求中等的场景？

是的，通常如此。

- `Cache-Aside（旁路缓存）` 适合一致性要求中等的场景：允许短时间旧数据，重点是降低延迟与减少后端压力。
- 对于高一致场景（如余额、支付、库存），默认应采用 `Network-First（网络优先）`，UI 展示 loading/skeleton 后请求网络。
- 回写缓存（write cache back）指的是：网络成功返回最新数据后，再把该结果写回缓存；缓存是副本，不是权威数据源。
- 在高一致场景中，`Cache-Aside` 更适合作为回写缓存或失败兜底（`stale-if-error`），而不是默认读路径。
- 这不矛盾：  
  正常路径是 `Network-First`（先网络，保证一致性）；  
  异常路径（超时/断网）才短暂展示旧数据，属于降级兜底，不是主策略。
- 强事务动作（支付确认、扣款、库存确认）通常不应展示旧数据，失败应明确报错并要求重试。

### Q7: 什么是“数据一致性（Data Consistency，一致性）”？

数据一致性指的是：同一份业务数据，在不同副本、不同时间、不同端读取时，是否满足你定义的“正确性规则”。

可以用 3 个判断问题快速定义一致性要求：

- 我现在读到的是不是最新值？
- 不同页面/设备看到的值会不会互相矛盾？
- 写入顺序会不会被打乱（比如后写被前写覆盖）？

常见一致性等级：

- `Strong Consistency（强一致）`：读取必须是最新提交值。  
  典型场景：余额、支付状态、库存确认。
- `Eventual Consistency（最终一致）`：短时间可能是旧值，但最终会收敛。  
  典型场景：Feed、点赞数、评论数。
- `Session Consistency（会话一致）`：至少保证“我刚写入的数据，我自己马上能读到”（Read-your-writes）。  
  常用于提升用户体感正确性。

与缓存策略的映射：

- 高一致：默认 `Network-First（网络优先）`。
- 中等一致：常用 `Cache-Aside（旁路缓存）`。
- 低一致/内容流：常用 `Stale-While-Revalidate（SWR）`。

一句话记忆：一致性不是“要不要缓存”，而是“允许多旧、允许多久、错误代价多大”。

### Q8: Session Consistency（会话一致）在这道系统设计题中有体现的地方吗？

有，且在 `Design Twitter Feed` 里很常见。  
`Session Consistency（会话一致）` 关注的是：我自己刚写入的数据，我自己要立刻读到（Read-your-writes）。

典型体现点：

- 发帖后自己立刻看到：先在本地 Feed 插入新 tweet（optimistic update，乐观更新），再异步与服务端对齐。
- 点赞后自己立刻看到：当前会话先显示已点赞与计数变化，其他用户可稍后再收敛。
- 删除后自己立刻看不到：先本地隐藏/标记删除，再同步服务端，失败时回滚。

一句话区分：`Session Consistency` 保证“我看到我刚写的”，不保证“所有人同时看到同一值”。

### Q9: 为什么常说“先更新 L2 再更新 L1”？这个顺序有什么考量？

先澄清：这不是“所有场景都固定如此”。

- 在**网络回源写入**场景中，常见做法是先写 `L2 Disk Cache`，再回填 `L1 Memory Cache`。  
  主要是为了：  
  1) 持久性优先（先落盘，重启后还在）；  
  2) 降低分层不一致风险（避免 L1 新、L2 旧）；  
  3) 失败处理更可控（L2 失败时可选择不提升到 L1）。
- 在**L2 命中读取**场景中，流程通常是：  
  先读取/校验 L2（必要时更新 L2 的过期元数据），再回填 L1 提升后续命中率。
- 如果业务极端追求首帧速度，也可先回填 L1、再异步写 L2，但要接受一致性与故障处理复杂度上升。

源码参考（Kingfisher）：

- `Reference/Kingfisher-master/Sources/Cache/ImageCache.swift:625-649`  
  内存 miss 后查磁盘，磁盘命中后执行 `store(..., toDisk: false)` 回填内存。
- `Reference/Kingfisher-master/Sources/Cache/ImageCache.swift:636-646`  
  注释明确“Cache the disk image to memory”。
- `Reference/Kingfisher-master/Sources/Cache/DiskStorage.swift:273-275`  
  磁盘读取时先判定是否过期，过期即 miss。
- `Reference/Kingfisher-master/Sources/Cache/DiskStorage.swift:282-283`  
  磁盘命中后会更新过期元数据（extend expiration）。

### Q10: HTTP 相关 Q&A 去哪看？

本阶段所有 HTTP 协议问答（`ETag/304` 流程、`URLSession` 自动控制、头像 URL 策略、`URLCache` 安全性、`Range Request`）已整理到：  
[E3-http-caching-protocol.md](/Users/sunset/Documents/Projects/mobile-system-design/case-study/design-twitter-feed/E3-http-caching-protocol.md)

---
---

## ✍️ 你的练习

**题目**：Design Twitter Feed 的缓存策略

**要求**：
1. 画出 L1/L2/Network 的读取路径（hit/miss）
2. 说明哪个场景用 Cache-Aside，哪个场景用 Stale-While-Revalidate（SWR）
3. 解释 `Cache-Control`、`ETag`、`Last-Modified` 各做什么（详见 `E3-http-caching-protocol.md`）
4. 说出 2 个 invalidation（失效）触发条件（例如：logout、pull-to-refresh）

你可以先用 5 分钟写草稿，我再帮你做面试版 review。

## ✅ 参考答案（缓存策略）

### 1) L1/L2/Network 读取路径（hit/miss）

```text
读取 Feed：
UI -> Repository -> L1 Memory Cache
  -> hit（命中）且未过期: 直接返回
  -> hit（命中）但已过期: 视为 miss（未命中），继续查 L2
  -> miss（未命中）: 查 L2 Disk Cache
      -> hit（命中）: 返回 UI，并回填 L1
      -> miss（未命中）或 expired（过期）: 请求 Network(API)
          -> 200: 写入 L2 + 回填 L1 + 返回 UI
          -> 304: 使用本地 L2 数据 + 回填 L1 + 返回 UI
```

### 2) 场景选择：Cache-Aside vs Stale-While-Revalidate（SWR）

- Feed 首页：用 `Stale-While-Revalidate（SWR）`  
  先展示旧数据，后台拉新，刷新体验更平滑。
- 余额/支付/库存（高一致场景）：默认 `Network-First（网络优先）`  
  UI 展示 loading/skeleton（骨架屏）后走网络请求，避免展示旧数据。
- `Cache-Aside（旁路缓存）` 在高一致场景可作为“回写缓存”或“失败兜底（stale-if-error）”，  
  但不应作为默认读路径的数据来源。

### 3) `Cache-Control`、`ETag`、`Last-Modified` 各自作用

- 请直接复述 [E3-http-caching-protocol.md](/Users/sunset/Documents/Projects/mobile-system-design/case-study/design-twitter-feed/E3-http-caching-protocol.md) 的「HTTP Cache 三件事」与「ETag 最小工作流」两段。
- 面试最短口条：`Cache-Control` 决定缓存规则，`ETag/If-None-Match` 与 `Last-Modified/If-Modified-Since` 决定重验证。

### 4) 失效触发条件（invalidation）

- `logout（登出）`：清理用户私有缓存（资料、私信、token 相关数据）。
- `pull-to-refresh（下拉刷新）`：主动触发重验证或强制拉新。
- `app version upgrade（版本升级）`：按版本号清理不兼容缓存结构。

### 面试 30 秒总结口条

我会做 L1 `Memory Cache` + L2 `Disk Cache` 的分层读取，优先命中本地，未命中再请求网络。  
Feed 用 `Stale-While-Revalidate（SWR）` 提升体感速度，强一致场景默认 `Network-First（网络优先）`。  
HTTP 层用 `Cache-Control`、`ETag`、`Last-Modified` 控制缓存与重验证，并通过登出、下拉刷新、版本升级触发失效。
