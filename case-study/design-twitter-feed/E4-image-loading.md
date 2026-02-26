# E4 练习：Image Loading 基础 — 设计高性能图片加载链路

## 练习目标

在 10-15 分钟内，针对「Design Twitter Feed」讲清楚 Image Loading（图片加载）系统的核心设计：

1. Image Loader（图片加载器）与 File Downloader（文件下载器）的区别
2. L1/L2 缓存 + 下载 + 解码 + UI 生命周期协作
3. Downsampling（降采样）与主线程性能关系
4. 关键 Trade-off（权衡取舍）

---
---

# 📝 Coach 教学

## 🎯 E4 的核心：Image Loading 的本质是“流畅度系统”，不是“下载系统”

面试里如果你只说“把图片下载下来再显示”，通常不够。

**面试官真正要听的是：**

1. 列表滑动时不掉帧（Frame Rate，帧率）
2. 内存可控，不引发 OOM（内存溢出）
3. 弱网下有可接受体验（缓存、占位图、渐进刷新）
4. UI 生命周期正确（复用、取消、防串图）

## 1) 先分清：Image Loader vs File Downloader

| 维度 | Image Loader（图片加载器） | File Downloader（文件下载器） |
|---|---|---|
| 核心目标 | 流畅体验、低延迟显示 | 完整性、可恢复下载 |
| 成功标准 | 不掉帧、不串图、首屏快 | 文件完整、断点续传成功 |
| 存储重点 | Memory + Disk 多层缓存 | 以磁盘持久化为主 |
| 生命周期 | 强绑定 View 复用与取消 | 弱绑定 UI，重状态管理 |

## 2) 推荐高层链路（Design Twitter Feed）

```text
FeedCell/ImageView
  ↓
ImageLoader Facade（门面层）
  ↓
Request Manager（去重 + 优先级 + 取消令牌）
  ↓
L1 Memory Cache（decoded image）
  ↓ miss
L2 Disk Cache（encoded data）
  ↓ miss
Downloader（URLSession/Alamofire）
  ↓
Processor（Downsampling/Corner/Blur）
  ↓
Background Decode（后台解码）
  ↓
Main Thread Render（仅主线程赋值 UI）
```

## 3) E4 必讲 5 个设计点

### A. Memory 里存 decoded image（已解码图片），Disk 里存 encoded data（编码数据）

- L1 目标是“可直接渲染”，避免每次展示都重复解码。
- L2 目标是“省网络与持久化”，存体积更友好的字节数据。

### B. View 复用必须做：取消 + 身份校验

- cell 复用时先取消旧任务（典型在 `prepareForReuse()`）。
- 回调时校验“是不是当前任务”（防止旧请求晚到导致串图）。

### C. Downsampling 要前置

- 先按目标尺寸降采样，再显示。
- 不要把 4K 原图完整解码后再缩到小头像，这会浪费 CPU 与内存。

### D. 同 URL 请求要做去重（Request Coalescing，请求合并）

- 多个 View 同时要同一 URL，不该发 N 次网络请求。
- 应共享同一个下载任务，结果 fan-out（扇出）给多个回调。

### E. Build vs Buy：面试建议优先 Buy（先用成熟库）

- 生产环境优先 Kingfisher / Nuke 之类成熟方案。
- 但你要能讲出底层原理（缓存分层、降采样、取消、去重），不是只会调 API。

## 4) iOS 实战口条（Kingfisher 视角）

- Kingfisher 的 `ImageCache` 天然就是 Memory + Disk 双层。
- `DownsamplingImageProcessor` 比先完整解码再 resize 更省内存与 CPU。
- `ImageView` 扩展里有任务标识检查和取消能力，解决复用串图。
- 下载层有同 URL 任务合并机制，减少重复网络请求。

## 关键 Trade-off（权衡取舍，面试加分）

| 决策 | 好处 | 代价 |
|---|---|---|
| Memory Cache 大 | 首屏更快、滑动更顺 | OOM 风险上升 |
| Downsampling 激进 | 内存与 CPU 压力小 | 清晰度可能下降 |
| 强预取（Prefetching，预取） | 感知更快 | 流量与电量开销增大 |
| 全量自研 | 可深度定制 | 维护成本与坑位显著上升 |

## ⚠️ 常见错误

- ❌ 在主线程做图片解码
- ❌ 只缓存原始 Data，不缓存可直接渲染结果
- ❌ 忽略复用取消，列表高速滚动时串图
- ❌ 同 URL 并发发多次请求（没做去重）
- ❌ 只会“用库”，不会解释设计动机

## ❓ E4 Q&A

### Q1: 为什么说 Image Loader 不是 File Downloader？

因为两者优化目标不同：

- 图片加载优先“体验”（帧率、低延迟、复用正确性）
- 文件下载优先“完整性”（续传、校验、后台可靠完成）

一句话：**Image Loader 关注显示系统，File Downloader 关注传输系统。**

### Q2: 为什么 Memory Cache 应该优先存 decoded image？

为了避免重复解码开销。UI 真正要渲染的是图片对象（如 `UIImage`），不是原始字节流。

源码参考（Kingfisher）：

- `Reference/Kingfisher-master/Sources/Cache/ImageCache.swift:171`  
  Memory 层类型是 `MemoryStorage.Backend<KFCrossPlatformImage>`。
- `Reference/Kingfisher-master/Sources/Cache/ImageCache.swift:178`  
  Disk 层类型是 `DiskStorage.Backend<Data>`。

### Q3: Memory Cache 大小怎么估算？

面试建议用“屏幕预算法”：

- `targetBytes ≈ screenWidthPx * screenHeightPx * 4 * N`（RGBA 约 4 bytes/pixel）
- `N` 通常取 3~4（保留约 3-4 屏图片）

再结合设备动态上限（避免硬编码固定 MB）。

源码参考（Kingfisher 默认策略）：

- `Reference/Kingfisher-master/Sources/Cache/ImageCache.swift:294-297`  
  默认以内存总量 `physicalMemory` 的约 `1/4` 作为 cost limit。

### Q4: 列表复用时如何避免串图？

两步：

1. 复用前取消旧任务（`cancelDownloadTask`）
2. 回调时校验任务标识（task identifier）一致才设置图片

源码参考（Kingfisher）：

- `Reference/Kingfisher-master/Sources/Extensions/ImageView+Kingfisher.swift:309-331`  
  生成 `issuedIdentifier` 并在回调中做一致性检查。
- `Reference/Kingfisher-master/Sources/Extensions/ImageView+Kingfisher.swift:379-380`  
  提供 `cancelDownloadTask()`。

### Q5: 多个 Cell 同时请求同一个 URL，怎么避免重复下载？

做请求合并（coalescing）：

- 若同 URL 已有下载任务，后续请求只追加 callback，不新建网络任务。

源码参考（Kingfisher）：

- `Reference/Kingfisher-master/Sources/Networking/ImageDownloader.swift:383-387`  
  已存在任务则 `append(existingTask, callback:)`。
- `Reference/Kingfisher-master/Sources/Networking/SessionDataTask.swift:61-67`  
  一个 `SessionDataTask` 维护多个 callbacks。

### Q6: Downsampling 和 Resizing 的差别是什么？

- `Downsampling`：直接从输入数据按目标尺寸解码，更省内存与 CPU。
- `Resizing`：常常是在完整图基础上再缩放，代价更高。

源码参考（Kingfisher）：

- `Reference/Kingfisher-master/Sources/General/KFOptionsSetter.swift:640-643`  
  文档注释明确：Downsampling 更高效，优先使用。
- `Reference/Kingfisher-master/Sources/General/KFOptionsSetter.swift:661-663`  
  对 data-represented image，建议优先 downsampling。

### Q7: 为什么 Kingfisher 下载层默认用 `URLSessionConfiguration.ephemeral`？

核心原因不是“要不要缓存”二选一，而是“默认避免持久化副作用，同时保留可配置性”。

- `ephemeral` 默认不使用持久化存储（不把缓存落盘），符合图片下载器“轻副作用、可回收”的目标。
- 直接把 `urlCache = nil` 属于更强策略：会彻底禁用该会话的 URLCache；这在某些场景没必要，且会减少协议层可用优化空间。
- Kingfisher 选择把 `sessionConfiguration` 暴露为可改：默认给你安全的 `ephemeral` 基线，但允许业务按需改成更激进（如 `urlCache = nil`）或更宽松策略。

实战建议：

- 默认沿用 Kingfisher 的 `ephemeral`。
- 高敏感接口（隐私/交易）再额外设 `sessionConfiguration.urlCache = nil`。

源码参考（Kingfisher）：

- `Reference/Kingfisher-master/Sources/Networking/ImageDownloader.swift:203-206`  
  默认 `sessionConfiguration` 是 `ephemeral`，并强调“无持久化缓存存储”是下载器正确工作的前提。
- `Reference/Kingfisher-master/Sources/Networking/ImageDownloader.swift:201-205`  
  文档注释明确该配置“可在下载开始前修改”，说明框架设计为“给默认值 + 允许业务覆盖”。
- `Reference/Kingfisher-master/Sources/Networking/ImageDownloader.swift:210-214`  
  `sessionConfiguration` 变更会重建 `URLSession`，可通过配置切换到你需要的缓存策略（包括 `urlCache = nil`）。

---
---

## ✍️ 你的练习

**题目**：Design Twitter Feed 的图片加载策略

**要求**：
1. 画出 Image Loading 的完整链路（UI -> Cache -> Network -> Decode -> Render）
2. 解释为什么要做 request coalescing（请求合并）
3. 说出 `Downsampling` 与 `Resizing` 的差别
4. 说出 2 个避免串图的机制

你先写 5 分钟草稿，我再帮你做面试版 review。

## ✅ 参考答案（面试可复述）

### 1) 链路

```text
Cell/ImageView -> ImageLoader -> L1 Memory(decoded) -> L2 Disk(data)
-> Downloader -> Processor(Downsampling) -> Background Decode -> Main Thread Render
```

### 2) 为什么要 request coalescing

- 同 URL 并发请求如果不合并，会重复占用网络/CPU/电量。
- 合并后：一个网络请求 + 多个订阅回调，整体吞吐更稳。

### 3) Downsampling vs Resizing

- `Downsampling`：解码阶段按目标尺寸输出，省内存省 CPU。
- `Resizing`：通常先拿到大图再缩放，成本更高。

### 4) 防串图机制

- `prepareForReuse()` 或复用前取消旧请求
- 回调设置图片前做任务标识检查（不是当前任务就丢弃）

### 面试 30 秒总结口条

我会把图片加载当成“性能系统”设计，而不是下载系统。核心是 Memory/Disk 双层缓存、Downsampling 前置、同 URL 请求合并、复用时取消与任务标识校验。这样能同时保证首屏速度、滚动流畅度和内存稳定性。
