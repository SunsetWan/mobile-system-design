# 补充：Step 3 System APIs（服务端 API 设计）

## 图中原始 API（函数式表达）

- `postTweet(userToken, string tweet)`
- `deleteTweet(userToken, string tweetId)`
- `likeOrUnlikeTweet(userToken, string tweetId, bool like)`
- `readHomeTimeLine(userToken, int pageSize, opt string pageToken)`
- `readUserTimeline(userToken, int pageSize, opt string pageToken)`

## 面试时建议的 RESTful API（REST 风格 API）

说明：`userToken` 不建议作为入参放在 body/query，通常放在 `Authorization: Bearer <token>` 请求头。

### 1) 发推（postTweet）

- `POST /v1/tweets`

请求体示例：

```json
{
  "text": "hello world",
  "mediaIds": ["m1", "m2"],
  "clientRequestId": "uuid-1234"
}
```

响应示例：

```json
{
  "tweetId": "t_1001",
  "authorId": "u_1",
  "text": "hello world",
  "createdAt": "2026-02-26T12:00:00Z"
}
```

### 2) 删推（deleteTweet）

- `DELETE /v1/tweets/{tweetId}`

响应：`204 No Content`

### 3) 点赞/取消点赞（likeOrUnlikeTweet）

推荐拆成两个幂等（Idempotent，幂等）接口：

- 点赞：`PUT /v1/tweets/{tweetId}/likes/me`
- 取消点赞：`DELETE /v1/tweets/{tweetId}/likes/me`

说明：比 `bool like` 更清晰，也更符合 REST 语义。

### 4) 读首页时间线（readHomeTimeLine）

- `GET /v1/timelines/home?pageSize=20&pageToken=...`

响应示例：

```json
{
  "items": [
    { "tweetId": "t_1001", "authorId": "u_1", "text": "..." }
  ],
  "nextPageToken": "eyJjcmVhdGVkQXQiOiIyMDI2LTAyLTI2VDEyOjAwOjAwWiJ9",
  "hasMore": true
}
```

### 5) 读用户时间线（readUserTimeline）

- `GET /v1/users/{userId}/tweets?pageSize=20&pageToken=...`

说明：

- `pageSize` 控制单页数量。
- `pageToken` 使用游标（Cursor，游标）更适合动态 Feed，避免 Offset 漂移。

## 设计要点（面试可直接说）

1. 鉴权放请求头，不把 `userToken` 放入业务参数。
2. 变更类接口（发推/点赞/取消点赞/删除）优先保证幂等与重试安全。
3. 时间线读取统一使用 `pageSize + pageToken` 分页模式。
4. 首页时间线与用户时间线分开建模，便于后续扩展推荐流与社交关系流。

## 30 秒口述版本

我会把图里的函数式 API 改成 REST 风格：`POST /tweets` 发推、`DELETE /tweets/{id}` 删推、`PUT/DELETE /tweets/{id}/likes/me` 点赞与取消、`GET /timelines/home` 和 `GET /users/{id}/tweets` 做时间线读取。分页统一用 `pageSize + pageToken` 游标模式，`userToken` 放 `Authorization` 头，不放业务参数里。
