## 前言

今天闲来时看了看ES7中的新标准之一，装饰器（Decorator）。过程中忽觉它和`Java`中的注解有一些类似之处，并且当前版本的`TypeScript`中已经支持它了，所以，就动手在一个Web应用Demo中尝鲜初体验了一番。

（装饰器中文简介：[这里][1]）

最终效果：

```ts
// UserController.ts
'use strict'
import {router, log, validateQuery} from './decorators'
import {IContext} from 'koa'

export class UserController {
  @router({
    method: 'get',
    path: '/user/login'
  })
  @validateQuery('username', 'string')
  @log
  login(ctx: IContext, next: Function) {
    ctx.body = 'login!'
  }

  @router({
    method: 'get',
    path: '/user/logout'
  })
  logout(ctx: IContext, next: Function) {
    ctx.body = 'logout!'
  }
}
```

## 实现

### `router`装饰器

#### 包个外壳

由于我们需要一个集中存储和挂载这些被装饰的路由的地方。所以，我们先来给`koa`包个外壳：

```ts
// Cover.ts
'use strict'
import * as Koa from 'koa'
const router = require('koa-router')()

class Cover {
  static __DecoratedRouters: Map<{target: any, method: string, path: string}, Function | Function[]> = new Map()
  private router: any
  private app: Koa

  constructor() {
    this.app = new Koa()
    this.router = router
    this.app.on('error', (err) => {
      if (err.status && err.status < 500) return
      console.error(err)
    })
  }

  registerRouters() {
    // ...
  }

  listen(port: number) {
    this.app.listen(port)
  }
}

export default Cover
```

其中，`__DecoratedRouters`是我们存储被修饰后的路由的地方，而`registerRouters`则是真实挂载它们的方法。

#### 实现装饰器

现在实现下装饰器，来把路由信息和处理函数保存起来：

```ts
// decorators.ts
'use strict'
import Cover from './Cover'
import {IContext} from 'koa'

export function router (config: {path: string, method: string}) {
  return (target: any, name: string, value: PropertyDescriptor) => {
    Cover.__DecoratedRouters({
      target: target,
      path: config.path,
      method: config.method
    }, target[name])
  }
}
```

感觉`TypeScript`中的类型已经把代码解释得差不多了...

#### 挂载

最后实现一下把所有存起来的路由挂载上的方法，就大功告成了：

```ts
// Cover.ts
'use strict'
import * as Koa from 'koa'
const router = require('koa-router')()

class Cover {
  // ...

  registerRouters() {
    for (let [config, controller] of Cover.__DecoratedRouters) {
      let controllers = Array.isArray(controller) ? controller : [controller]
      controllers.forEach((controller) => this.router[config.method](config.path, controller))
    }
    this.app.use(this.router.routes())
    this.app.use(this.router.allowedMethods())
  }

  // ...
}

export default Cover

// UserController.ts
'use strict'
import {router} from './decorators'
import {IContext} from 'koa'

export class UserController {
  @router({
    method: 'get',
    path: '/user/login'
  })
  login(ctx: IContext, next: Function) {
    ctx.body = 'login!'
  }

  @router({
    method: 'get',
    path: '/user/logout'
  })
  logout(ctx: IContext, next: Function) {
    ctx.body = 'logout!'
  }
}
```

用起来：

```ts
// app.ts
'use strict'
import Cover from './Cover'
export * from './UserController'

const app = new Cover()
app.registerRouters()

app.listen(3000)
```

写第三行代码：`export * from './UserController'` 的意图为空执行一下该模块内的代码（可否有更优雅的办法？）。

### 普通的koa中间件装饰器

普通的koa中间件装饰器则更为简单，不需额外的存储挂载过程，直接定义就好，以下为两个简单的中间件装饰器：

```ts
// decorators.ts
'use strict'
import Cover from './Cover'
import {IContext} from 'koa'

export function validateQuery (name, type) {
  return (target: any, name: string, value: PropertyDescriptor) => {
    if (!Array.isArray(target[name])) target[name] = [target[name]]
    target[name].splice(target[name].length - 1, 0, validate)
  }

  async function validate (ctx: IContext, next: Function) {
    if (typeof ctx.query[name] !== type) ctx.throw(400, `${name}'s type should be ${type}'`)
    await next()
  }
}

export function log (target: any, name: string, value: PropertyDescriptor) {
  if (!Array.isArray(target[name])) target[name] = [target[name]]
  target[name].splice(target[name].length - 1, 0, middleware)

  async function middleware (ctx: IContext, next: Function) {
    let start = Date.now()
    ctx.state.log = {
      path: ctx.path
    }

    try {
      await next()
    } catch (err) {
      if (err.status && err.status < 500) {
        Object.assign(ctx.state.log, {
          time: Date.now() - start,
          status: err.status,
          message: err.message
        })
        console.log(ctx.state.log)
      }
      throw err
    }

    let onEnd = done.bind(ctx)

    ctx.res.once('finish', onEnd)
    ctx.res.once('close', onEnd)

    function done () {
      ctx.res.removeListener('finish', onEnd)
      ctx.res.removeListener('close', onEnd)

      Object.assign(ctx.state.log, {
        time: Date.now() - start,
        status: ctx.status
      })
      console.log(ctx.state.log)
    }
  }
}
```

装饰上：

```ts
// UserController.ts
'use strict'
import {router, log, validateQuery} from './decorators'
import {IContext} from 'koa'

export class UserController {
  @router({
    method: 'get',
    path: '/user/login'
  })
  @validateQuery('username', 'string')
  @log
  login(ctx: IContext, next: Function) {
    ctx.body = 'login!'
  }

  // ...
}

```

一个需要注意的地方是，中间的经过顺序是**由下至上**的，故上面的例子中，会先进入`log`中间件，然后是`validateQuery`。

## 最后

以上例子仅是初体验时写的Demo代码，部分地方可能略有粗糙。另外，由于装饰器目前还是ES7中的一个提案，其中具体细节可能还会更改。个人感觉来说，它的确可以帮助代码在某种程度上更为简洁清晰。不过，由于它可以通过`target`参数直接取得被修饰类本身，在`TypeScript`中可能还好，若在`JavaScript`里，如果大量混合使用各种第三方装饰器，一个类是否可能会被改的面目全非？最佳实践可能还有待大家的一同探索。


  [1]: http://es6.ruanyifeng.com/#docs/decorator
