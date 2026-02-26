# Pagination 架构图（SwiftUI + MVVM）

## 1) 组件架构图

```mermaid
flowchart TD
    A["ContentView<br/>SwiftUI List"] --> B["FeedViewModel<br/>@MainActor ObservableObject"]
    B --> C["FeedRepository"]
    C --> D["TimelineAPIClient<br/>Protocol"]
    D --> E["MockTimelineAPIClient<br/>readHomeTimeline"]

    B --> F["State: tweets"]
    B --> G["State: nextPageToken"]
    B --> H["State: hasMore"]
    B --> I["State: isLoadingFirstPage / isLoadingMore"]
    B --> J["State: errorMessage"]

    A -->|onAppear near tail| B
    A -->|pull to refresh| B
```

## 2) 无限滚动时序图

```mermaid
sequenceDiagram
    participant V as ContentView
    participant VM as FeedViewModel
    participant R as FeedRepository
    participant API as TimelineAPIClient

    Note over V,VM: 首次进入页面
    V->>VM: loadInitialIfNeeded()
    VM->>R: readHomeTimeline(pageSize=20, pageToken=nil)
    R->>API: readHomeTimeline(userToken, 20, nil)
    API-->>R: HomeTimelinePage(items, nextPageToken, hasMore)
    R-->>VM: page
    VM-->>V: publish tweets + nextPageToken

    Note over V,VM: 用户滚动到末尾前5条
    V->>VM: loadMoreIfNeeded(currentItem)
    VM->>VM: guard hasMore && !isLoading
    VM->>R: readHomeTimeline(pageSize=20, pageToken=nextPageToken)
    R->>API: readHomeTimeline(userToken, 20, cursor_x)
    API-->>R: next page
    R-->>VM: page
    VM->>VM: append tweets / update token
    VM-->>V: publish updated list

    Note over V,VM: 下拉刷新
    V->>VM: refresh()
    VM->>VM: reset token + hasMore
    VM->>R: readHomeTimeline(pageSize=20, pageToken=nil)
    R-->>VM: first page
    VM-->>V: replace tweets
```

## 3) 触发规则（当前实现）

1. 默认 `pageSize = 20`
2. 当当前 cell 进入末尾前 5 条，触发 `loadMoreIfNeeded`
3. 并发保护：`hasMore && !isLoadingFirstPage && !isLoadingMore`
4. 刷新时重置游标，再从第一页加载

## 4) 错误重试分支时序图

```mermaid
sequenceDiagram
    participant V as ContentView
    participant VM as FeedViewModel
    participant R as FeedRepository
    participant API as TimelineAPIClient

    Note over V,VM: 滚动触发 loadMore
    V->>VM: loadMoreIfNeeded(currentItem)
    VM->>VM: guard hasMore && !isLoading
    VM->>R: readHomeTimeline(pageSize=20, pageToken=nextPageToken)
    R->>API: readHomeTimeline(userToken, 20, cursor_x)
    API--xR: throws error
    R--xVM: error
    VM->>VM: errorMessage = error.localizedDescription
    VM->>VM: isLoadingMore = false
    VM-->>V: render error footer + Retry button

    Note over V,VM: 用户点击 Retry
    V->>VM: retry()
    VM->>R: readHomeTimeline(pageSize=20, pageToken=nextPageToken)
    R->>API: readHomeTimeline(userToken, 20, cursor_x)
    API-->>R: HomeTimelinePage(items, nextPageToken, hasMore)
    R-->>VM: page
    VM->>VM: append tweets / clear errorMessage
    VM-->>V: render updated list
```
