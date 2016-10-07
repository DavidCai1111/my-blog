---
title: '[译] JavaScript ES6 class 指南'
date: 2015-08-15 13:39:28
tags:
---

## 前言

EcmaScript 2015 （又称ES6）通过一些新的关键字，使类成为了JS中一个新的一等公民。但是目前为止，这些关于类的新关键字仅仅是建立在旧的原型系统上的
语法糖，所以它们并没有带来任何的新特性。不过，它使代码的可读性变得更高，并且为今后版本里更多面向对象的新特性打下了基础。

这样做的原因是为了保证向后兼容性。也就是，旧代码可以在不做任何hack的情况下，与新代码同时运行。

## 定义类

让我们回想一下在ES5中定义一个类的方式。通过不是很常用的`Object.defineProperty`方法，我可以定义一些只读的属性。

```js
function Vehicle(make, year) {
  Object.defineProperty(this, 'make', {
    get: function() { return make; }
  });

  Object.defineProperty(this, 'year', {
    get: function() { return year; }
  });
}

Vehicle.prototype.toString = function() {
  return this.make + ' ' + this.year;
}

var vehicle = new Vehicle('Toyota Corolla', 2009);

console.log(vehicle.make); // Toyota Corolla
vehicle.make = 'Ford Mustang';
console.log(vehicle.toString()) // Toyota Corolla 2009
```

很简单，我们定义了一个有两个只读属性和一个自定义`toString`方法的`Vehicle`类。让我们在ES6中来做一样的事情：

```js
class Vehicle {
  constructor(make, year) {
    this._make = make;
    this._year = year;
  }

  get make() {
    return this._make;
  }

  get year() {
    return this._year;
  }

  toString() {
    return `${this.make} ${this.year}`;
  }
}

var vehicle = new Vehicle('Toyota Corolla', 2009);

console.log(vehicle.make); // Toyota Corolla
vehicle.make = 'Ford Mustang';
console.log(vehicle.toString()) // Toyota Corolla 2009
```

上面两个例子中定义的类有一个不同的地方。我们为了享受新的`get`语法带来的好处，所以只是将`make`和`year`定义成了普通的属性。这使它们可以被外部所改变。如果你确实需要一个严格的私有属性，还是请继续使用`defineProperty`。

## 类声明

在ES6中，有两个声明类的方式。第一种方法叫作 类声明，这也是我们在上述例子中使用的方式。

```js
class Vehicle() {
}
```

有一个需要注意的地方是，类声明与函数声明不同，它不会被提升（hoisted）。例如，以下的代码工作正常：

```js
console.log(helloWorld());

function helloWorld() {
  return "Hello World";
}
```

但是，以下代码会抛出一个异常：

```js
var vehicle = new Vehicle();

class Vehicle() {
}
```

## 类表达式

另一个定义类的方式叫做 类表达式。它与函数表达式的运行方式完全一样。一个类表达式可以是具名的也可以是匿名的。

```js
var Vehicle = class {
}

var Vehicle = class VehicleClass {
  constructor() {
    // VehicleClass is only available inside the class itself
  }
}

console.log(VehicleClass); // throws an exception
```

## 静态方法

`static`关键字是ES6的另一个语法糖，它使静态方法声明也成为了一个一等公民。在ES5中，静态方法就像是构造函数的一个属性。

```js
function Vehicle() {
  // ...
}

Vehicle.compare = function(a, b) {
  // ...
}
```

在使用了新的`static`关键字后：

```js
class Vehicle {
  static compare(a, b) {
    // ...
  }
}
```

在底层，`JavaScript`所做的，也只是将这个方法添加为`Vehicle`构造函数的一个属性。值得注意的是，你也可以用同样的语法为类添加静态属性。

## 类继承

旧的原型继承有时看起来让人非常头疼。ES6中新的`extends`关键字解决了这个问题。在ES5，我们是这么做的：

```js
function Motorcycle(make, year) {
  Vehicle.apply(this, [make, year]);
}

Motorcycle.prototype = Object.create(Vehicle.prototype, {
  toString: function() {
    return 'Motorcycle ' + this.make + ' ' + this.year;
  }
});

Motorcycle.prototype.constructor = Motorcycle;
```

使用的新的`extends`关键字，看上去就清晰多了：

```js
class Motorcycle extends Vehicle {
  constructor(make, year) {
    super(make, year);
  }

  toString() {
    return `Motorcycle ${this.make} ${this.year}`;
  }
}
```

`super`关键字也可以用于静态方法：

```js
class Vehicle {
  static compare(a, b) {
    // ...
  }
}

class Motorcycle {
  static compare(a, b) {
    if (super.compare(a, b)) {
      // ...
    }
  }
}
```

## super关键字

上一个例子也展示了新的`super`关键字的用法。当你想要调用父类的函数时，这个关键字就显得十分好用。

在想要调用父类的构造函数时，你可以简单地将`super`关键字视作一个函数使用，如`super(make, year)`。对于父类的其他函数，你可以将`super`视作一个对象，如`super.toString()`。例子：

```js
class Motorcycle extends Vehicle {
  toString() {
    return 'Motorcycle ' + super.toString();
  }
}
```

## 可被计算的方法名

当在`class`中声明属性时，定义属性名时，你可以使用表达式。这个语法特性在一些`ORM`类库中将会非常流行。例子：

```js
function createInterface(name) {
  return class {
    ['findBy' + name]() {
      return 'Found by ' + name;
    }
  }
}

const Interface = createInterface('Email');
const instance = new Interface();

console.log(instance.findByEmail());
```

## 最后

在当前，使用`class`关键字来声明类，而不使用原型，获得的仅仅是语法上的优势。但是，这个是一个适应新语法和新实践的好开始。`JavaScript`每天都在变得更好，并且通过`class`关键字，可以使各种工具更好得帮助你。

## 原文地址

[https://strongloop.com/strongblog/an-introduction-to-javascript-es6-classes/][1]

  [1]: https://strongloop.com/strongblog/an-introduction-to-javascript-es6-classes/
