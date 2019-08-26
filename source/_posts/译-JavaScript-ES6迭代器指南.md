---
title: '[译] JavaScript ES6 迭代器指南'
date: 2015-06-26 13:38:33
tags:
---

## 前言

EcmaScript 2015 （又称ES6）提供一个全新的`迭代器`的概念，它允许我们在语言层面上定义一个（有限或无限的）序列。

暂时先抛开它。我们对于`for`循环以及它的兄弟`for-in`循环，都已经十分的熟悉。后者可以被用来帮助我们理解迭代器。

```js
for (var key in table) {
  console.log(key + ' = ' + table[key]);
}
```

对于`for-in`循环，它有许多的问题。但是最大的问题，便是它不保证迭代的顺序。但是当我们使用ES6迭代器时，这个问题就迎刃而解了。
<!-- more -->
## for-of

`for-of`是ES6中的新语法，用来配合迭代器。

```js
for (var key of table) {
  console.log(key + ' = ' + table[key]);
}
```

使用`for-of`，我们得到的是一个可以保证顺序的迭代。为了让一个对象可以被迭代器所迭代，对象需要实现一个“迭代协议”，即拥有一个`Symbol.iterator`属性。这个属性会被`for-of`所使用，在我们的例子中，它就是`table[Symbol.iterator]`。

`Symbol.iterator`也是在ES6中新增的内容，我们会在另一篇文章中详细讨论。在这里，我们只需认为它是对象的一个特殊属性，并且永远不会和其他普通属性产生冲突。

`table[Symbol.iterator]`的值，必须是一个符合“迭代协议”的函数，即它需要返回一个类似于`{ next: function () {} }`的对象。

```js
table[Symbol.iterator] = function () {
   return {
    next: function () {}
  }
}
```

然后，在`for-of`循环每次调用`next()`函数时，它需要返回一个类似于`{value: …, done: [true/false]}`的对象。所以，一个迭代器的完整实现类似于如下的例子：

```js
table[Symbol.iterator] = function () {
  var keys = Object.keys(this).sort();
  var index = 0;

  return {
    next: function () {
      return {
        value: keys[index], done: index++ >= keys.length
      };
    }
  }
}
```

## 惰性执行

迭代器允许我们在第一次调用`next()`函数之后，再执行相应的逻辑。在上面的例子里，当我们调用迭代器的瞬间，我们就立刻执行了排序和取值的工作。但是，如果`next()`函数永远不被调用的话，我们就浪费了性能。所以让我们来优化它：

```js
table[Symbol.iterator] = function () {
  var _this = this;
  var keys = null;
  var index = 0;

  return {
    next: function () {
      if (keys === null) {
        keys = Object.keys(_this).sort();
      }

      return {
        value: keys[index], done: index++ >= keys.length
      };
    }
  }
}
```

`for-of`和`for-in`的差别

理解`for-of`和`for-in`之间的差别，是十分重要的。以下是一个简单的，但是非常好的解释差别的例子：

```js
var list = [3, 5, 7];
list.foo = 'bar';

for (var key in list) {
  console.log(key); // 0, 1, 2, foo
}

for (var value of list) {
  console.log(value); // 3, 5, 7
}
```

正如所见的，`for-of`循环仅打印出了数组中的值，忽略了其他属性。这是因为数组的迭代器只返回其中预期的元素。

## 内置迭代器

`String`，`Array`，`TypedArray`，`Map`和`Set`都是内置迭代器，因为它们的原型中都有一个`Symbol.iterator`方法。

```js
var string = "hello";

for (var chr of string) {
  console.log(chr); // h, e, l, l, o
}
```

## 解构赋值

解构操作同样也接受一个迭代器：

```js
var hello = 'world';
var [first, second, ...rest] = [...hello];
console.log(first, second, rest); // w o ["r","l","d"]
```

## 无限迭代器

只要永远不返回`done: true`，就实现了一个无限迭代器。当然，需要极力避免出现这种情况。

```js
var ids = {
  *[Symbol.iterator]: function () {
    var index = 0;

    return {
      next: function () {
        return { value: 'id-' + index++, done: false };
      }
    };
  }
};

var counter = 0;

for (var value of ids) {
  console.log(value);

  if (counter++ > 1000) { // let's make sure we get out!
    break;
  }
}
```

## Generator函数

如果你还不了解ES6 `generator` 函数，请参考[MDN文档](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Statements/function*)。简而言之，`generator`函数是当前被谈论最多的ES6特性，它是一个可以暂时退出，并且稍后重新进入继续执行的函数。在多次的进入中，它的上下文（绑定的变量）是会被保存的。`generator`函数自身就是一个迭代器，来看下面的例子：

```js
function* list(value) {
  for (var item of value) {
    yield item;
  }
}

for (var value of list([1, 2, 3])) {
  console.log(value);
}

var iterator = list([1, 2, 3]);

console.log(typeof iterator.next); // function
console.log(typeof iterator[Symbol.iterator]); // function

console.log(iterator.next().value); // 1

for (var value of iterator) {
  console.log(value); // 2, 3
}
```

所以，我们可以使用`generator`函数重写我们上面的迭代器：

```js
table[Symbol.iterator] = function* () {
  var keys = Object.keys(this).sort();

  for (var item of keys) {
    yield item;
  }
}
```

## 最后

迭代器给`JavaScript`中的循环，`generator`函数和值序列（value series）带来了一个新的维度。你可以使用它，定义一个类中，它的值的排序方式，也可以用通过其来创建一个惰性的或无限的序列，等等。

## 原文地址

[https://strongloop.com/strongblog/introduction-to-es6-iterators/][1]


  [1]: https://strongloop.com/strongblog/introduction-to-es6-iterators/
