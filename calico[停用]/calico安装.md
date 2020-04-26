# k8s网络组件---calico安装

## 1.要求

### k8s1.13集群

```
kubeadm init --apiserver-advertise-address 10.1.11.26 --kubernetes-version=v1.13.0 --pod-network-cidr=10.244.0.0/16
```

下面的calico配置文件用的都是192.168.0.0网段

### 集群初始化完毕(只剩coredns在creating)

### 配置好命令行工具

```
https://docs.projectcalico.org/v3.3/getting-started/kubernetes/
```

## 2.安装etcd实例 

```
kubectl apply -f \
https://docs.projectcalico.org/v3.3/getting-started/kubernetes/installation/hosted/etcd.yaml
```

镜像为`quay.io/coreos/etcd:v3.3.9`

输出

```
daemonset.extensions/calico-etcd created
service/calico-etcd created
```

## 3.安装Calico所需的RBAC角色 

```
kubectl apply -f \
https://docs.projectcalico.org/v3.3/getting-started/kubernetes/installation/rbac.yaml
```

输出

```
clusterrole.rbac.authorization.k8s.io/calico-kube-controllers created
clusterrolebinding.rbac.authorization.k8s.io/calico-kube-controllers created
clusterrole.rbac.authorization.k8s.io/calico-node created
clusterrolebinding.rbac.authorization.k8s.io/calico-node created
```

## 4.安装Calico

```
kubectl apply -f \
https://docs.projectcalico.org/v3.3/getting-started/kubernetes/installation/hosted/calico.yaml
```

镜像为`quay.io/calico/node:v3.3.2` `quay.io/calico/cni:v3.3.2` `quay.io/calico/kube-controllers                  v3.3.2`

输出

```
configmap/calico-config created
secret/calico-etcd-secrets created
daemonset.extensions/calico-node created
serviceaccount/calico-node created
deployment.extensions/calico-kube-controllers created
serviceaccount/calico-kube-controllers created
```

