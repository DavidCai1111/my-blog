## 前言

ECMAScript 2015（又称ES6）提供了一个前端`JavaScript`缺失已久的特性 —— 模块。ES2015中的模块参考了CommonJS规范（目前`Node.js`的模块规范）以及AMD规范，并且尽可能的取其精华，去其糟粕：

 - 它提供了简洁的语法
 - 以及异步的，可配置的模块加载

这篇文章将会专注于ES2015的模块语法以及注意点。关于模块的加载和打包，将会在另一篇文章中细述。


## 为什么要使用模块？

目前最普遍的`JavaScript`运行平台便是浏览器，在浏览器中，所有的代码都运行在同一个全局上下文中。这使得你即使更改应用中的很小一部分，你也要担心可能会产生的命名冲突。

传统的`JavaScript`应用被分离在多个文件中，并且在构建的时候连接在一起，这稍显笨重。所以人们开始将每个文件内的代码都包在一个自执行函数中：`(function() { ... })();`。这种方法创建了一个本地作用域，于是最初的模块化的概念产生了。之后的CommonJS和AMD系统中所称的模块，也是由此实现的。

换句话说，现存的“模块”系统是使用已有的语言特性所实现的。而ES2015则通过添加适当的新的语言特性，来使之官方化了。

## 创建模块

一个`JavaScript`模块就是一个对其他模块暴露一些内部属性/方法的文件。我们在这里仅会讨论浏览器中的ES2015模块系统，并不会涉及`Node.js`是如何组织它自身的模块的。一些在创建ES2015模块时需要注意的点：

### 每个模块都有自己的上下文

和传统的`JavaScript`不同，在使用模块时，你不必担心污染全局作用域。恰恰相反，你需要把所以你需要用到的东西从其他模块中导入进来。但是，这样也会使模块之间的依赖关系更为清晰。

### 模块的名字

模块的名字由它的文件名或文件夹名所决定，并且你可以忽略它的`.js`后缀：

 - 如果你有一个叫`utils.js`的文件，那么你可以通过`./utils`这样的相对路径导入它
 - 如果你有一个叫`./utils/index.js`的文件，则你可以通过`./utils/index`或`./utils`来导入它。这使得你可以批量导入一个文件夹内的所有模块。

## 导出和导入

可以使用ES2015的新关键字`import`和`exports`来导入或导出模块中的东西。模块可以导入和导出各种类型的变量，如函数，对象，字符串，数字，布尔值，等等。

### 默认导出

每一个模块都支持导出**一个**不具名的变量，这称作默认导出：

```js
// hello-world.js
export default function() {}

// main.js
import helloWorld from './hello-world';
import anotherFunction from './hello-world';

helloWorld();
console.log(helloWorld === anotherFunction);
```

等价的CommonJS语法：

```js
// hello.js
module.exports = function() {}

// main.js
var helloWorld = require('./hello-world');
var anotherFunction = require('./hello-world');

helloWorld();
console.log(helloWorld === anotherFunction);
```

任何的`JavaScript`值都可以被默认导出：

```js
export default 3.14;
export default {foo: 'bar'};
export default 'hello world';
```

### 具名导出

除了默认导出外，ES2015的模块系统还支持导出任意数量个具名的变量：

```js
const PI = 3.14;
const value = 42;
export function helloWorld() {}
export {PI, value};
```

等价的CommonJS语法：

```js
var PI = 3.14;
var value = 42;
module.exports.helloWorld = function() {}
module.exports.PI = PI;
module.exports.value = value;
```

你也可以在导出变量时对其重命名：

```js
const value = 42;
export {value as THE_ANSWER};
```

等价的CommonJS语法：

```js
var value = 42;
module.exports.THE_ANSWER = value;
```

在导入时，你也可以使用`as`关键字来重命名导入的变量：

```js
import {value as THE_ANSWER} from './module';
```

等价的CommonJS语法：

```js
var THE_ANSWER = require('./module'').value;
```

### 导入所有

最简单的，在一条命令中导入一个模块中所有变量的方法，是使用`*`标记。这样一来，被导入模块中所有导出的变量都会变成它的属性，默认导出的变量则会被置于`default`属性中。

```js
// module.js
export default 3.14;
export const table = {foo: 'bar'};
export function hello() {};

// main.js
import * as module from './module';
console.log(module.default);
console.log(module.table);
console.log(module.hello());
```

等价的CommonJS语法：

```js
// module.js
module.exports.default = 3.14;
module.exports.table = {foo: 'bar'};
module.exports.hello = function () {};

// main.js
var module = require('./module');
console.log(module.default);
console.log(module.table);
console.log(module.hello());
```

值得再强调的是，`import * as foo from`和`import foo from`的区别。后者仅仅会导入默认导出的变量，而前者则会在一个对象中导入所有。

### 导出所有

一个可能的需求是，你需要将另一个模块中的一些（或所有）值在你的模块中再次导出，这被称作二次导出（re-exporting）。值得注意的是，你可以二次导出许多同名的值，这将不会导致异常，而是最后一个被导出的值将会获得胜利。

```js
// module.js
const PI = 3.14;
const value = 42;
export const table = {foo: 'bar'};
export function hello() {};

// main.js
export * from './module';
export {hello} from './module';
export {hello as foo} from './module';
```

等价的CommonJS语法：

```js
// module.js
module.exports.table = {foo: 'bar'};
module.exports.hello = function () {};

// main.js
module.exports = require('./module');
module.exports.hello = require('./module').hello;
module.exports.foo = require('./module').hello;
```

## 注意点

一个关键点时，导入模块的东西，并不是一个引用或一个值，而是一个类似与被导入模块内部的一个`getter`对象。所以这可能会导致一些不符合预期的行为。

### 缺乏异常

在具名地导入其他模块的变量时，如果你不小心打错了变量名，这将不会抛出异常，而是导入的值将会变成`undefined`。

```js
// module.js
export const value = 42;

// main.js
import {valu} from './module'; // no errors
console.log(valu); // undefined
```

### 可变的基本类型值

在导入一些基本类型的值（如数字，布尔值或字符串）时，可能会产生一个有趣的副作用。这些值可能会在模块外被修改。例子：

```js
// module.js
export let count = 0;

export function inc() {
  count++;
}

// main.js
import {count, inc} from './module'; // `count` is a `Number` variable

assert.equal(count, 0);
inc();
assert.equal(count, 1);
```

上面的例子中，`count`变量是一个数值类型，它在`main`模块中被修改了值。

### 导入的变量是只读的

不论你以何种声明导出变量，它们都是只读的。但是，如果导出的是对象，你可以改变变量的属性。

```js
// module.js
export let count = 0;
export const table = {foo: 'bar'};

// main.js
import {count, table} from './module;

table.foo = 'Bar'; // OK
count++; // read-only error
```

### 测试模块

如果想要测试，或`mock`被导出的变量，很不幸，这在新的ES2015模块系统中是办不到的。因为与CommonJS一样，导出的变量在外面不能被重新赋值。唯一的解决办法是，导出一个单独的对象。

```js
// module.js
export default {
  value: 42,
  print: () =&gt; console.log(this.value)
}

// module-test.js
import m from './module';
m.value = 10;
m.print(); // 10
```

## 最后

ES2015的模块标准化了模块的加载和解析方式。CommonJS和AMD之间的争论终于被解决了。

我们得到了更简洁的模块语法，以及静态的模块定义，这有助于编译器的优化，甚至是类型检查。

原文链接：https://strongloop.com/strongblog/an-introduction-to-javascript-es6-modules/
