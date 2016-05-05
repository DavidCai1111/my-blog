在 Node.js 中，当我们使用 `child_process` 模块创建子进程后，会返回一个 `ChildProcess` 类的实例，通过调用 `ChildProcess#send(message[, sendHandle[, options]][, callback])` 方法，我们可以实现与子进程的通信，其中的 `sendHandle` 参数支持传递 `net.Server` ，`net.Socket` 等多种句柄，使用它，我们可以很轻松的实现在进程间转发 TCP socket：

```js
// parent.js
'use stirct'
const { createServer } = require('net')
const { fork } = require('child_process')

const server = createServer()
const child = fork('./child.js')

server.on('connection', function (socket) {
  child.send('socket', socket)
})
.listen(1337)
```

```js
// child.js
'use strict'

process.on('message', function (message, socket) {
  if (message === 'socket') socket.end('Child handled it.')
})
```

```
$ curl 127.0.0.1:1337
Child handled it.
```

这时你可能就会疑问，此时 socket 已经处在了另一个进程中，那么像 `net.Server#getConnections`，`net.Server#close` 等等这些方法，该怎么实现其功能呢？传递的句柄都是 JavaScript 对象，它们在传递时，序列化和反序列化的机制，又是怎么样的呢？

让我们跟着 Node.js 项目中的 `lib/child_process.js`，`lib/internal/child_process.js`，`lib/internal/process.js` 等文件中的代码，来一探究竟。

## 序列化与反序列化

当使用 `child_process` 模块中的 `fork` 函数创建 `ChildProcess` 类的实例时，会在建立 IPC channel 时，初始化 `ChildProcess#send` 方法：

```js
// lib/internal/child_process.js
// ...

function setupChannel(target, channel) {
  // 此处的 target，即为正在创建的 ChildProcess 类实例
  target._channel = channel;
  target._handleQueue = null;
  // ...

  target.send = function(message, handle, options, callback) {
    // ...
    if (this.connected) {
      return this._send(message, handle, options, callback);
    }
    // ...
  };

  target._send = function(message, handle, options, callback) {
    assert(this.connected || this._channel);
    // ...
    if (handle) {
      message = {
        cmd: 'NODE_HANDLE',
        type: null,
        msg: message
      };

      if (handle instanceof net.Socket) {
        message.type = 'net.Socket';
      } else if (handle instanceof net.Server) {
        message.type = 'net.Server';
      } else if (handle instanceof TCP || handle instanceof Pipe) {
        message.type = 'net.Native';
      } else if (handle instanceof dgram.Socket) {
        message.type = 'dgram.Socket';
      } else if (handle instanceof UDP) {
        message.type = 'dgram.Native';
      } else {
        throw new TypeError('This handle type can\'t be sent');
      }

      var obj = handleConversion[message.type];
      handle = handleConversion[message.type].send.call(target,
                                                        message,
                                                        handle,
                                                        options);
    // ...
    var req = new WriteWrap();
    req.async = false;

    var string = JSON.stringify(message) + '\n';
    var err = channel.writeUtf8String(req, string, handle);
    // ...
  };
}
```

从代码我们可以看到，当我们带着句柄调用 `ChildProcess#send` 方法发送消息时，Node.js 会替我们先将该消息封装成它的内部消息（将消息包在对象中，且对象拥有一个 `cmd` 属性）。句柄的序列化，使用到的是 `handleConversion[message.type].send` 方法，在传递的是 socket 时，即为 `handleConversion['net.Socket'].send`。

所以关键一定就是在 `handleConversion` 这个对象上了，我们先不着急看它的如山真面如。让我们先来看看子进程反序列化时的关键步骤代码。

在子进程启动时，若发现自己是通过 `child_process` 模块创建的进程（环境变量中带有 `NODE_CHANNEL_FD`），则最后也会执行上述的 `lib/internal/child_process.js` 文件中的 `setupChannel` 初始化函数：

```js
// lib/internal/process.js
// ...
function setupChannel() {
  if (process.env.NODE_CHANNEL_FD) {
    var fd = parseInt(process.env.NODE_CHANNEL_FD, 10);
    delete process.env.NODE_CHANNEL_FD;

    var cp = require('child_process');
    // ...
    cp._forkChild(fd);
    assert(process.send);
  }
}

// lib/child_process.js
// ...
const child_process = require('internal/child_process');
const setupChannel = child_process.setupChannel;

exports._forkChild = function(fd) {
  // ...
  const control = setupChannel(process, p);
};
```

以下函数与上上个例子的中函数为同一个，只不过于子进程中执行：

```js
// lib/internal/child_process.js
// ...
function setupChannel(target, channel) {
  target._channel = channel;
  target._handleQueue = null;
  // ...
  target.on('internalMessage', function(message, handle) {
    // ...
    if (message.cmd !== 'NODE_HANDLE') return;
    var obj = handleConversion[message.type];

    obj.got.call(this, message, handle, function(handle) {
      handleMessage(target, message.msg, handle);
    });
  });
}

function handleMessage(target, message, handle) {
  if (!target._channel)
    return;

  var eventName = 'message';
  if (message !== null &&
      typeof message === 'object' &&
      typeof message.cmd === 'string' &&
      message.cmd.length > INTERNAL_PREFIX.length &&
      message.cmd.slice(0, INTERNAL_PREFIX.length) === INTERNAL_PREFIX) {
    eventName = 'internalMessage';
  }
  target.emit(eventName, message, handle);
}
```

显而易见，使用了 `handleConversion[message.type].got` 来进行句柄的反序列化，使之构建成 JavaScript 对象。所以我们不难想到，句柄序列化 & 反序列化运用的就是，各个 `handleConversion[message.type]` 对象中提供的同一方法 `send` 和 `got` 。打个比方就像 Java 中的这些 `class` 都实现了同一个 `interface`：

```js
// lib/internal/child_process.js
// ...

const handleConversion = {
  // ...
  'net.Server': {
    // ...
    send: function(message, server, options) {
      return server._handle;
    },
    got: function(message, handle, emit) {
      var server = new net.Server();
      server.listen(handle, function() {
        emit(server);
      });
    }
  },

  'net.Socket': {
    send: function(message, socket, options) {
      // ...
    },

    got: function(message, handle, emit) {
      // ...
    }
  },
  'dgram.Socket': {
    send: function(message, socket, options) {
      // ...
    },
    got: function(message, handle, emit) {
      // ...
    }
  }
  // ...
};
```

所以传递的过程：

主进程：
  - 传递消息和句柄。
  - 将消息包装成内部消息，使用 `JSON.stringify` 序列化为字符串。
  - 通过对应的 `handleConversion[message.type].send` 方法序列化句柄。
  - 将序列化后的字符串和句柄发入 IPC channel 。

子进程
  - 使用 `JSON.parse` 反序列化消息字符串为消息对象。
  - 触发内部消息事件（`internalMessage`）监听器。
  - 将传递来的句柄使用 `handleConversion[message.type].got` 方法反序列化为 JavaScript 对象。
  - 带着消息对象中的具体消息内容和反序列化后的句柄对象，触发用户级别事件。

## `net.Server#getConnections` 等方法的功能实现

由于将 socket 传递给了子进程之后，`net.Server#getConnections`，`net.Server#close` 等等方法，原来的实现已经无效了，为了保证功能，Node.js 又是怎么办的呢？答案可以大致概括为，父子进程之间，在同一地址下的 socket 传递时，各自都额外维护一个关联列表存储这些 socket 信息和 `ChildProcess` 实例，并且父进程中的 `net#Server` 类实例自己保存下所有父进程关联列表。在调用 `net.Server#getConnections` 这类方法时，遍历列表中的 `ChildPorcess` 实例发送内部消息，子进程列表中的对应项收到内部消息并处理返回，父进程中再结合返回结果和对应着这个 `ChildProcess` 类实例维护的 socket 信息，保证功能的正确性。

`lib/internal/socket_list.js` 这个文件中，分别定义了这两个列表类，分别名为 `SocketListSend` 和 `SocketListReceive`：

```js
// lib/internal/socket_list.js
// ...
function SocketListSend(slave, key) {
  EventEmitter.call(this);

  this.key = key;
  this.slave = slave;
}
util.inherits(SocketListSend, EventEmitter);

// ...
function SocketListReceive(slave, key) {
  EventEmitter.call(this);

  this.connections = 0;
  this.key = key;
  this.slave = slave;
  // ...
}
util.inherits(SocketListReceive, EventEmitter);
```

然后在 `net.Socket` 句柄的序列化和反序列化过程中，将句柄和进程推入列表：

```js
// lib/internal/child_process.js
// ...

const handleConversion = {
  // ...
  send: function(message, socket, options) {
    // ...
    if (socket.server) {
      // ...
      var firstTime = !this._channel.sockets.send[message.key];
      var socketList = getSocketList('send', this, message.key);

      if (firstTime) socket.server._setupSlave(socketList);
    }
    // ...
    return handle;
  },

  got: function(message, handle, emit) {
    var socket = new net.Socket({handle: handle});
    socket.readable = socket.writable = true;
    if (message.key) {
      var socketList = getSocketList('got', this, message.key);
      socketList.add({
        socket: socket
      });
    }

    emit(socket);
  }
}

function getSocketList(type, slave, key) {
  // slave 对象即为当前正在创建的 ChildProcess 类实例
  var sockets = slave._channel.sockets[type];
  var socketList = sockets[key];
  if (!socketList) {
    var Construct = type === 'send' ? SocketListSend : SocketListReceive;
    socketList = sockets[key] = new Construct(slave, key);
  }
  return socketList;
}

// lib/net.js
// ...
Server.prototype._setupSlave = function(socketList) {
  this._usingSlaves = true;
  this._slaves.push(socketList);
};
```

然后在调用具体方法时，遍历列表，结合通信来的结果，再返回：

```js
// lib/net.js
// ...

Server.prototype.getConnections = function(cb) {
  // ...
  if (!this._usingSlaves) {
    return end(null, this._connections);
  }
  var left = this._slaves.length;
  var total = this._connections;

  function oncount(err, count) {
    if (err) {
      left = -1;
      return end(err);
    }

    total += count;
    if (--left === 0) return end(null, total);
  }

  this._slaves.forEach(function(slave) {
    slave.getConnections(oncount);
  });
}
```

即遍历了 `_salves<SocketListSend>` 列表调用各项其上的 `getConnections` 方法（封装了 IPC 通信和内部事件逻辑）。

当我们解析好了 `net.Server#getConnections` 方法后，其他类似需求方法的解决方案，其实也大同小异，思路是一致的。涉及的东西有点多，上一个简单的图示（顺序为黑，蓝，红）：

![2.pic_hd.jpg](//dn-cnode.qbox.me/FmEBE6PkrYsVP28m-Jgu1kuUngkT)

## 最后

参考：
  - https://github.com/nodejs/node/blob/master/lib/child_process.js
  - https://github.com/nodejs/node/blob/master/lib/net.js
  - https://github.com/nodejs/node/blob/master/lib/internal/process.js
  - https://github.com/nodejs/node/blob/master/lib/internal/child_process.js
  - https://github.com/nodejs/node/blob/master/lib/internal/socket_list.js
