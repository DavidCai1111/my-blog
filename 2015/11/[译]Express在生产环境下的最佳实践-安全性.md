## 前言

这将是一个分为两部分，内容是关于在生产环境下，跑`Express`应用的最佳实践。第一部分会关注安全性，第二部分最会关注性能和可靠性。当你读这篇文章时，假设你已经对`Node.js`和web开发有所了解，并且对生产环境有了概念。

## 概览

生产环境，指的是软件生命循环中的某个阶段。当一个应用或API已经被它的终端用户所使用时，它便处在了生产环境。相反的，在开发环境下，你任然在不断得修改和测试代码，应用也不能被外部所访问。

开发环境和生产环境经常有很大的配置上的和要求上的不同。一些在开发环境下可以使用的东西，在生产环境下，它们不一定是能够被接受的。例如，在开发环境下，我们需要详细的错误日志信息来帮助我们debug，而在生产环境下，这则会带来安全隐患。又比如，在开发环境下，你不必考虑可伸缩性和可靠性还有性能的问题，但这些在生产环境下都非常重要。

以下是将`Express`应用部署于生产环境中的一些安全性方面的最佳实践。

## 不要使用被弃用或不可靠的`Express`版本

`Express` 2.x 和 3.x 已经不再被维护了。这些版本上的安全和性能问题都将不会被修复。所以不要使用它们！如果你还没有迁移至`Express` 4，可以参考这份[迁移指南][1]。

同时也保证不要使用在[安全更新列表][2]中列出的这些不可靠版本的`Express`。如果你不巧使用了，请升级至稳定版，最好是最新版。

## 使用`TLS`

如果你的应用需要处理或传输敏感数据，请使用`TLS`来确保连接和信息的安全。这项技术会在数据被从客户端发出前加密它。尽管`Ajax`和`POST`请求中发出的数据看上去并不可见，但它们的网络环境仍可以被嗅探和进行中间人攻击。

你可能已经对`SSL`加密有所了解。`TLS`是进化版的`SSL`。换句话说，如果你正在使用`SSL`，请更新成使用`TLS`。大多数情况下，我们推荐使用`Nginx`来处理`TLS`。关于如何在`Nginx`（或其他服务器）上配置`TLS`，请参考[推荐的服务器配置（Mozilla Wiki）][3]。

另外，有一个可以很方便地取得`TLS`证书的工具是[Let’s Encrypt][4]。它是一个免费的，自动化的，开放的`CA`。由`ISRG`提供。

## 使用`Helmet`

`Helmet`通过适当地设置一些HTTP头，来帮助你的应用免受一些广为人知的web攻击。

`Helmet`其实就是九个设置与安全相关的HTTP头的中间件的集合：

 - [csp][5] 设置了`Content-Security-Policy`头来帮助抵挡跨站脚本攻击和其他跨站注入。
 - [hidePoweredBy][6] 移除了`X-Powered-By`头。
 - [hpkp][7] 添加了[Public Key Pinning][8]头来抵挡使用伪造证书的中间人攻击。
 - [hsts][9] 设置了`Strict-Transport-Security`头来强制使用安全连接。
 - [ieNoOpen][10] 为IE8+设置了`X-Download-Options`头。
 - [noCache][11] 设置了`Cache-Control`和`Pragma`头来禁止客户端缓存。
 - [noSniff][12] 设置了`X-Content-Type-Options`头来阻止浏览器进行MIME嗅探。
 - [frameguard][13] 设置了`X-Frame-Options`头来提供对[点击劫持][14]的保护。
 - [xssFilter][15] 设置了`X-XSS-Protection`头来启用大多数现代浏览器中的XSS过滤器。

安装`Helmet`的过程和其他模块没有什么两样：

```SHELL
$ npm install --save helmet
```

然后像其他中间件一样使用它：

```js
...
var helmet = require('helmet');
app.use(helmet());
...
```

### 至少至少，你需要禁用`X-Powered-By`头

如果你不想使用`Helmet`，那么你至少需要禁用`X-Powered-By`头。攻击者可以利用这个头（默认被启用）来了解到你的应用是一个`Express`应用，然后进行有针对性的攻击。

所以，最佳实践是使用`app.disable()`关闭这个头：

```js
app.disable('x-powered-by');
```

如果你使用了`Helmet`，则它会帮你完成这件事。

## 安全地使用cookies

确保不要让cookies暴露了你应用的信息。不要使用默认的`session cookie`名，并且要配置好cookie的安全选项。

`Express`中有两个主要的`cookie session`中间件模块：

 - [express-session][16] 代替了Express 3.x中内建的`express.session`中间件。
 - [cookie-session][17] 代替了Express 3.x中内建的`express.cookieSession`中间件。

这两个模块的主要区别是它们存储`cookie session`的方式。`express-session`在服务端存储`session`信息。它只在cookie中存储`session ID`，而不是session数据。默认情况下，它使用内存存储，在生产环境下，你需要自己配置可伸缩的`session-store`。以下是一个`session-store`的[列表][18]。

相反地，`cookie-session`中间件则把数据都存储在了cookie中：它将整个session序列化至cookie，而不仅仅是一个`session ID`。请仅仅在session数据很小且被早早得加密过时才使用它。浏览器支持的每个cookie的大小通常最多是4093B。所以请确保不要超过它。另外，cookie中的数据时可以被客户端看见的。所以如果你需要对其中的数据进行保密，使用`express-session`将是一个更好的选择。

### 不要使用默认的`session cookie`名

这点和禁用`X-Powered-By`头是类似的。潜在的攻击者可以通过它们进行针对性的攻击。

所以请使用比较普遍的cookie名；如：

```js
var session = require('express-session');
app.set('trust proxy', 1) // trust first proxy
app.use( session({
  secret : 's3Cur3',
  name : 'sessionId',
  })
);
```

### 配置cookie的安全选项

通过配置以下的cookie选项来加强安全性：

 - secure – 确保浏览器使用HTTPS发送cookie。
 - httpOnly – 确保cookie仅通过HTTP(S)被发送，而不是客户端的`JavaScript`。用来帮助抵御跨站脚本攻击。
 - domain – 指定cookie的域。使用它来与将要发送cookie的URL作比较。只有比较结果通过，才会继续检查下面的`path`属性。
 - path – 指定cookie的路径。使用它来比较请求的路径。如果比较结果通过，才会发送cookie。
 - expires – 为持久化的cookie设置过期时间。

以下是一个使用`cookie-session`中间件的例子：

```js
var session = require('cookie-session');
var express = require('express');
var app = express();
var expiryDate = new Date( Date.now() + 60 * 60 * 1000 ); // 1 hour
app.use(session({
  name: 'session',
  keys: ['key1', 'key2'],
  cookie: { secure: true,
          httpOnly: true,
          domain: 'example.com',
          path: 'foo/bar',
          expires: expiryDate
          }
  })
);
```

## 确保你的依赖库都是安全的

使用`npm`来管理你应用的依赖是强大而方便的。但是你的依赖库如果有安全隐患，这也会影响到你的应用。你的应用只会和其最虚弱的那部分一样的健壮。

幸运的是，有两个工具可以帮助你检查第三方库的安全性：[nsp][19]和[requireSafe][20]。这两个工具大致上干了相同的事情，所以选其一使用便好。

`nsp`是一个用来检查你应用的依赖库与它的`Node Security Project`数据库中的存储的漏洞相对比的命令行工具，你可以通过以下方式安装它：

```SHELL
$ npm i nsp -g
```

然后使用以下命令来进行检查你应用的`npm-shrinkwrap.json`和`package.json`：

```SHELL
$ cd your-app
$ nap check
```

使用`requireSafe`的过程也是类似的：

```SHELL
$ npm install -g requiresafe
$ cd your-app
$ require safe check
```

## 其他值得考虑的事

以下是一些从[Node.js安全清单][21]中提出安全建议。详细的建议请自行参阅它：

 - 对应用实现一个访问频率限制机制来抵御暴力破解。你可以使用如[express-limiter][22]这样的中间件。
 - 使用[csurf][23]中间件来抵挡跨站请求伪造（CSRF）。
 - 总是检查和过滤用户的输入，来防止XSS和命令注入。
 - 通过使用参数化的查询（parameterized queries）或预处理语句（prepared statements），来抵挡SQL注入攻击。
 - 使用开源的[sqlmap][24]工具来侦测你的应用中可能被SQL注入的地方。
 - 使用[namp][25]和[sslyze][26]来测试你的SSL配置。
 - 使用[safe-regex][27]来确保你的正则表达式的健壮性。

## 避免其他已知的漏洞

除了`Node Security Project`代替你检查出的`Express`或其他模块的漏洞外。`Express`应用也是一个web应用，所以你也要关注其他相关的已知的web漏洞，并且避免它们。

## 最后

原文链接：https://strongloop.com/strongblog/best-practices-for-express-in-production-part-one-security/

  [1]: http://expressjs.com/guide/migrating-4.html
  [2]: http://expressjs.com/advanced/security-updates.html
  [3]: https://wiki.mozilla.org/Security/Server_Side_TLS#Recommended_Server_Configurations
  [4]: https://letsencrypt.org/about/
  [5]: https://github.com/helmetjs/csp
  [6]: https://github.com/helmetjs/hide-powered-by
  [7]: https://github.com/helmetjs/hpkp
  [8]: https://developer.mozilla.org/en-US/docs/Web/Security/Public_Key_Pinning
  [9]: https://github.com/helmetjs/hsts
  [10]: https://github.com/helmetjs/ienoopen
  [11]: https://github.com/helmetjs/nocache
  [12]: https://github.com/helmetjs/dont-sniff-mimetype
  [13]: https://github.com/helmetjs/frameguard
  [14]: https://www.owasp.org/index.php/Clickjacking
  [15]: https://github.com/helmetjs/x-xss-protection
  [16]: https://www.npmjs.com/package/express-session
  [17]: https://www.npmjs.com/package/cookie-session
  [18]: https://github.com/expressjs/session#compatible-session-stores
  [19]: https://www.npmjs.com/package/nsp
  [20]: https://nodesecurity.io
  [21]: https://github.com/DavidCai1993/my-blog/issues/14
  [22]: https://www.npmjs.com/package/express-limiter
  [23]: https://www.npmjs.com/package/csurf
  [24]: http://sqlmap.org
  [25]: https://nmap.org
  [26]: https://github.com/nabla-c0d3/sslyze
  [27]: https://www.npmjs.com/package/safe-regex
