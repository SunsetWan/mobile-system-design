# E2 練習：High-Level Diagram — 畫出系統大圖

## 練習目標

在 10 分鐘內，針對「Design Twitter Feed」畫出一張包含 Server + Client + 主要模組的系統大圖，並能解釋每個模組的職責。

---
---

# 📝 Coach 教學

## 🎯 E2 的核心：畫圖不是畫 UI，是畫「資料怎麼流動」

很多 iOS 工程師一聽到「畫圖」，就開始畫 `UITableView` → `UITableViewCell` → `UIImageView`...

**❌ 錯！** 面試官要看的不是 UI 元件，而是：

1. **資料從哪裡來？**（Server → Client）
2. **資料在 Client 端怎麼流動？**（API → Repository → Persistence → UI）
3. **有哪些主要模組？各自負責什麼？**

## 系統大圖的三層結構

```
┌─────────────────────────────────────────────────┐
│                  ☁️ Server Side                  │
│  ┌──────────┐  ┌──────────────┐  ┌───────────┐  │
│  │ Backend  │  │Push Provider │  │   CDN     │  │
│  │ (API)    │  │ (APNs)       │  │ (Images)  │  │
│  └────┬─────┘  └──────┬───────┘  └─────┬─────┘  │
│       │               │               │         │
└───────┼───────────────┼───────────────┼─────────┘
        │               │               │
  ══════╪═══════════════╪═══════════════╪══════════
        │               │               │
┌───────┼───────────────┼───────────────┼─────────┐
│       ▼               ▼               ▼         │
│  📱 Client Side                                  │
│                                                  │
│  ┌─────────────┐              ┌──────────────┐   │
│  │ API Service │              │ Image Loader │   │
│  │ (Alamofire) │              │ (Kingfisher) │   │
│  └──────┬──────┘              └──────┬───────┘   │
│         │                            │           │
│         ▼                            │           │
│  ┌─────────────┐                     │           │
│  │ Repository  │◄────────────────────┘           │
│  └──────┬──────┘                                 │
│         │                                        │
│    ┌────┴────┐                                   │
│    ▼         ▼                                   │
│ ┌──────┐ ┌──────────┐                            │
│ │ API  │ │Persistence│                           │
│ │(遠端)│ │ (本地DB)  │  ← Single Source of Truth  │
│ └──────┘ └────┬─────┘                            │
│               │                                  │
│         ┌─────┴──────┐                           │
│         ▼            ▼                           │
│  ┌───────────┐ ┌────────────┐                    │
│  │ Feed Flow │ │Detail Flow │                    │
│  │(列表頁面) │ │(詳情頁面)  │                    │
│  └───────────┘ └────────────┘                    │
│                                                  │
│  ┌─────────────┐  ┌────────────────┐             │
│  │ Coordinator │  │ Analytics      │             │
│  │ (導航管理)  │  │ Service        │             │
│  └─────────────┘  └────────────────┘             │
│                                                  │
│  ┌──────────────────────────────────────────┐    │
│  │         App Module / DI Graph            │    │
│  │     (組裝所有模組、管理生命週期)          │    │
│  └──────────────────────────────────────────┘    │
└──────────────────────────────────────────────────┘
```

## 每個模組的職責（用你熟悉的 iOS 對照）

### ☁️ Server Side（一句帶過即可）

| 模組 | 職責 | 你需要說的 |
|---|---|---|
| **Backend** | 提供 API（Feed、Like、Comments） | 「假設 Backend 已經存在，我專注在 Client 端」 |
| **Push Provider** | 推播通知（APNs） | 「用來通知 client 有新推文」 |
| **CDN** | 靜態資源加速（圖片、影片） | 「圖片走 CDN，不經過 Backend，減少延遲」 |

### 📱 Client Side（你的主場）

| 模組 | 職責 | iOS 對應 | 面試要說的重點 |
|---|---|---|---|
| **API Service** | 封裝所有 server 通訊 | Alamofire / URLSession 封裝 | 「統一入口，方便加 auth header、retry、logging」 |
| **Persistence** | 本地資料庫，Single Source of Truth | CoreData / Realm | 「所有 UI 都從 Persistence 讀資料，不直接用 API response」 |
| **Repository** | 協調 API 和 Persistence | 你寫過的 DataManager | 「UI 不需要知道資料來自網路還是本地」 |
| **Image Loader** | 圖片載入 + Memory/Disk Cache | Kingfisher | 「獨立模組，和業務邏輯解耦」 |
| **Feed Flow** | 列表頁的 UI + ViewModel | ViewController + ViewModel | 「只負責顯示，不處理資料來源邏輯」 |
| **Detail Flow** | 詳情頁的 UI + ViewModel | 同上 | 同上 |
| **Coordinator** | 管理頁面跳轉邏輯 | Coordinator pattern | 「解耦頁面之間的依賴，支持 Deep Link」 |
| **DI Graph** | 依賴注入，組裝所有模組 | Swinject / 手動 DI | 「方便測試，可以替換 mock」 |

## 🔑 面試官在看什麼 Signal？

1. **能不能展示 Big Picture**：不陷入細節，10 分鐘內把大圖畫完
2. **模組之間的關係**：箭頭方向 = 資料流向，是否清楚
3. **Modularity 意識**：每個模組是否可以獨立開發/測試/替換

## ⚠️ 常見錯誤

- ❌ 畫了 `UITableView` → `UITableViewCell` → `UILabel`（太細節）
- ❌ 只畫了 Client 端，沒有 Server 端（缺少全局觀）
- ❌ 所有箭頭都指向同一個 ViewController（沒有分層）
- ❌ 花 20 分鐘畫圖（時間管理失敗，擠壓 Deep Dive 時間）

## ❓ E2 Q&A

### Q: 為什麼 `Image Loader` 不放到 `Repository` 後面？

**短答案**：因為圖片下載/解碼/快取屬於「媒體傳輸與渲染優化」，不是「業務資料來源協調」。

**面試可用版本（30 秒）**：

1. **職責分離（Separation of Concerns）**
   - `Repository` 專注在 Feed/Tweet 等業務資料（JSON → Domain Model → Persistence）。
   - `Image Loader` 專注在圖片生命週期（下載、解碼、Downsampling、Memory/Disk Cache）。

2. **快取策略不同**
   - `Repository` 常搭配 DB/SSOT 管理結構化資料一致性。
   - 圖片快取更像 Kingfisher：以 `URL + processor` 當 key，重視 decode 成本、尺寸變體、淘汰策略（LRU）。

3. **UI 效能需求不同**
   - 圖片載入要綁 `cell reuse`、取消請求、prefetch、priority（滾動時非常關鍵）。
   - 若硬塞進 `Repository`，容易讓資料層過重，且難以對齊 UI 細粒度優化。

4. **跨場景重用**
   - Avatar、Feed、Detail、Comment 都會用同一套圖片能力。
   - 獨立成 `Image Loader`（像 Kingfisher）可被多個 flow 共用，不綁單一 `Repository`。

**什麼情況可以讓 `Repository` 介入？**
- 可以由 `Repository` 保存「圖片 metadata（URL、ETag、尺寸）」到本地，  
  但實際圖片下載與快取仍建議交給 `Image Loader`。

---
---

## ✍️ 你的練習

現在請你自己畫一張 High-Level Diagram（可以用文字描述、ASCII art、或任何畫圖工具）：

**題目**：Design Twitter Feed

**要求**：
1. 包含 Server Side（至少 2 個模組）
2. 包含 Client Side（至少 5 個模組）
3. 標出資料流向（箭頭方向）
4. 每個模組寫一句話描述職責

畫完貼到這裡，我幫你 review！
