# Kingfisher `NetworkMonitor` 深度分析（Dispatch Queue 设计）

## 1. 结论先行

`NetworkMonitor` 相关实现里，**固定创建 3 条自定义 `DispatchQueue`**，并且在每个 `NetworkObserverImpl` 实例中**按需再创建 1 条队列**。

- 固定 3 条（`NetworkMonitor` 内）：
  - `monitorQueue`
  - `observersQueue`
  - `startQueue`
- 动态 N 条（每个 observer 1 条）：
  - `NetworkObserverImpl.queue`

所以总数不是固定常量，而是：`3 + N`。

参考：
- `NetworkMonitor.swift:64`（`monitorQueue`）
- `NetworkMonitor.swift:68`（`observersQueue`）
- `NetworkMonitor.swift:72`（`startQueue`）
- `NetworkMonitor.swift:141`（`NetworkObserverImpl.queue`）

---

## 2. 每条 Queue 在解决什么问题

## 2.1 `monitorQueue`：隔离系统网络监听回调，避免阻塞主线程

`NWPathMonitor` 被启动在 `monitorQueue` 上，而不是 main queue。

- 代码位置：
  - `NetworkMonitor.swift:64`（定义 utility queue）
  - `NetworkMonitor.swift:85`（`monitor.start(queue: monitorQueue)`）

解决的问题：

1. 让网络路径更新回调在后台执行，避免把监听逻辑塞进主线程。
2. 将“网络状态感知”与“UI 回调”解耦；UI 仅在最终通知时切回主线程。

---

## 2.2 `observersQueue`：保护共享观察者列表的一致性

`observers` 是共享可变数组，所有写操作都通过 `barrier` 进入。

- 代码位置：
  - `NetworkMonitor.swift:67`（`observers`）
  - `NetworkMonitor.swift:68`（并发队列）
  - `NetworkMonitor.swift:96`（网络恢复时“快照+清空”）
  - `NetworkMonitor.swift:110`（append observer）
  - `NetworkMonitor.swift:117`（remove observer）

解决的问题：

1. 避免并发 append/remove 与遍历冲突。
2. 保证“取当前 observers 快照并清空列表”在同一临界区完成，防止重复通知或漏清理。
3. 允许后续演进为“多读单写”模型（当前生产代码几乎都是写路径）。

---

## 2.3 `startQueue`：保证 `NWPathMonitor` 只被启动一次

`startMonitoring()` 用 `startQueue.sync` 包住 `isStarted` 检查和 `monitor.start`。

- 代码位置：
  - `NetworkMonitor.swift:71`（`isStarted`）
  - `NetworkMonitor.swift:72`（`startQueue`）
  - `NetworkMonitor.swift:82-87`（启动逻辑）

解决的问题：

1. 多线程并发调用 `observeConnectivity` 时，避免重复执行 `monitor.start`。
2. 让“检查 + 启动 + 置位”成为原子序列。

---

## 2.4 `NetworkObserverImpl.queue`：串行化单个 observer 的生命周期

每个 observer 有自己的串行 queue，用于处理 timeout、cancel、notify。

- 代码位置：
  - `NetworkMonitor.swift:141`（queue）
  - `NetworkMonitor.swift:149-155`（timeout 调度）
  - `NetworkMonitor.swift:158-173`（notify）
  - `NetworkMonitor.swift:176-187`（cancel）

解决的问题：

1. 将同一 observer 的状态变更（取消 timeout、移除监控、回调）串行化。
2. 降低 timeout 与 cancel、reconnect 通知互相竞争导致的状态不一致风险。
3. 最终用户回调统一切回 main queue（`NetworkMonitor.swift:170`），确保 UI 使用安全。

---

## 3. 结合 Call Site 的完整路径分析

## 3.1 上游入口：`KingfisherManager` 触发 retry

当下载失败且配置了 `retryStrategy`，`KingfisherManager` 会调用策略的 `retry(context:retryHandler:)`。

- 代码位置：
  - `KingfisherManager.swift:391-401`（失败后调用 `retryStrategy.retry`）

这时若策略是 `NetworkRetryStrategy`，就进入下一步。

## 3.2 策略层：`NetworkRetryStrategy` 决定“立即重试”或“挂起等待网络恢复”

- 代码位置：
  - `RetryStrategy.swift:241-247`
    - `isConnected == true`：立即 `.retry`
    - `isConnected == false`：`waitForReconnection(...)`
  - `RetryStrategy.swift:256-267`
    - 调用 `observeConnectivity(timeoutInterval:callback:)`
    - 把 observer 存入 `context.userInfo` 以便下一次重试前取消旧 observer
  - `RetryStrategy.swift:224-226`
    - 新一轮 retry 前先取消上一个 observer，防止重复监听

## 3.3 监控层：`NetworkMonitor` 收集 observer，网络恢复后批量唤醒

1. `observeConnectivity` -> `addObserver`（可能触发 `startMonitoring`）
   - `NetworkMonitor.swift:124-131`
   - `NetworkMonitor.swift:107-113`
2. `NWPathMonitor` 在 `monitorQueue` 回调路径更新
   - `NetworkMonitor.swift:76-77`
3. 网络恢复时，在 `observersQueue` barrier 区内执行“快照 + 清空”
   - `NetworkMonitor.swift:96-99`
4. 之后切回 main queue，逐个触发 observer `notify(true)`
   - `NetworkMonitor.swift:100-102`

这一整套流程的目标是：多个等待重试的请求共享一个 `NWPathMonitor`，并在网络恢复时安全地批量触发重试。

---

## 4. 为什么不是“全都放 main queue”？

可以把状态操作都放 main queue 来简化线程模型，但会有几个代价：

1. 网络监听与 observer 状态管理被强耦合到主线程，主线程忙时会放大延迟。
2. 背景网络事件处理与 UI 渲染争用同一队列，不利于抖动控制。
3. 可测试性和可维护性下降（当前实现把“监听/状态管理/UI回调”分层到不同队列，边界更清晰）。

当前设计本质是：

- 后台队列处理系统事件和状态同步；
- 主线程只做最终 callback 分发。

---

## 5. 工程视角的 Trade-off

优点：

1. 共享单例 monitor，避免重复创建 `NWPathMonitor`。
2. 队列职责清晰：监听、状态写入、启动幂等、observer 生命周期分别隔离。
3. 对并发重试请求更稳健，适合真实弱网场景。

成本：

1. 队列数量较多（`3 + N`），理解成本高于“单队列全串行”方案。
2. `observersQueue` 当前几乎全写路径，用并发 + barrier 在现阶段收益有限；若未来读操作增多才更显价值。

---

## 6. 可落地改进建议（保持语义不变）

1. 若团队更重视可读性，可将 `observersQueue` 改为 serial queue，去掉 barrier，语义更直接。
2. 保持 `monitorQueue` 与 `startQueue` 不变（这两者分别承担事件隔离和幂等启动，价值明确）。
3. 对 `NetworkObserverImpl` 增加一次性回调保护标记（例如 `didFire`），可进一步降低极端竞态下重复触发风险。

