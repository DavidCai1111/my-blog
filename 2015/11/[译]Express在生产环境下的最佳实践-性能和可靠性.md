## 前言

这将是一个分为两部分，内容是关于在生产环境下，跑`Express`应用的最佳实践。第一部分会关注安全性，第二部分则会关注性能和可靠性。当你读这篇文章时，会假设你已经对`Node.js`和web开发有所了解，并且对生产环境有了概念。

关于第一部分，请参阅[Express在生产环境下的最佳实践 - 安全性][1]。

## 概览

正如第一部分所说，生产环境是供你的最终用户们所使用的，而开发环境则是供你开发和测试代码所用。故对于和两个环境的要求，是非常不同的。例如，在开发环境下，你不必考虑伸缩性和可靠性还有性能的问题，但这些在生产环境下都非常重要。

接下来，我们会将此文分为两大部分：

 - 需要对代码做的事，即开发部分。
 - 需要对环境做的事，即运维部分，

## 需要对代码做的事

为了提升你应用的性能，你可以通过：

 - 使用`gzip`压缩
 - 禁止使用同步方法
 - 使用中间件来提供静态文件
 - 适当地打印日志
 - 合理地处理异常


### 使用`gzip`压缩

`Gzip`压缩可以显著地减少你web应用的响应体大小，从而提升你的web应用的响应速度。在`Express`中，你可以使用[compression][2]中间件来启用`gzip`：

```js
var compression = require('compression');
var express = require('express');
var app = express();
app.use(compression());
```

对于在生产环境中，流量十分大的网站，最好是在反向代理层处理压缩。如果这样做，那么就不就需要使用`compression`了，而是需要参阅`Nginx`的`ngx_http_gzip_module`模块的文档。

### 禁止使用同步方法

同步方法会在它返回之前都一直阻塞线程。一次单独的调用可能影响不大，但在流量非常巨大的生产环境中，它是不可接受的，可能会导致严重的性能问题。

虽然大多数的`Node.js`和其第三方库都同时提供了一个方法的同步和异步版本，但在生产环境下，请总是使用它的异步版本。唯一可能例外的场景可能是，如果这个方法只在应用初始化时调用一次，那么使用它的同步版本也是可以接受的。

如果你使用的是`Node.js` 4.0+ 或 `io.js` 2.1.0+ ，你可以在启动应用时附上`--trace-sync-io`参数来检查你的应用中哪里使用了同步API。更多关于这个参数的信息，你可以参阅`io.js` 2.1.0的[更新日志][3]。

### 使用中间件来提供静态文件

在开发环境下，你可以使用`res.sendFile()`来提供静态文件。但在生产环境下，这是不被允许的，因为这个方法会在每次请求时都会对文件系统进行读取。`res.sendFile()`并不是通过系统方法`sendfile`实现的。

对应的，你可以使用[serve-static][4]中间件来为你的`Express`应用提供静态文件。

更好的选择则是在反向代理层上提供静态文件。

### 适当地打印日志

总得来说，为你的应用打印日志的目的有两个：调试和操作记录。在开发环境下，我们通常使用`console.log()`或`console.err()`来做这些事。但是，当这些方法的输出目标是终端或文件时，它们是同步的，所以它们并不适用于生产环境，除非你将输出导流至另一个程序中。

##### 为了调试

如果你正在为了调试而打印日志。那么你可以使用一些专用于调试的库如[debug][5]，用于代替`console.log()`。这个库可以通过设置`DEBUG`环境变量来控制具体哪些信息会被打印。虽然这些方法也是同步的，但你一定不会在生产环境下进行调试吧？

#### 为了操作记录

如果你正在为了记录应用的活动而打印日志。那么你可以使用一些日志库如[winston][6]或[Bunyan][7]，来替代`console.log()`。更多关于这两个库的详情，可以参阅[这里][8]。


### 合理地处理异常

`Node.js`在遇到未处理的异常时就会退出。如果没有合理地捕获并处理异常，这会使你的应用崩溃和离线。如果你使用了一个自动重启的工具，那么你的应用则会在崩溃后立刻重启，而且幸运的是，`Express`应用的重启时间通常都很快。但是不管怎样，你都想要尽量避免这种崩溃。

为了保证你合理处理异常，请遵从以下指示：

 - 使用`try-catch`
 - 使用`promise`

#### 不应该做的事

你不应该监听全局事件`uncaughtException`。监听该事件将会导致进程遇到未处理异常时的行为被改变：进程将会忽略此异常并继续运行。这听上去很好，但是如果你的应用中存在未处理异常，继续运行它是非常危险的，因为应用的状态开始变得不可预测。

所以，监听`uncaughtException`并不是一个好主意，它已被官方地列为了不推荐的做法，并且以后可能会移除这个接口。我们更推荐的是，使用多进程和自动重启。

我们同样不推荐使用`domains`。它通常也并不能解决问题，并且已是一个被标识为弃用的模块。

#### 使用`try-catch`

`Try-catch`是一个`JavaScript`语言自带的捕获同步代码的结构。使用`try-catch`，你可以捕获例如JSON解析错误这样的异常。

使用`JSHint`或`JSLint`这样的工具则可以让你远离引用错误或未定义变量这种隐式的异常。

一个使用`try-catch`来避免进程退出的例子：

```js
// Accepts a JSON in the query field named "params"
// for specifying the parameters
app.get('/search', function (req, res) {
  // Simulating async operation
  setImmediate(function () {
    var jsonStr = req.query.params;
    try {
      var jsonObj = JSON.parse(jsonStr);
      res.send('Success');
    } catch (e) {
      res.status(400).send('Invalid JSON string');
    }
  })
});
```

但是，`try-catch`只能捕获同步代码的异常。但是`Node.js`世界主要是异步的，所以，对于大多数的异常它都无能为力。

#### 使用`promise`

`Promise`可以通过`then()`处理异步代码里的一切异常（显式和隐式）。记得在`promise`链的最后加上`.catch(next)`。例子：

```js
app.get('/', function (req, res, next) {
  // do some sync stuff
  queryDb()
    .then(function (data) {
      // handle data
      return makeCsv(data)
    })
    .then(function (csv) {
      // handle csv
    })
    .catch(next)
})

app.use(function (err, req, res, next) {
  // handle error
})
```

现在所有的同步代码和异步代码的异常都传递到了异常处理中间件中。

但是，仍有两点需要提醒：

所有你的异步代码都必须返回一个`promise`（除了`emitter`）。如果你正在使用的库没有返回一个`promise`，那么就使用一些工具方法（如`Bluebird.promisifyAll()`）来转换它。`Event emitter`（如`stream`）仍会造成未处理的异常。所以你必须合理地监听它们的`error`事件。例子：

```js
app.get('/', wrap(async (req, res, next) =&gt;; {
  let company = await getCompanyById(req.query.id)
  let stream = getLogoStreamById(company.id)
  stream.on('error', next).pipe(res)
}))
```

更多关于使用`promise`处理异常的信息，请参阅[这里][9]。

## 需要对环境做的事

以下是一些你可以对你的系统环境做的事，用于提升你应用的性能：

 - 将`NODE_ENV`设置为`“production”`
 - 保证你的应用在发生错误后自动重启
 - 使用集群模式运行你的应用
 - 缓存请求结果
 - 使用负载均衡
 - 使用反向代理


### 将`NODE_ENV`设置为`“production”`

`NODE_ENV`环境变量指明了应用当前的运行环境（开发或生产）。你可以做的为你的`Express`提升性能的最简单的事情之一，就是将`NODE_ENV`设置为`“production”`。

将`NODE_ENV`设置为`“production”`将使`Express`：

 - 缓存视图模板
 - 缓存CSS文件
 - 生成更简洁的错误信息

如果你想写环境相关的代码，你可以通过`process.env.NODE_ENV`来获取运行时`NODE_ENV`的值。不过需要注意的，检查环境变量的值会造成少许的性能损失，所以不要有太多这类操作。

你可能已经习惯了`SHELL`中设置环境变量，例如使用`export`或`.bash_profile`文件。但是你不应该在你的生产服务器上这么做。你应该使用操作系统的初始化系统（`systemd`或`systemd`）。下一个章节将会更详细的讲述初始化系统，但是由于设置`NODE_ENV`是如此的重要以及简单，所以我们在这里就列出它：

当使用`Upstart`时，请在任务文件中使用`env`关键字。例子：

```SHELL
# /etc/init/env.conf
 env NODE_ENV=production
```

更多信息，请参阅[这里][10]。

当使用`systemd`时，请在你的单元文件中使用`Environment`指令。例子：

```SHELL
# /etc/systemd/system/myservice.service
Environment=NODE_ENV=production
```

更多信息，请参阅[这里][11]。

如果你正在使用`StrongLoop Process Manager`，你也可以参阅[这篇文章][12]。

### 保证你的应用在发生错误后自动重启

在生产环境下，你一定不希望你的应用离线。所以你需要保证在你的应用发生错误时或你的服务器自身崩溃时，你的应用可以自动重启。虽然你可能不期望它们的发生，但是我们需要更现实得预防它们，可以通过：

 - 使用一个进程管理员（process manager）库来重启你的应用
 - 当你的操作系统崩溃时，使用它提供的初始化系统来重启你的进程管理员。

`Node.js`应用在遇到未处理异常时就会退出。你的首要任务是保证你的代码的测试健全并且合理地处理了所有的异常。但是如有万一，请准备一个机制来确保它的自动重启。

#### 使用进程管理员（process manager）

在开发环境下，你可以简单地使用`node server.js`这样的命令来启动你的应用。当时在生产环境下这么做将是不被允许的。如果应用崩溃了，在你手动重启它之前，它都会处于离线状态。为了保证你应用的自动重启，请使用一个进程管理员，它可以帮助你管理正在运行的应用。

除了保证你的应用的自动重启，一个进程管理员还可以使你：

 - 获取当前运行环境的性能表现和资源消耗情况。
 - 自动地修改环境设置
 - 管理集群（`StrongLoop PM`和`pm2`）

`Node.js`世界里比较流行的进程管理员有：

 - StrongLoop Process Manager
 - PM2
 - Forever

更多的它们之间的比较，你可以参阅[这里][13]。关于它们三者的简介，你可以参阅[这篇文章][14]。

#### 使用一个初始化系统

接下来要保证的就是，在你的服务器重启时，你的应用也会相应的重启。尽管我们认为我们的服务器是十分稳定的，但它们仍有挂掉的可能。所以为了保证在你的服务器时重启时你的应用也会重启，请使用你操作系统内建的初始化系统。如今比较主流的是`systemd`和`Upstart`。

以下是通过你的`Express`应用来使用初始化系统的两种方法：

 - 将你的应用运行于一个进程管理员中，然后将进程管理员设置为系统的一个服务。这个是比较推荐的做法。
 - 直接通过初始化系统运行你的应用。这个方法更为简单，但你却享受不到进程管理员带来的福利。

#### Systemd

`Systems`是一个`linux`系统的服务管理员。大多数的`linux`发行版都将它作为默认的初始化系统。

一个`systems`服务的配置文件也被称为一个单元文件，有一个`.service`后缀。以下是一个直接管理`Node.js`应用的例子：

```SHELL
[Unit]
Description=Awesome Express App

[Service]
Type=simple
ExecStart=<strong>/usr/local/bin/node /projects/myapp/index.js</strong>
WorkingDirectory=<strong>/projects/myapp</strong>

User=nobody
Group=nogroup

# Environment variables:
Environment=<strong>NODE_ENV=production</strong>

# Allow many incoming connections
LimitNOFILE=infinity

# Allow core dumps for debugging
LimitCORE=infinity

StandardInput=null
StandardOutput=syslog
StandardError=syslog
Restart=always

[Install]
WantedBy=multi-user.target
```

更多关于`systemd`的信息，请参阅[这里][15]。

#### Upstart

`Upstart`是一个大多数`linux`发行版都可用的系统工具，用于在系统启动时启动任务和服务，在系统关闭时停止它们，并且监控它们。你可以先将你的`Express`应用或进程管理员配置为一个服务，然后`Upstart`会自动地在系统重启后重启它们。

一个`Upstart`服务被定义在一个任务配置文件中，有一个`.conf`后缀。下面的例子展示了如何创建一个名为`“myapp”`的任务，且应用的入口是`/projects/myapp/index.js`。

在`/etc/init/`下创建一个名为`myapp.conf`的文件：

```shell
# When to start the process
start on runlevel [2345]

# When to stop the process
stop on runlevel [016]

# Increase file descriptor limit to be able to handle more requests
limit nofile 50000 50000

# Use production mode
env <strong>NODE_ENV=production</strong>

# Run as www-data
setuid www-data
setgid www-data

# Run from inside the app dir
chdir <strong>/projects/myapp</strong>

# The process to start
exec <strong>/usr/local/bin/node /projects/myapp/index.js</strong>

# Restart the process if it is down
respawn

# Limit restart attempt to 10 times within 10 seconds
respawn limit 10 10
```

注意：这个脚本要求`Upstart` 1.4 或更新的版本，支持于`Ubuntu` 12.04-14.10。

除了自动重启你的应用，`Upstart`还为你提供了以下命令：

 - start myapp – 手动启动应用
 - restart myapp – 手动重启应用
 - stop myapp – 手动退出应用

更多关于`Upstart`的信息，请参阅[这里][16]。

### 使用集群模式运行你的应用

在多核的系统里，你可以通过启动一个进程集群来成倍了提升你应用的性能。一个集群运行了你的应用的多个实例，理想情况下，一个CPU核对应一个实例。这样，便可以在多个实例件进行负载均衡。

值得注意的是，由于应用实例跑在不同的进程里，所以它们并不分享同一块内存空间。因为，应用里的所有对象都是本地的，你不可以在应用代码里维护状态。不过，你可以使用如`redis`这样的内存数据库来存储`session`这样的数据和状态。

在集群中，一个工作进程的崩溃不会影响到其他的工作进程。所以除了性能因素之外，单独工作进程崩溃的相互不影响也是另一个使用集群的好处。一个工作进程崩溃后，请确保记录下日志，然后重新通过`cluster.fork()`创建一个新的工作进程。

#### 使用`Node.js`的`cluster`模块

`Node.js`提供了`cluster`模块来支持集群。它使得一个主进程可以创建出多个工作进程。但是，比起直接使用这个模块，许多的库已经为你封装了它，并提供了更多自动化的功能：如[node-pm][17]或[cluser-service][18]。

### 缓存请求结果

另一个提升你应用性能的途径是缓存请求的结果，这样一来，对于同一个请求，你的应用就不必做多余的重复动作。

使用一个如`Varnish`或`Nginx`这样的缓存服务器可以极大地提升你应用的响应速度。

### 使用负载均衡

不论一个应用优化地多么好，一个单独的实例总是有它的负载上限的。一个很好的解决办法就是将你的应用跑上多个实例，然后在它们之前加上一个负载均衡器。

一个负载均衡器通常是一个反向代理，它接受负载，并将其均匀得分配给各个实例或服务器。你可以通过`Nginx`或`HAProxy`十分方便地架设一个负载均衡器。

使用了负载均衡后，你可以保证每个请求都根据它的来源被设置了独特`session id`。当然，你也可以使用如`Redis`这样的内存数据库来存储`session`。更多详情，可以参阅[这里][19]。

负载均衡是一个相当复杂的话题，更加细致的讨论已超过了本文的范畴。

### 使用反向代理

一个反向代理被设置与web应用之前，用于支持各类对于请求的操作，如将请求发送给应用，自动处理错误页，压缩，缓存，提供静态文件，负载均衡，等等。

在生产环境中，这里推荐将`Express`应用跑在`Nginx`或`HAProxy`之后。

## 最后

原文链接：https://strongloop.com/strongblog/best-practices-for-express-in-production-part-two-performance-and-reliability/

  [1]: http://segmentfault.com/a/1190000003996618
  [2]: https://www.npmjs.com/package/compression
  [3]: https://nodejs.org/en/blog/weekly-updates/weekly-update.2015-05-22/#2-1-0
  [4]: https://www.npmjs.com/package/serve-static
  [5]: https://www.npmjs.com/package/debug
  [6]: https://www.npmjs.com/package/winston
  [7]: https://www.npmjs.com/package/bunyan
  [8]: https://strongloop.com/strongblog/compare-node-js-logging-winston-bunyan/
  [9]: https://strongloop.com/strongblog/async-error-handling-expressjs-es7-promises-generators/
  [10]: http://upstart.ubuntu.com/cookbook/#environment-variables
  [11]: https://coreos.com/os/docs/latest/using-environment-variables-in-systemd-units.html
  [12]: https://docs.strongloop.com/display/SLC/Setting+up+a+production+host#Settingupaproductionhost-Setenvironmentvariables
  [13]: http://strong-pm.io/compare/
  [14]: http://expressjs.com/advanced/pm.html
  [15]: http://www.freedesktop.org/software/systemd/man/systemd.unit.html
  [16]: http://upstart.ubuntu.com/cookbook/
  [17]: https://www.npmjs.com/package/node-pm
  [18]: https://www.npmjs.com/package/cluster-service
  [19]: http://socket.io/docs/using-multiple-nodes/
