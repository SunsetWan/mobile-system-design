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

### Cache-Aside vs Stale-While-Revalidate 到底差在哪？

兩者都會發 API 請求，差別在於**使用者什麼時候看到資料**：

```
Cache-Aside（用戶少時）:
  打開 App → 查 cache → ❌ miss → 等 API 回來 → 😐 看到 spinner → 顯示資料

Stale-While-Revalidate（用戶多時）:
  打開 App → 查 cache → ✅ 有舊資料 → 🚀 立刻顯示 → 背景發 API → 悄悄刷新 UI
```

| | Cache-Aside | Stale-While-Revalidate |
|---|---|---|
| Cache Hit | ✅ 直接返回，不打 API | ✅ 直接返回，**同時**背景打 API |
| Cache Miss | ⏳ 使用者等 API（spinner） | ⏳ 同左，一樣要等 |
| 核心差別 | 資料**要嘛新、要嘛沒有** | 資料**先舊後新**，永遠秒開 |

**用戶少時 Cache-Aside 夠用**——server 壓力小，API 回得快，spinner 閃一下就過了。

**用戶多時必須 Stale-While-Revalidate**——因為：
1. Server 壓力大，API 可能回應慢，不能讓使用者乾等
2. 百萬用戶同時打開 app 都發請求 = DDoS，先顯示 cache 可以**延遲和分散**請求時機
3. 配合 `ETag` / `304 Not Modified`，如果資料沒變，server 回空 body 就好，**省頻寬**

**Kingfisher 就是這樣做的**：`kf.setImage(with: url)` 時，先從 `MemoryStorage` 秒回舊圖，背景再檢查有沒有更新。你從來不會看到頭像位置空白轉圈圈——這就是 Stale-While-Revalidate。

---

## 4. ETag / 304 Not Modified 機制詳解

### 要解決的問題

Stale-While-Revalidate 背景會發 API 拉最新資料，但如果資料根本**沒變**呢？Server 把完整的 JSON（比如 50KB 的 Feed）重新傳一遍就是浪費頻寬。

**ETag 機制讓 server 可以告訴 client：「資料沒變，你用舊的就好」，只回一個幾乎空的 response（~200 bytes）。**

### 完整流程

```
【第一次請求】

Client                              Server
  │                                    │
  ├── GET /feed ──────────────────────►│
  │                                    │
  │◄── 200 OK ────────────────────────┤
  │    Body: { tweets: [...] }  (50KB) │
  │    Header: ETag: "abc123"          │
  │                                    │
  │  （Client 把 "abc123" 和資料一起存到 cache）
  │                                    │

【之後的請求（背景刷新時）】

Client                              Server
  │                                    │
  ├── GET /feed ──────────────────────►│
  │    Header: If-None-Match: "abc123" │
  │                                    │
  │    Server 比對：資料的 ETag 還是 "abc123" 嗎？
  │                                    │
  │    ┌─ 沒變 ─►  304 Not Modified    │
  │    │           Body: 空（~200B）    │
  │    │           → Client 繼續用 cache │
  │    │                               │
  │    └─ 有變 ─►  200 OK              │
  │               Body: { 新資料 }(50KB)│
  │               Header: ETag: "def456"│
  │               → Client 更新 cache   │
```

### 類比

把 ETag 想像成資料的**指紋（fingerprint）**：
- Server 回資料時附上指紋 `ETag: "abc123"`
- Client 下次問：「我手上的指紋是 `abc123`，資料變了嗎？」（`If-None-Match: "abc123"`）
- Server 比對指紋：沒變 → 回 `304`（不用傳資料）；變了 → 回 `200` + 新資料 + 新指紋

### 省了多少？

| | 沒用 ETag | 用了 ETag（資料沒變時） |
|---|---|---|
| Response Body | 50KB 完整 JSON | 0 KB（空 body） |
| Status Code | 200 | 304 |
| 省頻寬 | — | **~99%** |

百萬用戶每個小時背景刷新一次，大部分人的 Feed 在一小時內沒變 → 用 ETag 可以省掉巨量頻寬。

### iOS 中的實現

**好消息：`URLSession` + `URLCache` 自動幫你做了！** 你不需要手動處理 ETag header。

```swift
// URLSession 預設就支持 HTTP caching（包含 ETag）
// 只要 server 回的 response 帶有 ETag header，URLCache 會自動：
// 1. 儲存 ETag
// 2. 下次請求自動加上 If-None-Match header
// 3. 收到 304 時自動從 cache 讀取

let config = URLSessionConfiguration.default
config.urlCache = URLCache(
    memoryCapacity: 10 * 1024 * 1024,   // 10MB memory
    diskCapacity: 50 * 1024 * 1024       // 50MB disk
)
config.requestCachePolicy = .useProtocolCachePolicy  // 預設值，遵守 HTTP cache 規則
let session = URLSession(configuration: config)
```

**Alamofire 也是一樣的**：底層用 `URLSession`，所以 ETag 機制自動生效，前提是 server 有回 `ETag` header。

### 相關的 HTTP Cache Header 家族

| Header | 誰設的 | 作用 | 範例 |
|---|---|---|---|
| `ETag` | Server → Client | 資料的指紋 | `ETag: "abc123"` |
| `If-None-Match` | Client → Server | 「我手上的指紋是這個，變了嗎？」 | `If-None-Match: "abc123"` |
| `Cache-Control` | Server → Client | 告訴 client 這筆資料能 cache 多久 | `Cache-Control: max-age=3600` |
| `Last-Modified` | Server → Client | 資料最後修改時間（ETag 的時間版） | `Last-Modified: Wed, 25 Feb 2026 10:00:00 GMT` |
| `If-Modified-Since` | Client → Server | 「這個時間之後有改過嗎？」 | `If-Modified-Since: Wed, 25 Feb 2026 10:00:00 GMT` |

**ETag vs Last-Modified**：ETag 更精確（基於內容 hash），Last-Modified 只精確到秒。面試中提 ETag 就夠了。

### 面試怎麼用？

在討論 Caching 或 Network Optimization 時：

> 「背景刷新時，client 會帶上 `If-None-Match` header 附上之前的 ETag。如果資料沒變，server 回 304 空 body，省掉 99% 頻寬。`URLSession` 的 `URLCache` 預設就支持這個機制，不需要額外實作。」

---

## 📌 關鍵記憶點

1. **Exponential Backoff** = 失敗後等待時間翻倍 + Jitter 防止驚群效應
2. **Stale-While-Revalidate** = 先顯示舊資料、背景更新，面試最愛考
3. **用戶量級**影響策略選擇，這是你問 clarifying question 的理由
