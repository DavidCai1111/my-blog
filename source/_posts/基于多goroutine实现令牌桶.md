---
title: 基于多 goroutine 实现令牌桶
date: 2016-12-07 17:31:37
tags:
  - Go
---

## 前言

[令牌桶](https://en.wikipedia.org/wiki/Token_bucket)是一种常见用于控制速率的控流算法。原理于 Wikipedia 上描述如下：

  - 每秒会有 r 个令牌被放入桶中，即每 1 / r 秒向桶中放入一个令牌。
  - 一个桶最多可以存放 b 个令牌。当令牌被放入桶时，若桶已满，则令牌被直接丢弃。
  - 当一个 n 字节的数据包抵达时，消耗 n 个令牌，然后放行之。
  - 若桶中的令牌不足 n ，则该数据包要么被缓存要么被丢弃。

下面我们便根据上述描述，使用 Go 语言，基于多 goroutine ，来实现是一个并发安全的令牌桶。后述代码的完整实现的仓库地址在：https://github.com/DavidCai1993/token-bucket 。
<!-- more -->
## 基本设计

最基本的结构便是，定义一个令牌桶 struct ，该 struct 每一个新生成的令牌桶实例，各自带有一个 goroutine ，像守护进程一样以固定时间向实例桶中放入令牌：

```go
type TokenBucket struct {
	interval          time.Duration  // 时间间隔
	ticker            *time.Ticker   // 定时器 timer
  // ...
	cap               int64          // 桶总容量
	avail             int64          // 桶内现有令牌数
}

func (tb *TokenBucket) adjustDaemon() {
	for now := range tb.ticker.C {
		var _ = now

		if tb.avail < tb.cap {
			tb.avail++
		}
	}
}

func New(interval time.Duration, cap int64) *TokenBucket {
	tb := &TokenBucket{
    // ...
	}

	go tb.adjustDaemon()

	return tb
}
```

该 struct 最终会提供以下 API ：
  - `TryTake(count int64) bool`： 尝试从桶中取出 `n` 个令牌。立刻返回，返回值表示该次取出是否成功。
  - `Take(count int64)`：尝试从桶中取出 `n` 个令牌，若当前桶中的令牌数不足，则保持等待，直至桶内令牌数量达标然后取出。
  - `TakeMaxDuration(count int64, max time.Duration) bool`：尝试从桶中取出 `n` 个令牌，若当前桶中的令牌数不足，则保持等待，直至桶内令牌数量达标然后取出。不过设置了一个超时时间 `max` ，若超时，则不再等待立刻返回，返回值表示该次取出是否成功。
  - `Wait(count int64)`：保持等待直至桶内令牌数大于等于 `n` 。
  - `WaitMaxDuration(count int64, max time.Duration) bool` 保持等待直至桶内令牌数大于等于 `n` ，但设置了一个超时时间 `max` 。

## `TryTake`： 一次性取出尝试

`TryTake(count int64) bool` 这样的一次性取出尝试，即可返回，实现起来最为简易。唯一需要注意的问题为当前我们在一个多 goroutine 环境下，令牌是我们的共享资源，为了防止[竞争条件](https://en.wikipedia.org/wiki/Race_condition)，最简单的解决方案即为存取都加上**锁**。Go 语言自带的 `sync.Mutex` 类提供了锁的实现。

```go
type TokenBucket struct {
  // ...
	tokenMutex        *sync.Mutex // 令牌锁
}

func (tb *TokenBucket) tryTake(count int64) bool {
	tb.tokenMutex.Lock() // 检查共享资源，加锁
	defer tb.tokenMutex.Unlock()

	if count <= tb.avail {
		tb.avail -= count

		return true
	}

	return false
}

func (tb *TokenBucket) adjustDaemon() {
	for now := range tb.ticker.C {
		var _ = now

    tb.tokenMutex.Lock() // 检查共享资源，加锁

		if tb.avail < tb.cap {
			tb.avail++
		}

    tb.tokenMutex.Unlock()
	}
}
```

## `Take`，`TakeMaxDuration` 等待型取出（尝试）

对于 `Take(count int64)` 和 `TakeMaxDuration(count int64, max time.Duration) bool` 这样的等待型取出（尝试），情况别就有所不同了：
  1. 由于这两个操作都是需要进行等待被通知，故原本的主动加锁检查共享资源的方案已不再适合。
  2. 由于可能存在多个正在等待的操作，为了避免混乱，我们需要有个先来后到，最早等待的操作，首先获取令牌。

我们可以使用 Go 语言提供的第二种共享多 goroutine 间共享资源的方式：channel 来解决第一个问题。channel 可以是双向的，完全符合我们需要被动通知的场景。而面对第二个问题，我们需要为等待的操作维护一个队列。这里我们使用的是 `list.List` 来模拟 FIFO 队列，不过值得留意的是，这样一来，队列本身也成了一个共享资源，我们也需要为了它，来配一把锁。

跟着上述思路，我们先来实现 `Take(count int64)` ：

```go
type TokenBucket struct {
  // ...
	waitingQuqueMutex: &sync.Mutex{}, // 等到操作的队列
	waitingQuque:      list.New(),    // 列队的锁
}

type waitingJob struct {
	ch        chan struct{}
	count     int64
}

func (tb *TokenBucket) Take(count int64) {
	w := &waitingJob{
		ch:    make(chan struct{}),
		count: count,
	}

	tb.addWaitingJob(w) // 将 w 放入列队，需为队列加锁。

	<-w.ch

	close(w.ch)
}

func (tb *TokenBucket) adjustDaemon() {
  var waitingJobNow *waitingJob

	for now := range tb.ticker.C {
		var _ = now

    tb.tokenMutex.Lock() // 检查共享资源，加锁

		if tb.avail < tb.cap {
			tb.avail++
		}

    element := tb.getFrontWaitingJob() // 取出队列头，需为队列加锁。

    if element != nil {
			if waitingJobNow == nil {
				waitingJobNow = element.Value.(*waitingJob)

				tb.removeWaitingJob(element) // 移除队列头，需为队列加锁。
			}

      if tb.avail >= waitingJobNow.need {
        tb.avail -= waitingJobNow.count
        waitingJobNow.ch <- struct{}{}

        waitingJobNow = nil
      }
		}

    tb.tokenMutex.Unlock()
	}
}
```

接着我们来实现 `TakeMaxDuration(count int64, max time.Duration) bool` ，该操作的超时部分，我们可以使用 Go 自带的 `select` 关键字结合定时器 channel 来实现。并且为 `waitingJob` 加上一个标识字段来表明该操作是否已超时被弃用。由于检查弃用的操作会在 `adjustDaemon` 中进行，而标识弃用的操作会在 `TakeMaxDuration` 内的 `select` 中，为了再次避免竞争状态，我们将使用的令牌的操作从 `adjustDaemon` 内通过 channel 返回给 `select` 中，并阻塞，来避免了竞争条件并且享受了令牌锁的保护：

```go
func (tb *TokenBucket) TakeMaxDuration(count int64, max time.Duration) bool {
	w := &waitingJob{
		ch:        make(chan struct{}),
		count:     count,
		abandoned: false, // 超时弃置标识
	}

	defer close(w.ch)

	tb.addWaitingJob(w)

	select {
	case <-w.ch:
		tb.avail -= use
		w.ch <- struct{}{}
		return true
	case <-time.After(max):
		w.abandoned = true
		return false
	}
}

func (tb *TokenBucket) adjustDaemon() {
    // ...

    if element != nil {
			if waitingJobNow == nil || waitingJobNow.abandoned {
				waitingJobNow = element.Value.(*waitingJob)

				tb.removeWaitingJob(element)
			}

			if tb.avail >= waitingJobNow.need && !waitingJobNow.abandoned {
				waitingJobNow.ch <- struct{}{}
				<-waitingJobNow.ch

				waitingJobNow = nil
			}
		}

    // ...
}
```

## 最后

最后总结一些关键点：
  - 对于共享资源的存取，要么使用锁，要么使用 channel ，视场景选择最好用的用之。
  - channel 可被动等待共享资源，而锁则使用十分简易。
  - 异步的多个等待操作，可使用队列进行协调。
  - 可以在锁的保护下，结合 channel 来对共享资源实现一个处理 pipeline ，结合两者优势，十分好用。
