## 前言
众所周知，Node.js在[child_process][1]模块中提供了`spawn`和`exec`这两个方法，用来开启子进程执行指定程序。这两个方法虽然目的一样，但是既然Node.js为我们提供了两个方法，那它们之间必然还是会有一些不同之处，下面让我们来分析一下他们的异同。

首先我们来看看`官方API文档`中对它们的说明：

### child_process.spawn(command[, args][, options])

**command String** 将要运行的命令。
**args Array** 字符串参数数组。
__options 配置对象：__

 - **cwd String** 子进程的当前工作目录。
 - **env Object** 环境变量键值对。
 - **stdio Array|String** 子进程的stdio配置。
 - **detached Boolean** 这个子进程将会变成进程组的领导。
 - **uid Number** 设置用户进程的ID。
 - **gid Number** 设置进程组的ID。

**返回值:** ChildProcess对象

利用给定的命令以及参数执行一个新的进程，如果没有参数数组，那么`args`将默认是一个空数组。

### child_process.exec(command[, options], callback)

**command String** 将要运行的命令，参数使用空格隔开。
__options 配置对象：__

 - **cwd String** 子进程的当前工作目录。
 - **env Object** 环境变量键值对。
 - **encoding String** 字符编码（默认： 'utf8'）。
 - **shell String** 将要执行命令的Shell（默认: 在`UNIX`中为`/bin/sh`， 在`Windows`中为`cmd.exe`， Shell应当能识别 `-c` 开关在`UNIX`中，或 `/s /c` 在`Windows`中。 在`Windows`中，命令行解析应当能兼容`cmd.exe`）。
 - **timeout Number** 超时时间（默认： 0）。
 - **maxBuffer Number** 在stdout或stderr中允许存在的最大缓冲（二进制），如果超出那么子进程将会被杀死 （默认: 200*1024）。
 - **killSignal String** 结束信号（默认：'SIGTERM'）。
 - **detached Boolean** 这个子进程将会变成进程组的领导。
 - **uid Number** 设置用户进程的ID。
 - **gid Number** 设置进程组的ID。

__callback Function 当子进程执行完毕后将会执行的回调函数，参数有：__

 - **error Error**
 - **stdout Buffer**
 - **stderr Buffer**

**返回值:** ChildProcess对象

在Shell中运行一个命令，并缓存命令的输出。

## 异同
### 从文档里可以得出的一些相同点：
1，它们都用于开一个子进程执行指定命令。

2，它们都可以自定义子进程的运行环境。

3，它们都返回一个ChildProcess对象，所以他们都可以取得子进程的标准输入流，标准输出流和标准错误流 。

### 不同点：
1，**接受参数的方式：** `spawn`使用了参数数组，而`exec`则直接接在命令后。

2，**子进程返回给Node的数据量：** `spawn`没有限制子进程可以返回给Node的数据大小，而`exec`则在`options配置对象`中有`maxBuffer`参数限制，且默认为200K，如果超出，那么子进程将会被杀死，并报错：`Error：maxBuffer exceeded`，虽然可以手动调大`maxBuffer`参数，但是并不被推荐。由此可窥见一番Node.js设置这两个API时的部分本意，`spawn`应用来运行返回大量数据的子进程，如图像处理，文件读取等。而`exec`则应用来运行只返回少量返回值的子进程，如只返回一个状态码。

3，**调用对象：** 虽然在官方文档中，两个方法接受的第一个参数标注的都是`command`，即要执行的命令，但其实不然。`spawn`接受的第一个参数为文件，而`exec`接受的第一个参数才是命令。在Node的源码中关于`spawn`的部分有如下一段：
```js
var spawn = exports.spawn = function(file, args, options)
```
而在`exec`部分则有如下一段：
```js
 if (process.platform === 'win32') {
file = 'cmd.exe';
args = ['/s', '/c', '"' + command + '"'];
// Make a shallow copy before patching so we don't clobber the user's
// options object.
options = util._extend({}, options);
options.windowsVerbatimArguments = true;
} else {
  file = '/bin/sh';
  args = ['-c', command];
}
```
所以在Windows下直接运行 `require('child_process').spawn('dir')` 会报异常说没有此文件，而使用`exec`则不会。若一定要使用`spwan`，则应写成`require('child_process').spawn('cmd.exe',['\s', '\c', 'dir'])`。


4，**回调函数：** `exec`方法相比`spawn`方法，多提供了一个回调函数，可以更便捷得获取子进程输出。这与为返回的ChildProcess对象的`stdout`或`stderr`监听`data`事件来获得输出的区别在于：`data`事件的方式，会在子进程一有数据时就触发，并把数据返回给Node。而回调函数，则会先将数据缓存在内存中（数据量小于`maxBuffer`参数），等待子进程运行完毕后，再调用回调函数，并把最终数据交给回调函数。

## 参考
http://www.hacksparrow.com/difference-between-spawn-and-exec-of-node-js-child_process.html

https://cnodejs.org/topic/507285c101d0b80148f7c538


  [1]: https://iojs.org/api/child_process.html