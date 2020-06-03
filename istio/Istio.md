# Istio-部署

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

#### 或者使用Curl下载最新版本

```
curl -L https://istio.io/downloadIstio | sh -
```

### 安装istio

参考

```
https://istio.io/zh/docs/setup/install/istioctl/
```

#### 进入安装目录

```
cd istio-1.5.1
```

安装目录包含如下内容：

- `install/kubernetes` 目录下，有 Kubernetes 相关的 YAML 安装文件
- `samples/` 目录下，有示例应用程序
- `bin/` 目录下，包含 [`istioctl`]的客户端文件。`istioctl` 工具用于手动注入 Envoy sidecar 代理。

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

##### 安装

```
istioctl manifest apply --set addonComponents.grafana.enabled=true
```

`--set addonComponents.grafana.enabled=true`开启grafana监控

```
istioctl manifest apply --set profile=demo
```

*demo版本⬆️⬆️⬆️*

```
自定义:
istioctl manifest apply --set addonComponents.grafana.enabled=true --set components.citadel.enabled=true 
```

##### 验证

###### 生成清单[安装前未生成]

```
istioctl manifest generate > $HOME/generated-manifest.yaml
```

```
istioctl manifest generate --set profile=demo > $HOME/generated-manifest.yaml
```

*demo版本⬆️⬆️⬆️*

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

## 使用Helm安装

```
https://istio.io/zh/docs/setup/install/helm/#option-1-install-with-helm-via-helm-template
```

### 添加 Helm chart 仓库

```
helm repo add istio.io https://storage.googleapis.com/istio-release/releases/1.5.4/charts/
```

#### 为 Istio 组件创建命名空间 istio-system：

```
kubectl create namespace istio-system
```

#### 使用 kubectl apply 安装所有 Istio 的 自定义资源 (CRDs) ：

```
helm template istio-init install/kubernetes/helm/istio-init --namespace istio-system | kubectl apply -f -
```

#### 等待所有的 Istio CRD 创建完成：

```
kubectl -n istio-system wait --for=condition=complete job --all
```

#### 安装

```
helm template istio install/kubernetes/helm/istio --namespace istio-system --set gateways.istio-ingressgateway.type=NodePort | kubectl apply -f - 
```

### 验证安装

```
kubectl get svc -n istio-system
```

```
kubectl get pods -n istio-system
```

## 卸载

```
helm template istio install/kubernetes/helm/istio --namespace istio-system | kubectl delete -f -
```

```
kubectl delete namespace istio-system
```

永久删除配置

```
kubectl delete -f install/kubernetes/helm/istio-init/files
```



# Istio-使用

## Bookinfo 应用示例

`Bookinfo` 应用分为四个单独的微服务：

- `productpage`. 这个微服务会调用 `details` 和 `reviews` 两个微服务，用来生成页面。
- `details`. 这个微服务中包含了书籍的信息。
- `reviews`. 这个微服务中包含了书籍相关的评论。它还会调用 `ratings` 微服务。
- `ratings`. 这个微服务中包含了由书籍评价组成的评级信息。

`reviews` 微服务有 3 个版本：

- v1 版本不会调用 `ratings` 服务。
- v2 版本会调用 `ratings` 服务，并使用 1 到 5 个黑色星形图标来显示评分信息。
- v3 版本会调用 `ratings` 服务，并使用 1 到 5 个红色星形图标来显示评分信息。

### 启动应用服务

Istio 默认自动注入 Sidecar. 为 default 命名空间打上标签 istio-injection=enabled：

```
kubectl label namespace default istio-injection=enabled
```

#### 部署

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

#### 创建网关和虚拟路由

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



## 流量管理

```
reviews:v1 带星
reviews:v2 不带星
```

```
https://istio.io/zh/docs/tasks/traffic-management/request-routing/
```

### 配置请求路由

要仅路由到一个版本，请应用为微服务设置默认版本的 virtual service。在这种情况下，virtual service 将所有流量路由到每个微服务的 `v1` 版本。

```
kubectl apply -f samples/bookinfo/networking/virtual-service-all-v1.yaml
```

*由于配置传播是最终一致的，因此请等待几秒钟以使 virtual services 生效。*

#### 使用以下命令显示已定义的路由：

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

验证

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


### 流量转移

***逐步将流量从一个版本的微服务迁移到另一个版本。也以将流量从旧版本迁移到新版本。***

*一个常见的用例是将流量从一个版本的微服务逐渐迁移到另一个版本。在 Istio 中，可以通过配置一系列规则来实现此目标， 这些规则将一定百分比的流量路由到一个或另一个服务。*

例如：可以把 50％ 的流量发送到 `reviews:v1`，另外 50％ 的流量发送到 `reviews:v3`。然后，再把 100％ 的流量发送到 `reviews:v3` 来完成迁移。

#### 应用基于权重的路由

##### 运行此命令将所有流量路由到各个微服务的 `v1` 版本。

```
kubectl apply -f samples/bookinfo/networking/virtual-service-all-v1.yaml
```

##### 把 50% 的流量从 `reviews:v1` 转移到 `reviews:v3`

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

### TCP流量转移

**应用基于权重的 TCP 路由**

#### 部署微服务 `tcp-echo` 的 `v1` 版本

##### 创建namespace

```
kubectl create namespace istio-io-tcp-traffic-shifting
```

##### 手动注入

```
kubectl apply -f <(istioctl kube-inject -f samples/tcp-echo/tcp-echo-services.yaml) -n istio-io-tcp-traffic-shifting
```

##### 自动注入

```
kubectl label namespace istio-io-tcp-traffic-shifting istio-injection=enabled
```

##### 部署

```
kubectl apply -f samples/tcp-echo/tcp-echo-services.yaml -n istio-io-tcp-traffic-shifting
```

#### 将目标为微服务 `tcp-echo` 的 TCP 流量全部路由到 `v1` 版本

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

#### 将 20% 的流量从 `tcp-echo:v1` 转移到 `tcp-echo:v2`

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

### 故障注入

*通过执行配置请求路由任务或运行以下命令来初始化应用程序版本路由*

```
kubectl apply -f samples/bookinfo/networking/virtual-service-all-v1.yaml
kubectl apply -f samples/bookinfo/networking/virtual-service-reviews-test-v2.yaml
```

经过上面的配置，下面是请求的流程：

- `productpage` → `reviews:v2` → `ratings` (针对 `jason` 用户)
- `productpage` → `reviews:v1` (其他用户)

#### 注入 HTTP 延迟故障

```
为了测试微服务应用程序 Bookinfo 的弹性，将为用户 jason 在 reviews:v2 和 ratings 服务之间注入一个 7 秒的延迟。 这个测试将会发现一个故意引入 Bookinfo 应用程序中的 bug。

注意 reviews:v2 服务对 ratings 服务的调用具有 10 秒的硬编码连接超时。 因此，尽管引入了 7 秒的延迟，但仍然期望端到端的流程是没有任何错误的。
```

##### 创建故障注入规则以延迟来自测试用户 `jason` 的流量：

```
kubectl apply -f samples/bookinfo/networking/virtual-service-ratings-test-delay.yaml
```

确认

```
kubectl get virtualservice ratings -o yaml
```

新的规则可能需要几秒钟才能传播到所有的 pod 。

##### 测试延迟配置

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

### 设置请求超时

运行以下命令初始化应用的版本路由：

```
kubectl apply -f samples/bookinfo/networking/virtual-service-all-v1.yaml
```

#### 请求超时

http 请求的超时可以用路由规则的 timeout 字段来指定。 默认情况下，超时是禁用的，本任务中，会把 reviews 服务的超时设置为 1 秒。 为了观察效果，还需要在对 ratings 服务的调用上人为引入 2 秒的延迟。

##### 将请求路由到 `reviews` 服务的 v2 版本，它会发起对 `ratings` 服务的调用：

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

##### 给对 `ratings` 服务的调用添加 2 秒的延迟：

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

验证

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

验证

```
刷新 Bookinfo 页面。
这时候应该看到 1 秒钟就会返回，而不是之前的 2 秒钟，但 reviews 是不可用的。
```

##### 注解:

```
即使超时配置为半秒，响应仍需要 1 秒，是因为 productpage 服务中存在硬编码重试，因此它在返回之前调用 reviews 服务超时两次。
```

### 熔断

*为连接、请求以及异常检测配置熔断*

```
熔断，是创建弹性微服务应用程序的重要模式。熔断能够使您的应用程序具备应对来自故障、潜在峰值和其他 未知网络因素影响的能力。
```

#### 部署 `httpbin` 服务

```
kubectl apply -f samples/httpbin/httpbin.yaml
```

#### 配置熔断器

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

验证

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

#### 增加一个客户

```
创建客户端程序以发送流量到 httpbin 服务。这是一个名为 Fortio 的负载测试客户的，其可以控制连接数、并发数及发送 HTTP 请求的延迟。通过 Fortio 能够有效的触发前面 在 DestinationRule 中设置的熔断策略。
```

##### 向客户端注入 Istio Sidecar 代理，以便 Istio 对其网络交互进行管理

```
kubectl apply -f <(istioctl kube-inject -f samples/httpbin/sample-client/fortio-deploy.yaml)
```

##### 登入客户端 Pod 并使用 Fortio 工具调用 `httpbin` 服务。`-curl` 参数表明发送一次调用：

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

#### 触发熔断器

*在 `DestinationRule` 配置中，定义了 `maxConnections: 1` 和 `http1MaxPendingRequests: 1`。 这些规则意味着，如果并发的连接和请求数超过一个，在 `istio-proxy` 进行进一步的请求和连接时，后续请求或 连接将被阻止。*

##### 发送并发数为 2 的连接（-c 2），请求 20 次（-n 20）：

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

***几乎所有的请求都完成了！`istio-proxy` 确实允许存在一些误差。***

```
Code 200 : 19 (95.0 %)
Code 503 : 1 (5.0 %)
```

##### 将并发连接数提高到 3 个

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

***开始看到预期的熔断行为，只有 63.3% 的请求成功，其余的均被熔断器拦截：***

```
Code 200 : 19 (63.3 %)
Code 503 : 11 (36.7 %)
```

##### 查询 `istio-proxy` 状态以了解更多熔断详情

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

### 镜像

*流量镜像，也称为影子流量，是一个以尽可能低的风险为生产带来变化的强大的功能。镜像会将实时流量的副本发送到镜像服务。镜像流量发生在主服务的关键请求路径之外。*

```
首先把流量全部路由到 v1 版本的测试服务。然后，执行规则将一部分流量镜像到 v2 版本。
```

#### 部署两个版本的 httpbin 服务，httpbin 服务已开启访问日志

##### **httpbin-v1:**

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

##### **httpbin-v2:**

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

##### **httpbin Kubernetes service:**

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

#### 启动 `sleep` 服务，这样就可以使用 `curl` 来提供负载了：

##### **sleep service:**

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

#### 创建一个默认路由策略

```
默认情况下，Kubernetes 在 httpbin 服务的两个版本之间进行负载均衡。在此步骤中会更改该行为，把所有流量都路由到 v1。
```

##### 创建一个默认路由规则，将所有流量路由到服务的 `v1`：

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

##### 向服务发送一下流量：

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

##### 分别查看 `httpbin` 服务 `v1` 和 `v2` 两个 pods 的日志，您可以看到访问日志进入 `v1`，而 `v2` 中没有日志，显示为 `none`：

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

***改变流量规则将流量镜像到 v2：***

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

##### 发送流量：

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



### Ingress

#### Ingress Gateway

##### 创建 Istio Gateway：

```
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: httpbin-gateway
spec:
  selector:
    istio: ingressgateway # use Istio default gateway implementation
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "httpbin.fuck.com"
EOF
```

***为通过 Gateway 的入口流量配置路由：***

```
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: httpbin
spec:
  hosts:
  - "httpbin.fuck.com"
  gateways:
  - httpbin-gateway
  http:
  - match:
    - uri:
        prefix: /status
    - uri:
        prefix: /delay
    route:
    - destination:
        port:
          number: 8000
        host: httpbin
EOF
```

```
已为 httpbin 服务创建了虚拟服务配置，包含两个路由规则，允许流量流向路径 /status 和 /delay。
gateways 列表规约了哪些请求允许通过 httpbin-gateway 网关。 所有其他外部请求均被拒绝并返回 404 响应。
```

##### 使用 *curl* 访问 *httpbin* 服务：

***正常：***

```
curl -I -HHost:httpbin.fuck.com http://202.107.190.8:10385/status/200
```

打印

```
HTTP/1.1 200 OK
server: istio-envoy
date: Wed, 06 May 2020 03:39:37 GMT
content-type: text/html; charset=utf-8
access-control-allow-origin: *
access-control-allow-credentials: true
content-length: 0
x-envoy-upstream-service-time: 29
```

*注意*

```
注意上文命令使用 -H 标识将 HTTP 头部参数 Host 设置为 “httpbin.example.com”。 该操作为必须操作，因为 ingress Gateway 已被配置用来处理 “httpbin.example.com” 的服务请求，而在测试环境中并没有为该主机绑定 DNS 而是简单直接地向 ingress IP 发送请求。
```

***非正常：***

访问其他没有被显式暴露的 URL 时，将看到 HTTP 404 错误：

```
curl -I -HHost:httpbin.fuck.com http://202.107.190.8:10385/fuck/
```

```
HTTP/1.1 404 Not Found
date: Wed, 06 May 2020 03:43:24 GMT
server: istio-envoy
transfer-encoding: chunked
```

##### 通过浏览器访问 ingress 服务

```
在浏览器中输入 httpbin 服务的 URL 不能获得有效的响应，因为无法像 curl 那样，将请求头部参数 Host 传给浏览器。在现实场景中，这并不是问题，因为你需要合理配置被请求的主机及可解析的 DNS，从而在 URL 中使用主机的域名，譬如： https://httpbin.example.com/status/200。
```

为了在简单的测试和演示中绕过这个问题，请在 `Gateway` 和 `VirtualService` 配置中使用通配符 `*`。譬如，修改 ingress 配置如下：

```
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: httpbin-gateway
spec:
  selector:
    istio: ingressgateway # use Istio default gateway implementation
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "*"
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: httpbin
spec:
  hosts:
  - "*"
  gateways:
  - httpbin-gateway
  http:
  - match:
    - uri:
        prefix: /headers
    route:
    - destination:
        port:
          number: 8000
        host: httpbin
EOF
```

###### 注：

```
此时，便可以在浏览器中输入包含 $INGRESS_HOST:$INGRESS_PORT 的 URL。譬如，输入http://$INGRESS_HOST:$INGRESS_PORT/headers，将显示浏览器发送的所有 headers 信息。
```

#### 安全网关（文件挂载）

配置一个 ingress 网关以将 HTTP 服务暴露给外部流量、使用简单或双向 TLS 暴露安全 HTTPS 服务。

##### 生成服务器证书和私钥[或者自己已有证书]

使用 openssl 创建一个根证书和私钥以为您的服务所用的证书签名：

```
openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -subj '/O=fuck./CN=fuck.com' -keyout fuck.com.key -out fuck.com.crt
```

为 `httpbin.fuck.com` 创建一个证书和私钥：

```
openssl req -out httpbin.fuck.com.csr -newkey rsa:2048 -nodes -keyout httpbin.fuck.com.key -subj "/CN=httpbin.fuck.com/O=httpbin organization"
```

```
openssl x509 -req -days 365 -CA fuck.com.crt -CAkey fuck.com.key -set_serial 0 -in httpbin.fuck.com.csr -out httpbin.fuck.com.crt
```

##### 基于文件挂载的方式配置 TLS ingress 网关

配置一个使用 443 端口的 ingress 网关，以处理 HTTPS 流量。 首先使用证书和私钥创建一个 secret。该 secret 将被挂载为 /etc/istio/ingressgateway-certs 路径下的一个文件。 然后您可以创建一个网关定义，它将配置一个运行于端口 443 的服务。

*创建一个 Kubernetes secret 以保存服务器的证书和私钥。使用 `kubectl` 在命名空间 `istio-system` 下创建 secret `istio-ingressgateway-certs`。Istio 网关将会自动加载该 secret。*

```
kubectl create -n istio-system secret tls istio-ingressgateway-certs --key httpbin.fuck.com.key --cert httpbin.fuck.com.crt
```

**注:**

```
默认情况下，istio-system 命名空间下的所有 pod 都能挂载这个 secret 并访问该私钥。可以将 ingress 网关部署到一个单独的命名空间中，并在那创建 secret，这样就只有这个 ingress 网关 pod 才能挂载它。
```

验证 `tls.crt` 和 `tls.key` 是否都已经挂载到 ingress 网关 pod 中：

```
kubectl exec -it -n istio-system $(kubectl -n istio-system get pods -l istio=ingressgateway -o jsonpath='{.items[0].metadata.name}') -- ls -al /etc/istio/ingressgateway-certs
```

##### 为 443 端口定义 `Gateway` 并设置 `server`。

```
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: httpbin-gateway
spec:
  selector:
    istio: ingressgateway # use istio default ingress gateway
  servers:
  - port:
      number: 443
      name: https
      protocol: HTTPS
    tls:
      mode: SIMPLE
      serverCertificate: /etc/istio/ingressgateway-certs/tls.crt
      privateKey: /etc/istio/ingressgateway-certs/tls.key
    hosts:
    - "httpbin.fuck.com"
EOF

```

##### 配置路由以让流量从 `Gateway` 进入

```
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: httpbin
spec:
  hosts:
  - "httpbin.fuck.com"
  gateways:
  - httpbin-gateway
  http:
  - match:
    - uri:
        prefix: /status
    - uri:
        prefix: /delay
    route:
    - destination:
        port:
          number: 8000
        host: httpbin
EOF
```

##### 使用 *curl* 发送一个 `https` 请求到 `SECURE_INGRESS_PORT` 以通过 HTTPS 访问 `httpbin` 服务。`--resolve` 标志让 *curl* 在通过 TLS 访问网关 IP 时支持 SNI值 `httpbin.fuck.com`。 `--cacert` 选项则让 *curl* 使用您创建的证书来验证服务器。

```
通过发送请求到 /status/418 URL 路径，您可以很好地看到您的 httpbin 服务确实已被访问。 httpbin 服务将返回 418 I’m a Teapot 代码。
```

```
curl -v -HHost:httpbin.fuck.com --resolve httpbin.fuck.com:10386:202.107.190.8 --cacert fuck.com.crt https://httpbin.fuck.com:10386/status/418
```

打印

```
* Added httpbin.fuck.com:10386:202.107.190.8 to DNS cache
* About to connect() to httpbin.fuck.com port 10386 (#0)
*   Trying 202.107.190.8...
* Connected to httpbin.fuck.com (202.107.190.8) port 10386 (#0)
* Initializing NSS with certpath: sql:/etc/pki/nssdb
*   CAfile: fuck.com.crt
  CApath: none
* SSL connection using TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256
* Server certificate:
*       subject: O=httpbin organization,CN=httpbin.fuck.com
*       start date: May 06 06:45:16 2020 GMT
*       expire date: May 06 06:45:16 2021 GMT
*       common name: httpbin.fuck.com
*       issuer: CN=fuck.com,O=fuck.
> GET /status/418 HTTP/1.1
> User-Agent: curl/7.29.0
> Accept: */*
> Host:httpbin.fuck.com
> 
< HTTP/1.1 418 Unknown
< server: istio-envoy
< date: Wed, 06 May 2020 07:27:35 GMT
< x-more-info: http://tools.ietf.org/html/rfc2324
< access-control-allow-origin: *
< access-control-allow-credentials: true
< content-length: 135
< x-envoy-upstream-service-time: 8
< 

    -=[ teapot ]=-

       _...._
     .'  _ _ `.
    | ."` ^ `". _,
    \_;`"---"`|//
      |       ;/
      \_     _/
        `"""`
* Connection #0 to host httpbin.fuck.com left intact
```

在 *curl* 的输出中寻找 *Server certificate* 部分，尤其是找到与 *common name* 匹配的行：`common name: httpbin.example.com (matched)`。 输出中的 `SSL certificate verify ok` 这一行表示服务端的证书验证成功。 如果一切顺利，您还应该看到返回的状态 418，以及精美的茶壶图。

#### 配置双向 TLS ingress 网关

将网关的定义从上一节中扩展为支持外部客户端和网关之间的双向 TLS。

##### 创建一个 Kubernetes `Secret` 以保存服务端将用来验证它的客户端的 CA 证书。使用 `kubectl` 在命名空间 `istio-system` 中创建 secret `istio-ingressgateway-ca-certs`。Istio 网关将会自动加载该 secret。

```
该 secret 必须在 istio-system 命名空间下，且名为 istio-ingressgateway-ca-certs，以与此任务中使用的 Istio 默认 ingress 网关的配置保持一致。
```

```
kubectl create -n istio-system secret generic istio-ingressgateway-ca-certs --from-file=fuck.com.crt
```

##### 重新定义之前的 `Gateway`，修改 TLS 模式为 `MUTUAL`，并指定 `caCertificates`：

```
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: httpbin-gateway
spec:
  selector:
    istio: ingressgateway # use istio default ingress gateway
  servers:
  - port:
      number: 443
      name: https
      protocol: HTTPS
    tls:
      mode: MUTUAL
      serverCertificate: /etc/istio/ingressgateway-certs/tls.crt
      privateKey: /etc/istio/ingressgateway-certs/tls.key
      caCertificates: /etc/istio/ingressgateway-ca-certs/fuck.com.crt
    hosts:
    - "httpbin.fuck.com"
EOF
```

##### 通过 HTTPS 访问 `httpbin` 服务：

```
curl -v -HHost:httpbin.fuck.com --resolve httpbin.fuck.com:10386:202.107.190.8 --cacert fuck.com.crt https://httpbin.fuck.com:10386/status/418
```

```
网关定义传播需要时间，因此您可能会仍然得到 418 状态码。请稍后重新执行 curl 命令。
这次您将得到一个报错，因为服务端拒绝接受未认证的请求。您需要传递 curl 客户端证书和私钥以将请求签名。
```

##### 重新用 *curl* 发送之前的请求，这次通过参数传递客户端证书（添加 `--cert` 选项）和您的私钥（`--key` 选项）：

```
curl -v -HHost:httpbin.fuck.com --resolve httpbin.fuck.com:10386:202.107.190.8 --cacert fuck.com.crt --cert ./httpbin.fuck.com.crt --key httpbin.fuck.com.key  https://httpbin.fuck.com:10386/status/418
```

打印

```
* Added httpbin.fuck.com:10386:202.107.190.8 to DNS cache
* About to connect() to httpbin.fuck.com port 10386 (#0)
*   Trying 202.107.190.8...
* Connected to httpbin.fuck.com (202.107.190.8) port 10386 (#0)
* Initializing NSS with certpath: sql:/etc/pki/nssdb
*   CAfile: fuck.com.crt
  CApath: none
* NSS: client certificate from file
*       subject: O=httpbin organization,CN=httpbin.fuck.com
*       start date: May 06 06:45:16 2020 GMT
*       expire date: May 06 06:45:16 2021 GMT
*       common name: httpbin.fuck.com
*       issuer: CN=fuck.com,O=fuck.
* SSL connection using TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256
* Server certificate:
*       subject: O=httpbin organization,CN=httpbin.fuck.com
*       start date: May 06 06:45:16 2020 GMT
*       expire date: May 06 06:45:16 2021 GMT
*       common name: httpbin.fuck.com
*       issuer: CN=fuck.com,O=fuck.
> GET /status/418 HTTP/1.1
> User-Agent: curl/7.29.0
> Accept: */*
> Host:httpbin.fuck.com
> 
< HTTP/1.1 418 Unknown
< server: istio-envoy
< date: Wed, 06 May 2020 09:18:14 GMT
< x-more-info: http://tools.ietf.org/html/rfc2324
< access-control-allow-origin: *
< access-control-allow-credentials: true
< content-length: 135
< x-envoy-upstream-service-time: 8
< 

    -=[ teapot ]=-

       _...._
     .'  _ _ `.
    | ."` ^ `". _,
    \_;`"---"`|//
      |       ;/
      \_     _/
        `"""`
* Connection #0 to host httpbin.fuck.com left intact
```

#### 为多主机配置 TLS ingress 网关

```
为多个主机（httpbin.example.com 和 bookinfo.com）配置 ingress 网关。 Ingress 网关将向客户端提供与每个请求的服务器相对应的唯一证书。
```

```
与之前不同，Istio 默认 ingress 网关无法立即使用，因为它仅被预配置为支持一个安全主机。 您需要先使用另一个 secret 配置并重新部署 ingress 网关服务器，然后才能使用它来处理第二台主机。
```

##### 为 `bookinfo.com` 创建服务器证书和私钥

```
openssl req -out bookinfo.com.csr -newkey rsa:2048 -nodes -keyout bookinfo.com.key -subj "/CN=bookinfo.com/O=bookinfo organization"
```

```
openssl x509 -req -days 365 -CA fuck.com.crt -CAkey fuck.com.key -set_serial 0 -in bookinfo.com.csr -out bookinfo.com.crt
```

##### 使用新证书重新部署 `istio-ingressgateway`

*创建一个新的 secret 以保存 `bookinfo.com` 的证书：*

```
kubectl create -n istio-system secret tls istio-ingressgateway-bookinfo-certs --key bookinfo.com.key --cert bookinfo.com.crt
```

*更新 `istio-ingressgateway` deployment 以挂载新创建的 secret。创建如下 `gateway-patch.json` 文件以更新 `istio-ingressgateway` deployment：*

```
cat > gateway-patch.json <<EOF
[{
  "op": "add",
  "path": "/spec/template/spec/containers/0/volumeMounts/0",
  "value": {
    "mountPath": "/etc/istio/ingressgateway-bookinfo-certs",
    "name": "ingressgateway-bookinfo-certs",
    "readOnly": true
  }
},
{
  "op": "add",
  "path": "/spec/template/spec/volumes/0",
  "value": {
  "name": "ingressgateway-bookinfo-certs",
    "secret": {
      "secretName": "istio-ingressgateway-bookinfo-certs",
      "optional": true
    }
  }
}]
EOF
```

##### 使用以下命令应用 `istio-ingressgateway` deployment 更新：

```
kubectl -n istio-system patch --type=json deploy istio-ingressgateway -p "$(cat gateway-patch.json)"
```

##### 验证 `istio-ingressgateway` pod 已成功加载私钥和证书：

```
kubectl exec -it -n istio-system $(kubectl -n istio-system get pods -l istio=ingressgateway -o jsonpath='{.items[0].metadata.name}') -- ls -al /etc/istio/ingressgateway-bookinfo-certs

```

*`tls.crt` 和 `tls.key` 应该出现在文件夹之中。*

##### 配置 `bookinfo.com` 主机的流量

```
kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml
```

##### 为 `bookinfo.com` 定义网关：

```
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: bookinfo-gateway
spec:
  selector:
    istio: ingressgateway # use istio default ingress gateway
  servers:
  - port:
      number: 443
      name: https-bookinfo
      protocol: HTTPS
    tls:
      mode: SIMPLE
      serverCertificate: /etc/istio/ingressgateway-bookinfo-certs/tls.crt
      privateKey: /etc/istio/ingressgateway-bookinfo-certs/tls.key
    hosts:
    - "bookinfo.com"
EOF
```

##### 配置 `bookinfo.com` 的路由。定义类似 `samples/bookinfo/networking/bookinfo-gateway.yaml` 的 `VirtualService`：

```
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: bookinfo
spec:
  hosts:
  - "bookinfo.com"
  gateways:
  - bookinfo-gateway
  http:
  - match:
    - uri:
        exact: /productpage
    - uri:
        exact: /login
    - uri:
        exact: /logout
    - uri:
        prefix: /api/v1/products
    route:
    - destination:
        host: productpage
        port:
          number: 9080
EOF

```

##### 发送到 *Bookinfo* `productpage` 的请求：

```
curl -o /dev/null -s -v -w "%{http_code}\n" -HHost:bookinfo.com --resolve bookinfo.com:10386:202.107.190.8 --cacert fuck.com.crt -HHost:bookinfo.com https://bookinfo.com:10386/productpage
```

##### 验证 `httbin.example.com` 像之前一样可访问

```
curl -HHost:httpbin.fuck.com --resolve httpbin.fuck.com:10386:202.107.190.8 --cacert fuck.com.crt --cert ./httpbin.fuck.com.crt --key httpbin.fuck.com.key https://httpbin.fuck.com:10386/status/418
```

打印

```
    -=[ teapot ]=-

       _...._
     .'  _ _ `.
    | ."` ^ `". _,
    \_;`"---"`|//
      |       ;/
      \_     _/
        `"""`
```

#### 无 TLS 终止的 Ingress Gateway

*安全网关说明了如何为 HTTP 服务配置 HTTPS 访问入口。 而本示例将说明如何为 HTTPS 服务配置 HTTPS 访问入口，即配置 Ingress Gateway 以执行 SNI 透传，而不是对传入请求进行 TLS 终止。*

*本任务中的 HTTPS 示例服务是一个简单的 NGINX 服务。 在接下来的步骤中，你会先在你的 Kubernetes 集群中创建一个 NGINX 服务。 然后，通过网关给这个服务配置一个域名是 nginx.example.com 的访问入口。*

##### 生成客户端和服务端的证书和密钥

创建根证书和私钥来为您的服务签名证书：

```
openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -subj '/O=example Inc./CN=example.com' -keyout example.com.key -out example.com.crt
```

为 `nginx.example.com` 创建证书和私钥：

```
openssl req -out nginx.example.com.csr -newkey rsa:2048 -nodes -keyout nginx.example.com.key -subj "/CN=nginx.example.com/O=some organization"
```

```
openssl x509 -req -days 365 -CA fuck.com.crt -CAkey fuck.com.key -set_serial 0 -in nginx.example.com.csr -out nginx.example.com.crt
```

##### 部署一个 NGINX 服务

创建一个 Kubernetes 的 Secret 资源来保存服务的证书：

```
kubectl create secret tls nginx-server-certs --key nginx.example.com.key --cert nginx.example.com.crt
```

为 NGINX 服务创建一个配置文件：

```
cat <<EOF > ./nginx.conf
events {
}

http {
  log_format main '$remote_addr - $remote_user [$time_local]  $status '
  '"$request" $body_bytes_sent "$http_referer" '
  '"$http_user_agent" "$http_x_forwarded_for"';
  access_log /var/log/nginx/access.log main;
  error_log  /var/log/nginx/error.log;

  server {
    listen 443 ssl;

    root /usr/share/nginx/html;
    index index.html;

    server_name nginx.example.com;
    ssl_certificate /etc/nginx-server-certs/tls.crt;
    ssl_certificate_key /etc/nginx-server-certs/tls.key;
  }
}
EOF

```

创建一个 Kubernetes 的 ConfigMap 资源来保存 NGINX 服务的配置：

```
kubectl create configmap nginx-configmap --from-file=nginx.conf=./nginx.conf
```

部署 NGINX 服务:

```
cat <<EOF | istioctl kube-inject -f - | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: my-nginx
  labels:
    run: my-nginx
spec:
  ports:
  - port: 443
    protocol: TCP
  selector:
    run: my-nginx
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-nginx
spec:
  selector:
    matchLabels:
      run: my-nginx
  replicas: 1
  template:
    metadata:
      labels:
        run: my-nginx
    spec:
      containers:
      - name: my-nginx
        image: nginx
        ports:
        - containerPort: 443
        volumeMounts:
        - name: nginx-config
          mountPath: /etc/nginx
          readOnly: true
        - name: nginx-server-certs
          mountPath: /etc/nginx-server-certs
          readOnly: true
      volumes:
      - name: nginx-config
        configMap:
          name: nginx-configmap
      - name: nginx-server-certs
        secret:
          secretName: nginx-server-certs
EOF
```

要测试 NGINX 服务是否已成功部署，需要从其 sidecar 代理发送请求，并忽略检查服务端的证书（使用 curl 的 -k 选项）。确保正确打印服务端的证书，即 `common name` 等于 `nginx.example.com`。

```
kubectl exec -it $(kubectl get pod  -l run=my-nginx -o jsonpath={.items..metadata.name}) -c istio-proxy -- curl -v -k --resolve nginx.example.com:443:127.0.0.1 https://nginx.example.com
```

##### 配置 ingress gateway

定义一个 server 部分的端口为 443 的 Gateway。 注意，PASSTHROUGH tls mode 指示 gateway 按原样通过入口流量，而不终止 TLS。

```
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: mygateway
spec:
  selector:
    istio: ingressgateway # use istio default ingress gateway
  servers:
  - port:
      number: 443
      name: https
      protocol: HTTPS
    tls:
      mode: PASSTHROUGH
    hosts:
    - nginx.example.com
EOF
```

配置通过 `Gateway` 进入的流量的路由：

```
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: nginx
spec:
  hosts:
  - nginx.example.com
  gateways:
  - mygateway
  tls:
  - match:
    - port: 443
      sni_hosts:
      - nginx.example.com
    route:
    - destination:
        host: my-nginx
        port:
          number: 443
EOF
```

根据确定 ingress IP 和端口中的指令来定义环境变量 SECURE_INGRESS_PORT 和 INGRESS_HOST。

从集群外访问 NGINX 服务。注意，服务端返回了正确的证书，并且该证书已成功验证（输出了 *SSL certificate verify ok* ）。

```
curl -v --resolve nginx.example.com:10386:202.107.190.8 --cacert fuck.com.crt https://nginx.example.com:10386
```

#### 使用 Cert-Manager 加密 Kubernetes Ingress

##### 准备工作

确认已经启用支持 Kubernetes Ingress 和 SDS 的 ingress gateway。

```
istioctl manifest apply \
  --set values.gateways.istio-ingressgateway.sds.enabled=true \
  --set values.global.k8sIngress.enabled=true \
  --set values.global.k8sIngress.enableHttps=true \
  --set values.global.k8sIngress.gatewayName=ingressgateway
```

安装cert-manager

```
kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v0.15.0/cert-manager.yaml
```

```
kubectl create clusterrolebinding cluster-admin-binding \
  --clusterrole=cluster-admin \
  --user=$(gcloud config get-value core/account)
```

验证

```
kubectl get pods --namespace cert-manager
```



*在 Istio 中使用 Let’s Encrypt 签发 TLS 证书为 Kubernetes Ingress controller 提供安全加固的过程。*

*将从全新的 Istio 安装开始，创建示例服务，使用 Kubernetes Ingress 把它开放出去，并使用 cert-manager（与 Istio 捆绑在一起）管理 TLS 证书的签发和续订来确保它的安全，这个证书之后会给 Istio ingress gateway 使用，并根据需要通过 Secrets Discovery Service (SDS) 提供 hot-swapped 功能。*

##### 配置 DNS 域名和 gateway

记录一下 `istio-ingressgateway` 服务的外部 IP：

```
kubectl -n istio-system get service istio-ingressgateway
```

对您的 DNS 进行设置，给 `istio-ingressgateway` 服务的外部 IP 分配一个合适的域名。为了能让例子正常执行，您需要一个真正的域名，用于获取 TLS 证书。让我们把域名保存为环境变量，以便于后面的使用：

```
INGRESS_DOMAIN=mysubdomain.mydomain.edu
```

Istio 安装中包含了一个自动生成的 gateway ，用于提供 Kubernetes Ingress 定义的路由服务。默认情况下，它不会使用 SDS，所以您需要对其进行修改，使其能通过 SDS 来为 istio-ingressgateway 签发 TLS 证书：

```
kubectl -n istio-system edit gateway
```

```
旧版bak如下
```

```
# Please edit the object below. Lines beginning with a '#' will be ignored,
# and an empty file will abort the edit. If an error occurs while saving this file will be
# reopened with the relevant failures.
#
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  annotations:
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"networking.istio.io/v1alpha3","kind":"Gateway","metadata":{"annotations":{},"labels":{"operator.istio.io/component":"IngressGateways","operator.istio.io/managed":"Reconcile","operator.istio.io/version":"1.5.1","release":"istio"},"name":"ingressgateway","namespace":"istio-system"},"spec":{"selector":{"istio":"ingressgateway"},"servers":[{"hosts":["*"],"port":{"name":"http","number":80,"protocol":"HTTP"}}]}}
  creationTimestamp: "2020-03-30T06:25:44Z"
  generation: 1
  labels:
    operator.istio.io/component: IngressGateways
    operator.istio.io/managed: Reconcile
    operator.istio.io/version: 1.5.1
    release: istio
  name: ingressgateway
  namespace: istio-system
  resourceVersion: "45373421"
  selfLink: /apis/networking.istio.io/v1beta1/namespaces/istio-system/gateways/ingressgateway
  uid: 4db0fc7c-52b2-4269-a445-014035c48710
spec:
  selector:
    istio: ingressgateway
  servers:
  - hosts:
    - '*'
    port:
      name: http
      number: 80
      protocol: HTTP
```

修改 https-default 端口对应的 tls 内容：

```
kubectl -n istio-system \
  patch gateway istio-autogenerated-k8s-ingress --type=json \
  -p='[{"op": "replace", "path": "/spec/servers/1/tls", "value": {"credentialName": "ingress-cert", "mode": "SIMPLE", "privateKey": "sds", "serverCertificate": "sds"}}]'
```

##### 部署演示应用

使用一个简单的 `helloworld` 应用来进行演示。下面的命令会为示例应用创建 `Deployment` 和 `Service`，并使用 Istio Ingress 开放服务。

```
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: helloworld
  labels:
    app: helloworld
spec:
  ports:
  - port: 5000
    name: http
  selector:
    app: helloworld
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: helloworld
spec:
  template:
    metadata:
      labels:
        app: helloworld
    spec:
      containers:
      - name: helloworld
        image: istio/examples-helloworld-v1
        resources:
          requests:
            cpu: "100m"
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 5000
---
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.class: istio
  name: helloworld-ingress
spec:
  rules:
    - host: "$INGRESS_DOMAIN"
      http:
        paths:
          - path: /hello
            backend:
              serviceName: helloworld
              servicePort: 5000
---
EOF
```

通过 HTTP 访问演示应用：

```
curl http://$INGRESS_DOMAIN/hello
```

因为没有配置任何的 TLS 证书，所以现在还不能使用 HTTPS 访问，下面就开始进行配置。

##### 使用 cert-manager 获取 Let’s Encrypt 签发的证书

*目前，您的 Istio 中应该已经启动了 cert-manager，并带有两个 ClusterIssuer 对象（分别对应 Let’s Encrypt 的生产和测试 ACME-endpoints）。这个例子中使用测试 ACME-endpoint（将 letsencrypt-staging 替换为 letsencrypt 就能获得浏览器信任的证书）。*

为了用 cert-manager 进行证书的签发和管理，需要创建一个 Certificate 对象：

```
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1alpha2
kind: Certificate
metadata:
  name: ingress-cert
  namespace: istio-system
spec:
  secretName: ingress-cert
  issuerRef:
    name: letsencrypt-staging
    kind: ClusterIssuer
  commonName: $INGRESS_DOMAIN
  dnsNames:
  - $INGRESS_DOMAIN
  acme:
    config:
    - http01:
        ingressClass: istio
      domains:
      - $INGRESS_DOMAIN
---
EOF
```

注意这里的 secretName 要匹配前面配置 gateway 时的 credentialName 字段值。Certificate 对象会被 cert-manager 处理，最终会签发新证书。为了看到这个过程我们可以查询 Certificate 对象的状态：

```
kubectl -n istio-system describe certificate ingress-cert
```

该服务也应通过 HTTPS 访问了：

```
curl --insecure https://$INGRESS_DOMAIN/hello
```

##### **从测试到生产**

现在换成生产 `letsencrypt`。首先，我们重新申请一下证书。

```
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1alpha2
kind: Certificate
metadata:
  name: ingress-cert
  namespace: istio-system
spec:
  secretName: ingress-cert
  issuerRef:
    name: letsencrypt
    kind: ClusterIssuer
  commonName: $INGRESS_DOMAIN
  dnsNames:
  - $INGRESS_DOMAIN
  acme:
    config:
    - http01:
        ingressClass: istio
      domains:
      - $INGRESS_DOMAIN
---
EOF
```

删除 secret 来强制 cert-manager 从生产 ACME-endpoints 请求新证书：

```
kubectl delete secret -n istio-system ingress-cert
```

查看证书是否成功签发了：

```
watch -n1 kubectl describe cert ingress-cert -n istio-system
```

打印

```
Normal  CertIssued     13m   cert-manager  Certificate issued successfully
```



#### Engress

##### 访问外部服务

```
由于默认情况下，来自 Istio-enable Pod 的所有出站流量都会重定向到其 Sidecar 代理，群集外部 URL 的可访问性取决于代理的配置。默认情况下，Istio 将 Envoy 代理配置为允许传递未知服务的请求。尽管这为入门 Istio 带来了方便，但是，通常情况下，配置更严格的控制是更可取的。

三种访问外部服务的方法：
	允许 Envoy 代理将请求传递到未在网格内配置过的服务。
	配置 service entries 以提供对外部服务的受控访问。
	对于特定范围的 IP，完全绕过 Envoy 代理。
```

###### 部署 sleep 这个示例应用，用作发送请求的测试源。

```
kubectl apply -f samples/sleep/sleep.yaml	
```

*Istio 有一个安装选项， `global.outboundTrafficPolicy.mode`，它配置 sidecar 对外部服务（那些没有在 Istio 的内部服务注册中定义的服务）的处理方式。如果这个选项设置为 `ALLOW_ANY`，Istio 代理允许调用未知的服务。如果这个选项设置为 `REGISTRY_ONLY`，那么 Istio 代理会阻止任何没有在网格中定义的 HTTP 服务或 service entry 的主机。`ALLOW_ANY` 是默认值，不控制对外部服务的访问。*

要查看这种方法的实际效果，你需要确保 Istio 的安装配置了 `global.outboundTrafficPolicy.mode` 选项为 `ALLOW_ANY`。它在默认情况下是开启的，除非你在安装 Istio 时显式地将它设置为 `REGISTRY_ONLY`。

```
kubectl get configmap istio -n istio-system -o yaml | grep -o "mode: ALLOW_ANY"
```

打印

```
mode: ALLOW_ANY
```

如果你显式地设置了 `REGISTRY_ONLY` 模式，可以用以下的命令来改变它：

```
kubectl get configmap istio -n istio-system -o yaml | sed 's/mode: REGISTRY_ONLY/mode: ALLOW_ANY/g' | kubectl replace -n istio-system -f -
```

###### 从 `SOURCE_POD` 向外部 HTTPS 服务发出两个请求，确保能够得到状态码为 `200` 的响应

```
kubectl exec -it sleep-6c7875499f-x48w2 -c sleep -- curl -I https://www.baidu.com | grep  "HTTP/"; kubectl exec -it sleep-6c7875499f-x48w2 -c sleep -- curl -I https://www.sina.com | grep "HTTP/"
```

打印

```
HTTP/1.1 200 OK
HTTP/2 301 
```

成功地从网格中发送了 egress 流量。

这种访问外部服务的简单方法有一个缺点，即丢失了对外部服务流量的 Istio 监控和控制；比如，外部服务的调用没有记录到 Mixer 的日志中。下一节将介绍如何监控和控制网格对外部服务的访问。

##### 控制对外部服务的访问

使用 Istio ServiceEntry 配置，你可以从 Istio 集群中访问任何公开的服务。

本节将向你展示如何在不丢失 Istio 的流量监控和控制特性的情况下，配置对外部 HTTP 服务(httpbin.org) 和外部 HTTPS 服务(www.baidu.com) 的访问。

###### 开启mixer

```
istioctl manifest apply --set addonComponents.grafana.enabled=true --set addonComponents.mixer.enabled=true
```



###### 更改为默认的封锁策略

如何控制对外部服务的访问，需要将 `global.outboundTrafficPolicy.mode` 选项，从 `ALLOW_ANY`模式 改为 `REGISTRY_ONLY` 模式。

执行以下命令来将 `global.outboundTrafficPolicy.mode` 选项改为 `REGISTRY_ONLY`：

```
kubectl get configmap istio -n istio-system -o yaml | sed 's/mode: ALLOW_ANY/mode: REGISTRY_ONLY/g' | kubectl replace -n istio-system -f -
```

从 `SOURCE_POD` 向外部 HTTPS 服务发出几个请求，验证它们现在是否被阻止：

```
kubectl exec -it sleep-6c7875499f-x48w2 -c sleep -- curl -I https://www.baidu.com | grep  "HTTP/"; kubectl exec -it sleep-6c7875499f-x48w2 -c sleep -- curl -I https://www.sina.com | grep "HTTP/"
```

打印

```
command terminated with exit code 35
command terminated with exit code 35
```

###### 创建一个 `ServiceEntry`，以允许访问一个外部的 HTTP 服务：

```
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: httpbin-ext
spec:
  hosts:
  - httpbin.org
  ports:
  - number: 80
    name: http
    protocol: HTTP
  resolution: DNS
  location: MESH_EXTERNAL
EOF
```

从 `SOURCE_POD` 向外部的 HTTP 服务发出一个请求：

```
kubectl exec -it sleep-6c7875499f-pwvls -c sleep -- curl http://httpbin.org/headers
```

打印

```
{
  "headers": {
    "Accept": "*/*", 
    "Content-Length": "0", 
    "Host": "httpbin.org", 
    "User-Agent": "curl/7.64.0", 
    "X-Amzn-Trace-Id": "Root=1-5eb4fdce-454fa3c12128dd0be3ddf78a", 
    "X-B3-Sampled": "0", 
    "X-B3-Spanid": "0a566ae796c597ad", 
    "X-B3-Traceid": "b9a9866fe891f0da0a566ae796c597ad", 
    "X-Envoy-Decorator-Operation": "httpbin.org:80/*", 
    "X-Envoy-Peer-Metadata": "Ch4KDElOU1RBTkNFX0lQUxIOGgwxMC4yMC4xNi4xODMKxAEKBkxBQkVMUxK5ASq2AQoOCgNhcHASBxoFc2xlZXAKIQoRcG9kLXRlbXBsYXRlLWhhc2gSDBoKNmM3ODc1NDk5ZgokChlzZWN1cml0eS5pc3Rpby5pby90bHNNb2RlEgcaBWlzdGlvCioKH3NlcnZpY2UuaXN0aW8uaW8vY2Fub25pY2FsLW5hbWUSBxoFc2xlZXAKLwojc2VydmljZS5pc3Rpby5pby9jYW5vbmljYWwtcmV2aXNpb24SCBoGbGF0ZXN0ChoKB01FU0hfSUQSDxoNY2x1c3Rlci5sb2NhbAogCgROQU1FEhgaFnNsZWVwLTZjNzg3NTQ5OWYteDQ4dzIKFgoJTkFNRVNQQUNFEgkaB2RlZmF1bHQKSQoFT1dORVISQBo+a3ViZXJuZXRlczovL2FwaXMvYXBwcy92MS9uYW1lc3BhY2VzL2RlZmF1bHQvZGVwbG95bWVudHMvc2xlZXAKGgoPU0VSVklDRV9BQ0NPVU5UEgcaBXNsZWVwChgKDVdPUktMT0FEX05BTUUSBxoFc2xlZXA=", 
    "X-Envoy-Peer-Metadata-Id": "sidecar~10.20.16.183~sleep-6c7875499f-x48w2.default~default.svc.cluster.local"
  }
}
```

```
注意由 Istio sidecar 代理添加的 headers: X-Envoy-Decorator-Operation。
```

检查 `SOURCE_POD` 的 sidecar 代理的日志:

```
kubectl logs sleep-6c7875499f-pwvls -c istio-proxy | tail
```



## 安全

### 自动双向TLS

通过一个简化的工作流，展示如何使用双向 TLS。

借助 Istio 的自动双向 TLS 特性，只需配置认证策略即可使用双向 TLS，而无需关注目标规则。

Istio 跟踪迁移到 sidecar 的服务端工作负载，并将客户端 sidecar 配置为自动向这些工作负载发送双向 TLS 流量， 同时将明文流量发送到没有 sidecar 的工作负载。这样可以通过最少的配置，逐步在网格中使用双向 TLS。

*安装 Istio 时，配置 `global.mtls.enabled` 选项为 false，`global.mtls.auto` 选项为 true。 以安装 `demo` 配置文件为例*

```
istioctl manifest apply --set profile=demo \
  --set values.global.mtls.auto=true \
  --set values.global.mtls.enabled=false
```

#### 操作

部署 `httpbin` 服务到 `full`、`partial` 和 `legacy` 三个命名空间中，分别 代表 Istio 迁移的不同阶段。

*命名空间 `full` 包含已完成 Istio 迁移的所有服务器工作负载。 每一个部署都有 Sidecar 注入。*

```
kubectl create ns full
```

```
kubectl apply -f <(istioctl kube-inject -f samples/httpbin/httpbin.yaml) -n full
```

```
kubectl apply -f <(istioctl kube-inject -f samples/sleep/sleep.yaml) -n full
```

*命名空间 `partial` 包含部分迁移到 Istio 的服务器工作负载。 只有完成迁移的服务器工作负载（由于已注入 Sidecar）能够使用双向 TLS 流量。*

```
kubectl create ns partial
```

```
kubectl apply -f <(istioctl kube-inject -f samples/httpbin/httpbin.yaml) -n partial
cat <<EOF | kubectl apply -n partial -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: httpbin-nosidecar
spec:
  replicas: 1
  selector:
    matchLabels:
      app: httpbin
  template:
    metadata:
      labels:
        app: httpbin
        version: nosidecar
    spec:
      containers:
      - image: docker.io/kennethreitz/httpbin
        imagePullPolicy: IfNotPresent
        name: httpbin
        ports:
        - containerPort: 80
EOF
```

*命名空间 `legacy` 中的工作负载，都没有注入 Sidecar。*

```
kubectl create ns legacy
```

```
kubectl apply -f samples/httpbin/httpbin.yaml -n legacy
```

```
kubectl apply -f samples/sleep/sleep.yaml -n legacy
```

*确认在所有命名空间部署完成。*

```
kubectl get pods -n full
kubectl get pods -n partial
kubectl get pods -n legacy
```

打印

```
NAME                      READY   STATUS    RESTARTS   AGE
httpbin-dcd949489-5cndk   2/2     Running   0          39s
sleep-58d6644d44-gb55j    2/2     Running   0          38s
NAME                                READY   STATUS    RESTARTS   AGE
httpbin-64b9b5b5d4-kkkw2            2/2     Running   0          12s
httpbin-nosidecar-cc684fdb4-zbhvx   1/1     Running   0          10s
NAME                       READY   STATUS    RESTARTS   AGE
httpbin-54f5bb4957-lzxlg   1/1     Running   0          6s
sleep-74564b477b-vb6h4     1/1     Running   0          4s
```

验证系统中是否存在默认的网格验证策略，可以参考下面操作：

```
kubectl get policies.authentication.istio.io --all-namespaces
kubectl get meshpolicies -o yaml | grep ' mode'
```

```
NAMESPACE      NAME                          AGE
istio-system   grafana-ports-mtls-disabled   2h
        mode: PERMISSIVE
```

检查 `sleep.full` 到 `httpbin.full` 可达性的命令：

```
kubectl exec $(kubectl get pod -l app=sleep -n full -o jsonpath={.items..metadata.name}) -c sleep -n full -- curl http://httpbin.full:8000/headers  -s  -w "response %{http_code}\n" | egrep -o 'URI\=spiffe.*sa/[a-z]*|response.*$'
```

```
URI=spiffe://cluster.local/ns/full/sa/sleep
response 200
```

SPIFFE URI 显示来自 X509 证书的客户端标识，它表明流量是在双向 TLS 中发送的。 如果流量为明文，将不会显示客户端证书。

#### 从 PERMISSIVE 模式开始

这里，我们从开启网格服务双向 TLS 的 `PERMISSIVE` 模式开始。

1. 所有的 `httpbin.full` 工作负载以及在 `httpbin.partial` 中使用了 Sidecar 的工作负载都能够使用双向 TLS 和明文流量。
2. 命名空间 `httpbin.partial` 中没有 Sidecar 的服务和 `httpbin.legacy` 中的服务都只能使用明文流量。

```
自动双向 TLS 将客户端和 sleep.full 配置为可将双向 TLS 流量发送到具有 Sidecar 的工作负载，明文流量发送到没有 Sidecar 的工作负载。
```

通过以下方式验证可达性：

```
for from in "full" "legacy"; do for to in "full" "partial" "legacy"; do echo "sleep.${from} to httpbin.${to}";kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl http://httpbin.${to}:8000/headers  -s  -w "response code: %{http_code}\n" | egrep -o 'URI\=spiffe.*sa/[a-z]*|response.*$';  echo -n "\n"; done; done
```

#### 使用 Sidecar 迁移

无论工作负载是否带有 Sidecar，对 `httpbin.partial` 的请求都可以到达。 Istio 自动将 `sleep.full` 客户端配置为使用双向 TLS 连接带有 Sidecar 的工作负载。

```
for i in `seq 1 10`; do kubectl exec $(kubectl get pod -l app=sleep -n full -o jsonpath={.items..metadata.name}) -c sleep -nfull  -- curl http://httpbin.partial:8000/headers  -s  -w "response code: %{http_code}\n" | egrep -o 'URI\=spiffe.*sa/[a-z]*|response.*$';  echo -n "\n"; done
```

如果不使用自动双向 TLS，您必须跟踪 Sidecar 迁移完成情况，然后显式的配置目标规则，使客户端发送双向 TLS 流量到 `httpbin.full`。

#### 锁定双向 TLS 为 STRICT 模式

您可配置认证策略为 `STRICT`，以锁定 `httpbin.full` 服务仅接收双向 TLS 流量。

```
cat <<EOF | kubectl apply -n full -f -
apiVersion: "authentication.istio.io/v1alpha1"
kind: "Policy"
metadata:
  name: "httpbin"
spec:
  targets:
  - name: httpbin
  peers:
  - mtls: {}
EOF
```

所有 `httpbin.full` 工作负载和带有 Sidecar 的 `httpbin.partial` 都只可使用双向 TLS 流量。

现在来自 `sleep.legacy` 的请求将开始失败，因为其不支持发送双向 TLS 流量。 但是客户端 `sleep.full` 的请求将仍可成功返回 200 状态码，因为它已配置为自动双向 TLS，并且发送双向 TLS 请求。

```
for from in "full" "legacy"; do for to in "full" "partial" "legacy"; do echo "sleep.${from} to httpbin.${to}";kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl http://httpbin.${to}:8000/headers  -s  -w "response code: %{http_code}\n" | egrep -o 'URI\=spiffe.*sa/[a-z]*|response.*$';  echo -n "\n"; done; done
```

#### 禁用双向 TLS 以启用明文传输

如果出于某种原因，您希望服务显式地处于明文模式，则可以将身份验证策略配置为明文。

```
cat <<EOF | kubectl apply -n full -f -
apiVersion: "authentication.istio.io/v1alpha1"
kind: "Policy"
metadata:
  name: "httpbin"
spec:
  targets:
  - name: httpbin
EOF
```

在这种情况下，由于服务处于纯文本模式。Istio 自动配置客户端 Sidecar 发送明文流量以避免错误。

```
for from in "full" "legacy"; do for to in "full" "partial" "legacy"; do echo "sleep.${from} to httpbin.${to}";kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl http://httpbin.${to}:8000/headers  -s  -w "response code: %{http_code}\n" | egrep -o 'URI\=spiffe.*sa/[a-z]*|response.*$';  echo -n "\n"; done; done
```

现在，所有流量都可以明文传输。

#### 重写目标规则

为了向后兼容，您仍然可以像以前一样使用目标规则来覆盖 TLS 配置。当目标规则具有显式 TLS 配置时，它将覆盖 Sidecar 客户端的 TLS 配置。

例如，您可以显式的为 `httpbin.full` 配置目标规则，以显式启用或禁用双向 TLS。

```
cat <<EOF | kubectl apply -n full -f -
apiVersion: "networking.istio.io/v1alpha3"
kind: "DestinationRule"
metadata:
  name: "httpbin-full-mtls"
spec:
  host: httpbin.full.svc.cluster.local
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
EOF
```

由于在前面的步骤中，我们已经禁用了 `httpbin.full` 的身份验证策略，以禁用双向 TLS，现在应该看到来自 `sleep.full` 的流量开始失败。

```
for from in "full" "legacy"; do for to in "full" "partial" "legacy"; do echo "sleep.${from} to httpbin.${to}";kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl http://httpbin.${to}:8000/headers  -s  -w "response code: %{http_code}\n" | egrep -o 'URI\=spiffe.*sa/[a-z]*|response.*$';  echo -n "\n"; done; done
```



***未完待续***



## 策略[开启policy]

```
istioctl manifest apply --set addonComponents.grafana.enabled=true --set components.citadel.enabled=true --set components.policy.enabled=true --set values.global.disablePolicyChecks=false --set values.pilot.policy.enabled=true 
```

### 启用策略检查功能

在默认的 Istio 安装配置中，策略检查功能是关闭的。若要开启策略检查功能，需在安装选项中加入`--set values.global.disablePolicyChecks=false` 和 `--set values.pilot.policy.enabled=true`。

对于已经安装的 Istio 网格

*检查该网格中策略检查功能的状态。*

```
kubectl -n istio-system get cm istio -o jsonpath="{@.data.mesh}" | grep disablePolicyChecks
```

打印

```
disablePolicyChecks: true
```

```
如果策略检查功能已开启（disablePolicyChecks置为 false），则无需再做什么。
```

修改 `istio` configuration，开启策略检查功能。

```
istioctl manifest apply --set values.global.disablePolicyChecks=false
```

验证策略检查功能是否已启用。

```
kubectl -n istio-system get cm istio -o jsonpath="{@.data.mesh}" | grep disablePolicyChecks
```

打印

```
disablePolicyChecks: false
```



### 启用速率限制

部署 Bookinfo 示例应用。

Bookinfo 部署了 3 个版本的 reviews 服务：

版本 v1 不会调用 ratings 服务。
版本 v2 调用 ratings 服务，且为每个评价显示 1 到 5 颗黑色星星。
版本 v3 调用 ratings 服务，且为每个评价显示 1 到 5 颗红色星星。
您需要指定其中一个版本为默认路由。否则，当您向 reviews 服务发送请求时，Istio 会随机路由到其中一个服务上，表现为有时显示星星，有时不会。

将所有服务的默认版本设置为 v1。

```
kubectl apply -f samples/bookinfo/networking/virtual-service-all-v1.yaml
```

#### 速率限制

在这部分，Istio 将以客户端的 IP 地址限制 `productpage` 的流量。 您将会使用 `X-Forwarded-For` 请求头作为客户端 IP 地址。也将会针对已登录的用户应用有条件的速率限制。

方便起见，配置 memory quota(`memquota`) 适配器用以启用速率限制。 如果在生产系统使用的是 Redis，那么启用 Redis quota(`redisquota`) 适配器。`memquota` 与 `redisquota` 适配器都支持 quota template， 所以他们的配置是一样的。

1. 速率限制的配置分为两部分。

   - 客户端
     - `QuotaSpec` 定义 quota 名称与客户端请求的数量。
     - `QuotaSpecBinding` 条件化的关联 `QuotaSpec` 到一个或多个服务。
   - Mixer 端
     - `quota instance` 定义 quota 的维度。
     - `memquota handler` 定义 `memquota` 适配器的配置。
     - `quota rule` 定义 quota 实例何时分发到 `memquota` 适配器。

   执行如下命令使用 `memquota` 开启速率限制：

   ```
   kubectl apply -f samples/bookinfo/policy/mixer-rule-productpage-ratelimit.yaml
   ```

   `memquota` 处理器定义了 4 个不同的速率限制规则。默认如果没有匹配到优先规则，是 `500` 个请求量每秒 (`1s`)。 我们也定义了两个优先规则：

   - 第一种是 `1` 个请求量 (`maxAmount` 字段) 每 `5s` (`validDuration` 字段)，如果`目标服务`是 `reviews`。
   - 第二种是 `500` 个请求量每 `1s`，如果`目标服务`是 `productpage` 且来源于 `10.28.11.20`。
   - 第三种是 `2` 个请求量每 `5s`，如果`目标服务`是 `productpage`。

   当一个请求被处理时，第一个被匹配到的优先规则会被触发(从上到下)。

   或者

   执行如下命令使用 `redisquota` 开启流量限制：

   ```
   kubectl apply -f samples/bookinfo/policy/mixer-rule-productpage-redis-quota-rolling-window.yaml
   ```

   注意: 替换您的配置中 rate_limit_algorithm， redis_server_url 的值.

   `redisquota` 处理器定义了 4 个不同的速率限制规则。默认如果没有匹配到优先规则，是 `500` 个请求量每秒 (`1s`)。 使用了 `ROLLING_WINDOW` 算法作为 quota 检查且为之定义了 500ms 的 `bucketDuration`。我们也定义了三个优先规则：

   - 第一种是 `1` 个请求量 (`maxAmount` 字段)，如果`目标服务`是 `reviews`。
   - 第二种是 `500`，如果`目标服务`是 `productpage` 且来源于 `10.28.11.20`。
   - 第三种是 `2`，如果`目标服务`是 `productpage`。

   当一个请求被处理时，第一个被匹配到的优先规则会被触发(从上到下)。

2. 确认 `quota 实例`已被创建：

   ```
   kubectl -n istio-system get instance requestcountquota -o yaml
   ```

   quota 模板通过 memquota 或 redisquota 定义了三个维度以匹配特定的属性的方式设置优先规则。 目标服务会被设置为 destination.labels["app"]，destination.service.host，或 "unknown" 中的第一个非空值。

3. 确认 `quota rule` 已被创建：

   ```
   kubectl -n istio-system get rule quota -o yaml
   ```

   `rule` 告诉 Mixer 去调用 `memquota` 或 `redisquota` 处理器（上面创建的）且传递 `requestcountquota` 构造的对象（也是上面创建的）。 这里将 `quota` 模板与 `memquota` 或 `redisquota` 处理器的维度一一对应。

4. 确认 `QuotaSpec` 已被创建：

   ```
   kubectl -n istio-system get QuotaSpec request-count -o yaml
   ```

   QuotaSpec` 用值 `1` 定义了您上面创建的 `requestcountquota`。

5. 确认 `QuotaSpecBinding` 已被创建：

   ```
   kubectl -n istio-system get QuotaSpecBinding request-count -o yaml
   ```

   `QuotaSpecBinding` 绑定了您上面创建的 `QuotaSpec` 与您想要生效的服务。`productpage` 显式的绑定了 `request-count`， 注意您必须定义与 `QuotaSpecBinding` 不同的命名空间。 如果最后一行注释被打开， `service: '*'` 将绑定所有服务到 `QuotaSpec` 使得首个 entry 是冗余的。

6. 在浏览器上刷新 product 页面。

   `request-count` quota 应用于 `productpage` 且只允许 2 个请求量每 5 秒。如果您持续刷新页面将会看到 `RESOURCE_EXHAUSTED:Quota is exhausted for: requestcount`。

#### 条件化的速率限制

在上面的例子我们为每个客户端 IP 地址的 `productpage` 限制了 `2 rps`。 考虑这样一个场景，如果您想要对已登录的用户放开速率限制。在 `bookinfo` 的例子中，我们用 cookie `session=<sessionid>` 去指代一个已登录用户。 在现实场景中您可能会用 `jwt` token 去实现这个目的。

您可以添加基于 `cookie` 的匹配条件更新 `quota rule`。

```
kubectl -n istio-system edit rules quota
```

添加

```
...
spec:
  match: match(request.headers["cookie"], "session=*") == false
  actions:
...
```

`memquota` 或 `redisquota` 适配器现在只有请求中存在 `session=<sessionid>` cookie 才会被分发。 这可以确保已登录的用户不会受限于这个 quota。

1. 确认速率限制没有生效于已登录的用户。

   以 `jason` 身份登录且反复刷新 `productpage` 页面。现在这样做不会出现任何问题。

2. 确认速率限制 *生效* 于未登录的用户。

   退出登录且反复刷新 `productpage` 页面。 您将会再次看到 `RESOURCE_EXHAUSTED:Quota is exhausted for: requestcount`。

### 请求头和路由控制

httpbin 服务定义一个包含两条路由规则的 virtual service，以接收来自路径 /headers 和 /status 的请求：

```
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: httpbin
spec:
  hosts:
  - "*"
  gateways:
  - httpbin-gateway
  http:
  - match:
    - uri:
        prefix: /headers
    - uri:
        prefix: /status
    route:
    - destination:
        port:
          number: 8000
        host: httpbin
EOF
```

#### Output-producing adapters

使用名为 `keyval` 的策略适配器。除输出策略检查结果之外， 此适配器还返回一个包含 `value` 字段的输出。适配器上配置有一个查找表，用于填充输出值， 或者在查找表中不存在输入实例键时返回 `NOT_FOUND` 错误状态。

部署演示适配器：

```
kubectl run keyval --image=gcr.io/istio-testing/keyval:release-1.1 --namespace istio-system --port 9070 --expose
```

通过模板和配置描述启用 `keyval` 适配器：

```
kubectl apply -f samples/httpbin/policy/keyval-template.yaml
kubectl apply -f samples/httpbin/policy/keyval.yaml
```

使用固定的查找表为演示适配器创建一个 Handler：

```
kubectl apply -f - <<EOF
apiVersion: config.istio.io/v1alpha2
kind: handler
metadata:
  name: keyval
  namespace: istio-system
spec:
  adapter: keyval
  connection:
    address: keyval:9070
  params:
    table:
      jason: admin
EOF
```

使用 `user` 请求头作为查找键，为 Handler 创建一个 Instance：

```
kubectl apply -f - <<EOF
apiVersion: config.istio.io/v1alpha2
kind: instance
metadata:
  name: keyval
  namespace: istio-system
spec:
  template: keyval
  params:
    key: request.headers["user"] | ""
EOF
```

#### 请求头操作

确保 *httpbin* 服务可以通过 ingress gateway 正常访问：

```
curl http://$INGRESS_HOST:$INGRESS_PORT/headers
```

输出应该是 *httpbin* 服务接收到的请求头。

```
{
  "headers": {
    "Accept": "*/*",
    "Content-Length": "0",
    ...
    "X-Envoy-Internal": "true"
  }
}
```

为演示适配器创建 Rule：

```
kubectl apply -f - <<EOF
apiVersion: config.istio.io/v1alpha2
kind: rule
metadata:
  name: keyval
  namespace: istio-system
spec:
  actions:
  - handler: keyval.istio-system
    instances: [ keyval ]
    name: x
  requestHeaderOperations:
  - name: user-group
    values: [ x.output.value ]
EOF
```

向入口网关发出新请求，将请求 `key` 设置为值 `jason`：

```
curl -Huser:jason http://$INGRESS_HOST:$INGRESS_PORT/headers
```

打印

```
{
  "headers": {
    "Accept": "*/*",
    "Content-Length": "0",
    "User": "jason",
    "User-Agent": "curl/7.58.0",
    "User-Group": "admin",
    ...
    "X-Envoy-Internal": "true"
  }
}
```

请注意 `user-group` 标头，该标头派生自适配器的 Rule 定义，Rule 中表达式 `x.output.value` 的取值结果为适配器 `keyval` 返回值的 `value` 字段。

如果匹配成功，则修改 Rule 规则，重写 URI 路径到其他 Virtual service 路由：

```
kubectl apply -f - <<EOF
apiVersion: config.istio.io/v1alpha2
kind: rule
metadata:
  name: keyval
  namespace: istio-system
spec:
  match: source.labels["istio"] == "ingressgateway"
  actions:
  - handler: keyval.istio-system
    instances: [ keyval ]
  requestHeaderOperations:
  - name: :path
    values: [ '"/status/418"' ]
EOF
```

再次向 ingress gateway 发送请求：

```
curl -Huser:jason -I http://$INGRESS_HOST:$INGRESS_PORT/headers
```

打印

```
HTTP/1.1 418 Unknown
server: istio-envoy
...
```

请注意，在策略适配器的规则应用 _之后_，ingress gateway 更改了路由。修改后的请求可能使用不同的路由和目的地，并受流量管理配置的约束。

同一代理内的策略引擎不会再次检查已修改的请求。因此，我们建议在网关中使用此功能，以便服务器端策略检查生效。

### Denials 和黑白名单

- 部署 Bookinfo 样例应用。

- 初始化直接访问 `reviews` 服务的应用程序的版本路由请求，对于测试用户 “jason” 的请求直接指定到 v2 版本，其他用户的请求指定到 v3 版本。

  ```
  kubectl apply -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
  ```

  然后执行以下命令：

  ```
  kubectl apply -f @samples/bookinfo/networking/virtual-service-reviews-jason-v2-v3.yaml@
  ```

  

  如果您使用的 namespace 不是 `default`，使用 `kubectl -n namespace ...` 来指明该 namespace。

#### 简单的 *denials*

通过 Istio 您可以根据 Mixer 中可用的任意属性来控制对服务的访问。 这种简单形式的访问控制是基于 Mixer 选择器的条件拒绝请求功能实现的。

考虑 Bookinfo 示例应用，其中 `ratings` 服务可通过 `reviews` 服务的多个版本进行访问。 我们想切断对 `reviews` 服务 `v3` 版本的访问

1. 将浏览器定位到 Bookinfo `productpage` (`http://$GATEWAY_URL/productpage`)。

   如果您以 “jason” 用户身份登录，则每个评论都应看到黑色的星标， 它表示 `ratings` 服务是通过 “v2” 版本 `reviews` 服务访问到的。

   如果您以其他任何用户身份登录（或登出），则每个评论都应看到红色的星标， 它表示 `ratings` 服务是通过 “v3” 版本 `reviews` 服务访问到的。

2. 要想明确地拒绝对 `v3` 版本 `reviews` 服务的访问。

   连同处理程序和实例，执行以下命令来配置拒绝规则。

   ```
   kubectl apply -f samples/bookinfo/policy/mixer-rule-deny-label.yaml
   ```

   注意 `denyreviewsv3` 规则的以下部分：

   ```plain
   match: destination.labels["app"] == "ratings" && source.labels["app"]=="reviews" && source.labels["version"] == "v3"
   ```

   它将带有 `v3` 标签的 `reviews` 工作负载请求与 `ratings` 工作负载进行匹配。

   该规则通过使用 `denier` 适配器来拒绝 `v3` 版本 reviews 服务的请求。 适配器始终拒绝带有预配置状态码和消息的请求。 状态码和消息在 denier 适配器配置中指定。

3. 在浏览器里刷新 `productpage`。

   如果您已登出或以非 “json” 用户登录，因为`v3 reviews` 服务已经被拒绝访问 `ratings` 服务，所以您不会再看到红色星标。 相反，如果您以 “json” 用户（`v2 reviews 服务` 用户）登录，可以一直看到黑色星标。

#### 基于属性的 *白名单* 或 *黑名单*

Istio 支持基于属性的白名单和黑名单。 以下白名单配置等同于上一节的 `denier` 配置。 此规则能有效地拒绝 `v3` 版本 `reviews` 服务的请求。

1. 移除上一节 denier 配置。

   ```
   kubectl delete -f samples/bookinfo/policy/mixer-rule-deny-label.yaml
   ```

2. 当您不登录去访问 Bookinfo `productpage` (`http://$GATEWAY_URL/productpage`) 时进行验证，会看到红星。 再执行以下步骤之后，除非您以 “json” 用户登录，否则不会看到星标。

3. 将配置应用于 [`list`] 适配器以让 `v1， v2` 版本位于白名单中；

   ```
   kubectl apply -f samples/bookinfo/policy/mixer-rule-deny-whitelist.yam
   ```

4. 当您不登录去访问 Bookinfo `productpage` (`http://$GATEWAY_URL/productpage`) 时进行验证，**不会**看到星标。 以 “jason” 用户登录后验证，您会看到黑色星标。

#### 基于 IP 的 *白名单* 或 *黑名单*

Istio 支持基于 IP 地址的 *白名单* 和 *黑名单* 。 您可以配置 Istio 接受或拒绝从一个 IP 地址或一个子网发出的请求。

1. 您可以访问位于 `http://$GATEWAY_URL/productpage` 的 Bookinfo `productpage` 来进行验证。 一旦应用以下规则，您将无法访问它。

2. 将配置应用于 [`list`] 适配器以添加 ingress 网关中的子网 `"10.57.0.0\16"` 到白名单中：

   ```
   kubectl apply -f samples/bookinfo/policy/mixer-rule-deny-ip.yaml
   ```

3. 试访问位于 `http://$GATEWAY_URL/productpage` 的 Bookinfo `productpage` 进行验证， 您会获得一个类似的错误：`PERMISSION_DENIED:staticversion.istio-system:<your mesh source ip> is not whitelisted`



## 可观察性

开启遥测

```
kubectl apply -f - <<EOF
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  components:
    telemetry:
      enabled: true
EOF
```

### 指标度量

#### 采集指标

假定 Mixer 已经用默认配置（`--configDefaultNamespace=istio-system`）设置好了。如果您使用的不同的值，请更新本任务中的配置和命令以匹配该值。

##### 应用配置新指标的 YAML 文件，该指标将由 Istio 自动生成和采集

```
kubectl apply -f samples/bookinfo/telemetry/metrics.yaml
```

##### 发送流量到示例应用

对于 Bookinfo 示例，从浏览器访问 `http://$GATEWAY_URL/productpage` 或使用下列命令：

```
curl http://202.107.190.8:10385/productpage
```

##### 确认新的指标已被生成并采集

对于 Kubernetes 环境，执行以下命令为 Prometheus 设置端口转发：

```
kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=prometheus -o jsonpath='{.items[0].metadata.name}') 9090:9090 &
```

通过 [Prometheus UI] 查看新指标的值。

上述链接打开 Prometheus UI 并执行对 `istio_double_request_count` 指标值的查询语句。 **Console** 选项卡中显示的表格包括了一些类似如下的条目：

```
istio_double_request_count{destination="details-v1",instance="172.17.0.12:42422",job="istio-mesh",message="twice the fun!",reporter="client",source="productpage-v1"}   8
istio_double_request_count{destination="details-v1",instance="172.17.0.12:42422",job="istio-mesh",message="twice the fun!",reporter="server",source="productpage-v1"}   8
istio_double_request_count{destination="istio-policy",instance="172.17.0.12:42422",job="istio-mesh",message="twice the fun!",reporter="server",source="details-v1"}   4
istio_double_request_count{destination="istio-policy",instance="172.17.0.12:42422",job="istio-mesh",message="twice the fun!",reporter="server",source="istio-ingressgateway"}   4
```











