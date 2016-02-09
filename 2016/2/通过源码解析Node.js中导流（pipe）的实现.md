在`Node.js`中，流（`Stream`）是其众多原生对象的基类，它对处理潜在的大文件提供了支持，也抽象了一些场景下的数据处理和传递。在它对外暴露的接口中，最为神奇的，莫过于导流（`pipe`）方法了。鉴于近期自己正在阅读`Node.js`中的部分源码，也来从源码层面分享下导流的具体实现。

## 正题

以下是一个关于导流的简单例子：

```js
'use strict'
import {createReadStream, createWriteStream} from 'fs'

createReadStream('/path/to/a/big/file').pipe(createWriteStream('/path/to/the/dest'))
```

再结合[官方文档][1]，我们可以把`pipe`方法的主要功能分解为：
 - 不断从来源可读流中获得一个指定长度的数据。
 - 将获取到的数据写入目标可写流。
 - 平衡读取和写入速度，防止读取速度大大超过写入速度时，出现大量滞留数据。

好，让我们跟随`Node.js`项目里`lib/_stream_readable.js`和`lib/_stream_writable.js`中的代码，逐个解析这三个主要功能的实现。

### 读取数据

刚创建出的可读流只是一个记录了一些初始状态的空壳，里面没有任何数据，并且其状态不属于官方文档中的流动模式（flowing mode）和暂停模式（paused mode）中的任何一种，算是一种伪暂停模式，因为此时实例的状态中记录它是否为暂停模式的变量还不是标准的布尔值，而是`null`，但又可通过将暂停模式转化为流动模式的行为（调用实例的`resume()`方法），将可读流切换至流动模式。在外部代码中，我们可以手动监听可读流的`data`事件，让其进入流动模式：

```js
// lib/_stream_readable.js
// ...

Readable.prototype.on = function(ev, fn) {
  var res = Stream.prototype.on.call(this, ev, fn);

  if (ev === 'data' && false !== this._readableState.flowing) {
    this.resume();
  }

  // ...

  return res;
};
```

可见，可读流类通过二次封装父类（`EventEmitter`）的`on()`方法，替我们在监听`data`事件时，将流切换至了流动模式。而开始读取数据的动作，则存在于`resume()`方法调用的内部方法`resume_()`中，让我们一窥究竟：

```js
// lib/_stream_readable.js
// ...

function resume_(stream, state) {
  if (!state.reading) {
    debug('resume read 0');
    stream.read(0);
  }

  // ...
}
```

通过向可读流读取一次空数据（大小为0），将会触发实例层面实现的`_read()`方法，开始读取数据，然后利用读到的数据触发`data`事件：

```js
// lib/_stream_readable.js
// ...

Readable.prototype.read = function(n) {
  // ...
  // 此次判断的意图为，如果可读流的缓冲中已满，则只空触发readable事件。
  if (n === 0 &&
      state.needReadable &&
      (state.length >= state.highWaterMark || state.ended)) {
    if (state.length === 0 && state.ended)
      endReadable(this);
    else
      emitReadable(this);
    return null;
  }

  // 若可读流已经被传入了终止符（null），且缓冲中没有遗留数据，则结束这个可读流
  if (n === 0 && state.ended) {
    if (state.length === 0)
      endReadable(this);
    return null;
  }

  // 若目前缓冲中的数据大小为空，或未超过设置的警戒线，则进行一次数据读取。
  if (state.length === 0 || state.length - n < state.highWaterMark) {
    doRead = true;
  }

  if (doRead) {
    // ...
    this._read(state.highWaterMark);
  }

  // ...

  if (ret !== null)
    this.emit('data', ret);

  return ret;
};
```

可见，在可读流的`read()`方法内部，通过调用在实例层面实现的`_read(size)`方法，取得了一段（设置的警戒线）大小的数据，但是，你可能会疑惑，这只是读取了一次数据啊，理想情况下，应该是循环调用`_read(size)`直至取完所有数据才对啊！？其实，这部分的逻辑存在于我们实现`_read(size)`方法时，在其内部调用的`this.push(data)`方法中，在最后其会调用私有方法`maybeReadMore_()`，再次触发`read(0)`，接着在`read(0)`函数的代码中再次判断可读流是否能够结束，否则再进行一次`_read(size)`读取：

```js
// lib/_stream_readable.js
// ...

Readable.prototype.push = function(chunk, encoding) {
  var state = this._readableState;
  // ...
  return readableAddChunk(this, state, chunk, encoding, false);
};

function readableAddChunk(stream, state, chunk, encoding, addToFront) {
  // ...
  if (er) {
    stream.emit('error', er);
  } else if (chunk === null) {
    state.reading = false;
    onEofChunk(stream, state); // 当传入终止符时，将可读流的结束标识（state.ended）设为true
  }
  // ...
      maybeReadMore(stream, state);
    }
  }

  // ...
}

function maybeReadMore(stream, state) {
  if (!state.readingMore) {
    // ...
    process.nextTick(maybeReadMore_, stream, state);
  }
}

function maybeReadMore_(stream, state) {
    // ...
    stream.read(0);
}

function onEofChunk(stream, state) {
  if (state.ended) return;
  // ...
  state.ended = true;
  // ...
}
```

好的，此时从可读流中读取数据的整个核心流程已经实现了，让我们归纳一下：
 - 刚创建出的可读流只是一个空壳，保存着一些初始状态。
 - 监听它的`data`事件，将会自动调用该可读流的`resume()`方法，使流切换至流动模式。
 - 在`resume()`方法的内部函数`_resume()`中，对可读流进行了一次`read(0)`调用。
 - `read(0)`调用的内部，首先检查流是否符合了结束条件，若符合，则**结束**之。否则调用实例实现的`_read(size)`方法读取一段预设的警戒线（highWaterMark）大小的数据。
 - 在实例实现`_read(size)`函数时内部调用的`this.push(data)`方法里，会先判断的读到的数据是否为结束符，若是，则将流的状态设为结束，然后再一次对可读流调用`read(0)`。

### 写入数据

和可读流一样，刚创建出的可写流也只是一个记录了相关状态（包括预设的写入缓冲大小）的空壳。直接调用它的`write`方法，该方法会在其内部调用`writeOrBuffer`函数来对数据是否可以直接一次性全部写入进行判断：

```js
// lib/_stream_writable.js
// ...

function writeOrBuffer(stream, state, chunk, encoding, cb) {
  // ...
  var ret = state.length < state.highWaterMark;

  // 记录可写流是否需要出发drain事件
  if (!ret)
    state.needDrain = true;

  if (state.writing || state.corked) {
    // 若可写流正在被写入或被人工阻塞，则先将写入操作排队
    // ...
  } else {
    doWrite(stream, state, false, len, chunk, encoding, cb);
  }

  return ret;
}

function doWrite(stream, state, writev, len, chunk, encoding, cb) {
  // ...
  if (writev)
    stream._writev(chunk, state.onwrite);
  else
    stream._write(chunk, encoding, state.onwrite);
  // ...
}
```

从代码中可知，在`writeOrBuffer`函数记录下了数据是否可以被一次性写入后，调用了实例层实现的`_write()`或`_writev()`方法进行了实际的写入操作。那么，如果不能一次性写入完毕，那么在真正写入完毕时，又是如何进行通知的呢？嗯，答案就在设置的`state.onwrite`回调中：

```js
// lib/_stream_writable.js
// ...

function onwrite(stream, er) {
  // ...

  if (er)
    onwriteError(stream, state, sync, er, cb);
  else {
    // ...
    if (sync) {
      process.nextTick(afterWrite, stream, state, finished, cb);
    } else {
      afterWrite(stream, state, finished, cb);
    }
  }
}

function afterWrite(stream, state, finished, cb) {
  if (!finished)
    onwriteDrain(stream, state);
  // ...
}

function onwriteDrain(stream, state) {
  if (state.length === 0 && state.needDrain) {
    state.needDrain = false;
    stream.emit('drain');
  }
}
```

可见，在回调函数的执行中，会对该可写流该次被写入的数据是否超过了警戒线的状态进行判断，如果是，则触发`drain`事件，进行通知。

我们也可以调用`end()`方法来表明要结束这个写入流，并进行最后一次写入，`end()`方法的内部最终会调用`endWritable()`函数来讲可写流的状态切换为已结束：

```js
// lib/_stream_writable.js
// ...

function endWritable(stream, state, cb) {
  // ...
  state.ended = true;
  stream.writable = false;
}
```

此时，向可写流中写入数据的整个核心流程已经实现了，这个流程和可写流的循环读取流程不同，它是直线的，归纳一下：

- 刚创建出的可写流只是一个空壳，保存着一些初始状态。
- 调用`write()`方法，其内部的`writeOrBuffer()`检测该次写入的数据是否需要被暂存在缓冲区中。
- `writeOrBuffer()`函数调用实例实现的`_write()`或`_writev()`方法，进行实际的写入，完成后调用回调函数`state.onwrite`。
- 回调函数中检测该次写入是否被缓冲，若是，触发`drain`事件。
- 重复以上过程，直至调用`end()`方法结束该可写流。

### 导流

在摸清了从可读流中读数据，和向可写流中写数据实现的核心流程后，`Node.js`中实现导流的核心流程其实已经呼之欲出了。首先，为了开始从源可读流读取数据，在`pipe()`方法的内部，它主动为源可读流添加了`data`事件的监听函数：

```js
// lib/_stream_readable.js
// ...

Readable.prototype.pipe = function(dest, pipeOpts) {
  // ...

  src.on('data', ondata);
  function ondata(chunk) {
      // ...
      src.pause();
    }
  }

  // ...
  return dest;
};
```

从代码中可见，若向目标可写流写入一次数据时，目标可写流表示该次写入它需要进行缓冲，则主动将源可读流切换至暂停模式。那么，源可读流通过什么手段得知可以再次读取数据并写入呢？嗯，通过监听目标可写流的`drain`事件：

```js
// lib/_stream_readable.js
// ...

Readable.prototype.pipe = function(dest, pipeOpts) {
  // ...
  var ondrain = pipeOnDrain(src);
  dest.on('drain', ondrain);

  // ...
  return dest;
};

function pipeOnDrain(src) {
  return function() {
    var state = src._readableState;

    // 目标可写流可能会存在多次写入需要进行缓冲的情况，需确保所有需要缓冲的写入都
    // 完成后，再次将可读流切换至流动模式。
    if (state.awaitDrain)
      state.awaitDrain--;
    if (state.awaitDrain === 0 && EE.listenerCount(src, 'data')) {
      state.flowing = true;
      flow(src);
    }
  };
}
```

最后，监听源可读流的结束事件，对应着结束目标可写流：

```js
// lib/_stream_readable.js
// ...

Readable.prototype.pipe = function(dest, pipeOpts) {
  // ...
  var endFn = doEnd ? onend : cleanup;
  if (state.endEmitted)
    process.nextTick(endFn);
  else
    src.once('end', endFn);

  function onend() {
    debug('onend');
    dest.end();
  }

  // ...
  return dest;
};
```

由于前面的铺垫，实际导流操作的核心流程其实实现得非常轻松，归纳一下：

- 主动监听源可读流的`data`事件，在该事件的监听函数中，向目标可写流写入数据。
- 若目标可写流表示该写入操作需要进行缓冲，则立刻将源可读流切换至暂停模式。
- 监听目标可写流的`drain`事件，当目标可写流里所有需要缓冲的写入操作都完毕后，将流重新切换回流动模式。
- 监听源可读流的`end`事件，相应地结束目标可写流。

## 最后

`Node.js`中流的实际实现其实非常庞大，复杂，精妙。每一个流的内部，都管理着大量状态。本文仅仅只是在庞大的流的实现中，选择了一条主线，进行了阐述。大家如果有闲，非常推荐完整地阅读一遍其实现。

参考：
- https://github.com/nodejs/node/blob/master/lib/_stream_readable.js
- https://github.com/nodejs/node/blob/master/lib/_stream_writable.js

  [1]: https://nodejs.org/dist/latest-v5.x/docs/api/stream.html#stream_stream
