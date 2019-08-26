---
title: 通过源码解析Node.js中一个文件被require后所发生的故事
date: 2016-03-27 13:53:22
tags:
---

在 Node.js 中，要说如果有几乎会在每一个文件都要用到的一个全局函数和一个全局对象，那应该是非 `require` 和 `module.exports` 莫属了。它们是 Node.js 模块机制的基石。大家在使用它们享受模块化的好处时，有时也不禁好奇：

 - 为何它俩使用起来像是全局函数/对象，却在 `global` 对象下访问不到它们？

```js
'use strict'
console.log(require) // Function
console.log(module) // Object
console.log(global.require) // undefined
console.log(global.module) // undefined
```
 - 这两个“类全局”对象是在什么时候，怎么生成的？
 - 当 `require` 一个目录时，Node.js 是如何替我们找到具体该执行的文件的？
 - 模块内的代码具体是以何种方式被执行的？
 - 循环依赖了怎么办？

让我们从 Node.js 项目的 `lib/module.js` 中的代码里，细细看一番，一个文件被 `require` 后，具体发生的故事，从而来解答上面这些问题。
<!-- more -->
## 一个文件被 `require` 后所发生的故事

当我们在命令行中敲下：

```sh
node ./index.js
```

之后，`src/node.cc` 中的 `node::LoadEnvironment` 函数会被调用，在该函数内则会接着调用 `src/node.js` 中的代码，并执行 `startup` 函数：

```js
// src/node.js
// ...

function startup() {
  // ...
  Module.runMain();
}

// lib/module.js
// ...

Module.runMain = function() {
  // ...
  Module._load(process.argv[1], null, true);
  // ...
};
```

所以，最后会执行到 `Module._load(process.argv[1], null, true);` 这条语句来加载模块，不过其实，这个`Module._load`在`require`函数的代码中也会被调用：

```js
// lib/module.js
// ...

Module.prototype.require = function(path) {
  assert(path, 'missing path');
  assert(typeof path === 'string', 'path must be a string');
  return Module._load(path, this, false);
};
```

所以说，当我们在命令行中敲下 `node ./index.js`，某种意义上，可以说随后 Node.js 的表现即为立刻进行一次 `require` ， 即：

```js
require('./index.js')
```

随后的步骤就是 `require` 一个普通模块了，让我们继续往下看，`Module._load` 方法做的第一件事，便是调用内部方法 `Module._resolveFilename` ，而该内部方法在进行了一些参数预处理后，最终会调用 `Module._findPath` 方法，来得到需被导入模块的完整路径，让我们从代码中来总结出它的路径分析规则：

```js
// lib/module.js
// ...

Module._findPath = function(request, paths) {
  // 优先取缓存
  var cacheKey = JSON.stringify({request: request, paths: paths});
  if (Module._pathCache[cacheKey]) {
    return Module._pathCache[cacheKey];
  }

  // ...
  for (var i = 0, PL = paths.length; i < PL; i++) {
    if (!trailingSlash) {
      const rc = stat(basePath);
      if (rc === 0) {  // 若是文件.
        filename = toRealPath(basePath);
      } else if (rc === 1) {  // 若是目录
        filename = tryPackage(basePath, exts);
      }

      if (!filename) {
        // 带上 .js .json .node 后缀进行尝试
        filename = tryExtensions(basePath, exts);
      }
    }

    if (!filename) {
      filename = tryPackage(basePath, exts);
    }

    if (!filename) {
      // 尝试 index.js index.json index.node
      filename = tryExtensions(path.resolve(basePath, 'index'), exts);
    }

    if (filename) {
      // ...
      Module._pathCache[cacheKey] = filename;
      return filename;
    }
  }
  return false;
};

function tryPackage(requestPath, exts) {
  var pkg = readPackage(requestPath); // 获取 package.json 中 main 属性的值

  // ...
  return tryFile(filename) || tryExtensions(filename, exts) ||
         tryExtensions(path.resolve(filename, 'index'), exts);
}
```

代码中的条件判断十分清晰，让我们来总结一下：
  - 若模块的路径不以 `/` 结尾，则先检查该路径是否真实存在：
    - 若存在且为一个文件，则直接返回文件路径作为结果。
    - 若存在且为一个目录，则尝试读取该目录下的 `package.json` 中 `main` 属性所指向的文件路径。
      - 判断该文件路径是否存在，若存在，则直接作为结果返回。
      - 尝试在该路径后依次加上 `.js` ， `.json` 和 `.node` 后缀，判断是否存在，若存在则返回加上后缀后的路径。
      - 尝试在该路径后依次加上 `index.js` ， `index.json` 和 `index.node`，判断是否存在，若存在则返回拼接后的路径。
    - 若仍未返回，则为指定的模块路径依次加上 `.js` ， `.json` 和 `.node` 后缀，判断是否存在，若存在则返回加上后缀后的路径。

  - 若模块以 `/` 结尾，则尝试读取该目录下的 `package.json` 中 `main` 属性所指向的文件路径。
    - 判断该文件路径是否存在，若存在，则直接作为结果返回。
    - 尝试在该路径后依次加上 `.js` ， `.json` 和 `.node` 后缀，判断是否存在，若存在则返回加上后缀后的路径。
    - 尝试在该路径后依次加上 `index.js` ， `index.json` 和 `index.node`，判断是否存在，若存在则返回拼接后的路径。
  - 若仍未返回，则为指定的模块路径依次加上 `index.js` ， `index.json` 和 `index.node`，判断是否存在，若存在则返回拼接后的路径。


在取得了模块的完整路径后，便该是执行模块了，我们以执行 `.js` 后缀的 JavaScript 模块为例。首先 Node.js 会通过 `fs.readFileSync` 方法，以 UTF-8 的格式，将 JavaScript 代码以字符串的形式读出，传递给内部方法 `module._compile`，在这个内部方法里，则会调用 `NativeModule.wrap` 方法，将我们的模块代码包裹在一个函数中：

```js
// src/node.js
// ...

NativeModule.wrap = function(script) {
  return NativeModule.wrapper[0] + script + NativeModule.wrapper[1];
};

NativeModule.wrapper = [
  '(function (exports, require, module, __filename, __dirname) { ',
  '\n});'
];
```

所以，这便解答了我们之前提出的，在 `global` 对象下取不到它们的问题，因为它们是以包裹在外的函数的参数的形式传递进来的。所以顺便提一句，我们平常在文件的顶上写的 `use strict` ，其实最终声明的并不是 `script-level` 的严格模式，而都是 `function-level` 的严格模式。

最后一步， Node.js 会使用 `vm.runInThisContext` 执行这个拼接完毕的字符串，取得一个 JavaScript 函数，最后带着对应的对象参数执行它们，并将赋值在 `module.exports` 上的对象返回：

```js
// lib/module.js
// ...

Module.prototype._compile = function(content, filename) {
  // ...

  var compiledWrapper = runInThisContext(wrapper, {
    filename: filename,
    lineOffset: 0,
    displayErrors: true
  });

  // ...
  const args = [this.exports, require, this, filename, dirname];

  const result = compiledWrapper.apply(this.exports, args);
  // ...
};
```

至此，一个同步的 `require` 操作便圆满结束啦。

## 循环依赖

通过上文我们已经可以知道，在 `Module._load` 内部方法里 Node.js 在加载模块之前，首先就会把传模块内的 `module` 对象的引用给缓存起来（此时它的 `exports` 属性还是一个空对象），然后执行模块内代码，在这个过程中渐渐为 `module.exports` 对象附上该有的属性。所以当 Node.js 这么做时，出现循环依赖的时候，仅仅只会让循环依赖点取到中间值，而不会让 `require` 死循环卡住。一个经典的例子：

```js
// a.js
'use strict'
console.log('a starting')
exports.done = false
var b = require('./b')
console.log(`in a, b.done=${b.done}`)
exports.done = true
console.log('a done')
```

```js
// b.js
'use strict'
console.log('b start')
exports.done = false
let a = require('./a')
console.log(`in b, a.done=${a.done}`)
exports.done = true
console.log('b done')
```

```js
// main.js
'use strict'
console.log('main start')
let a = require('./a')
let b = require('./b')
console.log(`in main, a.done=${a.done}, b.done=${b.done}`)
```

执行 `node main.js` ，打印：

```
main start
a starting
b start
in b, a.done=false => 循环依赖点取到了中间值
b done
in a, b.done=true
a done
in main, a.done=true, b.done=true
```

## 最后

由于 Node.js 中的模块导入和 ES6 规范中的不同，它的导入过程是同步的。所以实现起来会方便许多，代码量同样也不多。十分推荐大家阅读一下完整的实现。

参考：
  - https://github.com/nodejs/node/blob/v5.x/lib/module.js
  - https://github.com/nodejs/node/blob/v5.x/src/node.js
