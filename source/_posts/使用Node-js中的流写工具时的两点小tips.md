---
title: 使用Node.js中的流写工具时的两点小tips
date: 2016-02-29 13:50:28
tags:
---

`Node.js`中的流十分强大，它对处理潜在的大文件提供了支持，也抽象了一些场景下的数据处理和传递。正因为它如此好用，所以在实战中我们常常基于它来编写一些工具 函数/库 ，但往往又由于自己对流的某些特性的疏忽，导致写出的 函数/库 在一些情况会达不到想要的效果，或者埋下一些隐藏的地雷。本文将会提供两个在编写基于流的工具时，私以为有些用的两个tips。

## 一，警惕`EventEmitter`内存泄露

在一个可能被多次调用的函数中，如果需要给流添加事件监听器来执行某些操作。那么则需要警惕添加监听器而导致的内存泄露：

```js
'use strict';
const fs = require('fs');
const co = require('co');

function getSomeDataFromStream (stream) {
  let data = stream.read();
  if (data) return Promise.resolve(data);

  if (!stream.readable) return Promise.resolve(null);

  return new Promise((resolve, reject) => {
    stream.once('readable', () => resolve(stream.read()));
    stream.on('error', reject);
    stream.on('end', resolve);
  })
}

let stream = fs.createReadStream('/Path/to/a/big/file');

co(function *() {
  let chunk;
  while ((chunk = yield getSomeDataFromStream(stream)) !== null) {
    console.log(chunk);
  }
}).catch(console.error);
```
<!-- more -->
在上述代码中，`getSomeDataFromStream`函数会在通过监听`error`事件和`end`事件，来在流报错或没有数据时，完成这个`Promise`。然而在执行代码时，我们很快就会在控制台中看到报警信息：`(node) warning: possible EventEmitter memory leak detected. 11 error listeners added. Use emitter.setMaxListeners() to increase limit.`，因为我们在每次调用该函数时，都为传入的流添加了一个额外的`error`事件监听器和`end`事件监听器。为了避免这种潜在的内存泄露，我们要确保每次函数执行完毕后，清除所有此次调用添加的额外监听器，保持函数无污染：

```js
function getSomeDataFromStream (stream) {
  let data = stream.read();
  if (data) return Promise.resolve(data);

  if (!stream.readable) return Promise.resolve(null);

  return new Promise((resolve, reject) => {
    stream.once('readable', onData);
    stream.on('error', onError);
    stream.on('end', done);

    function onData () {
      done();
      resolve(stream.read());
    }

    function onError (err) {
      done();
      reject(err);
    }

    function done () {
      stream.removeListener('readable', onData);
      stream.removeListener('error', onError);
      stream.removeListener('end', done);
    }
  })
}
```

## 二，保证工具函数的回调在处理完毕数据后才被调用

工具函数往往会对外提供一个回调函数参数，待处理完流中的所有数据后，带着指定值触发，通常的做法是将回调函数的调用挂在流的`end`事件中，但如果处理函数是耗时的异步操作，回调函数则可能在所有数据处理完毕前被调用：

```js
'use strict';
const fs = require('fs');

let stream = fs.createReadStream('/Path/to/a/big/file');

function processSomeData (stream, callback) {
  stream.on('data', (data) => {
    // 对数据进行一些异步耗时操作
    setTimeout(() => console.log(data), 2000);
  });

  stream.on('end', () => {
    // ...
    callback()
  })
}

processSomeData(stream, () => console.log('end'));
```

以上的代码`callback`回调可能会在数据并未被全部处理时就被调用，因为流的`end`事件的触发时机仅仅是在流中的数据被读完时。所以我们需要额外地对数据是否已处理完进行检查：

```js
function processSomeData (stream, callback) {
  let count = 0;
  let finished = 0;
  let isEnd = false;

  stream.on('data', (data) => {
    count++;
    // 对数据进行一些异步耗时操作
    setTimeout(() => {
      console.log(data);
      finished++;
      check();
    }, 2000);
  });

  stream.on('end', () => {
    isEnd = true;
    // ...
    check();
  })

  function check () {
    if (count === finished && isEnd) callback()
  }
}
```

这样一来，回调便会在所有数据都处理完毕后触发了。

