# Knative使用



## Knative各组件:

### Service: activator

The activator is responsible for receiving & buffering requests for inactive revisions and reporting metrics to the autoscaler. It also retries requests to a revision after the autoscaler scales the revision based on the reported metrics.

```
activator负责接收和缓冲非活动修订[revisions]的请求，并向autoscaler报告指标。autoscaler根据报告的指标缩放修订版本后，它还会重试对修订的请求。
```

### Service: autoscaler

The autoscaler receives request metrics and adjusts the number of pods required to handle the load of traffic.

```
autoscaler接收请求指标并调整处理流量负载所需的Pod数量。
```

### Service: controller

The controller service reconciles all the public Knative objects and autoscaling CRDs. When a user applies a Knative service to the Kubernetes API, this creates the configuration and route. It will convert the configuration into revisions and the revisions into deployments and Knative Pod Autoscalers (KPAs).

```
controller协调所有公共Knative对象和自动缩放CRD。当用户向Kubernetes API应用Knative服务时，这将创建配置和路由。它将配置转换为修订版，并将修订转换为部署和Knative Pod自动缩放器（KPA）。
```

### Service: webhook

The webhook intercepts all Kubernetes API calls as well as all CRD insertions and updates. It sets default values, rejects inconsitent and invalid objects, and validates and mutates Kubernetes API calls.

```
Webhook拦截所有Kubernetes API调用以及所有CRD插入和更新。它设置默认值，拒绝不一致和无效的对象，并验证和更改Kubernetes API调用。
```

### Deployment: networking-certmanager

The certmanager reconciles cluster ingresses into cert manager objects.

```
证书管理器将群集入口协调为证书管理器对象。
```

### Deployment: networking-istio

The networking-istio deployment reconciles a cluster's ingress into an [Istio virtual service]

```
基于网络的部署可协调群集进入 Istio虚拟服务的过程。
```



## 部署服务

### 创建一个名为的新文件`service.yaml`

```
apiVersion: serving.knative.dev/v1 # Current version of Knative
kind: Service
metadata:
  name: helloworld-go # The name of the app
  namespace: default # The namespace the app will use
spec:
  template:
    spec:
      containers:
        # - image: gcr.io/knative-samples/helloworld-go # The URL to the image of the app
        - image: hatchin/knative-helloworld
          env:
            - name: TARGET # The environment variable printed out by the sample app
              value: "Go Sample v1"

```

### 部署

```
kubectl apply --filename service.yaml
```

### 查看

```
kubectl get ksvc
```

打印

```
NAME            URL                                           LATESTCREATED         LATESTREADY           READY   REASON
helloworld-go   http://helloworld-go.default.www.xjlhcz.com   helloworld-go-zpxvx   helloworld-go-zpxvx   True    
```

### 测试

```
curl http://helloworld-go.default.www.xjlhcz.com
```

#### 实际测试[需要添加header]

```
curl -HHost:helloworld-go.default.xjlhcz.com http://192.168.240.121:31380
```

注：

*一段时间未访问会发现服务副本为0，原因是autoscala的作用。*

### 生产环境部署

```
Knative Serving 始于 Configuration。可以在 Configuration 中为部署定义所需的状态。最小化 Configuration 至少包括一个配置名称和一个要部署容器镜像的引用。在 Knative 中，定义的引用为 Revision。Revision 代表一个不变的，某一时刻的代码和 Configuration 的快照。每个 Revision 引用一个特定的容器镜像和运行它所需要的任何特定对象（例如环境变量和卷）。然而，不必显式创建 Revision。由于 Revision 是不变的，它们从不会被改变和删除，相反，当修改 Configuration 的时候，Knative 会创建一个 Revision。这允许一个 Configuration 既反映工作负载的当前状态，同时也维护一个它自己的历史 Revision 列表。
```

#### *configuration*

```
vi configuration.yaml
```

```
apiVersion: serving.knative.dev/v1alpha1
kind: Configuration
metadata:
  name: knative-helloworld
  namespace: default
spec:
  revisionTemplate:
    spec:
      container:
        image: docker.io/gswk/knative-helloworld:latest
        env:
          - name: MESSAGE
            value: "Knative!"
        ports:
          - containerPort: 8081
          # Knative 默认监听 8080 端口。可以通过 containerPort 参数自定义一个端口
```

```
kubectl apply -f configuration.yaml
```

#### 查看Revision

```
kubectl get revisions
```

#### 查看Configuration

```
kubectl get configurations
```

#### Route（路由）

```
vi route.yml
```

```
apiVersion: serving.knative.dev/v1alpha1
kind: Route
metadata:
  name: knative-helloworld
  namespace: default
spec:
  traffic:
  - configurationName: knative-helloworld
percent: 100
```

就像我们对 Configuration 所做的那样，我们可以运行一个简单的命令应用该 YAML 文件：

```bash
kubectl apply -f route.yaml
Copy
```

这个定义中，Route 发送 100% 流量到由 `configurationName` 属性指定 Configuration 的最新就绪 Revision，该 Revision 由 Configuration YAML 中 `latestReadyRevisionName` 属性定义。您可以通过发送如下 `curl` 命令来测试这些 Route 和 Configuration ：

```bash
curl -H "Host: knative-routing-demo.default.example.com"
http://$KNATIVE_INGRESS
Copy
```

通过使用 `revisionName` 替代 `latestReadyRevisionName` ，您可以锁定一个 Route 以发送流量到一个指定的 Revision。使用 `name` 属性，您也可以通过可寻址子域名访问 Revision。[例 2-5](https://www.servicemesher.com/getting-started-with-knative/serving.html#example-2-5) 同时展示两种场景。

*例 2-5. knative-routing-demo/route.yml*

```yaml
apiVersion: serving.knative.dev/v1alpha1
kind: Route
metadata:
  name: knative-routing-demo
  namespace: default
spec:
  traffic:
  - revisionName: knative-routing-demo-00001
    name: v1
    percent: 100
Copy
```

我们可以再一次使用简单命令应用该 YAML 文件：

```bash
kubectl apply -f route.yaml
Copy
```

指定的 Revision 可以使用 `v1` 子域名访问，如下 `curl` 命令所示：

```bash
curl -H "Host: v1.knative-routing-demo.default.example.com"
http://$KNATIVE_INGRESS
Copy
```

> **提醒**
>
> Knative 默认使用 `example.com` 域名，但不适合生产使用。您会注意到在 `curl` 命令（v1.knative-routing-demo.default.example.com）中作为一个主机头传递的 URL 包含该默认值作为域名后缀。URL 格式遵循模式 `{REVISION_NAME}.{SERVICE_NAME}.{NAMESPACE}.{DOMAIN}` 。

Knative 也允许以百分比的方式跨 Revision 进行流量分配。支持诸如增量发布、蓝绿部署或者其他复杂的路由场景。

注:

```
Ksvc包含Route、Revisions、Configurations，后三者均为创建Ksvc时被自动创建

Configurations包含Kubernetes的Deployment及其下面的Replicaset和Pod，创建configurations时即是对Kubernetes创建资源
```

```
https://www.servicemesher.com/getting-started-with-knative/using-knative.html
```



## 访问日志

安装日志记录和监视组件[Elasticsearch和kibana和Fluentd]

```
https://knative.dev/docs/serving/accessing-logs/
```

### 开启代理访问

```
kubectl proxy --address='0.0.0.0'  --accept-hosts='^*$' -p 30009 
```

### 进入Kibana

```
http://202.107.190.8:10724/api/v1/namespaces/knative-monitoring/services/kibana-logging/proxy/app/kibana#/management/kibana/
```



## 访问度量

通过[Grafana] UI 访问指标。Grafana是[Prometheus]的可视化工具。

### 进入grafana

```
kubectl port-forward --namespace knative-monitoring \
$(kubectl get pods --namespace knative-monitoring \
--selector=app=grafana --output=jsonpath="{.items..metadata.name}") \
3000
```

- 这将在端口3000上启动Grafana的本地代理。出于安全原因，Grafana UI仅在群集中公开。

- **Revision HTTP Requests:** HTTP request count, latency, and size metrics per revision and per configuration

- ```
  每个修订版和每个配置的HTTP请求计数，延迟和大小指标
  ```

- **Nodes:** CPU, memory, network, and disk metrics at node level

- ```
  节点级别的CPU，内存，网络和磁盘指标
  ```

- **Pods:** CPU, memory, and network metrics at pod level

- ```
  POD级别的CPU，存储器，以及网络度量
  ```

- **Deployment:** CPU, memory, and network metrics aggregated at deployment level

- ```
  部署级别的汇总的CPU，内存和网络指标
  ```

- **Istio, Mixer and Pilot:** Detailed Istio mesh, Mixer, and Pilot metrics

- ```
  Istio网格，Mixer和Pilot指标
  ```

- **Kubernetes:** Dashboards giving insights into cluster health, deployments, and capacity usage

- ```
  仪表板可深入了解集群运行状况，部署和容量使用情况
  ```

### 账号密码

管理员帐户username：`admin` 和 password：`admin`。



## 访问请求跟踪

### 开启访问代理

```
kubectl proxy --address='0.0.0.0'  --accept-hosts='^*$' -p 30009 
```

### 进入页面

```
http://202.107.190.8:10724/api/v1/namespaces/istio-system/services/zipkin:9411/proxy/zipkin/
```



## Configuring autoscaling[配置自动缩放]

```
https://knative.dev/docs/serving/configuring-autoscaling/
```

serverless平台的主要特性之一是它们能够扩展应用程序以紧密匹配其传入需求的能力。这就需要观察负载流入应用程序时的负载，并根据各自的指标调整规模。精确地做到这一点是Knative Serving的自动缩放组件[autoscaling component]的工作。

Knative Serving带有自己的自动缩放器**KPA**（Knative Pod自动缩放器），但也可以配置为使用Kubernetes的**HPA**（Horizontal Pod自动缩放器）甚至是自定义的第三方自动缩放器。

Knative Serving Revisions附带自动缩放功能，该缩放功能已预先配置为默认值，并且已被证明可用于各种用例。但是，某些工作负载需要一种更精细的方法。可以以调节自动缩放器以适应工作负载的要求。

### Autoscaler 机制

```
Knative Serving 为每个 POD 注入 QUEUE 代理容器 (queue-proxy)，该容器负责向 Autoscaler 报告用户容器并发指标。Autoscaler 接收到这些指标之后，会根据并发请求数及相应的算法，调整 Deployment 的 POD 数量，从而实现自动扩缩容。
```

Autoscaler 基于每个 POD 的平均请求数（并发数）进行扩所容处理。默认并发数为 100。<br />POD 数=并发请求总数/容器并发数

如果服务中并发数设置了 10，这时候如果加载了 50 个并发请求的服务，Autoscaler 就会创建了 5 个 POD （50 个并发请求/10=POD）。

Autoscaler 实现了两种操作模式的缩放算法：Stable（稳定模式）和 Panic（恐慌模式）。

#### 稳定模式

在稳定模式下，Autoscaler 调整 Deployment 的大小，以实现每个 POD 所需的平均并发数。 POD 的并发数是根据 60 秒窗口内接收所有数据请求的平均数来计算得出。

#### 恐慌模式

Autoscaler 计算 60 秒窗口内的平均并发数，系统需要 1 分钟稳定在所需的并发级别。但是，Autoscaler 也会计算 6 秒的恐慌窗口，如果该窗口达到目标并发的 2 倍，则会进入恐慌模式。在恐慌模式下，Autoscaler 在更短、更敏感的紧急窗口上工作。一旦紧急情况持续 60 秒后，Autoscaler 将返回初始的 60 秒稳定窗口。

### 全局与每次修订设置

#### 全剧设定[configmap]

##### 查看configmap

```
kubectl -n knative-serving get cm config-autoscaler
```

上述内容全部为默认配置

```
apiVersion: v1
kind: ConfigMap
metadata:
 name: config-autoscaler
 namespace: knative-serving
data:

 # 配置的并发 target 为 100。
 container-concurrency-target-default: 100
 
 # 通过目标利用率值来调整副本数。此值指定自动定标器实际确定目标的百分比。
 # 实际上，这指定了副本运行时的“热度”，这会导致自动缩放器在达到总限制之前进行扩展。
 # 默认：70
 container-concurrency-target-percentage: 80
 
 # 弹性扩容驱动
 # 值："kpa.autoscaling.knative.dev"或"hpa.autoscaling.knative.dev"
 # 默认值："kpa.autoscaling.knative.dev"
 pod-autoscaler-class: "kpa.autoscaling.knative.dev"

 # pod是否收敛至0
 # 默认：true
 enable-scale-to-zero: true
  
 # KPA根据在基于一定时间上汇总的各个指标（并发或RPS）起作用。
 # 规定时间定义了自动定标器要考虑的历史数据量，并用于在指定的时间内平滑数据。
 # 规定的越短，自动定标器的反应速度就越快，但其反应越滞后。
 
 # KPA-稳定模式的时间窗口设定 [autoscaler 在稳定窗口期下平均并发数下的操作。]
 # 可能的值：持续时间，6s <= 值 <= 1h
 # 默认：60s
 stable-window: 60s
 
 # KPA慌乱模式的百分比设定
 # KPA慌乱模式稳定模式时间窗口收集的值的百分比
 # 此值指示进入紧急模式后将如何缩小评估历史数据的窗口
 # 可能的值： float，1.0<=值<=100.0
 # 默认：10.0
 panic-window-percentage: 20.0
 
 # 此阈值定义自动定标器何时从稳定模式转换为紧急模式
 # 当前数量的副本可以（或不能）处理的流量的倍数。100％表示自动定标器始终处于紧急模式
 # 缺省值为200表示如果流量是当前副本服务器填充量的两倍
 # 可能的值： float，110.0<=值<=1000.0
 # 默认： 200.0
 panic-threshold-percentage: "150.0"

 # 注意：在缩小过程中，只有在修订版在稳定窗口的整个持续时间内都看不到任何流量之后，才会删除最终副本。
 # 注意：只有在没有看到因稳定窗口的时间框架而恐慌的原因之后，自动缩放器才会退出恐慌模式。
 
 # 流量结束后到pod收敛至0时的时间
 # 默认：0s
 scale-to-zero-pod-retention-period: 42s
 
 # 系统在实际删除最后一个副本之前在内部等待从零开始缩放的机器就位的上限时间
 # 不会调整流量结束后最后一个副本将保留多长时间
 # 可能的值：持续时间（必须至少为6s）。
 # 默认：30s
 scale-to-zero-grace-period: 30s
 
```

##### 编辑configmap

```
kubectl -n knative-serving get edit config-autoscaler
```

#### 每次修订[部署时的yaml模板中配置]

```
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: helloworld-go
  namespace: default
spec:
  template:
    metadata:
      annotations:
        # 弹性扩容驱动
        # 值："kpa.autoscaling.knative.dev"或"hpa.autoscaling.knative.dev"
        # 默认值："kpa.autoscaling.knative.dev"
        autoscaling.knative.dev/class: "kpa.autoscaling.knative.dev"
        
        # 度量标准指定查看哪个值并将其与相应目标进行比较。
        # KPA支持两个指标：并发性和每秒请求数（rps）。
        # HPA当前仅在Knative Serving中支持cpu。
        # 默认："concurrency"
        # autoscaling.knative.dev/metric: "rps"
        
        # 当“Metric”设置为“concurrency”时，维护每个副本正在处理的稳定数量的并发请求。
        # 并发数设置为200
        # 默认：100
        # autoscaling软设置
        autoscaling.knative.dev/target: "200"
        
        # 通过目标利用率值来调整副本数。此值指定自动定标器实际确定目标的百分比。
        # 实际上，这指定了副本运行时的“热度”，这会导致自动缩放器在达到总限制之前进行扩展。
        # 默认：70
        autoscaling.knative.dev/targetUtilizationPercentage: "80"
        
        # 最小副本数
        # 默认值：0如果启用了从零到零的比例并且使用了KPA类，1否则
        autoscaling.knative.dev/minScale: "2"
        
        # 最大副本数
        # 默认值：0表示无限制
        autoscaling.knative.dev/maxScale: "3"
        
        # 流量结束后到pod收敛至0时的时间
        # 默认：0s
        autoscaling.knative.dev/scaleToZeroPodRetentionPeriod: "33"
        
        # KPA稳定模式的窗口时间设定
        # 可能的值：持续时间，6s<=值<=1h
        # 默认：60s
        autoscaling.knative.dev/window: "40s"
        
        # KPA慌乱模式的百分比设定
        # KPA慌乱模式稳定模式时间窗口收集的值的百分比
        # 此值指示进入紧急模式后将如何缩小评估历史数据的窗口
        # 可能的值： float，1.0<=值<=100.0
        # 默认：10.0
        autoscaling.knative.dev/panicWindowPercentage: "20.0"
        
        # 此阈值定义自动定标器何时从稳定模式转换为紧急模式
        # 当前数量的副本可以（或不能）处理的流量的倍数。100％表示自动定标器始终处于紧急模式
        # 缺省值为200表示如果流量是当前副本服务器填充量的两倍
        # 可能的值： float，110.0<=值<=1000.0
        # 默认： 200.0
        autoscaling.knative.dev/panicThresholdPercentage: "150.0"
        # 注意：在缩小过程中，只有在修订版在稳定窗口的整个持续时间内都看不到任何流量之后，才会删除最终副本。
        # 注意：只有在没有看到因稳定窗口的时间框架而恐慌的原因之后，自动缩放器才会退出恐慌模式。

    spec:
      # autoscaling硬设置
      # 默认值：0，表示无限制
      # 建议仅在应用程序明确需要硬限制时才使用硬限制。较低的硬限制值可能会影响应用程序的吞吐量和延迟。
      # 如果同时指定了软限制和硬限制，则将使用两个值中的较小者，以使自动缩放目标不具有硬限制甚至不允许进入副本的值。
      # containerConcurrency: 50
      containers:
        - image: gcr.io/knative-samples/helloworld-go
```



## 在Knative中配置您的凭据

### 使用私有镜像仓库

1. 创建一个`imagePullSecrets`包含您的凭据作为机密列表的：

   ```shell
   kubectl create secret docker-registry [REGISTRY-CRED-SECRETS] \
     --docker-server=[PRIVATE_REGISTRY_SERVER_URL] \
     --docker-email=[PRIVATE_REGISTRY_EMAIL] \
     --docker-username=[PRIVATE_REGISTRY_USER] \
     --docker-password=[PRIVATE_REGISTRY_PASSWORD]
   ```

   哪里

   - `[REGISTRY-CRED-SECRETS]`是您要用作秘密的名称（`imagePullSecrets`对象）。例如，`container-registry`。

   - `[PRIVATE_REGISTRY_SERVER_URL]` 是存储您的容器映像的私有注册表的URL。

     例子：

     - Google Container Registry：`https://gcr.io/`
     - DockerHub：`https://index.docker.io/v1/`

   - `[PRIVATE_REGISTRY_EMAIL]` 是与私人注册表关联的电子邮件地址。
   - `[PRIVATE_REGISTRY_USER]` 是用于访问专用容器注册表的用户名。
   - `[PRIVATE_REGISTRY_PASSWORD]` 是用于访问专用容器注册表的密码。

   例：

   ```shell
   kubectl create secret docker-registry harbor-registry \
     --docker-server=192.168.240.73 \
     --docker-email=zzz@zzz.com \
     --docker-username=zzz \
     --docker-password=asdlkjCS123..
   ```

   提示：创建完之后`imagePullSecrets`，可以通过运行以下命令查看这些secret信息：

   ```shell
   kubectl get secret [REGISTRY-CRED-SECRETS] --output=yaml
   ```

   例:

   ```
   kubectl get secret container-registry --output=container-registry.yaml
   ```

   

2. 将添加`imagePullSecrets`到您的`default`服务帐户中的 `default`名称空间。

   注意：默认情况下，、除非指定，否则您的修订版将使用Knative群集的`default`每个[命名空间]中的服务帐户 [`serviceAccountName`]。

   1. 运行以下命令来修改`default`服务帐户：

      例如，如果命名secrets时 `container-registry`，那么可以以此来修补它。

      ```shell
      kubectl patch serviceaccount default -p "{\"imagePullSecrets\": [{\"name\": \"harbor-registry\"}]}"
      ```

3. 将更新的服务帐户部署到您的Knative群集：

   ```bash
   kubectl apply --filename service-account.yaml
   ```

现在，在`default`命名空间中创建的所有新Pod 将包含您的凭据，并可以访问私有注册表中的容器映像。



## 创建私有集群本地服务

默认情况下，通过Knative部署的服务会发布到外部IP地址，从而使它们成为具有公共URL的公共IP地址上的公共服务 。虽然这对于需要从群集外部访问的服务很有用，但通常您可能正在构建后端服务，而该服务在集群外不可用。

### 将服务标记为群集本地

要将KService配置为仅在群集本地网络上可用（而不在公共Internet上可用）

可以将 `serving.knative.dev/visibility=cluster-local`标签应用于KService，Route或Kubernetes Service对象。

标记KService：

```shell
kubectl label kservice ${KSVC_NAME} serving.knative.dev/visibility=cluster-local
```

标记路线：

```shell
kubectl label route ${ROUTE_NAME} serving.knative.dev/visibility=cluster-local
```

标记Kubernetes服务：

```shell
kubectl label route ${SERVICE_NAME} serving.knative.dev/visibility=cluster-local
```

通过标记Kubernetes服务，它可以使您以更精细的方式限制可见性。

例如，可以部署[Hello World示例] ，然后通过标记服务将其转换为群集本地服务：

```shell
kubectl label kservice helloworld-go serving.knative.dev/visibility=cluster-local
```

- 可以通过验证helloworld-go服务的URL来验证所做的更改：

- ```
  kubectl get ksvc helloworld-go
  ```

  打印

  ```
  helloworld-go   http://helloworld-go.default.svc.cluster.local   helloworld-go-2bz5l   helloworld-go-2bz5l   True
  ```

  该服务返回带有`svc.cluster.local`域的URL ，指示该服务仅在群集本地网络中可用。

  可以用过在集群内的容器访问测试

  ```
  curl http://helloworld-go.default.svc.cluster.local
  ```

  打印

  ```
  Hello Go Sample v1!
  ```

  

























http://202.107.190.8:10724/api/v1/namespaces/istio-system/services/zipkin:9411/proxy/zipkin/



kubectl -n knative-serving get cm config-autoscaler