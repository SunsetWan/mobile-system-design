# E1 練習：Design Twitter Feed — Requirement Gathering

## Clarifying Questions（列出 5 個）

1. 預期有多少用戶？（网络请求失败后重试逻辑）
2. 主要用户是网络基础设施不好的地方的用户吗？（影响 app 大小，缓存逻辑）
3. 支持图文混排吗？还是就先纯文字 tweet？支持上传/下载视频吗？
4. timeline 是要求客户端主动调用 API 更新，还是服务队有推送机制？(WebSocket or HTTP SSE?)
5. 「資料一致性要求多高？」或「資料更新頻率多高？」

## Functional Requirements（列出 3 個）

1. 用戶可以無限滑動瀏覽 timeline（需要 pagination）
2. 可以点赞
3. 可以看评论

## Non-Functional Requirements（列出 2 個）

1. 用户手机离线时，仍可以看之前浏览过的推文
2. Feed 流提示有更新

## Out of Scope

- 登陆功能
- 关注功能
- 转发功能

---
---

# 📝 Coach Feedback（Round 1）

<details>
<summary>點擊展開 Round 1 feedback（已過期）</summary>

### 整體評價：⭐⭐⭐ (3/5) — 有基礎，但掉進了「iOS 工程師典型陷阱」

你的 Functional Requirements 和 Q3、Q4 不錯，說明你有產品意識。但有幾個關鍵問題需要修正 👇

### 🔴 最大問題：Q1 和 Q2 太 code-level 了

> Q1: 最低支持哪个 iOS 版本? (取决于是用 UIKit 还是 SwiftUI)
> Q2: 偏好什么工程架构？MVVM 还是 TCA？

這正是 `common-interview-mistakes.md` 說的「花太多時間在 UI 層」。System Design 面試**不是在討論 code 怎麼寫**，面試官不在乎你用 MVVM 還是 TCA。

**正確的思路**：問影響「系統」的問題，而不是影響「實作」的問題。

### 🟡 Functional Requirements：方向對，但表述要修正

**不要提 UITableView / List**。Functional Requirement 描述的是「使用者能做什麼」，不是「用什麼元件實作」。

### 🔴 Non-Functional Requirements：不應該用問句

NFR 應該是你做出的決定，不是問面試官的問題。

### 🟡 Out of Scope：語氣要修正

不要用問句「需要嗎？」，而是直接宣告。

</details>

---

# 📝 Coach Feedback（Round 2）

## 整體評價：⭐⭐⭐⭐ (4/5) — 明顯進步！🎉

Round 1 的三個核心問題（code-level 問題、問句語氣、提 UI 元件）全部修正了，進步很大 👍

### 🟢 Clarifying Questions：大幅進步

| 題號 | 評價 | 說明 |
|---|---|---|
| Q1 ✅ | 🟢 | 從「iOS 版本」升級為「用戶量級」，而且連結到了重試策略，表示你理解了 Exponential Backoff |
| Q2 ✅ | 🟢 | 從「MVVM vs TCA」升級為「新興市場」，連結到 app 大小和 caching，正確的系統思維 |
| Q3 ✅ | 🟢 | 保留了媒體類型的問題，而且加上了影片，比 Round 1 更完整 |
| Q4 ✅ | 🟢 | Pull vs Push 依然是最好的一題 |
| ⚠️ | 🟡 | 少了第 5 題！建議補上「資料一致性要求多高？」或「資料更新頻率多高？」 |

Q1 的括號說明可以再精準一點：「網路請求失敗後重試邏輯」→ 建議改為「影響 client 端 Exponential Backoff 策略和 caching 積極程度」，這樣更展現你對 mobile 影響的理解。

### 🟢 Functional Requirements：修正成功

- ✅ 不再提 UITableView / List
- ✅ 用使用者視角描述功能

⚠️ 但內容方向需要調整：你列了「發推文」和「刪除推文」，但 README 範例中這兩個是 **Out of Scope**。面試時 Feed 題通常聚焦在**讀取面**：

建議改為：
1. 用戶可以無限滑動瀏覽 timeline（需要 pagination）
2. 用戶可以對推文按讚（like）
3. 用戶可以查看推文的評論（唯讀）

**為什麼？** 45 分鐘面試時間有限，「發推」和「刪推」涉及寫入、同步、樂觀更新等複雜議題，會分散你的 deep dive 精力。先把讀取面做好，如果面試官想聊寫入面再展開。

### 🟢 Non-Functional Requirements：修正成功

- ✅ 不再用問句，改為陳述句

⚠️ 仍缺一個重要 NFR：**Resource optimization（最小化頻寬、CPU、電量消耗）**。這在 mobile 面試是必提的。

### 🟢 Out of Scope：修正成功

- ✅ 不再用問句，直接宣告

### ✅ 下一步

只差一點就可以過關（5/5）：
1. 補上 Q5（資料一致性 or 資料更新頻率）
2. Functional Requirements 調整為「讀取面」為主（滑動、按讚、看評論）
3. Non-Functional 補上 Resource optimization

修完就可以進入 **E2. High-Level Diagram** 了！🚀

---
---

# ❓ 學習 Q&A

### Q: 什麼是 Data Sharding？在這題會用到嗎？

**Data Sharding** = 把一張大資料表按規則拆分到多台 server 上（例如按 `user_id % 4` 分到 4 台 DB）。

**在 Mobile System Design 面試中，你幾乎不需要討論它。** 這是後端 System Design 的核心話題，不是 mobile 的。面試官不會期待一個 iOS 工程師深入 sharding 策略。

如果面試官主動問到，一句帶過即可：

> 「Sharding 是 backend 的職責，client 端不需要知道資料存在哪台 server。但如果 sharding 導致 API response 順序不一致，client 需要自己做排序。」

**結論**：把精力留在 Caching、Pagination、Offline 這些 mobile 核心主題上。

### Q: 什麼是 QPS（Queries Per Second）？iOS 工程師需要知道嗎？

**QPS** = 後端每秒能處理多少個請求。例如「這個 API 的 QPS 是 10,000」代表 server 每秒最多處理 1 萬次請求。

**iOS 工程師不需要會算 QPS，但要知道它如何影響你的 client 設計：**

| QPS 壓力 | 後端會做的事 | 你（iOS client）要配合做的事 |
|---|---|---|
| 正常 | 正常回應 | 正常請求 |
| 接近上限 | 回傳 `429 Too Many Requests` | 收到 429 後觸發 **Exponential Backoff**，不要繼續打 |
| 超過上限 | 開始 **Rate Limiting**（限流） | 減少請求頻率，合併請求（例如批次 like） |

**Alamofire 的對應**：`RetryPolicy` 可以設定遇到 `429` 時自動重試 + backoff，你不需要手動處理。

**面試怎麼用**：當你問「預期有多少用戶？」時，其實就是在間接評估 QPS。如果用戶量大，你可以說：

> 「Client 端應減少不必要的 API 呼叫——用 caching 避免重複請求、用 debounce 合併連續操作（例如連點 like）、遇到 429 時用 Exponential Backoff 退避。」

### Q: SQL DB 和 NoSQL DB 的區別？跟我用過的 Realm / SQLite 是什麼關係？

#### 一句話區別

- **SQL（關聯式）**：資料存在「表格」裡，表與表之間有關聯（Foreign Key），用 SQL 語言查詢
- **NoSQL（非關聯式）**：資料存成 document / key-value / graph 等形式，沒有固定 schema，查詢方式各異

#### 你用過的 iOS DB 對照

| iOS 你用過的 | 類型 | 說明 |
|---|---|---|
| **SQLite** | SQL | 關聯式，需要定義 table schema、寫 SQL 語句 |
| **Core Data** | SQL（底層是 SQLite） | Apple 封裝的 ORM，用物件操作，底層仍是 SQLite |
| **Realm** | NoSQL（Object Store） | 物件導向，不用寫 SQL，schema 是 Swift class 定義的 |
| **UserDefaults** | NoSQL（Key-Value） | 最簡單的 key-value 存儲，適合小量設定資料 |

#### 後端常見的 DB 類型

| 類型 | 代表 | 適合場景 | 不適合場景 |
|---|---|---|---|
| SQL | PostgreSQL、MySQL | 資料有明確關聯（User → Tweets → Comments）、需要複雜查詢 | 超大量寫入、schema 經常變動 |
| NoSQL - Document | MongoDB | Schema 不固定、JSON-like 資料、快速迭代 | 複雜跨表查詢 |
| NoSQL - Key-Value | Redis | 快取、Session、排行榜 | 複雜查詢 |
| NoSQL - Wide Column | Cassandra | 超大量寫入（IoT、日誌） | 小規模應用 |

#### 面試怎麼用？

Mobile System Design 面試中，DB 選擇通常出現在兩個場景：

**1. Client 端本地存儲**（你的主場 ✅）
> 「本地我會用 Core Data / Realm 作為 Single Source of Truth，因為 Feed 資料有明確的 model 關聯（Tweet → User → Comments），需要 query 能力。簡單的 config 用 UserDefaults 就夠了。」

**2. Server 端 DB**（一句帶過即可）
> 「Server 端 DB 選型不是 client 的職責，但我假設後端用關聯式 DB 來存 Tweet 和 User 的關聯，搭配 Redis 做 feed cache 加速讀取。」

**Trade-off 記憶口訣**：SQL 適合「關聯多、查詢複雜」；NoSQL 適合「量大、schema 靈活、讀寫快」。

### Q: 什麼是 Cache TTL？

**TTL（Time To Live）** = 快取資料的「保質期」。過期後資料會被自動丟棄，下次存取時必須重新從 server 拉取。

**Kingfisher 範例**：

```swift
let cache = ImageCache.default

// 頭像很少變 → TTL 設長
cache.diskStorage.config.expiration = .days(7)

// 廣告 banner 常變 → TTL 設短
cache.diskStorage.config.expiration = .seconds(300)
```

**HTTP 層的 TTL**：就是 `Cache-Control: max-age=3600`，意思是「這筆資料 3600 秒內有效，不用再問 server」。`URLCache` 會自動遵守這個 header。

**Trade-off**：TTL 長 → 省流量省電但可能看到過期資料；TTL 短 → 資料新鮮但頻繁請求。

### Q: 為什麼要問「資料更新頻率多高？」和「資料一致性要求多高？」

這兩個問題看起來抽象，但直接決定了你的 client 端設計方案。

#### 「資料更新頻率多高？」→ 決定 Pull vs Push 和 Cache TTL

| 場景 | 更新頻率 | 策略 | 為什麼 |
|---|---|---|---|
| Twitter Feed | 每秒數千條新推文 | Pull（下拉刷新） | 頻率太高，push 每一條會炸掉電量和流量 |
| 即時聊天 | 不定，但使用者期待秒到 | Push（WebSocket） | 使用者無法接受「下拉才看到新訊息」 |
| 天氣 App | 每小時更新一次 | Pull + 長 TTL Cache | 資料變化慢，cache 1 小時都沒問題 |

**對 client 的影響**：如果面試官說「Feed 更新非常頻繁」，你就知道：
- 不該用 WebSocket 推每一條（太耗電）
- 應該用 **Stale-While-Revalidate**（先顯示 cache，背景拉新的）
- 可以搭配 Push Notification 只通知「有新內容」，使用者打開再拉

**Kingfisher 類比**：`ImageCache` 的 `expiration` 設定就是 TTL。如果圖片很少變（用戶頭像），設 `.days(7)`；如果常變（廣告 banner），設 `.seconds(300)`。**更新頻率直接決定你的 Cache TTL**。

#### 「資料一致性要求多高？」→ 決定 Optimistic vs Pessimistic Update

**什麼是 Optimistic Update（樂觀更新）？** 使用者按了 Like，**不等 server 回應就先更新 UI**（❤️ 立刻變紅），背景再發 API。如果 API 失敗，再 rollback。

| 場景 | 一致性要求 | 策略 | 為什麼 |
|---|---|---|---|
| 按 Like | 🟢 低（Eventual Consistency） | Optimistic Update | 就算 like 數暫時差 1，使用者不會在意 |
| 銀行轉帳 | 🔴 高（Strong Consistency） | 等 server 確認才更新 UI | 餘額顯示錯誤是災難 |
| 發推文 | 🟡 中 | Optimistic + Pending 狀態 | 先顯示「發送中...」，成功後移除狀態 |

**面試怎麼用**：如果面試官說「Like 數不需要絕對精確」，你可以說：

> 「Like 我會用 Optimistic Update——按下後立刻更新本地 UI 和 cache，背景發 POST 請求。如果失敗，用 Alamofire 的 `RetryPolicy` 重試；重試都失敗則 rollback UI。這樣使用者體驗最流暢，trade-off 是短暫的資料不一致。」

#### 總結

```
資料更新頻率 → 決定 Pull vs Push → 決定 Cache TTL
資料一致性要求 → 決定 Optimistic vs Pessimistic Update → 決定 UI 回應速度
```

**不問這些，你就是在猜設計方案。問了之後，你的每個設計選擇都有依據。** 這就是面試官想看到的 signal 🎯

### Q: 什麼是 HTTP SSE？跟 WebSocket 有什麼差別？

#### 一句話區別

- **SSE（Server-Sent Events）**：Server **單向**推資料給 Client，走標準 HTTP
- **WebSocket**：Server 和 Client **雙向**互傳資料，走獨立的 WebSocket 協議

#### 生活化類比

- **SSE** = 聽廣播 📻：電台（server）一直播，你（client）只能聽，不能回話
- **WebSocket** = 打電話 📞：雙方可以同時說話和聽

#### 技術對比

| | SSE | WebSocket |
|---|---|---|
| **方向** | 單向（Server → Client） | 雙向（Server ↔ Client） |
| **協議** | 標準 HTTP | 獨立的 ws:// 協議 |
| **資料格式** | 純文字（text/event-stream） | 文字 + 二進位 |
| **斷線重連** | ✅ 瀏覽器/client 自動重連 | ❌ 需要自己實作 |
| **電量消耗** | 🟢 較低（HTTP 連線，OS 可優化） | 🔴 較高（持久連線 + heartbeat） |
| **防火牆** | ✅ 走 HTTP，不會被擋 | ⚠️ 部分企業防火牆會擋 ws:// |
| **實作複雜度** | 🟢 簡單 | 🔴 較複雜（連線管理、heartbeat） |
| **適合場景** | Feed 更新、股票報價、比分推播 | 即時聊天、多人遊戲、協作編輯 |

#### 關鍵判斷邏輯

```
Client 需要頻繁發資料給 Server 嗎？
    │
    ├── 不需要（只接收）→ 用 SSE
    │   例：Feed 有新推文通知、股票價格更新
    │
    └── 需要（雙向互傳）→ 用 WebSocket
        例：聊天室（發送 + 接收訊息）、多人遊戲
```

#### iOS 實作對應

| 方案 | iOS API | 範例 |
|---|---|---|
| SSE | 沒有原生 API，需用第三方（如 `EventSource` / `LDSwiftEventSource`），或自己用 `URLSession` stream 實作 | Feed 新推文提示 |
| WebSocket | `URLSessionWebSocketTask`（iOS 13+）原生支持 | 即時聊天 |

```swift
// WebSocket 範例（iOS 原生）
let task = URLSession.shared.webSocketTask(with: URL(string: "wss://api.twitter.com/stream")!)
task.resume()

// 接收訊息
func receive() {
    task.receive { result in
        switch result {
        case .success(let message):
            // 處理新訊息
            self.receive() // 繼續監聽
        case .failure(let error):
            // 斷線，需要自己重連
            self.reconnect()
        }
    }
}
```

#### 在 Twitter Feed 題中怎麼選？

> 「Feed 的即時更新我會選 SSE 而非 WebSocket，因為 Feed 更新是**單向的**——server 推新推文通知給 client，client 不需要透過這個通道回傳資料。SSE 走標準 HTTP、支持自動重連、電量消耗更低。Trade-off 是 SSE 只能傳文字，但 Feed 通知的 payload 本來就是 JSON 文字，所以不是問題。」
>
> 「如果之後需要做即時聊天功能，那就需要 WebSocket，因為聊天是雙向的。」

#### 面試常見追問

| 問題 | 回答要點 |
|---|---|
| 「SSE 斷線怎麼辦？」 | SSE 協議內建自動重連 + `Last-Event-ID`，斷線後自動從上次的位置繼續接收 |
| 「WebSocket 斷線怎麼辦？」 | 需要自己實作重連邏輯 + Exponential Backoff |
| 「為什麼不全用 WebSocket？」 | 過度設計（over-engineering）。單向場景用 WebSocket 浪費資源、增加複雜度、更耗電 |

### Q: Repository Pattern 和 Coordinator Pattern 是什麼？

這兩個是 iOS 開發中常見的設計模式，在 System Design 面試的 High-Level Diagram 裡幾乎一定會出現。

#### Repository Pattern — 資料來源的中間人

**一句話**：UI 不需要知道資料來自 API 還是本地 DB，Repository 統一幫你處理。

```
               ┌──────────────┐
               │  ViewModel   │   ← 只跟 Repository 拿資料
               └──────┬───────┘
                      │
               ┌──────▼───────┐
               │  Repository  │   ← 決定要打 API 還是讀 Cache
               └──┬────────┬──┘
                  │        │
          ┌───────▼──┐  ┌──▼──────────┐
          │API Service│  │ Persistence │
          │(Alamofire)│  │ (CoreData)  │
          └──────────┘  └─────────────┘
```

**解決什麼問題？**
- 沒有 Repository：ViewController 裡混雜 `URLSession` 呼叫 + CoreData 查詢 + cache 判斷，難以維護
- 有 Repository：ViewController 只呼叫 `repository.getTweets()`，完全不知道資料來源

**Swift 範例**：

```swift
protocol TweetRepository {
    func getTweets() async throws -> [Tweet]
}

class TweetRepositoryImpl: TweetRepository {
    let apiService: APIService      // Alamofire 封裝
    let persistence: TweetStorage   // CoreData / Realm

    func getTweets() async throws -> [Tweet] {
        // Stale-While-Revalidate 策略
        let cached = try? await persistence.getCachedTweets()
        if let cached { /* 先回傳舊資料給 UI */ }

        let fresh = try await apiService.fetchTweets()
        await persistence.save(fresh)   // 更新本地
        return fresh
    }
}
```

**面試怎麼說**：
> 「Repository 作為 API 和 Persistence 的中間層，讓 UI 不需要知道資料來自哪裡。這也方便做 Stale-While-Revalidate——先回傳 cache，背景刷新。測試時可以注入 mock Repository。」

---

#### Coordinator Pattern — 導航邏輯的管理者

**一句話**：把「頁面跳轉邏輯」從 ViewController 抽出來，由 Coordinator 統一管理。

**解決什麼問題？**

沒有 Coordinator 時，ViewController 之間互相 push/present，緊耦合：

```swift
// ❌ 沒有 Coordinator：VC 知道下一個畫面是誰
class FeedViewController {
    func didTapTweet(_ tweet: Tweet) {
        let detailVC = TweetDetailViewController(tweet: tweet)
        navigationController?.pushViewController(detailVC, animated: true)
        // FeedVC 直接依賴 TweetDetailVC → 緊耦合
    }
}
```

有 Coordinator 時，VC 只說「發生了什麼事」，由 Coordinator 決定「去哪裡」：

```swift
// ✅ 有 Coordinator：VC 不知道下一個畫面是誰
protocol FeedCoordinatorDelegate: AnyObject {
    func didSelectTweet(_ tweet: Tweet)
}

class FeedViewController {
    weak var coordinator: FeedCoordinatorDelegate?

    func didTapTweet(_ tweet: Tweet) {
        coordinator?.didSelectTweet(tweet)  // 只通知，不決定去哪
    }
}

class FeedCoordinator: FeedCoordinatorDelegate {
    let navigationController: UINavigationController

    func didSelectTweet(_ tweet: Tweet) {
        let detailVC = TweetDetailViewController(tweet: tweet)
        navigationController.pushViewController(detailVC, animated: true)
    }
}
```

**為什麼面試要提？**
- 展示你理解「模組解耦」
- 支持 Deep Link（Coordinator 可以直接建構任意頁面的 navigation stack）
- 方便 A/B Testing（同一個事件，Coordinator 可以導向不同頁面）

**面試怎麼說**：
> 「導航邏輯由 Coordinator 管理，ViewController 之間不直接引用。這支持 Deep Link——收到 push notification 時，Coordinator 可以直接建構正確的 navigation stack，不需要逐頁跳轉。」

---

#### 學習資源

| 資源 | 類型 | 連結 |
|---|---|---|
| **Soroush Khanlou — The Coordinator** | 📝 Blog（Coordinator 原始提出者） | https://khanlou.com/2015/01/the-coordinator/ |
| **Hacking with Swift — Coordinator Pattern** | 📝 Tutorial（完整教學） | https://www.hackingwithswift.com/articles/71/how-to-use-the-coordinator-pattern-in-ios-apps |
| **daveneff/Coordinator** | 💻 GitHub（Swift 5，含範例 App） | https://github.com/daveneff/Coordinator |
| **Alamofire 原始碼** | 💻 GitHub（Repository pattern 的真實範例：`Session` 封裝了 `Request` 的建立和分發） | https://github.com/Alamofire/Alamofire |
| **Kingfisher 原始碼** | 💻 GitHub（Repository pattern 的變體：`KingfisherManager` 協調 `ImageDownloader` + `ImageCache`） | https://github.com/onevcat/Kingfisher |

**Kingfisher 就是 Repository Pattern 的活教材**：`KingfisherManager` 扮演 Repository 角色——呼叫 `kf.setImage(with: url)` 時，它先查 `ImageCache`（本地），cache miss 再用 `ImageDownloader`（遠端），你完全不用管資料來自哪裡。
