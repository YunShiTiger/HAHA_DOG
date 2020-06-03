# Knative

```
https://knative.dev/docs/install/any-kubernetes-cluster/
```

## 安装服务组件[Serving]

### 安装自定义资源定义(CRD)

```
kubectl apply --filename https://github.com/knative/serving/releases/download/v0.14.0/serving-crds.yaml
```

### 安装Serving的核心组件

```
kubectl apply --filename https://github.com/knative/serving/releases/download/v0.14.0/serving-core.yaml
```

### 安装Istio并启用其Knative集成

```
cd istio-1.5.4
```

#### 添加 Helm chart 仓库

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
helm template istio --namespace=istio-system \
  --set gateways.istio-ingressgateway.type=NodePort \
  --set sidecarInjectorWebhook.enabled=true \
  --set sidecarInjectorWebhook.enableNamespacesByDefault=true \
  --set global.proxy.autoInject=disabled \
  --set global.disablePolicyChecks=true \
  --set prometheus.enabled=false \
  `# Disable mixer prometheus adapter to remove istio default metrics.` \
  --set mixer.adapters.prometheus.enabled=false \
  `# Disable mixer policy check, since in our template we set no policy.` \
  --set global.disablePolicyChecks=true \
  --set gateways.istio-ingressgateway.autoscaleMin=1 \
  --set gateways.istio-ingressgateway.autoscaleMax=2 \
  --set gateways.istio-ingressgateway.resources.requests.cpu=500m \
  --set gateways.istio-ingressgateway.resources.requests.memory=256Mi \
  `# Enable SDS in the gateway to allow dynamically configuring TLS of gateway.` \
  --set gateways.istio-ingressgateway.sds.enabled=true \
  `# More pilot replicas for better scale` \
  --set pilot.autoscaleMin=2 \
  `# Set pilot trace sampling to 100%` \
  --set pilot.traceSampling=100 \
  install/kubernetes/helm/istio | kubectl apply -f - 
```

##### 验证安装

```
kubectl get svc -n istio-system
```

```
kubectl get pods -n istio-system
```

#### 更新安装以使用群集本地网关

```
helm template istio --namespace=istio-system \
  --set gateways.custom-gateway.autoscaleMin=1 \
  --set gateways.custom-gateway.autoscaleMax=2 \
  --set gateways.custom-gateway.cpu.targetAverageUtilization=60 \
  --set gateways.custom-gateway.labels.app='cluster-local-gateway' \
  --set gateways.custom-gateway.labels.istio='cluster-local-gateway' \
  --set gateways.custom-gateway.type='ClusterIP' \
  --set gateways.istio-ingressgateway.enabled=false \
  --set gateways.istio-egressgateway.enabled=false \
  --set gateways.istio-ilbgateway.enabled=false \
  --set global.mtls.auto=false \
  install/kubernetes/helm/istio \
  -f install/kubernetes/helm/istio/example-values/values-istio-gateways.yaml \
  | sed -e "s/custom-gateway/cluster-local-gateway/g" -e "s/customgateway/clusterlocalgateway/g" | kubectl apply -f - 
```

#### 配置DNS

Knative根据其主机名调度到不同的服务，因此可以大大简化正确配置DNS的过程。为此，我们必须查找Istio收到的外部IP地址。

该外部IP可以与具有通配符`A`记录的DNS提供商一起使用；但是，对于基本功能的DNS设置（不适用于生产！），可以`xip.io`在`config-domain`ConfigMap中使用此外部IP地址`knative-serving`。您可以使用以下命令对其进行编辑：

```
kubectl edit cm config-domain --namespace knative-serving
```

给定上面的外部IP，将内容更改为：

```
apiVersion: v1
kind: ConfigMap
metadata:
  name: config-domain
  namespace: knative-serving
data:
  # xip.io is a "magic" DNS provider, which resolves all DNS lookups for:
  # *.{ip}.xip.io to {ip}.
  34.83.80.117.xip.io: ""
```

*DEV实践环境*

```
data:
  # xip.io is a "magic" DNS provider, which resolves all DNS lookups for:
  # *.{ip}.xip.io to {ip}.
  xjlhcz.com: ""
```

### 安装Knative Istio控制器

```
kubectl apply --filename https://github.com/knative/net-istio/releases/download/v0.14.0/release.yaml
```

### 提取外部IP或CNAME

```
kubectl --namespace istio-system get service istio-ingressgateway
```

保存此内容以在下面配置DNS。

### 配置DNS[Real DNS]

配置完DNS提供程序后，指示Knative使用该域：

```
# Replace knative.example.com with your domain suffix
kubectl patch configmap/config-domain \
  --namespace knative-serving \
  --type merge \
  --patch '{"data":{"xjlhcz.com":""}}'
```

### 监视Knative组件，直到所有的组件显示`STATUS`的`Running`还是`Completed`：

```
kubectl get pods --namespace knative-serving
```

***至此，已经基本安装了Knative Serving！***

### 其他插件安装

#### HPA

```
kubectl apply --filename https://github.com/knative/serving/releases/download/v0.14.0/serving-hpa.yaml
```





## 安装事件组件[Eventing]

### 安装自定义资源定义(CRD)

```
kubectl apply  --selector knative.dev/crd-install=true \
--filename https://github.com/knative/eventing/releases/download/v0.14.0/eventing.yaml
```

### 安装Eventing的核心组件

```
kubectl apply --filename https://github.com/knative/eventing/releases/download/v0.14.0/eventing.yaml
```

注：上述两份文件一模一样

### 安装默认的Channel（消息）组件

#### 安装Kafka

***install it by using Strimzi***

```
https://knative.dev/docs/eventing/samples/kafka/index.html
```

##### 为Apache Kafka安装创建名称空间，例如`kafka`

```
kubectl create namespace kafka
```

##### 安装Strimzi operator

```
curl -L "https://github.com/strimzi/strimzi-kafka-operator/releases/download/0.16.2/strimzi-cluster-operator-0.16.2.yaml" \
  | sed 's/namespace: .*/namespace: kafka/' \
  | kubectl -n kafka apply -f -
```

注:

```
sed -i 's/namespace: .*/namespace: kafka/' strimzi-cluster-operator-0.16.2.yaml
```

```
kubectl -n kafka apply -f strimzi-cluster-operator-0.16.2.yaml
```

##### 安装kafka

***kafka-deploy.yaml***

```
apiVersion: kafka.strimzi.io/v1beta1
kind: Kafka
metadata:
  name: my-cluster
spec:
  kafka:
    version: 2.4.0
    replicas: 3
    listeners:
      plain: {}
      tls: {}
    config:
      offsets.topic.replication.factor: 1
      transaction.state.log.replication.factor: 1
      transaction.state.log.min.isr: 1
      log.message.format.version: "2.4"
    storage:
      type: ephemeral
  zookeeper:
    replicas: 3
    storage:
      type: ephemeral
  entityOperator:
    topicOperator: {}
    userOperator: {}
```

```
kubectl apply -n kafka -f kafka.yaml
```

##### 验证

```
kubectl get pods -n kafka
```

#### 安装Kafka Channel

```
curl -L "https://github.com/knative/eventing-contrib/releases/download/v0.14.0/kafka-channel.yaml" \
 | sed 's/REPLACE_WITH_CLUSTER_URL/my-cluster-kafka-bootstrap.kafka:9092/' \
 | kubectl apply --filename -
```

注:

```
sed -i 's/REPLACE_WITH_CLUSTER_URL/my-cluster-kafka-bootstrap.kafka:9092/' kafka-channel.yaml
```

```
kubectl apply -f kafka-channel.yaml
```

#### 安装Broker (eventing)

```
kubectl apply --filename https://github.com/knative/eventing/releases/download/v0.14.0/channel-broker.yaml
```

### 验证

监视Knative组件，直到所有的组件显示`STATUS`的 `Running`：

```
kubectl get pods --namespace knative-eventing
```

***至此，已经基本安装了Knative Eventing！***



## 安装Observability插件

安装以下可观察性功能，以在服务和事件组件中启用日志记录，指标和请求跟踪。

### 安装核心组件

```
kubectl apply --filename https://github.com/knative/serving/releases/download/v0.14.0/monitoring-core.yaml
```

### 选择安装以下一个或所有可观察性插件：

安装核心后，您可以选择安装以下一个或所有可观察性插件：

- 安装[Prometheus](https://prometheus.io/)和[Grafana](https://grafana.com/)以获取指标：

  ```
  kubectl apply --filename https://github.com/knative/serving/releases/download/v0.14.0/monitoring-metrics-prometheus.yaml
  ```

- 安装用于日志的[ELK堆栈](https://www.elastic.co/what-is/elk-stack)（Elasticsearch，Logstash和Kibana）：

  ```
  kubectl apply --filename https://github.com/knative/serving/releases/download/v0.14.0/monitoring-logs-elasticsearch.yaml
  ```

- 安装[Jaeger](https://jaegertracing.io/)进行分布式跟踪

  - [内存中（独立）](https://knative.dev/docs/install/any-kubernetes-cluster/#jaeger-0)

  要安装Jaeger的内存（独立）版本，请运行以下命令：

  ```
  kubectl apply --filename https://github.com/knative/serving/releases/download/v0.14.0/monitoring-tracing-jaeger-in-mem.yaml
  ```

- 安装[Zipkin](https://zipkin.io/)进行分布式跟踪

  - [内存中（独立）](https://knative.dev/docs/install/any-kubernetes-cluster/#zipkin-0)

  要安装Zipkin的内存（独立）版本，请运行以下命令：

  ```
  kubectl apply --filename https://github.com/knative/serving/releases/download/v0.14.0/monitoring-tracing-zipkin-in-mem.yaml
  ```







