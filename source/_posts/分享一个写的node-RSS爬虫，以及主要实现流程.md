---
title: 分享一个写的 node RSS 爬虫，以及主要实现流程
date: 2015-05-12 13:32:51
tags:
---

前言
----------
为了更好分享和发布自己的内容，现在提供RSS服务的网站和社区非常之多，现在基于`python`，`java`等平台的RSS爬虫非常之多，所以结合node高并发特性，自己用node写了一个RSS爬虫——`rss-worker`。

代码地址：[这里][1] ， 欢迎star，欢迎follow。

简介
----------
`rss-worker`是一个持久的可配的rss爬虫。支持多URL的并行爬取，并且会将所有条目按时间顺序进行保存，保存格式为`"时间\n标题\n内容\n\n"`来供使用或分析，支持的保存方式有`fs`与`mongodb`。

结果演示
----------
一个抓取`https://github.com/alsotang.atom`，`https://cnodejs.org/rss`，`http://segmentfault.com/feeds/blogs`内容24小时的输出（2015/5/6 19:30至2015/5/7 19:30 ）：

[点这里][2]

主要流程
----------
爬取：并发地对所有指定URL使用[superagent][3]发送请求，并在所有URL全部爬取完毕后根据指定间隔再次发出爬取请求

结果更新：在内存中缓存了一个`lastUpdate`字段，与每次的爬取结果作比对

支持`fs`和`mongo`存储：利用`persistence`层提供统一接口，对外隐藏不同实现

安装使用
----------
直接通过npm：
```SHELL
npm install rss-worker --save
```

示例
----------
```js
var RssWorker = require('rss-worker');

var opt = {
  urls: ['https://cnodejs.org/rss', 'https://github.com/DavidCai1993.atom', 'http://segmentfault.com/feeds'],
  store: {
    type: 'fs',
    dist: './store/rss.txt'
  },
  timeout: 10
};

var rssWorker = new RssWorker(opt);
rssWorker.start();
```

API
----------
#### new RssWorker(options)
生成一个RssWorker的实例

__options:__

* `urls(Array)` - 必选，需要抓取的rss地址的数组
* `store(Object)` - 存储方式，需要配置`type`与`dist`两属性
  * `type` - 存储方式，可选`fs`（默认）或`mongodb`
  * `dist` - 存储结果的文件地址（将会自动创建），如：`./store/rss.txt`（fs），`mongodb://localhost:27017/rss_worker`（mongodb）
* `timeout(Number)` - 每次抓取的间隔（秒），默认为60秒

#### start()
开始抓取

#### forceToEnd()
发出停止抓取信号，将不会继续抓取，但不会影响到正在进行的本次抓取。


  [1]: https://github.com/DavidCai1993/rss-worker
  [2]: https://raw.githubusercontent.com/DavidCai1993/rss-worker/master/example/output.txt
  [3]: https://www.npmjs.com/package/superagent
