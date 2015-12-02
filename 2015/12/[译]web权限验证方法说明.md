## 前言

本文将会从最基本的一种web权限验证说起，即HTTP Basic authentication，然后是基于cookies和tokens的权限验证，最后则是signatures和一次性密码。

## HTTP Basic authentication

当客户端发起一个请求时，它可以使用HTTP Basic authentication来提供一个用户名和密码，来进行权限验证。

由于它不依赖于cookies，sessions等任何外部因素，所以它是最简单的权限验证方法。在使用它时，客户端需要在每次请求时，都附带上`Authorization`请求头，用户名和密码都不会被加密，但是需要被格式化为以下结构：

 - 用户名和密码由一个冒号连接，如`username:password`
 - 这个字符串需进行Base64编码
 - `Basic`关键字需被放置在这个编码后的字符串的前面

例子：

```SHELL
curl --header "Authorization: Basic am9objpzZWNyZXQ=" my-website.com  
```

在`Node.js`中实现它是非常简单的，以下是一个通过`Express`中间件来实现的例子：

```js
import basicAuth from 'basic-auth';

function unauthorized(res) {  
  res.set('WWW-Authenticate', 'Basic realm=Authorization Required');
  return res.send(401);
};

export default function auth(req, res, next) {
  const {name, pass} = basicAuth(req) || {};

  if (!name || !pass) {
    return unauthorized(res);
  };

  if (name === 'john' && pass === 'secret') {
    return next();
  }
  return unauthorized(res);
};
```

当然，你也可以在更高层上实现它，如`nginx`。

HTTP Basic authentication虽然十分简单，但仍有一些需要注意的地方：

 - 用户名和密码在每次请求时都会被带上，即使请求是通过安全连接发送的，这也是潜在的可能暴露它们的地方。
 - 如果网站使用的加密方法十分弱，或者被破解，那么用户名和密码将会马上泄露。
 - 用户通过这种方式进行验证时，并没有登出的办法
 - 同样，登陆超时也是没有办法做到的，你只能通过修改用户的密码来模拟。

## Cookies

当服务端在响应HTTP请求时，它可以在响应头里加上`Set-Cookie`头。然后浏览器会将这个cookie保存起来，并在以后请求同源的地址时，在`Cookie`请求头中附上这些cookie。

当使用cookies来进行权限验证时，有以下几点需要注意。

### 总是将cookies设为`HttpOnly `

当设置cookies时，总是使用`HttpOnly`标识，这样以来cookies就不能通过`document.cookies`获取，用以减少被XSS攻击可能性。

### 总是使用签名(signed) cookies

当使用签名cookies时，服务器则可以判断该cookie是否被客户端更改过。

不足：

 - 需要花费额外的功夫来抵御CSRF攻击
 - 与REST风格不匹配。因为它在一个无状态协议里注入了状态。

## Tokens

现今，JWT（JSON Web Token）无处不在。让我们先来看看它到底长什么样。

JWT由三部分组成：

 - `Header`，由token的类型和哈希算法组成
 - `Payload`，包含了内容主体
 - `Signature`，当你选择HMAC SHA256算法时，它由`HMACSHA256( base64UrlEncode(header) + "." + base64UrlEncode(payload), secret)`计算得出。

将你的`Koa`应用加上JWT仅需几行代码：

```js
var koa = require('koa');
var jwt = require('koa-jwt');

var app = koa();

app.use(jwt({
  secret: 'very-secret'
}));

// Protected middleware
app.use(function *(){
  // content of the token will be available on this.state.user
  this.body = {
    secret: '42'
  };
});
```

例子：

```SHELL
curl --header "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiYWRtaW4iOnRydWV9.TJVA95OrM7E2cBab30RMHrHDcEfxjoYZgeFONFh7HgQ" my-website.com  
```

如果你在写提供给原生移动应用或单页web应用的API，JWT是一个不错的选择。

不足：

 - 需要额外的措施来防护XSS攻击

## Signatures

不论是使用cookies还是token，如果你传输的内容被他人截获，那么它们将可以很容易得伪装成真实的用户。

如果解决这个问题？当我们讨论的是API之间的通信，而不是浏览器之间的通信时，有一个办法。

当API的消费者发送一个需要权限验证的请求时，你可以对整个请求用一个私钥进行哈希。你可以使用的请求的内容有：

 - HTTP方法
 - 请求路径
 - HTTP头
 - HTTP体
 - 以及一个私钥

API的消费者和提供者都必须持有相同的私钥。在生成了`signature`之后，你必须将其加在`query string`或HTTP头中。另外，还需附上一个时间戳，用于判断过期。

当这么做时，即使你传输的内容暴露了，攻击者也无法伪装成真实用户，因为它无法自己生成`signature`。

不足：

 - 不能用于浏览器/客户端中，只能用于API之间的通信中。

## 一次性密码

一次性密码算法使用一个共享的密钥和一个当前时间戳或计数器来生成一个一次性密码：

 - 基于时间的一次性密码算法，使用一个当前时间的时间戳
 - 基于HMAC的一次性密码算法，使用一个计数器

这些方法被用于双重认证（two-factor authentication）中：一个用户输入了用户名和密码，然后服务器和客户端同时生成一个一次性密码。

在`Node.js`中，使用[notp][1]实现它是相对简单的。

不足：

 - 如果共享密钥被窃取，那么用户的token将可以被伪造

## 该在何时选择何种验证方法？

如果你只需支持一个web应用，那么cookies和tokens的实现都是可以的（cookies对XSRF的防护较好，而JWT则更易于防护XSS）。

如果你需要同时支持web应用和移动客户端，那么请使用基于token的验证。

如果你正在构建仅与其他API通信的API，那么就使用signatures。

## 最后

原文链接：https://blog.risingstack.com/web-authentication-methods-explained/

  [1]: https://github.com/guyht/notp
