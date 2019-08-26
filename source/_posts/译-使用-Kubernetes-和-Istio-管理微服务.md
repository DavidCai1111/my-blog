---
title: "[译] 使用 Kubernetes 和 Istio 管理微服务"
date: 2018-10-23 15:00:46
tags:
---
![cover](https://cdn-images-1.medium.com/max/1600/1*68w2bcWP94mzs2m8Fl1Hkg.png)

当一个分布式的微服务架构不断地变得庞大和复杂之后，理解和管理服务之间的网络调用变得越来越艰难。然而，服务的监控、A/B 测试、金丝雀发布、访问控制、端到端认证等等又都是一些常见的必须的要求。”服务网格（service mesh）“这个概念，便是用来描述一个微服务之间的网络层，并用于解决这些问题。

这篇文章会先给予服务网格一个简略的概述，然后用一个 Kubernetes 和 Istio 的简单应用来展示如果使用它来管理流量，注入错误（inject faults）和监控服务。

## 服务网格概述

一个服务网格就是在服务的请求/响应之上的一个通信层（communication layer），用于提供一些保证服务健康的功能：

- 零信任安全模型（zero-trust security），用于保证服务间通信的安全
- 链路追踪，用于展示服务之间的通信状态。
- 错误容忍和注入，用于试验和论证应用的可用性。
- 高级路由，用于执行 A/B 测试，版本切换等需求。

一个服务网格可能存在于 Kubernetes 集群中的好几个地方：
- 作为一个依赖包存在于微服务应用的代码中。
- 作为一个 Node Agent 或 Deamon 存在于 Kubernetes 的节点中。
- 作为一个附属容器（Sidecar container）和应用容器跑在同一个 pod 里。
<!-- more -->
### 作为一个依赖包

![Libray](https://cdn-images-1.medium.com/max/1600/0*ECgnnMHDYXVpQ7Lt.png)

在这种实现下，每一个微服务应用都会引入一个实现了服务网格功能的依赖包（比如 [Hystrix](https://github.com/Netflix/Hystrix) 和 [Ribbon](https://github.com/Netflix/ribbon)）。

这种实现的一个好处便是由于代码是真实运行在微服务的容器中的，执行服务网格功能的资源分配是由操作系统分配的。另一个好处是服务网格并不需要了解底层的基础设施，例如，一个容器的运行并不需要知道底层服务器的细节。

这种实现的一个主要缺陷是如果要支持各种编程语音的微服务，这个依赖包要使用各种编程语言被实现好多次，同一套功能逻辑被反复重复实现。

### 作为 Kubernetes 节点的 Node Agent

![Node Agent](https://cdn-images-1.medium.com/max/1600/0*mcZu_HmF_uWZ9hyx.png)

在这种实现下，每一个 Kubernetes 节点上都会运行一个独立的 Node Agent ，这种实现和 Kubernetes 集群中每一个节点都会存在一个默认的 kube-proxy 很类似。

这种实现可以忽略下层各种微服务具体实现的编程语言，释放了很多重复劳动的生产力。

与依赖包的实现相反，这种实现需要和底层的基础设施合作。应用需要将它们的网络代理到 Agent 中。

### 作为一个附属容器

![Sidecar](https://cdn-images-1.medium.com/max/1600/0*vAcAGsmZnzMPHX8X.png)

在这种实现下，每一个应用容器的 pod 内，都会被部署上一个附属容器，这个附属容器会负责处理应用容器的所有网络流量。这个模型正是 Istio 正在使用的。这种实现更像是基于前两种实现优缺点的中庸方案，比如，部署附属容器不需要在每个 Kubernetes 节点中部署 Node Agent（因此也需要和底层的基础设施合作）。但是，你会需要在集群中运行多份同样的容器。

所以这种实现的缺点是相比以上两种方案，又能会有些许计算资源的重复浪费。不过因为 应用-附属容器 通信相比 应用-节点代理 通信要简单的多，并且这种方案更容易无缝的集成进现有的集群中，所以这些缺点在一定程度上可以被妥协。

## Istio 的功能和架构

Istio 提供一下一些跨服务网络的核心功能：

### 流量管理

提供了路由规则，重试，熔断，错误注入等流量管理功能。也支持服务级别的配置，如基于百分比流量的 A/B 测试，金丝雀发布，状态回滚。

### 安全

提供基于身份（identity）的服务至服务通信加密。

### 监控

自动收集性能指标，日志，记录服务调用链路，以及集群入口和出口的流量。

### 跨容器治理平台

Istio 目前支持部署在 Kubernetes，Consul 和个人虚拟机上。

## 架构

![Arch](https://cdn-images-1.medium.com/max/1600/0*ejwHOXB2s157YzJE.png)

一个 Istio 服务网格在逻辑上可以被分为数据部分和控制部分：

- 数据部分（data plane）由一系列的作为附属容器的智能代理组成（[Envoy Proxy](https://github.com/envoyproxy/envoy)）。这些代理根据中继并控制所有微服务之间的网络通信。

- 控制部分（control plane）用于管理和配置微服务间的流量路由规则。
  - 飞行员组件（Pilot）为 Envoy 附属容器提供服务发现功能，并且把配置的路由规则转换成 Envoy 内部可识别的配置。
  - 城堡组件（Citadel）提供服务至服务和服务至用户的安全认证。
  - 收集器组件（Mixer）用来从智能代理中收集流量特征和性能指标。

## 一个基于 Kubernetes + Istio 服务网格的例子

要体验一下基于 Kubernetes + Istio 服务网格的例子，可以使用官方的 [书籍信息应用](https://istio.io/docs/examples/bookinfo/) 。将其部署在 Kubernetes 集群中，然后使用 Istio 来进行流量控制和错误注入。首先需要下载 Istio ：

```
curl -L https://git.io/getLatestIstio | sh -
cd istio-1.0.2
export PATH=$PWD/bin:$PATH
```

然后将其安装在 Kubernetes 里（简单起见，没有开启 TLS 认证）：

```
kubectl apply -f install/kubernetes/helm/istio/templates/crds.yaml
kubectl apply -f install/kubernetes/istio-demo.yaml
```

这会在一个名叫 ”istio-system“ 的 kubernetes 命名空间下创建一系列的 kubernetes services 和 kubernetes pods 。

这个[书籍信息应用](https://istio.io/docs/examples/bookinfo/) 包含以下四个微服务：
- 产品主页服务：调用书本细节服务和书本评价服务，用于页面展示。
- 书本细节服务：保存书籍详细信息。
- 书本评论服务：保存书籍的评论。它也会调用书本打分服务（v1 版本不会调用打分服务，v2 会调用打分服务并且展示黑色星星，v3 也会调用打分服务并且展示红色星星）。
- 书本打分服务：保存书本评论服务所需要的打分信息。

![Book](https://cdn-images-1.medium.com/max/1600/0*MPpWvrnDxc4mH2Fo.png)

启动对应应用的容器：

```
# 为 default 命名空间添加 istio-injection=enabled 标记来开启附属容器自动注入
kubectl label namespace default istio-injection=enabled

# 部署应用
kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml

# 定义不同版本应用的路由规则
kubectl apply -f samples/bookinfo/networking/destination-rule-all.yaml
```

然后打开浏览器，将 URL 设置为应用的主页 URL ，可以看到一个包含书籍信息的页面，每一次刷新都会展示不同的书籍（并且同时包含了 v1 v2 v3 的书本打分服务）：

![Main Page 1](https://cdn-images-1.medium.com/max/1600/0*o54uwoV4pEoxnsHX.png)

![Main Page 2](https://cdn-images-1.medium.com/max/1600/0*TVMidNgqHDnwmtom.png)

![Main Page 3](https://cdn-images-1.medium.com/max/1600/0*AMZ9MfmqrDLZujeu.png)

### 配置请求路由

为了将请求到路由到同一个版本的服务，需要为微服务配置一个 VirtualService 资源，并在里面指定默认版本：

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: ratings
spec:
  hosts:
  - ratings
  http:
  - route:
     - destination:
host: ratings
subset: v1
```

然后创建该资源：

```
kubectl apply -f samples/bookinfo/networking/virtual-service-all-v1.yaml
```

现在，由于所有的请求都被指向了默认的 v1 书本评论服务，所以所有展示都没有了星星。

接下来，我们为指定的用户配置指定的微服务版本：

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
name: reviews
spec:
hosts:
  - reviews
http:
- match:
  - headers:
      end-user:
      exact: jason
route:
- destination:
    host: reviews
    subset: v2
- route:
- destination:
    host: reviews
    subset: v1
```

因为产品主页服务会在请求书本评论服务时自动添加 end-user 请求头，所以是成立的。

当以 jason 用户的身份登录时，我们能看到评论中有了黑色星星：

![Black Star 3](https://cdn-images-1.medium.com/max/1600/0*WIrZV3KgaQVxma_o.png)

总结一下，我们首先把 100% 的流量路由到了 v1 版本的书本评论中，然后又选择性地把以 jason 用户身份登录的请求路由到了 v2 版本的书本评论中。

### 错误注入

如果想测试微服务的弹性延迟（resiliency delays）和不可用的场景的话，我们可以通过错误注入来模拟一个逻辑错误或过载的微服务。在我们的例子里，我们将会为以 jason 身份登录的请求注入一个 7 秒的延迟：

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: ratings
spec:
  hosts:
- ratings
  http:
    - match:
      - headers:
          end-user:
            exact: jason
    fault:
      delay:
        percent: 100
        fixedDelay: 7s
    route:
    - destination:
        host: ratings
        subset: v1
  - route:
    - destination:
       host: ratings
       subset: v1
```

现在我们希望的情况是以 7 秒左右的时间打开主页，然后没有任何的报错。但是，我们发现评论区出现了一个报错信息。

这是书本评论页面的错误处理机制有问题，书本评论页面过早的超时并抛出了错误。

所以在这个错误注入的场景下，它帮助我们发现了一个微服务的问题，并且让我们可以在不影响用户的情况下解决它。

### 流量分发

在修复了问题之后，我们希望让一部分用户先体验我们新版本的服务。

首先，我们把 50% 的流量分发到 v3 的书本评论服务中：

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: reviews
spec:
  hosts:
    - reviews
  http:
  - route:
    - destination:
        host: reviews
        subset: v1
      weight: 50
    - destination:
        host: reviews
        subset: v3
      weight: 50
```

待经过一段时间的观察之后，我们就可以将流量全量的分发至 v3 的书本评论服务中了。

### 收集性能指标并展示

Istio 的 Mixer 组件提供了多种基础设施的后端组件用来收集性能指标，比如 [Prometheus](https://prometheus.io/) ,[Datadog](https://www.datadoghq.com/) 和 [Fluentd](https://www.fluentd.org/)。

可以使用 [Servicegraph](https://github.com/istio/istio/tree/release-1.0/addons/servicegraph) 插件来使调用链路数据可视化：

![Trace](https://cdn-images-1.medium.com/max/1600/0*oHvPb2ncYTeK64fp.png)

可以使用 [Grafana](https://grafana.com/) 来使性能指标可视化在一个看板上：

![Grafana Dashboard](https://cdn-images-1.medium.com/max/1600/0*5m50-D3MEWZ1eJIM.png)

### 安全


Istio 支持多种服务到服务和服务到终端用户的认证机制，既支持 RBAC 也提供了审计工具。这些话题的讨论超过了本文的范畴，如果想进一步了解可以参阅官方文档。

## 总结

总结一下，本文中我们描述了什么是服务网格以及如何实现它。同时也展示了如何在 Kubernetes 集群中安装 Istio 并且部署一个简单应用。在[书籍信息应用](https://istio.io/docs/examples/bookinfo/)的例子里展示了如何为不同的用户路由至不同版本的服务，另外，我们也学习了如何进行错误注入来发现微服务中潜在的问题。最后，还给出了收集性能指标和图形化展示它们的方法。

## 原文链接

https://medium.com/kreuzwerker-gmbh/managing-microservices-with-kubernetes-and-istio-76efea547b28
