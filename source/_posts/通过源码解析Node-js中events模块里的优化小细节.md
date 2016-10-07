---
title: 通过源码解析Node.js中events模块里的优化小细节
date: 2016-04-25 13:54:02
tags:
---

之前的文章里有说，在 Node.js 中，流（`stream`）是许许多多原生对象的父类，角色可谓十分重要。但是，当我们沿着“族谱”往上看时，会发现 `EventEmitter` 类是流（`stream`）类的父类，所以可以说，`EventEmitter` 类是 Node.js 的根基类之一，地位可显一般。虽然 `EventEmitter` 类暴露的接口并不多而且十分简单，并且是少数纯 `JavaScript` 实现的模块之一，但因为它的应用实在是太广泛，身份太基础，所以在它的实现里处处闪光着一些优化代码执行效率，和保证极端情况下代码结果正确性的小细节。在了解之后，我们也可以将其使用到我们的日常编码之后，学以致用。

好，现在就让我们跟随 Node.js 项目中的 `lib/events.js` 中的代码，来逐一了解：

  - 效率更高的 键 / 值 对存储对象的创建。
  - 效率更高的从数组中去除一个元素。
  - 效率更高的不定参数的函数调用。
  - 如果防止在一个事件监听器中监听同一个事件，接而导致死循环？
  - `emitter.once` 是怎么办到的？

## 效率更高的 键 / 值 对存储对象的创建

在 `EventEmitter` 类中，以 键 / 值 对的方式来存储事件名和对应的监听器。在 `Node.js`里 ，最简单的 键 / 值 对的存储方式就是直接创建一个空对象：

```js
let store = {}
store.key = 'value'
```

你可能会说，ES2015 中的 `Map` 已经在目前版本的 Node.js 中可用了，在语义上它更有优势：

```js
let store = new Map()
store.set('key', 'value')
```

不过，你可能只需要一个纯粹的 键 / 值 对存储对象，并不需要 `Object` 和 `Map` 这两个类的原型中的提供的那些多余的方法，所以你直接：

```js
let store = Object.create(null)
store.key = 'value'
```

好，我们已经做的挺极致了，但这还不是 `EventEmitter` 中的最终实现，它的办法是使用一个空的构造函数，并且把这个构造的原型事先置空：

```js
function Store () {}
Store.prototype = Object.create(null)
```

然后：

```js
let store = new Store()
store.key = 'value'
```

现在让我们来比一比效率，代码：

```js
/* global suite bench */
'use strict'

suite('key / value store', function () {
  function Store () {}
  Store.prototype = Object.create(null)

  bench('let store = {}', function () {
    let store = {}
    store.key = 'value'
  })

  bench('let store = new Map()', function () {
    let store = new Map()
    store.set('key', 'value')
  })

  bench('let store = Object.create(null)', function () {
    let store = Object.create(null)
    store.key = 'value'
  })

  bench('EventEmitter way', function () {
    let store = new Store()
    store.key = 'value'
  })
})
```

比较结果：

```
                      key / value store
      83,196,978 op/s » let store = {}
       4,826,143 op/s » let store = new Map()
       7,405,904 op/s » let store = Object.create(null)
     165,608,103 op/s » EventEmitter way
```

## 效率更高的从数组中去除一个元素

在 `EventEmitter#removeListener` 这个 API 的实现里，需要从存储的监听器数组中除去一个元素，我们首先想到的就是使用 `Array#splice` 这个 API ，即 `arr.splice(i, 1)` 。不过这个 API 所提供的功能过于多了，它支持去除自定义数量的元素，还支持向数组中添加自定义的元素。所以，源码中选择自己实现一个最小可用的：

```js
// lib/events.js
// ...

function spliceOne(list, index) {
  for (var i = index, k = i + 1, n = list.length; k < n; i += 1, k += 1)
    list[i] = list[k];
  list.pop();
}
```

比一比，代码：

```js
/* global suite bench */
'use strict'

suite('Remove one element from an array', function () {
  function spliceOne (list, index) {
    for (var i = index, k = i + 1, n = list.length; k < n; i += 1, k += 1) {
      list[i] = list[k]
    }
    list.pop()
  }

  bench('Array#splice', function () {
    let array = [1, 2, 3]
    array.splice(1, 1)
  })

  bench('EventEmitter way', function () {
    let array = [1, 2, 3]
    spliceOne(array, 1)
  })
})
```

结果，好吧，秒了：

```
                      Remove one element from an array
       4,262,168 op/s » Array#splice
      54,829,749 op/s » EventEmitter way
```

## 效率更高的不定参数的函数调用

在事件触发时，监听器拥有的参数数量是任意的，所以源码中优化了不定参数的函数调用。

不过好吧，这里使用的是笨办法，即...把不定参数的函数调用转变成固定参数的函数调用，且最多支持到三个参数：

```js
// lib/events.js
// ...

function emitNone(handler, isFn, self) {
  // ...
}
function emitOne(handler, isFn, self, arg1) {
  // ...
}
function emitTwo(handler, isFn, self, arg1, arg2) {
  // ...
}
function emitThree(handler, isFn, self, arg1, arg2, arg3) {
  // ...
}

function emitMany(handler, isFn, self, args) {
  // ...
}
```

虽然结果不言而喻，我们还是比较下会差多少，以三个参数为例：

```js
/* global suite bench */
'use strict'

suite('calling function with any amount of arguments', function () {
  function nope () {}

  bench('Function#apply', function () {
    function callMany () { nope.apply(null, arguments) }
    callMany(1, 2, 3)
  })

  bench('EventEmitter way', function () {
    function callThree (a, b, c) { nope.call(null, a, b, c) }
    callThree(1, 2, 3)
  })
})
```

结果显示差了一倍：

```
                      calling function with any amount of arguments
      11,354,996 op/s » Function#apply
      23,773,458 op/s » EventEmitter way
```

## 如果防止在一个事件监听器中监听同一个事件，接而导致死循环？

在注册事件监听器时，你可否曾想到过这种情况：

```js
'use strict'
const EventEmitter = require('events')

let myEventEmitter = new EventEmitter()

myEventEmitter.on('wtf', function wtf () {
  myEventEmitter.on('wtf', wtf)
})

myEventEmitter.emit('wtf')
```

运行上述代码，是否会直接导致死循环？答案是不会，因为源码中做了处理。

我们先看一下具体的代码：

```js
// lib/events.js
// ...

function emitMany(handler, isFn, self, args) {
  if (isFn)
    handler.apply(self, args);
  else {
    var len = handler.length;
    var listeners = arrayClone(handler, len);
    for (var i = 0; i < len; ++i)
      listeners[i].apply(self, args);
  }
}

// ...
function arrayClone(arr, i) {
  var copy = new Array(i);
  while (i--)
    copy[i] = arr[i];
  return copy;
}
```

其中的 `handler` 便是具体的事件监听器数组，不难看出，源码中的解决方案是，使用 `arrayClone` 方法，拷贝出另一个一模一样的数组，来执行它，这样一来，当我们在监听器内监听同一个事件时，的确给原监听器数组添加了新的函数，但并没有影响到当前这个被拷贝出来的副本数组。

## `emitter.once` 是怎么办到的

这个很简单，使用了闭包：

```js
function _onceWrap(target, type, listener) {
  var fired = false;
  function g() {
    target.removeListener(type, g);
    if (!fired) {
      fired = true;
      listener.apply(target, arguments);
    }
  }
  g.listener = listener;
  return g;
}
```

你可能会问，我既然已经在 `g` 函数中的第一行中移除了当前的监听器，为何还要使用 `fired` 这个 flag ？我个人觉得是因为，在 `removeListener` 这个同步方法中，会将这个 `g` 函数暴露出来给 `removeListener` 事件的监听器，所以该 flag 用来保证 `once` 注册的函数只会被调用一次。

## 最后

分析就到这里啦，在了解了这些做法之后，在今后我们写一些有性能要求的底层工具库等东西时，我们便可以用上它们啦。`EventEmitter` 类的源码并不复杂，并且是纯 `JavaScript` 实现的，所以也非常推荐大家闲时一读。

参考：https://github.com/nodejs/node/blob/master/lib/events.js

