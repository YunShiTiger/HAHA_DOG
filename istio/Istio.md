# Istio

使用集群:Kubernetes-1.16.2



## 安装

### 下载istio

```
https://github.com/istio/istio/releases
```

选择版本

#### 解压

```
tar -zxvf istio-1.5.1-linux.tar.gz 
```

#### 使用Curl下载最新版本

```
curl -L https://istio.io/downloadIstio | sh -
```

### 安装istio

#### 进入安装目录

```
cd istio-1.5.1
```

安装目录包含如下内容：

- `install/kubernetes` 目录下，有 Kubernetes 相关的 YAML 安装文件
- `samples/` 目录下，有示例应用程序
- `bin/` 目录下，包含 [`istioctl`](https://istio.io/zh/docs/reference/commands/istioctl) 的客户端文件。`istioctl` 工具用于手动注入 Envoy sidecar 代理。

#### 将 `istioctl` 客户端路径增加到 path 环境变量中

```
export PATH=$PWD/bin:$PATH
export PATH=$PATH:$HOME/.istioctl/bin
```

#### 命令自动补全

**注: bash-completion通常是安装好的**

```
yum install bash-completion -y
```

```
 vi ~/.bash_profile 
```

加入

```
[[ -r "/usr/local/etc/profile.d/bash_completion.sh" ]] && . "/usr/local/etc/profile.d/bash_completion.sh"
```

##### 复制`istioctl.bash`至home目录

`istioctl` 自动补全的文件位于 `tools` 目录。通过复制 `istioctl.bash` 文件到您的 home 目录，然后添加下行内容到您的 `.bashrc` 文件执行 `istioctl` tab 补全文件：

```
cp tools/istioctl.bash /root/
```

```
cp tools/istioctl.bash /home/
```

##### source

```
source ~/istioctl.bash
```

#### 安装

```
istioctl manifest apply --set addonComponents.grafana.enabled=true
```

`--set addonComponents.grafana.enabled=true`开启grafana监控

##### 验证

###### 生成清单[安装前未生成]

```
istioctl manifest generate > $HOME/generated-manifest.yaml
```

查看

```
cat /root/generated-manifest.yaml 
```

###### 验证

```
istioctl verify-install -f $HOME/generated-manifest.yaml
```

#### 将istio网关(gateway)改为NodePort

```
export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')
```

```
export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}')
```

```
kubectl edit svc istio-ingressgateway -n istio-system
```

修改`Type`为`NodePort`



## 卸载

```
istioctl manifest generate <your original installation options> | kubectl delete -f -
```



## 使用

### Bookinfo 应用示例

`Bookinfo` 应用分为四个单独的微服务：

- `productpage`. 这个微服务会调用 `details` 和 `reviews` 两个微服务，用来生成页面。
- `details`. 这个微服务中包含了书籍的信息。
- `reviews`. 这个微服务中包含了书籍相关的评论。它还会调用 `ratings` 微服务。
- `ratings`. 这个微服务中包含了由书籍评价组成的评级信息。

`reviews` 微服务有 3 个版本：

- v1 版本不会调用 `ratings` 服务。
- v2 版本会调用 `ratings` 服务，并使用 1 到 5 个黑色星形图标来显示评分信息。
- v3 版本会调用 `ratings` 服务，并使用 1 到 5 个红色星形图标来显示评分信息。

#### 启动应用服务

Istio 默认自动注入 Sidecar. 为 default 命名空间打上标签 istio-injection=enabled：

```
kubectl label namespace default istio-injection=enabled
```

##### 部署

```
kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml
```

确认 Bookinfo 应用是否正在运行

```
kubectl exec -it $(kubectl get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}') -c ratings -- curl productpage:9080/productpage | grep -o "<title>.*</title>"
```

打印

```
<title>Simple Bookstore App</title>
```

##### 创建网关和虚拟路由

```
kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml
```

#### 集群外部访问

```
curl -s 192.168.240.121:32723/productpage | grep -o "<title>.*</title>"
```

#### 应用默认目标规则

##### HTTP

```
kubectl apply -f samples/bookinfo/networking/destination-rule-all.yaml
```

##### HTTPS

```
kubectl apply -f samples/bookinfo/networking/destination-rule-all-mtls.yaml
```



### 流量管理

```
reviews:v1 带星
reviews:v2 不带星
```

```
https://istio.io/zh/docs/tasks/traffic-management/request-routing/
```

#### 配置请求路由

要仅路由到一个版本，请应用为微服务设置默认版本的 virtual service。在这种情况下，virtual service 将所有流量路由到每个微服务的 `v1` 版本。

```
kubectl apply -f samples/bookinfo/networking/virtual-service-all-v1.yaml
```

*由于配置传播是最终一致的，因此请等待几秒钟以使 virtual services 生效。*

##### 使用以下命令显示已定义的路由：

```
kubectl get virtualservices -o yaml
```

打印

```
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: details
  ...
spec:
  hosts:
  - details
  http:
  - route:
    - destination:
        host: details
        subset: v1
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: productpage
  ...
spec:
  gateways:
  - bookinfo-gateway
  - mesh
  hosts:
  - productpage
  http:
  - route:
    - destination:
        host: productpage
        subset: v1
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: ratings
  ...
spec:
  hosts:
  - ratings
  http:
  - route:
    - destination:
        host: ratings
        subset: v1
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: reviews
  ...
spec:
  hosts:
  - reviews
  http:
  - route:
    - destination:
        host: reviews
        subset: v1
---
```

使用以下命令显示相应的 `subset` 定义:

```
kubectl get destinationrules -o yaml
```

###### 验证

```
http://202.107.190.8:10385/productpage
```

#### 基于用户身份路由

更改路由配置，以便将来自特定用户的所有流量路由到特定服务版本。

*例:来自名为 Jason 的用户的所有流量将被路由到服务 `reviews:v2`*

##### 启用基于用户的路由

```
kubectl apply -f samples/bookinfo/networking/virtual-service-reviews-test-v2.yaml
```

##### 确认规则已创建

```
kubectl get virtualservice reviews -o yaml
```

打印

```
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: reviews
  ...
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

- 在 Bookinfo 应用程序的 `/productpage` 上，以用户 `jason` 身份登录。

  ```
  星级评分显示在每个评论旁边。
  因为Jason的所有用户的流量都被路由到 reviews:v2。
  ```

- 以其他用户身份登录（选择您想要的任何名称）。

  ```
  刷新浏览器后星星消失了。
  这是因为除了Jason之外，所有用户的流量都被路由到 reviews:v1。
  ```


#### 流量转移

***逐步将流量从一个版本的微服务迁移到另一个版本。也以将流量从旧版本迁移到新版本。***

*一个常见的用例是将流量从一个版本的微服务逐渐迁移到另一个版本。在 Istio 中，可以通过配置一系列规则来实现此目标， 这些规则将一定百分比的流量路由到一个或另一个服务。*

例如：可以把 50％ 的流量发送到 `reviews:v1`，另外 50％ 的流量发送到 `reviews:v3`。然后，再把 100％ 的流量发送到 `reviews:v3` 来完成迁移。

##### 应用基于权重的路由

###### 运行此命令将所有流量路由到各个微服务的 `v1` 版本。

```
kubectl apply -f samples/bookinfo/networking/virtual-service-all-v1.yaml
```

###### 把 50% 的流量从 `reviews:v1` 转移到 `reviews:v3`

```
kubectl apply -f samples/bookinfo/networking/virtual-service-reviews-50-v3.yaml
```

**等待几秒钟以让新的规则传播到代理中生效。**

验证

```
kubectl get virtualservice reviews -o yaml
```

打印

```
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: reviews
  ...
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

验证

```
刷新浏览器中的 /productpage 页面，大约有 50% 的几率会看到页面中出带 红色 星级的评价内容。这是因为 v3 版本的 reviews 访问了带星级评级的 ratings 服务，但 v1 版本却没有。
```

###### 如果 `reviews:v3` 微服务已经稳定，你可以通过应用此 virtual service 规则将 100% 的流量路由到 `reviews:v3`

```
kubectl apply -f samples/bookinfo/networking/virtual-service-reviews-v3.yaml
```

验证

```
刷新 /productpage 时，将始终看到带有红色星级评分的书评。
```

#### TCP流量转移

**应用基于权重的 TCP 路由**

##### 部署微服务 `tcp-echo` 的 `v1` 版本

###### 创建namespace

```
kubectl create namespace istio-io-tcp-traffic-shifting
```

###### 手动注入

```
kubectl apply -f <(istioctl kube-inject -f samples/tcp-echo/tcp-echo-services.yaml) -n istio-io-tcp-traffic-shifting
```

###### 自动注入

```
kubectl label namespace istio-io-tcp-traffic-shifting istio-injection=enabled
```

###### 部署

```
kubectl apply -f samples/tcp-echo/tcp-echo-services.yaml -n istio-io-tcp-traffic-shifting
```

##### 将目标为微服务 `tcp-echo` 的 TCP 流量全部路由到 `v1` 版本

```
kubectl apply -f samples/tcp-echo/tcp-echo-all-v1.yaml -n istio-io-tcp-traffic-shifting
```

##### 确认 `tcp-echo` 服务已启动并开始运行

##### 向微服务 `tcp-echo` 发送一些 TCP 流量

```
for i in {1..10}; do \
docker run -it --rm busybox sh -c "(date; sleep 1) | nc 192.168.240.121 30514"; \
done
```

打印

```
one Tue Apr 21 09:16:57 UTC 2020
one Tue Apr 21 09:16:59 UTC 2020
one Tue Apr 21 09:17:00 UTC 2020
one Tue Apr 21 09:17:02 UTC 2020
one Tue Apr 21 09:17:04 UTC 2020
one Tue Apr 21 09:17:06 UTC 2020
one Tue Apr 21 09:17:07 UTC 2020
```

*注意到，所有时间戳的前缀都是 one ，这意味着所有流量都被路由到了 tcp-echo 服务的 v1 版本。*

##### 将 20% 的流量从 `tcp-echo:v1` 转移到 `tcp-echo:v2`

```
kubectl apply -f samples/tcp-echo/tcp-echo-20-v2.yaml -n istio-io-tcp-traffic-shifting
```

验证

```
kubectl get virtualservice tcp-echo -o yaml -n istio-io-tcp-traffic-shifting
```

打印

```
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: tcp-echo
  ...
spec:
  ...
  tcp:
  - match:
    - port: 31400
    route:
    - destination:
        host: tcp-echo
        port:
          number: 9000
        subset: v1
      weight: 80
    - destination:
        host: tcp-echo
        port:
          number: 9000
        subset: v2
      weight: 20
```

##### 向微服务 `tcp-echo` 发送一些 TCP 流量

```
for i in {1..10}; do \
docker run -it --rm busybox sh -c "(date; sleep 1) | nc 192.168.240.121 30514"; \
done
```

打印

```
two Tue Apr 21 09:31:04 UTC 2020
two Tue Apr 21 09:31:06 UTC 2020
one Tue Apr 21 09:31:08 UTC 2020
one Tue Apr 21 09:31:09 UTC 2020
one Tue Apr 21 09:31:11 UTC 2020
two Tue Apr 21 09:31:13 UTC 2020
one Tue Apr 21 09:31:15 UTC 2020
one Tue Apr 21 09:31:16 UTC 2020
one Tue Apr 21 09:31:18 UTC 2020
one Tue Apr 21 09:31:20 UTC 2020
```

*有大约 20% 的流量时间戳前缀是 two ，这意味着有 80% 的 TCP 流量路由到了 tcp-echo 服务的 v1 版本，与此同时有 20% 流量路由到了 v2 版本。*

#### 故障注入

*通过执行配置请求路由任务或运行以下命令来初始化应用程序版本路由*

```
kubectl apply -f samples/bookinfo/networking/virtual-service-all-v1.yaml
kubectl apply -f samples/bookinfo/networking/virtual-service-reviews-test-v2.yaml
```

经过上面的配置，下面是请求的流程：

- `productpage` → `reviews:v2` → `ratings` (针对 `jason` 用户)
- `productpage` → `reviews:v1` (其他用户)

##### 注入 HTTP 延迟故障

```
为了测试微服务应用程序 Bookinfo 的弹性，将为用户 jason 在 reviews:v2 和 ratings 服务之间注入一个 7 秒的延迟。 这个测试将会发现一个故意引入 Bookinfo 应用程序中的 bug。

注意 reviews:v2 服务对 ratings 服务的调用具有 10 秒的硬编码连接超时。 因此，尽管引入了 7 秒的延迟，但仍然期望端到端的流程是没有任何错误的。
```

###### 创建故障注入规则以延迟来自测试用户 `jason` 的流量：

```
kubectl apply -f samples/bookinfo/networking/virtual-service-ratings-test-delay.yaml
```

确认

```
kubectl get virtualservice ratings -o yaml
```

新的规则可能需要几秒钟才能传播到所有的 pod 。

###### 测试延迟配置

1. 通过浏览器打开 [Bookinfo] 应用。

2. 使用用户 `jason` 登陆到 `/productpage` 页面。

   你期望 Bookinfo 主页在大约 7 秒钟加载完成并且没有错误。 但是，出现了一个问题：Reviews 部分显示了错误消息：

   ```plain
   Error fetching product reviews!
   Sorry, product reviews are currently unavailable for this book.
   ```

3. 查看页面的响应时间：

   1. 打开浏览器的 *开发工具* 菜单
   2. 打开 *网络* 标签
   3. 重新加载 `productpage` 页面。你会看到页面加载实际上用了大约 6s。

###### 注解

```
你发现了一个 bug。微服务中有硬编码超时，导致 reviews 服务失败。

按照预期，我们引入的 7 秒延迟不会影响到 reviews 服务，因为 reviews 和 ratings 服务间的超时被硬编码为 10 秒。 但是，在 productpage 和 reviews 服务之间也有一个 3 秒的硬编码的超时，再加 1 次重试，一共 6 秒。 结果，productpage 对 reviews 的调用在 6 秒后提前超时并抛出错误了。

这种类型的错误可能发生在典型的由不同的团队独立开发不同的微服务的企业应用程序中。 Istio 的故障注入规则可以帮助您识别此类异常，而不会影响最终用户。
```

**此次故障注入限制为仅影响用户 `jason`。如果您以任何其他用户身份登录，则不会遇到任何延迟。**

###### 问题修复

1. 增加 `productpage` 与 `reviews` 服务之间的超时或降低 `reviews` 与 `ratings` 的超时
2. 终止并重启修复后的微服务
3. 确认 `/productpage` 页面正常响应且没有任何错误

#### 设置请求超时

运行以下命令初始化应用的版本路由：

```
kubectl apply -f samples/bookinfo/networking/virtual-service-all-v1.yaml
```

##### 请求超时

http 请求的超时可以用路由规则的 timeout 字段来指定。 默认情况下，超时是禁用的，本任务中，会把 reviews 服务的超时设置为 1 秒。 为了观察效果，还需要在对 ratings 服务的调用上人为引入 2 秒的延迟。

###### 将请求路由到 `reviews` 服务的 v2 版本，它会发起对 `ratings` 服务的调用：

```
kubectl apply -f - <<EOF
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
        subset: v2
EOF
```

###### 给对 `ratings` 服务的调用添加 2 秒的延迟：

```
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: ratings
spec:
  hosts:
  - ratings
  http:
  - fault:
      delay:
        percent: 100
        fixedDelay: 2s
    route:
    - destination:
        host: ratings
        subset: v1
EOF
```

##### 验证

```
在浏览器中打开 Bookinfo 的网址 http://$GATEWAY_URL/productpage。
这时可以看到 Bookinfo 应用运行正常（显示了评级的星型符号），但是每次刷新页面，都会有 2 秒的延迟。
```

##### 对 `reviews` 服务的调用增加一个半秒的请求超时

```
kubectl apply -f - <<EOF
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
        subset: v2
    timeout: 0.5s
EOF
```

##### 验证

```
刷新 Bookinfo 页面。
这时候应该看到 1 秒钟就会返回，而不是之前的 2 秒钟，但 reviews 是不可用的。
```

##### 注解:

```
即使超时配置为半秒，响应仍需要 1 秒，是因为 productpage 服务中存在硬编码重试，因此它在返回之前调用 reviews 服务超时两次。
```

#### 熔断

*为连接、请求以及异常检测配置熔断*

```
熔断，是创建弹性微服务应用程序的重要模式。熔断能够使您的应用程序具备应对来自故障、潜在峰值和其他 未知网络因素影响的能力。
```

##### 部署 `httpbin` 服务

```
kubectl apply -f samples/httpbin/httpbin.yaml
```

##### 配置熔断器

创建一个目标规则，在调用 httpbin 服务时应用熔断设置

```
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: httpbin
spec:
  host: httpbin
  trafficPolicy:
    connectionPool:
      tcp:
        maxConnections: 1
      http:
        http1MaxPendingRequests: 1
        maxRequestsPerConnection: 1
    outlierDetection:
      consecutiveErrors: 1
      interval: 1s
      baseEjectionTime: 3m
      maxEjectionPercent: 100
EOF
```

https证书版本↓↓↓

```
https://istio.io/zh/docs/ops/common-problems/network-issues/#service-unavailable-errors-after-setting-destination-rule
```

###### 验证

```
kubectl get destinationrule httpbin -o yaml
```

打印

```
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: httpbin
  ...
spec:
  host: httpbin
  trafficPolicy:
    connectionPool:
      http:
        http1MaxPendingRequests: 1
        maxRequestsPerConnection: 1
      tcp:
        maxConnections: 1
    outlierDetection:
      baseEjectionTime: 180.000s
      consecutiveErrors: 1
      interval: 1.000s
      maxEjectionPercent: 100
```

##### 增加一个客户

```
创建客户端程序以发送流量到 httpbin 服务。这是一个名为 Fortio 的负载测试客户的，其可以控制连接数、并发数及发送 HTTP 请求的延迟。通过 Fortio 能够有效的触发前面 在 DestinationRule 中设置的熔断策略。
```

###### 向客户端注入 Istio Sidecar 代理，以便 Istio 对其网络交互进行管理

```
kubectl apply -f <(istioctl kube-inject -f samples/httpbin/sample-client/fortio-deploy.yaml)
```

###### 登入客户端 Pod 并使用 Fortio 工具调用 `httpbin` 服务。`-curl` 参数表明发送一次调用：

```
FORTIO_POD=$(kubectl get pod | grep fortio | awk '{ print $1 }')
```

```
kubectl exec -it $FORTIO_POD  -c fortio /usr/bin/fortio -- load -curl  http://httpbin:8000/get
HTTP/1.1 200 OK
server: envoy
date: Tue, 16 Jan 2018 23:47:00 GMT
content-type: application/json
access-control-allow-origin: *
access-control-allow-credentials: true
content-length: 445
x-envoy-upstream-service-time: 36

{
  "args": {},
  "headers": {
    "Content-Length": "0",
    "Host": "httpbin:8000",
    "User-Agent": "istio/fortio-0.6.2",
    "X-B3-Sampled": "1",
    "X-B3-Spanid": "824fbd828d809bf4",
    "X-B3-Traceid": "824fbd828d809bf4",
    "X-Ot-Span-Context": "824fbd828d809bf4;824fbd828d809bf4;0000000000000000",
    "X-Request-Id": "1ad2de20-806e-9622-949a-bd1d9735a3f4"
  },
  "origin": "127.0.0.1",
  "url": "http://httpbin:8000/get"
}
```

*可以看到调用后端服务的请求已经成功！接下来，可以测试熔断。*

##### 触发熔断器

*在 `DestinationRule` 配置中，定义了 `maxConnections: 1` 和 `http1MaxPendingRequests: 1`。 这些规则意味着，如果并发的连接和请求数超过一个，在 `istio-proxy` 进行进一步的请求和连接时，后续请求或 连接将被阻止。*

###### 发送并发数为 2 的连接（-c 2），请求 20 次（-n 20）：

```
kubectl exec -it $FORTIO_POD  -c fortio /usr/bin/fortio -- load -c 2 -qps 0 -n 20 -loglevel Warning http://httpbin:8000/get
```

打印

```
Fortio 0.6.2 running at 0 queries per second, 2->2 procs, for 5s: http://httpbin:8000/get
Starting at max qps with 2 thread(s) [gomax 2] for exactly 20 calls (10 per thread + 0)
23:51:10 W http.go:617> Parsed non ok code 503 (HTTP/1.1 503)
Ended after 106.474079ms : 20 calls. qps=187.84
Aggregated Function Time : count 20 avg 0.010215375 +/- 0.003604 min 0.005172024 max 0.019434859 sum 0.204307492
# range, mid point, percentile, count
>= 0.00517202 <= 0.006 , 0.00558601 , 5.00, 1
> 0.006 <= 0.007 , 0.0065 , 20.00, 3
> 0.007 <= 0.008 , 0.0075 , 30.00, 2
> 0.008 <= 0.009 , 0.0085 , 40.00, 2
> 0.009 <= 0.01 , 0.0095 , 60.00, 4
> 0.01 <= 0.011 , 0.0105 , 70.00, 2
> 0.011 <= 0.012 , 0.0115 , 75.00, 1
> 0.012 <= 0.014 , 0.013 , 90.00, 3
> 0.016 <= 0.018 , 0.017 , 95.00, 1
> 0.018 <= 0.0194349 , 0.0187174 , 100.00, 1
# target 50% 0.0095
# target 75% 0.012
# target 99% 0.0191479
# target 99.9% 0.0194062
Code 200 : 19 (95.0 %)
Code 503 : 1 (5.0 %)
Response Header Sizes : count 20 avg 218.85 +/- 50.21 min 0 max 231 sum 4377
Response Body/Total Sizes : count 20 avg 652.45 +/- 99.9 min 217 max 676 sum 13049
All done 20 calls (plus 0 warmup) 10.215 ms avg, 187.8 qps
```

**几乎所有的请求都完成了！`istio-proxy` 确实允许存在一些误差。**

```
Code 200 : 19 (95.0 %)
Code 503 : 1 (5.0 %)
```

###### 将并发连接数提高到 3 个

```
kubectl exec -it $FORTIO_POD  -c fortio /usr/bin/fortio -- load -c 3 -qps 0 -n 30 -loglevel Warning http://httpbin:8000/get
```

打印

```
Fortio 0.6.2 running at 0 queries per second, 2->2 procs, for 5s: http://httpbin:8000/get
Starting at max qps with 3 thread(s) [gomax 2] for exactly 30 calls (10 per thread + 0)
23:51:51 W http.go:617> Parsed non ok code 503 (HTTP/1.1 503)
23:51:51 W http.go:617> Parsed non ok code 503 (HTTP/1.1 503)
23:51:51 W http.go:617> Parsed non ok code 503 (HTTP/1.1 503)
23:51:51 W http.go:617> Parsed non ok code 503 (HTTP/1.1 503)
23:51:51 W http.go:617> Parsed non ok code 503 (HTTP/1.1 503)
23:51:51 W http.go:617> Parsed non ok code 503 (HTTP/1.1 503)
23:51:51 W http.go:617> Parsed non ok code 503 (HTTP/1.1 503)
23:51:51 W http.go:617> Parsed non ok code 503 (HTTP/1.1 503)
23:51:51 W http.go:617> Parsed non ok code 503 (HTTP/1.1 503)
23:51:51 W http.go:617> Parsed non ok code 503 (HTTP/1.1 503)
23:51:51 W http.go:617> Parsed non ok code 503 (HTTP/1.1 503)
Ended after 71.05365ms : 30 calls. qps=422.22
Aggregated Function Time : count 30 avg 0.0053360199 +/- 0.004219 min 0.000487853 max 0.018906468 sum 0.160080597
# range, mid point, percentile, count
>= 0.000487853 <= 0.001 , 0.000743926 , 10.00, 3
> 0.001 <= 0.002 , 0.0015 , 30.00, 6
> 0.002 <= 0.003 , 0.0025 , 33.33, 1
> 0.003 <= 0.004 , 0.0035 , 40.00, 2
> 0.004 <= 0.005 , 0.0045 , 46.67, 2
> 0.005 <= 0.006 , 0.0055 , 60.00, 4
> 0.006 <= 0.007 , 0.0065 , 73.33, 4
> 0.007 <= 0.008 , 0.0075 , 80.00, 2
> 0.008 <= 0.009 , 0.0085 , 86.67, 2
> 0.009 <= 0.01 , 0.0095 , 93.33, 2
> 0.014 <= 0.016 , 0.015 , 96.67, 1
> 0.018 <= 0.0189065 , 0.0184532 , 100.00, 1
# target 50% 0.00525
# target 75% 0.00725
# target 99% 0.0186345
# target 99.9% 0.0188793
Code 200 : 19 (63.3 %)
Code 503 : 11 (36.7 %)
Response Header Sizes : count 30 avg 145.73333 +/- 110.9 min 0 max 231 sum 4372
Response Body/Total Sizes : count 30 avg 507.13333 +/- 220.8 min 217 max 676 sum 15214
All done 30 calls (plus 0 warmup) 5.336 ms avg, 422.2 qps
```

**开始看到预期的熔断行为，只有 63.3% 的请求成功，其余的均被熔断器拦截：**

```
Code 200 : 19 (63.3 %)
Code 503 : 11 (36.7 %)
```

###### 查询 `istio-proxy` 状态以了解更多熔断详情

```
kubectl exec $FORTIO_POD -c istio-proxy -- pilot-agent request GET stats | grep httpbin | grep pending
```

打印

```
cluster.outbound|80||httpbin.springistio.svc.cluster.local.upstream_rq_pending_active: 0
cluster.outbound|80||httpbin.springistio.svc.cluster.local.upstream_rq_pending_failure_eject: 0
cluster.outbound|80||httpbin.springistio.svc.cluster.local.upstream_rq_pending_overflow: 12
cluster.outbound|80||httpbin.springistio.svc.cluster.local.upstream_rq_pending_total: 39
```

*可以看到 `upstream_rq_pending_overflow` 值 `12`，这意味着，目前为止已有 12 个调用被标记为熔断。*

#### 镜像

*流量镜像，也称为影子流量，是一个以尽可能低的风险为生产带来变化的强大的功能。镜像会将实时流量的副本发送到镜像服务。镜像流量发生在主服务的关键请求路径之外。*

```
首先把流量全部路由到 v1 版本的测试服务。然后，执行规则将一部分流量镜像到 v2 版本。
```

##### 部署两个版本的 httpbin 服务，httpbin 服务已开启访问日志

**httpbin-v1:**

```
cat <<EOF | istioctl kube-inject -f - | kubectl create -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: httpbin-v1
spec:
  replicas: 1
  selector:
    matchLabels:
      app: httpbin
      version: v1
  template:
    metadata:
      labels:
        app: httpbin
        version: v1
    spec:
      containers:
      - image: docker.io/kennethreitz/httpbin
        imagePullPolicy: IfNotPresent
        name: httpbin
        command: ["gunicorn", "--access-logfile", "-", "-b", "0.0.0.0:80", "httpbin:app"]
        ports:
        - containerPort: 80
EOF
```

**httpbin-v2:**

```
cat <<EOF | istioctl kube-inject -f - | kubectl create -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: httpbin-v2
spec:
  replicas: 1
  selector:
    matchLabels:
      app: httpbin
      version: v2
  template:
    metadata:
      labels:
        app: httpbin
        version: v2
    spec:
      containers:
      - image: docker.io/kennethreitz/httpbin
        imagePullPolicy: IfNotPresent
        name: httpbin
        command: ["gunicorn", "--access-logfile", "-", "-b", "0.0.0.0:80", "httpbin:app"]
        ports:
        - containerPort: 80
EOF
```

**httpbin Kubernetes service:**

```
kubectl create -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: httpbin
  labels:
    app: httpbin
spec:
  ports:
  - name: http
    port: 8000
    targetPort: 80
  selector:
    app: httpbin
EOF
```

##### 启动 `sleep` 服务，这样就可以使用 `curl` 来提供负载了：

**sleep service:**

```
cat <<EOF | istioctl kube-inject -f - | kubectl create -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sleep
spec:
  replicas: 1
  selector:
    matchLabels:
      app: sleep
  template:
    metadata:
      labels:
        app: sleep
    spec:
      containers:
      - name: sleep
        image: tutum/curl
        command: ["/bin/sleep","infinity"]
        imagePullPolicy: IfNotPresent
EOF
```

##### 创建一个默认路由策略

```
默认情况下，Kubernetes 在 httpbin 服务的两个版本之间进行负载均衡。在此步骤中会更改该行为，把所有流量都路由到 v1。
```

###### 创建一个默认路由规则，将所有流量路由到服务的 `v1`：

```
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: httpbin
spec:
  hosts:
    - httpbin
  http:
  - route:
    - destination:
        host: httpbin
        subset: v1
      weight: 100
---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: httpbin
spec:
  host: httpbin
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
EOF
```

###### 向服务发送一下流量：

```
export SLEEP_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
```

```
kubectl exec -it $SLEEP_POD -c sleep -- sh -c 'curl  http://httpbin:8000/headers' | python -m json.tool
```

打印

```
{
  "headers": {
    "Accept": "*/*",
    "Content-Length": "0",
    "Host": "httpbin:8000",
    "User-Agent": "curl/7.35.0",
    "X-B3-Sampled": "1",
    "X-B3-Spanid": "eca3d7ed8f2e6a0a",
    "X-B3-Traceid": "eca3d7ed8f2e6a0a",
    "X-Ot-Span-Context": "eca3d7ed8f2e6a0a;eca3d7ed8f2e6a0a;0000000000000000"
  }
}
```

###### 分别查看 `httpbin` 服务 `v1` 和 `v2` 两个 pods 的日志，您可以看到访问日志进入 `v1`，而 `v2` 中没有日志，显示为 `none`：

`查看V1`

```
export V1_POD=$(kubectl get pod -l app=httpbin,version=v1 -o jsonpath={.items..metadata.name})
kubectl logs -f $V1_POD -c httpbin
```

打印

```
127.0.0.1 - - [07/Mar/2018:19:02:43 +0000] "GET /headers HTTP/1.1" 200 321 "-" "curl/7.35.0"
```

`查看V2`

```
export V2_POD=$(kubectl get pod -l app=httpbin,version=v2 -o jsonpath={.items..metadata.name})
kubectl logs -f $V2_POD -c httpbin
```

打印

```
<none>
```

##### 镜像流量到 v2

###### 改变流量规则将流量镜像到 v2：

```
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: httpbin
spec:
  hosts:
    - httpbin
  http:
  - route:
    - destination:
        host: httpbin
        subset: v1
      weight: 100
    mirror:
      host: httpbin
      subset: v2
    mirror_percent: 100
EOF
```

```
这个路由规则发送 100% 流量到 v1。最后一段表示你将镜像流量到 httpbin:v2 服务。当流量被镜像时，请求将发送到镜像服务中，并在 headers 中的 Host/Authority 属性值上追加 -shadow。例如 cluster-1 变为 cluster-1-shadow。

此外，重点注意这些被镜像的流量是『 即发即弃』 的，就是说镜像请求的响应会被丢弃。

您可以使用 mirror_percent 属性来设置镜像流量的百分比，而不是镜像全部请求。为了兼容老版本，如果这个属性不存在，将镜像所有流量。
```

###### 发送流量：

```
kubectl exec -it $SLEEP_POD -c sleep -- sh -c 'curl  http://httpbin:8000/headers' | python -m json.tool
```

现在就可以看到 `v1` 和 `v2` 中都有了访问日志。v2 中的访问日志就是由镜像流量产生的，这些请求的实际目标是 v1。

`查看V1`

```
kubectl logs -f $V1_POD -c httpbin
```

打印

```
127.0.0.1 - - [07/Mar/2018:19:02:43 +0000] "GET /headers HTTP/1.1" 200 321 "-" "curl/7.35.0"
127.0.0.1 - - [07/Mar/2018:19:26:44 +0000] "GET /headers HTTP/1.1" 200 321 "-" "curl/7.35.0"
```

`查看V2`

```
kubectl logs -f $V2_POD -c httpbin
```

打印

```
127.0.0.1 - - [07/Mar/2018:19:26:44 +0000] "GET /headers HTTP/1.1" 200 361 "-" "curl/7.35.0"
```

##### 如果要检查流量内部，请在另一个控制台上运行以下命令：

```
export SLEEP_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
export V1_POD_IP=$(kubectl get pod -l app=httpbin,version=v1 -o jsonpath={.items..status.podIP})
export V2_POD_IP=$(kubectl get pod -l app=httpbin,version=v2 -o jsonpath={.items..status.podIP})
kubectl exec -it $SLEEP_POD -c istio-proxy -- sudo tcpdump -A -s 0 host $V1_POD_IP or host $V2_POD_IP
```

