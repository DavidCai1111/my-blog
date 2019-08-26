---
title: '分享一个自己写的小工具: dir-requirer'
date: 2015-04-27 13:31:11
tags:
---

前言
----------

之前在看许多站点的源代码时，类似这样的代码总是屡见不鲜：
```js
var sign = require('./controllers/sign');
var site = require('./controllers/site');
var user = require('./controllers/user');
var message = require('./controllers/message');
var topic = require('./controllers/topic');
var reply = require('./controllers/reply');
var rss = require('./controllers/rss');
var staticController  = require('./controllers/static');
var auth = require('./middlewares/auth');
var limit = require('./middlewares/limit');
var github = require('./controllers/github');
var search = require('./controllers/search');
```
这可以算是许多站点route文件里的小常态了，往往在一个文件(web_router.js)里引用另一个目录(./controllers与./middlewares)里的大量（甚至所有）js文件。这其实是一种不是很爽的编程体验。所以笔者这里自己动手写了一个`以目录为单位`来导入整个目录下所有module的小工具：[dir-requirer][1]，支持导入目录下所有的`.js`,`.json`和`.node`文件(可自定义)，并且返回一个`与目录结构相同`的对象，支持`屏蔽指定文件及目录`。
<!-- more -->
以下是工具简介：
--------
## 用途
dir-requirer是一个对nodejs自身的require方法的封装，使用它可以直接require一个目录，它会帮助你require指定目录下的
所有文件，并且返回一个与目录结构相同的对象，目录中被require的文件名即对象的方法名。

比如在当前目录下的dir文件夹的结构如下：

```
					  |-- inner2 -- d.json
		 |-- inner -- |
		 |            |-- e.js
		 |-- a.js
 dir --  |-- b.js
         |-- c.json
```

```js
var dr = require('dir-requirer')(__dirname);
var myDir = dr('./dir');
myDir.inner.e; //e.js中exports出的对象,相当于myDir.inner.e = require('./dir/inner/e');
cJson = myDir.c;//也可以调用json文件
```

## 安装

### 通过NPM即可安装使用:

```bash
$ npm install dir-requirer
```

### 调用:

```js
var dr = require('dir-requirer')(__dirname);
```

## 使用

比如在当前目录下的dir文件夹的结构如下：

```
					  |-- inner2 -- d.json
		 |-- inner -- |
		 |            |-- e.js
		 |-- a.js
 dir --  |-- b.js
         |-- c.json
```

### dr(path,options)

__参数：__

* `path(String)` - 指定要导入的路径
* `options(Object)` - 可选的配置选项

__options可选属性:__

* `ext(Array)` - 只导入指定扩展名的文件，如['.json'],默认为['.js','.json','.node']
* `dirBlackList(Array)` - 不导入指定目录名下的所有文件,如['inner2']，默认为[]
* `fileBlackList(Array)` - 不导入指定文件，如['e.js'],默认为[]

### 例子：

```js
var dr = require('dir-requirer')(__dirname);
var myDir = dr('./dir');
//如果目录'./dir'不存在,myDir将为undefined
//myDir对象将会拥有与'./dir'目录相同的结构,可以直接调用 myDir.a (即a.js文件exports出的对象/方法) ,
//myDir.c , myDir.inner.e , myDir.inner.inner2.d
var myDir = dr('./dir',{ext:['.json']});
//将只会require目录下的所有json文件,如 myDir.inner.inner2.d , myDir.c
var myDir = dr('./dir',{dirBlackList:['inner2']});
//将不会require在inner2目录下的所有文件(包括子目录)
var myDir = dr('./dir',{dirBlackList:['inner'],fileBlackList:['c.json']});
//将不会require在inner目录下的所有文件(包括子目录),以及名为c.json的单独文件
```

## 源码
https://github.com/DavidCai1993/dir-requirer

  [1]: https://github.com/DavidCai1993/dir-requirer

