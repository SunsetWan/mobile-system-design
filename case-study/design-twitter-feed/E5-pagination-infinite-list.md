# E5 练习：Pagination 基础 — 用 SwiftUI + MVVM 实现 Feed 无限滚动

## 练习目标

在 15-20 分钟内，基于前面 Step 3 API 设计，完成一个可运行的 Home Feed 分页 Demo：

1. 使用 `readHomeTimeline(userToken, pageSize, pageToken)` 思维建模
2. 在 SwiftUI `List` 中实现无限滚动（Infinite Scroll，无限滚动）
3. 用 MVVM 管理分页状态（首屏、加载更多、错误、重试）
4. 默认 `pageSize = 20`

---
---

# 📝 Coach 教学

## E5 的核心

这题重点不是“写一个列表”，而是“把分页状态机写对”。

你要能明确区分：

1. 首次加载（initial load）
2. 下拉刷新（refresh）
3. 向下翻页（load more）
4. 错误重试（retry）

## 本次代码落地点

Xcode 项目路径：

- `/Users/sunset/Documents/Projects/mobile-system-design/case-study/design-twitter-feed/pagenataion/design-twitter-feed/design-twitter-feed`

新增/修改文件：

1. `FeedModels.swift`：`Tweet` / `HomeTimelinePage`
2. `FeedAPI.swift`：`TimelineAPIClient` + `MockTimelineAPIClient`
3. `FeedRepository.swift`：封装 `readHomeTimeline(pageSize:pageToken:)`
4. `FeedViewModel.swift`：分页状态、阈值触发、加载逻辑
5. `ContentView.swift`：SwiftUI 列表与无限滚动触发

## MVVM 分层说明

### Model

- `Tweet`：Feed 行数据
- `HomeTimelinePage`：一次分页响应（`items + nextPageToken + hasMore`）

### ViewModel

`FeedViewModel` 持有这些状态：

- `tweets`：当前列表
- `isLoadingFirstPage`：首屏加载中
- `isLoadingMore`：翻页加载中
- `errorMessage`：错误信息
- `nextPageToken` / `hasMore`：分页游标状态

### View

`ContentView` 用 `List` 渲染，`onAppear` 触发 `loadMoreIfNeeded(currentItem:)`。

## 无限滚动触发策略（当前实现）

- 当当前行进入“末尾前 5 条”阈值时触发下一页加载。
- 并且必须满足：
  1. 还有更多页（`hasMore == true`）
  2. 当前不在加载中（避免重复请求）

## API 设计映射

这次 Demo 对应你前面 Step 3 的接口：

- 目标接口：`readHomeTimeLine(userToken, pageSize, opt string pageToken)`
- Demo 实现：`readHomeTimeline(pageSize: Int = 20, pageToken: String?)`
- `userToken` 在 Demo 里由 `FeedRepository` 内部持有（`demo_user_token`），不暴露给 UI

## ✅ 完成标准（你要检查）

1. 首屏打开会加载第一页（20 条）
2. 向下滚动到底部附近会自动加载下一页
3. 不会重复并发请求同一页
4. 下拉刷新会清空并重新从第一页加载
5. 出错后可以点击 Retry 恢复

## 30 秒口述版本

我用 SwiftUI + MVVM 做了一个 Home Feed 分页 Demo。ViewModel 管理 `tweets`、`isLoadingFirstPage`、`isLoadingMore`、`nextPageToken` 和 `hasMore`。列表在滚到末尾前 5 条时触发 `loadMore`，并用 guard 防止重复请求。API 形态映射到 `readHomeTimeline(pageSize, pageToken)`，默认 pageSize 是 20，支持首屏、刷新、翻页和失败重试。
