---
title: '[译]从 coffeeScript 迁移到 ES6'
date: 2015-05-24 13:33:50
tags:
---

## 从coffeeScript迁移到ES6
我在多年前爱上了coffeScript。对于javaScript，我一直保持着深沉的爱，也十分高兴得看到node.js的快速发展，但是作为一个有python背景的程序员，我更喜欢coffeeScript的简练语法。
在任何一个活跃的社区中，事物的迭代更新都是必然的，现在，我们看见了javaScript向着ES6标准的巨大进步。ES6包含了相比于CoffeeScript更多好的特性，并且通过如[Babel][1]这样的工具，我们已经可以开始着手使用他们。以下是从coffeeScript迁移到ES6的一些注意点和我的想法。

### 符号
放弃空格（`whitespace`），重新转而使用圆括号，花括号和分号。请接受在使用ES6时，你会敲上更多的符号。不过在规范的代码格式下，它们看上去还是挺整洁的。

### 语法校验
过去我使用的是[CoffeeLint][2]，现在我通过[babel-eslint][3]来使用[ESLint][4]。遵循[Airbnb ES6 style guide][5]这个语法风格指南。最好将你的编辑器设置成在输入或保存时进行语法检查。[Atom's eslint plugin][6]这个语法校验插件非常不错，你可以将上面的`Airbnb ES6 style guide`链接中的内容，放入你的`.eslintrc`配置文件中。SublimeText也有[类似的插件][7]。

### 代码转换（Transpiling）
由于现在离对ES6的完美支持还很远，所以最好还是使用代码转换器（Transpiling），如[Babel][8]，就像在用CoffeeScript时一样。不过和CoffeeScript不同的是，这里有一些值得说明的：

1，并不是所有的ES6特性全部都可用，诸如`Proxies`。

2，另有一些ES6特性需要使用`polyfill/runtime`才可用，如Symbols，generator函数，WeakMap。一段`package.json`的例子：
```json
{
  ...
  "scripts": {
    "lint": "eslint --ext .js,.es6 src",
    "precompile": "npm run lint",
    "compile": "babel --optional runtime src --out-dir lib",
  },
  "dependencies": {
    "babel-runtime": "^5.3.3"
  },
  "devDependencies": {
    "babel": "^5.3.3",
    ...
  }
  ...
}
```
请不要将`babel`放入`dependencies `中，这样会下载许多你并不需要的package，请将`babel-runtime`写在`dependencies `中，将`babel`写在`devDependencies`中。

3，一些CoffeeScript即有的特性如数组推导（list comprehensions）在ES6中也是不可用的，因为这些特性的规范还未被完全完善。

### Let和Const
`var`已经过时了，现在流行的是它的好基友`let`和`const`。今后在javaScript中，如果要声明不可变的变量，请使用`const`，反之，请使用`let`。
语法校验会给出警告当你仍在使用`var`或不同任何关键字声明变量时。

有一个值得注意的点是，`const`**仅仅**是指向变量所在的地址，这可能需要花一点时间去适应：
```js
const name = 'Daniel';

// This is a compile error
name = 'Kari';

// ---------
const options = {};
const items = [];

// This is *not* a compile error
options.foo = 'bar';
options.baz = 5;
items.push(1);
items.push(2);

// This *is* a compile error
options = {};
items = null;
```

### 字符串替换
幸运的是，CoffeScript和ES6关于字符串替换方面区别很小，你要做的只是改变一下你的手指肌肉记忆：
```js
const name = 'World';

console.log(`Hello, ${name}!`);
```
注意反引号代替了双引号。

请确保你的编辑器能正确的高亮这些新语法，我敢保证在一开始你任然会时不时敲出`#{name}`。。

### 函数
ES6中，有了一些新的函数类型，如generator函数和胖箭头（=>）函数。胖箭头函数在ES6和CoffeeScript中表现一致，如绑定函数中的上下文（this）为它被定义时的上下文。

函数的变参也同样被支持，但是与coffeeScript语法不同的是，ES6中省略号在另外一侧。参数默认值和解构赋值也同样被支持。

coffeeScript:
```Coffee
square = (value) -> value * value

someTask (err, result) =>
  # Handle err and result

myFunc = ({source, flag}, args...) ->
  otherFunc source, args...
```

javaScript:
```js
const square = value => value * value;

someTask((err, result) => {
  // Handle err and result
});

function myFunc({source, flag}, ...args) {
  return otherFunc(source, ...args);
}
```

#### generator函数：
generator函数提供了一种迭代一系列超长任务的便捷方式，例子：
```js
// Instead of creating a 10000 item array, we yield each item as
// needed.
function *squares() {
  for (let n = 0; n < 10000; n++) {
    yield n * n;
  }
}

for (let square of squares()) {
  console.log(square);
}
```
通过`function*`语法来声明一个generator函数。这与CoffeScript中只要函数体内包含`yield`关键字，本函数就是generator函数不同。generator函数同样也可以yield和返回值。

### 类（Classes）
两者关于类的语法非常的相似，不过在ES6中，只可以在`class`中声明函数。下面的例子说明了两者语法的接近，包括继承：

coffeeScript:
```Coffee
class Account extends Foo
  @types = ['checking', 'savings']

  constructor: (@balance) ->

  history: (done) ->
    someLongTask (err, data) ->
      # Do something with data
      done null, data

  deposit: (amount) ->
    @balance += amount
```

javaScript:
```js
class Account extends Foo {
  constructor(balance) {
    this.balance = balance;
  }

  history(done) {
    someLongTask((err, data) => {
      // Do something with data
      done(null, data);
    });
  }

  deposit(amount) {
    this.balance += amount;
    return this.balance;
  }
}

// Currently, you can only declare functions in a class
Account.types = ['checking', 'savings'];
```

一个不错的特性是类有了定义`getter`和`setter`的能力，不过它们不能是generator函数：
```js
class Account {
  constructor() {
    this.balance = 0;
  }

  get underBudget() {
    return this.balance >= 0;
  }

  get overBudget() {
    return this.balance < 0;
  }
}

const myAccount = Account();
myAccount.balance = 100;
console.log(myAccount.underBudget); // => true
```

### 可遍历类（Iterable Classes）
另一个灵活的特性就是可以创建可遍历类，并且可以将generator函数用于遍历器。
```js
class MyIterable {
  constructor(items) {
    this.items = items;
  }

  *[Symbol.iterator]() {
    for (let item of this.items) {
      yield `Hello, ${item}`;
    }
  }
}

const test = new MyIterable([1, 2, 3, 4, 5]);

for (let item of test) {
  console.log(item); // => Hello, 1...
}
```

### 模块
ES6提供了一个[新的模块语法][9]，这也需要花一定时间适应，因为它同时提供了匿名导出和普通导出：
```js
import _ from 'lodash';
import {item1, item2} from './mylib';
import * as library from 'library';

//普通导出
export const name = 'Daniel';

export function abc() {
  return 1;
}

export class Toaster {
  // ...
}

//匿名导出
export default function() {
  return new Toaster();
}
```

几个值得注意的点：
1，如果不使用匿名导出，你不能直接通过`import moduleName from 'moduleName';`来获取所有的导出对象，而是要使用`import * as moduleName from 'moduleName';`:
```js
// mymodule.js
// -----------
export function yes() { return true; }

// script-broken.js
// ----------------
import mymodule from './mymodule';

// This gives an error about `undefined`!
console.log(mymodule.yes());

// script-working.js
// -----------------
import * as mymodule from './mymodule';

console.log(mymodule.yes());
```

2，如果脚本中仅仅只有一个匿名导出，那么在使用Node.js的`require`命令引入时，这个匿名导出的对象表现得像被传递给了`module.exports`一样。**但是**如果脚本中还有其他的普通导出，就会得到非常奇怪的结果：
```js
// mymodule.js
// -----------
export function yes() { return true; }
function no() { return false; }
export default {yes, no};

// script-working.js
// -----------------
import mymodule, {yes} from './mymodule';

console.log(mymodule.no());
console.log(yes());

// script-broken.js
// ----------------
const mymodule = require('./mymodule');

// Wat? This is an error.
console.log(mymodule.no());

// This works instead. Turns out the module is an object with a 'default'
// key that contains the default export.
console.log(mymodule.default.no());
```
这个坑爹的情况目前还没有任何好的解决方案。所以如果你正在写一个库并且准备让Node.js使用者使用`require`命令对其进行导入，最好只使用一次匿名导出，并且把一切的一切都绑定在这个匿名导出的对象的属性上。

### 结语
希望本文可以帮助到一些准备从coffeeScript迁移到ES6的人，我本人也在学习ES6的过程中感受到十足的乐趣，并且我对我的新玩具ESLint和Babel实在是爱不释手。。

[原文链接][10]


  [1]: https://babeljs.io/
  [2]: https://www.npmjs.com/package/coffeelint
  [3]: https://github.com/babel/babel-eslint
  [4]: http://eslint.org/
  [5]: https://github.com/airbnb/javascript
  [6]: https://atom.io/packages/linter-eslint
  [7]: https://github.com/roadhump/SublimeLinter-eslint
  [8]: https://babeljs.io/
  [9]: http://www.2ality.com/2014/09/es6-modules-final.html
  [10]: https://gist.github.com/danielgtaylor/0b60c2ed1f069f118562
