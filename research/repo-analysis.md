# 📚 Mobile System Design 倉庫調研報告

> **目標讀者**：5 年 iOS 經驗、System Design 經驗為零的工程師
> **調研日期**：2026-02-24

---

## 一、倉庫全景總覽

本倉庫是目前 GitHub 上最完整的 **Mobile System Design 面試準備資源** 之一，結構如下：

```
mobile-system-design/
├── README.md                         ← 面試框架主幹（約 600 行）
├── TEMPLATE.md                       ← 面試筆記模板
├── common-interview-mistakes.md      ← 常見錯誤清單
├── topics/                           ← 10 個 Deep Dive 主題
│   ├── caching-deep-dive.md
│   ├── image-loading-deep-dive.md
│   ├── in-app-api-design-deep-dive.md
│   ├── mobile-navigation-deep-dive.md
│   ├── mobile-pagination-deep-dive.md
│   ├── offline-first-architecture-deep-dive.md
│   ├── prefetching.md
│   ├── quality-of-service.md
│   ├── restful-api-design-deep-dive.md
│   └── resumable-uploads.md
└── exercises/                        ← 4 個完整練習 + 題目清單
    ├── image-library.md
    ├── caching-library.md
    ├── file-downloader-library.md
    ├── chat-app.md
    └── README.md                     ← 30+ 題目清單（大部分無解答）
```

---

## 二、內容深度分析

### 2.1 README.md — 面試框架主幹 ⭐⭐⭐⭐⭐

**內容**：完整的面試流程 + 所有核心知識點的概覽。

| 涵蓋主題 | 深度 | iOS 學員價值 |
|---|---|---|
| 面試流程（4 階段） | 完整 | 🟢 必讀 — 建立時間管理意識 |
| Requirement Gathering | 完整 | 🟢 必讀 — 學員最缺的能力 |
| High-Level Diagram | 完整 | 🟢 必讀 — 學會畫系統大圖 |
| Real-time Notifications（5 種方案比較） | 非常詳細 | 🟡 重要 — Push/SSE/WebSocket 對比 |
| Protocols（REST/GraphQL/WebSocket/gRPC/MQTT） | 非常詳細 | 🟡 重要 — 但學員只需深入 REST |
| Pagination（4 種策略） | 詳細 | 🟢 必讀 — 面試必考 |
| Storage（Client-side） | 中等 | 🟢 必讀 — CoreData schema 設計 |
| Offline & Sync | 概覽 | 🟡 需搭配 topic deep dive |
| Privacy & Security | 詳細 | 🟡 加分項 |
| Cloud vs On-Device | 詳細 | 🟡 加分項 |

**關鍵發現**：README 是一篇「超級長文」，涵蓋面極廣但缺少結構化的學習路徑。直接從頭讀到尾會讓零經驗的學員迷失。

**教學建議**：拆成 3 輪閱讀：
1. **第一輪（骨架）**：只讀面試流程 + Requirement Gathering + High-Level Diagram
2. **第二輪（肌肉）**：Pagination + API Design + Storage
3. **第三輪（血管）**：Real-time + Offline + Security

---

### 2.2 topics/ — Deep Dive 主題 ⭐⭐⭐⭐

10 個 deep dive 的品質和深度不一，以下按對 iOS 學員的學習優先級排序：

#### 🥇 Tier 1 — 必學（面試出現率 >80%）

| 主題 | 品質 | 要點 | iOS 連結 |
|---|---|---|---|
| **Pagination** | ⭐⭐⭐⭐⭐ | 最完整的一篇。Cursor vs Offset vs Keyset，含 Twitter/Slack/Stripe/Reddit 真實案例 | `UICollectionViewDataSourcePrefetching`、Diffable Data Source |
| **Caching** | ⭐⭐⭐⭐ | L1 Memory / L2 Disk、策略（Cache-Aside / Stale-While-Revalidate）、HTTP Cache | `NSCache`、`URLCache`、`Cache-Control` headers |
| **Image Loading** | ⭐⭐⭐⭐ | Build vs Buy、L1/L2 sizing、View lifecycle、Downsampling | Kingfisher `ImageProcessor`、`CGImageSourceCreateThumbnailAtIndex` |
| **Offline-First** | ⭐⭐⭐⭐⭐ | SSOT 概念、Delta Sync、Pending Queue、Conflict Resolution（4 種策略）、Soft Deletes | CoreData `NSFetchedResultsController`、`BGProcessingTask` |

#### 🥈 Tier 2 — 重要（面試出現率 40-60%）

| 主題 | 品質 | 要點 | iOS 連結 |
|---|---|---|---|
| **RESTful API Design** | ⭐⭐⭐⭐ | Resource-oriented、HTTP semantics、Versioning、BFF、Idempotency Key | `URLSession`、`Codable`、API Router pattern |
| **In-App API Design** | ⭐⭐⭐⭐ | Library 設計哲學、Error Reporting（Result type）、Threading | Swift `Result<Success, Failure>`、Protocol-oriented design |
| **Navigation** | ⭐⭐⭐ | Coordinator、URI-based Router、Deep Linking、Synthetic Back Stack | `UINavigationController`、Coordinator pattern |

#### 🥉 Tier 3 — 進階（面試出現率 <30%，但能展現深度）

| 主題 | 品質 | 要點 | iOS 連結 |
|---|---|---|---|
| **QoS** | ⭐⭐⭐ | 4 級 Priority、Concurrency limits、Device state awareness | `URLSession` priority、`OperationQueue.qualityOfService` |
| **Prefetching** | ⭐⭐⭐ | 3 種 Prefetching 類型、ETag、Adaptive策略 | `UICollectionViewDataSourcePrefetching`、`prefetchDataSource` |
| **Resumable Uploads** | ⭐⭐⭐ | Chunked upload 流程、Pros/Cons | `URLSessionUploadTask`、tus 協議 |

---

### 2.3 exercises/ — 練習題 ⭐⭐⭐⭐⭐

這是倉庫 **最有價值** 的部分。每道題都模擬了真實的面試對話（Candidate/Interviewer 格式），展示：
- 如何問 clarifying questions
- 如何推導 functional / non-functional requirements
- 如何畫 high-level diagram
- 如何在 deep dive 中展現 trade-off 思維

| 練習 | 類型 | 頁數 | 深度 | iOS 學員建議 |
|---|---|---|---|---|
| **Image Library** | Library 設計 | ~210 行 | ⭐⭐⭐⭐ | **第 1 題** — 最熟悉的領域，入門最佳 |
| **Caching Library** | Library 設計 | ~280 行 | ⭐⭐⭐⭐⭐ | **第 2 題** — 練習 data structure（LRU）和 persistence |
| **File Downloader** | Library 設計 | ~290 行 | ⭐⭐⭐⭐ | **第 3 題** — 練習 concurrency 和 background tasks |
| **Chat App** | App 設計 | ~360 行 | ⭐⭐⭐⭐⭐ | **第 4 題** — 綜合題，涵蓋 WebSocket + Offline + Data Model |

**關鍵發現**：
- 3 道是 **Library 設計**，1 道是 **App 設計** — 比例偏向 Library
- `exercises/README.md` 列出了 30+ 題目，但只有 4 道有解答
- 缺少 **Feed 類**（Twitter/Instagram Feed）完整練習，而 README 的 Twitter Feed 範例散佈在主文中

---

### 2.4 common-interview-mistakes.md — 錯誤清單 ⭐⭐⭐⭐

**內容**：~300 行，分為 Candidate 和 Interviewer 兩部分。

**對 iOS 學員最重要的警告**：

| 錯誤 | 嚴重度 | 學員風險 |
|---|---|---|
| 🚨 沒有先收集需求就開始畫圖 | 致命 | 🔴 極高 — iOS 工程師習慣直接寫 code |
| 🚨 GitHub Template Syndrome | 致命 | 🔴 極高 — 套用 Repository/UseCase/ViewModel 模板 |
| 🚨 花太多時間在 UI 層 | 嚴重 | 🔴 極高 — UITableView/UICollectionView 是舒適區 |
| ⚠️ 不敢做決定（一直問 "Is this okay?"） | 嚴重 | 🟡 中等 — 缺乏 System Design 信心 |
| ⚠️ Buzzword Dropping | 中等 | 🟡 中等 — 說了 "Clean Architecture" 卻解釋不出來 |
| ⚠️ 用特定 Vendor 替代設計 | 中等 | 🟡 中等 — "用 Firebase" 不是設計 |

---

### 2.5 TEMPLATE.md — 面試筆記模板 ⭐⭐⭐

一份約 80 行的面試結構化筆記模板，包含：
- Requirement Gathering 檢查清單
- High-Level Diagram 核心元件清單
- Deep Dive 主題選擇
- Signal Checklist（Trade-offs、Edge Cases、Platform Specifics）

**教學建議**：讓學員在每次模擬面試時使用這個模板，養成結構化思考的習慣。

---

## 三、知識圖譜 — 主題之間的關聯

以下是 10 個 deep dive 主題之間的依賴和關聯：

```
                    ┌─────────────────┐
                    │  README.md      │
                    │ (面試框架主幹)   │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              ▼              ▼              ▼
     ┌────────────┐  ┌────────────┐  ┌────────────┐
     │ RESTful API│  │  Storage   │  │ Real-time  │
     │  Design    │  │  (README)  │  │ (README)   │
     └─────┬──────┘  └──────┬─────┘  └──────┬─────┘
           │                │               │
     ┌─────┴─────┐    ┌────┴────┐     ┌────┴────────┐
     │ Pagination │    │ Caching │     │ Offline-    │
     │            │◄──►│         │◄───►│ First       │
     └─────┬──────┘    └────┬────┘     └──────┬──────┘
           │                │                 │
     ┌─────┴──────┐   ┌────┴─────┐    ┌──────┴──────┐
     │ Prefetching │   │ Image    │    │ Resumable   │
     │             │   │ Loading  │    │ Uploads     │
     └─────────────┘   └──────────┘    └─────────────┘
     
     ┌─────────────┐   ┌──────────────┐
     │ QoS         │   │ Navigation   │   ← 相對獨立
     └─────────────┘   └──────────────┘
     
     ┌──────────────────┐
     │ In-App API Design│   ← Library 設計專用
     └──────────────────┘
```

**核心關聯**：
- **Pagination ↔ Caching ↔ Offline-First** 是三位一體，幾乎所有面試都會涉及
- **Image Loading** 是 Caching 的一個特化應用
- **Prefetching** 是 Pagination 的延伸優化
- **Resumable Uploads** 是 Offline-First 的上行版本
- **QoS** 和 **Navigation** 相對獨立，但在綜合題（如 Chat App）中會被涉及

---

## 四、倉庫的優勢與不足

### ✅ 優勢

1. **真實面試對話格式**：exercises 完美模擬了面試互動，學員可以學到「怎麼說」而非只是「怎麼想」
2. **Trade-off 導向**：每個設計選擇都有 Pros/Cons 表格，正是面試最看重的 signal
3. **Real-World Case Studies**：Pagination 篇引用 Twitter/Slack/Stripe/Reddit API，增加說服力
4. **平台雙棲**：iOS + Android 並列，有助於理解跨平台設計思維
5. **Common Mistakes 清單**：直接命中 iOS 工程師常犯的錯誤

### ❌ 不足

1. **缺少 Feed 類完整練習**：最常見的面試題（Design Twitter Feed / Instagram Feed）沒有獨立的 exercise 檔
2. **缺少 Architecture Pattern 深入**：MVVM、Clean Architecture、Redux 只在 README 中簡單提及
3. **iOS 範例不足**：大部分 code 範例是 Kotlin/Android，Swift 範例較少
4. **缺少 Mermaid/視覺化流程圖**：使用 SVG 圖片，無法在純文字環境中查看
5. **缺少 Concurrency 主題**：Swift Concurrency（async/await、Actor）在現代面試中越來越重要，但未涵蓋
6. **缺少 Performance 主題**：App Startup Time、Memory Profiling、Instruments 使用等
7. **缺少模擬面試計時指引**：雖然有時間建議，但沒有 step-by-step 的計時練習方案
8. **exercises/README.md 列出 30+ 題但只有 4 題有解答**

---

## 五、個人化學習路徑建議

基於學員「5 年 iOS 經驗、0 System Design 經驗」的背景，建議以下學習路徑：

### Phase 1：建立框架（第 1-2 週）

**目標**：理解面試流程，學會「先問再畫」

| 天 | 任務 | 資源 |
|---|---|---|
| 1-2 | 讀 README.md 的面試流程（前 100 行） | `README.md` L1-L106 |
| 3 | 讀 common-interview-mistakes.md | `common-interview-mistakes.md` |
| 4-5 | 讀 TEMPLATE.md，理解面試結構化筆記 | `TEMPLATE.md` |
| 6-7 | 完成第一道練習：Image Library（只讀不做） | `exercises/image-library.md` |

**關鍵成果**：能說出面試 4 階段，能列出 clarifying questions

### Phase 2：核心知識（第 3-5 週）

**目標**：掌握 4 個必考主題

| 週 | 主題 | 資源 | 練習 |
|---|---|---|---|
| 3 | Caching + Image Loading | `topics/caching-deep-dive.md` + `topics/image-loading-deep-dive.md` | 用 iOS 術語重新描述 Caching 策略 |
| 4 | Pagination + Prefetching | `topics/mobile-pagination-deep-dive.md` + `topics/prefetching.md` | 設計一個 cursor pagination 的 Swift API |
| 5 | Offline-First + RESTful API | `topics/offline-first-architecture-deep-dive.md` + `topics/restful-api-design-deep-dive.md` | 畫出 Offline-First 的資料流圖 |

**關鍵成果**：能解釋 Cursor vs Offset Pagination 的 trade-off，能畫出 SSOT 架構圖

### Phase 3：練習驅動（第 6-8 週）

**目標**：用練習題訓練面試實戰能力

| 週 | 練習 | 重點 |
|---|---|---|
| 6 | Image Library（自己做一遍） | 練習 requirement gathering + high-level diagram |
| 7 | Caching Library | 練習 data structure 討論 + persistence |
| 8 | File Downloader | 練習 concurrency + background tasks |

**練習方法**：
1. **計時 45 分鐘**，先不看答案自己做
2. 對照答案找差距
3. 記錄「我漏掉了什麼」和「我多說了什麼（scope creep）」

### Phase 4：綜合與進階（第 9-10 週）

| 週 | 任務 | 資源 |
|---|---|---|
| 9 | Chat App 練習 | `exercises/chat-app.md` |
| 10 | 模擬面試 + 補充主題（QoS、Navigation、Resumable Uploads） | `topics/` 剩餘檔案 |

### Phase 5：模擬面試衝刺（第 11-12 週）

- 從 `exercises/README.md` 中挑選無解答的題目（如 Instagram Feed、Photo App）
- 計時 45 分鐘自行設計
- 用 coach 進行 mock interview 和 feedback

---

## 六、教學策略建議

### 6.1 利用學員的 iOS 優勢

| 系統設計概念 | 用 iOS 語言解釋 |
|---|---|
| Single Source of Truth | 就像 `NSFetchedResultsController` 監聽 CoreData |
| Cache-Aside Pattern | 就像先檢查 `NSCache`，miss 了才呼叫 `URLSession` |
| Cursor Pagination | 就像 `UICollectionViewDataSourcePrefetching` + `after_id` |
| Optimistic Update | 就像 `UITableView.insertRows` 先更新 UI，背景再呼叫 API |
| Coordinator Pattern | 就像 `UINavigationController` 的進階版 |
| Delta Sync | 就像 `NSPersistentHistoryTracking` 追蹤 CoreData 變更 |
| QoS Priority | 就像 `URLSession.configuration.networkServiceType` |

### 6.2 每次教學的結構

```
1. 拋出問題 → 「如果面試官問你 XXX，你會怎麼回答？」
2. 學員嘗試回答
3. 引用 repo 內容補充
4. 用 iOS 範例具象化
5. 討論 trade-off
6. 總結成一句話（面試可用的 elevator pitch）
```

### 6.3 模擬面試 Feedback 框架

每次模擬面試後，從 4 個維度評分：

| 維度 | 優秀 | 合格 | 不合格 |
|---|---|---|---|
| **Requirement Gathering** | 問了 5+ 好問題，清楚分類 FR/NFR/OOS | 問了基本問題 | 沒問直接畫圖 |
| **High-Level Diagram** | 畫出完整系統，有 Server/Client/模組 | 畫出主要元件 | 只畫了 UI 層 |
| **Deep Dive** | 有 trade-off 分析，用 iOS 具體實作說明 | 說了概念但無比較 | 套模板或背答案 |
| **Communication** | 主動引導對話，觀察面試官反應 | 能回答問題 | 沉默或一直問 "Is this okay?" |

---

## 七、倉庫外的補充資源建議

以下是 repo 未涵蓋但面試可能涉及的主題：

| 主題 | 為什麼重要 | 建議來源 |
|---|---|---|
| **Architecture Patterns（MVVM / Clean / TCA）** | 面試常問 "What architecture would you use?" | [iOS-Clean-Architecture-MVVM](https://github.com/nicklima/iOS-Clean-Architecture-MVVM) |
| **Swift Concurrency（async/await, Actor）** | 現代 iOS 面試必問 | Apple WWDC 2021-2023 |
| **Dependency Injection** | repo 多次提及但未深入 | Swinject / Factory framework |
| **Server-Driven UI** | 部分公司（Airbnb、Uber）的面試重點 | Airbnb Engineering Blog |
| **Performance Optimization** | App Startup、Memory、Battery | Apple Instruments 文件 |
| **Accessibility** | 加分項 | Apple Human Interface Guidelines |

---

## 八、總結

### 這個倉庫能提供什麼

✅ 完整的面試框架和流程  
✅ 高品質的 Deep Dive 主題（尤其是 Pagination 和 Offline-First）  
✅ 最佳的面試對話模擬（exercises）  
✅ 實用的錯誤清單  

### 學員需要額外補充什麼

🔧 Swift/iOS 具體實作範例（repo 偏 Kotlin）  
🔧 Architecture Pattern 深入比較  
🔧 Swift Concurrency  
🔧 更多 App 類練習題（Feed、Photo、Map）  
🔧 計時模擬面試訓練  

### 一句話總結

> **這個 repo 是「知識地圖」，而非「教科書」。** 它告訴你面試會考什麼（what），但學員需要教練幫忙理解為什麼（why）和怎麼說（how）。教練的價值在於把這些零散的知識點串成一條有邏輯的學習路徑，並用 iOS 的語言讓學員產生「啊，原來我已經會了！」的感覺。
