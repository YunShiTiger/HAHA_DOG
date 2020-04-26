# Monitor

## 整理Helm仓库

### 查看仓库

```
helm repo list
```

### 移除原先仓库

```
helm repo remove stable
```

### 添加新仓库地址

```
helm repo add stable http://mirror.azure.cn/kubernetes/charts/
```

```
helm repo add incubator http://mirror.azure.cn/kubernetes/charts-incubator/
```

```
helm repo update
```

## 使用Helm安装metrics-server

### 创建 metrics-server-custom.yaml 

```
cat >> metrics-server-custom.yaml <<EOF
image:
  repository: reg01.sky-mobi.com/k8s/gcr.io/google_containers/metrics-server-amd64
  tag: v0.3.1
args:
  - --kubelet-insecure-tls
  - --kubelet-preferred-address-types=InternalIP,Hostname,InternalDNS,ExternalDNS,ExternalIP
EOF
```

### 安装 metrics-server（这里 -n 是 name） 

```
helm install stable/metrics-server -n metrics-server --namespace kube-system --version=2.5.1 -f metrics-server-custom.yaml
```

### 查看

```
kubectl get pod -n kube-system  | grep metrics
```

```
kubectl top node
```

打印

```
NAME       CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%   
master-1   256m         1%     4998Mi          15%       
master-2   471m         2%     4832Mi          15%       
master-3   140m         0%     2903Mi          9%        
slave-1    96m          0%     2973Mi          9%        
slave-2    409m         2%     6009Mi          18%       
slave-3    102m         0%     4438Mi          13%       
slave-4    80m          0%     3793Mi          11%       
slave-5    88m          0%     1671Mi          5%   
```

#### 注:`kubectl top node`可能会有1到2分钟的延迟才能打印出效果

## 安装prometheus-operator 

### 创建namespace

```
kubectl create namespace monitoring
```

### 下载

```
helm fetch stable/prometheus-operator --version=5.0.3  --untar
```

### 定义 prometheus-operator 参数 

```
cat prometheus-operator/values.yaml  | grep -v '#' | grep -v ^$ > prometheus-operator-custom.yaml
```

```
cat >> prometheus-operator-custom.yaml << EOF
## prometheus-operator/values.yaml
alertmanager:
  service:
    nodePort: 31309
    type: NodePort
  alertmanagerSpec:
    image:
      repository: reg01.sky-mobi.com/k8s/quay.io/prometheus/alertmanager
      tag: v0.16.1
prometheusOperator:
  image:
    repository: reg01.sky-mobi.com/k8s/quay.io/coreos/prometheus-operator
    tag: v0.29.0
    pullPolicy: IfNotPresent
  configmapReloadImage:
    repository: reg01.sky-mobi.com/k8s/quay.io/coreos/configmap-reload
    tag: v0.0.1
  prometheusConfigReloaderImage:
    repository: reg01.sky-mobi.com/k8s/quay.io/coreos/prometheus-config-reloader
    tag: v0.29.0
  hyperkubeImage:
    repository: reg01.sky-mobi.com/k8s/k8s.gcr.io/hyperkube
    tag: v1.12.1
    pullPolicy: IfNotPresent
prometheus:
  service:
    nodePort: 32489
    type: NodePort
  prometheusSpec:
    image:
      repository: reg01.sky-mobi.com/k8s/quay.io/prometheus/prometheus
      tag: v2.7.1
    secrets: [etcd-client-cert]
kubeEtcd:
  serviceMonitor:
    scheme: https
    insecureSkipVerify: false
    serverName: ""
    caFile: /etc/prometheus/secrets/etcd-client-cert/ca.crt
    certFile: /etc/prometheus/secrets/etcd-client-cert/healthcheck-client.crt
    keyFile: /etc/prometheus/secrets/etcd-client-cert/healthcheck-client.key


## prometheus-operator/charts/grafana/values.yaml
grafana:
  service:
    nodePort: 30579
    type: NodePort
  image:
    repository: reg01.sky-mobi.com/k8s/grafana/grafana
    tag: 6.0.2
  sidecar:
    image: reg01.sky-mobi.com/k8s/kiwigrid/k8s-sidecar:0.0.13

## prometheus-operator/charts/kube-state-metrics/values.yaml
kube-state-metrics:
  image:
    repository: reg01.sky-mobi.com/k8s/k8s.gcr.io/kube-state-metrics
    tag: v1.5.0


## prometheus-operator/charts/prometheus-node-exporter/values.yaml
prometheus-node-exporter:
  image:
    repository: reg01.sky-mobi.com/k8s/quay.io/prometheus/node-exporter
    tag: v0.17.0
EOF
```

### 创建连接 etcd 的证书secre 

```
kubectl -n monitoring create secret generic etcd-client-cert --from-file=/etc/kubernetes/pki/etcd/ca.crt --from-file=/etc/kubernetes/pki/etcd/healthcheck-client.crt --from-file=/etc/kubernetes/pki/etcd/healthcheck-client.key 
```

### 部署

```
helm install stable/prometheus-operator --version=5.0.3 --name=monitoring --namespace=monitoring -f prometheus-operator-custom.yaml
```

## 查看

### 进入主机IP对应的NodePort地址查看

### 修改grafana密码

[通过查找docker container容器进入grafana]

```
grafana-cli admin reset-admin-password 123123
```

### grafana安装grafana-kubernetes-app插件

```
https://www.cnblogs.com/xzkzzz/p/10211394.html
```

[通过查找docker container容器进入grafana]

```
grafana-cli plugins install grafana-kubernetes-app
```

[也可以手动下载参考官网]

手动下载后解压放入docker容器中

```
https://grafana.com/grafana/plugins/grafana-kubernetes-app/installation
```

目录为`/var/lib/grafana/plugins`

然后重启docker container，之后网页登录Grafana实例。导航到`插件`在Grafana主菜单中找到的部分。



## 卸载

如果想要删除重来，可以使用 helm 删除，指定名字 monitoring 

```
helm del --purge monitoring
```

```
kubectl delete crd prometheusrules.monitoring.coreos.com
```

```
kubectl delete crd servicemonitors.monitoring.coreos.com
```

```
kubectl delete crd alertmanagers.monitoring.coreos.com
```

## 重新安装

重新安装 不要删除之前的，再安装可能会报错，用 upgrade 就好

```
helm upgrade monitoring stable/prometheus-operator --version=5.0.3  --namespace=monitoring -f prometheus-operator-custom.yaml
```





# 参考

```
https://blog.csdn.net/dazuiba008/article/details/89958715
```

```
https://fengxsong.github.io/2018/05/30/Using-helm-to-manage-prometheus-operator/
```

 