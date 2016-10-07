---
title: '[译] 初窥 Express 5'
date: 2015-10-22 13:44:02
tags:
---

## 前言

`Express` 5.0 仍处于`alpha`版中，但是我们还是想先来初窥一下新的`express`版本中将会有哪些改变，以及如何将你的应用从`Express` 4 迁移至 `Express` 5。

`Express` 5 与`Express` 4 的区别，并有像之前从`Express` 3 更新至 `Express` 4 时的那样非常巨大。但是，仍然还是有几个API有了颠覆性的变化。这意味着你的`Express` 4 应用在更新至`Express` 5 之后，将有可能不能运行。

## 安装

想要使用`alpha`版的`Express` 5 ，你只需在你应用的根目录下运行命令：

```SHELL
$ npm install express@5.0.0-alpha.2 --save
```

完成了以上步骤之后，你便可以运行你项目中的自动化测试，来看看有哪些代码运行失败了，然后根据下文列出的`Express` 5 的更新清单，来修复它们。（你的代码应该是有写测试的吧。。）接着，根据测试的错误信息，来实际运行你的应用，看看到底是发生了什么错误。这些错误应该都是使用了`Express` 5不再支持的属性和方法所导致的。

## `Express` 5 的改变

以下是`Express` 5 的改变清单。当然，由于目前它还在一个`alpha`版，所以可能会有更多的变化。

### 被移除的方法和属性：

 - `app.del()`
 - `app.param(fn)`

#### 被改变为复数形式的方法名：

以下这些方法名被更改为了复数形式。在`Express` 4 中，使用单数的方法名将会得到一个警告。而`Express` 5 则不再支持它们了：

 - `req.acceptsCharset()` -> `req.acceptsCharsets()`.
 - `req.acceptsEncoding()` -> `req.acceptsEncodings()`.
 - `req.acceptsLanguage()` -> `req.acceptsLanguages()`.

#### `app.param(name, fn)`中`name`的前置冒号（`:`）

`app.param(name, fn)`中`name`的前置冒号是为了向前兼容`Express` 3。在`Express` 4 中，使用前置了冒号的`name`会得到一个警告。而在`Express` 5 中，将会默默得**忽略**它，然后使用没有前置冒号的`name`。

如果你遵循的是`Express` 4的文档，这个改变不应该影响到你的应用。

#### req.param(name)

这个方法的方法名非常具有歧义，并且在获取已经被删除的数据时可能会有危险，所以它被移除了。你将必须从`req.params`，`req.body`或`req.query`来明确地获取指定数据。

#### res.json(obj, status)

`Express` 5 将不再支持方法`res.json(obj, status)`。取而代之的是，你可以通过`status`方法链式调用它，如：`res.status(status).json(obj)`。

#### res.jsonp(obj, status)

`Express` 5 将不再支持方法`res.jsonp(obj, status)`。取而代之的是，你可以通过`status`方法链式调用它，如：`res.status(status).jsonp(obj)`。


#### res.send(body, status)

`Express` 5 将不再支持方法`res.send(obj, status)`。取而代之的是，你可以通过`status`方法链式调用它，如：`res.status(status).send(obj)`。

#### res.send(status)

`Express` 5 将不再支持`status`参数是数字的`res.send(status)`方法。取而代之的是，你可以使用`res.sendStatus(status)`，它将会设置一个指定的HTTP响应码以及文字描述，如`“Not Found”`，`“Internal Server Error”`等等。

如果你需要向`res.send()`传递一个数字，那就给这个数字用引号包围，来将其转换为一个字符串，然后`Express` 5 将不会认为你在使用旧的不再支持的方法。

#### res.sendfile()

在`Express` 5 中，`res.sendfile()`被它的驼峰命名版本`res.sendFile()`所取代。

### 有所改变的方法和属性：

#### `app.router`

`app.router`对象在`Express` 4中被移除了，但是在`Express` 5 中，它有回归了。但是它与`Express` 3 中的不同，它只是一个对基本的`Express` `router`对象的引用，在你的应用中，你不许要显式的加载它。

#### req.host

在`Express` 4中，`req.host`中会删去端口号，而在`Express` 5 中，端口号会被保留。

#### req.query

在`Express` 4.7和`Express` 5 中，`query parser`接受`false`参数来禁用默认的查询字符串解释。然后你可以使用自己的查询字符串解释逻辑代替之。

### 有所改进的方法：

#### res.render()

对于所有的模板引擎，这个方法现在都会强制去使用它异步版本的编译方法，来避免在使用支持同步编译的模板引擎中可能会出现的bug。

## 结论

我们已经给了`Express` 5 中的所有改变的一个预览，以及升级你的应用的大致路径。但是由于它还处于一个`alpha`阶段，所以未来可能会有更多的变化。请保持关注`StrongLoop`。

## 原文链接

https://strongloop.com/strongblog/moving-toward-express-5/
