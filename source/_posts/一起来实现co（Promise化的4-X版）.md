---
title: 一起来实现 co（Promise 化的 4.X 版）
date: 2015-06-07 13:31:57
tags:
---

前言
----------
大名鼎鼎的[co][1]正是TJ大神基于ES6的一些新特性开发的异步流程控制库，基于它所开发的[koa][2]更是被视为未来主流的web框架。之前在论坛也看了不少大神们关于co源码的分析，不过co在升级为4.X版本时，代码进行了一次颇有规模的重构，从先前的基于[thunkify函数][3]，改变成了现在的**基于Promise**，并且可能在未来版本移除对thunkify函数的支持。正好小弟最近也在看TJ大神的源码，也来分享一下co（4.X）的实现思路以及源码注解。

进入正题
----------
以下是两段co（4.X）的经典使用示例：
```js
co(function* () {
  var result = yield Promise.resolve(true);
  return result;
}).then(function (value) {
  console.log(value);
}, function (err) {
  console.error(err.stack);
});
```
<!-- more -->
```js
co(function *(){
  // resolve multiple promises in parallel
  var a = Promise.resolve(1);
  var b = Promise.resolve(2);
  var c = Promise.resolve(3);
  var res = yield [a, b, c];
  console.log(res);
  // => [1, 2, 3]
}).catch(onerror);
```
再结合co的文档，我们可以把co的主要功能分为：

 - 异步流程控制，依次执行**generator函数**内的每个位于**yield**后的**Promise对象**，并在Promise的状态改变后，把其将要**传递给reslove函数的结果**或**传递给reject函数的错误**返回出来，可供外部来进行传递值等操作，这些Promise是**串行执行**的。
 - 若**yield**后是**Promise对象的数组**或**属性值是Promise对象的对象**，则返回出**结构相同**的Promise执行结果数组/对象，并且这些Promise是**并行执行**的。
 - co自身的返回值也是一个Promise对象，可供继续使用。

好了，我们要实现以上这几个功能，其实就是解决以下几个问题：

1，确保每一个**yield**动作的串行执行，并正确的返回异步结果。
2，若在yield后的是**Promise数组**或**属性值为Promise对象的对象**，则并行执行这些Promise。
3，检查每一个yield后的对象**是否符合要求**，若不，则尝试进行转换。
4，最后整体返回一个Promise。

我们来逐个击破。

#### 解决1,4
以下是co（4.X）源码中的解决1，4的方案：
```js
function co(gen) {
  var ctx = this;

  /**
   * 我们看到，co函数整个的返回值便是一个Promise实例，包装了
   * 传递的generator函数内所有Promise的执行，
   * 我们暂且称它为"外壳Promise"吧，而在传递进来的generator函数内的所有Promise我们都先称为“内部Promise”，
   * 用以区分。
   */
  return new Promise(function(resolve, reject) {

    //判断传递给co的参数，若是一个generator函数，则执行之，得到一个generator对象
    if (typeof gen === 'function') gen = gen.call(ctx);
    //此时gen对象还不是一个generator对象的话，
    //则调用“外壳Promise”的resolve，直接结束整个“外壳Promise”，把参数值作为结果传出
    if (!gen || typeof gen.next !== 'function') return resolve(gen);

    //入口，这个函数的详细分析请往下看两行。。
    onFulfilled();

    //这个onFulfilled函数主要有两个用途:
    //第一个用途就是上面的入口函数的功能，将generator执行到第一个yield处开启第一个异步调用
    //第二个用途便是当作所有”内部Promise“的resolve方法，处理异步结果，并继续调用下一个Promise
    function onFulfilled(res) {
      var ret;
      try {
        //当作为”内部Promise“的resolve方法时，res参数自然便是本次Promise的执行结果了
        //利用generator函数的特性，调用next方法时的参数，会当做yield的返回值，这样我们就做到了将异步的结果返回出来
        ret = gen.next(res);
      } catch (e) {
        //若报错，则直接调用"外壳Promise"的reject方法，直接结束整个“外壳Promise”，把错误对象作为结果传出
        return reject(e);
      }

      //将generator.next的执行结果传入next函数，实现串行调用。关于next函数的分析也请往下看。。
      next(ret);
    }

    //这个onRejected函数的用途自然便是当作"内部Promise"的reject方法啦
    function onRejected(err) {
      var ret;
      try {
        ret = gen.throw(err);
      } catch (e) {
        return reject(e);
      }
      next(ret);
    }

    //这个next函数便是用来执行串行调用
    function next(ret) {
      //如果“内部Promise”，全部执行完毕，done的值便已经是generator函数中的return出的值了，
      //把这个结果传递给“外壳Promise”的resolve函数，暴露给处理整个co结果的后续调用
      if (ret.done) return resolve(ret.value);

      //若“内部Promise”尚未执行完毕，那么确保ret.value是一个Promise对象，并进而调用它
      var value = toPromise.call(ctx, ret.value);
      if (value && isPromise(value)) return value.then(onFulfilled, onRejected);
      return onRejected(new TypeError('You may only yield a function, promise, generator, array, or object, '
        + 'but the following object was passed: "' + String(ret.value) + '"'));
    }
  });
}
```

好，到这儿我们已经把co4.X的核心串行调用的实现过程给搞定了。整个的执行流程可以归结为：

 * 进入“**外壳Promise**”
 * 通过入口**onFulfilled()**，取得第一个Promise对象
 * 将每一个“**内部Promise**”通过**then(onFulfilled, onRejected)**开始执行，并将resolve函数都封装为**onFulfilled()**，reject函数都封装为**onRejected()**
 * 通过在**onFulfilled()**或**onRejected()**内调用**next方法**，实现在一个异步调用结果返回后继续执行下一个，通过将结果作为**参数**传递给next方法，实现将异步结果返回给外部，依次往复。
 * 所有“**内部Promise**”执行完毕，将最后结果暴露给“**外壳Promise**”的处理函数，结束

#### 解决2,3
在TJ大神的源码中，2其实伴随在3(即上面代码中的**toPromise**方法)中解决的，我们来看一下：
```js
/**
 * 主要任务便是将传入的参数对象转换为Promise对象
 */
function toPromise(obj) {
  //确保obj有意义
  if (!obj) return obj;
  //如果已经是Promise对象，则直接把obj返回出去
  if (isPromise(obj)) return obj;
  //若是generator函数或现成的generator对象，则直接把obj作为参数传入co函数，并把这个co函数
  //返回出来的"外壳Promise"作为return出来的Promise
  if (isGeneratorFunction(obj) || isGenerator(obj)) return co.call(this, obj);
  //若obj是函数，则直接视为符合thunk规范的函数（thunk函数是啥这里就不细说了哈。。），直接转换
  if ('function' == typeof obj) return thunkToPromise.call(this, obj);
  //若是Promise数组，则调用arrayToPromise方法
  if (Array.isArray(obj)) return arrayToPromise.call(this, obj);
  //若是属性值是Promise对象的对象，则调用objectToPromise方法
  if (isObject(obj)) return objectToPromise.call(this, obj);
  return obj;
}
```

5个**if**其实就是一堆的判断并执行响应转换咯（废话。。），看来已经解决了问题3，问题2的精髓自然就是**arrayToPromise**和**objectToPromise**，好，我们来攻克这最后一道壁垒：

先是**arrayToPromise**：
```js
/**
 * 利用ES6规范中的Promise.all方法，充当全部结果的返回者
 * 利用Array.map方法，实现了并行操作，分别对数组中的每一个元素递归执行toPromise方法，把这些子Promise接着
 * 返回co中来获取执行结果，最后等待这些子Promise全部得到结果后，Promise.all执行成功，
 * 返回执行结果数组
 * 这实现，请收下我的膝盖。。。
 */
function arrayToPromise(obj) {
  return Promise.all(obj.map(toPromise, this));
}
```

接着是**objectToPromise**：
```js
/**
 * 与数组略有不同，利用for循环来实现并行的异步调用，
 * Promise.all()仅充当一个类计数器，并返回最终结果
 */
function objectToPromise(obj){
  //results是将用于返回的对象，使用和obj相同的构造函数
  var results = new obj.constructor();
  //Object.keys方法用于返回对象的所有的属性名
  var keys = Object.keys(obj);
  //寄存所有对象属性的Promise的数组
  var promises = [];

  //利用for循环来实现异步
  for (var i = 0; i < keys.length; i++) {
    var key = keys[i];
    //确保obj[key]为Promise对象，然后调用defer推入promises数组等待执行，否则直接将结果返回给result[key]
    var promise = toPromise.call(this, obj[key]);
    if (promise && isPromise(promise)) defer(promise, key);
    else results[key] = obj[key];
  }

  //传入的是promise.then()返回的空Promise，所以此处Promise.all仅充当一个计数器，确保所有异步操作的resolve操作中对results对象的属性都赋值完毕后，返回最终的results对象
  return Promise.all(promises).then(function () {
    return results;
  });

  //执行异步操作，并在操作结果赋值给results[key]
  function defer(promise, key) {
    results[key] = undefined;
    promises.push(promise.then(function (res) {
      results[key] = res;
    }));
  }
}
```

好了，到这我们已经把co（4.X）的核心源码实现都搞定，它的庐山真面目就是这样啦~

如有任何不正确之处，欢迎指出^ ^

参考
----------
[co][4]


  [1]: https://www.npmjs.com/package/co
  [2]: https://www.npmjs.com/package/koa
  [3]: https://www.npmjs.com/package/thunkify
  [4]: https://github.com/tj/co
