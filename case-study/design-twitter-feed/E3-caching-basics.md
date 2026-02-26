# E3 練習：Caching 基礎 — 設計多層快取策略

## 練習目標

在 10-15 分鐘內，針對「Design Twitter Feed」說清楚快取分層、快取策略與 HTTP Cache 的設計，並能解釋關鍵 trade-off。

---
---

# 📝 Coach 教學

## 🎯 E3 的核心：Cache 不是只為了快，而是為了「穩定體驗」

很多 iOS 工程師談快取只會說「加速」。

**面試官真正要聽的是：**

1. **離線可用**：網路差時還能看內容
2. **成本控制**：少打 API、少耗流量
3. **電量優化**：降低無線電喚醒次數
4. **一致性策略**：何時允許舊資料，何時一定要最新

## Cache 三層思維（Mobile 版本）

```
UI
  ↓
Repository
  ↓
L1 Memory Cache (NSCache)
  ↓ miss
L2 Disk Cache (File/CoreData/Realm)
  ↓ miss or expired
Network (API + HTTP Cache/ETag)
```

## 每層該放什麼（iOS 對照）

| 層級 | 速度 | 持久性 | 放什麼 | iOS 對應 |
|---|---|---|---|---|
| **L1 Memory Cache** | 最快 | App kill 後消失 | 熱資料、當前畫面常用圖片 | `NSCache`、Kingfisher memory storage |
| **L2 Disk Cache** | 中等 | 可跨重啟 | JSON、圖片、列表快照 | `FileManager`、CoreData、Realm、Kingfisher disk storage |
| **HTTP Cache** | 由協議控制 | 視 header | 可重驗證的 API 回應 | `URLCache` + `Cache-Control`/`ETag` |

## 兩個面試最高頻策略

### 1) Cache-Aside（旁路缓存）

流程：
1. 先查 cache
2. hit 直接回
3. miss 打 API，寫回 cache，再回 UI

**適合**：一致性需求中等、邏輯清楚的一般資料載入。

### 2) Stale-While-Revalidate（先返回旧数据并后台刷新）

流程：
1. 先回舊資料（UI 秒開）
2. 背景打 API 拿新資料
3. 有新資料再刷新 UI

**適合**：Feed、Profile、內容流。
**不適合**：付款、餘額、庫存等強一致場景。

## HTTP Cache 三件事（一定要會講）

| Header | 作用 | 面試一句話 |
|---|---|---|
| `Cache-Control` | 控制可用時間與重驗證規則 | 「決定能不能直接用本地副本」 |
| `ETag` + `If-None-Match` | 內容指紋比對 | 「沒變就回 304，省流量」 |
| `Last-Modified` + `If-Modified-Since` | 以時間戳判斷是否更新 | 「時間版條件請求，精度不如 ETag」 |

## iOS 實戰口條（用你熟悉的庫）

- **Kingfisher**：Memory/Disk 兩層快取 + processor key，對圖片尺寸與解碼成本友好。
- **Alamofire**：可結合 `URLSessionConfiguration.urlCache`；必要時用 interceptor 控制重試與 revalidate。
- **Repository**：負責協調資料來源與策略，不直接耦合 UI 元件。

## 關鍵 Trade-off（面試加分）

| 決策 | 好處 | 代價 |
|---|---|---|
| Memory cache 大 | 命中率高、滑動順 | OOM 風險上升 |
| Disk cache 大 | 離線更完整 | I/O 變慢、清理更複雜 |
| SWR | 體感快、低等待 | 短暫顯示舊資料 |
| 強制每次拉新 | 一致性高 | 延遲高、耗流量耗電 |

## ⚠️ 常見錯誤

- ❌ 只說「快」，沒提離線/成本/電量
- ❌ 把所有資料都塞進 Memory（忽略 OOM）
- ❌ 沒有 invalidation 規則（登出、下拉刷新、版本升級）
- ❌ 不了解 `304 Not Modified` 的意義
- ❌ 在強一致場景也套用 SWR

## ❓ E3 Q&A

### Q1: 既然有 ETag，還需要 App 端 Disk Cache 嗎？

需要。ETag 只能幫你「省下載量」，但每次仍可能要發請求等待 RTT。  
Disk Cache 能在離線或弱網時立即回應，兩者是互補，不是替代。

### Q2: 登出時要清哪些 cache？

- 必清：與使用者身份綁定的資料（個人資料、私訊、token 關聯快取）
- 可保留：公開、匿名可見且不敏感的資源（例如通用圖片）
- 原則：安全優先，其次再談命中率

### Q3: 為什麼 Feed 常用 SWR？

因為 Feed 對「立即可看」的要求通常高於「毫秒級最新」。  
先回快取再背景刷新，能把首屏等待降到最低。

---
---

## ✍️ 你的練習

**題目**：Design Twitter Feed 的快取策略

**要求**：
1. 畫出 L1/L2/Network 的讀取路徑（hit/miss）
2. 說明哪個場景用 Cache-Aside，哪個場景用 SWR
3. 解釋 `Cache-Control`、`ETag`、`Last-Modified` 各做什麼
4. 說出 2 個 invalidation 觸發條件（例如：logout、pull-to-refresh）

你可以先用 5 分鐘寫草稿，我再幫你做面試版 review。
