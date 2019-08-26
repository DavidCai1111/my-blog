---
title: 一些当前 Node.js 中最流行 ES6 特性的 benchmark（V8 / Chakra）
date: 2016-03-20 13:52:19
tags:
---

## 前言
项目 github 地址：https://github.com/DavidCai1993/ES6-benchmark

如果有想要增加的特性 benchmark ，欢迎更新`benchmarks/` ，然后 PR 。

## 环境

 - CPU: Intel Core(TM) i5-2410M 2.30GHz
 - Memory: 8GB 1600 MHz DDR3
 - Node.js: 5.9.0 / Node-chakracore 6.0.0-pre5

## 大致结论

许多情况下： V8 ES5 >> Chakra ES6 > Chakra ES5 > V8 ES6

Chakra 下的 ES6 特性表现相对更好。
<!-- more -->
## Benchmark

[concat-strings.js](benchmarks/concat-strings.js)

```
V8:
template string vs use +
  14,643,602 op/s » ${a}${b}
  96,959,110 op/s » a + b

Chakra:
template string vs use +
  35,756,501 op/s » ${a}${b}
  19,995,366 op/s » a + b
```

[for-of-for-loop.js](benchmarks/for-of-for-loop.js)

```
V8:
for...of vs for loop
  851,761 op/s    » for...of
  12,507,823 op/s » for loop, i < arr.length

Chakra:
for...of vs for loop
  1,133,193 op/s  » for...of
  16,715,320 op/s » for loop, i < arr.length
```

[merge-objects.js](benchmarks/merge-objects.js)

```
V8:
merge objects
  669,921 op/s    » Object.assign
  23,625,182 op/s » for...in loop and assign

Chakra:
merge objects
  3,102,889 op/s  » Object.assign
  3,744,837 op/s  » for...in loop and assign
```

[declear-class.js](benchmarks/declear-class.js)

```
V8:
declear a class
  118,864 op/s » Class
  153,662 op/s » use function and prototype

Chakra:
declear a class
  560,705 op/s » Class
  701,991 op/s » use function and prototype
```

[repeat-string.js](benchmarks/repeat-string.js)

```
V8:
string.repeat() vs use +
  8,828,842 op/s   » string.repeat()
  107,824,137 op/s » use +

Chakra:
string.repeat() vs use +
  13,022,259 op/s  » string.repeat()
  3,328,631 op/s   » use +
```

[array-like-to-array.js](benchmarks/array-like-to-array.js)

```
V8:
array like object to array
  1,302,649 op/s » Array.from
  540,458 op/s   » Array.prototype.slice.call

Chakra:
array like object to array
  1,864,649 op/s » Array.from
  2,537,458 op/s   » Array.prototype.slice.call
```

[promise-bluebird.js](benchmarks/promise-bluebird.js)

```
promise vs bluebird
V8:
  322,534 op/s   » promise
  1,763,186 op/s » bluebird

Chakra:
  69,534 op/s   » promise
  178,186 op/s » bluebird
```

[var-let-const.js](benchmarks/var-let-const.js)

```
V8:
var let const
  134,028,614 op/s » let
  129,193,000 op/s » const
  431,460,321 op/s » var

Chakra:
var let const
  156,028,614 op/s » let
  170,193,000 op/s » const
  150,460,321 op/s » var
```

[string-start-with.js](benchmarks/string-start-with.js)

```
V8:
string starts with
  9,774,987 op/s  » string.startsWith(value)
  74,127,611 op/s » string[0] === value

Chakra:
string starts with
  26,774,987 op/s » string.startsWith(value)
  47,127,611 op/s » string[0] === value
```

[define-a-funciton-with-this.js](benchmarks/define-a-funciton-with-this.js)

```
V8:
define a function with inherited this
  59,661,143 op/s » () =>
  64,874,220 op/s » function statement

Chakra:
define a function with inherited this
  69,661,143 op/s » () =>
  69,874,220 op/s » function statement
```

[parse-int.js](benchmarks/parse-int.js)

```
V8:
global.parseInt() vs Number.parseInt()
  53,940,634 op/s  » Number.parseInt()
  81,509,873 op/s  » global.parseInt()

Chakra:
global.parseInt() vs Number.parseInt()
  16,940,634 op/s  » Number.parseInt()
  19,509,873 op/s  » global.parseInt()
```
