前言
--

众所周知，[connect][1]是TJ大神所造的一个大轮子，是大家用`尾式调用`来控制异步流程时最常使用的库，也是后来著名的[express框架][2]的本源。但令人惊讶的是，它的源码其实只有200多行，今天也来解析一下它的真容。

解析
----

以下是connect源码的主要文件结构：

 - lib目录
    - connect.js
    - proto.js
 - index.js

是的，就这三个js文件。。

以下是一个connect的经典用法：
```js
var app = require('connect');
var http = require('http');
app.use('/',function(req,res){
  res.send("haha");
});
app.use('/',function(req,res){
  res.end("hoho");
})
http.createServer(app).listen(3000)
```
可以看到，所有的奥秘，都在于`app`这个变量。让我们先来看看`require('connect')`到底返回的是何物。

#### index.js
```js
module.exports = require('./lib/connect');
//好吧。。这只是一个入口，让我们跟随它的脚步进入./lib/connect.js
```
#### lib/connect.js
```js
var EventEmitter = require('events').EventEmitter;
var merge = require('utils-merge');
var proto = require('./proto');

module.exports = createServer;//对外暴露createServer函数

/**
*  这个函数return出来的app对象便是我们在之前例子中的见到的那个app对象，
*  可以看到他自身便是一个带req,res参数的函数，所以这也是它可以直接
*  作为参数被传递给http.createServer的原因。而且，由于在javascript
*  中，函数也是对象，所以app函数也有自己的属性，他继承了./lib/proto.js
*  中暴露出来的方法，也继承了EventEmitter的原型。可以看到，route属性是
*  用来表示请求路径。stack属性，则是一个存放所有中间件的容器数组。
*/
function createServer() {
  function app(req, res, next){ app.handle(req, res, next); }
  merge(app, proto);
  merge(app, EventEmitter.prototype);
  app.route = '/';
  app.stack = [];
  return app;
}
```
从上面的代码中我们可以发现，自把`app对象`作为参数传递给了`http.createServer`方法形成httpServer实例，并监听了某个端口之后，我们的Server其实是在所有请求的callback里，都执行了`app.handle(req,res,next)`。这个`handle`函数到底是在哪定义的呢？从`merge(app, proto)`这里不难看出，它是从`./lib/proto.js`这里暴露出来的方法。让我们来看看最后还剩的这个`./lib/proto.js`。

#### lib/proto.js

在`proto.js`中，主要暴露出了3个方法，分别为`use`,`handle`和`call`，我们来逐一分解：
```js
/**
 * 这就是我们最后使用app.use()函数，用作添加中间件，route默认为“/”，其最终           
 * 任务为将请求路由与其处理函数绑定为一个形为
 * {route: route , handle : fn}的匿名函数，推入自身的stack数组中。
 */

app.use = function(route, fn){
  //如果第一个参数不是字符串，则路由默认为"/"
  if ('string' != typeof route) {
    fn = route;
    route = '/';
  }

  //如果fn为一个app的实例，则将其自身handle方法的包裹给fn
  if ('function' == typeof fn.handle) {
    var server = fn;
    server.route = route;
    fn = function(req, res, next){
      server.handle(req, res, next);
    };
  }

  //如果fn为一个http.Server实例，则fn为其request事件的第一个监听器
  if (fn instanceof http.Server) {
    fn = fn.listeners('request')[0];
  }

  //如果route参数的以"/"结尾，则删除"/"
  if ('/' == route[route.length - 1]) {
    route = route.slice(0, -1);
  }

  //输出测试信息
  debug('use %s %s', route || '/', fn.name || 'anonymous');
  //将一个包裹route和fn的匿名对象推入stack数组
  this.stack.push({ route: route, handle: fn });

  //返回自身，以便继续链式调用
  return this;
};
```
可以看到这个`use`方法的任务便是`中间件的登记`，这样一来，自身的`stack`数组中变充满了一个个登记了的`{route: route , handle : fn}`匿名函数。为请求到达时，匹配URL，并执行对应的函数，做好了`在一个地点，统一格式化，统一存放`。

接下来我们就看看真正挂在Server里的`handle`处理函数：
```js
/**
 * 这个函数的是为当前请求路径寻找出它的所有handler处理函数，并依次调用call
 * 方法执行（主要做的是大量的缜密的字符串匹配工作,详看内部注释）
 */

app.handle = function(req, res, out) {
  var stack = this.stack
      //req中“？”字符的位置索引，用来判断是否有query string
      , searchIndex = req.url.indexOf('?')
      //获取url的长度（除去query string）
      , pathlength = searchIndex !== -1 ? searchIndex : req.url.length
      //若url以“/”开头，则为false,否则为"://"字符串的位置索引
      , fqdn = req.url[0] !== '/' && 1 + req.url.substr(0, pathlength).indexOf('://')
      //若url不以“/”开头，则protohost为 协议:/(如https:/)
      , protohost = fqdn ? req.url.substr(0, req.url.indexOf('/', 2 + fqdn)) : ''
      , removed = ''
      // 标记：url是否以"/"结尾
      , slashAdded = false
      , index = 0;

  //若含有next（第三个）参数,则继续调用，若无，则使用finalhandler库，作为请求最后的处理函数，若有err则抛出，否则则报404
  var done = out || finalhandler(req, res, {
    env: env,
    onerror: logerror
  });

  req.originalUrl = req.originalUrl || req.url;

  function next(err) {
    //若salshAdded标记为真，则去除最前面的“/”
    if (slashAdded) {
      req.url = req.url.substr(1);
      slashAdded = false;
    }

    if (removed.length !== 0) {
      req.url = protohost + removed + req.url.substr(protohost.length);
      removed = '';
    }

    //取本index的中间件，之后把index+1
    var layer = stack[index++];

    //如果已没有更多中间件，则结束
    if (!layer) {
      defer(done, err);
      return;
    }

    //路由路径
    var path = parseUrl(req).pathname || '/';
    //此中间件的route，用作与path匹配比较
    var route = layer.route;

    //查看当前请求路由是否匹配route,只匹配route长度的字符串，如"/foo/bar"与"/foo"是匹配的
    if (path.toLowerCase().substr(0, route.length) !== route.toLowerCase()) {
      return next(err);
    }

    //如果匹配到的路径不以'/'与‘.’结尾,或已结束，则报错(即上一个if保证了头匹配，这里保证了尾部匹配)
    var c = path[route.length];
    if (c !== undefined && '/' !== c && '.' !== c) {
      return next(err);
    }

    //去除与route不匹配的其他部分
    if (route.length !== 0 && route !== '/') {
      removed = route;
      req.url = protohost + req.url.substr(protohost.length + removed.length);

      //保证路径以"/"开头
      if (!fqdn && req.url[0] !== '/') {
        req.url = '/' + req.url;
        slashAdded = true;
      }
    }

    //调用call函数执行layer
    call(layer.handle, route, err, req, res, next);
  }

  next();
};

```
所以这个`handle`方法的角色只是一个对`请求路径`和`中间件注册路径`的一个匹配者，找出所有相匹配的中间件，并负责把它们一个个`有序(因为中间件也是有序的push进的stack，handle又是靠索引来取的stack里的匿名对象)`传入`call`方法执行。

好，我们来看最后的`call`方法：
```js
/**
 * 主要任务便是执行handler中匹配到的中间件
 */

function call(handle, route, err, req, res, next) {
  //handle函数的参数个数(3个参数为一般中间件，4个参数为错误处理中间件)
  var arity = handle.length;
  //是否有错
  var hasError = Boolean(err);
  //输出测试信息  
  debug('%s %s : %s', handle.name || '<anonymous>', route, req.originalUrl);

  try {
    //执行错误处理中间件
    if (hasError && arity === 4) {
      handle(err, req, res, next);
      return;
    } else if (!hasError && arity < 4) {
      //执行一般中间件
      handle(req, res, next);
      return;
    }
  } catch (e) {
    // reset the error
    err = e;
  }

  next(err);
}
```

所以，可喜可贺，看到这里，我们大概已经摸清了`connect`的庐山真面目了，其整体的结构大致可概括为：

 - 暴露出的app函数（函数体为自己的`handle`方法）
    - 从`proto`处继承的属性（方法）
    - 继承的`EventEmitter`的原型
    - `route`属性，表示中间件的默认请求路径
    - `stack`数组，所有的中间件的存放处，中间件会被格式化成形为`{route: route , handle : fn}`的匿名函数存放
    
而整体的运行过程大致可概括为：
 
- `use`注册中间件
-  Server接受请求
- 调用`handle`检查`stack`数组中注册的中间件与此请求的url是否匹配
- 若匹配到了一个中间件，则调用`call`执行
- 继续寻找是否还有匹配的中间件并执行...
- 登记的中间件全部查询完毕，匹配的中间件全部执行完毕，结束。

  [1]: https://www.npmjs.com/package/connect
  [2]: https://www.npmjs.com/package/express
