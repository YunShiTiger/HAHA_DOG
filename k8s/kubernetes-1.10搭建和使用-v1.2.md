# Kubernetes集群部署(k8s-1.10)

## 系统配置

1.    虚拟机安装(CentOS 7) ---一个管理节点(master)、一个或两个运行节点(node)。高可用可以使用keepalive。(可以多加入一个热备节点或者把一个运行节点做成热备节点)
2.    CPU:2核-2线程
3.    RAM:2G
4.    ROM:40G

## 基本设置---所有节点

### 关闭防火墙

```
systemctl disable firewalld
```

验证

```
service firewalld status
打印出dead为成功
```
### 关闭selinux

```
vi /etc/selinux/config
```

```
将SELINUX=enforcing 改为SELINUX=disabled
```

验证

```
getenforce
打印出disabled为修改成功
```
### 关闭交换空间

```
vi /etc/fstab
```

```
注释swap项
```
### 将节点IP加入到hosts中

查看IP

```
Ifconfig
```

我的节点IP为

192.168.136.181---master    192.168.136.176---node-1  192.168.136.176---node-2

```
vi /etc/hosts
```

加入地址

```
192.168.136.181 master
192.168.136.176 node-1
192.168.136.176 node-2
```
### 配置系统内核参数使流过网桥的流量

```
vi /etc/sysctl.conf
```

添加

```
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
```
### 配置阿里源

```
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0 
EOF
```
### 安装docker

```
yum install docker -y
```

配置docker阿里源加速器

```
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://tsqluof3.mirror.aliyuncs.com"]
}
EOF
```

```
systemctl daemon-reload
```

```
systemctl enable docker && systemctl restart docker
```
## kubernetes集群安装

### 各节点的部署

#### 安装kubernetes组件(所有节点)

```
yum -y install docker kubelet kubeadm kubectl
systemctl enable docker kubelet kubeadm kubectl
```
#### 下载docker镜像(所有节点)

```
#!/bin/bash
images=(kube-proxy-amd64:v1.11.0 kube-scheduler-amd64:v1.11.0 kube-controller-manager-amd64:v1.11.0 kube-apiserver-amd64:v1.11.0
etcd-amd64:3.2.18 coredns:1.1.3 pause-amd64:3.1 kubernetes-dashboard-amd64:v1.8.3 k8s-dns-sidecar-amd64:1.14.9 k8s-dns-kube-dns-amd64:1.14.9
k8s-dns-dnsmasq-nanny-amd64:1.14.9 )
for imageName in ${images[@]} ; do
docker pull registry.cn-qingdao.aliyuncs.com/caonima/$imageName
docker tag registry.cn-qingdao.aliyuncs.com/caonima/$imageName k8s.gcr.io/$imageName
docker rmi registry.cn-qingdao.aliyuncs.com/caonima/$imageName
done
```

上面的shell脚本主要做了3件事，下载各种需要用到的容器镜像、重新打标记为符合k8s命令规范的版本名称、清除旧的容器镜像。

###  主节点的部署

#### 集群初始化(master)

```
kubeadm init --apiserver-advertise-address 192.168.136.181 --kubernetes-version=v1.10.0 --pod-network-cidr=10.244.0.0/16
```

最后successfully后会生成token↓↓↓(每个人都不一样，用自己的)

```
kubeadm join 192.168.136.181:6443 --token ard5rr.gah6qj8oevefdz5b --discovery-token-ca-cert-hash sha256:f969fed5bedf444da33a9aceb46a5e01bd0a1cbb3da7a62e4e9481b50717cdb8
```
#### 配置kubectl认证信息

```
echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> ~/.bash_profile
或者(分开执行)
export KUBECONFIG=/etc/kubernetes/admin.conf
source ~/.bash_profile
```
(kubectl是管理集群的命令行工具)

#### 安装flannel网络

```
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/v0.10.0/Documentation/kube-flannel.yml
```
```
---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: flannel
rules:
  - apiGroups:
      - ""
    resources:
      - pods
    verbs:
      - get
  - apiGroups:
      - ""
    resources:
      - nodes
    verbs:
      - list
      - watch
  - apiGroups:
      - ""
    resources:
      - nodes/status
    verbs:
      - patch
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: flannel
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: flannel
subjects:
- kind: ServiceAccount
  name: flannel
  namespace: kube-system
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: flannel
  namespace: kube-system
---
kind: ConfigMap
apiVersion: v1
metadata:
  name: kube-flannel-cfg
  namespace: kube-system
  labels:
    tier: node
    app: flannel
data:
  cni-conf.json: |
    {
      "name": "cbr0",
      "plugins": [
        {
          "type": "flannel",
          "delegate": {
            "hairpinMode": true,
            "isDefaultGateway": true
          }
        },
        {
          "type": "portmap",
          "capabilities": {
            "portMappings": true
          }
        }
      ]
    }
  net-conf.json: |
    {
      "Network": "10.244.0.0/16",
      "Backend": {
        "Type": "vxlan"
      }
    }
---
apiVersion: extensions/v1beta1
kind: DaemonSet
metadata:
  name: kube-flannel-ds
  namespace: kube-system
  labels:
    tier: node
    app: flannel
spec:
  template:
    metadata:
      labels:
        tier: node
        app: flannel
    spec:
      hostNetwork: true
      nodeSelector:
        beta.kubernetes.io/arch: amd64
      tolerations:
      - key: node-role.kubernetes.io/master
        operator: Exists
        effect: NoSchedule
      serviceAccountName: flannel
      initContainers:
      - name: install-cni
        image: quay.io/coreos/flannel:v0.10.0-amd64
        command:
        - cp
        args:
        - -f
        - /etc/kube-flannel/cni-conf.json
        - /etc/cni/net.d/10-flannel.conflist
        volumeMounts:
        - name: cni
          mountPath: /etc/cni/net.d
        - name: flannel-cfg
          mountPath: /etc/kube-flannel/
      containers:
      - name: kube-flannel
        image: quay.io/coreos/flannel:v0.10.0-amd64
        command:
        - /opt/bin/flanneld
        args:
        - --ip-masq
        - --kube-subnet-mgr
        resources:
          requests:
            cpu: "100m"
            memory: "50Mi"
          limits:
            cpu: "100m"
            memory: "50Mi"
        securityContext:
          privileged: true
        env:
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: POD_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        volumeMounts:
        - name: run
          mountPath: /run
        - name: flannel-cfg
          mountPath: /etc/kube-flannel/
      volumes:
        - name: run
          hostPath:
            path: /run
        - name: cni
          hostPath:
            path: /etc/cni/net.d
        - name: flannel-cfg
          configMap:
            name: kube-flannel-cfg
```



#### 注:

如果让主节点也加入到工作节点中可以执行

```
kubectl taint nodes --all node-role.kubernetes.io/master-
```

或者

```
kubectl taint node 主节点名 node-role.kubernetes.io/master-
```

输出结果:

```	
node "test-01" untainted
taint key="dedicated" and effect="" not found.
taint key="dedicated" and effect="" not found.
```

注:这步我没做过，我认为管理节点还是要踏踏实实的做管理节点

将主节点从工作节点中脱离

```
kubectl taint node k8s-master node-role.kubernetes.io/master="":NoSchedule
```
###  从节点的加入

#### 加入到集群中

```
kubeadm join 192.168.136.181:6443 --token ard5rr.gah6qj8oevefdz5b --discovery-token-ca-cert-hash sha256:f969fed5bedf444da33a9aceb46a5e01bd0a1cbb3da7a62e4e9481b50717cdb8
```

打印出

```
[preflight] Running pre-flight checks
[discovery] Trying to connect to API Server "10.138.0.4:6443"
[discovery] Created cluster-info discovery client, requesting info from "https://10.138.0.4:6443"
[discovery] Requesting info from "https://10.138.0.4:6443" again to validate TLS against the pinned public key
[discovery] Cluster info signature and contents are valid and TLS certificate validates against pinned roots, will use API Server "10.138.0.4:6443"
[discovery] Successfully established connection with API Server "10.138.0.4:6443"
[bootstrap] Detected server version: v1.8.0
[bootstrap] The server supports the Certificates API (certificates.k8s.io/v1beta1)
[csr] Created API client to obtain unique certificate for this node, generating keys and certificate signing request
[csr] Received signed certificate from the API server, generating KubeConfig...

Node join complete:
* Certificate signing request sent to master and response
  received.
* Kubelet informed of new secure connection details.

Run 'kubectl get nodes' on the master to see this machine join.
```

在master节点中查看

```
kubectl get nodes
```
## 使用

### 创建应用

```
kubectl run kubernetes-bootcamp \
      --image=docker.io/jocatalin/kubernetes-bootcamp:v1 \
      --port=8080
这里我们通过 kubectl run 部署了一个应用，命名为 kubernetes-bootcamp。
Docker 镜像通过 --image 指定。
--port 设置应用对外服务的端口。
```
### 资源创建

(1).用 kubectl 命令直接创建，比如：

```
kubectl run nginx-deployment --image=nginx:1.7.9 --replicas=2
```

在命令行中通过参数指定资源的属性。

(2).通过配置文件和 `kubectl apply` 创建，要完成前面同样的工作，可执行命令：

```
kubectl apply -f nginx.yaml
```

nginx.yaml 的内容为：

```
apiVersion: extensions/v1beta1   #--当前配置格式的版本
kind: Deployment   #--创建资源的类型
metadata:   #--该资源的元数据
  name: nginx-deployment   #--name是必须的元数据项
  namespace: nginx   #--不设定默认为default
spec:   #--Deployment的规格说明
  replicas: 2   #--副本数量(默认是1)
  template:    #--这个文件最重要的部分就在这
   metadata:   #--定义pod的元数据(至少要定义一个label,label的key和value可以任意指定)
     labels:
	   app: web_server
   spec:   #--定义pod的规格(定义pod中每一个容器的属性,name和images在这里是必须要有的)
     containers:
     - name: nginx
       image: nginx:1.7.9	
```

资源的属性写在配置文件中，文件格式为 YAML。

service.yaml模板内容:

```
apiVersion: v1
kind: Service
metadata:
  name: httpd-svc
spec:
  type: NodePort   #--指定开放对外端口
  selector:
    run: httpd
  ports:
  - protocal: TCP
    nodePort: 30000   #--指定对外端口为30000
    port: 8080
    targetPort: 80
```

查看/编辑正在运行的资源

```
kubectl edit deployment nginx-deployment
```
### 删除资源

```
kubectl delete deployment nginx-deploymen
```

或者

```
kubectl delete -f nginx.yaml
```
删除Evicted的应用

```
kubectl get pods | grep Evicted | awk '{print $1}' | xargs kubectl delete pod
```

### 暴露端口

```
kubectl expose deployment/kubernetes-bootcamp \
      --type="NodePort" \
      --port 8080
```
### 查看pod

```
kubectl get pods --all-namespaces
```
### 查看应用被映射到哪个端口

```
kubectl get services --all-namespaces
```
### 查看应用的副本数

```
kubectl get deployments
```
### 将副本数增加到三个

```
kubectl scale deployments/kubernetes-bootcamp --replicas=3
变为两个就是
kubectl scale deployments/kubernetes-bootcamp --replicas=2 ---从3个变为2个也是这样
```

修改上面的"资源创建"的配置文件也可以执行副本数量的增加和减少。运行时就用资源创建的"kubectl apply -f XXX.yaml"就可以。

### 设置滚动更新(热更新)

```
kubectl set image deployments/kubernetes-bootcamp kubernetes-bootcamp=jocatalin/kubernetes-bootcamp:v2
↓可以退回原来的版本哦~
kubectl rollout undo deployments/kubernetes-bootcamp
```
例:

创建资源:

```
apiVersion: apps/v1beta1
kind: Deployment
metadata:
  name: httpd
spec:
  revisionHistoryLimit: 10   #--保留之前历史版本数量
  replicas: 3
  template:
    metadata:
      labels:
        run: httpd
    spec:
      containers:
      - name:httpd
        image: :httpd:2.2.31
        ports:
        - containerPort: 80
```

构建资源

```
kubectl apply -f httpd.yaml
```

修改image:":httpd:2.2.31"→":httpd:2.2.32"

再次构建资源

```
kubectl apply -f httpd.yaml
```

会发现之前的pod被逐一替换

Kubernetes 提供了两个参数 `maxSurge` 和 `maxUnavailable` 来精细控制 Pod 的替换数量

用带--record参数构建

```
kubectl apply -f httpd.yaml --record
```

`--record` 的作用是将当前命令记录到 revision 记录中，这样我们就可以知道每个 revison 对应的是哪个配置文件

#### 查看 revison 历史记录

```
kubectl rollout history deployment httpd
```

回滚到版本"1"

```
kubectl rollout undo deployment httpd --to-revision=1
```

#### rolling-update

rolling-update是一个非常重要的命令，对于已经部署并且正在运行的业务，rolling-update提供了不中断业务的更新方式。rolling-update每次起一个新的pod，等新pod完全起来后删除一个旧的pod，然后再起一个新的pod替换旧的pod，直到替换掉所有的pod。
rolling-update需要确保新的版本有不同的name，Version和label，否则会报错 。

`kubectl rolling-update rc-nginx-``2` `-f rc-nginx.yaml`

如果在升级过程中，发现有问题还可以中途停止update，并回滚到前面版本

`kubectl rolling-update rc-nginx-``2` `—rollback`

rolling-update还有很多其他选项提供丰富的功能，如—update-period指定间隔周期，使用时可以使用-h查看help信息

### 查看节点label

```
kubectl get node --show-labels
```
### 为节点添加备注(添加到label中)

```
kubectl label node k8s-node1 disktype=ssd
```
### 部署到指定node

```
apiVersion: extensions/v1beta1   #--当前配置格式的版本
kind: Deployment   #--创建资源的类型
metadata:   #--该资源的元数据
  name: nginx-deployment   #--name是必须的元数据项
spec:   #--Deployment的规格说明
  replicas: 2   #--副本数量(默认是1)
  template:    #--这个文件最重要的部分就在这
   metadata:   #--定义pod的元数据(至少要定义一个label,label的key和value可以任意指定)
     labels:
	   app: web_server
   spec:   #--定义pod的规格(定义pod中每一个容器的属性,name和images在这里是必须要有的)
     containers:
     - name: nginx
       image: nginx:1.7.9	
     nodeSelector:
       disktype: ssd   #指定到"11"中所添加"ssd"备注的node-1节点--disktype是kubernetes自己维护的几个label中的其中之一
```
### 删除节点备注(label中的备注)

```
kubectl label node k8s-node1 disktype-

```

注:在删除节点备注以后,之前部署的程序也不会被删除,若想删除有备注时的部署则需要将配置文件中的"nodeSelector"项删掉在重新"kubectl apply"部署

### job

#### myjob.yml配置文件(该job只执行一次)

```
apiVersion: batch/v1
kind: Job
metadata:
  name: myjob
spec:
  template:
   metadata:
     name: myjob
   spec:
     containers:
     - name: hello
       image: busybox
       command: ["echo","hello k8s job !"]
     restartPolicy: Never
#restartPolicy项有Never和OnFailure两个选项
#执行失败后表现为Never:因为successfully为0,容器在被一直创建;OnFailure:因为successfully为0,容器一直在重启
```

执行该job

```
kubectl apply -f myjob.yml
```

验证

```
kubectl log myjob-bkrsm #--查看执行日志
```

#### 并行job

```
apiVersion: batch/v1
kind: Job
metadata:
  name: myjob
spec:
  completions: 6   #--执行总数为6(没有参数则默认为执行一次)
  parallelism: 2   #--两个同时执行(没有参数则默认为执行一次)
  template:
   metadata:
     name: myjob
   spec:
     containers:
     - name: hello
       image: busybox
       command: ["echo","hello k8s job !"]
     restartPolicy: Onfailure
```

#### 定时job(CronJob )

```
apiVersion: batch/v2alpha1
kind: CronJob
metadata:
  name: myjob
spec:
  schedule: "*/1 * * * *"   #--每分钟执行一次"pipeline流水线脚本定时一样"
  jobTemplate:
   spec:
     template:
       spec:
         containers:
         - name: hello
           image: busybox
           command: ["echo","hello k8s job !"]
         restartPolicy: Onfailure

```

查看

```
kubectl get cronjob
```

注:Kubernetes 默认没有 enable CronJob 功能，需要在 kube-apiserver 中加入这个功能。方法很简单，修改 kube-apiserver 的配置文件 

```
vi /etc/kubernetes/manifests/kube-apiserver.yaml
```

在kube-apiserver启动参数后面加入

```
runtime-config=batch/v2alpha1=true
```

确认

```
kubectl api-versions
```

看到支持batch/v2alpha1

### Health Check

#### Liveness

liveness.yaml内容:

```
apiVersion: v1
kind: Pod
metadata:
  labels: 
    test: liveness
  name: liveness
spec:
  restartPolicy: OnFailure
    containers:
    - name: liveness
      image: busybox
    args:
    - /bin/sh
    - -c
    - touch /tmp/healthy; sleep 30; rm -rf /tmp/healthy; sleep 600
    livenessProbe:
      exec:
        command:
        - cat
        - /tmp/healthy
      initialDelaySeconds: 10 
      periodSeconds: 5
```

注:

1. 探测的方法是：通过 `cat` 命令检查 `/tmp/healthy` 文件是否存在。如果命令执行成功，返回值为零，Kubernetes 则认为本次 Liveness 探测成功；如果命令返回值非零，本次 Liveness 探测失败。
2. `initialDelaySeconds: 10` 指定容器启动 10 之后开始执行 Liveness 探测，我们一般会根据应用启动的准备时间来设置。比如某个应用正常启动要花 30 秒，那么 `initialDelaySeconds` 的值就应该大于 30。
3. `periodSeconds: 5` 指定每 5 秒执行一次 Liveness 探测。Kubernetes 如果连续执行 3 次 Liveness 探测均失败，则会杀掉并重启容器。

创建

```
kubectl apply -f liveness.yaml
```

检验

```
kubectl describe pod liveness
#查看event事件
kubectl get pod liveness
#发现已经重启
```

#### Readiness

Readiness.yaml内容:

```
apiVersion: v1
kind: Pod
metadata:
  labels: 
    test: readiness
  name: readiness
spec:
  restartPolicy: OnFailure
    containers:
    - name: readiness
      image: busybox
    args:
    - /bin/sh
    - -c
    - touch /tmp/healthy; sleep 30; rm -rf /tmp/healthy; sleep 600
    readinessProbe:
      exec:
        command:
        - cat
        - /tmp/healthy
      initialDelaySeconds: 10 
      periodSeconds: 5

```

创建

```
kubectl apply -f readiness.yaml
```

检验

```
kubectl describe pod readiness
#查看event事件
kubectl get pod readiness
#不同时间Ready状态都在变化: 9s--不可用 16s--可用 53s--不可用
```

#### Liveness和Readiness区别

1. Liveness 探测和 Readiness 探测是两种 Health Check 机制，如果不特意配置，Kubernetes 将对两种探测采取相同的默认行为，即通过判断容器启动进程的返回值是否为零来判断探测是否成功。
2. 两种探测的配置方法完全一样，支持的配置参数也一样。不同之处在于探测失败后的行为：Liveness 探测是重启容器；Readiness 探测则是将容器设置为不可用，不接收 Service 转发的请求。
3. Liveness 探测和 Readiness 探测是独立执行的，二者之间没有依赖，所以可以单独使用，也可以同时使用。用 Liveness 探测判断容器是否需要重启以实现自愈；用 Readiness 探测判断容器是否已经准备好对外提供服务。

#### 应用于Scale Up

对于多副本应用，当执行 Scale Up 操作时，新副本会作为 backend 被添加到 Service 的负责均衡中，与已有副本一起处理客户的请求。考虑到应用启动通常都需要一个准备阶段，比如加载缓存数据，连接数据库等，从容器启动到正真能够提供服务是需要一段时间的。我们可以通过 Readiness 探测判断容器是否就绪，避免将请求发送到还没有 ready 的 backend。

web应用部署.yaml

```
apiVersion: apps/v1beta1
kind: Deployment
metadata:
  name: web
spec:
  replicas: 3
  template:
    metadata:
      labels:
        run: web
    spec
      containers:
      - name: web
        image: web-image
        port:
        - containerPort: 8080
        readinessProbe:
          httpGet:
            scheme: HTTP   #--schema 指定协议，支持 HTTP（默认值）和 HTTPS
            path: /healthy   #--指定访问路径
            port: 8080   #--指定端口
          initialDelaySeconds: 10 
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: web-svc
spec:
  selector:
    run: web
  port:
  - protocol: TCP
    port: 8080
    targetPort: 80
```

Readiness探测方法 -- `httpGet`。Kubernetes 对于该方法探测成功的判断条件是 http 请求的返回代码在 200-400 之间。

上面配置的作用是：

1. 容器启动 10 秒之后开始探测。
2. 如果 `http://[container_ip]:8080/healthy` 返回代码不是 200-400，表示容器没有就绪，不接收 Service `web-svc` 的请求。
3. 每隔 5 秒再探测一次。
4. 直到返回代码为 200-400，表明容器已经就绪，然后将其加入到 `web-svc` 的负责均衡中，开始处理客户请求。
5. 探测会继续以 5 秒的间隔执行，如果连续发生 3 次失败，容器又会从负载均衡中移除，直到下次探测成功重新加入。


#### 应用于 Rolling Update

```
apiVersion: apps/v1beta1
kind: Deployment
metadata:
  name: app
spec:
  strategy:
    rollingUpdate:
      maxSurge: 35%
      maxUnavailable: 35%
  replicas: 10
  template:
    metadata:
      labels:
        run: app
    spec
      containers:
      - name: app
        image: busybox
        args:
        - /bin/sh
        - -c
        - sleep 3000
        redinessProbe:
          exec:
            command:
            - cat
            - /tmp/healthy
          initialDelaySeconds: 10
          periodSeconds: 5
```

maxSurge:此参数控制滚动更新过程中副本总数的超过 `DESIRED` 的上限。`maxSurge` 可以是具体的整数（比如 3），也可以是百分百，向上取整。`maxSurge` 默认值为 25%。

maxUnavailable:此参数控制滚动更新过程中，不可用的副本相占 `DESIRED` 的最大比例。 `maxUnavailable` 可以是具体的整数（比如 3），也可以是百分百，向下取整。`maxUnavailable` 默认值为 25%。

`maxSurge` 值越大，初始创建的新副本数量就越多；`maxUnavailable` 值越大，初始销毁的旧副本数量就越多。

如果滚动更新失败，可以通过 `kubectl rollout undo` 回滚到上一个版本。

### 数据存储

PersistentVolume (PV) 是外部存储系统中的一块存储空间，由管理员创建和维护。与 Volume 一样，PV 具有持久性，生命周期独立于 Pod。

PersistentVolumeClaim (PVC) 是对 PV 的申请 (Claim)。PVC 通常由普通用户创建和维护。需要为 Pod 分配存储资源时，用户可以创建一个 PVC，指明存储资源的容量大小和访问模式（比如只读）等信息，Kubernetes 会查找并提供满足条件的 PV。

#### NFS实现PV(静态供给)

在master节点上搭建nfs服务器---目录为/extends

##### PV

创建一个 PV `mypv1`，配置文件 `nfs-pv1.yml` 如下:

```
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mypv1
spec:
  capacity:
    storage: 1Gi   #①
  accessModes:
    - ReadWriteOnce   #②
  persistentVolumeReclaimPolicy: Recycle   #③ 
  storageClassName: nfs   #④
  nfs:
    path: /extends/pv1   #⑤
    server: 192.168.136.181
```

① `capacity` 指定 PV 的容量为 1G。

② `accessModes` 指定访问模式为 `ReadWriteOnce`，支持的访问模式有：
ReadWriteOnce – PV 能以 read-write 模式 mount 到单个节点。
ReadOnlyMany – PV 能以 read-only 模式 mount 到多个节点。
ReadWriteMany – PV 能以 read-write 模式 mount 到多个节点。

③ `persistentVolumeReclaimPolicy` 指定当 PV 的回收策略为 `Recycle`，支持的策略有：
Retain – 需要管理员手工回收。(不需要当前PV的时候不被删除)
Recycle – 清除 PV 中的数据，效果相当于执行 `rm -rf /thevolume/*`。(不需要当前PV的时候将被删除)
Delete – 删除 Storage Provider 上的对应存储资源，例如 AWS EBS、GCE PD、Azure Disk、OpenStack Cinder Volume 等。(NFS不支持Delete)

④ `storageClassName` 指定 PV 的 class 为 `nfs`。相当于为 PV 设置了一个分类，PVC 可以指定 class 申请相应 class 的 PV。

⑤ 指定 PV 在 NFS 服务器上对应的目录。

创建mypv1

```
kubectl apply -f nfs-pv1.yml
```

查看

```
kubectl get pv
```

##### PVC

创建 PVC `mypvc1`，配置文件 `nfs-pvc1.yml` 如下:

```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mypvc1
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: nfs  
```

创建mypv1

```
kubectl apply -f nfs-pvc1.yml
```

查看

```
 kubectl get pvc
```

##### 验证

```
 kubectl get pvc 和 kubectl get pv
```

看到STATUS都变味Bound到mypv1则成功

##### 测试存储

创建pod1,配置内容如下:

```
apiVersion: v1
kind: Pod
metadata:
  name: mypod1
spec:
  containers:
    - name: mypod1
      image: busybox
      args:
      - /bin/sh
      - -c
      - sleep 3000
      volumeMounts:
      - mountPath: "/mydata"
        name: mydata
  volumes:
    - name: mydata
      persistentVolumeClaim:
        claimName: mypvc1
```

创建pod1

```
kubectl apply -f pod1.yml
```

在容器中创建文档

```
kubectl exec mypod1 touch /mydata/caonima
```

在master节点中查看

```
ls /extends/pv1
#打印出caonima字样则成功
```

注:NFS挂载目录需要赋予权限

##### 回收PV

当 PV 不再需要时，可通过删除 PVC 回收。

当 PVC `mypvc1`被删除后，我们发现 Kubernetes 启动了一个新 Pod `recycler-for-mypv1`，这个 Pod 的作用就是清除 PV `mypv1` 的数据。此时 `mypv1` 的状态为 `Released`，表示已经解除了与 `mypvc1` 的 Bound，正在清除数据，不过此时还不可用。

当数据清除完毕，`mypv1` 的状态重新变为 `Available`，此时则可以被新的 PVC 申请。(原先的存放在NFS中的数据也被删除了，因为 PV 的回收策略设置为 `Recycle`，所以数据会被清除，但这可能不是我们想要的结果。如果我们希望保留数据，可以将策略设置为 `Retain`。)

如果将会手册乱设备`Retain`，这样在删除pvc后， Kubernetes 不会启动 Pod `recycler-for-mypv1`将数据删除，虽然 `mypv1` 中的数据得到了保留，但其 PV 状态会一直处于 `Released`，不能被其他 PVC 申请。为了重新使用存储资源，可以删除并重新创建 `mypv1`。删除操作只是删除了 PV 对象，存储空间中的数据并不会被删除。

#### 动态供给

之前都是我们提前创建了 PV，然后通过 PVC 申请 PV 并在 Pod 中使用，这种方式叫做静态供给（Static Provision）。

与之对应的是动态供给（Dynamical Provision），即如果没有满足 PVC 条件的 PV，会动态创建 PV。相比静态供给，动态供给有明显的优势：不需要提前创建 PV，减少了管理员的工作量，效率高。

动态供给是通过 StorageClass 实现的，StorageClass 定义了如何创建 PV，下面是两个例子。

StorageClass `standard`：

```
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: standard
provisioner: kubernetes.io/aws-ebs
parameters:
  type: gp2
reclaimPolicy: Retain
```

StorageClass `slow`：

```
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: slow
provisioner: kubernetes.io/aws-ebs
parameters:
  type: io1
  zones: us-east-1d, us-east-1c
  iopsPerGB: "10"
```

这两个 StorageClass 都会动态创建 AWS EBS，不同在于 `standard` 创建的是 `gp2` 类型的 EBS，而 `slow` 创建的是 `io1` 类型的 EBS。不同类型的 EBS 支持的参数可参考 AWS 官方文档。

StorageClass 支持 `Delete` 和 `Retain` 两种 `reclaimPolicy`，默认是 `Delete`。

与之前一样，PVC 在申请 PV 时，只需要指定 StorageClass 和容量以及访问模式

```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mypvc1
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: standard  
```

除了 AWS EBS，Kubernetes 支持其他多种动态供给 PV 的 Provisioner

#### CephFS

##### 创建`rbd-with-secret & ceph-secret`

```
grep key /etc/ceph/ceph.client.admin.keyring |awk '{printf "%s", $NF}'|base64
```

打印出

```
QVFCUWZ1SmIrTmh3QkJBQUdSK2hOMUMvVmxEUWJ1QWdjT1Y5ZXc9PQ==
```

##### 创建`ceph-secret.yml`

```
apiVersion: v1
kind: Secret
metadata:
  name: ceph-secret
type: "kubernetes.io/rbd"  
data:
  key: QVFCUWZ1SmIrTmh3QkJBQUdSK2hOMUMvVmxEUWJ1QWdjT1Y5ZXc9PQ==
```

```
kubectl create -f ceph-secret.yml
```

##### 创建PV

```
apiVersion: v1
kind: PersistentVolume
metadata:
  name: ceph-pv-tracker
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteMany
  storageClassName: cephfs
  cephfs:
    monitors:
      - 192.168.1.103:6789
    path: "/tracker"
    user: admin
    secretRef:
      name: ceph-secret
    readOnly: false
  persistentVolumeReclaimPolicy: Recycle
```

##### 创建PVC

```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ceph-pvc-tracker
spec:
  accessModes:
    - ReadWriteMany
  volumeName: ceph-pv-tracker
  storageClassName: cephfs
  resources:
    requests:
      storage: 10Gi
```

#### Ceph

##### 创建`rbd-with-secret & ceph-secret`

```
grep key /etc/ceph/ceph.client.admin.keyring |awk '{printf "%s", $NF}'|base64
```

打印出

```
QVFCUWZ1SmIrTmh3QkJBQUdSK2hOMUMvVmxEUWJ1QWdjT1Y5ZXc9PQ==
```

##### 创建`ceph-secret.yml`

```
apiVersion: v1
kind: Secret
metadata:
  name: ceph-secret
type: "kubernetes.io/rbd"  
data:
  key: QVFCUWZ1SmIrTmh3QkJBQUdSK2hOMUMvVmxEUWJ1QWdjT1Y5ZXc9PQ==
```

```
kubectl create -f ceph-secret.yml
```

##### 创建Image

```
rbd create ceph-rbd-pv-tracker --size 10240
```

验证

```
rbd list
```

##### 临时关闭内核不支持的特性 

```
rbd feature disable ceph-rbd-pv-tracker exclusive-lock, object-map, fast-diff, deep-flatten
```

验证

```
rbd info ceph-rbd-pv-tracker
```

##### 映射到内核

```
sudo rbd map ceph-rbd-pv-tracker
```

验证

```
rbd showmapped
```

##### 创建PV

```
apiVersion: v1
kind: PersistentVolume
metadata:
  name: ceph-rbd-pv-tracker
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  rbd:
    monitors:
      - 192.168.1.103:6789
    pool: rbd
    image: ceph-rbd-pv-tracker
    user: admin
    secretRef:
      name: ceph-secret
    fsType: ext4
    readOnly: false
  persistentVolumeReclaimPolicy: Recycle
```

```
kubectl apply -f fastdfs-pv.yml
```

验证

```
kubectl get pv
```

##### 创建PVC

```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ceph-rbd-pvc-tracker
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
```

```
kubectl apply -f fastdfs-pvc.yml
```

验证

```
kubectl get pvc

打印出

ceph-rbd-pvc-tracker  Bound  ceph-rbd-pv-tracker  10Gi  RWO  30s
```

##### 创建挂载应用

```
apiVersion: apps/v1beta1
kind: Deployment
metadata:
  name: fastdfs-tracker
spec:
  replicas: 5
  template:
    metadata:
      labels:
        run: fastdfs-tracker
    spec:
      containers:
      - name: fastdfs-tracker
        image: fastdfs:tracker
        ports:
        - containerPort: 32522
        command: [ "/bin/bash", "-c", "--" ]
        args: [ "while true; do sleep 30; done;" ]
        volumeMounts:
        - name: fastdfs-volume
          mountPath: /fastdfs/tracker/data
          readOnly: false
      volumes:
      - name: fastdfs-volume
        persistentVolumeClaim:
          claimName: ceph-rbd-pvc-tracker
---
apiVersion: v1
kind: Service
metadata:
  name: fastdfs-tracker-service
spec:
  selector:
    run: fstdfs-tracker
  type: NodePort
  ports:
  - nodePort: 32522
    port: 32522
    targetPort: 32522
```



#### MySQL 使用 PV 和 PVC

mysql-pv.yml

```
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mysql-pv
spec:
  accessModes:
    - ReadWriteMany
  capacity:
    storage: 1Gi
  persistentVolumeReclaimPolicy: Retain
  storageClassName: nfs
  nfs:
    path: /extends/mysql-pv
    server: 192.168.136.181
```

mysql-pvc.yml

```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mysql-pvc
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 1Gi
  storageClassName: nfs
```

mysql.yml

```
apiVersion: v1
kind: Service
metadata:
  name: mysql
spec:
  ports:
    port: 3306
  selector:
    app: mysql

---
apiVersion: apps/v1beta1
kind: Deployment
metadata:
  name: mysql
spec:
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
    labels:
      app: mysql
    spec:
      containers:
      - image: mysql:5.7
        name: mysql
        env:
        - name: MYSQL_ROOT_PASSWORD
          value: password
        ports:
        - containerPort: 3306
          name: mysql
        volumeMounts:
        - name: mysql-persistent-storage
          mountPath: /var/lib/mysql
    volumes:
    - name: mysql-persistent-storage
      persistentVolumeClaim:
        claimName: mysql-pvc
```

进入mysql

```
kubectl run -it --rm --image=mysql:5.6 --restart=Never mysql-client -- mysql -h mysql -ppassword
```

### 查看错误报告

查看描述

```
kubectl describe pod prometheus-tim-3864503240-rwpq5 -n kube-system 
```

查看日志

```
kubectl logs monitoring-grafana-7d47d46b7b-jdffg -n kube-system
```

#### 系统级应用起不来[Back-off restarting failed containe]

在配置文件中加入`command: [ "/bin/bash", "-c", "--" ]` 和 `args: [ "while true; do sleep 30; done;" ]`

例:

```
apiVersion: v1
#定义Pod
kind: Pod
metadata:
 #Pod的名称，全局唯一
 name: ubuntu1604-0912-log-yaml-3
 labels:
  name: ubuntu1604-0912-log-yaml
spec:
  #设置存储卷
  volumes:
   - name: yytubuntulogs
     hostPath:
      path: /Users/YantaiYang/logtmep
  containers:
   #容器名称
   - name: ubuntu1604-0912-container-yaml
     #容器对应的Docker Image
     image: ubuntu:16.04
     # Just spin & wait forever
     command: [ "/bin/bash", "-c", "--" ]
     args: [ "while true; do sleep 30; done;" ]
     volumeMounts:
      - mountPath: /mydata-log
        name: yytubuntulogs
```



### 编辑运行中的容器

```
kubectl --namespace=kube-system edit service kubernetes-dashboard 

```

### 安装heapster

#### 拉取镜像(在从节点中执行)

```
git clone https://github.com/datagrand/k8s_deploy
```

#### 拉取创建文件(在主节点中执行)

```
git clone https://github.com/kubernetes/heapster.git
```

#### 挂载镜像

```
cd k8s_deploy\images\heapster
```

##### 挂载heapster

```
docker load -i heapster-amd64.tgz
```

```
docker tag 镜像ID k8s.gcr.io/heapster-amd64:v1.5.3
```

##### 挂载grafana

```
docker load -i heapster-grafana-amd64.tgz
```

```
docker tag 镜像ID k8s.gcr.io/heapster-grafana-amd64:v4.4.3
```

##### 挂载influxdb

```
docker load -i heapster-influxdb-amd64.tgz
```

```
docker tag 镜像ID k8s.gcr.io/heapster-influxdb-amd64:v1.3.3
```

#### 部署

```
kubectl apply -f heapster/deploy/kube-config/influxdb/
```

```
kubectl apply -f heapster/deploy/kube-config/rbac/heapster-rbac.yaml
```

注:需要在heapster目录外执行

#### 编辑grafana

```
kubectl --namespace=kube-system edit monitoring-grafana
```

将类型修改为 `NodePort`

#### 页面查看

```
kubectl get service --all-namespace
```

↑查看grafana的端口

使用`masterIP:端口`进入也页面

### 安装dashboard

#### 拉取镜像

```
docker pull daocloud.io/liukuan73/kubernetes-dashboard-amd64:v1.8.3
```

修改镜像名称

```
docker tag [镜像ID] k8s.gcr.io/kubernetes-dashboard-amd64:v1.8.3
```

#### 创建dashboard

dashboard.yml

```
# Copyright 2017 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Configuration to deploy release version of the Dashboard UI compatible with
# Kubernetes 1.8.
#
# Example usage: kubectl create -f <this_file>

# ------------------- Dashboard Secret ------------------- #

apiVersion: v1
kind: Secret
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard-certs
  namespace: kube-system
type: Opaque

---
# ------------------- Dashboard Service Account ------------------- #

apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard
  namespace: kube-system

---
# ------------------- Dashboard Role & Role Binding ------------------- #

kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: kubernetes-dashboard-minimal
  namespace: kube-system
rules:
  # Allow Dashboard to create 'kubernetes-dashboard-key-holder' secret.
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["create"]
  # Allow Dashboard to create 'kubernetes-dashboard-settings' config map.
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["create"]
  # Allow Dashboard to get, update and delete Dashboard exclusive secrets.
- apiGroups: [""]
  resources: ["secrets"]
  resourceNames: ["kubernetes-dashboard-key-holder", "kubernetes-dashboard-certs"]
  verbs: ["get", "update", "delete"]
  # Allow Dashboard to get and update 'kubernetes-dashboard-settings' config map.
- apiGroups: [""]
  resources: ["configmaps"]
  resourceNames: ["kubernetes-dashboard-settings"]
  verbs: ["get", "update"]
  # Allow Dashboard to get metrics from heapster.
- apiGroups: [""]
  resources: ["services"]
  resourceNames: ["heapster"]
  verbs: ["proxy"]
- apiGroups: [""]
  resources: ["services/proxy"]
  resourceNames: ["heapster", "http:heapster:", "https:heapster:"]
  verbs: ["get"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: kubernetes-dashboard-minimal
  namespace: kube-system
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: kubernetes-dashboard-minimal
subjects:
- kind: ServiceAccount
  name: kubernetes-dashboard
  namespace: kube-system

---
# ------------------- Dashboard Deployment ------------------- #

kind: Deployment
apiVersion: apps/v1beta2
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard
  namespace: kube-system
spec:
  replicas: 1
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      k8s-app: kubernetes-dashboard
  template:
    metadata:
      labels:
        k8s-app: kubernetes-dashboard
    spec:
      serviceAccountName: kubernetes-dashboard
      containers:
      - name: kubernetes-dashboard
        image: k8s.gcr.io/kubernetes-dashboard-amd64:v1.8.3
        ports:
        - containerPort: 9090
          protocol: TCP
        args:
          #- --auto-generate-certificates
          # Uncomment the following line to manually specify Kubernetes API server Host
          # If not specified, Dashboard will attempt to auto discover the API server and connect
          # to it. Uncomment only if the default does not work.
          #- --apiserver-host=http://10.0.1.168:8080
        volumeMounts:
        - name: kubernetes-dashboard-certs
          mountPath: /certs
          # Create on-disk volume to store exec logs
        - mountPath: /tmp
          name: tmp-volume
        livenessProbe:
          httpGet:
            scheme: HTTP
            path: /
            port: 9090
          initialDelaySeconds: 30
          timeoutSeconds: 30
      volumes:
      - name: kubernetes-dashboard-certs
        secret:
          secretName: kubernetes-dashboard-certs
      - name: tmp-volume
        emptyDir: {}
      serviceAccountName: kubernetes-dashboard
      # Comment the following tolerations if Dashboard must not be deployed on master
      tolerations:
      - key: node-role.kubernetes.io/master
        effect: NoSchedule

---
# ------------------- Dashboard Service ------------------- #

kind: Service
apiVersion: v1
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard
  namespace: kube-system
spec:
  ports:
    - port: 9090
      targetPort: 9090
  selector:
    k8s-app: kubernetes-dashboard

# ------------------------------------------------------------
kind: Service
apiVersion: v1
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard-external
  namespace: kube-system
spec:
  ports:
    - port: 9090
      targetPort: 9090
      nodePort: 31116
  type: NodePort
  selector:
    k8s-app: kubernetes-dashboard
```

```
kubectl apply -f dashboard.yml
```

#### 权限获取

dashboard.rbac.admin.yml

```
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: kubernetes-dashboard
  labels:
    k8s-app: kubernetes-dashboard
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: kubernetes-dashboard
  namespace: kube-system
```

```
kubectl apply -f dashboard.rbac.admin.yml
```

#### 页面查看

```
masterIP:31116
```

### Helm

#### 安装

```
curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | bash
```

helm 有很多子命令和参数，为了提高使用命令行的效率，通常建议安装 helm 的 bash 命令补全脚本，方法如下：

```
helm completion bash > .helmrc; echo "source .helmrc" >> .bashrc
```

重新登录(reboot)后就可以通过 `Tab` 键补全 helm 子命令和参数了。





dockerhub镜像

```
mirrorgooglecontainers
和
keveon
```

