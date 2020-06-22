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
helm template istio install/kubernetes/helm/istio --namespace istio-system --set gateways.istio-ingressgateway.type=NodePort --set grafana.enabled=true --set kiali.enabled=true --set tracing.enabled=true | kubectl apply -f - 
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
kubectl label namespace test istio-injection=enabled
```

#### 部署

```
kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml -n test
```

确认 Bookinfo 应用是否正在运行

```
kubectl -n test exec -it $(kubectl get pod -n test -l app=ratings -o jsonpath='{.items[0].metadata.name}') -c ratings -- curl productpage:9080/productpage | grep -o "<title>.*</title>"
```

打印

```
<title>Simple Bookstore App</title>
```

#### 创建网关和虚拟路由

```
kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml -n test
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





## 配置TLS网关

### 创建TLS挂载

```
kubectl create -n istio-system secret tls istio-ingressgateway-certs --key 2017585_www.xjlhcz.com.key --cert 2017585_www.xjlhcz.com.pem
```

#### 查看是否被挂载

```
kubectl exec -it -n istio-system $(kubectl -n istio-system get pods -l istio=ingressgateway -o jsonpath='{.items[0].metadata.name}') -- ls -al /etc/istio/ingressgateway-certs
```

### 创建网关

```
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
      # serverCertificate: /etc/istio/ingressgateway-certs/2017585_www.xjlhcz.com.pem
      # privateKey: /etc/istio/ingressgateway-certs/2017585_www.xjlhcz.com.key
      # caCertificates: /etc/istio/ingressgateway-ca-certs/2017585_www.xjlhcz.com.pem
    hosts:
    # - "www.xjlhcz.com"
    - "*"
```

### 配置路由

```
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: httpbin
spec:
  hosts:
  # - "www.xjlhcz.com"
  - "*"
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
```

访问测试

```
curl -I https://www.xjlhcz.com:10723/status/200
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

## 流量控制

***具体流程：***

Gateway => VS => DestinationRule => Kubernetes-Service => Pod

如果DestinationRule没被创建则VS会去直接拿匹配的Kubernetes Service

### 创建Gateway

```
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: bookinfo-gateway
spec:
  selector:
    istio: ingressgateway # use istio default controller
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "*"
```

### 创建VirtualService

```
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: bookinfo
spec:
  hosts:
  - "*"
  gateways:
  - bookinfo-gateway
  http:
  - match:
    - uri:
        exact: /productpage
    - uri:
        prefix: /static
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
```

### 创建DestinetionRule

```
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: productpage
spec:
  host: productpage
  subsets:
  - name: v1
    labels:
      version: v1
---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: reviews
spec:
  host: reviews
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
  - name: v3
    labels:
      version: v3
---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: ratings
spec:
  host: ratings
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
  - name: v2-mysql
    labels:
      version: v2-mysql
  - name: v2-mysql-vm
    labels:
      version: v2-mysql-vm
---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: details
spec:
  host: details
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
```

### 进阶

#### VirtualService:

```
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
        subset: v3
```

**hosts**: 

 用来配置下游访问的可寻址地址。配置一个 String[] 类型的值，可以配置多个。指定了发送流量的目标主机， 可以使用FQDN（Fully Qualified Domain Name - 全限定域名）或者短域名， 也可以一个前缀匹配的域名格式或者一个具体的IP地址。

**match：**

 这部分用来配置路由规则，通常情况下配置一组路由规则，当请求到来时，自上而下依次进行匹配，直到匹配成功后跳出匹配。它可以对请求的 uri、method、authority、headers、port、queryParams 以及是否对 uri 大小写敏感等进行配置。

**route：**

 用来配置路由转发目标规则，可以指定需要访问的 subset （服务子集），同时可以对请求权重进行设置、对请求头、响应头中数据进行增删改等操作。subset （服务子集）是指同源服务而不同版本的 [Pod]，通常在 Deployment 资源中设置不同的 label 来标识。

以上配置表示 ：当访问 reviews 服务时，如果请求标头中存在`end-user:jason`这样的键值对则转发到 `v2` 版本的 reviews 服务子集中，其他的请求则转发到 `v3` 版本的 reviews 服务子集中。

**补充：**在 Istio 1.5 中，VirtualService 资源之间是无法进行转发的，在 Istio 1.6版本中规划了 VirtualService Chain 机制，也就是说，我们可以通过 delegate 配置项将一个 VirtualService 代理到另外一个 VirtualService 中进行规则匹配。

##### 流量转移[权重分流]

```
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

```
v1和v3版本的两个服务各自占取50%流量
```









```
kubectl exec -it -n istio-system $(kubectl -n istio-system get pods -l istio=ingressgateway -o jsonpath='{.items[0].metadata.name}') -- ls -al /etc/istio/ingressgateway-certs
```

```
openssl req -out 2017585_www.xjlhcz.com.pem -newkey rsa:2048 -nodes -keyout httpbin-client.example.com.key -subj "/CN=httpbin-client.example.com/O=httpbin's client organization"


openssl x509 -req -days 365 -CA example.com.crt -CAkey example.com.key -set_serial 0 -in httpbin-client.example.com.csr -out httpbin-client.example.com.crt

```





```
https://istio.io/latest/zh/docs/tasks/traffic-management/request-routing/
```

```
https://www.servicemesher.com/istio-handbook/practice/route.html
```

