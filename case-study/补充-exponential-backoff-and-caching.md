# 補充知識：Exponential Backoff & Caching 策略

> 這兩個概念在 System Design 面試中出現率極高，而且你作為 iOS 工程師其實每天都在「用」，只是沒意識到。

---

## 1. Exponential Backoff（指數退避）

### 一句話解釋

請求失敗後，不要立刻重試，而是**每次等待的時間翻倍**，避免對 server 造成更大壓力。

### iOS 生活化類比

想像你打電話給客服，佔線了：
- ❌ 瘋狂重撥（= 立即重試）→ 線路更塞
- ✅ 等 1 秒 → 再等 2 秒 → 再等 4 秒 → 再等 8 秒...（= Exponential Backoff）

### 公式

```
等待時間 = base × 2^(重試次數) + random jitter
```

| 重試次數 | 等待時間（base=1s） | 加上 Jitter（隨機偏移） |
|---|---|---|
| 第 1 次 | 1s | 1s + random(0~0.5s) |
| 第 2 次 | 2s | 2s + random(0~0.5s) |
| 第 3 次 | 4s | 4s + random(0~0.5s) |
| 第 4 次 | 8s | 8s + random(0~0.5s) |
| 第 5 次 | 16s | 16s + random(0~0.5s) |

### 為什麼需要 Jitter（隨機偏移）？

如果 10 萬個用戶同時失敗，都在第 1 秒重試 → 又全部失敗 → 都在第 2 秒重試...這叫 **Thundering Herd（驚群效應）**。加上隨機偏移可以把重試分散開。

### Swift 範例

```swift
func retry<T>(
    maxAttempts: Int = 5,
    baseDelay: TimeInterval = 1.0,
    operation: () async throws -> T
) async throws -> T {
    for attempt in 0..<maxAttempts {
        do {
            return try await operation()
        } catch {
            if attempt == maxAttempts - 1 { throw error }
            
            let delay = baseDelay * pow(2.0, Double(attempt))
            let jitter = Double.random(in: 0...0.5)
            try await Task.sleep(nanoseconds: UInt64((delay + jitter) * 1_000_000_000))
        }
    }
    fatalError("Unreachable")
}

// 使用
let tweets = try await retry {
    try await apiService.fetchFeed()
}
```

### 面試怎麼用？

當你被問「用戶量很大怎麼辦？」時，可以說：

> 「Client 端會實作 Exponential Backoff with Jitter，避免大量用戶同時重試造成 Thundering Herd。配合 max retry count 和 max delay cap，防止無限等待。」

---

## 2. Caching 策略（面試常考的三種）

### 策略對比表

| 策略 | 做法 | 使用者體驗 | 適用場景 |
|---|---|---|---|
| **Cache-Aside** | 先查 cache → miss 就打 API → 寫回 cache | 第一次慢，之後快 | 一般資料載入 |
| **Stale-While-Revalidate** | 先回傳舊資料（立即顯示）→ 背景更新 → 刷新 UI | 永遠秒開，可能短暫看到舊資料 | Feed、Profile |
| **Read-Through** | Cache 自己負責去打 API（app 不管） | 對 app 最簡單 | Repository pattern |

### iOS 對照表

| System Design 概念 | iOS 你已經在用的東西 |
|---|---|
| Memory Cache (L1) | `NSCache`（app 被 kill 就清掉） |
| Disk Cache (L2) | `FileManager.default.urls(for: .cachesDirectory)`、CoreData |
| HTTP Cache | `URLCache`（`URLSession` 內建，靠 `Cache-Control` header 控制） |
| LRU 淘汰 | `NSCache` 內建 LRU（`countLimit` / `totalCostLimit`） |
| Cache-Aside | 你寫的 `if let cached = cache[key] { return cached } else { fetch() }` |
| Stale-While-Revalidate | Kingfisher 的 `.loadDiskFileSynchronously` + 背景刷新 |

### Stale-While-Revalidate 流程（面試最常考）

```
使用者打開 Feed
    │
    ├──① 立即從 Disk Cache 讀取舊資料 → 顯示在 UI（秒開！）
    │
    └──② 同時發 API 請求
            │
            ├── 成功 → 更新 Cache + 刷新 UI（使用者可能看到內容閃一下更新）
            └── 失敗 → 不影響，使用者已經在看舊資料了
```

### 面試怎麼用？

當你被問「Feed 怎麼做 caching？」時，可以說：

> 「我會用 Stale-While-Revalidate 策略。打開 app 時先從 disk cache 載入上次的 feed 立即顯示，同時背景發 API 拉最新資料。這樣使用者不用看到 loading spinner，體驗最好。Trade-off 是使用者可能短暫看到過期資料。」

---

## 3. 兩者的關係：用戶量級如何影響策略選擇

| 用戶量級 | Backoff 策略 | Caching 策略 |
|---|---|---|
| 少（< 1 萬） | 簡單重試就好 | Cache-Aside 夠用 |
| 中（10-100 萬） | 需要 Exponential Backoff | Stale-While-Revalidate 減少 API 請求 |
| 大（> 1000 萬） | Backoff + Jitter + Rate Limiting | 積極 caching + `ETag` / `304` 減少傳輸量 |

這就是為什麼面試時要問「預期有多少用戶？」—— 它直接決定了你的 caching 和 retry 策略要多積極。

---

## 📌 關鍵記憶點

1. **Exponential Backoff** = 失敗後等待時間翻倍 + Jitter 防止驚群效應
2. **Stale-While-Revalidate** = 先顯示舊資料、背景更新，面試最愛考
3. **用戶量級**影響策略選擇，這是你問 clarifying question 的理由
