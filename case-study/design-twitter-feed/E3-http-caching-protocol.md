# E3 补充：HTTP 缓存协议与安全性（Design Twitter Feed）

## 学习目标

这份文档专门补足 E3 里的 `HTTP Cache（HTTP 缓存）` 知识，帮助你在面试中讲清：

1. `Cache-Control（缓存控制）`、`ETag（实体标签）`、`Last-Modified（最后修改时间）` 的作用
2. `Conditional Request（条件请求）` 与 `304 Not Modified` 的完整链路
3. iOS 端如何用 `URLSession` / `Alamofire` 落地
4. `URLCache` 安全边界与敏感数据防护
5. `HTTP Range Request（字节范围请求）` 与 `.reloadIgnoringLocalCacheData`

## HTTP Cache 三件事（面试最常用）

| Header | 作用 | 面试一句话 |
|---|---|---|
| `Cache-Control` | 控制可用时间与重验证规则 | 决定能不能直接用本地副本 |
| `ETag` + `If-None-Match` | 内容指纹比对 | 没变就回 `304`，省流量 |
| `Last-Modified` + `If-Modified-Since` | 以时间戳判断是否更新 | 时间版条件请求，精度通常不如 `ETag` |

## 先记住 3 种请求结果

1. **直接命中本地缓存（不发网络）**  
   条件：缓存仍在 `fresh（新鲜期）`，例如 `max-age` 未过期。
2. **条件请求（Conditional Request，条件请求）**  
   条件：缓存过期，但本地有 `ETag` 或 `Last-Modified`。  
   结果：
   - 未变化：`304 Not Modified`（通常无 body）
   - 已变化：`200 OK + 新 body`
3. **强制走网络（Network Fetch，网络拉取）**  
   条件：`no-store`、无可用缓存、或策略要求绕过缓存。

## `Cache-Control` 常见指令速查

| 指令 | 含义 | 适用建议 |
|---|---|---|
| `max-age=60` | 60 秒内可直接用缓存 | Feed 列表等可容忍短时旧数据 |
| `no-cache` | 可缓存，但使用前必须重验证 | 想省流量且要确认新鲜度 |
| `no-store` | 不允许存储响应 | 支付、敏感信息、一次性安全数据 |
| `public` | 可被共享缓存（CDN 等）缓存 | 公共静态资源（头像、图片） |
| `private` | 仅终端私有缓存可存 | 与用户身份强相关数据 |
| `must-revalidate` | 过期后必须重验证 | 一致性要求较高的读取接口 |

## `ETag` 最小工作流

```http
# 第一次请求
GET /users/123/avatar
-> 200 OK
ETag: "avatar_v17"
Cache-Control: public, max-age=60
<binary image>

# 下一次（缓存过期后）重验证
GET /users/123/avatar
If-None-Match: "avatar_v17"
-> 304 Not Modified
```

解释：
- `200`：缓存 body，并记录新的 `ETag`。
- `304`：继续使用本地 body，不重复下载。

## 在 Design Twitter Feed 里的实战映射

| 数据类型 | 推荐 HTTP 策略 | 说明 |
|---|---|---|
| 头像/图片（公共） | `public + max-age` +（可选）`ETag` | 建议配合版本化 URL，CDN 友好 |
| Feed 列表 | `private, max-age(短)` + `ETag` | 先快后新，过期后条件请求 |
| 个人资料 | `private, no-cache` + `ETag` | 每次使用前重验证 |
| 支付/余额/库存确认 | `no-store` 或 `must-revalidate` | 强一致优先 |

## iOS 端落地（URLSession / Alamofire）

- `URLSession + URLCache` 在默认策略下可基于 HTTP 头自动处理缓存与重验证。
- `Alamofire` 底层仍是 `URLSession`，优势是工程化能力：`RequestInterceptor（请求拦截器）`、`RetryPolicy（重试策略）`、日志与错误归一。
- 当你要强制 `Network-First（网络优先）`、`stale-if-error（失败回退旧缓存）` 等业务策略时，需在 `Repository（仓储层）` 显式控制。

## Q&A（HTTP 与安全）

### Q1: `ETag` + `If-None-Match` + `304` 的完整流程是什么？

1. 首次请求：服务端返回 `200 + body + ETag`。
2. 客户端缓存 body 与 ETag。
3. 下次请求携带 `If-None-Match: <旧ETag>`。
4. 服务端比对：
   - 未变：`304 Not Modified`
   - 已变：`200 + 新body + 新ETag`
5. 客户端处理：
   - `304`：继续使用本地 body
   - `200`：覆盖本地缓存与 ETag

### Q2: 这套逻辑是 `URLSessionDataTask` 自动处理，还是必须用 `Alamofire`？

- 不必须用 `Alamofire`。
- `URLSession + URLCache` 就能自动处理大量 HTTP 缓存行为。
- `Alamofire` 价值在工程化扩展，不是 HTTP 缓存“唯一入口”。

### Q3: 用户头像适合用 `ETag` 吗？URL 固定还是变化？

适合。两种常见策略：

- 稳定 URL：同一路径长期不变，靠 `ETag` 判新旧。
- 版本化 URL：资源变更即换 URL（如 `?v=42` 或 hash 文件名），更利于 CDN 精准失效。

### 安全性與快取策略

### Q4: 共享 `URLCache.shared` 会泄露数据吗？

结论：部分正确，但常被简化。

- `URLCache.shared` 不是天然不安全。
- 风险来源是“敏感数据被允许落盘缓存”。
- 关键是按数据等级设计缓存策略，不是“一刀切禁用缓存”。

Alamofire 示例（按数据分级创建 Session）：

```swift
import Alamofire

// 公共内容：可使用默认缓存策略（依赖服务端 Cache-Control / ETag）
let publicSession = Session.default

// 敏感内容：临时会话 + 禁用 URLCache
let secureConfig = URLSessionConfiguration.ephemeral
secureConfig.urlCache = nil
secureConfig.requestCachePolicy = .reloadIgnoringLocalCacheData
let secureSession = Session(configuration: secureConfig)
```

### Q5: 敏感数据怎么做更安全？

1. 使用 `ephemeral session（临时会话）`，避免持久化缓存/cookie/凭据落盘。
2. 对敏感会话设置 `configuration.urlCache = nil`。
3. 对敏感请求可用 `.reloadIgnoringLocalCacheData`。
4. 在 `urlSession(_:dataTask:willCacheResponse:completionHandler:)` 返回 `nil`，阻止特定响应进入缓存。

Alamofire 示例（会话级 + 请求级双保险）：

```swift
import Alamofire

let config = URLSessionConfiguration.ephemeral
config.urlCache = nil
config.requestCachePolicy = .reloadIgnoringLocalCacheData

let secureSession = Session(
    configuration: config,
    cachedResponseHandler: ResponseCacher.doNotCache // 等价于 willCacheResponse -> nil
)

let headers: HTTPHeaders = [
    "Authorization": "Bearer <token>",
    "Cache-Control": "no-store"
]

secureSession
    .request(
        "https://api.example.com/me",
        headers: headers,
        requestModifier: { urlRequest in
            urlRequest.cachePolicy = .reloadIgnoringLocalCacheData
        }
    )
    .cacheResponse(using: ResponseCacher.doNotCache) // 仅该请求禁缓存
    .validate()
    .responseDecodable(of: ProfileDTO.self) { response in
        // handle response
    }
```

### Q6: 什么是 `HTTP Range Request（字节范围请求）`？为什么常建议配合 `.reloadIgnoringLocalCacheData`？

`HTTP Range Request（字节范围请求）` 指客户端只请求资源的一段字节，而不是整份文件。

常见场景：
- 断点续传（resume download，续传下载）
- 视频/音频拖动（seek，跳播）
- 大文件分块下载

关键头部：
- 请求：`Range: bytes=1000-1999`
- 响应：`206 Partial Content`
- 响应头：`Content-Range: bytes 1000-1999/123456`

为什么建议 `.reloadIgnoringLocalCacheData`：
- Range 请求对字节偏移极度敏感。
- 若本地缓存版本与服务端不一致，可能发生分片拼接错误、校验失败或内容损坏。
- 强制走网络可降低“拿错字节分片”的风险。

Alamofire 示例（Range 下载）：

```swift
import Alamofire

Session.default
    .request(
        "https://cdn.example.com/video.mp4",
        headers: ["Range": "bytes=1000-1999"],
        requestModifier: { request in
            request.cachePolicy = .reloadIgnoringLocalCacheData
        }
    )
    .cacheResponse(using: ResponseCacher.doNotCache)
    .validate(statusCode: 206..<300)
    .responseData { response in
        // 处理分片数据
    }
```

## 学习资源（补课清单）

### Apple 官方

- [URLSessionConfiguration.urlCache](https://developer.apple.com/documentation/foundation/urlsessionconfiguration/urlcache)
- [URLCache.shared](https://developer.apple.com/documentation/foundation/urlcache/shared)
- [URLSessionConfiguration.ephemeral](https://developer.apple.com/documentation/foundation/urlsessionconfiguration/ephemeral)
- [URLSessionConfiguration.requestCachePolicy](https://developer.apple.com/documentation/foundation/urlsessionconfiguration/requestcachepolicy)
- [NSURLRequest.CachePolicy.reloadIgnoringLocalCacheData](https://developer.apple.com/documentation/foundation/nsurlrequest/cachepolicy-swift.enum/reloadignoringlocalcachedata)
- [urlSession(_:dataTask:willCacheResponse:completionHandler:)](https://developer.apple.com/documentation/foundation/urlsessiondatadelegate/urlsession(_:datatask:willcacheresponse:completionhandler:))

### HTTP 标准与实战

- [MDN: HTTP Caching](https://developer.mozilla.org/en-US/docs/Web/HTTP/Caching)
- [MDN: ETag](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/ETag)
- [MDN: If-None-Match](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/If-None-Match)
- [MDN: Range Requests](https://developer.mozilla.org/en-US/docs/Web/HTTP/Range_requests)
- [RFC 9111: HTTP Caching](https://www.rfc-editor.org/rfc/rfc9111)
- [RFC 9110: HTTP Semantics (Range / Conditional Requests)](https://www.rfc-editor.org/rfc/rfc9110)
