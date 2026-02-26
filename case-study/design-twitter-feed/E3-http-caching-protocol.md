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

注：上表是面试常见“响应头视角”的速查。你贴的 RFC `5.2.1.4 / 5.2.1.5` 属于“请求指令视角”，细节见后面的 Q7。

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
- `URLSession` 能遵循 HTTP 缓存语义处理 `ETag/304`，但要满足前提：
  - `requestCachePolicy` 允许协议缓存（通常 `.useProtocolCachePolicy`）
  - 会话有可用的 `urlCache`
  - 服务端返回正确缓存头（`Cache-Control` / `ETag` / `Last-Modified`）

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

先回答你问的重点：何时用 `Session Level（会话级）`，何时用 `request/task Level（请求或任务级）`？

- 用 `Session Level`：当一整类接口长期共享同一安全策略（如 `payment（支付）`、`profile（个人资料）`、`public content（公共内容）`）。
- 用 `request/task Level`：当只有少数请求需要“临时例外策略”（如某个请求要强制绕过缓存、某个下载是 Range 请求）。
- 实务建议：默认策略放在 Session，例外放在 request/task，避免每个请求都手写安全参数。

Trade-off（权衡取舍）：

| 维度 | Session Level（会话级） | request/task Level（请求或任务级） |
|---|---|---|
| 一致性（Consistency，一致性） | 高：同类请求默认同一策略 | 中：容易漏配，依赖调用方自觉 |
| 灵活性（Flexibility，灵活性） | 中：改动影响整类请求 | 高：可按单请求微调 |
| 维护成本（Maintenance，维护成本） | 低到中：集中配置，长期省心 | 中到高：分散在调用点，易重复 |
| 误用风险（Misconfiguration Risk，错配风险） | 低：策略被“框死” | 高：某次忘记设置就可能泄漏 |
| 资源开销（Resource Overhead，资源开销） | 多 Session 会增加管理复杂度 | 不增 Session，但逻辑分散 |

Alamofire 示例 A（Session Level：按安全级别建 Session，一次配置，多处复用）：

```swift
import Alamofire

let publicSession = Session.default

let privateConfig = URLSessionConfiguration.default
privateConfig.urlCache = nil
privateConfig.requestCachePolicy = .reloadIgnoringLocalCacheData
let privateSession = Session(
    configuration: privateConfig,
    cachedResponseHandler: ResponseCacher.doNotCache
)

let transactionConfig = URLSessionConfiguration.ephemeral
transactionConfig.urlCache = nil
transactionConfig.requestCachePolicy = .reloadIgnoringLocalCacheData
let transactionSession = Session(
    configuration: transactionConfig,
    cachedResponseHandler: ResponseCacher.doNotCache
)
```

Alamofire 示例 B（request/task Level：只对单个请求临时加严）：

```swift
import Alamofire

let headers: HTTPHeaders = [
    "Authorization": "Bearer <token>",
    "Cache-Control": "no-store"
]

publicSession
    .request(
        "https://api.example.com/me",
        headers: headers,
        requestModifier: { request in
            // 覆盖会话默认 cachePolicy（仅此请求）
            request.cachePolicy = .reloadIgnoringLocalCacheData
        }
    )
    // 仅此任务禁缓存（task level）
    .cacheResponse(using: ResponseCacher.doNotCache)
    .validate()
    .responseDecodable(of: ProfileDTO.self) { _ in }
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

### Q7: RFC 里 `no-cache` 与 `no-store`（请求指令）到底差在哪？

你引用的是 **request directive（请求指令）**，重点如下：

1. `Cache-Control: no-cache`（请求）  
   含义：客户端要求“缓存副本在使用前必须先向源站验证”。  
   关键点：**可以存**，但不能未经验证直接拿来回包。
2. `Cache-Control: no-store`（请求）  
   含义：缓存不应存储该请求及其响应（私有/共享缓存都适用）。  
   关键点：规范说的是“`MUST NOT intentionally store` + 尽力尽快清除易失存储”，并非数学意义的 100% 保证。
3. 为什么 RFC 说它“不是可靠或充分的隐私机制”  
   因为恶意/受损缓存可能不遵守，且链路层仍可能被窃听。  
   所以隐私安全仍要依赖 HTTPS、鉴权、最小化敏感数据落盘等整体设计。
4. “如果请求已从缓存命中，`no-store` 不追溯生效”是什么意思  
   如果某个响应在过去已经被存进缓存，这次请求即便带 `no-store`，也不会自动抹掉那份“既有缓存副本”。

Alamofire 示例（请求指令 + 客户端侧强化控制）：

```swift
import Alamofire

// A) no-cache: 可缓存，但使用前必须重验证
AF.request(
    "https://api.example.com/feed",
    headers: ["Cache-Control": "no-cache"]
)

// B) no-store: 请求端表达“不应存储”
//    同时在客户端再加两层保险：忽略本地缓存 + 禁止写回缓存
AF.request(
    "https://api.example.com/payment/confirm",
    headers: ["Cache-Control": "no-store"],
    requestModifier: { $0.cachePolicy = .reloadIgnoringLocalCacheData }
)
.cacheResponse(using: ResponseCacher.doNotCache)
```

面试一句话：`no-cache` 是“先验证再用”，`no-store` 是“不要存”，但隐私安全不能只靠 `no-store`。

### Q8: 在业务代码里，如何观察 `URLSession` 是否缓存命中？

首选方法：看 `URLSessionTaskMetrics` 的 `resourceFetchType`。

- `.localCache`：本地缓存命中
- `.networkLoad`：走网络
- `.serverPush` / `.unknown`：其他情况

`URLSession` 示例（推荐）：

```swift
import Foundation

final class MetricsDelegate: NSObject, URLSessionTaskDelegate {
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didFinishCollecting metrics: URLSessionTaskMetrics) {
        guard let tx = metrics.transactionMetrics.last else { return }
        switch tx.resourceFetchType {
        case .localCache:
            print("cache hit, task=\(task.taskIdentifier)")
        case .networkLoad:
            print("network load, task=\(task.taskIdentifier)")
        case .serverPush:
            print("server push, task=\(task.taskIdentifier)")
        default:
            print("unknown fetch type, task=\(task.taskIdentifier)")
        }
    }
}
```

Alamofire 示例（用 `EventMonitor` 读取同一套 metrics）：

```swift
import Alamofire

final class CacheHitMonitor: EventMonitor {
    let queue = DispatchQueue(label: "cache-hit-monitor")

    func request(_ request: Request, didGatherMetrics metrics: URLSessionTaskMetrics) {
        guard let tx = metrics.transactionMetrics.last else { return }
        switch tx.resourceFetchType {
        case .localCache:
            print("[AF] cache hit: \(request.id)")
        case .networkLoad:
            print("[AF] network: \(request.id)")
        default:
            print("[AF] other: \(request.id)")
        }
    }
}

let session = Session(eventMonitors: [CacheHitMonitor()])
```

补充：`URLCache.cachedResponse(for:)` 只能看“当前缓存里有没有副本”，不等价于“这次请求是否命中缓存”；做埋点请以 `TaskMetrics` 为准。

### Q9: “`Cache-Control: no-cache` 使用前必须重验证”到底是什么意思？为什么我平时几乎不手动设置？

先区分协议里的两个方向：

- **请求头** `Cache-Control: no-cache`：客户端表达“这次请求不要直接用缓存副本，先去源站验证”。
- **响应头** `Cache-Control: ...`：服务端告诉客户端/中间缓存“这个响应可以怎么缓存、缓存多久、何时必须重验证”。

“使用前必须重验证”的 HTTP 流程：

1. 本地缓存里可能已有旧副本。
2. 这次不能直接返回旧副本，需先发条件请求（常见带 `If-None-Match` / `If-Modified-Since`）。
3. 源站返回：
   - `304 Not Modified`：继续使用本地副本；
   - `200 OK + new body`：用新响应覆盖旧缓存。

为什么你日常几乎不手动设请求 `no-cache` 也正常：

- 多数客户端使用 `.useProtocolCachePolicy` 默认策略。
- 缓存行为主要由**服务端响应头**（`Cache-Control` / `ETag` / `Last-Modified`）驱动。
- 所以“不手动加请求 `Cache-Control`”不代表“没用 HTTP 缓存”。

这是否说明服务端没用“HTTP 缓存服务器”？

- 不是。HTTP 缓存是协议语义，可发生在客户端 `URLCache`、代理、CDN 等多层。
- 有无 CDN/反向代理是部署架构问题，不是 HTTP 缓存是否生效的前提。
- 即使没有 CDN，只要服务端响应头正确，`URLSession + URLCache` 一样能缓存与重验证。

Alamofire 示例（仅在“这次必须先验证”时显式加 `no-cache`）：

```swift
import Alamofire

AF.request(
    "https://api.example.com/feed",
    headers: ["Cache-Control": "no-cache"]
).responseData { _ in }
```

面试一句话：请求 `no-cache` 是“这次先验证再用缓存”；日常主要靠服务端响应头驱动缓存，不必每个请求手动加。

### Q10: HTTP 已经有很多缓存机制了，为什么 Kingfisher（KF）这类业务层缓存还有必要？

有必要。两者是互补关系，不是替代关系。

核心区别：

1. HTTP 缓存（协议层）解决“**字节响应**是否可复用”。
2. KF 缓存（业务/图片层）解决“**图片对象与显示成本**如何复用”。

为什么仅靠 HTTP 缓存不够：

- UI 使用的是已解码图片对象（`UIImage`），HTTP 缓存主要存的是响应数据；重复解码仍有 CPU 成本。
- 同一 URL 经过不同处理（圆角、缩略图、下采样）是不同展示结果，KF 可按 `processor key（处理器键）` 区分缓存。
- 业务通常需要更细粒度策略：内存上限、磁盘上限、按场景清理、内存告警清空、预取与回填。
- 有些资源来源不只 HTTP（本地文件、自定义数据源），业务层缓存可统一策略。
- 列表滚动场景中，业务层缓存命中可减少主线程抖动，优化首屏和滑动体验。

推荐实践（面试可直接说）：

- 协议层：用 `HTTP Cache（HTTP 缓存）` 做网络字节级复用与重验证（`ETag/304`）。
- 业务层：用 KF 的 `Memory + Disk` 做图片对象级复用与展示性能优化。
- 结论：`HTTP Cache` 负责“省网路与正确性”，`KF Cache` 负责“省解码与体验稳定性”。

## 学习资源（补课清单）

### Apple 官方

- [URLSessionConfiguration.urlCache](https://developer.apple.com/documentation/foundation/urlsessionconfiguration/urlcache)
- [URLCache.shared](https://developer.apple.com/documentation/foundation/urlcache/shared)
- [URLSessionConfiguration.ephemeral](https://developer.apple.com/documentation/foundation/urlsessionconfiguration/ephemeral)
- [URLSessionConfiguration.requestCachePolicy](https://developer.apple.com/documentation/foundation/urlsessionconfiguration/requestcachepolicy)
- [NSURLRequest.CachePolicy.reloadIgnoringLocalCacheData](https://developer.apple.com/documentation/foundation/nsurlrequest/cachepolicy-swift.enum/reloadignoringlocalcachedata)
- [urlSession(_:dataTask:willCacheResponse:completionHandler:)](https://developer.apple.com/documentation/foundation/urlsessiondatadelegate/urlsession(_:datatask:willcacheresponse:completionhandler:))
- [URLSessionTaskMetrics.ResourceFetchType](https://developer.apple.com/documentation/foundation/urlsessiontaskmetrics/resourcefetchtype)

### HTTP 标准与实战

- [MDN: HTTP Caching](https://developer.mozilla.org/en-US/docs/Web/HTTP/Caching)
- [MDN: ETag](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/ETag)
- [MDN: If-None-Match](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/If-None-Match)
- [MDN: Range Requests](https://developer.mozilla.org/en-US/docs/Web/HTTP/Range_requests)
- [RFC 9111: HTTP Caching](https://www.rfc-editor.org/rfc/rfc9111)
- [RFC 9110: HTTP Semantics (Range / Conditional Requests)](https://www.rfc-editor.org/rfc/rfc9110)
