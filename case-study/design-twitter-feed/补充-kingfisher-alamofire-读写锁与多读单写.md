# 补充：Kingfisher / Alamofire 读写锁与多读单写

## Q&A

### Q: KF 和 Alamofire 里有没有「读写锁」或「多读单写」实现？

结论（先说结果）：

1. **Kingfisher 有典型的多读单写（MRSW）范式**，在测试实现里使用 `concurrent queue + barrier write`。
2. **Kingfisher 生产代码里也有并发写隔离**（`concurrent queue + barrier`），但读路径不总是以 `queue.sync` 暴露，更多是通过写侧串行化维护状态。
3. **Alamofire 当前主干源码没有使用 RWLock / barrier 的 MRSW 结构**；它主要用 `Protected<T>` + `os_unfair_lock`（或 `NSLock`）做互斥访问，读写都会串行进入临界区。

## 源码参考

### 结论 1：Kingfisher 有标准 MRSW（读 `sync`，写 `barrier`）

- `Reference/Kingfisher-master/Tests/KingfisherTests/RetryStrategyTests.swift:442`
  - `queue` 定义为 `DispatchQueue(..., attributes: .concurrent)`。
- `Reference/Kingfisher-master/Tests/KingfisherTests/RetryStrategyTests.swift:446`
  - `isConnected` 的 getter 使用 `queue.sync { _isConnected }`（读）。
- `Reference/Kingfisher-master/Tests/KingfisherTests/RetryStrategyTests.swift:448`
  - `isConnected` 的 setter 使用 `queue.sync(flags: .barrier)`（写）。

这是一种典型的「多读并行、单写独占」实现方式。

### 结论 2：Kingfisher 生产代码使用 barrier 串行化共享集合写入

- `Reference/Kingfisher-master/Sources/Networking/NetworkMonitor.swift:68`
  - `observersQueue` 使用 `attributes: .concurrent`。
- `Reference/Kingfisher-master/Sources/Networking/NetworkMonitor.swift:110`
  - 新增 observer 时使用 `observersQueue.async(flags: .barrier)`。
- `Reference/Kingfisher-master/Sources/Networking/NetworkMonitor.swift:117`
  - 删除 observer 时使用 `observersQueue.async(flags: .barrier)`。
- `Reference/Kingfisher-master/Sources/Networking/NetworkMonitor.swift:96`
  - 网络恢复时批量读取并清空 observers 也放在 barrier 块中。

### 结论 3：Alamofire 主要是互斥锁模型（不是 RWLock）

- `Reference/Alamofire-master/Source/Core/Protected.swift:54`
  - `UnfairLock` 注释明确是 `os_unfair_lock` wrapper。
- `Reference/Alamofire-master/Source/Core/Protected.swift:104`
  - `read` 通过 `lock.around { ... }` 访问。
- `Reference/Alamofire-master/Source/Core/Protected.swift:114`
  - `write` 也通过同一个 `lock.around { ... }` 修改。
- `Reference/Alamofire-master/Tests/ProtectedTests.swift:36`
  - 测试用 `DispatchQueue.concurrentPerform` 并发读写 `Protected`，验证线程安全语义。

这代表 Alamofire 的选择是「实现简单、行为可预测」的互斥锁封装，而不是提升读并行度的 RWLock 设计。

---

### Q: `NetworkMonitor.swift` 里为什么用 `barrier`？放到 main queue 可以吗？

结论：

1. `barrier` 在这里主要是保护 `observers` 共享数组，确保「append / remove / 批量取出并清空」不会并发冲突。
2. 放到 main queue **可以实现线程安全**，前提是你保证所有 `observers` 读写都只在 main queue 执行。
3. 但当前实现把网络监听放在后台队列，回调再切到 main，这样能避免把状态管理与 UI 主线程强耦合；另外，当前这段代码几乎都是 barrier 写操作，用 serial queue 也能达到同样安全性。

源码参考：

- `Reference/Kingfisher-master/Sources/Networking/NetworkMonitor.swift:64`
  - `NWPathMonitor` 在 `monitorQueue`（utility）上运行，不在 main queue。
- `Reference/Kingfisher-master/Sources/Networking/NetworkMonitor.swift:76`
  - `pathUpdateHandler` 触发后会进入 `handlePathUpdate`，这条路径来自监控队列。
- `Reference/Kingfisher-master/Sources/Networking/NetworkMonitor.swift:96`
  - 网络恢复时使用 `observersQueue.async(flags: .barrier)`，并在同一临界区做 `activeObservers = observers` + `removeAll()`，保证原子性。
- `Reference/Kingfisher-master/Sources/Networking/NetworkMonitor.swift:110`
  - `addObserver` 对数组写入用 barrier。
- `Reference/Kingfisher-master/Sources/Networking/NetworkMonitor.swift:117`
  - `removeObserver` 对数组删除也用 barrier。
- `Reference/Kingfisher-master/Sources/Networking/NetworkMonitor.swift:100`
  - 真正通知观察者前，显式切到 `DispatchQueue.main`，说明 UI 回调已经和状态队列解耦。

落地建议（iOS 工程）：

1. 如果你希望最小认知负担：把 `observersQueue` 改成 serial queue，去掉 barrier，语义更直观。
2. 如果你后续会增加“高频只读”（例如查询 observer 数量、快照读取）：保留 concurrent + barrier 的结构更有扩展性。
3. 不建议把 `observers` 管理直接绑死到 main queue，除非这是明确的 UI-only 状态；否则主线程繁忙时会拉长状态变更延迟。

---

### Q: Kingfisher `NetworkMonitor` 内部到底创建了几条自定义 queue？

结论：

1. 固定创建 3 条：`monitorQueue`、`observersQueue`、`startQueue`。
2. 每个 `NetworkObserverImpl` 实例再创建 1 条 `queue`，因此总体是 `3 + N`。

源码参考：

- `Reference/Kingfisher-master/Sources/Networking/NetworkMonitor.swift:64`
  - `monitorQueue`（`NWPathMonitor` 回调队列）。
- `Reference/Kingfisher-master/Sources/Networking/NetworkMonitor.swift:68`
  - `observersQueue`（共享 observer 列表并发保护）。
- `Reference/Kingfisher-master/Sources/Networking/NetworkMonitor.swift:72`
  - `startQueue`（`monitor.start` 幂等启动保护）。
- `Reference/Kingfisher-master/Sources/Networking/NetworkMonitor.swift:141`
  - `NetworkObserverImpl.queue`（每个 observer 的生命周期串行化）。

call site 关联：

- `Reference/Kingfisher-master/Sources/General/KingfisherManager.swift:391`
  - 下载失败后触发 `retryStrategy.retry(...)`。
- `Reference/Kingfisher-master/Sources/Networking/RetryStrategy.swift:210`
  - `NetworkRetryStrategy` 默认注入 `NetworkMonitor.default`。
- `Reference/Kingfisher-master/Sources/Networking/RetryStrategy.swift:256`
  - 断网时通过 `observeConnectivity(...)` 注册 observer，等待网络恢复触发重试。
