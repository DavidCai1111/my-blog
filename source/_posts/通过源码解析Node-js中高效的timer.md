---
title: 通过源码解析 Node.js 中高效的 timer
date: 2016-05-08 13:58:06
tags:
---

在 Node.js 中，许许多多的异步操作，都需要来一个兜底的超时，这时，就轮到 timer 登场了。由于需要使用它的地方是那么的多，而且都是基础的功能模块，所以，对于它性能的要求，自然是十分高的。总结来说，要求有：

  - 更快的添加操作。
  - 更快的移除操作。
  - 更快的超时触发。

接下来就让我们跟着 Node.js 项目中的 `lib/timer.js` 和 `lib/internal/linklist.js` 来探究它具体的实现。

## 更快的添加 / 移除操作

说到添加和移除都十分高效的数据结构，第一个映入脑帘的，自然就是[链表][1]啦。是的，Node.js 就是使用了双向链表，来将 timer 的插入和移除操作的时间复杂度都降至 O(1) 。双向链表的具体实现便在 `lib/internal/linklist.js` 中：

```js
// lib/internal/linklist.js
'use strict';
function init(list) {
  list._idleNext = list;
  list._idlePrev = list;
}
exports.init = init;

function peek(list) {
  if (list._idlePrev == list) return null;
  return list._idlePrev;
}
exports.peek = peek;

function shift(list) {
  var first = list._idlePrev;
  remove(first);
  return first;
}
exports.shift = shift;

function remove(item) {
  if (item._idleNext) {
    item._idleNext._idlePrev = item._idlePrev;
  }

  if (item._idlePrev) {
    item._idlePrev._idleNext = item._idleNext;
  }

  item._idleNext = null;
  item._idlePrev = null;
}
exports.remove = remove;

function append(list, item) {
  remove(item);
  item._idleNext = list._idleNext;
  list._idleNext._idlePrev = item;
  item._idlePrev = list;
  list._idleNext = item;
}
exports.append = append;

function isEmpty(list) {
  return list._idleNext === list;
}
exports.isEmpty = isEmpty;
```

可以看到，都是些修改链表中指针的操作，都十分高效。

## 更快的超时触发

链表的缺点，自然是它的查找时间，对于一个无序的链表来说，查找时间需要 O(n) ，但是，只要基于一个*大前提*，那么我们的实现就并不需要使用到链表的查询，这也是更高效的超时触发的基础所在，那就是，**对于同一延迟的 timers ，后添加的一定比先添加的晚触发。**所以，源码的具体做法就是，对于同一延迟的所有 timers ，全部都维护在同一个双向链表中，后来的，就不断往链表末尾追加，并且这条链表实际上共享同一个定时器 。这个定时器会在当次超时触发时，动态计算下一次的触发时间点。所有的链表，都保存在一个对象 map 中。如此一来，既做到了定时器的复用优化，又对链表结构进行了扬长避短。

让我们先以 `setTimeout` 为例看看具体代码，首先是插入：

```js
// lib/timer.js
// ...
const refedLists = {};
const unrefedLists = {};

exports.setTimeout = function(callback, after) {
  // ...
  var timer = new Timeout(after);
  var length = arguments.length;
  var ontimeout = callback;
  // ...
  timer._onTimeout = ontimeout;

  active(timer);
  return timer;
};

const active = exports.active = function(item) {
  insert(item, false);
};

function insert(item, unrefed) {
  const msecs = item._idleTimeout;
  if (msecs < 0 || msecs === undefined) return;

  item._idleStart = TimerWrap.now();

  var list = lists[msecs];
  if (!list) {
    // ...
    list = new TimersList(msecs, unrefed);
    L.init(list);
    list._timer._list = list;

    if (unrefed === true) list._timer.unref();
    list._timer.start(msecs, 0);

    lists[msecs] = list;
    list._timer[kOnTimeout] = listOnTimeout;
  }

  L.append(list, item);
  assert(!L.isEmpty(list));
}
```

即检查当前在对象 map 中，是否存在该超时时间（`msecs`）的双向链表，若无，则新建一条。你应该已经看出，超时触发时具体的处理逻辑，就在 `listOnTimeout` 函数中：

```js
// lib/timer.js
// ...
function listOnTimeout() {
  var list = this._list;
  var msecs = list.msecs;

  var now = TimerWrap.now();

  var diff, timer;
  while (timer = L.peek(list)) {
    diff = now - timer._idleStart;

    if (diff < msecs) {
      this.start(msecs - diff, 0);
      return;
    }
    L.remove(timer);
    // ...
    tryOnTimeout(timer, list);
    // ...
  }

  this.close();
  // ...
}
```

即不断从链表头取出封装好的包含了*注册时间点*和*处理函数*的对象，然后挨个执行，直到计算出的超时时间点已经超过当前时间点。

举个图例，在时间点 10，100，400 时分别注册了三个超时时间为 1000 的 timer，在时间点 300 注册了一个超时时间为 3000 的 timer，即在时间点 500 时，对象 map 的结构即为：

![3.pic.jpg](http://dn-cnode.qbox.me/Fk8xPsE6dngPmzWb3Pa8veKzZTHN)

随后在时间点 **1200** 触发了超时事件，并在时间点 1300 执行完毕，彼时对象 map 的结构即为：

![4.pic.jpg](http://dn-cnode.qbox.me/FstFzY_Ys4L8HjVJTVqF7bFPmO0_)

## setInterval 和 setImmediate

`setInterval` 的实现总体和 `setTimeout` 很相似，区别在于对注册的回调函数进行了封装，在链表的尾部重新插入：

```js
// lib/timer.js
// ...

function wrapper() {
  timer._repeat(); // 执行传入的回调函数

  if (!timer._repeat)
    return;

  // ...
  timer._idleTimeout = repeat;
  active(timer);
}
```

而 `setImmediate` 和 `setTimeout` 实现上的主要区别则在于，它会一次性将链表中注册的，都执行完：

```js
// lib/timer.js
// ...
function processImmediate() {
  var queue = immediateQueue;
  var domain, immediate;

  immediateQueue = {};
  L.init(immediateQueue);

  while (L.isEmpty(queue) === false) {
    immediate = L.shift(queue);
    // ...
    tryOnImmediate(immediate, queue);
    // ...
  }

  if (L.isEmpty(immediateQueue)) {
    process._needImmediateCallback = false;
  }
}
```

所以作为功能类似的 `process.nextTick` 和 `setImmediate` ，在功能层面上看，每次事件循环，它们都会将存储的回调都执行完，但 `process.nextTick` 中的存储的回调，会先于 `setImmediate` 中的执行：

```js
'use strict'
const print = (i) => () => console.log(i)

process.nextTick(print(1))
process.nextTick(print(2))

setImmediate(() => {
  print(3)()
  setImmediate(print(6))
  process.nextTick(print(5))
})
setImmediate(print(4))

console.log('发车')

// 发车
// 1
// 2
// 3
// 4
// 5
// 6
```

## 最后

参考：
  - https://github.com/nodejs/node/blob/master/lib/timers.js
  - https://github.com/nodejs/node/blob/master/lib/internal/linkedlist.js

  [1]: https://en.wikipedia.org/wiki/Linked_list
