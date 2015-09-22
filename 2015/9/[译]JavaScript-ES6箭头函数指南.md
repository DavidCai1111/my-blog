## 前言

胖箭头函数（Fat arrow functions），又称箭头函数，是一个来自ECMAScript 2015（又称ES6）的全新特性。有传闻说，箭头函数的语法`=>`，是受到了`CoffeeScript `的影响，并且它与`CoffeeScript`中的`=>`语法一样，共享`this`上下文。

箭头函数的产生，主要由两个目的：更简洁的语法和与父作用域共享关键字`this`。接下来，让我们来看几个详细的例子。

## 新的函数语法

传统的`JavaScript`函数语法并没有提供任何的灵活性，每一次你需要定义一个函数时，你都必须输入`function () {}`。`CoffeeScript`如今之所以那么火，有一个不可忽略的原因就是它有更简洁的函数语法。更简洁的函数语法在有大量回调函数的场景下好处特别明显，让我们从一个`Promise`链的例子看起：

```js
function getVerifiedToken(selector) {
  return getUsers(selector)
    .then(function (users) { return users[0]; })
    .then(verifyUser)
    .then(function (user, verifiedToken) { return verifiedToken; })
    .catch(function (err) { log(err.stack); });
}
```

以下是使用新的箭头函数语法进行重构后的代码：

```js
function getVerifiedToken(selector) {
  return getUsers(selector)
    .then(users => users[0])
    .then(verifyUser)
    .then((user, verifiedToken) => verifiedToken)
    .catch(err => log(err.stack));
}
```

以下是值得注意的几个要点：

 - `function`和`{}`都消失了，所有的回调函数都只出现在了一行里。
 -  当只有一个参数时，`()`也消失了（rest参数是一个例外，如`(...args) => ...`）。
 - 当`{}`消失后，`return`关键字也跟着消失了。单行的箭头函数会提供一个隐式的`return`（这样的函数在其他编程语言中常被成为lamda函数）。

这里再着重强调一下上述的最后一个要求。仅仅当箭头函数为单行的形式时，才会出现隐式的`return`。当箭头函数伴随着`{}`被声明，那么即使它是单行的，它也不会有隐式`return`：

```js
const getVerifiedToken = selector => {
  return getUsers()
    .then(users => users[0])
    .then(verifyUser)
    .then((user, verifiedToken) => verifiedToken)
    .catch(err => log(err.stack));
}
```

如果我们的函数内只有一条声明（statement），我们可以不写`{}`，这样看上去会和`CoffeeScript`中的函数非常相似：

```js
const getVerifiedToken = selector =>
  getUsers()
    .then(users => users[0])
    .then(verifyUser)
    .then((user, verifiedToken) => verifiedToken)
    .catch(err => log(err.stack));
```

你没有看错，以上的例子是完全合法的ES6语法。当我们谈论只包含一条声明（statement）的箭头函数时，这并不意味着这条声明不能够分成多行写。

这里有一个坑，当忽略了`{}`后，我们该怎么返回空对象（`{}`）呢？

```js
const emptyObject = () => {};
emptyObject(); // ?
```

不幸的是，空对象`{}`和空白函数代码块`{}`长得一模一样。。以上的例子中，`emptyObject`的`{}`会被解释为一个空白函数代码块，所以`emptyObject()`会返回`undefined`。如果要在箭头函数中明确地返回一个空对象，则你不得不将`{}`包含在一对圆括号中(`({})`)：

```js
const emptyObject = () => ({});
emptyObject(); // {}
```

下面是一个更完整的例子：

```js
function () { return 1; }
() => { return 1; }
() => 1

function (a) { return a * 2; }
(a) => { return a * 2; }
(a) => a * 2
a => a * 2

function (a, b) { return a * b; }
(a, b) => { return a * b; }
(a, b) => a * b

function () { return arguments[0]; }
(...args) => args[0]

() => {} // undefined
() => ({}) // {}
```

## this

`JavaScript`中`this`的故事已经是非常古老了，每一个函数都有自己的上下文。以下例子的目的是使用`jQuery`来展示一个每秒都会更新的时钟：

```js
$('.current-time').each(function () {
  setInterval(function () {
    $(this).text(Date.now());
  }, 1000);
});
```

当尝试在`setInterval`的回调中使用`this`来引用DOM元素时，很不幸，我们得到的只是一个属于回调函数自身上下文的`this`。一个通常的解决办法是定义一个`that`或者`self`变量：

```js
$('.current-time').each(function () {
  var self = this;

  setInterval(function () {
    $(self).text(Date.now());
  }, 1000);
});
```

但当使用胖箭头函数时，这个问题就不复存在了。因为它不产生属于它自己上下文的`this`：

```js
$('.current-time').each(function () {
  setInterval(() => $(this).text(Date.now()), 1000);
});
```

## arguments变量

箭头函数与普通函数还有一个区别就是，它没有自己的`arguments`变量：

```js
function log(msg) {
  const print = () => console.log(arguments[0]);
  print(`LOG: ${msg}`);
}

log('hello'); // hello
```

再次重申，箭头函数没有属于自己的`this`和`arguments`。但是，你仍可以通过rest参数，来得到所有传入的参数数组：

```js
function log(msg) {
  const print = (...args) => console.log(args[0]);
  print(`LOG: ${msg}`);
}

log('hello'); // LOG: hello
```

## 关于`yield`

箭头函数不能作为`generator`函数使用。

## 最后

箭头函数是我最喜欢的ES6特性之一。使用`=>`来代替`function`是非常便捷的。但我也曾见过只使用`=>`来声明函数的代码，我并不认为这是好的做法，因为`=>`也提供了它区别于传统`function`，其所独有的特性。我个人推荐，仅在你需要使用它提供的新特性时，才使用它：

 - 当只有一条声明（statement）语句时，隐式`return`。
 - 需要使用到父作用域中的`this`。

## 原文链接

https://strongloop.com/strongblog/an-introduction-to-javascript-es6-arrow-functions/
