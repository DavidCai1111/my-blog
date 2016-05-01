如果大家使用 Node.js 写过 web 应用，那么你一定使用过 `http` 模块。在 Node.js 中，起一个 HTTP server 十分简单，短短数行即可：

```js
'use stirct'
const { createServer } = require('http')

createServer(function (req, res) {
  res.writeHead(200, { 'Content-Type': 'text/plain' })
  res.end('Hello World\n')
})
.listen(3000, function () { console.log('Listening on port 3000') })
```

```
$ curl localhost:3000
Hello World
```

就这么简单，因为 Node.js 把许多细节都已在源码中封装好了，主要代码在 `lib/_http_*.js` 这些文件中，现在就让我们照着上述代码，看看从一个 HTTP 请求的到来直到响应，Node.js 都为我们在源码层做了些什么。

## HTTP 请求的来到

在 Node.js 中，若要收到一个 HTTP 请求，首先需要创建一个 `http.Server` 类的实例，然后监听它的 `request` 事件。由于 HTTP 协议属于应用层，在下层的传输层通常使用的是 TCP 协议，所以 `net.Server` 类正是 `http.Server` 类的父类。具体的 HTTP 相关的部分，是通过监听 `net.Server` 类实例的 `connection` 事件封装的：

```js
// lib/_http_server.js
// ...

function Server(requestListener) {
  if (!(this instanceof Server)) return new Server(requestListener);
  net.Server.call(this, { allowHalfOpen: true });

  if (requestListener) {
    this.addListener('request', requestListener);
  }

  // ...
  this.addListener('connection', connectionListener);

  // ...
}
util.inherits(Server, net.Server);
```

这时，则需要一个 HTTP parser 来解析通过 TCP 传输过来的数据：

```js
// lib/_http_server.js
const parsers = common.parsers;
// ...

function connectionListener(socket) {
  // ...
  var parser = parsers.alloc();
  parser.reinitialize(HTTPParser.REQUEST);
  parser.socket = socket;
  socket.parser = parser;
  parser.incoming = null;
  // ...
}
```

值得一提的是，parser 是从一个“池”中获取的，这个“池”使用了一种叫做 *free list*（[wiki][1]）的数据结构，实现很简单，个人觉得是为了尽可能的对 parser 进行重用，并避免了不断调用构造函数的消耗，且设有数量上限（`http` 模块中为 `1000`）：

```js
// lib/freelist.js
'use strict';

exports.FreeList = function(name, max, constructor) {
  this.name = name;
  this.constructor = constructor;
  this.max = max;
  this.list = [];
};


exports.FreeList.prototype.alloc = function() {
  return this.list.length ? this.list.pop() :
                            this.constructor.apply(this, arguments);
};


exports.FreeList.prototype.free = function(obj) {
  if (this.list.length < this.max) {
    this.list.push(obj);
    return true;
  }
  return false;
};
```

由于数据是从 TCP 不断推入的，所以这里的 parser 也是基于事件的，很符合 Node.js 的核心思想。使用的是 [http-parser][2] 这个库：

```js
// lib/_http_common.js
// ...
const binding = process.binding('http_parser');
const HTTPParser = binding.HTTPParser;
const FreeList = require('internal/freelist').FreeList;
// ...

var parsers = new FreeList('parsers', 1000, function() {
  var parser = new HTTPParser(HTTPParser.REQUEST);
  // ...
  parser[kOnHeaders] = parserOnHeaders;
  parser[kOnHeadersComplete] = parserOnHeadersComplete;
  parser[kOnBody] = parserOnBody;
  parser[kOnMessageComplete] = parserOnMessageComplete;
  parser[kOnExecute] = null;

  return parser;
});
exports.parsers = parsers;

// lib/_http_server.js
// ...

function connectionListener(socket) {
  parser.onIncoming = parserOnIncoming;
}
```

所以一个完整的 HTTP 请求从接收到完全解析，会挨个经历 parser 上的如下事件监听器：

1. `parserOnHeaders`：不断解析推入的请求头数据。
2. `parserOnHeadersComplete`：请求头解析完毕，构造 header 对象，为请求体创建 `http.IncomingMessage` 实例。
3. `parserOnBody`：不断解析推入的请求体数据。
4. `parserOnExecute`：请求体解析完毕，检查解析是否报错，若报错，直接触发 `clientError` 事件。若请求为 CONNECT 方法，或带有 Upgrade 头，则直接触发 `connect` 或 `upgrade` 事件。
5. `parserOnIncoming`：处理具体解析完毕的请求。

所以接下来，我们的关注点自然是 `parserOnIncoming` 这个监听器，正是这里完成了最终 `request` 事件的触发，关键步骤代码如下：

```js
// lib/_http_server.js
// ...

function connectionListener(socket) {
  var outgoing = [];
  var incoming = [];
  // ...

  function parserOnIncoming(req, shouldKeepAlive) {
    incoming.push(req);
    // ...
    var res = new ServerResponse(req);

    if (socket._httpMessage) { // 这里判断若为真，则说明 socket 正在被队列中之前的 ServerResponse 实例占用
      outgoing.push(res);
    } else {
      res.assignSocket(socket);
    }

    res.on('finish', resOnFinish);
    function resOnFinish() {
      incoming.shift();
      // ...
      var m = outgoing.shift();
      if (m) {
        m.assignSocket(socket);
      }
    }
    // ...
    self.emit('request', req, res);
  }
}
```

可以看出，对于同一个 socket 发来的请求，源码中分别维护了两个队列，用于缓冲 `IncomingMessage` 实例和对应的 `ServerResponse` 实例。先来的 `ServerResponse` 实例先占用 socket ，监听其 `finish` 事件，从各自队列中释放该 `ServerResponse` 实例和对应的 `IncomingMessage` 实例。

比较绕，以一个简化的图示来总结这部分逻辑：
![3.pic_hd.jpg](//dn-cnode.qbox.me/FjJ05SxuHUVoW1hY6bBFA0i9kRUx)

## 响应该 HTTP 请求

到了响应时，事情已经简单许多了，传入的 `ServerResponse` 已经获取到了 socket。`http.ServerResponse` 继承于一个内部类 `http.OutgoingMessage`，当我们调用 `ServerResponse#writeHead` 时，Node.js 为我们拼凑好了头字符串，并缓存在 `ServerResponse` 实例内部的 `_header` 属性中：

```js
// lib/_http_outgoing.js
// ...

OutgoingMessage.prototype._storeHeader = function(firstLine, headers) {
  // ...
  if (headers) {
    var keys = Object.keys(headers);
    var isArray = Array.isArray(headers);
    var field, value;

    for (var i = 0, l = keys.length; i < l; i++) {
      var key = keys[i];
      if (isArray) {
        field = headers[key][0];
        value = headers[key][1];
      } else {
        field = key;
        value = headers[key];
      }

      if (Array.isArray(value)) {
        for (var j = 0; j < value.length; j++) {
          storeHeader(this, state, field, value[j]);
        }
      } else {
        storeHeader(this, state, field, value);
      }
    }
  }
  // ...
  this._header = state.messageHeader + CRLF;
}
```

紧接着在调用 `ServerResponse#end` 时，将数据拼凑在头字符串后，添加对应的尾部，推入 TCP ，具体的写入操作在内部方法 `ServerResponse#_writeRaw` 中：

```js
// lib/_http_outgoing.js
// ...

OutgoingMessage.prototype.end = function(data, encoding, callback) {
  // ...
  if (this.connection && data)
    this.connection.cork();

  var ret;
  if (data) {
    this.write(data, encoding);
  }

  if (this._hasBody && this.chunkedEncoding) {
    ret = this._send('0\r\n' + this._trailer + '\r\n', 'binary', finish);
  } else {
    ret = this._send('', 'binary', finish);
  }

  if (this.connection && data)
    this.connection.uncork();

  // ...
  return ret;
}

OutgoingMessage.prototype._writeRaw = function(data, encoding, callback) {
  if (typeof encoding === 'function') {
    callback = encoding;
    encoding = null;
  }

  var connection = this.connection;
  // ...
  return connection.write(data, encoding, callback);
};
```

## 最后

到这，一个请求就已经通过 TCP ，发回给客户端了。其实本文中，只涉及到了一条主线进行解析，源码中还考虑了更多的情况，如超时，socket 被占用时的缓存，特殊头，上游突然出现问题，更高效的已写头的查询等等。非常值得一读。

参考：
  - https://github.com/nodejs/node/blob/master/lib/_http_common.js
  - https://github.com/nodejs/node/blob/master/lib/_http_outgoing.js
  - https://github.com/nodejs/node/blob/master/lib/_http_server.js

  [1]: https://en.wikipedia.org/wiki/Free_list
  [2]: https://github.com/nodejs/http-parser