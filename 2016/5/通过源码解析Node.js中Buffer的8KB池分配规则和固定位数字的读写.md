在 Node.js 中，Buffer 常常用来存储一些潜在的大体积数据，例如，文件和网络 I/O 所获取来的数据，若不指定编码，则都以 Buffer 的形式来提供，可见其地位非同一般。你或许听说过，Buffer 的创建，是可能会经过内部的一个 8KB 池的，那么具体的规则是什么呢？可以创建一个新 Buffer 实例的 API 那么多，到底哪些 API 会经过，哪些又不会经过呢？或许你在阅读文档时，还看到过许多形如 `Buffer#writeUInt32BE` ， `Buffer#readUInt32BE` 等等这类固定位的数字的读写操作，它们具体是如何实现的呢？

现在让我们一起跟着 Node.js 项目中 `lib/buffer.js` 中的代码，来一探究竟。

## 8KB 池分配规则

统计一下，当前版本的 Node.js （v6.0）中可以创建一个新 Buffer 类实例的 API 有：

  - `new Buffer()` （已不推荐使用，可能会泄露内存中潜在的敏感信息，具体例子可以看[这里][1]）
  - `Buffer.alloc()`
  - `Buffer.allocUnsafe()`（虽然也有泄露内存中敏感信息的可能，但语义上非常明确）
  - `Buffer.from()`
  - `Buffer.concat()`

跟着代码追溯，这些 API 最后都会走进两个内部函数中的一个，来创建 Buffer 实例，这两个内部函数分别是 `createBuffer()` 和 `allocate()`：

```js
// lib/buffer.js
// ...

Buffer.poolSize = 8 * 1024;
var poolSize, poolOffset, allocPool;

function createPool() {
  poolSize = Buffer.poolSize;
  allocPool = createBuffer(poolSize, true);
  poolOffset = 0;
}
createPool();

function createBuffer(size, noZeroFill) {
  flags[kNoZeroFill] = noZeroFill ? 1 : 0;
  try {
    const ui8 = new Uint8Array(size);
    Object.setPrototypeOf(ui8, Buffer.prototype);
    return ui8;
  } finally {
    flags[kNoZeroFill] = 0;
  }
}

function allocate(size) {
  if (size === 0) {
    return createBuffer(size);
  }
  if (size < (Buffer.poolSize >>> 1)) {
    if (size > (poolSize - poolOffset))
      createPool();
    var b = allocPool.slice(poolOffset, poolOffset + size);
    poolOffset += size;
    alignPool();
    return b;
  } else {
    return createBuffer(size, true);
  }
}
```

通过代码可以清楚的看到，若最后创建时，走的是 `createBuffer()` 函数，则不经过 8KB 池，若走 `allocate()` 函数，当传入的数据大小小于 `Buffer.poolSize` 有符号右移 1 位后的结果（相当于将该值除以 2 再向下取整，在本例中，为 4 KB），才会使用到 8KB 池（若当前池剩余空间不足，则创建一个新的，并将当前池指向新池）。

那么现在让我们来看看，这些 API 都走的是哪些方法：

```js
// lib/buffer.js
// ...

Buffer.alloc = function(size, fill, encoding) {
  // ...
  return createBuffer(size);
};

Buffer.allocUnsafe = function(size) {
  assertSize(size);
  return allocate(size);
};

Buffer.from = function(value, encodingOrOffset, length) {
  // ...
  if (value instanceof ArrayBuffer)
    return fromArrayBuffer(value, encodingOrOffset, length);

  if (typeof value === 'string')
    return fromString(value, encodingOrOffset);

  return fromObject(value);
};

function fromArrayBuffer(obj, byteOffset, length) {
  byteOffset >>>= 0;

  if (typeof length === 'undefined')
    return binding.createFromArrayBuffer(obj, byteOffset);

  length >>>= 0;
  return binding.createFromArrayBuffer(obj, byteOffset, length);
}

function fromString(string, encoding) {
  // ...
  if (length >= (Buffer.poolSize >>> 1))
    return binding.createFromString(string, encoding);

  if (length > (poolSize - poolOffset))
    createPool();
  var actual = allocPool.write(string, poolOffset, encoding);
  var b = allocPool.slice(poolOffset, poolOffset + actual);
  poolOffset += actual;
  alignPool();
  return b;
}

Buffer.concat = function(list, length) {
  // ...
  var buffer = Buffer.allocUnsafe(length);
  // ...
  return buffer;
};
```

挺一目了然的，让我们来总结一下，当在以下情况同时都成立时，创建的新的 Buffer 类实例才会经过内部 8KB 池：

  - 通过 `Buffer.allocUnsafe`，`Buffer.concat`，`Buffer.from`（参数不为一个 [ArrayBuffer][2] 实例）和 `new Buffer`（参数不为一个 [ArrayBuffer][3] 实例）创建。
  - 传入的数据大小不为 0 。
  - 且传入数据的大小必须小于 4KB 。

## 那些固定位数字读写 API

当你在阅读 Buffer 的文档时，看到诸如 `Buffer#writeUInt32BE`，`Buffer#readUInt32BE` 这样的 API 时，可能会想到 ES6 规范中的 [DateView][4] 类提供的那些方法。其实它们做的事情十分相似，Node.js 项目中甚至还有将这些 API 的底层都替换成原生的 `DateView` 实例来操作的 [PR][5] ，但该 PR 目前已被标记为 `stalled` ，具体原因大致是：

  - 没有显著的性能提升。
  - 会在实例被初始化后又增加新的属性。
  - `noAssert` 参数将会失效。

先不管这个 PR ，其实，这些读写操作，若数字的精度在 32 位以下，则对应方法都是由 JavaScript 实现的，十分优雅，利用了 `TypeArray` 下那些类（Buffer 中使用的是 `Uint8Array`）的实例中的元素，在位溢出时，会抛弃溢出位的机制。以 `writeUInt32LE` 和 `writeUInt32BE` （LE 和 BE 即小端字节序和大端字节序，可以参阅[这篇文章][6]）为例，一个 32 位无符号整数需要 4 字节存储，大端字节序时，则第一个元素为直接将传入的 32 位整数无符号右移 24 位，获取到原最左的 8 位，抛弃当下左边的所有位。以此类推，第二个元素为无符号右移 16 位，第三个元素为 8 位，第四个元素无需移动（小端字节序则相反）：

```js
Buffer.prototype.writeUInt32BE = function(value, offset, noAssert) {
  value = +value;
  offset = offset >>> 0;
  if (!noAssert)
    checkInt(this, value, offset, 4, 0xffffffff, 0);
  this[offset] = (value >>> 24);
  this[offset + 1] = (value >>> 16);
  this[offset + 2] = (value >>> 8);
  this[offset + 3] = value;
  return offset + 4;
};
```

读操作与之对应，使用了无符号左移后腾出空位再进行 `|` 操作合并：

```js
Buffer.prototype.readUInt32BE = function(offset, noAssert) {
  offset = offset >>> 0;
  if (!noAssert)
    checkOffset(offset, 4, this.length);

  return (this[offset] * 0x1000000) +
      ((this[offset + 1] << 16) |
      (this[offset + 2] << 8) |
      this[offset + 3]);
};
```

其中的 `(this[offset] * 0x1000000) +` 相当于 `this[offset] << 24 |` 。

## 最后

参考：
  - https://github.com/nodejs/node/blob/master/lib/buffer.js


  [1]: https://github.com/ChALkeR/notes/blob/master/Buffer-knows-everything.md
  [2]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/ArrayBuffer
  [3]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/ArrayBuffer
  [4]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/DataView
  [5]: https://github.com/nodejs/node/pull/2897
  [6]: https://www.cs.umd.edu/class/sum2003/cmsc311/Notes/Data/endian.html