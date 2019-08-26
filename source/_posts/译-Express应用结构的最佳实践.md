---
title: '[译] Express 应用结构的最佳实践'
date: 2015-11-19 13:45:58
tags:
---

## 前言

`Node`和`Express`并不严格要求它的应用的文件结构。你可以以任意的结构来阻止你的web应用。这对于小应用来说，通常是不错的，十分易于学习和实验。

但是，当你的应用在体积和复杂性上都变得越来越高时，情况就变得复杂了。你的代码可能会变得凌乱。当你的团队人数增加时，向在同一个代码库内写代码变得愈发困难，每次合并代码时都可能会出现各种各样的冲突。为应用增加新的特性和处理新的情况可能都会改变文件的结构。

一个好的文件结构，应该是每一个不同的文件或文件夹，都分别负责处理不同的任务。这样，在添加新特性时才会变得不会有冲突。
<!-- more -->
## 最佳实践

这里所推荐的结构是基于MVC设计模式的。这个模式在职责分离方面做得非常好，所以让你的代码更具有可维护性。在这里我们不会去过多地讨论MVC的优点，而是更多地讨论如果使用它来建立你的`Express`应用的文件结构。

例子：

让我们来看下面这个例子。这是一个用户可以登录，注册，留下评论的应用。以下是他的文件结构。

```
project/
  controllers/
    comments.js
    index.js
    users.js
  helpers/
    dates.js
  middlewares/
    auth.js
    users.js
  models/
    comment.js
    user.js
  public/
    libs/
    css/
    img/
  views/
    comments/
      comment.jade
    users/
    index.jade
  tests/
    controllers/
    models/
      comment.js
    middlewares/
    integration/
    ui/
  .gitignore
  app.js
  package.json
```


这看上去可能有点复杂，但不要担心。在读完这篇文章之后，你将会完完全全地理解它。它本质上是十分简单的。

以下是对这个应用中的根文件(夹)的作用的简介：

 - controllers/ – 定义你应用的路由和它们的逻辑
 - helpers/ – 可以被应用的其他部分所共享的代码和功能
 - middlewares/ – 处理请求的`Express`中间件
 - models/ – 代表了实现了业务逻辑的数据
 - public/ – 包含了如图片，样式，`javascript`这样的静态文件
 - views/ – 提供了供路由渲染的页面模板
 - tests/ – 用于测试其他文件夹的代码
 - app.js – 初始化你的应用，并将所以部分联接在一起
 - package.json – 记录你的应用的依赖库以及它们的版本

需要提醒的是，除了文件的结构本身，它们所代表的职责也是十分重要的。

### Models

你应该在`modules`中处理与数据库的交互，里面的文件包含了处理数据所有方法。它们不仅提供了对数据的增，删，改，查方法，还提供了额外的业务逻辑。例如，如果你有一个汽车`model`，它也应该包含一个`mountTyres`方法。

对于数据库中的每一类数据，你都至少应该创建一个对应的文件。对应到我们的例子里，有用户以及评论，所以我们至少要有一个`user model`和一个`comment model`。当一个`model`变得过于臃肿时，基于它的内部逻辑将它拆分成多个不同的文件通常是一个更好的做法。


你应该保持你的各个`model`之间保持相对独立，它们应相互不知道对方的存在，也不应引用对方。它们也不需要知道`controllers`的存在，也永远不要接受HTTP请求和响应对象，和返回HTTP错误，但是，我们可以返回特定的`model`错误。

这些都会使你的`model`变得更容易维护。由于它们之间相互没有依赖，所以也容易进行测试，对其中一个`model`进行改变也不会影响到其他`model`。

以下是我们的评论`model`：

```js
var db = require('../db')

// Create new comment in your database and return its id
exports.create = function(user, text, cb) {
  var comment = {
    user: user,
    text: text,
    date: new Date().toString()
  }

  db.save(comment, cb)
}

// Get a particular comment
exports.get = function(id, cb) {
  db.fetch({id:id}, function(err, docs) {
    if (err) return cb(err)
    cb(null, docs[0])
  })
}

// Get all comments
exports.all = function(cb) {
  db.fetch({}, cb)
}

// Get all comments by a particular user
exports.allByUser = function(user, cb) {
  db.fetch({user: user}, cb)
}
```

它并不引用用户`model`。它仅仅需要一个提供用户信息的`user`参数，可能包含用户ID或用户名。评论`model`并不关心它到底是什么，它只关心这可以被存储。

```js
var db = require('../db')
  , crypto = require('crypto')

hash = function(password) {
  return crypto.createHash('sha1').update(password).digest('base64')
}

exports.create = function(name, email, password, cb) {
  var user = {
    name: name,
    email: email,
    password: hash(password),
  }

  db.save(user, cb)
}

exports.get = function(id, cb) {
  db.fetch({id:id}, function(err, docs) {
    if (err) return cb(err)
    cb(null, docs[0])
  })
}

exports.authenticate = function(email, password) {
  db.fetch({email:email}, function(err, docs) {
    if (err) return cb(err)
    if (docs.length === 0) return cb()

    user = docs[0]

    if (user.password === hash(password)) {
      cb(null, docs[0])
    } else {
      cb()
    }
  })
}

exports.changePassword = function(id, password, cb) {
  db.update({id:id}, {password: hash(password)}, function(err, affected) {
    if (err) return cb(err)
    cb(null, affected > 0)
  })
}
```

除了创建和管理用户的方法，用户的`model`还应该提供身份验证和密码管理的方法。再次重申，这些`model`之间必须相互不知道对方的存在。

### Views

这个文件夹内包含了所有你的应用需要渲染的模板，通常都是由你团队内的设计师设计的。

当选择模板语言时，你可能会有些困难，因为当下可选择的模板语言太多了。我最喜欢的两个模板语言是`Jade`和`Mustache`。`Jade`非常擅于生成`HTML`，它相对于`HTML`更简短以及更可读。它对`JavaScript`的条件和迭代语法也有强大的支持。`Mustache`则完全相反，它更专注于模板渲染，而不是很关心逻辑操作。

写一个模板的最佳实践是，不要在模板中处理数据。如果你需要在模板中展示处理后的数据，你应该在`controller`处理它们。同样地，多余的逻辑操作也应该被移到`controller`中。

```jade
doctype html
html
  head
    title Your comment web app
  body
    h1 Welcome and leave your comment
    each comment in comments
      article.Comment
        .Comment-date= comment.date
        .Comment-text= comment.text
```
### Controllers

在这个文件夹里的是所有你定义的路由。它们处理web请求，处理数据，渲染模板，然后将其返回给用户。它们是你的应用中的其他部分的粘合剂。

通常情况下，你应该至少为你应用的每一个逻辑部分写一个路由。例如，一个路由来处理评论，另一个路由来处理用户，等等。同一类的路由最好有相同的前缀，如`/comments/all`，`/comments/new`。

有时，什么代码该写进`controller`，什么代码该写进`model`是容易混淆的。最佳的实践是，永远不要在`controller`里直接调用数据库，应该使用`model`提供方法来代替之。例如，如果你有一个汽车`model`，然后想要在某辆车上安上四个轮子，你应该直接调用`db.update(id, {wheels: 4})`，而是应该调用类似`car.mountWheels(id, 4)`这样的`model`方法。

以下是关于评论的`controller`代码：

```js
var express = require('express')
  , router = express.Router()
  , Comment = require('../models/comment')
  , auth = require('../middlewares/auth')

router.post('/', auth, function(req, res) {
  user = req.user.id
  text = req.body.text

  Comment.create(user, text, function (err, comment) {
    res.redirect('/')
  })
})

router.get('/:id', function(req, res) {
  Comment.get(req.params.id, function (err, comment) {
    res.render('comments/comment', {comment: comment})
  })
})

module.exports = router
```

通常在`controller`文件夹中，有一个`index.js`。它用来加载其他的`controller`，并且定义一些没有常规前缀的路由，如首页路由：

```js
var express = require('express')
  , router = express.Router()
  , Comment = require('../models/comment')

router.use('/comments', require('./comments'))
router.use('/users', require('./users'))

router.get('/', function(req, res) {
  Comments.all(function(err, comments) {
    res.render('index', {comments: comments})
  })
})

module.exports = router
```

这个文件的`router`加载了你的所有路由。所以你的应用在启动时，只需要引用它既可。

### Middlewares

所有的`Express`中间件都会保存在这个文件夹中。中间件存在的目的，就是提取出一些`controller`中，处理请求和响应对象的共有的代码。

和`controller`一样，一个`middleware`也不应该直接调用数据库方法。而应使用`model`方法。

以下例子是`middlewares/users.js`，它用来在请求时加载用户信息。


```js
User = require('../models/user')

module.exports = function(req, res, next) {
  if (req.session && req.session.user) {
    User.get(req.session.user, function(err, user) {
      if (user) {
        req.user = user
      } else {
        delete req.user
        delete req.session.user
      }

      next()
    })
  } else {
    next()
  }
}
```

这个`middleware`使用了用户`model`，而不是直接操作数据库。

下面，是一个身份认证中间件。通过它来阻止未认证的用户进入某些路由：

```js
module.exports = function(req, res, next) {
  if (req.user) {
    next()
  } else {
    res.status(401).end()
  }
}
```

它没有任何外部依赖。如果你看了上文`controller`中的例子，你一定已经明白它是如何运作的。

### Helpers

这个文件夹中包含一些实用的工具方法，被用于`model`,`middleware`或`controller`中。通常对于不同的任务，这些工具方法会保存在不同的文件中。

### Public

这个文件只用于存放静态文件。通常是`css`， 图片，JS库（如`jQuery`）。提供静态文件的最佳实践是使用`Nginx`或`Apache`作为静态文件服务器，在这方面，它们通常比`Node`更出色。

### Tests

所有的项目都需要有测试，你需要将所有的测试代码放在一个地方。为了方便管理，你可能需要将这些测试代码放于几个不同的子文件夹中。

- controllers
- helpers
- models
- middleware
- integration
- ui

`controllers`，`helpers`，`models`和`middlewares`都十分清晰。这些文件夹里的文件都应该与源被测试的文件夹中的文件一一对应，且名字相同。这样更易于维护。

在上面这四个文件夹中，主要的测试代码将是单元测试，这意味着你需要将被测试的代码与应用分离开来。但是，`integration`文件夹内的代码则主要用来测试你的各部分代码是否被正确得粘合。例如，是否在正确的地方，调用了正确的中间件。这些代码通常会比单元测试更慢一些。

`ui`文件夹内包含了则是UI测试，它与`integration`文件夹内的测试代码相似，因为它们的目标都是保证各个部分被正确地粘合。但是，UI测试通常运行在浏览器上，并且还需要模拟用户的操作。所以，通常它比集成测试更慢。

在前四个文件夹的测试代码，通常都需要尽量多包含各种边际情况。而集成测试则不必那么细致，你只需保证功能的正确性。UI测试也一样，它也只需要保证每一个UI组件都正确工作即可。

### Other files

还剩下`app.js`和`package.json`这两个文件。

`app.js`是你应用的起始点。它加载其他的一切，然后开始接收用户的请求。

```js
var express = require('express')
  , app = express()

app.engine('jade', require('jade').__express)
app.set('view engine', 'jade')

app.use(express.static(__dirname + '/public'))
app.use(require('./middlewares/users'))
app.use(require('./controllers'))

app.listen(3000, function() {
  console.log('Listening on port 3000...')
})
```

`package.son`文件的主要目的，则是记录你的应用的各个依赖库，以及它们的版本号。

```son
{
  "name": "Comments App",
  "version": "1.0.0",
  "description": "Comments for everyone.",
  "main": "app.js",
  "scripts": {
    "start": "node app.js",
    "test": "node_modules/.bin/mocha tests/**"
  },
  "keywords": [
    "comments",
    "users",
    "node",
    "express",
    "structure"
  ],
  "author": "Terlici Ltd.",
  "license": "MIT",
  "dependencies": {
    "express": "^4.9.5",
    "jade": "^1.7.0"
  },
  "devDependencies": {
    "mocha": "^1.21.4",
    "should": "^4.0.4"
  }
}
```

你的应用也可以通过正确地配置`package.json`，然后使用`npm start`和`nam test`来启动和测试你的代码。详情参阅：http://browsenpm.org/package.json

## 最后

原文链接：https://www.terlici.com/2014/08/25/best-practices-express-structure.html

