---
title: '[译] fasthttp 文档手册'
date: 2016-10-07 14:00:03
tags:
---

# fasthttp 文档手册

## 常量

```go
const (
    CompressNoCompression      = flate.NoCompression
    CompressBestSpeed          = flate.BestSpeed
    CompressBestCompression    = flate.BestCompression
    CompressDefaultCompression = flate.DefaultCompression
)
```

所支持的压缩级别。
<!-- more -->
```go
const (
    StatusContinue           = 100 // RFC 7231, 6.2.1
    StatusSwitchingProtocols = 101 // RFC 7231, 6.2.2
    StatusProcessing         = 102 // RFC 2518, 10.1

    StatusOK                   = 200 // RFC 7231, 6.3.1
    StatusCreated              = 201 // RFC 7231, 6.3.2
    StatusAccepted             = 202 // RFC 7231, 6.3.3
    StatusNonAuthoritativeInfo = 203 // RFC 7231, 6.3.4
    StatusNoContent            = 204 // RFC 7231, 6.3.5
    StatusResetContent         = 205 // RFC 7231, 6.3.6
    StatusPartialContent       = 206 // RFC 7233, 4.1
    StatusMultiStatus          = 207 // RFC 4918, 11.1
    StatusAlreadyReported      = 208 // RFC 5842, 7.1
    StatusIMUsed               = 226 // RFC 3229, 10.4.1

    StatusMultipleChoices  = 300 // RFC 7231, 6.4.1
    StatusMovedPermanently = 301 // RFC 7231, 6.4.2
    StatusFound            = 302 // RFC 7231, 6.4.3
    StatusSeeOther         = 303 // RFC 7231, 6.4.4
    StatusNotModified      = 304 // RFC 7232, 4.1
    StatusUseProxy         = 305 // RFC 7231, 6.4.5

    StatusTemporaryRedirect = 307 // RFC 7231, 6.4.7
    StatusPermanentRedirect = 308 // RFC 7538, 3

    StatusBadRequest                   = 400 // RFC 7231, 6.5.1
    StatusUnauthorized                 = 401 // RFC 7235, 3.1
    StatusPaymentRequired              = 402 // RFC 7231, 6.5.2
    StatusForbidden                    = 403 // RFC 7231, 6.5.3
    StatusNotFound                     = 404 // RFC 7231, 6.5.4
    StatusMethodNotAllowed             = 405 // RFC 7231, 6.5.5
    StatusNotAcceptable                = 406 // RFC 7231, 6.5.6
    StatusProxyAuthRequired            = 407 // RFC 7235, 3.2
    StatusRequestTimeout               = 408 // RFC 7231, 6.5.7
    StatusConflict                     = 409 // RFC 7231, 6.5.8
    StatusGone                         = 410 // RFC 7231, 6.5.9
    StatusLengthRequired               = 411 // RFC 7231, 6.5.10
    StatusPreconditionFailed           = 412 // RFC 7232, 4.2
    StatusRequestEntityTooLarge        = 413 // RFC 7231, 6.5.11
    StatusRequestURITooLong            = 414 // RFC 7231, 6.5.12
    StatusUnsupportedMediaType         = 415 // RFC 7231, 6.5.13
    StatusRequestedRangeNotSatisfiable = 416 // RFC 7233, 4.4
    StatusExpectationFailed            = 417 // RFC 7231, 6.5.14
    StatusTeapot                       = 418 // RFC 7168, 2.3.3
    StatusUnprocessableEntity          = 422 // RFC 4918, 11.2
    StatusLocked                       = 423 // RFC 4918, 11.3
    StatusFailedDependency             = 424 // RFC 4918, 11.4
    StatusUpgradeRequired              = 426 // RFC 7231, 6.5.15
    StatusPreconditionRequired         = 428 // RFC 6585, 3
    StatusTooManyRequests              = 429 // RFC 6585, 4
    StatusRequestHeaderFieldsTooLarge  = 431 // RFC 6585, 5
    StatusUnavailableForLegalReasons   = 451 // RFC 7725, 3

    StatusInternalServerError           = 500 // RFC 7231, 6.6.1
    StatusNotImplemented                = 501 // RFC 7231, 6.6.2
    StatusBadGateway                    = 502 // RFC 7231, 6.6.3
    StatusServiceUnavailable            = 503 // RFC 7231, 6.6.4
    StatusGatewayTimeout                = 504 // RFC 7231, 6.6.5
    StatusHTTPVersionNotSupported       = 505 // RFC 7231, 6.6.6
    StatusVariantAlsoNegotiates         = 506 // RFC 2295, 8.1
    StatusInsufficientStorage           = 507 // RFC 4918, 11.5
    StatusLoopDetected                  = 508 // RFC 5842, 7.2
    StatusNotExtended                   = 510 // RFC 2774, 7
    StatusNetworkAuthenticationRequired = 511 // RFC 6585, 6
)
```

与 net/http 相同的 HTTP 状态吗。

```go
const DefaultConcurrency = 256 * 1024
```

`DefaultConcurrency` 为默认情况下（没有设置 `Server.Concurrency` 时）服务器可以接受的最大并发请求数。

```go
const DefaultDNSCacheDuration = time.Minute
```

`DefaultDNSCacheDuration` 是由 `Dial*` 函数族缓存处理过的 TCP 地址的持续时间。

```go
const DefaultDialTimeout = 3 * time.Second
```

`DefaultDialTimeout` 是由 `Dial` 和 `DialDualStack` 使用的用于建立 TCP 连接的超时时间。

```go
const DefaultMaxConnsPerHost = 512
```

`DefaultMaxConnsPerHost` 是 http 客户端在默认情况下（如果没有设置 `Client.MaxConnsPerHost`）单个 host 可以建立的最大并发连接数。

```go
const DefaultMaxIdleConnDuration = 10 * time.Second
```

`DefaultMaxIdleConnDuration` 是在空闲的 keep-alive 连接被关闭前默认的持续时间。

```go
const DefaultMaxPendingRequests = 1024
```

`DefaultMaxPendingRequests` 是 `PipelineClient.MaxPendingRequests` 的默认值。

```go
const DefaultMaxRequestBodySize = 4 * 1024 * 1024
```

`DefaultMaxRequestBodySize` 是服务器默认可读的最大请求体大小。

更多详情请参阅 `Server.MaxRequestBodySize` 。

```go
const FSCompressedFileSuffix = ".fasthttp.gz"
```

`FSCompressedFileSuffix` 是当需要使用新文件名存储被压缩后的文件时， `FS` 在原始文件名上添加的前缀。更多详情请参阅 `FS.Compress` 。

```go
const FSHandlerCacheDuration = 10 * time.Second
```

`FSHandlerCacheDuration` 是由 `FS` 所打开的非活跃文件句柄的默认失效时间。

## 变量

```go
var (
    // ErrNoFreeConns 在当特定的 host 没有可用的连接时返回。
    //
    // 如果你看到了这个错误，你可以选择调高每个 host 可用的连接数。
    ErrNoFreeConns = errors.New("no free connections available to host")

    // ErrTimeout 在调用超时时返回。
    ErrTimeout = errors.New("timeout")

    // ErrConnectionClosed 会在当服务端在返回第一个相应字节前被关闭时，
    // 于客户端方法中返回。
    //
    // 如果你看到了这个错误，你可以在服务端关闭连接前通过 `'Connection: close'` 相应头
    // 来修复这个错误，或者在客户端发送请求前添加 `'Connection: close'` 请求头。
    ErrConnectionClosed = errors.New("the server closed connection before returning the first response byte. " +
        "Make sure the server returns 'Connection: close' response header before closing the connection")
)
```

```go
var (
    // CookieExpireDelete 可以会被支持于 `Cookie.Expire` 中，用于为指定
    // cookie 添加过期。
    CookieExpireDelete = time.Date(2009, time.November, 10, 23, 0, 0, 0, time.UTC)

    // CookieExpireUnlimited 用于表明该 cookie 不会过期。
    CookieExpireUnlimited = zeroTime
)
```

```go
var (
    // ErrPerIPConnLimit 会在任一 ip 连接数超过 Server.MaxConnsPerIP 时
    // 由 ServeConn 返回。
    ErrPerIPConnLimit = errors.New("too many connections per ip")

    // ErrConcurrencyLimit 会在并发连接数超过 Server.Concurrency 时由
    // ServeConn 返回。
    ErrConcurrencyLimit = errors.New("canot serve the connection because Server.Concurrency concurrent connections are served")

    // ErrKeepaliveTimeout 会在连接的时长超过 MaxKeepaliveDuration 时
    // 由 ServeConn 返回。
    ErrKeepaliveTimeout = errors.New("exceeded MaxKeepaliveDuration")
)
```

```go
var ErrBodyTooLarge = errors.New("body size exceeds the given limit")
```

`ErrBodyTooLarge` 会在请求体或者响应体超过指定限制时返回。

```go
var ErrDialTimeout = errors.New("dialing to the given TCP address timed out")
```

`ErrDialTimeout` 会在 TCP 握手超时时触发。

```go
var ErrMissingFile = errors.New("there is no uploaded file associated with the given key")
```

`ErrMissingFile` 会在没有与指定的 `multipart` 表单键相关联的被上传文件时由 `FormFile` 返回。

```go
var ErrNoArgValue = errors.New("no Args value for the given key")
```

`ErrNoArgValue` 会在指定 `Args` 键缺少值时返回。

```go
var ErrNoMultipartForm = errors.New("request has no multipart/form-data Content-Type")
```

`ErrNoMultipartForm` 意味着请求的 `Content-Type` 不是 `'multipart/form-data'` 。

```go
var ErrPipelineOverflow = errors.New("pipelined requests' queue has been overflown. Increase MaxConns and/or MaxPendingRequests")
```

`ErrPipelineOverflow` 会在请求的队列溢出时，由 `PipelineClient.Do*` 函数族返回。

### func AppendBytesStr

```go
func AppendBytesStr(dst []byte, src string) []byte
```

`AppendBytesStr` 向 `dst` 追加 `src` ，并且返回追加后的 `dst` 。

这个函数与 `append(dst, src...)` 的性能没有差别。目前它仅用于向后兼容。

这个函数已经弃用并且可能很快被移除。

### func AppendGunzipBytes

```go
func AppendGunzipBytes(dst, src []byte) ([]byte, error)
```

`AppendGunzipBytes` 向 `dst` 追加 gunzip 压缩后的 `src` ，并且返回追加后的 `dst` 。

### func AppendGzipBytes

```go
func AppendGzipBytes(dst, src []byte) []byte
```

`AppendGzipBytes` 向 `dst` 追加 gzip 压缩后的 `src` ，并且返回追加后的 `dst` 。

### func AppendGzipBytesLevel

```go
func AppendGzipBytesLevel(dst, src []byte, level int) []byte
```

`AppendGzipBytesLevel` 向 `dst` 追加指定级别的 gzip 压缩后的 `src` ，并且返回追加后的 `dst` 。

支持的压缩级别有：

- `CompressNoCompression`
- `CompressBestSpeed`
- `CompressBestCompression`
- `CompressDefaultCompression`

### func AppendHTMLEscape

```go
func AppendHTMLEscape(dst []byte, s string) []byte
```

`AppendHTMLEscape` 向 `dst` 追加 HTML 转义后的 `src` ，并且返回追加后的 `dst` 。

### func AppendHTMLEscapeBytes

```go
func AppendHTMLEscapeBytes(dst, s []byte) []byte
```

`AppendHTMLEscapeBytes` 向 `dst` 追加 HTML 转义后的 `src` ，并且返回追加后的 `dst` 。

### func AppendHTTPDate

```go
func AppendHTTPDate(dst []byte, date time.Time) []byte
```

`AppendHTTPDate` 向 `dst` 追加符合 HTTP-compliant (RFC1123) 表示的时间 ，并且返回追加后的 `dst` 。

### func AppendIPv4

```go
func AppendIPv4(dst []byte, ip net.IP) []byte
```

`AppendIPv4` 向 `dst` 追加表示 ip v4 的字符串 ，并且返回追加后的 `dst` 。

### func AppendNormalizedHeaderKey

```go
func AppendNormalizedHeaderKey(dst []byte, key string) []byte
```

`AppendNormalizedHeaderKey` 向 `dst` 追加标准化后的 HTTP 头键（名），并且返回追加后的 `dst` 。

标准化后的头键由一个大写字母开头。在 `-` 后的第一个字母也为大写。其他的所有字母则都为小写。例子：


- coNTENT-TYPe -> Content-Type
- HOST -> Host
- foo-bar-baz -> Foo-Bar-Baz

### func AppendNormalizedHeaderKeyBytes

```go
func AppendNormalizedHeaderKeyBytes(dst, key []byte) []byte
```

`AppendNormalizedHeaderKeyBytes` 向 `dst` 追加标准化后的 HTTP 头键（名），并且返回追加后的 `dst` 。

标准化后的头键由一个大写字母开头。在 `-` 后的第一个字母也为大写。其他的所有字母则都为小写。例子：

- coNTENT-TYPe -> Content-Type
- HOST -> Host
- foo-bar-baz -> Foo-Bar-Baz

### func AppendQuotedArg

```go
func AppendQuotedArg(dst, src []byte) []byte
```

`AppendQuotedArg` 向 `dst` 追加经过 url 加密的 `src` ，并且返回追加后的 `dst` 。

### func AppendUint

```go
func AppendUint(dst []byte, n int) []byte
```

`AppendUint` 向 `dst` 追加 `n`，并且返回追加后的 `dst` 。

### func Dial

```go
func Dial(addr string) (net.Conn, error)
```

`Dial` 使用 tcp4 连接指定的 TCP 地址 `addr` 。

与 `net.Dial` 相比，该函数有以下这些额外的特性：

- 它通过以 `DefaultDNSCacheDuration` 持续时间缓存解析后的 TCP 地址来减少 DNS 解析器的负载。
- 它通过轮询来连接所有被解析后的 TCP 连接，直至第一个连接被建立。这在当其中的某一个 TCP 地址临时性不可用时相当有用。
- 在 `DefaultDialTimeout` 秒之后若连接还没有被建立，它会返回 `ErrDialTimeout` ，可以使用 `DialTimeout` 来自定义这个超时。

`addr` 参数必须包含端口，例如：

- `foobar.baz:443`
- `foo.bar:80`
- `aaa.com:8080`

### func DialDualStack

```go
func DialDualStack(addr string) (net.Conn, error)
```

`DialDualStack` 使用 tcp4 和 tcp6 连接指定的 TCP 地址 `addr` 。

与 `net.Dial` 相比，该函数有以下这些额外的特性：

- 它通过以 `DefaultDNSCacheDuration` 持续时间缓存解析后的 TCP 地址来减少 DNS 解析器的负载。
- 它通过轮询来连接所有被解析后的 TCP 连接，直至第一个连接被建立。这在当其中的某一个 TCP 地址临时性不可用时相当有用。
- 在 `DefaultDialTimeout` 秒之后若连接还没有被建立，它会返回 `ErrDialTimeout` ，可以使用 `DialTimeout` 来自定义这个超时。

`addr` 参数必须包含端口，例如：

- `foobar.baz:443`
- `foo.bar:80`
- `aaa.com:8080`

### func DialDualStackTimeout

```go
func DialDualStackTimeout(addr string, timeout time.Duration) (net.Conn, error)
```

`DialDualStackTimeout` 使用 tcp4 和 tcp6 连接指定的 TCP 地址 `addr` ，并且会在指定时间后超时。

与 `net.Dial` 相比，该函数有以下这些额外的特性：

- 它通过以 `DefaultDNSCacheDuration` 持续时间缓存解析后的 TCP 地址来减少 DNS 解析器的负载。
- 它通过轮询来连接所有被解析后的 TCP 连接，直至第一个连接被建立。这在当其中的某一个 TCP 地址临时性不可用时相当有用。
- 在 `DefaultDialTimeout` 秒之后若连接还没有被建立，它会返回 `ErrDialTimeout` ，可以使用 `DialTimeout` 来自定义这个超时。

`addr` 参数必须包含端口，例如：

- `foobar.baz:443`
- `foo.bar:80`
- `aaa.com:8080`

### func DialTimeout

```go
func DialTimeout(addr string, timeout time.Duration) (net.Conn, error)
```

`DialTimeout` 使用 tcp4 和 tcp6 连接指定的 TCP 地址 `addr` ，并且会在指定时间后超时。

与 `net.Dial` 相比，该函数有以下这些额外的特性：

- 它通过以 `DefaultDNSCacheDuration` 持续时间缓存解析后的 TCP 地址来减少 DNS 解析器的负载。
- 它通过轮询来连接所有被解析后的 TCP 连接，直至第一个连接被建立。这在当其中的某一个 TCP 地址临时性不可用时相当有用。
- 在 `DefaultDialTimeout` 秒之后若连接还没有被建立，它会返回 `ErrDialTimeout` ，可以使用 `DialTimeout` 来自定义这个超时。

`addr` 参数必须包含端口，例如：

- `foobar.baz:443`
- `foo.bar:80`
- `aaa.com:8080`

### func Do

```go
func Do(req *Request, resp *Response) error
```

`Do` 发出指定的 http 请求，在得到响应后并且填充指定的 http 响应对象。

请求必须至少包含一个非空的 RequestURI （包含协议和 host）或非空的 Host 头 + RequestURI。

客户端以以下顺序确定待请求的服务端：

- 如果 RequestURI 包含完整的带有协议和 host 的 url ，则从 RequestURI 中取得。
- 否则就从 Host 头中取得。

这个函数不会跟随重定向。若要跟随重定向，请使用 `Get*` 。

如果 `resp` 是 `nil` ，那么响应会被忽略。

如果向指定请求 host 的所有 `DefaultMaxConnsPerHost` 数量的连接都被占用，那么会返回 `ErrNoFreeConns`。

在有性能要求的代码中，推荐通过 `AcquireRequest` 和 `AcquireResponse` 来获取 `req` 和 `resp` 。

### func DoDeadline

```go
func DoDeadline(req *Request, resp *Response, deadline time.Time) error
```

`DoDeadline` 发出指定的 http 请求，并且在指定的 deadline 之前得到响应后填充指定的 http 响应对象。

请求必须至少包含一个非空的 RequestURI （包含协议和 host）或非空的 Host 头 + RequestURI。

客户端以以下顺序确定待请求的服务端：

- 如果 RequestURI 包含完整的带有协议和 host 的 url ，则从 RequestURI 中取得。
- 否则就从 Host 头中取得。

这个函数不会跟随重定向。若要跟随重定向，请使用 `Get*` 。

如果 `resp` 是 `nil` ，那么响应会被忽略。

如果向指定请求 host 的所有 `DefaultMaxConnsPerHost` 数量的连接都被占用，那么会返回 `ErrNoFreeConns`。

在有性能要求的代码中，推荐通过 `AcquireRequest` 和 `AcquireResponse` 来获取 `req` 和 `resp` 。

### func DoTimeout

```go
func DoTimeout(req *Request, resp *Response, timeout time.Duration) error
```

`DoTimeout` 发出指定的 http 请求，并且在指定的超时之前得到响应后填充指定的 http 响应对象。

请求必须至少包含一个非空的 RequestURI （包含协议和 host）或非空的 Host 头 + RequestURI。

客户端以以下顺序确定待请求的服务端：

- 如果 RequestURI 包含完整的带有协议和 host 的 url ，则从 RequestURI 中取得。
- 否则就从 Host 头中取得。

这个函数不会跟随重定向。若要跟随重定向，请使用 `Get*` 。

如果 `resp` 是 `nil` ，那么响应会被忽略。

如果向指定请求 host 的所有 `DefaultMaxConnsPerHost` 数量的连接都被占用，那么会返回 `ErrNoFreeConns`。

在有性能要求的代码中，推荐通过 `AcquireRequest` 和 `AcquireResponse` 来获取 `req` 和 `resp` 。

### func EqualBytesStr

```go
func EqualBytesStr(b []byte, s string) bool
```

`EqualBytesStr`，在 `string(b) == s` 时返回 `true`。

这个函数与 `string(b) == s` 的性能没有差别。目前它仅用于向后兼容。

这个函数已经弃用并且可能很快被移除。

### func FileLastModified

```go
func FileLastModified(path string) (time.Time, error)
```

`FileLastModified` 返回文件的最后修改时间。

### func Get

```go
func Get(dst []byte, url string) (statusCode int, body []byte, err error)
```

`Get` 向 `dst` 追加 url 信息，并且通过 `body` 返回它。

这个函数会跟随重定向。若要手动操作重定向，请使用 `Do*` 。

如果 `dst` 为 `nil` ，那么则会分配一个新的 `body` 缓冲。

### func GetDeadline

```go
func GetDeadline(dst []byte, url string, deadline time.Time) (statusCode int, body []byte, err error)
```

`GetDeadline` 向 `dst` 追加 url 信息，并且通过 `body` 返回它。

这个函数会跟随重定向。若要手动操作重定向，请使用 `Do*` 。

如果 `dst` 为 `nil` ，那么则会分配一个新的 `body` 缓冲。

若在指定的 deadline 之前没能获取到响应，那么会返回 `ErrTimeout` 。

### func GetTimeout

```go
func GetTimeout(dst []byte, url string, timeout time.Duration) (statusCode int, body []byte, err error)
```

`GetTimeout` 向 `dst` 追加 url 信息，并且通过 `body` 返回它。

这个函数会跟随重定向。若要手动操作重定向，请使用 `Do*` 。

如果 `dst` 为 `nil` ，那么则会分配一个新的 `body` 缓冲。

若在指定的超时之前没能获取到响应，那么会返回 `ErrTimeout` 。

### func ListenAndServe

```go
func ListenAndServe(addr string, handler RequestHandler) error
```

`ListenAndServe` 使用指定的 `handler` 处理来自指定 TCP 地址 `addr` 的 HTTP 请求。

例子：

```go
// 这个服务器会监听所有来自该地址的请求
listenAddr := "127.0.0.1:80"

// 当每个请求到来时，这个函数都将被调用。
// RequestCtx 提供了很多有用的处理 http 请求的方法。更多详情请参阅 RequestCtx 说明。
requestHandler := func(ctx *fasthttp.RequestCtx) {
    fmt.Fprintf(ctx, "Hello, world! Requested path is %q", ctx.Path())
}

// 使用默认设置启动服务器。
// 创建服务器实例。
//
// ListenAndServe 只返回一个错误，所以它通常是永久阻塞的。
if err := fasthttp.ListenAndServe(listenAddr, requestHandler); err != nil {
    log.Fatalf("error in ListenAndServe: %s", err)
}
```

### func ListenAndServeTLS

```go
func ListenAndServeTLS(addr, certFile, keyFile string, handler RequestHandler) error
```

`ListenAndServeTLS` 使用指定的 `handler` 处理来自指定 TCP 地址 `addr` 的 HTTPS 请求。

`certFile` 和 `keyFile` 是 TLS 证书和密钥文件的路径。

### func ListenAndServeTLSEmbed

```go
func ListenAndServeTLSEmbed(addr string, certData, keyData []byte, handler RequestHandler) error
```

`ListenAndServeTLSEmbed` 使用指定的 `handler` 处理来自指定 TCP 地址 `addr` 的 HTTPS 请求。

`certData` 和 `keyData` 必须包含合法的 TLS 证书和密钥数据。

### func ListenAndServeUNIX

```go
func ListenAndServeUNIX(addr string, mode os.FileMode, handler RequestHandler) error
```

`ListenAndServeUNIX` 使用指定的 `handler` 处理来自指定 UNIX 地址 `addr` 的 HTTP 请求。

这个函数会在开始接受请求前删除所有 `addr` 下的文件。

该函数会为制定 UNIX 地址 `addr` 设置参数中指定的 `mode` 。

### func NewStreamReader

```go
func NewStreamReader(sw StreamWriter) io.ReadCloser
```

`NewStreamReader` 返回一个 `reader` ，用于获取所有由 `sw` 生成的数据。

返回的 `reader` 可以被传递至 `Response.SetBodyStream` 。

在返回的 `reader` 中所有的数据都被读取完毕之后，必须调用 `Close` 。否则可能会造成 goroutine 泄露。

更多详情可参阅 `Response.SetBodyStreamWriter` 。

### func ParseByteRange

```go
func ParseByteRange(byteRange []byte, contentLength int) (startPos, endPos int, err error)
```

`ParseByteRange` 用于解释 `'Range: bytes=...'` 头的值。

依据的规范是 https://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.35 。

### func ParseHTTPDate

```go
func ParseHTTPDate(date []byte) (time.Time, error)
```

`ParseHTTPDate` 用于解释符合 HTTP-compliant (RFC1123) 规范的时间。

### func ParseIPv4

```go
func ParseIPv4(dst net.IP, ipStr []byte) (net.IP, error)
```

`ParseIPv4` 解释 `ipStr` 提供的 ip 地址，并填充 `dst` ，然后返回填充后的 `dst` 。

### func ParseUfloat

```go
func ParseUfloat(buf []byte) (float64, error)
```

`ParseUfloat` 解释 `buf` 提供的无符号浮点数。

### func ParseUint

```go
func ParseUint(buf []byte) (int, error)
```

`ParseUint` 解释 `buf` 提供的无符号整型数。

### func Post

```go
func Post(dst []byte, url string, postArgs *Args) (statusCode int, body []byte, err error)
```

`Post` 使用指定 POST 参数向指定 `url` 发出 POST 请求。

请求体会追加值 `dst` ，并且通过 `body` 返回。

这个函数会跟随重定向。若要手动操作重定向，请使用 `Do*` 。

若 `dst` 是 `nil` ，那么新的 `body` 缓冲会被分配。

如果 `postArgs` 是 `nil` ，则发送空 POST 请求体。

### func ReleaseArgs

```go
func ReleaseArgs(a *Args)
```

`ReleaseArgs` 向池中释放通过 `AquireArgs` 取得的对象。

不要试图访问释放的 `Args` 对象，可能会产生数据竞争。

### func ReleaseByteBuffer

```go
func ReleaseByteBuffer(b *ByteBuffer)
```

`ReleaseByteBuffer` 返回池中释放指定字节缓冲。

在释放回池之后， `ByteBuffer.B` 不能再被访问，可能会产生数据竞争。

### func ReleaseCookie

```go
func ReleaseCookie(c *Cookie)
```

`ReleaseCookie` 向池中释放由 `AcquireCookie` 返回的对象。

不要试图访问释放的 `Cookie` 对象，可能会产生数据竞争。

### func ReleaseRequest

```go
func ReleaseRequest(req *Request)
```

`ReleaseRequest` 向池中释放由 `AcquireRequest` 返回的对象。

在释放回池之后，禁止再访问 `req` 对象以及它的任何成员。

### func ReleaseResponse

```go
func ReleaseResponse(resp *Response)
```

`ReleaseResponse` 向池中释放由 `AcquireResponse` 返回的对象。

在释放回池之后，禁止再访问 `resp` 对象以及它的任何成员。

### func ReleaseURI

```go
func ReleaseURI(u *URI)
```

`ReleaseURI` 向池中释放由 `AcquireURI` 返回的对象。

不要试图访问释放的 `URI` 对象，可能会产生数据竞争。

### func SaveMultipartFile

```go
func SaveMultipartFile(fh *multipart.FileHeader, path string) error
```

`SaveMultipartFile` 在指定的 `path` 下保存文件 `fh` 。

### func Serve

```go
func Serve(ln net.Listener, handler RequestHandler) error
```

`Serve` 使用指定的 `handler` 来处理来自 `listener` 的连接。

在 `listener` 返回永久性的错误之前， `Serve` 都会一直保持阻塞。

例子：

```go
// 创建一个接受请求的 listener
//
// 你不仅可以创建 TCP listener - 任意的 net.Listener 都可以。
// 例如 UNIX Socket 或 TLS listener 。

ln, err := net.Listen("tcp4", "127.0.0.1:8080")
if err != nil {
    log.Fatalf("error in net.Listen: %s", err)
}

// 当每个请求到来时，这个函数都将被调用。
// RequestCtx 提供了很多有用的处理 http 请求的方法。更多详情请参阅 RequestCtx 说明。
requestHandler := func(ctx *fasthttp.RequestCtx) {
    fmt.Fprintf(ctx, "Hello, world! Requested path is %q", ctx.Path())
}

// 使用默认设置启动服务器。
// 创建服务器实例。
//
// Serve 在 ln.Close() 或发生错误时返回，所以它通常是永久阻塞的。
if err := fasthttp.Serve(ln, requestHandler); err != nil {
    log.Fatalf("error in Serve: %s", err)
}
```

### func ServeConn

```go
func ServeConn(c net.Conn, handler RequestHandler) error
```

`ServeConn` 使用指定的 `handler` 处理来自指定连接的 HTTP 请求。

如果所有来自 `c` 的请求都被成功处理，`ServeConn` 会返回 `nil` 。否则返回一个非空错误。

连接 `c` 必须立刻将所有数据通过 `Write()` 发送至客户端，否则请求的处理可能会被挂起。

`ServeConn` 在返回之前会关闭 `c` 。

### func ServeFile

```go
func ServeFile(ctx *RequestCtx, path string)
```

`ServeFile` 返回来自指定 `path` 的压缩后文件内容的 HTTP 响应。

在以下情况下，HTTP 响应可能会包含未压缩文件内容：

- 缺少 `'Accept-Encoding: gzip'` 请求头。
- 没有对文件目录的写权限。

如果 `path` 指向一个目录，那么目录的内容会被返回。

如果你不需要响应压缩后的文件内容，请使用 `ServeFileUncompressed` 。

更多详情可参阅 `RequestCtx.SendFile` 。

### func ServeFileBytes

```go
func ServeFileBytes(ctx *RequestCtx, path []byte)
```

`ServeFileBytes` 返回来自指定 `path` 的压缩后文件内容的 HTTP 响应。

在以下情况下，HTTP 响应可能会包含未压缩文件内容：

- 缺少 `'Accept-Encoding: gzip'` 请求头。
- 没有对文件目录的写权限。

如果 `path` 指向一个目录，那么目录的内容会被返回。

如果你不需要响应压缩后的文件内容，请使用 `ServeFileUncompressed` 。

更多详情可参阅 `RequestCtx.SendFile` 。

### func ServeFileBytesUncompressed

```go
func ServeFileBytesUncompressed(ctx *RequestCtx, path []byte)
```

`ServeFileBytesUncompressed` 返回来自指定 `path` 文件内容的 HTTP 响应。

如果 `path` 指向一个目录，那么目录的内容会被返回。

若需要处理压缩后的文件，请使用 `ServeFileBytes` 。

更多详情可参阅 `RequestCtx.SendFileBytes` 。

### func ServeFileUncompressed

```go
func ServeFileUncompressed(ctx *RequestCtx, path string)
```

`ServeFileUncompressed` 返回来自指定 `path` 文件内容的 HTTP 响应。

如果 `path` 指向一个目录，那么目录的内容会被返回。

若需要处理压缩后的文件，请使用 `ServeFile` 。

更多详情可参阅 `RequestCtx.SendFile` 。

### func ServeTLS

```go
func ServeTLS(ln net.Listener, certFile, keyFile string, handler RequestHandler) error
```

`ServeTLS` 使用指定的 `handler` 来处理来自指定 `net.Listener` 的 HTTPS 请求。

`certFile` 和 `keyFile` 是 TLS 证书和密钥文件的路径。

### func ServeTLSEmbed

```go
func ServeTLSEmbed(ln net.Listener, certData, keyData []byte, handler RequestHandler) error
```

`ServeTLSEmbed` 使用指定的 `handler` 来处理来自指定 `net.Listener` 的 HTTPS 请求。

`certData` 和 `keyData` 必须包含合法的 TLS 证书和密钥数据。

### func StatusMessage

```go
func StatusMessage(statusCode int) string
```

`StatusMessage` 根据指定的状态码返回 HTTP 状态信息。

### func WriteGunzip

```go
func WriteGunzip(w io.Writer, p []byte) (int, error)
```

`WriteGunzip` 向 `w` 写入经 gunzip 压缩的 `p` ，并且返回未压缩的字节数。

### func WriteGzip

```go
func WriteGzip(w io.Writer, p []byte) (int, error)
```

`WriteGunzip` 向 `w` 写入经 gzip 压缩的 `p` ，并且返回未压缩的字节数。

### func WriteGzipLevel

```go
func WriteGzipLevel(w io.Writer, p []byte, level int) (int, error)
```

`WriteGunzip` 向 `w` 写入经指定级别 gzip 压缩的 `p` ，并且返回未压缩的字节数。

支持的压缩级别有：

- `CompressNoCompression`
- `CompressBestSpeed`
- `CompressBestCompression`
- `CompressDefaultCompression`

### func WriteInflate

```go
func WriteInflate(w io.Writer, p []byte) (int, error)
```

`WriteGunzip` 向 `w` 写入压缩后的 `p` ，并且返回未压缩的字节数。

### func WriteMultipartForm

```go
func WriteMultipartForm(w io.Writer, f *multipart.Form, boundary string) error
```

`WriteMultipartForm` 使用指定的 `w` 写入指定的表单 `f` 。

### type Args

```go
type Args struct {
    // 包含被过滤或未导出的属性
}
```

`Args` 代表查询字符串参数。

拷贝 `Args` 实例是禁止的。你需要使用 `CopyTo()` 函数或创建一个新实例。

`Args` 实例必须不能在并发执行的 goroutine 间使用。

#### func AcquireArgs

```go
func AcquireArgs() *Args
```

`AcquireArgs` 从池中返回一个空的 `Args` 对象。

返回的 `Args` 实例在不再需要时可以通过 `ReleaseArgs` 释放回池。这可以降低垃圾回收负载。

#### func (*Args) Add

```go
func (a *Args) Add(key, value string)
```

`Add` 添加 `'key=value'` 参数。

同一个 `key` 可以添加多个值。

#### func (*Args) AddBytesK

```go
func (a *Args) AddBytesK(key []byte, value string)
```

`AddBytesK` 添加 `'key=value'` 参数。

同一个 `key` 可以添加多个值。

#### func (*Args) AddBytesKV

```go
func (a *Args) AddBytesKV(key, value []byte)
```

`AddBytesKV` 添加 `'key=value'` 参数。

同一个 `key` 可以添加多个值。

#### func (*Args) AddBytesV

```go
func (a *Args) AddBytesV(key string, value []byte)
```

`AddBytesV` 添加 `'key=value'` 参数。

同一个 `key` 可以添加多个值。

#### func (*Args) AppendBytes

```go
func (a *Args) AppendBytes(dst []byte) []byte
```

`AppendBytes` 像 `dst` 追加查询字符串，并返回 `dst` 。

#### func (*Args) CopyTo

```go
func (a *Args) CopyTo(dst *Args)
```

`CopyTo` 将所有的参数复制至 `dst` 。

#### func (*Args) Del

```go
func (a *Args) Del(key string)
```

`Del` 删除键为指定 `key` 的参数。

#### func (*Args) DelBytes

```go
func (a *Args) DelBytes(key []byte)
```

`Del` 删除键为指定 `key` 的参数。

#### func (*Args) GetUfloat

```go
func (a *Args) GetUfloat(key string) (float64, error)
```

`GetUfloat` 返回指定 `key` 的无符号浮点数值。

#### func (*Args) GetUfloatOrZero

```go
func (a *Args) GetUfloatOrZero(key string) float64
```

`GetUfloatOrZero` 返回指定 `key` 的无符号浮点数值。

当出错时返回 `0` 。

#### func (*Args) GetUint

```go
func (a *Args) GetUint(key string) (int, error)
```

`GetUint` 返回指定 `key` 的无符号整型数值。

#### func (*Args) GetUintOrZero

```go
func (a *Args) GetUintOrZero(key string) int
```

`GetUintOrZero` 返回指定 `key` 的无符号整型数值。

当出错时返回 `0` 。

#### func (*Args) Has

```go
func (a *Args) Has(key string) bool
```

`Has` 在当 `Args` 中存在指定 `key` 时返回 `true` 。

#### func (*Args) HasBytes

```go
func (a *Args) HasBytes(key []byte) bool
```

`HasBytes` 在当 `Args` 中存在指定 `key` 时返回 `true` 。

#### func (*Args) Len

```go
func (a *Args) Len() int
```

`Len` 查询参数的数量。

#### func (*Args) Parse

```go
func (a *Args) Parse(s string)
```

`Parse` 解析包含查询参数的字符串。

#### func (*Args) ParseBytes

```go
func (a *Args) ParseBytes(b []byte)
```

`ParseBytes` 解析包含查询参数的 `b`。

#### func (*Args) Peek

```go
func (a *Args) Peek(key string) []byte
```

`Peek` 返回查询参数中指定 `key` 的值。

#### func (*Args) PeekBytes

```go
func (a *Args) PeekBytes(key []byte) []byte
```

`PeekBytes` 返回查询参数中指定 `key` 的值。

#### func (*Args) PeekMulti

```go
func (a *Args) PeekMulti(key string) [][]byte
```

`PeekMulti` 返回查询参数中指定 `key` 的所有值。

#### func (*Args) PeekMultiBytes

```go
func (a *Args) PeekMultiBytes(key []byte) [][]byte
```

`PeekMultiBytes` 返回查询参数中指定 `key` 的所有值。

#### func (*Args) QueryString

```go
func (a *Args) QueryString() []byte
```

`QueryString` 返回查询参数的字符串表示。

在下个 `Args` 方法调用之前，返回值都是合法的。

#### func (*Args) Reset

```go
func (a *Args) Reset()
```

`Reset` 清除所有查询参数。

#### func (*Args) Set

```go
func (a *Args) Set(key, value string)
```

`Set` 设置 `'key=value'` 参数。

#### func (*Args) SetBytesK

```go
func (a *Args) SetBytesK(key []byte, value string)
```

`SetBytesK` 设置 `'key=value'` 参数。

#### func (*Args) SetBytesKV

```go
func (a *Args) SetBytesKV(key, value []byte)
```

`SetBytesKV` 设置 `'key=value'` 参数。

#### func (*Args) SetBytesV

```go
func (a *Args) SetBytesV(key string, value []byte)
```

`SetBytesV` 设置 `'key=value'` 参数。

#### func (*Args) SetUint

```go
func (a *Args) SetUint(key string, value int)
```

`SetUint` 为指定 `key` 设置无符号整数值。

#### func (*Args) SetUintBytes

```go
func (a *Args) SetUintBytes(key []byte, value int)
```

`SetUintBytes` 为指定 `key` 设置无符号整数值。

#### func (*Args) String

```go
func (a *Args) String() string
```

`String` 返回查询参数的字符串表示。

#### func (*Args) VisitAll

```go
func (a *Args) VisitAll(f func(key, value []byte))
```

`VisitAll` 对每一个存在的参数调用 `f` 。

`f` 在返回后必须不能保留对键和值的引用。若要在返回后扔需要存储它们，请存储它们的副本。

#### func (*Args) WriteTo

```go
func (a *Args) WriteTo(w io.Writer) (int64, error)
```

`WriteTo` 向 `w` 写入查询字符串。

`WriteTo` 实现了 `io.WriterTo` 接口。

### type Client

```go
type Client struct {

    // 客户端名字。在 User-Agent 请求头中会被使用到。
    //
    // 如果未被设置，则会使用默认客户端名。
    Name string

    // 建立到指定 host 的新连接后的回调函数。
    //
    // 如果未被设置，则会使用默认 Dial 函数。
    Dial DialFunc

    // 若被设为 true ，则会试图连接 ipv4 和 ipv6 的地址。
    //
    // 这个选项仅在使用默认 TCP dialer 时有效，
    // 例如：Dial 为空。
    //
    // 默认情况下客户端仅会连接 ipv4 地址，
    // 因为 ipv6 在世界上的大多数网络中都仍然不可用 ：）
    DialDualStack bool

    // HTTPS 连接的 TLS 配置。
    // 如果未被设置，则使用默认的 TLS 配置。
    TLSConfig *tls.Config

    // 每个 host 可以被建立的最大连接数。
    //
    // 如果未被设置，则使用默认的 DefaultMaxConnsPerHost 。
    MaxConnsPerHost int

    // 在这个时间间隔后，空闲的 keep-alive 连接会被关闭。
    // 默认值为 DefaultMaxIdleConnDuration 。
    MaxIdleConnDuration time.Duration

    // 每个连接响应读取时的缓冲大小。
    // 这个值也限制了最大头大小。
    //
    // 默认值为 0 。
    ReadBufferSize int

    // 每个连接请求写入时的缓冲大小。
    //
    // 默认值为 0 。
    WriteBufferSize int

    // 完整的响应读取（包含响应体）可用的最大时间。
    //
    // 默认为无限制。
    ReadTimeout time.Duration

    // 完整的请求写入（包含请求体）可用的最大时间。
    //
    // 默认为无限制。
    WriteTimeout time.Duration

    // 相应体的最大大小。
    //
    // 当该值大于 0 ，且相应体超过它时，客户端返回 ErrBodyTooLarge 。
    // 默认为无限制。
    MaxResponseBodySize int

    DisableHeaderNamesNormalizing bool

    // 包含被过滤或未导出的属性
}
```

`Client` 实现了 HTTP 客户端。

不允许按值拷贝 `Client` ，应该创建一个新的实例。

在多个运行的 goroutine 间调用 `Client` 方法是安全的。

#### func (*Client) Do

```go
func (c *Client) Do(req *Request, resp *Response) error
```

`Do` 发出指定的 http 请求，在得到响应后并且填充指定的 http 响应对象。

请求必须至少包含一个非空的 RequestURI （包含协议和 host）或非空的 Host 头 + RequestURI。

客户端以以下顺序确定待请求的服务端：

- 如果 RequestURI 包含完整的带有协议和 host 的 url ，则从 RequestURI 中取得。
- 否则就从 Host 头中取得。

如果 `resp` 是 `nil` ，那么响应会被忽略。

这个函数不会跟随重定向。若要跟随重定向，请使用 `Get*` 。

如果向指定请求 host 的所有 `DefaultMaxConnsPerHost` 数量的连接都被占用，那么会返回 `ErrNoFreeConns`。

在有性能要求的代码中，推荐通过 `AcquireRequest` 和 `AcquireResponse` 来获取 `req` 和 `resp` 。

#### func (*Client) DoDeadline

```go
func (c *Client) DoDeadline(req *Request, resp *Response, deadline time.Time) error
```

`DoDeadline` 发出指定的 http 请求，并且在指定的 deadline 之前得到响应后填充指定的 http 响应对象。

请求必须至少包含一个非空的 RequestURI （包含协议和 host）或非空的 Host 头 + RequestURI。

客户端以以下顺序确定待请求的服务端：

- 如果 RequestURI 包含完整的带有协议和 host 的 url ，则从 RequestURI 中取得。
- 否则就从 Host 头中取得。

这个函数不会跟随重定向。若要跟随重定向，请使用 `Get*` 。

如果 `resp` 是 `nil` ，那么响应会被忽略。

如果向指定请求 host 的所有 `DefaultMaxConnsPerHost` 数量的连接都被占用，那么会返回 `ErrNoFreeConns`。

在有性能要求的代码中，推荐通过 `AcquireRequest` 和 `AcquireResponse` 来获取 `req` 和 `resp` 。

#### func (*Client) DoTimeout

```go
func (c *Client) DoTimeout(req *Request, resp *Response, timeout time.Duration) error
```

`DoTimeout` 发出指定的 http 请求，并且在指定的超时之前得到响应后填充指定的 http 响应对象。

请求必须至少包含一个非空的 RequestURI （包含协议和 host）或非空的 Host 头 + RequestURI。

客户端以以下顺序确定待请求的服务端：

- 如果 RequestURI 包含完整的带有协议和 host 的 url ，则从 RequestURI 中取得。
- 否则就从 Host 头中取得。

这个函数不会跟随重定向。若要跟随重定向，请使用 `Get*` 。

如果 `resp` 是 `nil` ，那么响应会被忽略。

如果向指定请求 host 的所有 `DefaultMaxConnsPerHost` 数量的连接都被占用，那么会返回 `ErrNoFreeConns`。

在有性能要求的代码中，推荐通过 `AcquireRequest` 和 `AcquireResponse` 来获取 `req` 和 `resp` 。

#### func (*Client) Get

```go
func (c *Client) Get(dst []byte, url string) (statusCode int, body []byte, err error)
```

`Get` 向 `dst` 追加 url 信息，并且通过 `body` 返回它。

这个函数会跟随重定向。若要手动操作重定向，请使用 `Do*` 。

如果 `dst` 为 `nil` ，那么则会分配一个新的 `body` 缓冲。

#### func (*Client) GetDeadline

```go
func (c *Client) GetDeadline(dst []byte, url string, deadline time.Time) (statusCode int, body []byte, err error)
```

`GetDeadline` 向 `dst` 追加 url 信息，并且通过 `body` 返回它。

这个函数会跟随重定向。若要手动操作重定向，请使用 `Do*` 。

如果 `dst` 为 `nil` ，那么则会分配一个新的 `body` 缓冲。

若在指定的 deadline 之前没能获取到响应，那么会返回 `ErrTimeout` 。

#### func (*Client) GetTimeout

```go
func (c *Client) GetTimeout(dst []byte, url string, timeout time.Duration) (statusCode int, body []byte, err error)
```

`GetTimeout` 向 `dst` 追加 url 信息，并且通过 `body` 返回它。

这个函数会跟随重定向。若要手动操作重定向，请使用 `Do*` 。

如果 `dst` 为 `nil` ，那么则会分配一个新的 `body` 缓冲。

若在指定的超时之前没能获取到响应，那么会返回 `ErrTimeout` 。

#### func (*Client) Post

```go
func (c *Client) Post(dst []byte, url string, postArgs *Args) (statusCode int, body []byte, err error)
```

`Post` 使用指定 POST 参数向指定 `url` 发出 POST 请求。

请求体会追加值 `dst` ，并且通过 `body` 返回。

这个函数会跟随重定向。若要手动操作重定向，请使用 `Do*` 。

若 `dst` 是 `nil` ，那么新的 `body` 缓冲会被分配。

如果 `postArgs` 是 `nil` ，则发送空 POST 请求体。

### type Cookie

```go
type Cookie struct {
    // 包含被过滤或未导出的属性
}
```

`Cookie` 代表 HTTP 相应的 cookie 。

不允许按值拷贝 `Cookie` ，应该创建一个新的实例。

在多个运行的 goroutine 间使用 `Cookie` 实例是禁止的。

#### func AcquireCookie

```go
func AcquireCookie() *Cookie
```

`AcquireCookie` 从池中返回一个空的 `Cookie` 对象。

返回的 `Cookie` 实例在不再需要时可以通过 `ReleaseCookie` 释放回池。这可以降低垃圾回收负载。

#### func (*Cookie) AppendBytes

```go
func (c *Cookie) AppendBytes(dst []byte) []byte
```

`AppendBytes` 向 `dst` 追加 cookie ，并且返回追加后的 `dst` 。

#### func (*Cookie) Cookie

```go
func (c *Cookie) Cookie() []byte
```

`Cookie` 返回 cookie 的表示。

直到下次调用 `Cookie` 方法前，返回值都是合法的。

#### func (*Cookie) CopyTo

```go
func (c *Cookie) CopyTo(src *Cookie)
```

`CopyTo` 拷贝 `src` cookie 至 `c` 。

#### func (*Cookie) Domain

```go
func (c *Cookie) Domain() []byte
```

`Domain` 返回 cookie 的 domain 值。

直到下次调用会改变 `Cookie` 的方法前，返回值都是合法的。

#### func (*Cookie) Expire

```go
func (c *Cookie) Expire() time.Time
```

`Expire` 返回 cookie 的过期时间。

若没设置过期，则返回 `CookieExpireUnlimited` 。

#### func (*Cookie) HTTPOnly

```go
func (c *Cookie) HTTPOnly() bool
```

`HTTPOnly` 在 cookie 为 http only 时返回 `true` 。

#### func (*Cookie) Key

```go
func (c *Cookie) Key() []byte
```

`Key` 返回 cookie 名字。

直到下次调用会改变 `Cookie` 的方法前，返回值都是合法的。

#### func (*Cookie) Parse

```go
func (c *Cookie) Parse(src string) error
```

`Parse` 解析 Set-Cookie 头。

#### func (*Cookie) ParseBytes

```go
func (c *Cookie) ParseBytes(src []byte) error
```

`ParseBytes` 解析 Set-Cookie 头。

#### func (*Cookie) Path

```go
func (c *Cookie) Path() []byte
```

`Path` 返回 cookie path 。

#### func (*Cookie) Reset

```go
func (c *Cookie) Reset()
```

`Reset` 清空该 cookie 。

#### func (*Cookie) Secure

```go
func (c *Cookie) Secure() bool
```

`Secure` 在当 cookie 为 secure 时返回 `true` 。

#### func (*Cookie) SetDomain

```go
func (c *Cookie) SetDomain(domain string)
```

`SetDomain` 设置 cookie 的 domain 。

#### func (*Cookie) SetDomainBytes

```go
func (c *Cookie) SetDomainBytes(domain []byte)
```

`SetDomainBytes` 设置 cookie 的 domain 。

#### func (*Cookie) SetExpire

```go
func (c *Cookie) SetExpire(expire time.Time)
```

`SetExpire` 设置 cookie 的过期时间。

若要使该 cookie 在客户端过期，则将值设置为 `CookieExpireDelete` 。

默认情况下 cookie 的寿命由浏览器会话限制。

#### func (*Cookie) SetHTTPOnly

```go
func (c *Cookie) SetHTTPOnly(httpOnly bool)
```

`SetHTTPOnly` 将 cookie 的 httpOnly 标识设置为指定值。

#### func (*Cookie) SetKey

```go
func (c *Cookie) SetKey(key string)
```

`SetKey` 设置 cookie 名。

#### func (*Cookie) SetKeyBytes

```go
func (c *Cookie) SetKeyBytes(key []byte)
```

`SetKeyBytes` 设置 cookie 名。

#### func (*Cookie) SetPath

```go
func (c *Cookie) SetPath(path string)
```

`SetPath` 设置 cookie 路径。

#### func (*Cookie) SetPathBytes

```go
func (c *Cookie) SetPathBytes(path []byte)
```

`SetPathBytes` 设置 cookie 路径。

#### func (*Cookie) SetSecure

```go
func (c *Cookie) SetSecure(secure bool)
```

`SetSecure` 将 cookie 的 secure 标识设置为指定值。

#### func (*Cookie) SetValue

```go
func (c *Cookie) SetValue(value string)
```

`SetValue` 设置 cookie 的值。

#### func (*Cookie) SetValueBytes

```go
func (c *Cookie) SetValueBytes(value []byte)
```

`SetValueBytes` 设置 cookie 的值。

#### func (*Cookie) String

```go
func (c *Cookie) String() string
```

`String` 返回 cookie 的字符串表示。

#### func (*Cookie) Value

```go
func (c *Cookie) Value() []byte
```

`Value` 返回 cookie 的值。

直到下次调用会改变 `Cookie` 的方法前，返回值都是合法的。

#### func (*Cookie) WriteTo

```go
func (c *Cookie) WriteTo(w io.Writer) (int64, error)
```

`WriteTo` 将 cookie 的字符串表示写入 `w` 。

`WriteTo` 实现了 `io.WriterTo` 接口。

### type DialFunc

```go
type DialFunc func(addr string) (net.Conn, error)
```

`DialFunc` 必须建立到 `addr` 的连接。

没有必要为 HTTPS 建立到 TLS（SSL）的连接。若 `HostClient.IsTLS` 被设置，则客户端会自动转换连接至 TLS 。

TCP address passed to DialFunc always contains host and port. Example TCP addr values:
传递至 `DialFunc` 的 TCP 地址总是包含 host 和端口。例子：

- `foobar.com:80`
- `foobar.com:443`
- `foobar.com:8080`

### type FS

```go
type FS struct {

    // 用于响应文件的根目录
    Root string

    // 目录中的索引文件名。
    //
    // 例子：
    //
    //     * index.html
    //     * index.htm
    //     * my-super-index.xml
    //
    // 默认为空。
    IndexNames []string

    GenerateIndexPages bool

    // 若设为 true ，则压缩响应。
    //
    // 服务器会通过缓存来最小化 CPU 的使用。
    // 新的缓存文件名字会添加 `CompressedFileSuffix` 前缀。
    // 所以建议使服务器对 Root 目录以及子目录有写权限。
    Compress bool

    // 若被设为 true ，则启用字节范围请求
    //
    // 默认为 false 。
    AcceptByteRange bool

    // 重写路径函数。
    //
    // 默认为不改变请求路径。
    PathRewrite PathRewriteFunc

    // 非活跃的文件句柄的过期时间间隔。
    //
    // 默认为 `FSHandlerCacheDuration` 。
    CacheDuration time.Duration

    // 为缓存的压缩文件添加的前缀。
    //
    // 这个值仅在 Compress 被设置时才有效。
    //
    // 默认为 FSCompressedFileSuffix 。
    CompressedFileSuffix string

    // 包含被过滤或未导出的属性
}
```

`FS` 代表了通过本地文件系统来响应静态文件 HTTP 请求的设置。

不允许复制 `FS` 值，应该创建新的 `FS` 值。

例子：

```go
fs := &fasthttp.FS{
    // 响应静态文件请求的目录
    Root: "/var/www/static-site",

    // 生成索引
    GenerateIndexPages: true,

    // 开启压缩，用于节省带宽
    Compress: true,
}

// 创建响应静态文件的 handler
h := fs.NewRequestHandler()

// 启动服务器
if err := fasthttp.ListenAndServe(":8080", h); err != nil {
    log.Fatalf("error in ListenAndServe: %s", err)
}
```

#### func (*FS) NewRequestHandler

```go
func (fs *FS) NewRequestHandler() RequestHandler
```

`NewRequestHandler` 通过指定的 `FS` 设置返回新的请求 handler 。

返回的 handler 根据 `FS.CacheDuration` 来缓存请求的文件句柄。若 `FS.Root` 目录包含大量文件，请确保你的程序通过 `'ulimit -n'` 来保证有足够的“可打开文件”。

不需要对单个 `FS` 实例创建多个请求 handler ，只需重用即可。

### type HijackHandler

```go
type HijackHandler func(c net.Conn)
```

`HijackHandler` 必须处理拦截的连接 `c` 。

在 `HijackHandler` 返回后连接 `c` 会被自动关闭。

在 `HijackHandler` 返回后连接 `c` 必须不可再被使用。

### type HostClient

```go
type HostClient struct {

    // 以逗号分隔的上游 HTTP 服务器 host 地址列表，通过轮询传递给 Dial
    //
    // 如果默认的 dialer 被使用，每一个地址都需要包含端口。
    // 例子：
    //
    //    - foobar.com:80
    //    - foobar.com:443
    //    - foobar.com:8080
    Addr string

    // 客户端名，用于 User-Agent 请求头。
    Name string

    // 建立到指定 host 的新连接后的回调函数。
    //
    // 如果未被设置，则会使用默认 Dial 函数。
    Dial DialFunc

    // 若被设为 true ，则会试图连接 ipv4 和 ipv6 的地址。
    //
    // 这个选项仅在使用默认 TCP dialer 时有效，
    // 例如：Dial 为空。
    //
    // 默认情况下客户端仅会连接 ipv4 地址，
    // 因为 ipv6 在世界上的大多数网络中都仍然不可用 ：）
    DialDualStack bool

    // 是否使用 TLS 。
    IsTLS bool

    // 可选的 TLS 配置。
    TLSConfig *tls.Config


    // 每个 host 可以被建立的最大连接数。
    //
    // 如果未被设置，则使用默认的 DefaultMaxConnsPerHost 。
    MaxConns int

    // 在这个时间间隔后， keep-alive 连接会被关闭。
    // 默认值为无限制。
    MaxConnDuration time.Duration

    // 在这个时间间隔后，空闲的 keep-alive 连接会被关闭。
    // 默认值为 DefaultMaxIdleConnDuration 。
    MaxIdleConnDuration time.Duration

    // 每个连接响应读取时的缓冲大小。
    // 这个值也限制了最大头大小。
    //
    // 默认值为 0 。
    ReadBufferSize int

    // 每个连接请求写入时的缓冲大小。
    //
    // 默认值为 0 。
    WriteBufferSize int

    // 完整的响应读取（包含响应体）可用的最大时间。
    //
    // 默认为无限制。
    ReadTimeout time.Duration

    // 完整的请求写入（包含请求体）可用的最大时间。
    //
    // 默认为无限制。
    WriteTimeout time.Duration

    // 相应体的最大大小。
    //
    // 当该值大于 0 ，且相应体超过它时，客户端返回 ErrBodyTooLarge 。
    // 默认为无限制。
    MaxResponseBodySize int

    DisableHeaderNamesNormalizing bool

    // 包含被过滤或未导出的属性
}
```

`HostClient` 均衡地向列于 `Addr` 中的 host 发起请求。

禁止拷贝 `HostClient` 实例。应使用创建新的实例。

在多个运行的 goroutine 间执行 `HostClient` 方法是安全的。

例子：
```go
package main

import (
    "log"

    "github.com/valyala/fasthttp"
)

func main() {
    // 准备一个客户端，用于通过监听于 localhost:8080 的 HTTP 代理获取网页
    c := &fasthttp.HostClient{
        Addr: "localhost:8080",
    }

    // 使用本地代理获取谷歌页面。
    statusCode, body, err := c.Get(nil, "http://google.com/foo/bar")
    if err != nil {
        log.Fatalf("Error when loading google page through local proxy: %s", err)
    }
    if statusCode != fasthttp.StatusOK {
        log.Fatalf("Unexpected status code: %d. Expecting %d", statusCode, fasthttp.StatusOK)
    }
    useResponseBody(body)

    // 通过本地代理获取 foobar 页面。重用 body 缓冲。
    statusCode, body, err = c.Get(body, "http://foobar.com/google/com")
    if err != nil {
        log.Fatalf("Error when loading foobar page through local proxy: %s", err)
    }
    if statusCode != fasthttp.StatusOK {
        log.Fatalf("Unexpected status code: %d. Expecting %d", statusCode, fasthttp.StatusOK)
    }
    useResponseBody(body)
}

func useResponseBody(body []byte) {
  // 处理 body
}
```

#### func (*HostClient) Do

```go
func (c *HostClient) Do(req *Request, resp *Response) error
```

`Do` 发出指定的 http 请求，在得到响应后并且填充指定的 http 响应对象。

请求必须至少包含一个非空的 RequestURI （包含协议和 host）或非空的 Host 头 + RequestURI。

客户端以以下顺序确定待请求的服务端：

- 如果 RequestURI 包含完整的带有协议和 host 的 url ，则从 RequestURI 中取得。
- 否则就从 Host 头中取得。

这个函数不会跟随重定向。若要跟随重定向，请使用 `Get*` 。

如果 `resp` 是 `nil` ，那么响应会被忽略。

如果向指定请求 host 的所有 `DefaultMaxConnsPerHost` 数量的连接都被占用，那么会返回 `ErrNoFreeConns`。

在有性能要求的代码中，推荐通过 `AcquireRequest` 和 `AcquireResponse` 来获取 `req` 和 `resp` 。

#### func (*HostClient) DoDeadline

```go
func (c *HostClient) DoDeadline(req *Request, resp *Response, deadline time.Time) error
```

`DoDeadline` 发出指定的 http 请求，并且在指定的 deadline 之前得到响应后填充指定的 http 响应对象。

请求必须至少包含一个非空的 RequestURI （包含协议和 host）或非空的 Host 头 + RequestURI。

客户端以以下顺序确定待请求的服务端：

- 如果 RequestURI 包含完整的带有协议和 host 的 url ，则从 RequestURI 中取得。
- 否则就从 Host 头中取得。

这个函数不会跟随重定向。若要跟随重定向，请使用 `Get*` 。

如果 `resp` 是 `nil` ，那么响应会被忽略。

如果向指定请求 host 的所有 `DefaultMaxConnsPerHost` 数量的连接都被占用，那么会返回 `ErrNoFreeConns`。

在有性能要求的代码中，推荐通过 `AcquireRequest` 和 `AcquireResponse` 来获取 `req` 和 `resp` 。

#### func (*HostClient) DoTimeout

```go
func (c *HostClient) DoTimeout(req *Request, resp *Response, timeout time.Duration) error
```

`DoTimeout` 发出指定的 http 请求，并且在指定的超时之前得到响应后填充指定的 http 响应对象。

请求必须至少包含一个非空的 RequestURI （包含协议和 host）或非空的 Host 头 + RequestURI。

客户端以以下顺序确定待请求的服务端：

- 如果 RequestURI 包含完整的带有协议和 host 的 url ，则从 RequestURI 中取得。
- 否则就从 Host 头中取得。

这个函数不会跟随重定向。若要跟随重定向，请使用 `Get*` 。

如果 `resp` 是 `nil` ，那么响应会被忽略。

如果向指定请求 host 的所有 `DefaultMaxConnsPerHost` 数量的连接都被占用，那么会返回 `ErrNoFreeConns`。

在有性能要求的代码中，推荐通过 `AcquireRequest` 和 `AcquireResponse` 来获取 `req` 和 `resp` 。

#### func (*HostClient) Get

```go
func (c *HostClient) Get(dst []byte, url string) (statusCode int, body []byte, err error)
```

`Get` 向 `dst` 追加 url 信息，并且通过 `body` 返回它。

这个函数会跟随重定向。若要手动操作重定向，请使用 `Do*` 。

如果 `dst` 为 `nil` ，那么则会分配一个新的 `body` 缓冲。

#### func (*HostClient) GetDeadline

```go
func (c *HostClient) GetDeadline(dst []byte, url string, deadline time.Time) (statusCode int, body []byte, err error)
```

`GetDeadline` 向 `dst` 追加 url 信息，并且通过 `body` 返回它。

这个函数会跟随重定向。若要手动操作重定向，请使用 `Do*` 。

如果 `dst` 为 `nil` ，那么则会分配一个新的 `body` 缓冲。

若在指定的 deadline 之前没能获取到响应，那么会返回 `ErrTimeout` 。

#### func (*HostClient) GetTimeout

```go
func (c *HostClient) GetTimeout(dst []byte, url string, timeout time.Duration) (statusCode int, body []byte, err error)
```

`GetTimeout` 向 `dst` 追加 url 信息，并且通过 `body` 返回它。

这个函数会跟随重定向。若要手动操作重定向，请使用 `Do*` 。

如果 `dst` 为 `nil` ，那么则会分配一个新的 `body` 缓冲。

若在指定的超时之前没能获取到响应，那么会返回 `ErrTimeout` 。

#### func (*HostClient) LastUseTime

```go
func (c *HostClient) LastUseTime() time.Time
```

`LastUseTime` 返回客户端最后被使用的时间。

#### func (*HostClient) PendingRequests

```go
func (c *HostClient) PendingRequests() int
```

`PendingRequests` 返回正在执行的请求数。

#### func (*HostClient) Post

```go
func (c *HostClient) Post(dst []byte, url string, postArgs *Args) (statusCode int, body []byte, err error)
```

`Post` 使用指定 POST 参数向指定 `url` 发出 POST 请求。

请求体会追加值 `dst` ，并且通过 `body` 返回。

这个函数会跟随重定向。若要手动操作重定向，请使用 `Do*` 。

若 `dst` 是 `nil` ，那么新的 `body` 缓冲会被分配。

如果 `postArgs` 是 `nil` ，则发送空 POST 请求体。

### type Logger

```go
type Logger interface {
    // Printf 必须与 log.Printf 有相同的语义。
    Printf(format string, args ...interface{})
}
```

`Logger` 被用于记录格式化信息日志。

### type PathRewriteFunc

```go
type PathRewriteFunc func(ctx *RequestCtx) []byte
```

`PathRewriteFunc` 必须返回基于 `ctx.Path()` 的新请求路径。

该函数用于在 `FS` 中转义当前请求路径至相对于 `FS.Root` 的相对路径。

处于安全原因，返回的路径中不允许包含 `'/../'` 子字符串。

### func NewPathPrefixStripper

```go
func NewPathPrefixStripper(prefixSize int) PathRewriteFunc
```

`NewPathPrefixStripper` 返回重写路径函数，返回移除的前缀大小。

例子：

- prefixSize = 0, 原路径： "/foo/bar", 结果： "/foo/bar"
- prefixSize = 3, 原路径： "/foo/bar", 结果： "o/bar"
- prefixSize = 7, 原路径： "/foo/bar", 结果： "r"

返回的路径重写函数可能会被 `FS.PathRewrite` 使用。

### func NewPathSlashesStripper

```go
func NewPathSlashesStripper(slashesCount int) PathRewriteFunc
```

`NewPathSlashesStripper` 返回重写路径函数，返回移除的路径分隔符数量。

例子：

- slashesCount = 0, 原路径： "/foo/bar", 结果： "/foo/bar"
- slashesCount = 1, 原路径： "/foo/bar", 结果： "/bar"
- slashesCount = 2, 原路径： "/foo/bar", 结果： ""

返回的路径重写函数可能会被 `FS.PathRewrite` 使用。

### type PipelineClient

```go
type PipelineClient struct {

    // 连接的 host 的地址
    Addr string

    // 连接至 Addr 的最大并发数。
    //
    // 默认为单连接。
    MaxConns int

    // 单个连接至 Addr 的最大等待管道请求数量。
    //
    // 默认为 DefaultMaxPendingRequests 。
    MaxPendingRequests int

    // 在批量发送管道请求至服务器前的最大延时。
    //
    // 默认为无延时。
    MaxBatchDelay time.Duration

    /// 建立到指定 host 的新连接后的回调函数。
    //
    // 如果未被设置，则会使用默认 Dial 函数。
    Dial DialFunc

    // 若被设为 true ，则会试图连接 ipv4 和 ipv6 的地址。
    //
    // 这个选项仅在使用默认 TCP dialer 时有效，
    // 例如：Dial 为空。
    //
    // 默认情况下客户端仅会连接 ipv4 地址，
    // 因为 ipv6 在世界上的大多数网络中都仍然不可用 ：）
    DialDualStack bool

    // 是否使用 TLS 。
    IsTLS bool

    // 可选的 TLS 配置。
    TLSConfig *tls.Config

    // 在这个时间间隔后，空闲的 keep-alive 连接会被关闭。
    // 默认值为 DefaultMaxIdleConnDuration 。
    MaxIdleConnDuration time.Duration

    // 每个连接响应读取时的缓冲大小。
    // 这个值也限制了最大头大小。
    //
    // 默认值为 0 。
    ReadBufferSize int

    // 每个连接请求写入时的缓冲大小。
    //
    // 默认值为 0 。
    WriteBufferSize int

    // 完整的响应读取（包含响应体）可用的最大时间。
    //
    // 默认为无限制。
    ReadTimeout time.Duration

    // 完整的请求写入（包含请求体）可用的最大时间。
    //
    // 默认为无限制。
    WriteTimeout time.Duration

    // 用于记录客户端错误的日志记录器。
    //
    // 默认为标准 log 库。
    Logger Logger

    // 包含被过滤或未导出的属性
}
```

`PipelineClient` 通过一个指定的并发连接限制数，来发送请求。

这个客户端可能被用于高负载的 RPC 系统。更多详情参阅 https://en.wikipedia.org/wiki/HTTP_pipelining 。

禁止拷贝 `PipelineClient` 实例。应该创建新实例。

在运行的 goroutine 间调用 `PipelineClient` 方法是安全的。

#### func (*PipelineClient) Do

```go
func (c *PipelineClient) Do(req *Request, resp *Response) error
```

`Do` 发出指定的 http 请求，在得到响应后并且填充指定的 http 响应对象。

请求必须至少包含一个非空的 RequestURI （包含协议和 host）或非空的 Host 头 + RequestURI。

客户端以以下顺序确定待请求的服务端：

- 如果 RequestURI 包含完整的带有协议和 host 的 url ，则从 RequestURI 中取得。
- 否则就从 Host 头中取得。

这个函数不会跟随重定向。若要跟随重定向，请使用 `Get*` 。

如果 `resp` 是 `nil` ，那么响应会被忽略。

如果向指定请求 host 的所有 `DefaultMaxConnsPerHost` 数量的连接都被占用，那么会返回 `ErrNoFreeConns`。

在有性能要求的代码中，推荐通过 `AcquireRequest` 和 `AcquireResponse` 来获取 `req` 和 `resp` 。

#### func (*PipelineClient) DoDeadline

```go
func (c *PipelineClient) DoDeadline(req *Request, resp *Response, deadline time.Time) error
```

`DoDeadline` 发出指定的 http 请求，并且在指定的 deadline 之前得到响应后填充指定的 http 响应对象。

请求必须至少包含一个非空的 RequestURI （包含协议和 host）或非空的 Host 头 + RequestURI。

客户端以以下顺序确定待请求的服务端：

- 如果 RequestURI 包含完整的带有协议和 host 的 url ，则从 RequestURI 中取得。
- 否则就从 Host 头中取得。

这个函数不会跟随重定向。若要跟随重定向，请使用 `Get*` 。

如果 `resp` 是 `nil` ，那么响应会被忽略。

如果向指定请求 host 的所有 `DefaultMaxConnsPerHost` 数量的连接都被占用，那么会返回 `ErrNoFreeConns`。

在有性能要求的代码中，推荐通过 `AcquireRequest` 和 `AcquireResponse` 来获取 `req` 和 `resp` 。

#### func (*PipelineClient) DoTimeout

```go
func (c *PipelineClient) DoTimeout(req *Request, resp *Response, timeout time.Duration) error
```

`DoTimeout` 发出指定的 http 请求，并且在指定的超时之前得到响应后填充指定的 http 响应对象。

请求必须至少包含一个非空的 RequestURI （包含协议和 host）或非空的 Host 头 + RequestURI。

客户端以以下顺序确定待请求的服务端：

- 如果 RequestURI 包含完整的带有协议和 host 的 url ，则从 RequestURI 中取得。
- 否则就从 Host 头中取得。

这个函数不会跟随重定向。若要跟随重定向，请使用 `Get*` 。

如果 `resp` 是 `nil` ，那么响应会被忽略。

如果向指定请求 host 的所有 `DefaultMaxConnsPerHost` 数量的连接都被占用，那么会返回 `ErrNoFreeConns`。

在有性能要求的代码中，推荐通过 `AcquireRequest` 和 `AcquireResponse` 来获取 `req` 和 `resp` 。

#### func (*PipelineClient) PendingRequests

```go
func (c *PipelineClient) PendingRequests() int
```

`PendingRequests` 返回正在执行的请求数。

### type Request

```go
type Request struct {

    // 请求头
    //
    // 按值拷贝 Header 是禁止的。应使用指针。
    Header RequestHeader

    // 包含被过滤或未导出的属性
}
```

`Request` 代表一个 HTTP 请求。

禁止拷贝 `Request` 实例。应该创建新实例或使用 `CopyTo` 。

`Request` 实例必须不能再多个运行的 goroutine 间使用。

#### func AcquireRequest

```go
func AcquireRequest() *Request
```

`AcquireRequest` 从请求池中返回一个空的 `Request` 实例。

返回的 `Request` 实例在不再需要时可以通过 `ReleaseRequest` 释放回池。这可以降低垃圾回收负载。


#### func (*Request) AppendBody

```go
func (req *Request) AppendBody(p []byte)
```

`AppendBody` 追加 `p` 至请求体。

在函数返回后重用 `p` 是安全的。

#### func (*Request) AppendBodyString

```go
func (req *Request) AppendBodyString(s string)
```

`AppendBodyString` 追加 `s` 至请求体。

#### func (*Request) Body

```go
func (req *Request) Body() []byte
```

`Body` 返回请求体。

#### func (*Request) BodyGunzip

```go
func (req *Request) BodyGunzip() ([]byte, error)
```

`BodyGunzip` 返回未被 gzip 压缩的请求体数据。

当请求体中包含 `'Content-Encoding: gzip'` 且读取未被 gzip 请求体时，这个方法可能会被使用。使用 `Body` 来读取被 gzip 压缩的请求体。

#### func (*Request) BodyInflate

```go
func (req *Request) BodyInflate() ([]byte, error)
```

`BodyGunzip` 返回未被压缩的请求体数据。

当请求体中包含 `'Content-Encoding: deflate'` 且读取未被压缩请求体时，这个方法可能会被使用。使用 `Body` 来读取被压缩的请求体。

#### func (*Request) BodyWriteTo

```go
func (req *Request) BodyWriteTo(w io.Writer) error
```

`BodyWriteTo` 向 `w` 写入请求体。

#### func (*Request) BodyWriter

```go
func (req *Request) BodyWriter() io.Writer
```

`BodyWriter` 返回用于发送请求体的 writer 。

#### func (*Request) ConnectionClose

```go
func (req *Request) ConnectionClose() bool
```

`ConnectionClose` 在 `'Connection: close'` 头被设置时返回 `true` 。

#### func (*Request) ContinueReadBody

```go
func (req *Request) ContinueReadBody(r *bufio.Reader, maxBodySize int) error
```

`ContinueReadBody` 在 `'Expect: 100-continue'` 头被设置时读取请求体 。

在调用该方法前，调用者必须发送 `StatusContinue` 响应。

如果 `maxBodySize > 0` 且请求体大于 `maxBodySize` ，会返回 `ErrBodyTooLarge` 。

#### func (*Request) CopyTo

```go
func (req *Request) CopyTo(dst *Request)
```

`CopyTo` 拷贝 `req` 的内容至 `dst` 。

#### func (*Request) Host

```go
func (req *Request) Host() []byte
```

`Host` 返回指定请求的 host 。

#### func (*Request) IsBodyStream

```go
func (req *Request) IsBodyStream() bool
```

`IsBodyStream` 当请求体由 `SetBodyStream*` 设置时返回 `true` 。

#### func (*Request) MayContinue

```go
func (req *Request) MayContinue() bool
```

`MayContinue` 当请求头中包含 `'Expect: 100-continue'` 时返回 `true` 。

当 `MayContinue` 返回 `true` 时，调用者必须执行以下动作之一：

- 若请求头不符合要求，则返回 `StatusExpectationFailed` 。
- 或在读取请求体前发送 `StatusContinue` 。
- 或关闭连接。

#### func (*Request) MultipartForm

```go
func (req *Request) MultipartForm() (*multipart.Form, error)
```

`MultipartForm` 返回请求的 multipart 表单。

如果请求头的 Content-Type 不是 `'multipart/form-data'` 时返回 `ErrNoMultipartForm` 。

在 multipart 表单的处理结束后，`RemoveMultipartFormFiles` 必须被调用。

#### func (*Request) PostArgs

```go
func (req *Request) PostArgs() *Args
```

`PostArgs` 返回 POST 参数。

#### func (*Request) Read

```go
func (req *Request) Read(r *bufio.Reader) error
```

`Read` 从指定 `r` 中读取请求（包含请求体）。

#### func (*Request) ReadLimitBody

```go
func (req *Request) ReadLimitBody(r *bufio.Reader, maxBodySize int) error
```

`ReadLimitBody` 从指定 `r` 中读取请求（包含请求体），并且请求体大小有限制。

如果 `maxBodySize > 0` 且请求体大于 `maxBodySize` ，会返回 `ErrBodyTooLarge` 。

#### func (*Request) ReleaseBody

```go
func (req *Request) ReleaseBody(size int)
```

`ReleaseBody` 当请求体大于 `size` 时释放请求体。

调用它之后，将会允许垃圾回收器回收巨大的缓冲。如果使用这个函数，需要先调用 `ReleaseRequest` 。

一般情况下不会使用这个方法。仅当你十分清楚该方法的工作细节后才可使用它。

#### func (*Request) RemoveMultipartFormFiles

```go
func (req *Request) RemoveMultipartFormFiles()
```

`RemoveMultipartFormFiles` 删除 `multipart/form-data` 的临时文件。

#### func (*Request) RequestURI

```go
func (req *Request) RequestURI() []byte
```

`RequestURI` 返回请求的 URI 。

#### func (*Request) Reset

```go
func (req *Request) Reset()
```

`Reset` 清除请求体内容。

#### func (*Request) ResetBody

```go
func (req *Request) ResetBody()
```

`ResetBody` 清除请求体。

#### func (*Request) SetBody

```go
func (req *Request) SetBody(body []byte)
```

`SetBody` 设置请求体。

在函数返回后，重用 `body` 参数是安全的。

#### func (*Request) SetBodyStream

```go
func (req *Request) SetBodyStream(bodyStream io.Reader, bodySize int)
```

`SetBodyStream` 设置请求体流，`bodySize` 为可选。

若 `bodySize is >= 0` ，那么 `bodyStream` 在返回 `io.EOF` 前必须提供精确的 `bodySize` 字节数据。

若 `bodySize < 0`，那么 `bodyStream` 会被一直读取至 `io.EOF` 。

如果 `bodyStream` 实现了 `io.Closer` 接口，那么 `bodyStream.Close()` 会在数据都被读取后被调用。

注意 GET 和 HEAD 请求没有请求体。

更多详情也可参阅 `SetBodyStreamWriter` 。

#### func (*Request) SetBodyStreamWriter

```go
func (req *Request) SetBodyStreamWriter(sw StreamWriter)
```

`SetBodyStreamWriter` 为请求体注册指定的 `sw` 。

这个函数可能会在以下情况下被使用：

- 如果请求体过大（大于 10MB）。
- 如果请求体来自慢速的外部源。
- 如果请求体必须通过流传入（又称 `http client push` 或 `chunked transfer-encoding`）。

注意 GET 和 HEAD 请求没有请求体。

更多详情也可参阅 `SetBodyStream` 。

#### func (*Request) SetBodyString

```go
func (req *Request) SetBodyString(body string)
```

`SetBodyString` 设置请求体。

#### func (*Request) SetConnectionClose

```go
func (req *Request) SetConnectionClose()
```

`SetConnectionClose` 设置 `'Connection: close'` 头。

#### func (*Request) SetHost

```go
func (req *Request) SetHost(host string)
```

`SetHost` 设置请求的 host 。

#### func (*Request) SetHostBytes

```go
func (req *Request) SetHostBytes(host []byte)
```

`SetHostBytes` 设置请求的 host 。

#### func (*Request) SetRequestURI

```go
func (req *Request) SetRequestURI(requestURI string)
```

`SetRequestURI` 设置请求 URI 。

#### func (*Request) SetRequestURIBytes

```go
func (req *Request) SetRequestURIBytes(requestURI []byte)
```

`SetRequestURIBytes` 设置请求 URI 。

#### func (*Request) String

```go
func (req *Request) String() string
```

`String` 返回请求的字符串表示。

在发生错误时会返回错误信息。

在有性能要求的代码中，请使用 `Write` 来代替 `String` 。

#### func (*Request) SwapBody

```go
func (req *Request) SwapBody(body []byte) []byte
```

`SwapBody` 使用指定 `body` 来交换请求体，并且返回之前的请求体。

在函数返回后，禁止再使用该 `body` 对象。

#### func (*Request) URI

```go
func (req *Request) URI() *URI
```

`URI` 返回请求 URI 。

#### func (*Request) Write

```go
func (req *Request) Write(w *bufio.Writer) error
```

`Write` 向 `w` 写入请求。

`Write` 由于性能原因并不会冲刷（flush）请求至 `w` 。

更多详情也可参阅 `WriteTo` 。

#### func (*Request) WriteTo

```go
func (req *Request) WriteTo(w io.Writer) (int64, error)
```

`WriteTo` 向 `w` 写入请求。它实现了 `io.WriterTo` 接口。

#### type RequestCtx

```go
type RequestCtx struct {

    // 收到的请求。
    //
    // 按值复制 Request 是禁止的。应使用指针。
    Request Request

    // 即将发出的响应。
    //
    // 按值复制 Response 是禁止的。应使用指针。
    Response Response

    // 包含被过滤或未导出的属性
}
```

`RequestCtx` 包含了收到的请求和即将发出的响应。

拷贝 `RequestCtx` 实例是禁止的。

在函数返回后 `RequestHandler` 必须避免使用 `RequestCtx` 的引用。如果使用 `RequestCtx` 的引用是不可避免的，那么 `RequestHandler` 必须在返回前调用 `ctx.TimeoutError()` 。

在多个正在运行的 goroutine 间读取/修改 `RequestCtx` 是不安全的。当其他 goroutine 访问 `RequestCtx` 时，会返回 `TimeoutError*` 。

#### func (*RequestCtx) ConnID

```go
func (ctx *RequestCtx) ConnID() uint64
```

`ConnID` 返回连接的唯一标识 ID 。

这个 ID 可以用于区分同一连接的不同请求。

#### func (*RequestCtx) ConnRequestNum

```go
func (ctx *RequestCtx) ConnRequestNum() uint64
```

`ConnRequestNum` 返回当前连接的请求序列号。

#### func (*RequestCtx) ConnTime

```go
func (ctx *RequestCtx) ConnTime() time.Time
```

`ConnTime` 返回服务器开始接受请求后的持续时间。

#### func (*RequestCtx) Error

```go
func (ctx *RequestCtx) Error(msg string, statusCode int)
```

`Error` 设置相应状态码以及状态信息。

#### func (*RequestCtx) FormFile

```go
func (ctx *RequestCtx) FormFile(key string) (*multipart.FileHeader, error)
```

`FormFile` 返回指定 multipart 表单键对应的上传后文件。

在 `RequestHandler` 返回后这个文件会被制动删除。所以如果你需要保留它，可以预先移动或拷贝这个文件。

使用 `SaveMultipartFile` 来永久保存这个文件。

在 `RequestHandler` 返回前，这个返回的文件头都是合法的。

#### func (*RequestCtx) FormValue

```go
func (ctx *RequestCtx) FormValue(key string) []byte
```

`FormValue` 返回表单指定键的值。

值会在以下地方被搜寻：

- 查询字符串。
- POST 或 PUT 请求体。

还有一些其他方法来获取表单值：

- `QueryArgs` 来获取查询字符串。
- `PostArgs` 来获取 POST 或 PUT 的请求体。
- `MultipartForm` 来获取 multipart 表单值。
- `FormFile` 来获取上传的文件。

在 `RequestHandler` 返回前，这个返回值都是合法的。

#### func (*RequestCtx) Hijack

```go
func (ctx *RequestCtx) Hijack(handler HijackHandler)
```

`Hijack` 为连接劫持（connection hijacking）注册指定 `handler` 。

`handler` 会在 `RequestHandler` 返回后，发送 HTTP 响应前被调用。当前连接会被传递给 `handler` 。在 `handler` 返回后连接会自动关闭。

在以下情况下服务器会调用调用 `handler` :

- `'Connection: close'` 出现于请求或响应中。
- 在写入响应时发生未预期错误。

`handler` 不允许留有对 `ctx` 成员的引用。

包含 `'Connection: Upgrade'` 的协议可能由 `HijackHandler` 实现。例如：

- WebSocket ( https://en.wikipedia.org/wiki/WebSocket )
- HTTP/2.0 ( https://en.wikipedia.org/wiki/HTTP/2 )

#### func (*RequestCtx) Host

```go
func (ctx *RequestCtx) Host() []byte
```

`Host` 返回请求的 host 。

在 `RequestHandler` 返回前，这个返回值都是合法的。

#### func (*RequestCtx) ID

```go
func (ctx *RequestCtx) ID() uint64
```

`ID` 返回请求的唯一 ID 。

#### func (*RequestCtx) IfModifiedSince

```go
func (ctx *RequestCtx) IfModifiedSince(lastModified time.Time) bool
```

`IfModifiedSince` 在当 `lastModified` 超过 `'If-Modified-Since'` 值时返回 `true` 。

当 `'If-Modified-Since'` 请求头缺失时，这个函数也返回 `true` 。

#### func (*RequestCtx) Init

```go
func (ctx *RequestCtx) Init(req *Request, remoteAddr net.Addr, logger Logger)
```

`Init` 准备传递给 `RequestHandler` 的 `ctx` 。

`remoteAddr` 和 `logger` 是可选的。它们被 `RequestCtx.Logger()` 使用。

这个函数可能会被自定义的服务器实现所使用。

#### func (*RequestCtx) Init2

```go
func (ctx *RequestCtx) Init2(conn net.Conn, logger Logger, reduceMemoryUsage bool)
```

`Init2` 准备传递给 `RequestHandler` 的 `ctx` 。

`conn` 仅用于决定本地或远程地址。

这个函数可能会被自定义的服务器实现所使用。详情参阅 https://github.com/valyala/httpteleport 。

#### func (*RequestCtx) IsBodyStream

```go
func (ctx *RequestCtx) IsBodyStream() bool
```

`IsBodyStream` 在响应体被通过 `SetBodyStream*` 设置时返回 `true` 。

#### func (*RequestCtx) IsDelete

```go
func (ctx *RequestCtx) IsDelete() bool
```

`IsDelete` 在请求方法是 DELETE 时返回 `true` 。

#### func (*RequestCtx) IsGet

```go
func (ctx *RequestCtx) IsGet() bool
```

`IsGet` 在请求方法是 GET 时返回 `true` 。

#### func (*RequestCtx) IsHead

```go
func (ctx *RequestCtx) IsHead() bool


`IsHead` 在请求方法是 HEAD 时返回 `true` 。

#### func (*RequestCtx) IsPost

```go
func (ctx *RequestCtx) IsPost() bool
```

`IsPost` 在请求方法是 POST 时返回 `true` 。

#### func (*RequestCtx) IsPut

```go
func (ctx *RequestCtx) IsPut() bool
```

`IsPut` 在请求方法是 PUT 时返回 `true` 。

#### func (*RequestCtx) IsTLS

```go
func (ctx *RequestCtx) IsTLS() bool
```

`IsTLS` 在底层连接为 `tls.Conn` 时返回 `true` 。

`tls.Conn` 是一个加密连接（又称 SSL，HTTPS）。

#### func (*RequestCtx) LastTimeoutErrorResponse

```go
func (ctx *RequestCtx) LastTimeoutErrorResponse() *Response
```

`LastTimeoutErrorResponse` 返回通过 `TimeoutError*` 调用设置的最新超时响应。

这个函数可能会被自定义的服务器实现所使用。

#### func (*RequestCtx) LocalAddr

```go
func (ctx *RequestCtx) LocalAddr() net.Addr
```

`LocalAddr` 返回指定请求的地址。

总是返回非 `nil` 值。

#### func (*RequestCtx) Logger

```go
func (ctx *RequestCtx) Logger() Logger
```

`Logger` 返回一个日志记录器，用于在 `RequestHandler` 内部记录请求相关信息。

通过日志记录器记录的日志包含的信息可以有请求 ID，请求持续时间，本地地址，远程地址，请求方法和请求 url 等等。

在当前请求中，重用该函数返回的日志记录器用于多次记录日志是安全的。

在 `RequestHandler` 返回前，该函数返回的日志记录器都是合法的。

例子：

```go
requestHandler := func(ctx *fasthttp.RequestCtx) {
    if string(ctx.Path()) == "/top-secret" {
        ctx.Logger().Printf("Alarm! Alien intrusion detected!")
        ctx.Error("Access denied!", fasthttp.StatusForbidden)
        return
    }

    // 日志记录器可能被本地变量缓存。
    logger := ctx.Logger()

    logger.Printf("Good request from User-Agent %q", ctx.Request.Header.UserAgent())
    fmt.Fprintf(ctx, "Good request to %q", ctx.Path())
    logger.Printf("Multiple log messages may be written during a single request")
}

if err := fasthttp.ListenAndServe(":80", requestHandler); err != nil {
    log.Fatalf("error in ListenAndServe: %s", err)
}
```

#### func (*RequestCtx) Method

```go
func (ctx *RequestCtx) Method() []byte
```

`Method` 返回请求方法。

在 `RequestHandler` 返回前，该函数的返回值都是合法的。

#### func (*RequestCtx) MultipartForm

```go
func (ctx *RequestCtx) MultipartForm() (*multipart.Form, error)
```

`MultipartForm` 返回请求的 multipart 表单信息。

如果请求的 content-type 不是 `'multipart/form-data'` ，则返回 `ErrNoMultipartForm` 。

在 `RequestHandler` 返回后这个文件会被制动删除。所以如果你需要保留它，可以预先移动或拷贝这个文件。

使用 `SaveMultipartFile` 来永久保存这个文件。

在 `RequestHandler` 返回前，这个返回的文件头都是合法的。

更多详情可参阅 `FormFile` 和 `FormValue` 。

#### func (*RequestCtx) NotFound

```go
func (ctx *RequestCtx) NotFound()
```

`NotFound` 重置响应，并且为响应设置 `'404 Not Found'` 状态码。

#### func (*RequestCtx) NotModified

```go
func (ctx *RequestCtx) NotModified()
```

`NotModified` 重置响应，并且为响应设置 `'304 Not Modified'` 状态码。

#### func (*RequestCtx) Path

```go
func (ctx *RequestCtx) Path() []byte
```

`Path` 返回被请求的路径。

在 `RequestHandler` 返回前，这个返回值都是合法的。

#### func (*RequestCtx) PostArgs

```go
func (ctx *RequestCtx) PostArgs() *Args
```

`PostArgs` 返回 POST 参数。

该方法不会返回 `RequestURI` 的查询字符串参数，使用 `QueryArgs` 来替代。

在 `RequestHandler` 返回前，这个返回值都是合法的。

更多详情可参阅 `QueryArgs` ，`FormFile` 和 `FormValue` 。


#### func (*RequestCtx) PostBody

```go
func (ctx *RequestCtx) PostBody() []byte
```

`PostArgs` 返回 POST 请求体。

在 `RequestHandler` 返回前，这个返回值都是合法的。

#### func (*RequestCtx) QueryArgs

```go
func (ctx *RequestCtx) QueryArgs() *Args
```

`QueryArgs` 返回来自 `RequestURI` 的查询字符串参数。

该方法不会返回 POST 请求的参数，使用 `PostArgs()` 来替代。

在 `RequestHandler` 返回前，这个返回值都是合法的。

更多详情可参阅 `PostArgs` ，`FormFile` 和 `FormValue` 。

#### func (*RequestCtx) Redirect

```go
func (ctx *RequestCtx) Redirect(uri string, statusCode int)
```

`Redirect` 设置响应头尾 `'Location: uri'` 并且设置响应的状态码 `statusCode`。

`statusCode` 必须为以下值之一：

- StatusMovedPermanently (301)
- StatusFound (302)
- StatusSeeOther (303)
- StatusTemporaryRedirect (307)

其他状态码都会被 StatusFound (302) 替代。

`uri` 可以是绝对路径也可以是针对当前请求路径的相对路径。

#### func (*RequestCtx) RedirectBytes

```go
func (ctx *RequestCtx) RedirectBytes(uri []byte, statusCode int)
```

`RedirectBytes` 设置响应头尾 `'Location: uri'` 并且设置响应的状态码 `statusCode`。

`statusCode` 必须为以下值之一：

- StatusMovedPermanently (301)
- StatusFound (302)
- StatusSeeOther (303)
- StatusTemporaryRedirect (307)

其他状态码都会被 StatusFound (302) 替代。

`uri` 可以是绝对路径也可以是针对当前请求路径的相对路径。

#### func (*RequestCtx) Referer

```go
func (ctx *RequestCtx) Referer() []byte
```

`Referer` 返回请求的 referer 。

在 `RequestHandler` 返回前，这个返回值都是合法的。

#### func (*RequestCtx) RemoteAddr

```go
func (ctx *RequestCtx) RemoteAddr() net.Addr
```

`RemoteAddr` 返回指定请求的客户端地址。

总是返回非 `nil` 值。

#### func (*RequestCtx) RemoteIP

```go
func (ctx *RequestCtx) RemoteIP() net.IP
```

`RemoteIP` 放回指定请求的客户端 IP 。

总是返回非 `nil` 值。

#### func (*RequestCtx) RequestURI

```go
func (ctx *RequestCtx) RequestURI() []byte
```

`RequestURI` 返回请求 URI 。

在 `RequestHandler` 返回前，这个返回值都是合法的。

#### func (*RequestCtx) ResetBody

```go
func (ctx *RequestCtx) ResetBody()
```

`ResetBody` 重置响应体内容。

#### func (*RequestCtx) SendFile

```go
func (ctx *RequestCtx) SendFile(path string)
```

`SendFile` 从指定路径向响应体发送本地文件内容。

这是 `ServeFile(ctx, path)` 的快捷方式。

`SendFile` 通过 `ctx.Logger` 记录所有发生的错误。

更多详情可参阅 `ServeFile` ，`FSHandler` 和 `FS` 。

#### func (*RequestCtx) SendFileBytes

```go
func (ctx *RequestCtx) SendFileBytes(path []byte)
```

`SendFileBytes` 从指定路径向响应体发送本地文件内容。

这是 `ServeFile(ctx, path)` 的快捷方式。

`SendFile` 通过 `ctx.Logger` 记录所有发生的错误。

更多详情可参阅 `ServeFile` ，`FSHandler` 和 `FS` 。

#### func (*RequestCtx) SetBody

```go
func (ctx *RequestCtx) SetBody(body []byte)
```

`SetBody` 设置响应体为指定值。

在该函数返回后重用 `body` 参数是安全的。

#### func (*RequestCtx) SetBodyStream

```go
func (ctx *RequestCtx) SetBodyStream(bodyStream io.Reader, bodySize int)
```

`SetBodyStream` 设置请求体流，`bodySize` 为可选。

若 `bodySize is >= 0` ，那么 `bodyStream` 在返回 `io.EOF` 前必须提供精确的 `bodySize` 字节数据。

若 `bodySize < 0`，那么 `bodyStream` 会被一直读取至 `io.EOF` 。

如果 `bodyStream` 实现了 `io.Closer` 接口，那么 `bodyStream.Close()` 会在数据都被读取后被调用。

更多详情也可参阅 `SetBodyStreamWriter` 。

#### func (*RequestCtx) SetBodyStreamWriter

```go
func (ctx *RequestCtx) SetBodyStreamWriter(sw StreamWriter)
```

`SetBodyStreamWriter` 为请求体注册指定的 `sw` 。

这个函数可能会在以下情况下被使用：

- 如果请求体过大（大于 10MB）。
- 如果请求体来自慢速的外部源。
- 如果请求体必须通过流传入（又称 `http client push` 或 `chunked transfer-encoding`）。

#### func (*RequestCtx) SetBodyString

```go
func (ctx *RequestCtx) SetBodyString(body string)
```

`SetBodyString` 设置请求体。

#### func (*RequestCtx) SetConnectionClose

```go
func (ctx *RequestCtx) SetConnectionClose()
```

`SetConnectionClose` 设置 `'Connection: close'` 头。

#### func (*RequestCtx)

```go
func (ctx *RequestCtx) SetContentType(contentType string)
```

`SetContentType` 设置响应的 Content-Type 。

#### func (*RequestCtx) SetContentTypeBytes

```go
func (ctx *RequestCtx) SetContentTypeBytes(contentType []byte)
```

`SetContentTypeBytes` 设置响应的 Content-Type 。

在函数返回后再改变 `contentType` 缓冲是安全的。

#### func (*RequestCtx) SetStatusCode

```go
func (ctx *RequestCtx) SetStatusCode(statusCode int)
```

`SetStatusCode` 设置响应的响应状态码。

#### func (*RequestCtx) SetUserValue

```go
func (ctx *RequestCtx) SetUserValue(key string, value interface{})
```

`SetUserValue` 根据 `ctx` 内的指定 `key` 存储指定值（任意对象）。

存储于 `ctx` 内的值可以通过 `UserValue*` 获得。

这个函数在多个请求处理函数间传递任意值时可能有用。

所有值在顶层的 `RequestHandler` 返回后被移除。另外，所有的实现了 `io.Close` 的值的 `Close` 方法都会在被移除时调用。

#### func (*RequestCtx) SetUserValueBytes

```go
func (ctx *RequestCtx) SetUserValueBytes(key []byte, value interface{})
```

`SetUserValueBytes` 根据 `ctx` 内的指定 `key` 存储指定值（任意对象）。

存储于 `ctx` 内的值可以通过 `UserValue*` 获得。

这个函数在多个请求处理函数间传递任意值时可能有用。

所有值在顶层的 `RequestHandler` 返回后被移除。另外，所有的实现了 `io.Close` 的值的 `Close` 方法都会在被移除时调用。

#### func (*RequestCtx) Success

```go
func (ctx *RequestCtx) Success(contentType string, body []byte)
```

`Success` 通过给定值设置响应的 Content-Type 和响应体。

#### func (*RequestCtx) SuccessString

```go
func (ctx *RequestCtx) SuccessString(contentType, body string)
```

`SuccessString` 通过给定值设置响应的 Content-Type 和响应体。

#### func (*RequestCtx) TLSConnectionState

```go
func (ctx *RequestCtx) TLSConnectionState() *tls.ConnectionState
```

`TLSConnectionState` 返回 TLS 连接状态。

如果底层的连接不是 `tls.Conn` 那么该函数返回 `nil` 。

这个返回值可能会被用于鉴别 TLS 版本，客户端证书等等。

#### func (*RequestCtx) Time

```go
func (ctx *RequestCtx) Time() time.Time
```

`Time` 返回 `RequestHandler` 调用时间。

#### func (*RequestCtx) TimeoutError

```go
func (ctx *RequestCtx) TimeoutError(msg string)
```

`TimeoutError` 将响应状态码设置 `StatusRequestTimeout` 并且按指定 `msg` 设置响应体。

在 `TimeoutError` 执行后所有响应的修改都会被忽略。

如果仍有对于 `ctx` 及其成员的引用在其他的 goroutine 中，`TimeoutError` 必须在 `RequestHandler` 返回前调用。

不推荐使用这个函数。更推荐减少在其他 goroutine 里对 `ctx` 的引用，而不是使用该函数。

#### func (*RequestCtx) TimeoutErrorWithCode

```go
func (ctx *RequestCtx) TimeoutErrorWithCode(msg string, statusCode int)
```

`TimeoutErrorWithCode` 将响应状态码设置 `StatusRequestTimeout` 。

在 `TimeoutErrorWithCode` 执行后所有响应的修改都会被忽略。

如果仍有对于 `ctx` 及其成员的引用在其他的 goroutine 中，`TimeoutErrorWithCode` 必须在 `RequestHandler` 返回前调用。

不推荐使用这个函数。更推荐减少在其他 goroutine 里对 `ctx` 的引用，而不是使用该函数。

#### func (*RequestCtx) TimeoutErrorWithResponse

```go
func (ctx *RequestCtx) TimeoutErrorWithResponse(resp *Response)
```

`TimeoutErrorWithResponse` 将响应状态码设置 `StatusRequestTimeout` 并且发送对应响应给客户端。

在 `TimeoutErrorWithResponse` 执行后所有响应的修改都会被忽略。

如果仍有对于 `ctx` 及其成员的引用在其他的 goroutine 中，`TimeoutErrorWithResponse` 必须在 `RequestHandler` 返回前调用。

不推荐使用这个函数。更推荐减少在其他 goroutine 里对 `ctx` 的引用，而不是使用该函数。

#### func (*RequestCtx) URI

```go
func (ctx *RequestCtx) URI() *URI
```

`URI` 返回请求的 uri 。

在 `RequestHandler` 返回前，这个返回值都是合法的。

#### func (*RequestCtx) UserAgent

```go
func (ctx *RequestCtx) UserAgent() []byte
```

`UserAgent` 返回来自请求的 User-Agent 头的值。

#### func (*RequestCtx) UserValue

```go
func (ctx *RequestCtx) UserValue(key string) interface{}
```

`UserValue` 按 `key` 返回通过 `SetUserValue*` 设置的值。

#### func (*RequestCtx) UserValueBytes

```go
func (ctx *RequestCtx) UserValueBytes(key []byte) interface{}
```

`UserValueBytes` 按 `key` 返回通过 `SetUserValue*` 设置的值。

#### func (*RequestCtx) VisitUserValues

```go
func (ctx *RequestCtx) VisitUserValues(visitor func([]byte, interface{}))
```

`VisitUserValues` 对每一个存在的 `userValue` 调用 `visitor` 。

`visitor` 在返回后不能再保留对 `userValue` 的引用。如果你还想只用它们，请拷贝一份副本。

#### func (*RequestCtx) Write

```go
func (ctx *RequestCtx) Write(p []byte) (int, error)
```

`Write` 向响应体写入 `p` 。

#### func (*RequestCtx) WriteString

```go
func (ctx *RequestCtx) WriteString(s string) (int, error)
```

`WriteString` 向响应体追加 `s` 。

### type RequestHandler

```go
type RequestHandler func(ctx *RequestCtx)
```

`RequestHandler` 必须处理收到的请求。

如果要在该函数返回后仍保持对 `ctx` 或其成员的引用，必须在返回之前调用 `ctx.TimeoutError()` 。如果响应时间有限制，可以考虑使用 `TimeoutHandler` 包裹 `RequestHandler` 。

#### func CompressHandler

```go
func CompressHandler(h RequestHandler) RequestHandler
```

`CompressHandler` 在当请求头 `'Accept-Encoding'` 包含 `gzip` 或 `deflate` 时，压缩响应体。

#### func CompressHandlerLevel

```go
func CompressHandlerLevel(h RequestHandler, level int) RequestHandler
```

`CompressHandler` 在当请求头 `'Accept-Encoding'` 包含 `gzip` 或 `deflate` 时，通过指定级别压缩响应体。

可选的级别有：

- CompressNoCompression
- CompressBestSpeed
- CompressBestCompression
- CompressDefaultCompression

#### func FSHandler

```go
func FSHandler(root string, stripSlashes int) RequestHandler
```

`FSHandler` 返回用于根据根目录响应静态文件的 handler 。

`stripSlashes` 表明在根目录下搜索请求的文件时，有多少目录分隔符被移除。例子：

- stripSlashes = 0, 原路径： "/foo/bar", 结果： "/foo/bar"
- stripSlashes = 1, 原路径： "/foo/bar", 结果： "/bar"
- stripSlashes = 2, 原路径： "/foo/bar", 结果： ""

返回的请求 handler 会自动生成默认首页如果目录不包含 index.html 。

返回的 handler 根据 `FS.CacheDuration` 来缓存请求的文件句柄。若 `FS.Root` 目录包含大量文件，请确保你的程序通过 `'ulimit -n'` 来保证有足够的“可打开文件”。

不需要对单个 `FS` 实例创建多个请求 handler ，只需重用即可。

#### func TimeoutHandler

```go
func TimeoutHandler(h RequestHandler, timeout time.Duration, msg string) RequestHandler
```

`TimeoutHandler` 创建一个在指定超时时间内 `h` 没有返回时返回 `StatusRequestTimeout` 错误的 `RequestHandler` 。

### type RequestHeader

```go
type RequestHeader struct {
    // 包含被过滤或未导出的属性
}
```

`RequestHeader` 代表 HTTP 请求头。

拷贝 `RequestHeader` 实例是禁止的。你需要创建一个新实例或使用 `CopyTo` 。

`RequestHeader` 不能在多个运行的 goroutine 间使用。

#### func (*RequestHeader) Add

```go
func (h *RequestHeader) Add(key, value string)
```

`Add` 添加 `'key=value'` 参数。

同一个 `key` 可以添加多个值。

#### func (*RequestHeader) AddBytesK

```go
func (h *RequestHeader) AddBytesK(key []byte, value string)
```

`AddBytesK` 添加 `'key=value'` 参数。

同一个 `key` 可以添加多个值。

#### func (*RequestHeader) AddBytesKV

```go
func (h *RequestHeader) AddBytesKV(key, value []byte)
```

`AddBytesKV` 添加 `'key=value'` 参数。

同一个 `key` 可以添加多个值。

#### func (*RequestHeader) AddBytesV

```go
func (h *RequestHeader) AddBytesV(key string, value []byte)
```

`AddBytesV` 添加 `'key=value'` 参数。

同一个 `key` 可以添加多个值。

#### func (*RequestHeader) AppendBytes

```go
func (h *RequestHeader) AppendBytes(dst []byte) []byte
```

`AppendBytes` 像 `dst` 追加请求头字符串，并返回 `dst` 。

#### func (*RequestHeader) ConnectionClose

```go
func (h *RequestHeader) ConnectionClose() bool
```

`ConnectionClose` 在 `'Connection: close'` 头被设置时返回 `true` 。

#### func (*RequestHeader) ConnectionUpgrade

```go
func (h *RequestHeader) ConnectionUpgrade() bool
```

`ConnectionUpgrade` 在 `'Connection: Upgrade` 头被设置时返回 `true` 。

#### func (*RequestHeader) ContentLength

```go
func (h *RequestHeader) ContentLength() int
```

`ContentLength` 返回 Content-Length 头的值。

当请求头包含 Transfer-Encoding: chunked 它可能为 `-1` 。

#### func (*RequestHeader) ContentType

```go
func (h *RequestHeader) ContentType() []byte
```

`ContentType` 返回 Content-Type 头的值。

#### func (*RequestHeader) Cookie

```go
func (h *RequestHeader) Cookie(key string) []byte
```

`Cookie` 根据指定 `key` 返回 cookie 。

#### func (*RequestHeader) CookieBytes

```go
func (h *RequestHeader) CookieBytes(key []byte) []byte
```

`CookieBytes` 根据指定 `key` 返回 cookie 。

#### func (*RequestHeader) CopyTo

```go
func (h *RequestHeader) CopyTo(dst *RequestHeader)
```

`CopyTo` 拷贝所有头至 `dst` 。

#### func (*RequestHeader) Del

```go
func (h *RequestHeader) Del(key string)
```

`Del` 通过指定 `key` 删除头。

#### func (*RequestHeader) DelAllCookies

```go
func (h *RequestHeader) DelAllCookies()
```

`DelAllCookies` 从请求头中删除所有 cookie 。

#### func (*RequestHeader) DelBytes

```go
func (h *RequestHeader) DelBytes(key []byte)
```

`DelBytes` 通过指定 `key` 删除头。

#### func (*RequestHeader) DelCookie

```go
func (h *RequestHeader) DelCookie(key string)
```

`DelCookie` 通过指定 `key` 删除 cookie 。

#### func (*RequestHeader) DelCookieBytes

```go
func (h *RequestHeader) DelCookieBytes(key []byte)
```

`DelCookieBytes` 通过指定 `key` 删除 cookie 。

#### func (*RequestHeader) DisableNormalizing

```go
func (h *RequestHeader) DisableNormalizing()
```

`DisableNormalizing` 关闭头名字的标准化。

标准化后的头键由一个大写字母开头。在 `-` 后的第一个字母也为大写。其他的所有字母则都为小写。例子：

- coNTENT-TYPe -> Content-Type
- HOST -> Host
- foo-bar-baz -> Foo-Bar-Baz

#### func (*RequestHeader) HasAcceptEncoding

```go
func (h *RequestHeader) HasAcceptEncoding(acceptEncoding string) bool
```

`HasAcceptEncoding` 当请求头包含 `Accept-Encoding` 时返回 `true` 。

#### func (*RequestHeader) HasAcceptEncodingBytes

```go
func (h *RequestHeader) HasAcceptEncodingBytes(acceptEncoding []byte) bool
```

`HasAcceptEncodingBytes` 当请求头包含 `Accept-Encoding` 值时返回 `true` 。

#### func (*RequestHeader) Header

```go
func (h *RequestHeader) Header() []byte
```

`Header` 返回请求头的字节表示。

在下次调用 `RequestHeader` 方法前，返回值都是合法的。

#### func (*RequestHeader) Host

```go
func (h *RequestHeader) Host() []byte
```

`Host` 返回 Host 头值。

#### func (*RequestHeader) IsDelete

```go
func (h *RequestHeader) IsDelete() bool
```

`IsDelete` 当请求方法是 DELETE 时返回 `true` 。

#### func (*RequestHeader) IsGet

```go
func (h *RequestHeader) IsGet() bool
```

`IsGet` 当请求方法是 GET 时返回 `true` 。

#### func (*RequestHeader) IsHTTP11

```go
func (h *RequestHeader) IsHTTP11() bool
```

`IsHTTP11` 当请求是 HTTP/1.1 时返回 `true` 。

#### func (*RequestHeader) IsHead

```go
func (h *RequestHeader) IsHead() bool
```

`IsHead` 在请求方法是 HEAD 时返回 `true` 。

#### func (*RequestHeader) IsPost

```go
func (h *RequestHeader) IsPost() bool
```

`IsPost` 在请求方法是 POST 时返回 `true` 。

#### func (*RequestHeader) IsPut

```go
func (h *RequestHeader) IsPut() bool
```

`IsPut` 在请求方法是 PUT 时返回 `true` 。

#### func (*RequestHeader) Len

```go
func (h *RequestHeader) Len() int
```

`Len` 返回被设置的头的数量。

#### func (*RequestHeader) Method

```go
func (h *RequestHeader) Method() []byte
```

`Method` 返回 HTTP 请求方法。

#### func (*RequestHeader) MultipartFormBoundary

```go
func (h *RequestHeader) MultipartFormBoundary() []byte
```

`MultipartFormBoundary` 返回 `'multipart/form-data; boundary=...'` 的 boundary 部分。


#### func (*RequestHeader) Peek

```go
func (h *RequestHeader) Peek(key string) []byte
```

`Peek` 返回请求头中指定 `key` 的值。

#### func (*RequestHeader) PeekBytes

```go
func (h *RequestHeader) PeekBytes(key []byte) []byte
```
`PeekBytes` 返回请求头中指定 `key` 的值。

#### func (*RequestHeader) Read

```go
func (h *RequestHeader) Read(r *bufio.Reader) error
```

`Read` 从 `r` 从读取请求头。

#### func (*RequestHeader) Referer

```go
func (h *RequestHeader) Referer() []byte
```

`Referer` 返回 Referer 头的值。

#### func (*RequestHeader) RequestURI
```go
func (h *RequestHeader) RequestURI() []byte
```

`RequestURI` 从 HTTP 请求的第一行获取请求 URI 。

#### func (*RequestHeader) Reset
```go
func (h *RequestHeader) Reset()
```

`Reset` 清空请求头。

#### func (*RequestHeader) ResetConnectionClose
```go
func (h *RequestHeader) ResetConnectionClose()
```

`ResetConnectionClose` 在 `'Connection: close'` 存在的情况下清空之。

#### func (*RequestHeader) Set
```go
func (h *RequestHeader) Set(key, value string)
```

`Set` 设置指定 `'key: value'` 头。

同一 `key` 可以添加多个值。

#### func (*RequestHeader) SetByteRange
```go
func (h *RequestHeader) SetByteRange(startPos, endPos int)
```

`SetByteRange` 设置指定 `'Range: bytes=startPos-endPos'` 头。

- 如果 `startPos` 为负，那么 `'bytes=-startPos'` 被设置。
- 如果 `endPos` 为负，那么 `'bytes=startPos-'` 被设置。

#### func (*RequestHeader) SetBytesK
```go
func (h *RequestHeader) SetBytesK(key []byte, value string)
```

`SetBytesK` 设置指定 `'key: value'` 头。

同一 `key` 可以添加多个值。

#### func (*RequestHeader) SetBytesKV
```go
func (h *RequestHeader) SetBytesKV(key, value []byte)
```

`SetBytesKV` 设置指定 `'key: value'` 头。

同一 `key` 可以添加多个值。

#### func (*RequestHeader) SetBytesV
```go
func (h *RequestHeader) SetBytesV(key string, value []byte)
```

`SetBytesV` 设置指定 `'key: value'` 头。

同一 `key` 可以添加多个值。

#### func (*RequestHeader) SetCanonical
```go
func (h *RequestHeader) SetCanonical(key, value []byte)
```

`SetCanonical`  在假设 `key` 在表单值内且设置 `'key: value'` 。

#### func (*RequestHeader) SetConnectionClose
```go
func (h *RequestHeader) SetConnectionClose()
```

`SetConnectionClose` 设置指定 `'Connection: close'` 头。

#### func (*RequestHeader) SetContentLength
```go
func (h *RequestHeader) SetContentLength(contentLength int)
```

`SetContentLength` 设置指定 Content-Length 头。

若 `contentLength` 为负，则设置 `'Transfer-Encoding: chunked'` 头。

#### func (*RequestHeader) SetContentType
```go
func (h *RequestHeader) SetContentType(contentType string)
```

`SetContentType` 设置指定 Content-Type 头。

#### func (*RequestHeader) SetContentTypeBytes
```go
func (h *RequestHeader) SetContentTypeBytes(contentType []byte)
```

`SetContentTypeBytes` 设置指定 Content-Type 头。

#### func (*RequestHeader) SetCookie
```go
func (h *RequestHeader) SetCookie(key, value string)
```

`SetCookie` 设置指定 `'key: value'` cookie 。

#### func (*RequestHeader) SetCookieBytesK
```go
func (h *RequestHeader) SetCookieBytesK(key []byte, value string)
```

`SetCookieBytesK` 设置指定 `'key: value'` cookie 。

#### func (*RequestHeader) SetCookieBytesKV
```go
func (h *RequestHeader) SetCookieBytesKV(key, value []byte)
```

`SetCookieBytesKV` 设置指定 `'key: value'` cookie 。

#### func (*RequestHeader) SetHost
```go
func (h *RequestHeader) SetHost(host string)

`SetHost` 设置 Host 头的值。

#### func (*RequestHeader) SetHostBytes
```go
func (h *RequestHeader) SetHostBytes(host []byte)
```

`SetHostBytes` 设置 Host 头的值。

#### func (*RequestHeader) SetMethod
```go
func (h *RequestHeader) SetMethod(method string)
```

`SetMethod` 设置 HTTP 请求方法。

#### func (*RequestHeader) SetMethodBytes
```go
func (h *RequestHeader) SetMethodBytes(method []byte)
```

`SetMethodBytes` 设置 HTTP 请求方法。

#### func (*RequestHeader) SetMultipartFormBoundary
```go
func (h *RequestHeader) SetMultipartFormBoundary(boundary string)
```

`SetMultipartFormBoundary` 设置 `'multipart/form-data; boundary=...'` 的 boundary 部分。

#### func (*RequestHeader) SetMultipartFormBoundaryBytes
```go
func (h *RequestHeader) SetMultipartFormBoundaryBytes(boundary []byte)
```

`SetMultipartFormBoundaryBytes` 设置 `'multipart/form-data; boundary=...'` 的 boundary 部分。

#### func (*RequestHeader) SetReferer
```go
func (h *RequestHeader) SetReferer(referer string)
```

`SetReferer` 设置 Referer 头的值。

#### func (*RequestHeader) SetRefererBytes
```go
func (h *RequestHeader) SetRefererBytes(referer []byte)
```

`SetRefererBytes` 设置 Referer 头的值。

#### func (*RequestHeader) SetRequestURI
```go
func (h *RequestHeader) SetRequestURI(requestURI string)
```

`SetRequestURI` 设置 HTTP 请求第一行的请求 URI 。`requestURI` 必须被适当的加密。如果不确定，请使用 `URI.RequestURI` 来构造合适的 `requestURI` 。

#### func (*RequestHeader) SetRequestURIBytes
```go
func (h *RequestHeader) SetRequestURIBytes(requestURI []byte)
```

`SetRequestURIBytes` 设置 HTTP 请求第一行的请求 URI 。`requestURI` 必须被适当的加密。如果不确定，请使用 `URI.RequestURI` 来构造合适的 `requestURI` 。

#### func (*RequestHeader) SetUserAgent
```go
func (h *RequestHeader) SetUserAgent(userAgent string)
```

`SetUserAgent` 设置 User-Agent 头的值。

#### func (*RequestHeader) SetUserAgentBytes
```go
func (h *RequestHeader) SetUserAgentBytes(userAgent []byte)
```

`SetUserAgentBytes` 设置 User-Agent 头的值。

#### func (*RequestHeader) String
```go
func (h *RequestHeader) String() string
```

`SetUserAgentBytes` 返回请求头的字符串表示。

#### func (*RequestHeader) UserAgent
```go
func (h *RequestHeader) UserAgent() []byte
```

`UserAgent` 返回 User-Agent 头的值。

#### func (*RequestHeader) VisitAll
```go
func (h *RequestHeader) VisitAll(f func(key, value []byte))
```

`VisitAll` 对每一个存在的头调用 `f` 。

`f` 在返回后必须不能保留对键和值的引用。若要在返回后扔需要存储它们，请存储它们的副本。

#### func (*RequestHeader) VisitAllCookie
```go
func (h *RequestHeader) VisitAllCookie(f func(key, value []byte))
```

`VisitAllCookie` 对每一个存在的 cookie 调用 `f` 。

`f` 在返回后必须不能保留对键和值的引用。若要在返回后扔需要存储它们，请存储它们的副本。

#### func (*RequestHeader) Write
```go
func (h *RequestHeader) Write(w *bufio.Writer) error
```

`Write` 将请求头写入 `w` 。

#### func (*RequestHeader) WriteTo
```go
func (h *RequestHeader) WriteTo(w io.Writer) (int64, error)
```

`WriteTo` 将请求头写入 `w` 。

`WriteTo` 实现了 `io.WriterTo` 接口。

### type Response
```go
type Response struct {

    // 响应头
    //
    // 按值拷贝响应头是禁止了。请使用指针替代。
    Header ResponseHeader

    // 若为 true ，Response.Read() 将跳过读取响应体。
    // 用于读取 HEAD 响应。
    //
    // 若为 true ，Response.Write() 将跳过写入响应体。
    // 用于写入 HEAD 响应。
    SkipBody bool

    // 包含被过滤或未导出的属性
}
```

`Response` 代表一个 HTTP 响应。

拷贝 `Response` 实例是禁止的。你需要创建一个新实例或使用 `CopyTo` 。

`Response` 必须不能再多个运行的 goroutine 间使用。

#### func AcquireResponse
```go
func AcquireResponse() *Response
```

`AcquireResponse` 从请求池中返回一个空的 `Response` 实例。

返回的 `Response` 实例在不再需要时可以通过 `ReleaseResponse` 释放回池。这可以降低垃圾回收负载。

#### func (*Response) AppendBody
```go
func (resp *Response) AppendBody(p []byte)
```

`AppendBody` 追加 `p` 至响应体。

在函数返回后重用 `p` 是安全的。

#### func (*Response) AppendBodyString
```go
func (resp *Response) AppendBodyString(s string)
```

`AppendBodyString` 追加 `s` 至响应体。

#### func (*Response) Body
```go
func (resp *Response) Body() []byte
```

`Body` 返回响应体。

#### func (*Response) BodyGunzip
```go
func (resp *Response) BodyGunzip() ([]byte, error)
```

`BodyGunzip` 返回未被 gzip 压缩的响应体数据。

当响应体中包含 `'Content-Encoding: gzip'` 且读取未被 gzip 请求体时，这个方法可能会被使用。使用 `Body` 来读取被 gzip 压缩的响应体。

#### func (*Response) BodyInflate
```go
func (resp *Response) BodyInflate() ([]byte, error)
```

`BodyGunzip` 返回未被压缩的响应体数据。

当响应体中包含 `'Content-Encoding: deflate'` 且读取未被压缩请求体时，这个方法可能会被使用。使用 `Body` 来读取被压缩的响应体。

#### func (*Response) BodyWriteTo
```go
func (resp *Response) BodyWriteTo(w io.Writer) error
```

`BodyWriteTo` 向 `w` 写入响应体。

#### func (*Response) BodyWriter
```go
func (resp *Response) BodyWriter() io.Writer
```

`BodyWriter` 返回用于发送请响应体的 writer 。

#### func (*Response) ConnectionClose
```go
func (resp *Response) ConnectionClose() bool
```

`ConnectionClose` 在 `'Connection: close'` 头被设置时返回 `true` 。

#### func (*Response) CopyTo
```go
func (resp *Response) CopyTo(dst *Response)
```

`CopyTo` 拷贝 `resp` 的内容至 `dst` 。

#### func (*Response) IsBodyStream
```go
func (resp *Response) IsBodyStream() bool
```

`IsBodyStream` 当响应体由 `SetBodyStream*` 设置时返回 `true` 。

#### func (*Response) Read
```go
func (resp *Response) Read(r *bufio.Reader) error
```

`Read` 从指定 `r` 中读取响应（包含响应体）。

如果在读取头的第一字节之前 `r` 被关闭，则返回 `io.EOF` 。

#### func (*Response) ReadLimitBody
```go
func (resp *Response) ReadLimitBody(r *bufio.Reader, maxBodySize int) error
```

`ReadLimitBody` 从指定 `r` 中读取响应（包含响应体），并且响应体大小有限制。

如果 `maxBodySize > 0` 且请求体大于 `maxBodySize` ，会返回 `ErrBodyTooLarge` 。

如果在读取头的第一字节之前 `r` 被关闭，则返回 `io.EOF` 。

#### func (*Response) ReleaseBody
```go
func (resp *Response) ReleaseBody(size int)
```

`ReleaseBody` 当请求体大于 `size` 时释放响应体。

调用它之后，将会允许垃圾回收器回收巨大的缓冲。如果使用这个函数，需要先调用 `ReleaseRequest` 。

一般情况下不会使用这个方法。仅当你十分清楚该方法的工作细节后才可使用它。

#### func (*Response) Reset
```go
func (resp *Response) Reset()
```

`Reset` 清除响应体内容。

#### func (*Response) ResetBody
```go
func (resp *Response) ResetBody()
```

`ResetBody` 清除响应体。

#### func (*Response) SendFile
```go
func (resp *Response) SendFile(path string) error
```

`SendFile` 在指定路径上注册文件，在 `Write` 被调用时用于作为响应体。

注意 `SendFile` 不设置 Content-Type 。你需要手动设置 `Header.SetContentType` 。

#### func (*Response) SetBody
```go
func (resp *Response) SetBody(body []byte)
```

`SetBody` 设置响应体。

在函数返回后，重用 `body` 参数是安全的。

#### func (*Response) SetBodyStream
```go
func (resp *Response) SetBodyStream(bodyStream io.Reader, bodySize int)
```

`SetBodyStream` 设置响应体流，`bodySize` 为可选。

若 `bodySize is >= 0` ，那么 `bodyStream` 在返回 `io.EOF` 前必须提供精确的 `bodySize` 字节数据。

若 `bodySize < 0`，那么 `bodyStream` 会被一直读取至 `io.EOF` 。

如果 `bodyStream` 实现了 `io.Closer` 接口，那么 `bodyStream.Close()` 会在数据都被读取后被调用。

注意 GET 和 HEAD 请求没有请求体。

更多详情也可参阅 `SetBodyStreamWriter` 。


#### func (*Response) SetBodyStreamWriter
```go
func (resp *Response) SetBodyStreamWriter(sw StreamWriter)
```

这个函数可能会在以下情况下被使用：

- 如果响应体过大（大于 10MB）。
- 如果响应体来自慢速的外部源。
- 如果响应体必须通过流传入（又称 `http client push` 或 `chunked transfer-encoding`）。

更多详情也可参阅 `SetBodyStream` 。

#### func (*Response) SetBodyString
```go
func (resp *Response) SetBodyString(body string)
```

`SetBodyString` 设置响应体。

#### func (*Response) SetConnectionClose
```go
func (resp *Response) SetConnectionClose()
```

`SetConnectionClose` 设置 `'Connection: close'` 头。

#### func (*Response) SetStatusCode
```go
func (resp *Response) SetStatusCode(statusCode int)
```

`SetStatusCode` 设置响应的响应状态码。

#### func (*Response) StatusCode
```go
func (resp *Response) StatusCode() int
```

`StatusCode` 返回响应状态码。

#### func (*Response) String
```go
func (resp *Response) String() string
```

`String` 返回响应的字符串表示。

在发生错误时会返回错误信息。

在有性能要求的代码中，请使用 `Write` 来代替 `String` 。

#### func (*Response) SwapBody
```go
func (resp *Response) SwapBody(body []byte) []byte
```

`SwapBody` 使用指定 `body` 来交换响应体，并且返回之前的响应体。

在函数返回后，禁止再使用该 `body` 对象。

#### func (*Response) Write
```go
func (resp *Response) Write(w *bufio.Writer) error
```

`Write` 向 `w` 写入响应。

`Write` 由于性能原因并不会冲刷（flush）响应至 `w` 。

更多详情也可参阅 `WriteTo` 。

#### func (*Response) WriteDeflate
```go
func (resp *Response) WriteDeflate(w *bufio.Writer) error
```

`WriteDeflate` 向 `w` 写入压缩后的响应。

该方法会压缩响应体，并且在向 `w` 写入响应前设置 `'Content-Encoding: deflate'` 头。

`WriteDeflate` 由于性能原因并不会冲刷（flush）响应至 `w` 。

#### func (*Response) WriteDeflateLevel
```go
func (resp *Response) WriteDeflateLevel(w *bufio.Writer, level int) error
```

`WriteDeflateLevel` 向 `w` 写入指定压缩级别压缩后的响应。

支持的压缩级别有：

- `CompressNoCompression`
- `CompressBestSpeed`
- `CompressBestCompression`
- `CompressDefaultCompression`

该方法会压缩响应体，并且在向 `w` 写入响应前设置 `'Content-Encoding: deflate'` 头。

`WriteDeflateLevel` 由于性能原因并不会冲刷（flush）响应至 `w` 。

#### func (*Response) WriteGzip
```go
func (resp *Response) WriteGzip(w *bufio.Writer) error
```

`WriteGzip` 向 `w` 写入 gizp 压缩后的响应。

该方法会压缩响应体，并且在向 `w` 写入响应前设置 `'Content-Encoding: deflate'` 头。

`WriteGzip` 由于性能原因并不会冲刷（flush）响应至 `w` 。

#### func (*Response) WriteGzipLevel
```go
func (resp *Response) WriteGzipLevel(w *bufio.Writer, level int) error
```

`WriteGzipLevel` 向 `w` 写入指定压缩级别 gzip 压缩后的响应。

支持的压缩级别有：

- `CompressNoCompression`
- `CompressBestSpeed`
- `CompressBestCompression`
- `CompressDefaultCompression`

该方法会压缩响应体，并且在向 `w` 写入响应前设置 `'Content-Encoding: deflate'` 头。

`WriteGzipLevel` 由于性能原因并不会冲刷（flush）响应至 `w` 。

#### func (*Response) WriteTo
```go
func (resp *Response) WriteTo(w io.Writer) (int64, error)
```

`WriteTo` 向 `w` 写入响应。它实现了 `io.Writer` 接口。

### type ResponseHeader
```go
type ResponseHeader struct {
    // 包含被过滤或未导出的属性
}
```

`ResponseHeader` 代表了一个 HTTP 响应头。

禁止拷贝 `ResponseHeader` 实例。应该创建新实例或使用 `CopyTo` 。

`ResponseHeader` 实例必须不能再多个运行的 goroutine 间使用。

#### func (*ResponseHeader) Add
```go
func (h *ResponseHeader) Add(key, value string)
```

`Add` 添加 `'key=value'` 头。

同一个 `key` 可以添加多个值。

#### func (*ResponseHeader) AddBytesK
```go
func (h *ResponseHeader) AddBytesK(key []byte, value string)
```

`AddBytesK` 添加 `'key=value'` 头。

同一个 `key` 可以添加多个值。

#### func (*ResponseHeader) AddBytesKV
```go
func (h *ResponseHeader) AddBytesKV(key, value []byte)
```

`AddBytesKV` 添加 `'key=value'` 头。

同一个 `key` 可以添加多个值。

#### func (*ResponseHeader) AddBytesV
```go
func (h *ResponseHeader) AddBytesV(key string, value []byte)
```

`AddBytesV` 添加 `'key=value'` 头。

同一个 `key` 可以添加多个值。

#### func (*ResponseHeader) AppendBytes
```go
func (h *ResponseHeader) AppendBytes(dst []byte) []byte
```

`AppendBytes` 像 `dst` 追加响应头字符串，并返回 `dst` 。

#### func (*ResponseHeader) ConnectionClose
```go
func (h *ResponseHeader) ConnectionClose() bool
```

`ConnectionClose` 在 `'Connection: close'` 头被设置时返回 `true` 。

#### func (*ResponseHeader) ConnectionUpgrade
```go
func (h *ResponseHeader) ConnectionUpgrade() bool
```

`ConnectionUpgrade` 在 `'Connection: Upgrade` 头被设置时返回 `true` 。

#### func (*ResponseHeader) ContentLength
```go
func (h *ResponseHeader) ContentLength() int
```

`ContentLength` 返回 Content-Length 头的值。

当响应头包含 Transfer-Encoding: chunked 它可能为 `-1` 。


#### func (*ResponseHeader) ContentType
```go
func (h *ResponseHeader) ContentType() []byte
```

`ContentType` 返回 Content-Type 头的值。

#### func (*ResponseHeader) Cookie
```go
func (h *ResponseHeader) Cookie(cookie *Cookie) bool
```

`Cookie` 为指定的 `cookie.Key` 填充 cookie 。

如果指定的 `cookie.Key` 不存在，则返回 `false` 。

#### func (*ResponseHeader) CopyTo
```go
func (h *ResponseHeader) CopyTo(dst *ResponseHeader)
```

`CopyTo` 拷贝所有头至 `dst` 。

#### func (*ResponseHeader) Del
```go
func (h *ResponseHeader) Del(key string)
```

`Del` 通过指定 `key` 删除头。

#### func (*ResponseHeader) DelAllCookies
```go
func (h *ResponseHeader) DelAllCookies()
```

`DelAllCookies` 从响应头中删除所有 cookie 。

#### func (*ResponseHeader) DelBytes
```go
func (h *ResponseHeader) DelBytes(key []byte)
```

`DelBytes` 通过指定 `key` 删除头。

#### func (*ResponseHeader) DelClientCookie
```go
func (h *ResponseHeader) DelClientCookie(key string)
```

`DelCookieBytes` 指示客户端移除指定 cookie 。

如果你指向移除响应头中的 cookie ，请使用 `DelCookie` 。

#### func (*ResponseHeader) DelClientCookieBytes
```go
func (h *ResponseHeader) DelClientCookieBytes(key []byte)
```

`DelClientCookieBytes` 指示客户端移除指定 cookie 。

如果你指向移除响应头中的 cookie ，请使用 `DelCookieBytes` 。

#### func (*ResponseHeader) DelCookie
```go
func (h *ResponseHeader) DelCookie(key string)
```

`DelCookie` 通过指定 `key` 删除 cookie 。

若想要指示客户端移除指定 cookie ，请使用 `DelClientCookie` 。

#### func (*ResponseHeader) DelCookieBytes
```go
func (h *ResponseHeader) DelCookieBytes(key []byte)
```

`DelCookieBytes` 通过指定 `key` 删除 cookie 。

若想要指示客户端移除指定 cookie ，请使用 `DelCookieBytes` 。

#### func (*ResponseHeader) DisableNormalizing
```go
func (h *ResponseHeader) DisableNormalizing()
```

`DisableNormalizing` 关闭头名字的标准化。

标准化后的头键由一个大写字母开头。在 `-` 后的第一个字母也为大写。其他的所有字母则都为小写。例子：

- coNTENT-TYPe -> Content-Type
- HOST -> Host
- foo-bar-baz -> Foo-Bar-Baz

#### func (*ResponseHeader) Header
```go
func (h *ResponseHeader) Header() []byte
```

`Header` 返回响应头的字节表示。

在下次调用 `ResponseHeader` 方法前，返回值都是合法的。

#### func (*ResponseHeader) IsHTTP11
```go
func (h *ResponseHeader) IsHTTP11() bool
```

`IsHTTP11` 当响应是 HTTP/1.1 时返回 `true` 。

#### func (*ResponseHeader) Len

```go
func (h *ResponseHeader) Len() int
```

`Len` 返回被设置的头的数量。

#### func (*ResponseHeader) Peek
```go
func (h *ResponseHeader) Peek(key string) []byte
```

`Peek` 返回响应头中指定 `key` 的值。

#### func (*ResponseHeader) PeekBytes
```go
func (h *ResponseHeader) PeekBytes(key []byte) []byte
```

`PeekBytes` 返回响应头中指定 `key` 的值。

#### func (*ResponseHeader) Read
```go
func (h *ResponseHeader) Read(r *bufio.Reader) error
```

`Read` 从 `r` 从读取响应头。

如果在读取第一个头字节前 `r` 被关闭，则返回 `io.EOF` 。

#### func (*ResponseHeader) Reset
```go
func (h *ResponseHeader) Reset()
```

`Reset` 清空响应头。

#### func (*ResponseHeader) ResetConnectionClose
```go
func (h *ResponseHeader) ResetConnectionClose()
```

`ResetConnectionClose` 在 `'Connection: close'` 存在的情况下清空之。

#### func (*ResponseHeader) Server
```go
func (h *ResponseHeader) Server() []byte
```

`Server` 返回服务器 handler 值。

#### func (*ResponseHeader) Set
```go
func (h *ResponseHeader) Set(key, value string)
```

`Set` 设置指定 `'key: value'` 头。

同一 `key` 可以添加多个值。

#### func (*ResponseHeader) SetBytesK
```go
func (h *ResponseHeader) SetBytesK(key []byte, value string)
```

`SetBytesK` 设置指定 `'key: value'` 头。

同一 `key` 可以添加多个值。

#### func (*ResponseHeader) SetBytesKV
```go
func (h *ResponseHeader) SetBytesKV(key, value []byte)
```

`SetBytesKV` 设置指定 `'key: value'` 头。

同一 `key` 可以添加多个值。

#### func (*ResponseHeader) SetBytesV
```go
func (h *ResponseHeader) SetBytesV(key string, value []byte)
```

`SetBytesV` 设置指定 `'key: value'` 头。

同一 `key` 可以添加多个值。

#### func (*ResponseHeader) SetCanonical
```go
func (h *ResponseHeader) SetCanonical(key, value []byte)
```

`SetCanonical`  在假设 `key` 在表单值内且设置 `'key: value'` 。

#### func (*ResponseHeader) SetConnectionClose
```go
func (h *ResponseHeader) SetConnectionClose()
```

`SetConnectionClose` 设置指定 `'Connection: close'` 头。

#### func (*ResponseHeader) SetContentLength
```go
func (h *ResponseHeader) SetContentLength(contentLength int)
```

`SetContentLength` 设置指定 Content-Length 头。

若 `contentLength` 为负，则设置 `'Transfer-Encoding: chunked'` 头。

#### func (*ResponseHeader) SetContentRange
```go
func (h *ResponseHeader) SetContentRange(startPos, endPos, contentLength int)
```

`SetContentRange` 设置指定 `'Content-Range: bytes startPos-endPos/contentLength' ` 头。

#### func (*ResponseHeader) SetContentType
```go
func (h *ResponseHeader) SetContentType(contentType string)
```

`SetContentType` 设置指定 Content-Type 头。

#### func (*ResponseHeader) SetContentTypeBytes
```go
func (h *ResponseHeader) SetContentTypeBytes(contentType []byte)
```

`SetContentTypeBytes` 设置指定 Content-Type 头。

#### func (*ResponseHeader) SetCookie
```go
func (h *ResponseHeader) SetCookie(cookie *Cookie)
```

`SetCookie` 设置指定 `'key: value'` cookie 。

#### func (*ResponseHeader) SetLastModified
```go
func (h *ResponseHeader) SetLastModified(t time.Time)
```

`SetContentTypeBytes` 设置指定 Last-Modified 头。

#### func (*ResponseHeader) SetServer
```go
func (h *ResponseHeader) SetServer(server string)
```

`SetServer` 设置指定 Server 头。

#### func (*ResponseHeader) SetServerBytes
```go
func (h *ResponseHeader) SetServerBytes(server []byte)
```

`SetServerBytes` 设置指定 Server 头。

#### func (*ResponseHeader) SetStatusCode
```go
func (h *ResponseHeader) SetStatusCode(statusCode int)
```

`SetStatusCode` 设置响应的响应状态码。

#### func (*ResponseHeader) StatusCode
```go
func (h *ResponseHeader) StatusCode() int
```

`SetStatusCode` 返回响应的响应状态码。

#### func (*ResponseHeader) String
```go
func (h *ResponseHeader) String() string
```

`String` 返回响应头的字符串表示。

#### func (*ResponseHeader) VisitAll
```go
func (h *ResponseHeader) VisitAll(f func(key, value []byte))
```

`VisitAll` 对每一个存在的头调用 `f` 。

`f` 在返回后必须不能保留对键和值的引用。若要在返回后扔需要存储它们，请存储它们的副本。

#### func (*ResponseHeader) VisitAllCookie
```go
func (h *ResponseHeader) VisitAllCookie(f func(key, value []byte))
```

`VisitAllCookie` 对每一个存在的 cookie 调用 `f` 。

`f` 在返回后必须不能保留对键和值的引用。若要在返回后扔需要存储它们，请存储它们的副本。

#### func (*ResponseHeader) Write
```go
func (h *ResponseHeader) Write(w *bufio.Writer) error
```

`Write` 将响应头写入 `w` 。

#### func (*ResponseHeader) WriteTo
```go
func (h *ResponseHeader) WriteTo(w io.Writer) (int64, error)
```

`WriteTo` 将响应头写入 `w` 。

`WriteTo` 实现了 `io.WriterTo` 接口。

### type Server
```go
type Server struct {

    // Hanlder 为接收请求的处理函数。
    Handler RequestHandler

    // 响应头中 Server 的名字。
    //
    // 若为空，则为默认名。
    Name string

    // 服务器可以同时处理的最大并发连接数。
    //
    // 默认为 DefaultConcurrency
    Concurrency int

    // 是否禁止 keep-alive 连接
    //
    // 如果为 true ，服务器会在发送了第一个响应后关闭连接。
    //
    // 默认为 false 。
    DisableKeepalive bool

    // 每个连接的请求读取可用的缓冲大小。
    // 它也会限制最大头大小。
    //
    // 若你的客户端发送了许多 KB 的 URI 或许多 KB 的头（如大 cookie），请扩大这个值
    //
    // 若不设置则使用默认值。
    ReadBufferSize int

    // 每个连接的响应写入可用的缓冲大小。
    //
    // 若不设置则使用默认值。
    WriteBufferSize int

    // 完整的响应读取（包含响应体）可用的最大时间。
    //
    // 默认为无限制。
    ReadTimeout time.Duration

    // 完整的请求写入（包含请求体）可用的最大时间。
    //
    // 默认为无限制。
    WriteTimeout time.Duration

    MaxConnsPerIP int

    // 每个连接的最大请求数。
    //
    // 默认为无限制。
    MaxRequestsPerConn int

    // keep-alive 连接的最大存在时长。
    //
    // 默认为无限制。
    MaxKeepaliveDuration time.Duration

    // 最大请求提大小。
    //
    // 服务器会拒绝超过此大小的请求。
    //
    // 默认为 DefaultMaxRequestBodySize 。
    MaxRequestBodySize int

    // 使用高 CPU 使用率来减少内存使用。
    //
    // 当存在大量空闲 keep-alive 连接时可以使用这个选项来降低内存消耗。可以降低超过 50 % 。
    // 默认为关闭。
    ReduceMemoryUsage bool

    // 是否值接收 GET 请求。
    // 这个选项在抵挡 DOS 攻击时可能有用。若被设置，则请求体大小会被 ReadBufferSize 限制。
    //
    // 默认接收所有请求。
    GetOnly bool

    // 记录所有错误日志，包括最常见的 'connection reset by peer'，broken pipe' 和 'connection timeout' 。
    //
    // 默认不会记录这些错误。
    LogAllErrors bool

    DisableHeaderNamesNormalizing bool

    // RequestCtx.Logger() 使用的日志记录器。
    //
    // 默认使用标准 logger 库。
    Logger Logger

    // 包含被过滤或未导出的属性
}
```

`Server` 实现了 HTTP 服务器。


默认配置满足了大多数使用者的需求。在理解后果的前提下，你可以修改这些配置。

不允许复制 `Server` 实例。应该创建新实例。

在多个正在运行的 goroutine 间调用 `Server` 方法是安全的。

例子：

```go
// 当每个请求到来时，这个函数都将被调用。
// RequestCtx 提供了很多有用的处理 http 请求的方法。更多详情请参阅 RequestCtx 说明。
requestHandler := func(ctx *fasthttp.RequestCtx) {
    fmt.Fprintf(ctx, "Hello, world! Requested path is %q", ctx.Path())
}

// 创建自定义服务器。
s := &fasthttp.Server{
    Handler: requestHandler,

    // Every response will contain 'Server: My super server' header.
    Name: "My super server",

    // Other Server settings may be set here.
}

if err := s.ListenAndServe("127.0.0.1:80"); err != nil {
    log.Fatalf("error in ListenAndServe: %s", err)
}
```

#### func (*Server) ListenAndServe
```go
func (s *Server) ListenAndServe(addr string) error
```

`ListenAndServe` 使用指定的 `handler` 处理来自指定 TCP 地址 `addr` 的 HTTP 请求。


#### func (*Server) ListenAndServeTLS
```go
func (s *Server) ListenAndServeTLS(addr, certFile, keyFile string) error
```

`ListenAndServeTLS` 使用指定的 `handler` 处理来自指定 TCP 地址 `addr` 的 HTTPS 请求。

`certFile` 和 `keyFile` 是 TLS 证书和密钥文件的路径。

#### func (*Server) ListenAndServeTLSEmbed
```go
func (s *Server) ListenAndServeTLSEmbed(addr string, certData, keyData []byte) error
```

`ListenAndServeTLSEmbed` 使用指定的 `handler` 处理来自指定 TCP 地址 `addr` 的 HTTPS 请求。

`certData` 和 `keyData` 必须包含合法的 TLS 证书和密钥数据。

#### func (*Server) ListenAndServeUNIX
```go
func (s *Server) ListenAndServeUNIX(addr string, mode os.FileMode) error
```

`ListenAndServeUNIX` 使用指定的 `handler` 处理来自指定 UNIX 地址 `addr` 的 HTTP 请求。

这个函数会在开始接受请求前删除所有 `addr` 下的文件。

该函数会为制定 UNIX 地址 `addr` 设置参数中指定的 `mode` 。

#### func (*Server) Serve
```go
func (s *Server) Serve(ln net.Listener) error
```

`Serve` 使用指定的 `handler` 来处理来自 `listener` 的连接。

在 `listener` 返回永久性的错误之前， `Serve` 都会一直保持阻塞。

#### func (*Server) ServeConn
```go
func (s *Server) ServeConn(c net.Conn) error
```

`ServeConn` 使用指定的 `handler` 处理来自指定连接的 HTTP 请求。

如果所有来自 `c` 的请求都被成功处理，`ServeConn` 会返回 `nil` 。否则返回一个非空错误。

连接 `c` 必须立刻将所有数据通过 `Write()` 发送至客户端，否则请求的处理可能会被挂起。

`ServeConn` 在返回之前会关闭 `c` 。

#### func (*Server) ServeTLS
```go
func (s *Server) ServeTLS(ln net.Listener, certFile, keyFile string) error
```

`ServeTLS` 使用指定的 `handler` 来处理来自指定 `net.Listener` 的 HTTPS 请求。

`certFile` 和 `keyFile` 是 TLS 证书和密钥文件的路径。

#### func (*Server) ServeTLSEmbed
```go
func (s *Server) ServeTLSEmbed(ln net.Listener, certData, keyData []byte) error
```

`ServeTLSEmbed` 使用指定的 `handler` 来处理来自指定 `net.Listener` 的 HTTPS 请求。

`certData` 和 `keyData` 必须包含合法的 TLS 证书和密钥数据。

### type StreamWriter
```go
type StreamWriter func(w *bufio.Writer)
```

`StreamWriter` 必须向 `w` 写入数据。

通常 `StreamWriter` 在一个循环（又称 'data streaming'）中向 `w` 写入数据。

当 `w` 返回错误时，必须立刻返回。

由于写入数据是会被缓存的，所以在 reader 读取数据前必须调用 `w.Flush` 。

### type URI
```go
type URI struct {
    // 包含被过滤或未导出的属性
}
```

`URI` 表示 URI ：）。

不允许复制 `URI` 实例。应该创建新实例或使用 `CopyTo`。

不能在多个运行的 goroutine 间使用 `URI` 实例。

#### func AcquireURI
```go
func AcquireURI() *URI
```

`AcquireURI` 从请求池中返回一个空的 `URI` 实例。

返回的 `URI` 实例在不再需要时可以通过 `ReleaseURI` 释放回池。这可以降低垃圾回收负载。

#### func (*URI) AppendBytes
```go
func (u *URI) AppendBytes(dst []byte) []byte
```

`AppendBytes` 像 `dst` 追加完整 uri ，并返回 `dst` 。

#### func (*URI) CopyTo
```go
func (u *URI) CopyTo(dst *URI)
```

`CopyTo` 复制 uri 内容至 `dst` 。

#### func (*URI) FullURI
```go
func (u *URI) FullURI() []byte
```

`FullURI` 返回 {Scheme}://{Host}{RequestURI}#{Hash} 形式的完整 uri 。

#### func (*URI) Hash
```go
func (u *URI) Hash() []byte
```

`Hash` 返回 `URI` 的哈希部分。如 http://aaa.com/foo/bar?baz=123#qwe 中的 qwe 。

在下一次 `URI` 方法被调用前返回值都是合法的。

#### func (*URI) Host
```go
func (u *URI) Host() []byte
```

`Host` 返回 host 部分，如 http://aaa.com/foo/bar?baz=123#qwe 中的 aaa.com 。

返回值总是小写。

#### func (*URI) LastPathSegment
```go
func (u *URI) LastPathSegment() []byte
```

`LastPathSegment` 返回 uri 里最后一个 '/' 后面的部分。

例子：

- /foo/bar/baz.html 返回 baz.html 。
- /foo/bar/ 返回空 byte slice 。
- /foobar.js 返回 foobar.js 。

#### func (*URI) Parse

```go
func (u *URI) Parse(host, uri []byte)
```

`Parse` 根据指定 `host` 和 `uri` 初始化 `URI` 。

#### func (*URI) Path
```go
func (u *URI) Path() []byte
```

`Path` 返回 `URI` path 部分，如 http://aaa.com/foo/bar?baz=123#qwe 中的 /foo/bar 。

返回值总是被 url 解码并且被标准化。如 '//f%20obar/baz/../zzz' 变为 '/f obar/zzz' 。

在下一次 `URI` 方法被调用前返回值都是合法的。

#### func (*URI) PathOriginal
```go
func (u *URI) PathOriginal() []byte
```

`PathOriginal` 返回传递给 `URI.Parse()` 的 `requestURI` 。

在下一次 `URI` 方法被调用前返回值都是合法的。

#### func (*URI) QueryArgs
```go
func (u *URI) QueryArgs() *Args
```

`QueryArgs` 返回查询参数。

#### func (*URI) QueryString
```go
func (u *URI) QueryString() []byte
```

`QueryString` 返回查询字符串。如 http://aaa.com/foo/bar?baz=123#qwe 中的 baz=123 。

在下一次 `URI` 方法被调用前返回值都是合法的。

#### func (*URI) RequestURI
```go
func (u *URI) RequestURI() []byte
```

`RequestURI` 返回 RequestURI ，例如没有 Scheme 和 Host 部分的 URI 。

#### func (*URI) Reset
```go
func (u *URI) Reset()
```

`Reset` 清空 uri 。

#### func (*URI) Scheme
```go
func (u *URI) Scheme() []byte
```

`Scheme` 返回 URI scheme 部分。如 http://aaa.com/foo/bar?baz=123#qwe 中的 http 。

返回值总是小写的。

在下一次 `URI` 方法被调用前返回值都是合法的。

#### func (*URI) SetHash
```go
func (u *URI) SetHash(hash string)
```
SetHash sets URI hash.

#### func (*URI) SetHashBytes
```go
func (u *URI) SetHashBytes(hash []byte)
```
SetHashBytes sets URI hash.

#### func (*URI) SetHost
```go
func (u *URI) SetHost(host string)
```

`SetHost` 设置 uri 的 host 。

#### func (*URI) SetHostBytes
```go
func (u *URI) SetHostBytes(host []byte)
```

`SetHostBytes` 设置 uri 的 host 。

#### func (*URI) SetPath
```go
func (u *URI) SetPath(path string)
```

`SetPath` 设置 uri 的 path 。

#### func (*URI) SetPathBytes
```go
func (u *URI) SetPathBytes(path []byte)
```

`SetPathBytes` 设置 uri 的 path 。

#### func (*URI) SetQueryString
```go
func (u *URI) SetQueryString(queryString string)
```

`SetQueryString` 设置 uri 的查询字符串。

#### func (*URI) SetQueryStringBytes
```go
func (u *URI) SetQueryStringBytes(queryString []byte)
```

`SetQueryStringBytes` 设置 uri 的查询字符串。

#### func (*URI) SetScheme
```go
func (u *URI) SetScheme(scheme string)
```

`SetScheme` 设置 uri 的 scheme ，如 http ，https ，ftp 等等。

#### func (*URI) SetSchemeBytes
```go
func (u *URI) SetSchemeBytes(scheme []byte)
```

`SetSchemeBytes` 设置 uri 的 scheme ，如 http ，https ，ftp 等等。

#### func (*URI) String
```go
func (u *URI) String() string
```

`String` 返回完整 uri 。

#### func (*URI) Update
```go
func (u *URI) Update(newURI string)
```

`Update` 更新 uri 。

以下形式的 `newURI` 是可接受的：

- 绝对路径，如 http://foobar.com/aaa/bb?cc ，这种情况下原 uri 被完整替换。
- 缺少 host ，如 /aaa/bb?cc ，这种情况仅 RequestURI 部分会被替换。
- 相对路径，如xx?yy=abc ，这种情况下原 uri 被根据相对路径更新。

#### func (*URI) UpdateBytes

```go
func (u *URI) UpdateBytes(newURI []byte)
```

`UpdateBytes` 更新 uri 。

以下形式的 `newURI` 是可接受的：

- 绝对路径，如 http://foobar.com/aaa/bb?cc ，这种情况下原 uri 被完整替换。
- 缺少 host ，如 /aaa/bb?cc ，这种情况仅 RequestURI 部分会被替换。
- 相对路径，如xx?yy=abc ，这种情况下原 uri 被根据相对路径更新。

#### func (*URI) WriteTo
```go
func (u *URI) WriteTo(w io.Writer) (int64, error)
```

`WriteTo` 向 `w` 写入完整 uri 。

`WriteTo` 实现了 `io.WriterTo` 接口。

