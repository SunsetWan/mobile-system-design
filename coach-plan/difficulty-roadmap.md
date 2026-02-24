# 🗺️ Mobile System Design 難度路線圖

> 像 LeetCode 一樣，從 Easy → Medium → Hard 循序漸進
> 每個單元標注：前置知識、學習資源、完成標準

---

## 難度分級邏輯

| 難度 | 判斷標準 | 對 iOS 工程師的意義 |
|---|---|---|
| 🟢 Easy | 概念與日常 iOS 開發高度重疊，只是換個角度（系統設計）重新理解 | 「原來我已經會了，只是不知道怎麼表達」 |
| 🟡 Medium | 需要學習新概念，但可以用 iOS 已知知識作為跳板 | 「這個概念是新的，但我能用 iOS 經驗來理解」 |
| 🔴 Hard | 需要跨領域思考（後端、分散式系統、即時通訊），iOS 經驗不足以直接遷移 | 「這需要全新的思考方式」 |

---

## 🟢 Easy（第 1-3 週）

> **目標**：用你已經熟悉的 iOS 知識，建立 System Design 的「語感」

### E1. 面試框架入門

| 項目 | 內容 |
|---|---|
| **學什麼** | 面試 4 階段流程、時間分配、如何問 clarifying questions |
| **資源** | `README.md` 前 106 行（Interview Process → Gathering Requirements） |
| **為什麼 Easy** | 不涉及技術深度，只是學「面試該怎麼進行」 |
| **iOS 連結** | 想像你在做 Sprint Planning 時如何 clarify user story |
| **完成標準** | ✅ 能不看資料說出 4 個階段和每階段時間 |
| | ✅ 能針對「Design Twitter Feed」列出 5 個 clarifying questions |

---

### E2. High-Level Diagram 基礎

| 項目 | 內容 |
|---|---|
| **學什麼** | 如何畫系統大圖（Server / Client / 主要模組） |
| **資源** | `README.md` L87-L120（High-Level Diagram 段落）、`TEMPLATE.md` |
| **為什麼 Easy** | 你每天都在用這些元件（API Service、Persistence、Image Loader），只是沒畫過圖 |
| **iOS 連結** | API Service = `URLSession` 封裝、Persistence = CoreData、Image Loader = Kingfisher |
| **完成標準** | ✅ 能在 10 分鐘內畫出一個包含 Server + Client + 5 個模組的系統大圖 |
| | ✅ 能解釋每個模組的職責 |

---

### E3. Caching 基礎

| 項目 | 內容 |
|---|---|
| **學什麼** | L1 Memory Cache / L2 Disk Cache、LRU 淘汰策略、HTTP Cache headers |
| **資源** | `topics/caching-deep-dive.md`（62 行，最短的 topic） |
| **前置知識** | 無 |
| **為什麼 Easy** | 你已經用過 `NSCache`、`URLCache`，只是需要用系統設計語言重新描述 |
| **iOS 連結** | `NSCache` = L1、`URLCache` = HTTP Cache、`FileManager` cacheDirectory = L2 |
| **完成標準** | ✅ 能解釋 Cache-Aside vs Stale-While-Revalidate 的差異和適用場景 |
| | ✅ 能說出 ETag / Cache-Control / Last-Modified 的作用 |
| **關鍵 Trade-off** | Memory Cache 大 → 快但 OOM 風險；Disk Cache 大 → 慢但可離線 |

---

### E4. Image Loading

| 項目 | 內容 |
|---|---|
| **學什麼** | Image Loader vs File Downloader 的區別、Caching 分層策略、Downsampling、View lifecycle 整合 |
| **資源** | `topics/image-loading-deep-dive.md` |
| **前置知識** | E3 Caching |
| **為什麼 Easy** | 你每天都在用 Kingfisher/SDWebImage，只是沒思考過「為什麼這樣設計」 |
| **iOS 連結** | Kingfisher `ImageProcessor`、`CGImageSourceCreateThumbnailAtIndex`、`prepareForReuse()` 取消請求 |
| **完成標準** | ✅ 能解釋為什麼 Memory Cache 應該存 decoded image 而非 raw data |
| | ✅ 能說出 Memory Cache 大小應該怎麼計算（螢幕尺寸 × 像素 × 4 screens） |
| **關鍵 Trade-off** | Build vs Buy — 自建 vs 用 Kingfisher，各自的風險 |

---

### E5. 常見面試錯誤

| 項目 | 內容 |
|---|---|
| **學什麼** | iOS 工程師最容易踩的 10 個坑 |
| **資源** | `common-interview-mistakes.md` |
| **前置知識** | E1-E4 |
| **為什麼 Easy** | 閱讀為主，不需要深度技術理解 |
| **完成標準** | ✅ 能列出自己最可能犯的 3 個錯誤 |
| | ✅ 能解釋什麼是「GitHub Template Syndrome」 |

---

### E6. 🏋️ 練習：Design Image Library

| 項目 | 內容 |
|---|---|
| **學什麼** | 完整走一遍面試流程（Requirement → Diagram → Deep Dive） |
| **資源** | `exercises/image-library.md`（有完整解答） |
| **前置知識** | E1-E5 全部 |
| **為什麼 Easy** | 題目領域（圖片載入）是你最熟悉的 iOS 開發場景 |
| **練習方法** | ① 計時 45 分鐘先自己做 → ② 對照答案找差距 → ③ 記錄漏掉的點 |
| **完成標準** | ✅ 能在 5 分鐘內完成 requirement gathering |
| | ✅ 能畫出 Image Request → Request Manager → Cache → Loader 的架構圖 |
| | ✅ 能在 deep dive 中討論 cache key 設計（URI + dimensions + format） |

---

## 🟡 Medium（第 4-7 週）

> **目標**：掌握面試核心主題，學會 trade-off 思維

### M1. RESTful API Design

| 項目 | 內容 |
|---|---|
| **學什麼** | Resource-oriented URL、HTTP methods/status codes、Versioning、Idempotency Key、BFF |
| **資源** | `topics/restful-api-design-deep-dive.md` |
| **前置知識** | E1-E2 |
| **為什麼 Medium** | 你用過 `URLSession` 呼叫 API，但沒有「設計」過 API |
| **iOS 連結** | `URLRequest` HTTP method、`HTTPURLResponse.statusCode`、`Codable` |
| **完成標準** | ✅ 能設計一組 CRUD endpoint（用正確的 HTTP method + status code） |
| | ✅ 能解釋為什麼需要 Idempotency Key（用 Stripe 付款場景說明） |
| | ✅ 能說出 over-fetching 和 under-fetching 的解法 |
| **關鍵 Trade-off** | REST vs GraphQL — 何時用哪個 |

---

### M2. Pagination

| 項目 | 內容 |
|---|---|
| **學什麼** | Offset vs Cursor vs Keyset、API 設計（request/response 格式）、Page Drift 問題 |
| **資源** | `topics/mobile-pagination-deep-dive.md`（最長最完整的 topic） |
| **前置知識** | M1 RESTful API |
| **為什麼 Medium** | Cursor 的概念對 iOS 工程師是全新的，但用 `UICollectionView` 的「載入更多」可以理解 |
| **iOS 連結** | `UICollectionViewDataSourcePrefetching`、Diffable Data Source |
| **完成標準** | ✅ 能解釋 Page Drift 問題和 Cursor 如何解決它 |
| | ✅ 能寫出 cursor pagination 的 request/response JSON |
| | ✅ 能說出 Twitter / Slack / Stripe 分別用什麼 pagination（引用 case study） |
| **關鍵 Trade-off** | Cursor（無 Page Drift 但不能跳頁） vs Offset（能跳頁但有 Page Drift） |

---

### M3. In-App API Design（Library 設計）

| 項目 | 內容 |
|---|---|
| **學什麼** | Library 公開 API 設計哲學、Error Reporting（Result type）、Builder Pattern、Threading 規則 |
| **資源** | `topics/in-app-api-design-deep-dive.md` |
| **前置知識** | E3、E4 |
| **為什麼 Medium** | Swift 的 Protocol-oriented design 你很熟，但「為其他開發者設計 API」的思維是新的 |
| **iOS 連結** | Swift `Result<Success, Failure>`、`@discardableResult`、Fluent Interface（如 SnapKit） |
| **完成標準** | ✅ 能說出 "Easy to learn, hard to misuse" 的具體實踐方式 |
| | ✅ 能設計一個 Swift library 的 public API（用 Protocol + Result type） |
| **關鍵 Trade-off** | 靈活性 vs 安全性 — 參數用 String（靈活但易錯）vs Enum（安全但不靈活） |

---

### M4. Navigation Architecture

| 項目 | 內容 |
|---|---|
| **學什麼** | Direct Coupling → Coordinator → Router 的演進、Deep Linking、Synthetic Back Stack |
| **資源** | `topics/mobile-navigation-deep-dive.md` |
| **前置知識** | E2 High-Level Diagram |
| **為什麼 Medium** | Coordinator pattern 你可能聽過，但 URI-based Router 和 Deep Link 的系統設計是新的 |
| **iOS 連結** | `UINavigationController`、Coordinator pattern、`NSUserActivity`、Universal Links |
| **完成標準** | ✅ 能畫出 Coordinator vs Router 的對比圖 |
| | ✅ 能回答「Deep Link 打開後按 Back 應該去哪？」（Synthetic Back Stack） |
| **關鍵 Trade-off** | Type Safety（Coordinator 知道目標 class）vs Decoupling（Router 用 URI 字串） |

---

### M5. Prefetching + QoS

| 項目 | 內容 |
|---|---|
| **學什麼** | 3 種 Prefetching 類型、QoS 4 級 Priority、Adaptive Concurrency |
| **資源** | `topics/prefetching.md` + `topics/quality-of-service.md` |
| **前置知識** | M2 Pagination、E3 Caching |
| **為什麼 Medium** | 概念不難，但需要把多個知識點組合在一起 |
| **iOS 連結** | `UICollectionViewDataSourcePrefetching`、`URLSession.configuration.networkServiceType`、`OperationQueue.qualityOfService` |
| **完成標準** | ✅ 能說出什麼時候該 prefetch、什麼時候不該（metered network / low battery） |
| | ✅ 能把 QoS 4 級和具體場景對應（User-Critical / UI-Critical / UI-Non-Critical / Background） |
| **關鍵 Trade-off** | Prefetch 太激進 → 浪費流量電量；太保守 → 使用者看到 spinner |

---

### M6. 🏋️ 練習：Design Caching Library

| 項目 | 內容 |
|---|---|
| **學什麼** | Library 設計全流程 + Persistence 深入討論（Journal + BLOB vs File System） |
| **資源** | `exercises/caching-library.md`（有完整解答） |
| **前置知識** | E3 Caching + M3 In-App API |
| **為什麼 Medium** | 比 Image Library 多了 data structure（LRU 的 Doubly Linked List + HashMap）和 concurrency 討論 |
| **練習方法** | 計時 45 分鐘自行設計 → 對照答案 |
| **完成標準** | ✅ 能設計 Cache 的 public API（init / get / set / clear） |
| | ✅ 能討論 BLOB vs File System 的 trade-off |
| | ✅ 能解釋 DIRTY/CLEAN state 解決 crash 後一致性問題 |

---

### M7. 🏋️ 練習：Design File Downloader Library

| 項目 | 內容 |
|---|---|
| **學什麼** | Concurrency 管理（Dispatcher + Worker Pool）、Foreground vs Background Download、File Integrity |
| **資源** | `exercises/file-downloader-library.md`（有完整解答） |
| **前置知識** | M3 In-App API + M5 QoS |
| **為什麼 Medium** | 引入了 Job vs Worker 的概念、同一 URL 多個 Job 的去重、以及 background download |
| **練習方法** | 計時 45 分鐘自行設計 → 對照答案 |
| **完成標準** | ✅ 能畫出 Download Dispatcher 的 Job queue + Worker pool 架構 |
| | ✅ 能解釋 Foreground vs Background download 的 pros/cons |
| | ✅ 能說出 checksum validation 的流程 |
| **iOS 連結** | `URLSessionDownloadTask`、`URLSessionConfiguration.background`、`BGProcessingTask` |

---

## 🔴 Hard（第 8-12 週）

> **目標**：征服跨領域難題，達到 Senior/Staff 面試水平

### H1. Offline-First Architecture

| 項目 | 內容 |
|---|---|
| **學什麼** | SSOT（Single Source of Truth）、Delta Sync（sync_token）、Pending Queue、4 種 Conflict Resolution、Soft Deletes |
| **資源** | `topics/offline-first-architecture-deep-dive.md`（最深的 topic） |
| **前置知識** | E3 Caching + M1 RESTful API + M2 Pagination |
| **為什麼 Hard** | Sync 和 Conflict Resolution 是全新的分散式系統概念，iOS 經驗無法直接遷移 |
| **iOS 連結** | CoreData `NSFetchedResultsController` = SSOT 觀察者、`BGProcessingTask` = 背景同步、`NSPersistentHistoryTracking` ≈ Delta Sync |
| **完成標準** | ✅ 能畫出 Offline-First 的完整資料流（UI → Local DB → Sync Engine → API） |
| | ✅ 能解釋 Full Sync vs Delta Sync，並說出 sync_token 優於 timestamp 的原因 |
| | ✅ 能比較 4 種 Conflict Resolution（LWW / Server Authority / Field-Level Merge / CRDT） |
| | ✅ 能設計一個 Pending Queue 的完整流程（Optimistic Update → Persist → Retry → Rollback） |
| **關鍵 Trade-off** | Optimistic Update（快但可能 rollback）vs Pessimistic Update（慢但安全） |

---

### H2. Resumable Uploads

| 項目 | 內容 |
|---|---|
| **學什麼** | Chunked Upload 三階段（Init → Append → Finalize）、Chunk Size 選擇、Idempotency |
| **資源** | `topics/resumable-uploads.md` |
| **前置知識** | H1 Offline-First + M1 RESTful API |
| **為什麼 Hard** | 需要同時考慮 network 不穩定、app 被 kill、server 端 chunk 組裝，是多層次的問題 |
| **iOS 連結** | `URLSessionUploadTask`、tus 協議、`FileManager` 分割檔案 |
| **完成標準** | ✅ 能畫出 3 階段流程圖 |
| | ✅ 能說出 chunk size 的 trade-off（小 chunk → 多 overhead；大 chunk → 失敗代價大） |
| | ✅ 能解釋如何確保 resume 不會造成重複（Idempotency） |

---

### H3. Real-Time Communication（README 知識整合）

| 項目 | 內容 |
|---|---|
| **學什麼** | Push Notification / Short Polling / Long Polling / SSE / WebSocket 的完整比較、協議選擇（REST / GraphQL / gRPC） |
| **資源** | `README.md` L176-L232（Real-time Notifications + Protocols 段落） |
| **前置知識** | M1 RESTful API |
| **為什麼 Hard** | 5 種即時通訊方案的深入 trade-off 比較，需要理解後端概念（持久連線、server push） |
| **iOS 連結** | APNs = Push Notification、`URLSessionWebSocketTask` = WebSocket、`EventSource` = SSE |
| **完成標準** | ✅ 能畫出 5 種方案的比較表（Pros / Cons / Use Cases） |
| | ✅ 能為不同場景選擇方案（Feed 用 SSE、Chat 用 WebSocket、Like 用 Background REST） |
| | ✅ 能解釋 WebSocket 的 battery 影響和 heartbeat 機制 |

---

### H4. 🏋️ 練習：Design Chat App

| 項目 | 內容 |
|---|---|
| **學什麼** | 綜合所有知識：WebSocket + REST + Push + Offline + Pagination + Data Model + Attachments |
| **資源** | `exercises/chat-app.md`（有完整解答，最長的練習） |
| **前置知識** | H1 + H2 + H3 全部 |
| **為什麼 Hard** | 是整個 repo 最複雜的練習，涵蓋 3 層通訊協議 + 資料模型設計 + 附件處理 + 安全性 |
| **練習方法** | 計時 60 分鐘自行設計 → 對照答案 → 特別注意 API Service 的 3 層設計 |
| **完成標準** | ✅ 能設計 WebSocket event 格式（HELLO/MSG_IN/MSG_OUT/MSG_READ/BYE） |
| | ✅ 能設計 Chat / Message / User / Attachment 的 DB schema |
| | ✅ 能回答「Two-ID Problem」（client UUID vs server ID） |
| | ✅ 能討論 E2E Encryption 的必要性和限制 |
| | ✅ 能解釋訊息排序問題（為什麼不能信任 client clock） |

---

### H5. 🏋️ 練習：Design Instagram Feed（無解答）

| 項目 | 內容 |
|---|---|
| **學什麼** | 在沒有「標準答案」的情況下獨立完成設計 — 這才是真正的面試 |
| **資源** | 無解答。用 `README.md` 的 Twitter Feed 範例作為參考 |
| **前置知識** | 所有 Easy + Medium + Hard |
| **為什麼 Hard** | 沒有解答可以對照，必須獨立判斷設計的完整性和合理性 |
| **練習方法** | 計時 45 分鐘獨立完成 → 請 coach 進行 mock interview feedback |
| **需涵蓋的主題** | Requirement Gathering、High-Level Diagram、Feed Pagination（Cursor）、Image Loading 策略、Offline Cache、Like/Comment 的 Optimistic Update |
| **完成標準** | ✅ 能在 45 分鐘內走完面試 4 階段 |
| | ✅ 每個設計選擇都能說出 trade-off |

---

### H6. 🏋️ 練習：自選題（無解答，模擬真實面試）

從 `exercises/README.md` 中選擇無解答的題目進行練習：

| 題目 | 核心挑戰 | 建議順序 |
|---|---|---|
| Design Photo App | Upload/Sync photos、Resumable Upload、CDN | H6-1 |
| Design Push Notification System | APNs 整合、Silent Push、Payload 設計 | H6-2 |
| Design Contact App with Real-Time Status | Presence（在線狀態）、WebSocket vs Polling | H6-3 |
| Design Flight Booking System | Transaction、Seat Locking、Cache Invalidation | H6-4 |
| Design Facebook/Instagram Story | 24hr TTL、Media Pipeline、Prefetching | H6-5 |

---

## 📊 總覽表

| # | 單元 | 難度 | 類型 | 預估時間 |
|---|---|---|---|---|
| E1 | 面試框架入門 | 🟢 Easy | 知識 | 1 天 |
| E2 | High-Level Diagram | 🟢 Easy | 知識 | 1 天 |
| E3 | Caching 基礎 | 🟢 Easy | 知識 | 2 天 |
| E4 | Image Loading | 🟢 Easy | 知識 | 2 天 |
| E5 | 常見面試錯誤 | 🟢 Easy | 知識 | 1 天 |
| E6 | 練習：Image Library | 🟢 Easy | 練習 | 2 天 |
| M1 | RESTful API Design | 🟡 Medium | 知識 | 2 天 |
| M2 | Pagination | 🟡 Medium | 知識 | 3 天 |
| M3 | In-App API Design | 🟡 Medium | 知識 | 2 天 |
| M4 | Navigation Architecture | 🟡 Medium | 知識 | 2 天 |
| M5 | Prefetching + QoS | 🟡 Medium | 知識 | 2 天 |
| M6 | 練習：Caching Library | 🟡 Medium | 練習 | 2 天 |
| M7 | 練習：File Downloader | 🟡 Medium | 練習 | 2 天 |
| H1 | Offline-First Architecture | 🔴 Hard | 知識 | 4 天 |
| H2 | Resumable Uploads | 🔴 Hard | 知識 | 2 天 |
| H3 | Real-Time Communication | 🔴 Hard | 知識 | 3 天 |
| H4 | 練習：Chat App | 🔴 Hard | 練習 | 3 天 |
| H5 | 練習：Instagram Feed | 🔴 Hard | 練習 | 2 天 |
| H6 | 自選題 ×5 | 🔴 Hard | 練習 | 5 天 |
| | | | **總計** | **~12 週** |

---

## 🔑 每個難度的核心心法

| 難度 | 你要學會的一句話 |
|---|---|
| 🟢 Easy | 「面試不是寫 code，是 **溝通你的思考過程**」 |
| 🟡 Medium | 「每個設計選擇都要說出 **為什麼選這個、不選那個**」 |
| 🔴 Hard | 「面對不確定性時，**做出決定並說明理由** 比找到正確答案更重要」 |
