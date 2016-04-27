大家可能会好奇，在 Node.js 启动后，第一个执行的 JavaScript 文件会是哪个？它具体又会干些什么事？

一步步来看，翻开 Node.js 的源码，不难看出，入口文件在 `src/node_main.cc` 中，主要任务为将参数传入 `node::Start` 函数：

```c++
// src/node_main.cc
// ...

int main(int argc, char *argv[]) {
  setvbuf(stderr, NULL, _IOLBF, 1024);
  return node::Start(argc, argv);
}
```

`node::Start` 函数定义于 `src/node.cc` 中，它进行了必要的初始化工作后，会调用 `StartNodeInstance` ：

```c++
// src/node.cc
// ...

int Start(int argc, char** argv) {
    // ...
    NodeInstanceData instance_data(NodeInstanceType::MAIN,
                                   uv_default_loop(),
                                   argc,
                                   const_cast<const char**>(argv),
                                   exec_argc,
                                   exec_argv,
                                   use_debug_agent);
    StartNodeInstance(&instance_data);
}
```

而在 `StartNodeInstance` 函数中，又调用了 `LoadEnvironment` 函数，其中的 `ExecuteString(env, MainSource(env), script_name);` 步骤，便执行了第一个 JavaScript 文件代码：

```c++
// src/node.cc
// ...
void LoadEnvironment(Environment* env) {
  // ...
  Local<Value> f_value = ExecuteString(env, MainSource(env), script_name);
  // ...
}

static void StartNodeInstance(void* arg) {
  // ...
  {
      Environment::AsyncCallbackScope callback_scope(env);
      LoadEnvironment(env);
  }
  // ...
}

// src/node_javascript.cc
// ...

Local<String> MainSource(Environment* env) {
  return String::NewFromUtf8(
      env->isolate(),
      reinterpret_cast<const char*>(internal_bootstrap_node_native),
      NewStringType::kNormal,
      sizeof(internal_bootstrap_node_native)).ToLocalChecked();
}
```

其中的 `internal_bootstrap_node_native ` ，即为 `lib/internal/bootstrap_node.js` 中的代码。（注：很多以前的 Node.js 源码分析文章中，所写的第一个执行的 JavaScript 文件代码为 `src/node.js` ，但这个文件在 Node.js v5.10 中已被移除，并被拆解为了 `lib/internal/bootstrap_node.js` 等其他 `lib/internal` 下的文件，PR 为： https://github.com/nodejs/node/pull/5103 ）

## 正文

作为第一段被执行的 JavaScript 代码，它的历史使命免不了就是进行一些环境和全局变量的初始化工作。代码的整体结构很简单，所有的初始化逻辑都被封装在了 `startup` 函数中：

```js
// lib/internal/bootstrap_node.js
'use strict';

(function(process) {
  function startup() {
    // ...
  }
  // ...
  startup();
});
```

而在 `startup` 函数中，逻辑可以分为四块：

  - 初始化全局 `process` 对象上的部分属性 / 行为
  - 初始化全局的一些 `timer` 方法
  - 初始化全局 `console` 等对象
  - 开始执行用户执行指定的 JavaScript 代码

让我们一个个来解析。

### 初始化全局 `process` 对象上的部分属性 / 行为

#### 添加 `process` 上 `uncaughtException` 事件的默认行为

在 Node.js 中，如果没有为 `process` 上的 `uncaughtException` 事件注册监听器，那么该事件触发时，将会导致进程退出，这个行为便是在 `startup` 函数里添加的：

```js
// lib/internal/bootstrap_node.js
'use strict';

(function(process) {
  function startup() {
    setupProcessFatal();
  }
  // ...

  function setupProcessFatal() {

    process._fatalException = function(er) {
      var caught;
      // ...
      if (!caught)
        caught = process.emit('uncaughtException', er);

      if (!caught) {
        try {
          if (!process._exiting) {
            process._exiting = true;
            process.emit('exit', 1);
          }
        } catch (er) {
        }
      }
      // ...
      return caught;
    };
  }
});
```

逻辑十分直白，使用到了 `EventEmitter#emit` 的返回值来判断该事件上是否有注册过的监听器，并最终调用 c++ 的 `exit()` 函数退出进程：

```c++
// src/node.cc
// ...

void FatalException(Isolate* isolate,
                    Local<Value> error,
                    Local<Message> message) {
  // ...
  Local<Value> caught =
      fatal_exception_function->Call(process_object, 1, &error);

  // ...
  if (false == caught->BooleanValue()) {
    ReportException(env, error, message);
    exit(1);
  }
}
```

#### 根据 Node.js 在启动时所带的某些参数，来调整 `process` 上 `warning` 事件触发时的行为

具体来说，这些参数是：`--no-warnings`，`--no-deprecation`，`--trace-deprecation` 和 `--throw-deprecation`。这些参数的有无信息，会先被挂载在 `process` 对象上：

```c++
// src/node.cc
// ...

  if (no_deprecation) {
    READONLY_PROPERTY(process, "noDeprecation", True(env->isolate()));
  }

  if (no_process_warnings) {
    READONLY_PROPERTY(process, "noProcessWarnings", True(env->isolate()));
  }

  if (trace_warnings) {
    READONLY_PROPERTY(process, "traceProcessWarnings", True(env->isolate()));
  }

  if (throw_deprecation) {
    READONLY_PROPERTY(process, "throwDeprecation", True(env->isolate()));
  }
```

然后根据这些信息，控制行为：

```js
// lib/internal/bootstrap_node.js
'use strict';

(function(process) {
  function startup() {
    // ...
    NativeModule.require('internal/process/warning').setup();
  }
  // ...
  startup();
});
```

```js
// lib/internal/process/warning.js
'use strict';

const traceWarnings = process.traceProcessWarnings;
const noDeprecation = process.noDeprecation;
const traceDeprecation = process.traceDeprecation;
const throwDeprecation = process.throwDeprecation;
const prefix = `(${process.release.name}:${process.pid}) `;

exports.setup = setupProcessWarnings;

function setupProcessWarnings() {
  if (!process.noProcessWarnings) {
    process.on('warning', (warning) => {
      if (!(warning instanceof Error)) return;
      const isDeprecation = warning.name === 'DeprecationWarning';
      if (isDeprecation && noDeprecation) return;
      const trace = traceWarnings || (isDeprecation && traceDeprecation);
      if (trace && warning.stack) {
        console.error(`${prefix}${warning.stack}`);
      } else {
        var toString = warning.toString;
        if (typeof toString !== 'function')
          toString = Error.prototype.toString;
        console.error(`${prefix}${toString.apply(warning)}`);
      }
    });
  }
  // ...
}
```

具体行为的话，文档中已经有详细说明，逻辑总结来说，就是按需将警告打印到控制台，或者按需抛出特定的异常。其中 `NativeModule` 对象为 Node.js 在当前的函数体的局部作用域内，实现的一个最小可用的模块加载器，具有缓存等基本功能。

#### 为 `process` 添加上 `stdin`, `stdout` 和 `stderr` 属性

通常为 `tty.ReadStream` 类和 `tty.WriteStream` 类的实例：

```js
// lib/internal/bootstrap_node.js
'use strict';

(function(process) {
  function startup() {
    // ...
    NativeModule.require('internal/process/stdio').setup();
  }
  // ...
  startup();
});
```

```js
// lib/internal/process/stdio.js
// ...

function setupStdio() {
  var stdin, stdout, stderr;

  process.__defineGetter__('stdout', function() {
    if (stdout) return stdout;
    stdout = createWritableStdioStream(1);
    // ...
    return stdout
  }

  process.__defineGetter__('stderr', function() {
    if (stderr) return stderr;
    stderr = createWritableStdioStream(2);
    // ...
    return stderr;
  });

  process.__defineGetter__('stdin', function() {
    if (stdin) return stdin;

    var tty_wrap = process.binding('tty_wrap');
    var fd = 0;

    switch (tty_wrap.guessHandleType(fd)) {
      case 'TTY':
        var tty = require('tty');
        stdin = new tty.ReadStream(fd, {
          highWaterMark: 0,
          readable: true,
          writable: false
        });
        break;
      // ...
    }
    return stdin;
  }
}

function createWritableStdioStream(fd) {
  var stream;
  var tty_wrap = process.binding('tty_wrap');

  // Note stream._type is used for test-module-load-list.js

  switch (tty_wrap.guessHandleType(fd)) {
    case 'TTY':
      var tty = require('tty');
      stream = new tty.WriteStream(fd);
      stream._type = 'tty';
      break;
    // ...
  }
  // ...
}
```

#### 为 `process` 添加上 `nextTick` 方法

具体的做法便是将注册的回调推进队列中，等待事件循环的下一次 Tick ，一个个取出执行：

```js
// lib/internal/bootstrap_node.js
'use strict';

(function(process) {
  function startup() {
    // ...
    NativeModule.require('internal/process/next_tick').setup();
  }
  // ...
  startup();
});
```

```js
// lib/internal/process/next_tick.js
'use strict';

exports.setup = setupNextTick;

function setupNextTick() {
  var nextTickQueue = [];
  // ...
  var kIndex = 0;
  var kLength = 1;

  process.nextTick = nextTick;
  process._tickCallback = _tickCallback;

  function _tickCallback() {
    var callback, args, tock;

    do {
      while (tickInfo[kIndex] < tickInfo[kLength]) {
        tock = nextTickQueue[tickInfo[kIndex]++];
        callback = tock.callback;
        args = tock.args;
        _combinedTickCallback(args, callback);
        if (1e4 < tickInfo[kIndex])
          tickDone();
      }
      tickDone();
    } while (tickInfo[kLength] !== 0);
  }

  function nextTick(callback) {
    if (typeof callback !== 'function')
      throw new TypeError('callback is not a function');
    if (process._exiting)
      return;

    var args;
    if (arguments.length > 1) {
      args = new Array(arguments.length - 1);
      for (var i = 1; i < arguments.length; i++)
        args[i - 1] = arguments[i];
    }

    nextTickQueue.push(new TickObject(callback, args));
    tickInfo[kLength]++;
  }
}
// ...
```

#### 为 `process` 添加上 `hrtime`, `kill`, `exit` 方法

```js
// lib/internal/bootstrap_node.js
'use strict';

(function(process) {
  function startup() {
    // ...
    _process.setup_hrtime();
    _process.setupKillAndExit();
  }
  // ...
  startup();
});
```

这些功能的核心实现也重度依赖于 c++ 函数：

  - `hrtime` 方法依赖于 `libuv` 提供的 `uv_hrtime()` 函数
  - `kill` 方法依赖于 `libuv` 提供的 `uv_kill(pid, sig)` 函数
  - `exit` 方法依赖于 c++ 提供的 `exit(code)` 函数

### 初始化全局的一些 `timer` 方法和 `console` 等对象

这些初始化都干的十分简单，直接赋值：

```js
// lib/internal/bootstrap_node.js
'use strict';

(function(process) {
  function startup() {
    // ...
    setupGlobalVariables();
    if (!process._noBrowserGlobals) {
      setupGlobalTimeouts();
      setupGlobalConsole();
    }

    function setupGlobalVariables() {
      global.process = process;
      // ...
      global.Buffer = NativeModule.require('buffer').Buffer;
      process.domain = null;
      process._exiting = false;
    }

    function setupGlobalTimeouts() {
      const timers = NativeModule.require('timers');
      global.clearImmediate = timers.clearImmediate;
      global.clearInterval = timers.clearInterval;
      global.clearTimeout = timers.clearTimeout;
      global.setImmediate = timers.setImmediate;
      global.setInterval = timers.setInterval;
      global.setTimeout = timers.setTimeout;
    }

    function setupGlobalConsole() {
      global.__defineGetter__('console', function() {
        return NativeModule.require('console');
      });
    }
  }
  // ...
  startup();
});
```

值得注意的一点是，由于 `console` 是通过 `__defineGetter__` 赋值给 `global` 对象的，所以在严格模式下给它赋值将会抛出异常，而非严格模式下，赋值将被忽略。

### 开始执行用户执行指定的 JavaScript 代码

这一部分的逻辑已经在之前的[文章][1]中有所阐述，这边就不再重复说明啦。

## 最后

还是再次总结下:
  - `lib/internal/bootstrap_node.js` 中的代码 为 Node.js 执行后第一段被执行的 JavaScript 代码，从 `src/node.cc` 中的 `node::LoadEnvironment` 被调用
  - `lib/internal/bootstrap_node.js` 主要进行了一些初始化工作：
    - 初始化全局 `process` 对象上的部分属性 / 行为
      - 添加接收到 `uncaughtException` 事件时的默认行为
      - 根据 Node.js 启动时参数，调整 `warning` 事件的行为
      - 添加上 `stdin`，`stdout` 和 `stderr` 属性
      - 添加上 `nextTick`，`hrtime`，`exit` 方法
    - 初始化全局的一些 `timer` 方法
    - 初始化全局 `console` 等对象
    - 开始执行用户执行指定的 JavaScript 代码

参考：

  - https://github.com/nodejs/node/blob/master/src/node.cc
  - https://github.com/nodejs/node/blob/master/src/node_javascript.cc
  - https://github.com/nodejs/node/blob/master/lib/internal/process.js
  - https://github.com/nodejs/node/blob/master/lib/internal/process/next_tick.js
  - https://github.com/nodejs/node/blob/master/lib/internal/process/stdio.js
  - https://github.com/nodejs/node/blob/master/lib/internal/process/warning.js
  - https://github.com/nodejs/node/blob/master/lib/internal/bootstrap_node.js


  [1]: https://github.com/DavidCai1993/my-blog/issues/26