---
title: 用 ES6 重写 《JavaScript Patterns》中的设计模式
date: 2015-05-27 13:35:16
tags:
---

## 前言
最近在回顾设计模式方式的知识，重新翻阅了[《JavaScript模式》][1]（个人感觉也算是一本小有名气的书了哈）一书，读时总有感触：在即将到来的ES6的大潮下，书中的许多模式的代码可用ES6的语法更为优雅简洁的实现，而另一些模式，则已经被ES6原生支持，如模块模式（99页）。所以自己动手用ES6重新实现了一遍里面的设计模式，算是对其的巩固，也算是与大家一起来研究探讨ES6语法的一些最佳实践。

## 目录
（以下所有例子的原型均为《JavaScript模式》一书里“设计模式”章节中的示例）

 - [单例模式](#单例模式)
 - [迭代器模式](#迭代器模式)
 - [工厂模式](#工厂模式)
 - [装饰者模式](#装饰者模式)
 - [策略模式](#策略模式)
 - [外观模式](#外观模式)
 - [代理模式](#代理模式)
 - [订阅/发布模式](#订阅/发布模式)

[代码repo地址][2]，欢迎star，欢迎follow。

<!-- more -->
## 实现

### 单例模式
主要改变为使用了class的写法，使对象原型的写法更为清晰，更整洁：
```js
'use strict';
let __instance = (function () {
  let instance;
  return (newInstance) => {
    if (newInstance) instance = newInstance;
    return instance;
  }
}());

class Universe {
  constructor() {
    if (__instance()) return __instance();
    //按自己需求实例化
    this.foo = 'bar';
    __instance(this);
  }
}

let u1 = new Universe();
let u2 = new Universe();

console.log(u1.foo); //'bar'
console.log(u1 === u2); //true
```

### 迭代器模式
ES6原生提供的Iterator接口就是为这而生的啊，使用胖箭头函数写匿名函数（还顺带绑定了上下文，舒舒服服）：
```js
'use strict';
let agg = {
  data: [1, 2, 3, 4, 5],
  [Symbol.iterator](){
    let index = 0;
    return {
      next: () => {
        if (index < this.data.length) return {value: this.data[index++], done: false};
        return {value: undefined, done: true};
      },
      hasNext: () => index < this.data.length,
      rewind: () => index = 0,
      current: () => {
        index -= 1;
        if (index < this.data.length) return {value: this.data[index++], done: false};
        return {value: undefined, done: true};
      }
    }
  }
};

let iter = agg[Symbol.iterator]();
console.log(iter.next()); // { value: 1, done: false }
console.log(iter.next()); // { value: 2, done: false }
console.log(iter.current());// { value: 2, done: false }
console.log(iter.hasNext());// true
console.log(iter.rewind()); // rewind!
console.log(iter.next()); // { value: 1, done: false }

// for...of
for (let ele of agg) {
  console.log(ele);
}
```

### 工厂模式
个人感觉变化比较不大的一个：
```js
'use strict';
class CarMaker {
  constructor() {
    this.doors = 0;
  }

  drive() {
    console.log(`jaja, i have ${this.doors} doors`);
  }

  static factory(type) {
    return new CarMaker[type]();
  }
}

CarMaker.Compact = class Compact extends CarMaker {
  constructor() {
    super();
    this.doors = 4;
  }
};

CarMaker.factory('Compact').drive(); // 'jaja, i have 4 doors'
```

### 装饰者模式
`for...of`循环，新时代的`for (var i = 0 ; i < arr.length ; i++)`？ :
```js
'use strict';
class Sale {
  constructor(price) {
    [this.decoratorsList, this.price] = [[], price];
  }

  decorate(decorator) {
    if (!Sale[decorator]) throw new Error(`decorator not exist: ${decorator}`);
    this.decoratorsList.push(Sale[decorator]);
  }

  getPrice() {
    for (let decorator of this.decoratorsList) {
      this.price = decorator(this.price);
    }
    return this.price.toFixed(2);
  }

  static quebec(price) {
    return price + price * 7.5 / 100;
  }

  static fedtax(price) {
    return price + price * 5 / 100;
  }
}

let sale = new Sale(100);
sale.decorate('fedtax');
sale.decorate('quebec');
console.log(sale.getPrice()); //112.88
```

### 策略模式
对于传统的键值对，使用Map来代替对象(数组)来组织，感觉带来得是更好的语义和更方便的遍历：
```js
'use strict';
let data = new Map([['first_name', 'Super'], ['last_name', 'Man'], ['age', 'unknown'], ['username', 'o_O']]);
let config = new Map([['first_name', 'isNonEmpty'], ['age', 'isNumber'], ['username', 'isAlphaNum']]);

class Checker {
  constructor(check, instructions) {
    [this.check, this.instructions] = [check, instructions];
  }
}

class Validator {
  constructor(config) {
    [this.config, this.messages] = [config, []];
  }

  validate(data) {
    for (let [k, v] of data.entries()) {
      let type = this.config.get(k);
      let checker = Validator[type];
      if (!type) continue;
      if (!checker) throw new Error(`No handler to validate type ${type}`);
      let result = checker.check(v);
      if (!result) this.messages.push(checker.instructions + ` **${v}**`);
    }
  }

  hasError() {
    return this.messages.length !== 0;
  }
}

Validator.isNumber = new Checker((val) => !isNaN(val), 'the value can only be a valid number');
Validator.isNonEmpty = new Checker((val) => val !== "", 'the value can not be empty');
Validator.isAlphaNum = new Checker((val) => !/^a-z0-9/i.test(val), 'the value can not have special symbols');

let validator = new Validator(config);
validator.validate(data);
console.log(validator.messages.join('\n')); //the value can only be a valid number **unknown**
```

### 外观模式
这个简直没啥好变的。。。：
```js
'use strict';
let nextTick = (global.setImmediate == undefined) ? process.nextTick : global.setImmediate;
```

### 代理模式
利用`extends`关键字来获得父类中的方法引用以及和父类相同的类接口：
```js
'use strict';
class Real {
  doSomething() {
    console.log('do something...');
  }
}

class Proxy extends Real {
  constructor() {
    super();
  }

  doSomething() {
    setTimeout(super.doSomething, 1000 * 3);
  }
}

new Proxy().doSomething(); //after 3s ,do something...
```

### 订阅/发布模式
被Node原生的Events模块所支持，同样结合默认参数，for...of遍历等特性，代码的减少以及可读性的增加都是可观的：
```js
'use strict';
class Event {
  constructor() {
    this.subscribers = new Map([['any', []]]);
  }

  on(fn, type = 'any') {
    let subs = this.subscribers;
    if (!subs.get(type)) return subs.set(type, [fn]);
    subs.set(type, (subs.get(type).push(fn)));
  }

  emit(content, type = 'any') {
    for (let fn of this.subscribers.get(type)) {
      fn(content);
    }
  }
}

let event = new Event();

event.on((content) => console.log(`get published content: ${content}`), 'myEvent');
event.emit('jaja', 'myEvent'); //get published content: jaja
```

## 最后
以上所有代码均可通过[Babel][3]跑通，90%以上的代码可被当前版本的io.js(v2.0.2)跑通。


  [1]: http://www.oreilly.com.cn/index.php?func=book&isbn=978-7-5123-2923-2
  [2]: https://github.com/DavidCai1993/JsPattern-ES6
  [3]: https://babeljs.io
