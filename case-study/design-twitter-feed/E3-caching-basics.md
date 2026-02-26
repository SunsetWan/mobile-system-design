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

## HTTP Cache 三件事（一定要会讲）

| Header | 作用 | 面试一句话 |
|---|---|---|
| `Cache-Control` | 控制可用时间与重验证规则 | “决定能不能直接用本地副本” |
| `ETag` + `If-None-Match` | 内容指纹比对 | “没变就回 304，省流量” |
| `Last-Modified` + `If-Modified-Since` | 以时间戳判断是否更新 | “时间版条件请求，精度不如 ETag” |

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
- 在高一致场景中，`Cache-Aside` 更适合作为回写缓存或失败兜底（`stale-if-error`），而不是默认读路径。

---
---

## ✍️ 你的练习

**题目**：Design Twitter Feed 的缓存策略

**要求**：
1. 画出 L1/L2/Network 的读取路径（hit/miss）
2. 说明哪个场景用 Cache-Aside，哪个场景用 Stale-While-Revalidate（SWR）
3. 解释 `Cache-Control`、`ETag`、`Last-Modified` 各做什么
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

- `Cache-Control`：定义缓存策略（如 `max-age`、`no-cache`、`no-store`）。
- `ETag`：资源指纹；客户端带 `If-None-Match` 发条件请求，未变化返回 `304 Not Modified`。
- `Last-Modified`：资源最后修改时间；客户端带 `If-Modified-Since` 做时间型重验证。

### 4) 失效触发条件（invalidation）

- `logout（登出）`：清理用户私有缓存（资料、私信、token 相关数据）。
- `pull-to-refresh（下拉刷新）`：主动触发重验证或强制拉新。
- `app version upgrade（版本升级）`：按版本号清理不兼容缓存结构。

### 面试 30 秒总结口条

我会做 L1 `Memory Cache` + L2 `Disk Cache` 的分层读取，优先命中本地，未命中再请求网络。  
Feed 用 `Stale-While-Revalidate（SWR）` 提升体感速度，强一致场景默认 `Network-First（网络优先）`。  
HTTP 层用 `Cache-Control`、`ETag`、`Last-Modified` 控制缓存与重验证，并通过登出、下拉刷新、版本升级触发失效。
