# E1 練習：Design Twitter Feed — Requirement Gathering

## Clarifying Questions（列出 5 個）

1. 最低支持哪个 iOS 版本? (取决于是用 UIKit 还是 SwiftUI)
2. 偏好什么工程架构？MVVM 还是 TCA？
3. 支持图文混排吗？还是就先纯文字 tweet？
4. timeline 是要求客户端主动调用 API 更新，还是服务队有推送机制？(WebSocket or HTTP SSE?)
5. 

## Functional Requirements（列出 3 個）

1. 无限滑动的列表（UITableView / List，需要分页）
2. 可以给推文点赞
3. 可以看到别人评论

## Non-Functional Requirements（列出 2 個）

1. 用户手机离线时，仍可以看之前浏览过的推文吗？
2. Feed 流提示有更新

## Out of Scope

- 登陆功能需要吗？
- 关注功能需要吗？
- 转发功能需要吗？

---
---

# 📝 Coach Feedback（Round 1）

## 整體評價：⭐⭐⭐ (3/5) — 有基礎，但掉進了「iOS 工程師典型陷阱」

你的 Functional Requirements 和 Q3、Q4 不錯，說明你有產品意識。但有幾個關鍵問題需要修正 👇

### 🔴 最大問題：Q1 和 Q2 太 code-level 了

> Q1: 最低支持哪个 iOS 版本? (取决于是用 UIKit 还是 SwiftUI)
> Q2: 偏好什么工程架构？MVVM 还是 TCA？

這正是 `common-interview-mistakes.md` 說的「花太多時間在 UI 層」。System Design 面試**不是在討論 code 怎麼寫**，面試官不在乎你用 MVVM 還是 TCA。

**正確的思路**：問影響「系統」的問題，而不是影響「實作」的問題。例如：
- ✅ 預期有多少用戶？（影響 client 端 Exponential Backoff、caching 策略）
- ✅ 需要支持新興市場嗎？（影響 app 大小、caching 策略、離線能力）
- ✅ 資料更新頻率多高？（影響 pull vs push 的選擇）
- ✅ 資料一致性要求多高？（like 數可以 eventual consistency 嗎？）

### 🟡 Q3 ✅ 好問題

問媒體類型很重要，因為會影響 caching 策略和 network 優化。可以更進一步問：是否需要支持影片？影片是串流還是下載？

### 🟢 Q4 ✅ 最好的一題！

Pull vs Push 的思考是正宗 System Design 思維，而且你提到了 WebSocket 和 SSE，表示你有方案意識 👍

### 🟡 Functional Requirements：方向對，但表述要修正

> 无限滑动的列表（UITableView / List，需要分页）

**不要提 UITableView / List**。面試官聽到這個會覺得你在想 code 而非系統。正確說法：
- ✅「Users can scroll through an infinite list of tweets with pagination」

記住：**Functional Requirement 描述的是「使用者能做什麼」，不是「用什麼元件實作」。**

### 🔴 Non-Functional Requirements：不應該用問句

> 用户手机离线时，仍可以看之前浏览过的推文吗？

NFR 應該是**你做出的決定**，不是問面試官的問題。你應該這樣說：
- ✅「Offline support：使用者在離線時應能瀏覽已快取的推文」（語氣是「我認為這很重要」）

同時你漏了一個重要 NFR：**Resource optimization（最小化頻寬、CPU、電量消耗）**

### 🟡 Out of Scope：語氣要修正

不要用問句「需要嗎？」，而是**直接宣告**：
- ❌「登陆功能需要吗？」
- ✅「Login/Authentication — out of scope for this discussion」

面試官想看到你**有主見、敢做決定**，而不是事事都問他。

### 📌 總結

> **System Design 面試 ≠ 討論 code 怎麼寫。你要跳出「工程師寫 code」的視角，用「架構師設計系統」的視角來思考。**

### ✅ 下一步

嘗試用上面的 feedback 重寫一版，特別注意：
1. 把 Q1、Q2 換成系統層級的問題
2. 補上 Q5
3. Functional / Non-Functional / Out of Scope 都用**陳述句**而非問句
4. 不要提任何 UIKit 元件名稱
