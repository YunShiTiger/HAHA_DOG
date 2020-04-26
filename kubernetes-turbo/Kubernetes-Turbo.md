# Kubernetes-Turbo

## minikube

### 查看状态

    minikube status

打印

    host: Running
    kubelet: Running
    apiserver: Running
    kubectl: Correctly Configured: pointing to minikube-vm at 10.211.55.6



## 动态查看

    kubectl get --watch deployment
    
    --watch
    #该参数类似于shell的tail

```
watch "kubectl get pods"
```



## 查看labels

### 搜索所有

    kubectl get pods --show-labels
    
    --show-labels
    #该参数查看所设的selector

### 增加搜索条件

    kubectl get pods --show-labels -l app=nginx,env=test

```
#后面-l参数增加检索内容 多个用","隔开并且为并集
```

### 查询搜索条件

```
kubectl get pods --show-labels -l 'app in (nginx,test)'
```

```
#查询app=nginx和app=test的所有pods,并且不为并集
```



## 查看pods配置

    kubectl get pod nginx-deployment-54f57cf6bf-g9kbz -o yaml


    -o yaml
    #该方式输出其yaml格式配置文件



## 修改label

### 添加/修改

    kubectl label pod nginx-deployment-54f57cf6bf-g9kbz env=aaa --overwrite
    
    #可以修改deployment这类controller也可以修改pods
    #若添加的label没有则为添加,若有则为修改

### 删除

    kubectl label pod nginx-deployment-54f57cf6bf-g9kbz env-


    #删除label则为最后为label标签,不用写"="和":"直接写"-"即可



## 增加注解Annotate

```
kubectl annotate pods nginx-deployment-54f57cf6bf-g9kbz jb='来一根大鸡巴'
```

查看

```
kubectl get pods nginx-deployment-54f57cf6bf-g9kbz -o yaml | less
```



## 查看ownerReferences

```
kubectl get rs nginx-deployment-54f57cf6bf -o yaml | less
```



## 编辑[pods/rs/deployment等]

```
kubectl edit pods nginx-deployment-54f57cf6bf-2x98b
```



## 命令行更新应用

```
kubectl set image deployment nginx-deployment nginx=nginx:1.9.1
```

```
#kubectl set image deployment deployment名称 对应deployment下的容器名称=镜像名
```

在执行更新后查看replicaset

```
kubectl get rs
```

打印

```
NAME                          DESIRED   CURRENT   READY   AGE
nginx-deployment-54f57cf6bf   0         0         0       20m
nginx-deployment-56f8998dbc   2         2         2       14m
```

会出现两个rs(版本一新一旧)



## 回滚(Rollout)

在创建时添加--record参数将内容加入,`—recored`参数可以记录命令，可以很方便的查看每次revison的变化。

```
kubectl apply -f deployment.yaml --record
```

注:Yaml模板文件中`spec.revisonHistoryLimit`参数为设定历史版本

### 检查Deployment的revision

```
kubectl rollout history deployment/nginx-deployment
```

### 查看单个revision的详细信息

```
kubectl rollout history deployment/nginx-deployment --revision=2
```

### 回退到上一个版本

```
kubectl rollout undo deployment/nginx-deployment
```

### 使用 `--revision`参数指定某个历史版本

```
kubectl rollout undo deployment/nginx-deployment --to-revision=2
```



## Job

```
spec.template格式同Pod

spec.restartPolicy 重启策略仅支持Never或OnFailure

spec.backoffLimit 重启次数

单个Pod时，默认Pod成功运行后Job即结束

spec.completions标志Job结束需要成功运行的Pod个数，默认为1

spec.parallelism标志并行运行的Pod的个数，默认为1

spec.activeDeadlineSeconds标志失败Pod的重试最大时间，超过这个时间不会继续重试
```

### 单一job

```
apiVersion: batch/v1
kind: Job
metadata:
  name: jb
spec:
  template:
    metadata:
      name: jb
    spec:
      containers:
      - name: jb
        image: ubuntu
        command: ["/bin/sh"]
        args: ["-c","sleep 30; date"]
      restartPolicy: Never
```

### 并行job

```
apiVersion: batch/v1
kind: Job
metadata:
  name: jb-paral
spec:
  completions: 8
  parallelism: 2
  template:
    metadata:
      name: jb-paral
    spec:
      containers:
      - name: jb-paral
        image: ubuntu
        command: ["/bin/sh"]
        args: ["-c","sleep 30; date"]
      restartPolicy: OnFailure
```



## Cronjob

```
apiVersion: batch/v1beta1
kind: CronJob
metadata:
  name: hello
spec:
  schedule: "*/1 * * * *"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: hello
            image: busybox
            args:
            - /bin/sh
            - -c
            - date; echo Hello from the Kubernetes cluster
          restartPolicy: OnFailure
  startingDeadlineSeconds: 10
  concurrencyPolicy: Allow
  successfulJobsHistoryLimit: 3
```

```
spec.schedule指定任务运行周期，格式同Cron

spec.jobTemplate指定需要运行的任务，格式同Job

spec.startingDeadlineSeconds指定任务开始的截止期限(每次运行job时,或者说是当他开始准备运行时,最长的等待时间)

spec.concurrencyPolicy指定任务的并发策略，支持Allow、Forbid和Replace三个选项

spec.successfulJobsHistoryLimit允许job执行完存留历史job个数
```

## StatefulSet

StatefulSet是为了解决有状态服务的问题（对应Deployments和ReplicaSets是为无状态服务而设计），其应用场景包括

- 稳定的持久化存储，即Pod重新调度后还是能访问到相同的持久化数据，基于PVC来实现
- 稳定的网络标志，即Pod重新调度后其PodName和HostName不变，基于Headless Service（即没有Cluster IP的Service）来实现
- 有序部署，有序扩展，即Pod是有顺序的，在部署或者扩展的时候要依据定义的顺序依次依次进行（即从0到N-1，在下一个Pod运行之前所有之前的Pod必须都是Running和Ready状态），基于init containers来实现
- 有序收缩，有序删除（即从N-1到0）

从上面的应用场景可以发现，StatefulSet由以下几个部分组成：

- 用于定义网络标志（DNS domain）的Headless Service
- 用于创建PersistentVolumes的volumeClaimTemplates
- 定义具体应用的StatefulSet

StatefulSet中每个Pod的DNS格式为`statefulSetName-{0..N-1}.serviceName.namespace.svc.cluster.local`，其中

- `serviceName`为Headless Service的名字
- `0..N-1`为Pod所在的序号，从0开始到N-1
- `statefulSetName`为StatefulSet的名字
- `namespace`为服务所在的namespace，Headless Servic和StatefulSet必须在相同的namespace
- `.cluster.local`为Cluster Domain

### 使用storageclass动态供给的statefulset↓↓↓

```
apiVersion: v1
kind: Service
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  ports:
  - port: 80
    name: web
  clusterIP: None
  selector:
    app: nginx
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web
spec:
  serviceName: "nginx"
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
          name: web
        volumeMounts:
        - name: www
          mountPath: /usr/share/nginx/html
  volumeClaimTemplates:
  - metadata:
      name: www
      annotations:
        volume.alpha.kubernetes.io/storage-class: csi-cephfs
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: "csi-cephfs"
      resources:
        requests:
          storage: 1Gi
```

```
创建后pods逐一生成
并且随之的headless service也生成
```

### 查看headless service的endpoints

```
kubectl get endpoints nginx
```

打印

```
NAME    ENDPOINTS                                        AGE
nginx   10.20.114.73:80,10.20.16.136:80,10.20.80.69:80   16h
```

### 查看StatefulSet

```
kubectl get sts
```

StatefulSet不同于Deployment通过Replicaset管理版本和维持副本是,StatefulSet是直接管理下属的pod(`通过查看pod的ownerReferences可以看到`),而Pod中用的一个label来标识版本:`controller-revision-hash`

### 查看controller-revision-hash

```
kubectl get pod -L controller-revision-hash
```

打印

```
NAME    READY   STATUS    RESTARTS   AGE   CONTROLLER-REVISION-HASH
web-0   1/1     Running   0          21h   web-5f6745bd6f
web-1   1/1     Running   0          21h   web-5f6745bd6f
web-2   1/1     Running   0          21h   web-5f6745bd6f
```

### 更新镜像

修改配置yaml文件更新

或者

```
kubectl set image statefulset web nginx=nginx:1.8
```

```
set image     ---   设置镜像(固定写法)
statefulset   ---   资源类型
web           ---   要更新的statefulset的name
nginx         ---   需要变更容器的容器name
nginx:1.8.0   ---   新的镜像
```

查看

```
kubectl get pod -L controller-revision-hash
```

打印

```
NAME    READY   STATUS    RESTARTS   AGE   CONTROLLER-REVISION-HASH
web-0   1/1     Running   0          46m   web-75469f7cb
web-1   1/1     Running   0          46m   web-75469f7cb
web-2   1/1     Running   0          47m   web-75469f7cb
```

更新时候顺序为`2`→`1`→`0`这样倒序更新

## DaemonSet

DaemonSet保证在每个Node上都运行一个容器副本，常用来部署一些集群的日志、监控或者其他系统管理应用。典型的应用包括：

```
1.日志收集，比如fluentd，logstash等
2.系统监控，比如Prometheus Node Exporter，collectd，New Relic agent，Ganglia gmond等
3.系统程序，比如kube-proxy, kube-dns, glusterd, ceph等
```

### 使用Fluentd收集日志的例子：

```
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentd
  labels:
    k8s-app: fluentd
spec:
  selector:
    matchLabels:
      name: fluentd
  template:
    metadata:
      labels:
        name: fluentd
    spec:
      containers:
      - name: fluentd-es
        image: fluent/fluentd:v1.4-1
        env:
         - name: FLUENTD_ARGS
           value: -qq
        volumeMounts:
         - name: containers
           mountPath: /var/lib/docker/containers
         - name: varlog
           mountPath: /varlog
      volumes:
         - hostPath:
             path: /var/lib/docker/containers
           name: containers
         - hostPath:
             path: /var/log
           name: varlog
```

### Update

```
kubectl set image ds fluentd fluentd-es=fluent/fluentd:v1.4
```

### Update  Status

```
kubectl rollout status ds/fluentd
```

打印

```
Waiting for daemon set "fluentd" rollout to finish: 0 out of 1 new pods have been updated...
Waiting for daemon set "fluentd" rollout to finish: 0 out of 1 new pods have been updated...
Waiting for daemon set "fluentd" rollout to finish: 0 of 1 updated pods are available...
daemon set "fluentd" successfully rolled out
```

## 指定Node节点

DaemonSet会忽略Node的unschedulable状态，有两种方式来指定Pod只运行在指定的Node节点上：

```
nodeSelector：	只调度到匹配指定label的Node上
nodeAffinity：	功能更丰富的Node选择器，比如支持集合操作
podAffinity：	调度到满足条件的Pod所在的Node上
```

### nodeSelector示例

先给Node打上标签

```
kubectl label nodes node-01 disktype=ssd
```

然后在daemonset中指定nodeSelector为disktype=ssd：

```
spec:
  nodeSelector:
    disktype: ssd
```

### nodeAffinity示例

nodeAffinity目前支持两种：

```
1.requiredDuringSchedulingIgnoredDuringExecution	#必须满足条件
2.preferredDuringSchedulingIgnoredDuringExecution	#优选条件
```

```
apiVersion: v1
kind: Pod
metadata:
  name: with-node-affinity
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: kubernetes.io/e2e-az-name
            operator: In
            values:
            - e2e-az1
            - e2e-az2
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 1
        preference:
          matchExpressions:
          - key: another-node-label-key
            operator: In
            values:
            - another-node-label-value
  containers:
  - name: with-node-affinity
    image: gcr.io/google_containers/pause:2.0
```

```
上面的例子代表调度到包含标签kubernetes.io/e2e-az-name并且值为e2e-az1或e2e-az2的Node上，并且优选(因为有weight的权重)还带有标签another-node-label-key=another-node-label-value的Node。
在使用preferredDuringSchedulingIgnoredDuringExecution时的 weight: 100 字段则代表一个权重,如果有多个调度条件则按照权重更高(100>70)的条件去筛选调度
```

```
- requiredDuringSchedulingIgnoredDuringExecution
#必须/禁止和某些pod调度到一起
- preferredDuringSchedulingIgnoredDuringExecution
#优先/优先不和某些pod调度到一起
- 是否必须或必须、优先或优先不则取决于podAffinity还是podAntiAffinity
```

```
Operator选项有In/NotIn/Exists/DoesNotExists/Gt/Lt
- In/NotIn: 按照 key: A , value: B 这样筛选
- Exists/DoesNotExists: 按照 key:A ,value: 任意 这样筛选(不用在配置文件中再填写value,直接按照key进行筛选)
- Gt/Lt: 使用Gt/Lt的时候类似于In/NotIn但是value只能填写数字
```

### podAffinity示例

podAffinity基于Pod的标签来选择Node，仅调度到满足条件Pod所在的Node上。

podAffinity目前支持两种：

```
podAffinity				亲和
podAntiAffinity		反亲和
```

```
apiVersion: v1
kind: Pod
metadata:
  name: with-pod-affinity
spec:
  affinity:
    podAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchExpressions:
          - key: security
            operator: In
            values:
            - S1
        topologyKey: failure-domain.beta.kubernetes.io/zone
    podAntiAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchExpressions:
            - key: security
              operator: In
              values:
              - S2
          topologyKey: kubernetes.io/hostname
  containers:
  - name: with-pod-affinity
    image: gcr.io/google_containers/pause:2.0
```

```
- 上面例子表示如果一个“Node所在Zone中包含至少一个带有security=S1标签且运行中的Pod”，那么可以调度到该Node
- 优先不调度到“包含至少一个带有security=S2标签且运行中Pod”的Node上
在使用preferredDuringSchedulingIgnoredDuringExecution时的 weight: 100 字段则代表一个权重,如果有多个调度条件则按照权重更高(100>70)的条件去筛选调度
```

```
- requiredDuringSchedulingIgnoredDuringExecution
#必须/禁止和某些pod调度到一起
- preferredDuringSchedulingIgnoredDuringExecution
#优先/优先不和某些pod调度到一起
- 是否必须或必须、优先或优先不则取决于podAffinity还是podAntiAffinity
```

```
Operator选项有In/NotIn/Exists/DoesNotExists
In/NotIn: 按照 key: A , value: B 这样筛选
Exists/DoesNotExists: 按照 key:A ,value: 任意 这样筛选(不用在配置文件中再填写value,直接按照key进行筛选)
```

### 静态Pod

除了DaemonSet，还可以使用静态Pod来在每台机器上运行指定的Pod，这需要kubelet在启动的时候指定manifest目录：

```
kubelet --pod-manifest-path=/etc/kubernetes/manifests
```

```
然后将所需要的Pod定义文件放到指定的manifest目录中。
注意：静态Pod不能通过API Server来删除，但可以通过删除manifest文件来自动删除对应的Pod。
```

### Taints 和 tolerations

Taints 和 tolerations 用于保证 Pod 不被调度到不合适的 Node 上，其中 Taint 应用于 Node 上，而 toleration 则应用于 Pod 上。

#### Taints:

目前支持三种`taint[effect(不能为空)]`类型:

- NoSchedule：新的 Pod 不调度到该 Node 上，不影响正在运行的 Pod
- PreferNoSchedule：soft 版的 NoSchedule，尽量不调度到该 Node 上
- NoExecute：新的 Pod 不调度到该 Node 上，并且删除（evict）已在运行的 Pod。Pod 可以增加一个时间（tolerationSeconds）

然而，当 Pod 的 Tolerations 匹配 Node 的所有 Taints 的时候可以调度到该 Node 上；当 Pod 是已经运行的时候，也不会被删除（evicted）。另外对于 NoExecute，如果 Pod 增加了一个 tolerationSeconds，则会在该时间之后才删除 Pod。

比如，假设 node1 上应用以下几个 taint

```
kubectl taint nodes node1 key1=value1:NoSchedule
kubectl taint nodes node1 key1=value1:NoExecute
kubectl taint nodes node1 key2=value2:NoSchedule
```

或者使用yaml文件创建

```
apiVersion: v1
kind: Node
metadata:
  name: demo-node
spec:
  taints:
    - key: "key1"
      value: "value1"
      effect: "NoSchedule"
    - key: "key1"
      value: "value1"
      effect: "NoExecute"
    - key: "key2"
      value: "value2"
      effect: "NoSchedule"
```

#### tolerations:

不同于Taints,pod的tolerations可以为空但是类型与Taints相同

Operator参数:

```
Exists/Equal
- Equal: 比较tolerations与Taints中key和value的值再做筛选
- Exists: 比较tolerations与Taints中key,value则不再比较并且value可为空
```

下面的这个 Pod 由于没有 tolerate`key2=value2:NoSchedule` 无法调度到 node1 上

```
tolerations:
- key: "key1"
  operator: "Equal"
  value: "value1"
  effect: "NoSchedule"
- key: "key1"
  operator: "Equal"
  value: "value1"
  effect: "NoExecute"
```

而正在运行且带有 tolerationSeconds 的 Pod 则会在 600s 之后删除

```
tolerations:
- key: "key1"
  operator: "Equal"
  value: "value1"
  effect: "NoSchedule"
- key: "key1"
  operator: "Equal"
  value: "value1"
  effect: "NoExecute"
  tolerationSeconds: 600
- key: "key2"
  operator: "Equal"
  value: "value2"
  effect: "NoSchedule"
```

注意，DaemonSet 创建的 Pod 会自动加上对 `node.alpha.kubernetes.io/unreachable` 和 `node.alpha.kubernetes.io/notReady` 的 NoExecute Toleration，以避免它们因此被删除。

## 优先级调度

从 v1.8 开始，kube-scheduler 支持定义 Pod 的优先级，从而保证高优先级的 Pod 优先调度。并从 v1.11 开始默认开启。在v1.14 则变为stable版本

在指定 Pod 的优先级之前需要先定义一个PriorityClass(非 namespace 资源)

```
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: high-priority #(高优先级)
value: 10000
globalDefault: false
description: "high"
```

```
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: low-priority #(低优先级)
value: 100
globalDefault: false
description: "low"
```

其中

- `value` 为 32 位整数的优先级，该值越大，优先级越高
- `globalDefault` 用于未配置 PriorityClassName 的 Pod，整个集群中应该只有一个 PriorityClass 将其设置为 true

然后，在 PodSpec 中通过 PriorityClassName 设置 Pod 的优先级：

```
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  labels:
    env: test
spec:
  containers:
  - name: nginx
    image: nginx
    imagePullPolicy: IfNotPresent
  priorityClassName: high-priority
```

## 配置管理

```
ConfigMap				可变配置

Secret					敏感信息

ServiceAccount	身份认证
```

```
Spec.Containers[].Resources.limit/requests	资源配置

Spec.Containers[].SecurityContext						安全管控

Spec.initContainers													前置校验
```

### ConfigMap

ConfigMap用于保存配置数据的键值对，可以用来保存单个属性，也可以用来保存配置文件。ConfigMap跟secret很类似，但它可以更方便地处理不包含敏感信息的字符串。

```
可以使用kubectl create configmap从文件、目录或者key-value字符串创建等创建ConfigMap。
```

#### 从key-value字符串创建ConfigMap

```
kubectl create configmap special-config --from-literal=special.how=very
```

打印

```
configmap "special-config" created
```

查看

```
kubectl get configmap special-config -o go-template='{{.data}}'
```

打印

```
map[special.how:very]
```

#### 从env文件创建

##### 创建env文件

```
echo -e "a=b\nc=d" | tee config.env
```

```
kubectl create configmap special-config --from-env-file=config.env
```

打印

```
configmap "special-config" created
```

查看

```
kubectl get configmap special-config -o go-template='{{.data}}'
```

打印

```
map[a:b c:d]
```

#### 从目录创建

##### 创建目录

```
mkdir config
echo a>config/a
echo b>config/b
```

```
kubectl create configmap special-config --from-file=config/
```

打印

```
configmap "special-config" created
```

查看

```
kubectl get configmap special-config -o go-template='{{.data}}'
```

打印

```
map[a:a
 b:b
]
```

#### ConfigMap使用

ConfigMap可以通过多种方式在Pod中使用，比如设置环境变量、设置容器命令行参数、在Volume中创建配置文件等。

注意:

```
- ConfigMap必须在Pod引用它之前创建
- 使用envFrom时，将会自动忽略无效的键
- Pod只能使用同一个命名空间内的ConfigMap
```

##### 用作环境变量

创建ConfigMap：

```
kubectl create configmap special-config --from-literal=special.how=very --from-literal=special.type=charm
```

```
kubectl create configmap env-config --from-literal=log_level=INFO
```

以环境变量方式引用:

```
apiVersion: v1
kind: Pod
metadata:
  name: test-pod
spec:
  containers:
    - name: test-container
      image: busybox
      command: [ "/bin/sh", "-c", "env" ]
      env:
        - name: SPECIAL_LEVEL_KEY
          valueFrom:
            configMapKeyRef:
              name: special-config
              key: special.how
        - name: SPECIAL_TYPE_KEY
          valueFrom:
            configMapKeyRef:
              name: special-config
              key: special.type
      envFrom:
        - configMapRef:
            name: env-config
  restartPolicy: Never
```

当pod运行完成后查看日志

```
kubectl logs test-pod
```

打印包括刚刚写入的环境变量

```
KUBERNETES_SERVICE_PORT=443
KUBERNETES_PORT=tcp://10.96.0.1:443
HOSTNAME=test-pod
SHLVL=1
HOME=/root
SPECIAL_TYPE_KEY=charm	#这呢
KUBERNETES_PORT_443_TCP_ADDR=10.96.0.1
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
KUBERNETES_PORT_443_TCP_PORT=443
KUBERNETES_PORT_443_TCP_PROTO=tcp
SPECIAL_LEVEL_KEY=very	#这呢
log_level=INFO					#这呢
KUBERNETES_SERVICE_PORT_HTTPS=443
KUBERNETES_PORT_443_TCP=tcp://10.96.0.1:443
KUBERNETES_SERVICE_HOST=10.96.0.1
PWD=/
```

##### 用作命令行参数

将ConfigMap用作命令行参数时，需要先把ConfigMap的数据保存在环境变量中，然后通过$(VAR_NAME)的方式引用环境变量.

```
apiVersion: v1
kind: Pod
metadata:
  name: dapi-test-pod
spec:
  containers:
    - name: test-container
      image: busybox
      command: [ "/bin/sh", "-c", "echo $(SPECIAL_LEVEL_KEY) $(SPECIAL_TYPE_KEY)" ]
      env:
        - name: SPECIAL_LEVEL_KEY
          valueFrom:
            configMapKeyRef:
              name: special-config
              key: special.how
        - name: SPECIAL_TYPE_KEY
          valueFrom:
            configMapKeyRef:
              name: special-config
              key: special.type
  restartPolicy: Never

```

当pod运行完成后查看日志

```
kubectl logs dapi-test-pod
```

打印包括刚刚写入的环境变量

```
very charm
```

##### 使用volume将ConfigMap作为文件或目录直接挂载

将创建的ConfigMap直接挂载至Pod的/etc/config目录下，其中每一个key-value键值对都会生成一个文件，key为文件名，value为内容

```
apiVersion: v1
kind: Pod
metadata:
  name: vol-test-pod
spec:
  containers:
    - name: test-container
      image: busybox
      command: [ "/bin/sh", "-c", "cat /etc/config/special.how" ]
      volumeMounts:
      - name: config-volume
        mountPath: /etc/config
  volumes:
    - name: config-volume
      configMap:
        name: special-config
  restartPolicy: Never
```

当pod运行完成后查看日志

```
kubectl logs vol-test-pod
```

打印包括刚刚写入的环境变量

```
very
```

将创建的ConfigMap中special.how这个key挂载到/etc/config目录下的一个相对路径/keys/special.level。如果存在同名文件，直接覆盖。其他的key不挂载

```
apiVersion: v1
kind: Pod
metadata:
  name: dapi-test-pod
spec:
  containers:
    - name: test-container
      image: gcr.io/google_containers/busybox
      command: [ "/bin/sh","-c","cat /etc/config/keys/special.level" ]
      volumeMounts:
      - name: config-volume
        mountPath: /etc/config
  volumes:
    - name: config-volume
      configMap:
        name: special-config
        items:
        - key: special.how
          path: keys/special.level
  restartPolicy: Never
```

当Pod结束后会输出

```
very
```

### Secret

Secret解决了密码、token、密钥等敏感数据的配置问题，而不需要把这些敏感数据暴露到镜像或者Pod Spec中。Secret可以以Volume或者环境变量的方式使用。

Secret有三种类型：

 ```
- Service Account：用来访问Kubernetes API，由Kubernetes自动创建，并且会自动挂载到Pod的/run/secrets/kubernetes.io/serviceaccount目录中；

- Opaque：base64编码格式的Secret，用来存储密码、密钥等；

- kubernetes.io/dockerconfigjson：用来存储私有docker registry的认证信息。
 ```

#### Opaque Secret

Opaque类型的数据是一个map类型，要求value是base64编码格式

base64转码:

```
echo -n "admin" | base64
```

打印

```
YWRtaW4=
```

还有

```
echo -n "asdlkjcs2" | base64
```

打印

```
YXNkbGtqY3My
```

##### secrets.yaml

```
apiVersion: v1
kind: Secret
metadata:
  name: mysecret
type: Opaque
data:
  password: YXNkbGtqY3My
  username: YWRtaW4=
```

##### 创建

```
kubectl create -f secrets.yaml
```

创建好secret之后，有两种方式来使用它：

```
- 以Volume方式
- 以环境变量方式
```

##### 将Secret挂载到Volume中

```
apiVersion: v1
kind: Pod
metadata:
  labels:
    name: db
  name: db
spec:
  volumes:
  - name: secrets
    secret:
      secretName: mysecret
  containers:
  - image: gcr.io/my_project_id/pg:v1
    name: db
    volumeMounts:
    - name: secrets
      mountPath: "/etc/secrets"
      readOnly: true
    ports:
    - name: cp
      containerPort: 5432
      hostPort: 5432
```

##### 将Secret导出到环境变量中

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: wordpress-deployment
spec:
  replicas: 2
  strategy:
      type: RollingUpdate
  template:
    metadata:
      labels:
        app: wordpress
        visualize: "true"
    spec:
      containers:
      - name: "wordpress"
        image: "wordpress"
        ports:
        - containerPort: 80
        env:
        - name: WORDPRESS_DB_USER
          valueFrom:
            secretKeyRef:
              name: mysecret
              key: username
        - name: WORDPRESS_DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysecret
              key: password
```

##### kubernetes.io/dockerconfigjson

###### 可以直接用kubectl命令来创建用于docker registry认证的secret：

```
kubectl create secret docker-registry myregistrykey --docker-server=DOCKER_REGISTRY_SERVER --docker-username=DOCKER_USER --docker-password=DOCKER_PASSWORD --docker-email=DOCKER_EMAIL
```

打印

```
secret "myregistrykey" created.
```

或者

###### 先进行登录docker registry

```
docker login --username=hatchin666 registry.cn-qingdao.aliyuncs.com
```

查看

```
cat ~/.docker/config.json
```

创建

```
cat ~/.docker/config.json | base64
```

```
cat > myregistrykey.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: myregistrykey
data:
  .dockerconfigjson: ewoJImF1dGhzIjogewoJCSJyZWdpc3RyeS5jbi1xaW5nZGFvLmFsaXl1bmNzLmNvbSI6IHsKCQkJImF1dGgiOiAiYUdGMFkyaHBialkyTmpwNmVHTXhNVEF4TVE9PSIKCQl9Cgl9LAoJIkh0dHBIZWFkZXJzIjogewoJCSJVc2VyLUFnZW50IjogIkRvY2tlci1DbGllbnQvMTguMDkuOSAobGludXgpIgoJfQp9
type: kubernetes.io/dockerconfigjson
EOF
```

###### 在创建Pod的时候，通过`imagePullSecrets`来引用刚创建的`myregistrykey`:

```
apiVersion: v1
kind: Pod
metadata:
  name: foo
spec:
  containers:
    - name: foo
      image: registry.cn-qingdao.aliyuncs.com/caonima/assets:2018-12-07-16-14
  imagePullSecrets:
    - name: myregistrykey
```

##### Service Account

Service Account用来访问Kubernetes API，由Kubernetes自动创建，并且会自动挂载到Pod的`/run/secrets/kubernetes.io/serviceaccount`目录中。

```
kubectl run nginx --image nginx
```

```
kubectl get pods
```

```
kubectl exec nginx-6db489d4b7-rwvp5 ls /run/secrets/kubernetes.io/serviceaccount
```

### Service Account

Service account是为了方便Pod里面的进程调用Kubernetes API或其他外部服务而设计的。它与User account不同

- User account是为人设计的，而service account则是为Pod中的进程调用Kubernetes API而设计；
- User account是跨namespace的，而service account则是仅局限它所在的namespace；
- 每个namespace都会自动创建一个default service account
- Token controller检测service account的创建，并为它们创建secret
- 开启ServiceAccount Admission Controller后
  - 每个Pod在创建后都会自动设置spec.serviceAccount为default（除非指定了其他ServiceAccout）
  - 验证Pod引用的service account已经存在，否则拒绝创建
  - 如果Pod没有指定ImagePullSecrets，则把service account的ImagePullSecrets加到Pod中
  - 每个container启动后都会挂载该service account的token和ca.crt到/var/run/secrets/kubernetes.io/serviceaccount/

- 以Volume方式
- 以环境变量方式

```
$ kubectl exec nginx-3137573019-md1u2 ls /run/secrets/kubernetes.io/serviceaccount
ca.crt
namespace
token
```

#### 创建Service Account

```
kubectl create serviceaccount jenkins
```

打印

```
serviceaccount "jenkins" created
```

查看

```
kubectl get serviceaccounts jenkins -o yaml
```

打印

```
apiVersion: v1
kind: ServiceAccount
metadata:
  creationTimestamp: "2019-10-28T07:37:22Z"
  name: jenkins
  namespace: default
  resourceVersion: "172005"
  selfLink: /api/v1/namespaces/default/serviceaccounts/jenkins
  uid: 6a8e66f4-36ac-4a33-84d9-bdf6ad2784a6
secrets:
- name: jenkins-token-sdp4q
```

自动创建的secret：

```
kubectl get secret jenkins-token-sdp4q -o yaml
```

打印

```
apiVersion: v1
data:
  ca.crt: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUM1ekNDQWMrZ0F3SUJBZ0lCQVRBTkJna3Foa2lHOXcwQkFRc0ZBREFWTVJNd0VRWURWUVFERXdwdGFXNXAKYTNWaVpVTkJNQjRYRFRFNU1UQXlNREF6TWpRMU4xb1hEVEk1TVRBeE9EQXpNalExTjFvd0ZURVRNQkVHQTFVRQpBeE1LYldsdWFXdDFZbVZEUVRDQ0FTSXdEUVlKS29aSWh2Y05BUUVCQlFBRGdnRVBBRENDQVFvQ2dnRUJBTDJmCnluYW52MnBiZzhoTkJZSEprNVIxZ2E1UGZNV21KMlBZK2JuZnc2N0RJNnROMWY1MDUwYjRVTWNZeWNiTWorelUKdzhadEo1MFpmSzNUZHJUem1yalRpSmtkQTFGeWpnb0txbVBDeVc3NmRzRXR4L21nRkllNVYyWTRiUVRSQkFyKwpzRWdnVHdab3h1SXpVK2pEa1piQVg1ZHdNQzFNejd6RmlBMTk3SUQ1aEY4TVRObmwyUCtUT0piRWVUalhNb3V0ClZpbWlhNjU4Zld3SC9yT1hERmJpYm9rUzZwTllRTy9XK1hCK2M2aHptNmVlelRCT05ja3UxNUg3a1ZDSW9POXIKMU4xVlA4emU0QXpTa2t2ZEdnN1p1TU9oRmxkVC9qbk1TbURCdjRabnZlcVhxeVZRTy9jNWlLTW9kL1JzRUhNdwp0V2Z1QVBQTVV2b004dkNXa1VrQ0F3RUFBYU5DTUVBd0RnWURWUjBQQVFIL0JBUURBZ0trTUIwR0ExVWRKUVFXCk1CUUdDQ3NHQVFVRkJ3TUNCZ2dyQmdFRkJRY0RBVEFQQmdOVkhSTUJBZjhFQlRBREFRSC9NQTBHQ1NxR1NJYjMKRFFFQkN3VUFBNElCQVFBMnVldnpLR2I0NmNEWHpTQVBON2F2eUcxa2FaWW9KS0pLbnVBNmQ1SUtsRWZ2dnpYVwpwcEpmaEtsYmp4RkQvQVBCbmlTbUs4emhCSkNQUGszbTYya0VicldBUlAzbWwrNnZ3SCttZGhpUUdSV2x3ZEJzCmFpY1NNbzcwaWtiaEFIeUdwSGtiQVFWSXFvZEl4aDB2ZzhPRExhanEyQXRBNktRTEUxRHBtNjQrZURKYUFlWDMKYlFtQjk5dS9ZOUR0VkpYMWRzbTdsVk9VV0FKZnhNWGEyNm5YcFF1U09xSTdvWWpETVpxNWl5N050RGRhVmVjVwpuT2pXdWQrSjQ4em5iNncvczZqUnZ0Y1l0TDVCUVlHUElPRzZodmJCL1JybWlQbDdQWHgyc1RiWldjRjFsVnRhCnhQWHFZWUNqdXkzNEVTRnNaNklzYm82V0lndUpCSDlVdEJ0aAotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg==
  namespace: ZGVmYXVsdA==
  token: ZXlKaGJHY2lPaUpTVXpJMU5pSXNJbXRwWkNJNklscGtkVFpTVXkxUUxUWjFkMk51TUc1RlZqWllUWHBEUkdSaWNERkNkVFpuWTJkaFUyNVFjRTgzYm5jaWZRLmV5SnBjM01pT2lKcmRXSmxjbTVsZEdWekwzTmxjblpwWTJWaFkyTnZkVzUwSWl3aWEzVmlaWEp1WlhSbGN5NXBieTl6WlhKMmFXTmxZV05qYjNWdWRDOXVZVzFsYzNCaFkyVWlPaUprWldaaGRXeDBJaXdpYTNWaVpYSnVaWFJsY3k1cGJ5OXpaWEoyYVdObFlXTmpiM1Z1ZEM5elpXTnlaWFF1Ym1GdFpTSTZJbXBsYm10cGJuTXRkRzlyWlc0dGMyUndOSEVpTENKcmRXSmxjbTVsZEdWekxtbHZMM05sY25acFkyVmhZMk52ZFc1MEwzTmxjblpwWTJVdFlXTmpiM1Z1ZEM1dVlXMWxJam9pYW1WdWEybHVjeUlzSW10MVltVnlibVYwWlhNdWFXOHZjMlZ5ZG1salpXRmpZMjkxYm5RdmMyVnlkbWxqWlMxaFkyTnZkVzUwTG5WcFpDSTZJalpoT0dVMk5tWTBMVE0yWVdNdE5HRXpNeTA0TkdRNUxXSmtaalpoWkRJM09EUmhOaUlzSW5OMVlpSTZJbk41YzNSbGJUcHpaWEoyYVdObFlXTmpiM1Z1ZERwa1pXWmhkV3gwT21wbGJtdHBibk1pZlEuWUdTVjE4bExVUjRYSjRNbTBLY0Zrb21mOFliS1NnOHBGZHVvcXZkbTNtRERZa21jNUh1YVNfbEVOaW5UY2c5STFTZU5FaXc0aTVLNWwzUTJGV1ZTMjB2U1JfekdhYnRlNTgybl9wblI2eVVGa3R6VjJYcXBUZnBRTFVIOUt2Nk9hT3JOWEd3VElvVW9aNTFLbUtKZkFPVDFtRWcwWU1ya3l6cFA5OUxBZ0lTS3BLNTA0QUlJY2hwQnNmcDhabTZzVWFiUlRzQmcyUHZoSEVqalY0blBsSVR1RVgycTdaU01NN19TLVdUOHVuZllsZ0lzcnU5UFlWNlRtclBPY2JKdlRzMFRQZzJBLU9rQllyaTVYM0E3U0ZGc1RURFo1Zm4ySlVwamFRbTdXNXZCQ2loNmZkM0pGVWxiQzdYZUR2d082S0dxNUNTdnZwVkQxMUVsNW9nbTlR
kind: Secret
metadata:
  annotations:
    kubernetes.io/service-account.name: jenkins
    kubernetes.io/service-account.uid: 6a8e66f4-36ac-4a33-84d9-bdf6ad2784a6
  creationTimestamp: "2019-10-28T07:37:22Z"
  name: jenkins-token-sdp4q
  namespace: default
  resourceVersion: "172004"
  selfLink: /api/v1/namespaces/default/secrets/jenkins-token-sdp4q
  uid: 9fd6e103-84fe-4cae-b4be-3b7cbe14603b
type: kubernetes.io/service-account-token
```

#### 添加ImagePullSecrets

##### 获取yaml模板

```
kubectl get serviceaccount default -o yaml
```

添加

```
apiVersion: v1
kind: ServiceAccount
metadata:
  creationTimestamp: "2019-10-21T03:26:24Z"
  name: default
  namespace: default
  resourceVersion: "349"
  selfLink: /api/v1/namespaces/default/serviceaccounts/default
  uid: d56748e4-3e28-4dc1-8b81-4fd83cc147bf
secrets:
- name: default-token-8k7rj
imagePullSecrets:
- name: myregistrykey
```

##### 授权

Service Account为服务提供了一种方便的认证机制，但它不关心授权的问题。可以配合RBAC来为Service Account鉴权：

- 配置–authorization-mode=RBAC和–runtime-config=rbac.authorization.k8s.io/v1alpha1
- 配置–authorization-rbac-super-user=admin
- 定义Role、ClusterRole、RoleBinding或ClusterRoleBinding

```
# This role allows to read pods in the namespace "default"
kind: Role
apiVersion: rbac.authorization.k8s.io/v1alpha1
metadata:
  namespace: default
  name: pod-reader
rules:
  - apiGroups: [""] # The API group "" indicates the core API Group.
    resources: ["pods"]
    verbs: ["get", "watch", "list"]
    nonResourceURLs: []
---
# This role binding allows "default" to read pods in the namespace "default"
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1alpha1
metadata:
  name: read-pods
  namespace: default
subjects:
  - kind: ServiceAccount # May be "User", "Group" or "ServiceAccount"
    name: default
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

### Resources

- requests : 最小满足
- limits : 最大满足不能超过

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  selector:
    matchLabels:
      app: nginx
  replicas: 2 # indica al controlador que ejecute 2 pods
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.8.0
        resources:
          requests:
            memory: "100Mi"
            cpu: "0.5"
            ephemeral-storage: "100Mi"  #临时存储
          limits:
            memory: "300Mi"
            cpu: "750m"  # 750m=0.75
            ephemeral-storage: "200Mi"  #临时存储
        ports:
        - containerPort: 80
```

#### Qos

```
Qos并不能自己指定等级,而是根据Resources中的request和limit设定的值由系统分配
```

Qos的三个等级:

```
Guaranteed :	CPU/Memory必须相等(request=limit),其余可以不等
Burstable	 :	CPU/Memory不用相等(request!=limit)
BestEffort :	所以资源均不填写
```

#### ResourceQuota

防止该Namespace对于资源的过量使用,保障其他Namespace对资源的使用

```
设置Pod配额以限制可以在名字空间中运行的Pod数量、CPU使用量、内存使用量。
配额通过ResourceQuota对象设置。
```

```
http://docs.kubernetes.org.cn/749.html
```



### Security Context

Security Context的目的是限制不可信容器的行为，保护系统和其他容器不受其影响。

Kubernetes提供了三种配置Security Context的方法：

- Container-level Security Context：仅应用到指定的容器
- Pod-level Security Context：应用到Pod内所有容器以及Volume
- Pod Security Policies（PSP）：应用到集群内部所有Pod以及Volume

#### Container-level Security Context

Container-level Security Context仅应用到指定的容器上，并且不会影响Volume。比如设置容器运行在特权模式：

```
apiVersion: v1
kind: Pod
metadata:
  name: hello-world
spec:
  containers:
    - name: hello-world-container
      # The container definition
      # ...
      securityContext:
        privileged: true
```

#### Pod-level Security Context

Pod-level Security Context应用到Pod内所有容器，并且还会影响Volume（包括fsGroup和selinuxOptions）。

```
apiVersion: v1
kind: Pod
metadata:
  name: hello-world
spec:
  containers:
  # specification of the pod's containers
  # ...
  securityContext:
    fsGroup: 1234
    supplementalGroups: [5678]
    seLinuxOptions:
      level: "s0:c123,c456"
```

#### Pod Security Policies（PSP）

Pod Security Policies（PSP）是集群级的Pod安全策略，自动为集群内的Pod和Volume设置Security Context。

使用PSP需要API Server开启extensions/v1beta1/podsecuritypolicy，并且配置PodSecurityPolicyadmission控制器。

##### 支持的控制项

```
控制项																说明
privileged													运行特权容器
defaultAddCapabilities							可添加到容器的Capabilities
requiredDropCapabilities						会从容器中删除的Capabilities
volumes															控制容器可以使用哪些volume
hostNetwork													host网络
hostPorts														允许的host端口列表
hostPID															使用host PID namespace
hostIPC															使用host IPC namespace
seLinux															SELinux Context
runAsUser														user ID
supplementalGroups									允许的补充用户组
fsGroup															volume FSGroup
readOnlyRootFilesystem							只读根文件系统
```

##### 示例

限制容器的host端口范围为8000-8080：

```
apiVersion: extensions/v1beta1
kind: PodSecurityPolicy
metadata:
  name: permissive
spec:
  seLinux:
    rule: RunAsAny
  supplementalGroups:
    rule: RunAsAny
  runAsUser:
    rule: RunAsAny
  fsGroup:
    rule: RunAsAny
  hostPorts:
  - min: 8000
    max: 8080
  volumes:
  - '*'
```

#### SELinux

SELinux (Security-Enhanced Linux) 是一种强制访问控制（mandatory access control）的实现。它的作法是以最小权限原则（principle of least privilege）为基础，在Linux核心中使用Linux安全模块（Linux Security Modules）。SELinux主要由美国国家安全局开发，并于2000年12月22日发行给开放源代码的开发社区。

可以通过runcon来为进程设置安全策略，ls和ps的-Z参数可以查看文件或进程的安全策略。

`开启与关闭SELinux:`

```
修改/etc/selinux/config文件方法：
开启：SELINUX=enforcing
关闭：SELINUX=disabled

通过命令临时修改：
开启：setenforce 1
关闭：setenforce 0
```

`查询SELinux状态:`

```
getenforce
```

```
apiVersion: v1
kind: Pod
metadata:
  name: hello-world
spec:
  containers:
  - image: gcr.io/google_containers/busybox:1.24
    name: test-container
    command:
    - sleep
    - "6000"
    volumeMounts:
    - mountPath: /mounted_volume
      name: test-volume
  restartPolicy: Never
  hostPID: false
  hostIPC: false
  securityContext:
    seLinuxOptions:
      level: "s0:c2,c3"
  volumes:
  - name: test-volume
    emptyDir: {}
```

这会自动给docker容器生成如下的HostConfig.Binds:

```
/var/lib/kubelet/pods/f734678c-95de-11e6-89b0-42010a8c0002/volumes/kubernetes.io~empty-dir/test-volume:/mounted_volume:Z
/var/lib/kubelet/pods/f734678c-95de-11e6-89b0-42010a8c0002/volumes/kubernetes.io~secret/default-token-88xxa:/var/run/secrets/kubernetes.io/serviceaccount:ro,Z
/var/lib/kubelet/pods/f734678c-95de-11e6-89b0-42010a8c0002/etc-hosts:/etc/hosts
```

对应的volume也都会正确设置SELinux：

```
ls -Z /var/lib/kubelet/pods/f734678c-95de-11e6-89b0-42010a8c0002/volumes
```

打印

```
drwxr-xr-x. root root unconfined_u:object_r:svirt_sandbox_file_t:s0:c2,c3 kubernetes.io~empty-dir
drwxr-xr-x. root root unconfined_u:object_r:svirt_sandbox_file_t:s0:c2,c3 kubernetes.io~secret
```

### Init Container

Init Container在所有容器运行之前执行（run-to-completion），常用来初始化配置。initContainer是服务于普通Container的container

```
apiVersion: v1
kind: Pod
metadata:
  name: init-demo
spec:
  containers:
  - name: nginx
    image: nginx
    ports:
    - containerPort: 80
    volumeMounts:
    - name: workdir
      mountPath: /usr/share/nginx/html
  # These containers are run during pod initialization
  initContainers:
  - name: install
    image: busybox
    command:
    - wget
    - "-O"
    - "/work-dir/index.html"
    - http://kubernetes.io
    volumeMounts:
    - name: workdir
      mountPath: "/work-dir"
  dnsPolicy: Default
  volumes:
  - name: workdir
    emptyDir: {}
```



## 资源调度





## 探针

Liveness and Readiness Probes

liveness和readiness两种探针均可以三种方式实现:

```
1.Exec
2.httpGet
3.tcpSocket
```

```
https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/
```

### Liveness

LivenessProbe探针:用于判断容器是否存活(Running状态),如果LivenessProbe探针探测到容器不健康,则kubelet将杀掉该容器,并根据容器的重启策略作相应的处理。如果一个容器被创建时不包含LivenessProbe探针,那么kubelet认为该容器的LivenessProbe探针返回的值永远为Success。

### Readiness

ReadinessProbe探针:用户判断容器服务是否可用(Ready状态),达到Ready状态的Pod才可以接收请求(Service和Pod之间的通道才可以打开从而让外不可以访问Pod中的服务)。对于被Service管理的Pod,Service与Pod Endpoint的关联关系也将基于Pod是否Ready进行设置。如果在运行过程中Ready状态变为False,则系统自动将其从Service的后端Endpoint列表中剥离出去,后续再把恢复到Ready状态的Pod加回后端Endpoint列表。这样就能保证客户端在访问Service时不会被转发到服务不可用的Pod实例上。

### 实现

#### exec

```
apiVersion: v1
kind: Pod
metadata:
  labels:
    test: liveness
  name: liveness-exec
spec:
  containers:
  - name: liveness
    image: nginx
    args:
    - /bin/sh
    - -c
    - touch /tmp/healthy; sleep 30; rm -rf /tmp/healthy; sleep 600
    livenessProbe:
      exec:
        command:
        - cat
        - /tmp/healthy
      initialDelaySeconds: 5
      periodSeconds: 5
```

```
- 该配置文件给Pod配置了一个容器。periodSeconds 规定kubelet要每隔5秒执行一次liveness probe。 initialDelaySeconds 告诉kubelet在第一次执行probe之前要的等待5秒钟。探针检测命令是在容器中执行 cat /tmp/healthy 命令。如果命令执行成功，将返回0，kubelet就会认为该容器是活着的并且很健康。如果返回非0值，kubelet就会杀掉这个容器并重启它。

- 容器启动时，执行该命令：
/bin/sh -c "touch /tmp/healthy; sleep 30; rm -rf /tmp/healthy; sleep 600"

- 在容器生命的最初30秒内有一个 /tmp/healthy 文件，在这30秒内 cat /tmp/healthy命令会返回一个成功的返回码。30秒后， cat /tmp/healthy 将返回失败的返回码。

- 在容器刚刚创建的30秒内查看容器Event会发现容器启动,但是30秒后Liveness执行后会发现容器被重启并且可以在kubectl get pods的返回结果中查看到restart的增加。
```

#### httpGet

##### nginx镜像

```
apiVersion: v1
kind: Pod
metadata:
  labels:
    test: liveness
  name: liveness-http
spec:
  containers:
  - name: liveness
    args:
    image: nginx
    livenessProbe:
      httpGet:
        path: /
        port: 80
#        httpHeaders:
#          - name: X-Custom-Header
#            value: Awesome
      initialDelaySeconds: 3
      periodSeconds: 3
```

nginx会一直可以通。。。。

##### liveness镜像

```
apiVersion: v1
kind: Pod
metadata:
  labels:
    test: liveness
  name: liveness-http
spec:
  containers:
  - name: liveness
    args:
    - /server
    image: gcr.io/google_containers/liveness
    livenessProbe:
      httpGet:
        path: /healthz
        port: 8080
        httpHeaders:
          - name: X-Custom-Header
            value: Awesome
      initialDelaySeconds: 3
      periodSeconds: 3
```

```
- 该配置文件只定义了一个容器，livenessProbe 指定kubelete需要每隔3秒执行一次liveness probe。initialDelaySeconds 指定kubelet在该执行第一次探测之前需要等待3秒钟。该探针将向容器中的server的8080端口发送一个HTTP GET请求。如果server的/healthz路径的handler返回一个成功的返回码，kubelet就会认定该容器是活着的并且很健康。如果返回失败的返回码，kubelet将杀掉该容器并重启它。

- 任何大于200小于400的返回码都会认定是成功的返回码。其他返回码都会被认为是失败的返回码。
```

查看liveness镜像中该server的源码：server.go

```
http.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
    duration := time.Now().Sub(started)
    if duration.Seconds() > 10 {
        w.WriteHeader(500)
        w.Write([]byte(fmt.Sprintf("error: %v", duration.Seconds())))
    } else {
        w.WriteHeader(200)
        w.Write([]byte("ok"))
    }
})
```

```
- 最开始的10秒该容器是活着的， /healthz handler返回200的状态码。这之后将返回500的返回码。

- 容器启动3秒后，kubelet开始执行健康检查。第一次健康监测会成功，但是10秒后，健康检查将失败，kubelet将杀掉和重启容器。
```

#### tcpSocket

```
apiVersion: v1
kind: Pod
metadata:
  name: goproxy
  labels:
    app: goproxy
spec:
  containers:
  - name: goproxy
    image: k8s.gcr.io/goproxy:0.1
    ports:
    - containerPort: 8080
    readinessProbe:
      tcpSocket:
        port: 8080
      initialDelaySeconds: 5
      periodSeconds: 10
    livenessProbe:
      tcpSocket:
        port: 8080
      initialDelaySeconds: 15
      periodSeconds: 20
```

```
- liveness probe使用TCP Socket,kubelet将尝试在指定端口上打开容器的套接字。 如果可以建立连接，容器被认为是健康的，如果不能就认为是失败的。

- TCP检查的配置与HTTP检查非常相似。上述示例同时使用了readiness和liveness probe。 容器启动后5秒钟，kubelet将发送第一个readiness probe。 这将尝试连接到端口8080上的goproxy容器。如果探测成功，则该pod将被标记为就绪。Kubelet将每隔10秒钟执行一次该检查。

- 除了readiness probe之外，该配置还包括liveness probe。 容器启动15秒后，kubelet将运行第一个liveness probe。 就像readiness probe一样，这将尝试连接到goproxy容器上的8080端口。如果liveness probe失败，容器将重新启动。
```

#### 使用命名的端口

可以使用命名的ContainerPort作为HTTP或TCP liveness检查：

```
ports:
- name: liveness-port
  containerPort: 8080
  hostPort: 8080

livenessProbe:
  httpGet:
  path: /healthz
  port: liveness-port
```

#### 定义readiness探针

有时，应用程序暂时无法对外部流量提供服务。 例如，应用程序可能需要在启动期间加载大量数据或配置文件。 在这种情况下，你不想杀死应用程序，但你也不想发送请求。 Kubernetes提供了readiness probe来检测和减轻这些情况。 Pod中的容器可以报告自己还没有准备，不能处理Kubernetes服务发送过来的流量。

Readiness probe的配置跟liveness probe很像。唯一的不同是使用 `readinessProbe`而不是`livenessProbe`。

```
readinessProbe:
  exec:
    command:
    - cat
    - /tmp/healthy
  initialDelaySeconds: 5
  periodSeconds: 5
```

Readiness probe的HTTP和TCP的探测器配置跟liveness probe一样。

Readiness和livenss probe可以并行用于同一容器。 使用两者可以确保流量无法到达未准备好的容器，并且容器在失败时重新启动。

### 配置Probe

Probe中有很多精确和详细的配置，通过它们你能准确的控制liveness和readiness检查：

- `initialDelaySeconds`：容器启动后第一次执行探测是需要等待多少秒。
- `periodSeconds`：执行探测的频率。默认是10秒，最小1秒。
- `timeoutSeconds`：探测超时时间。默认1秒，最小1秒。
- `successThreshold`：探测失败后，最少连续探测成功多少次才被认定为成功。默认是1。对于liveness必须是1。最小值是1。
- `failureThreshold`：探测成功后，最少连续探测失败多少次才被认定为失败。默认是3。最小值是1。

HTTP probe中可以给 `httpGet`设置其他配置项：

- `host`：连接的主机名，默认连接到pod的IP。你可能想在http header中设置”Host”而不是使用IP。
- `scheme`：连接使用的schema，默认HTTP。
- `path`: 访问的HTTP server的path。
- `httpHeaders`：自定义请求的header。HTTP运行重复的header。
- `port`：访问的容器的端口名字或者端口号。端口号必须介于1和65525之间。

对于HTTP探测器，kubelet向指定的路径和端口发送HTTP请求以执行检查。 Kubelet将probe发送到容器的IP地址，除非地址被`httpGet`中的可选`host`字段覆盖。 在大多数情况下，你不想设置主机字段。 有一种情况下你可以设置它。 假设容器在127.0.0.1上侦听，并且Pod的`hostNetwork`字段为true。 然后，在`httpGet`下的`host`应该设置为127.0.0.1。 如果你的pod依赖于虚拟主机，这可能是更常见的情况，你不应该是用`host`，而是应该在`httpHeaders`中设置`Host`头。



## 容器远程调试

#### 调试pod

##### 进入一个正在运行的pod

```
kubectl exec -it pod-name /bin/bash
```

##### 进入一个正在运行并包含多个容器的pod

```
kubectl exec -it pod-name -c container-name /bin/bash
```

#### 调试service

##### 将本地应用代理到集群中的一个service上

`Telepresence`

```
Telepresence --swap-deployment deployment-name
```

```
https://www.kubernetes.org.cn/5313.html
```

##### 本地开发的应用需要调用集群中的服务时

`Port-Forward`

```
kubectl port-forward svc/app -n app-namespace 本地端口:pod端口
```

```
https://blog.csdn.net/qq_21816375/article/details/80165167
```

##### kubectl debug

```
kubectl debug 远程pod-name
```

之后可以进行各种调试操作

```
例:
# hostname
# ps -ef
# netstat
等...

# logout #退出
```

```
kubectl debug 远程pod-name --image 镜像名 
#(后面的--image 是引入其他镜像中所需要的命令行工具 例如:redis-cli等)
```

```
https://blog.csdn.net/weixin_33698043/article/details/91440144
```



## Monitor

### kube-eventer

```
https://github.com/AliyunContainerService/kube-eventer
```

```
支持钉钉、微信、Kafka、ES等推送↓↓↓
```

```
Sink Name        Description
dingtalk				 sink to dingtalk bot
sls							 sink to alibaba cloud sls service
elasticsearch		 sink to elasticsearch
honeycomb				 sink to honeycomb
influxdb	 			 sink to influxdb
kafka						 sink to kafka
mysql					   sink to mysql database
wechat					 sink to wechat
```

#### Install eventer and configure sink

```
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    name: kube-eventer
  name: kube-eventer
  namespace: kube-system
spec:
  replicas: 1
  selector:
    matchLabels:
      app: kube-eventer
  template:
    metadata:
      labels:
        app: kube-eventer
      annotations:      
        scheduler.alpha.kubernetes.io/critical-pod: ''
    spec:
      dnsPolicy: ClusterFirstWithHostNet
      serviceAccount: kube-eventer
      containers:
        - image: registry.aliyuncs.com/acs/kube-eventer-amd64:v1.1.0-63e7f98-aliyun
          name: kube-eventer
          command:
            - "/kube-eventer"
            - "--source=kubernetes:https://kubernetes.default"
            ## .e.g,dingtalk sink demo
            #- --sink=dingtalk:[your_webhook_url]&label=[your_cluster_id]&level=[Normal or Warning(default)]
            - --sink=wechat:?corp_id=ww8bc26de785bce8d8&corp_secret=88-DWQxgsdYt4is99D87c-5Dl6voKgnJN60vrf8ISNs&agent_id=1000002&&level=Warning
            #- --sink=wechat:?corp_id=<your_corp_id>&corp_secret=<your_corp_secret>&agent_id=<your_agent_id>&to_user=<to_user>&label=<your_cluster_id>&level=<Normal or Warning, Warning default>
          env:
          # If TZ is assigned, set the TZ value as the time zone
          - name: TZ
            value: America/New_York
          volumeMounts:
            - name: localtime
              mountPath: /etc/localtime
              readOnly: true
            - name: zoneinfo
              mountPath: /usr/share/zoneinfo
              readOnly: true
          resources:
            requests:
              cpu: 100m
              memory: 100Mi
            limits:
              cpu: 500m
              memory: 250Mi
      volumes:
        - name: localtime
          hostPath:
            path: /etc/localtime
        - name: zoneinfo
          hostPath:
            path: /usr/share/zoneinfo
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: kube-eventer
rules:
  - apiGroups:
      - ""
    resources:
      - events
    verbs:
      - get
      - list
      - watch
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  annotations:
  name: kube-eventer
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: kube-eventer
subjects:
  - kind: ServiceAccount
    name: kube-eventer
    namespace: kube-system
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: kube-eventer
  namespace: kube-system
```

#### sink举例(微信)

```
--sink=wechat:?corp_id=<your_corp_id>&corp_secret=<your_corp_secret>&agent_id=<your_agent_id>&to_user=<to_user>&label=<your_cluster_id>&level=<Normal or Warning, Warning default>
```

```
https://github.com/AliyunContainerService/kube-eventer/blob/master/docs/en/wechat-sink.md
```

```
https://www.jianshu.com/p/02a692d67b78
```



## Service 

#### 集群内访问service

- ##### 直接访问service 的虚拟IP

  ```
  kubectl get svc
  #查询到的Cluster-IP + service端口
  ```

- ##### 直接访问服务名,依靠集群内DNS解析

  ###### 同一个namespace中

  ```
  curl service-name + service端口
  ```

  ###### 不同的namespace中

  ```
  curl service-name.namespace + service端口
  ```

- ##### 通过环境变量访问

  以service-name为my-service,service端口为80为例

  ```
  curl $MY_SERVICE_HOST:$MY_SERVICE_SERVICE_PORT
  ```

#### Headless Service

Headless Service指定Service的ClusterIP为None

```
- Pod通过service_name方式直接解析到所有后端的PodIP

- 客户端应用自主选择需要访问的Pod
```



## ETCD

### 查看ETCD状态

```
etcdctl --endpoints=https://127.0.0.1:2379 --ca-file=/etc/kubernetes/pki/etcd/ca.crt --cert-file=/etc/kubernetes/pki/etcd/healthcheck-client.crt --key-file=/etc/kubernetes/pki/etcd/healthcheck-client.key cluster-health
```

### 查看ETCD成员

```
etcdctl --endpoints=https://127.0.0.1:2379 --ca-file=/etc/kubernetes/pki/etcd/ca.crt --cert-file=/etc/kubernetes/pki/etcd/healthcheck-client.crt --key-file=/etc/kubernetes/pki/etcd/healthcheck-client.key member list
```



## Volume

in-tree:kubernetes支持的nfs、hostpath、gcepersistentdisk等

out-of-tree:使用flex和csi插件等

### Kubernete 支持如下类型的volume:

```
emptyDir

hostPath

gcePersistentDisk

awsElasticBlockStore

nfs

iscsi

glusterfs

rbd

gitRepo

secret

persistentVolumeClaim
```

#### emptyDir

如果 Pod 设置了 emptyDir 类型 Volume， Pod 被分配到 Node 上时候，会创建 emptyDir，只要 Pod 运行在 Node 上，emptyDir 都会存在（容器挂掉不会导致 emptyDir 丢失数据），但是如果 Pod 从 Node 上被删除（Pod 被删除，或者 Pod 发生迁移），emptyDir 也会被删除，并且永久丢失。

```
apiVersion: v1
kind: Pod
metadata:
  name: test-pd
spec:
  containers:
  - image: gcr.io/google_containers/test-webserver
    name: test-container
    volumeMounts:
    - mountPath: /cache
      name: cache-volume
  volumes:
  - name: cache-volume
    emptyDir: {}
```

#### hostPath

hostPath 允许挂载 Node 上的文件系统到 Pod 里面去。如果 Pod 需要使用 Node 上的文件，可以使用 hostPath。

```
apiVersion: v1
kind: Pod
metadata:
  name: test-pd
spec:
  containers:
  - image: gcr.io/google_containers/test-webserver
    name: test-container
    volumeMounts:
    - mountPath: /test-pd
      name: test-volume
  volumes:
  - name: test-volume
    hostPath:
      path: /data
```

#### NFS

NFS 是 Network File System 的缩写，即网络文件系统。Kubernetes 中通过简单地配置就可以挂载 NFS 到 Pod 中，而 NFS 中的数据是可以永久保存的，同时 NFS 支持同时写操作。

```
volumes:
- name: nfs
  nfs:
    # FIXME: use the right hostname
    server: 10.254.234.223
    path: "/"
```

完整版部署mysql

```
apiVersion: v1
kind: Service
metadata:
  name: wordpress-mysql
  labels:
    app: wordpress
spec:
  ports:
    - port: 3306
  selector:
    app: wordpress
    tier: mysql
  clusterIP: None
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: wordpress-mysql
  labels:
    app: wordpress
    tier: mysql
spec:
  selector:
    matchLabels:
      app: wordpress
      tier: mysql
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: wordpress
        tier: mysql
    spec:
      containers:
      - image: mysql:5.6
        name: mysql
        env:
        - name: MYSQL_ROOT_PASSWORD
          value: changeme
        ports:
        - containerPort: 3306
          name: mysql
        volumeMounts:
        - name: nfs
          mountPath: /var/lib/mysql
      volumes:
      - name: nfs
        nfs:
          server: 192.168.240.123
          path: "/nfs/jb/"
```



#### gcePersistentDisk

gcePersistentDisk 可以挂载 GCE 上的永久磁盘到容器，需要 Kubernetes 运行在 GCE 的 VM 中。

```
volumes:
  - name: test-volume
    # This GCE PD must already exist.
    gcePersistentDisk:
      pdName: my-data-disk
      fsType: ext4
```

#### awsElasticBlockStore

awsElasticBlockStore 可以挂载 AWS 上的 EBS 盘到容器，需要 Kubernetes 运行在 AWS 的 EC2 上。

```
volumes:
  - name: test-volume
    # This AWS EBS volume must already exist.
    awsElasticBlockStore:
      volumeID: <volume-id>
      fsType: ext4
```

#### gitRepo

gitRepo volume 将 git 代码下拉到指定的容器路径中

```
  volumes:
  - name: git-volume
    gitRepo:
      repository: "git@somewhere:me/my-git-repository.git"
      revision: "22f1d8406d464b0c0874075539c1f2e96c253775"
```

#### subPath

Pod 的多个容器使用同一个 Volume 时，subPath 非常有用

```
apiVersion: v1
kind: Pod
metadata:
  name: my-lamp-site
spec:
    containers:
    - name: mysql
      image: mysql
      volumeMounts:
      - mountPath: /var/lib/mysql
        name: site-data
        subPath: mysql #建立子目录mysql
    - name: php
      image: php
      volumeMounts:
      - mountPath: /var/www/html
        name: site-data
        subPath: html #建立子目录html
    volumes:
    - name: site-data
      persistentVolumeClaim:
        claimName: my-lamp-site-data
```

#### FlexVolume

如果内置的这些 Volume 不满足要求，则可以使用 FlexVolume 实现自己的 Volume 插件。注意要把 volume plugin 放到 `/usr/libexec/kubernetes/kubelet-plugins/volume/exec//`

plugin 要实现 `init/attach/detach/mount/umount` 等命令。

```
  - name: test
    flexVolume:
      driver: "kubernetes.io/lvm"
      fsType: "ext4"
      options:
        volumeID: "vol1"
        size: "1000m"
        volumegroup: "kube_vg"
```

### PV/PVC

PersistentVolume (PV) 和 PersistentVolumeClaim (PVC) 提供了方便的持久化卷：PV 提供网络存储资源，而 PVC 请求存储资源。这样，设置持久化的工作流包括配置底层文件系统或者云数据卷、创建持久性数据卷、最后创建 PVC 来将 Pod 跟数据卷关联起来。PV 和 PVC 可以将 pod 和数据卷解耦，pod 不需要知道确切的文件系统或者支持它的持久化引擎

Volume 的生命周期包括 5 个阶段

1. Provisioning，即 PV 的创建，可以直接创建 PV（静态方式），也可以使用 StorageClass 动态创建
2. Binding，将 PV 分配给 PVC
3. Using，Pod 通过 PVC 使用该 Volume，并可以通过准入控制 StorageObjectInUseProtection（1.9 及以前版本为 PVCProtection）阻止删除正在使用的 PVC
4. Releasing，Pod 释放 Volume 并删除 PVC
5. Reclaiming，回收 PV，可以保留 PV 以便下次使用，也可以直接从云存储中删除
6. Deleting，删除 PV 并从云存储中删除后段存储

根据这 5 个阶段，Volume 的状态有以下 4 种

- Available：可用
- Bound：已经分配给 PVC
- Released：PVC 解绑但还未执行回收策略
- Failed：发生错误

#### pv

PersistentVolume（PV）是集群之中的一块网络存储。跟 Node 一样，也是集群的资源。PV 跟 Volume (卷) 类似，不过会有独立于 Pod 的生命周期。

比如一个 NFS 的 PV 可以定义为

```
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv0003
spec:
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Recycle
  nfs:
    path: /tmp
    server: 172.17.0.2
```

PV 的访问模式（accessModes）有三种：

- ReadWriteOnce（RWO）：是最基本的方式，可读可写，但只支持被单个节点挂载。
- ReadOnlyMany（ROX）：可以以只读的方式被多个节点挂载。
- ReadWriteMany（RWX）：这种存储可以以读写的方式被多个节点共享。不是每一种存储都支持这三种方式，像共享方式，目前支持的还比较少，比较常用的是 NFS。在 PVC 绑定 PV 时通常根据两个条件来绑定，一个是存储的大小，另一个就是访问模式。

PV 的回收策略（persistentVolumeReclaimPolicy，即 PVC 释放卷的时候 PV 该如何操作）也有三种

- Retain，不清理, 保留 Volume（需要手动清理）
- Recycle，删除数据，即 `rm -rf /thevolume/*`（只有 NFS 和 HostPath 支持）
- Delete，删除存储资源，比如删除 AWS EBS 卷（只有 AWS EBS, GCE PD, Azure Disk 和 Cinder 支持）

#### storageclass

上面通过手动的方式创建了一个 NFS Volume，这在管理很多 Volume 的时候不太方便。Kubernetes 还提供了StorageClass来动态创建 PV，不仅节省了管理员的时间，还可以封装不同类型的存储供 PVC 选用。

StorageClass 包括四个部分

- provisioner：指定 Volume 插件的类型，包括内置插件（如 `kubernetes.io/glusterfs`）和外部插件（如external-storage提供的 `ceph.com/cephfs`）。
- mountOptions：指定挂载选项，当 PV 不支持指定的选项时会直接失败。比如 NFS 支持 `hard` 和 `nfsvers=4.1` 等选项。
- parameters：指定 provisioner 的选项，比如 `kubernetes.io/aws-ebs` 支持 `type`、`zone`、`iopsPerGB` 等参数。
- reclaimPolicy：指定回收策略，同 PV 的回收策略。

在使用 PVC 时，可以通过 `DefaultStorageClass` 准入控制设置默认 StorageClass, 即给未设置 storageClassName 的 PVC 自动添加默认的 StorageClass。而默认的 StorageClass 带有 annotation `storageclass.kubernetes.io/is-default-class=true`。

##### ceph rbd storageclass示例

```
apiVersion: storage.k8s.io/v1
  kind: StorageClass
  metadata:
    name: fast
  provisioner: kubernetes.io/rbd
  parameters:
    monitors: 10.16.153.105:6789
    adminId: kube
    adminSecretName: ceph-secret
    adminSecretNamespace: kube-system
    pool: kube
    userId: kube
    userSecretName: ceph-secret-user
```

#### 静态(nfs)

以部署elasticsearch为例

##### pv

```
apiVersion: v1
kind: PersistentVolume
metadata:
  name: es-pv-1
  namespace: ns-elasticsearch
spec:
  capacity: #存储大小
    storage: 900G
  accessModes:
    - ReadWriteMany #该volume可以被多个node上的pod挂载并具有读写权限
  persistentVolumeReclaimPolicy: Recycle
  nfs:
    server: 192.168.240.60
    path: /data/ES-data-1
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: es-pv-2
  namespace: ns-elasticsearch
spec:
  capacity:
    storage: 900G
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Recycle
  nfs:
    server: 192.168.240.61
    path: /data/ES-data-2
```

##### pvc

```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: es-pvc-1
  namespace: ns-elasticsearch
spec:
  accessModes:
    - ReadWriteMany
  volumeName: es-pv-1
  resources:
    requests:
      storage: 900G
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: es-pvc-2
  namespace: ns-elasticsearch
spec:
  accessModes:
    - ReadWriteMany
  volumeName: es-pv-2
  resources:
    requests:
      storage: 900G
```

##### 创建应用

```
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    elastic-app: elasticsearch
  name: elasticsearch-admin
  namespace: ns-elasticsearch

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: elasticsearch-admin
  labels:
    elastic-app: elasticsearch
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
  - kind: ServiceAccount
    name: elasticsearch-admin
    namespace: ns-elasticsearch

---
kind: Deployment
apiVersion: apps/v1beta2
metadata:
  labels:
    elastic-app: elasticsearch
    role: master
  name: elasticsearch-master
  namespace: ns-elasticsearch
spec:
  replicas: 2
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      elastic-app: elasticsearch
      role: master
  template:
    metadata:
      labels:
        elastic-app: elasticsearch
        role: master
    spec:
      containers:
        - name: elasticsearch-master
          image: 192.168.240.73/fuck/elasticsearch:k8s
          lifecycle:
            postStart:
              exec:
                command: ["/bin/bash", "-c", "sysctl -w vm.max_map_count=262144; ulimit -l unlimited;"]
          ports:
            - containerPort: 9200
              protocol: TCP
            - containerPort: 9300
              protocol: TCP
          env:
            - name: "cluster.name"
              value: "elasticsearch-cluster"
            - name: "bootstrap.memory_lock"
              value: "true"
            - name: "discovery.zen.ping.unicast.hosts"
              value: "elasticsearch-discovery"
            - name: "discovery.zen.minimum_master_nodes"
              value: "2"
            - name: "discovery.zen.ping_timeout"
              value: "5s"
            - name: "node.master"
              value: "true"
            - name: "node.data"
              value: "false"
            - name: "node.ingest"
              value: "false"
            - name: "ES_JAVA_OPTS"
              value: "-Xms256m -Xmx256m"
          securityContext:
            privileged: true
      serviceAccountName: elasticsearch-admin
      tolerations:
        - key: node-role.kubernetes.io/master
          effect: NoSchedule

---
kind: Service
apiVersion: v1
metadata:
  labels:
    elastic-app: elasticsearch
  name: elasticsearch-discovery
  namespace: ns-elasticsearch
spec:
  ports:
    - port: 9300
      targetPort: 9300
  selector:
    elastic-app: elasticsearch
    role: master

---
kind: Deployment
apiVersion: apps/v1beta2
metadata:
  labels:
    elastic-app: elasticsearch
    role: data
  name: elasticsearch-data-1
  namespace: ns-elasticsearch
spec:
  replicas: 1
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      elastic-app: elasticsearch
  template:
    metadata:
      labels:
        elastic-app: elasticsearch
        role: data
    spec:
      containers:
        - name: elasticsearch-data-1
          image: 192.168.240.73/fuck/elasticsearch:k8s
          lifecycle:
            postStart:
              exec:
                command: ["/bin/bash", "-c", "sysctl -w vm.max_map_count=262144; ulimit -l unlimited;"]
          ports:
            - containerPort: 9200
              protocol: TCP
            - containerPort: 9300
              protocol: TCP
          volumeMounts:
            - name: esdata-1
              mountPath: /usr/share/elasticsearch/data
          env:
            - name: "cluster.name"
              value: "elasticsearch-cluster"
            - name: "bootstrap.memory_lock"
              value: "true"
            - name: "discovery.zen.ping.unicast.hosts"
              value: "elasticsearch-discovery"
            - name: "node.master"
              value: "false"
            - name: "node.data"
              value: "true"
            - name: "ES_JAVA_OPTS"
              value: "-Xms256m -Xmx256m"
          securityContext:
            privileged: true
      serviceAccountName: elasticsearch-admin
      tolerations:
        - key: node-role.kubernetes.io/master
          effect: NoSchedule
      volumes:
      - name: esdata-1
        persistentVolumeClaim:
          claimName: es-pvc-1

---
kind: Service
apiVersion: v1
metadata:
  labels:
    elastic-app: elasticsearch-service
  name: elasticsearch-service
  namespace: ns-elasticsearch
spec:
  ports:
    - port: 9200
      targetPort: 9200
      nodePort: 30007
  selector:
    elastic-app: elasticsearch
  type: NodePort

---
kind: Deployment
apiVersion: apps/v1beta2
metadata:
  labels:
    elastic-app: elasticsearch
    role: data
  name: elasticsearch-data-2
  namespace: ns-elasticsearch
spec:
  replicas: 1
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      elastic-app: elasticsearch
  template:
    metadata:
      labels:
        elastic-app: elasticsearch
        role: data
    spec:
      containers:
        - name: elasticsearch-data-2
          image: 192.168.240.73/fuck/elasticsearch:k8s
          lifecycle:
            postStart:
              exec:
                command: ["/bin/bash", "-c", "sysctl -w vm.max_map_count=262144; ulimit -l unlimited;"]
          ports:
            - containerPort: 9200
              protocol: TCP
            - containerPort: 9300
              protocol: TCP
          volumeMounts:
            - name: esdata-2
              mountPath: /usr/share/elasticsearch/data
          env:
            - name: "cluster.name"
              value: "elasticsearch-cluster"
            - name: "bootstrap.memory_lock"
              value: "true"
            - name: "discovery.zen.ping.unicast.hosts"
              value: "elasticsearch-discovery"
            - name: "node.master"
              value: "false"
            - name: "node.data"
              value: "true"
            - name: "ES_JAVA_OPTS"
              value: "-Xms256m -Xmx256m"
          securityContext:
            privileged: true
      serviceAccountName: elasticsearch-admin
      tolerations:
        - key: node-role.kubernetes.io/master
          effect: NoSchedule
      volumes:
        - name: esdata-2
          persistentVolumeClaim:
            claimName: es-pvc-2
```

#### 动态(cephfs)

##### StorageClass

```
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: csi-cephfs
provisioner: rook-ceph.cephfs.csi.ceph.com
parameters:
  # clusterID is the namespace where operator is deployed.
  clusterID: rook-ceph

  # CephFS filesystem name into which the volume shall be created
  fsName: myfs

  # Ceph pool into which the volume shall be created
  # Required for provisionVolume: "true"
  pool: myfs-data0

  # Root path of an existing CephFS volume
  # Required for provisionVolume: "false"
  # rootPath: /absolute/path

  # The secrets contain Ceph admin credentials. These are generated automatically by the operator
  # in the same namespace as the cluster.
  csi.storage.k8s.io/provisioner-secret-name: rook-csi-cephfs-provisioner
  csi.storage.k8s.io/provisioner-secret-namespace: rook-ceph
  csi.storage.k8s.io/node-stage-secret-name: rook-csi-cephfs-node
  csi.storage.k8s.io/node-stage-secret-namespace: rook-ceph

  # (optional) The driver can use either ceph-fuse (fuse) or ceph kernel client (kernel)
  # If omitted, default volume mounter will be used - this is determined by probing for ceph-fuse
  # or by setting the default mounter explicitly via --volumemounter command-line argument.
  # mounter: kernel
reclaimPolicy: Retain
mountOptions:
  # uncomment the following line for debugging
  #- debug
```

##### pvc

```
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: cephfs-pvc
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: csi-cephfs
```

##### 创建应用

```
---
apiVersion: v1
kind: Pod
metadata:
  name: csicephfs-demo-pod
spec:
  containers:
   - name: web-server
     image: nginx
     volumeMounts:
       - name: mypvc
         mountPath: /var/lib/www/html
  volumes:
   - name: mypvc
     persistentVolumeClaim:
       claimName: cephfs-pvc
       readOnly: false
```



















































