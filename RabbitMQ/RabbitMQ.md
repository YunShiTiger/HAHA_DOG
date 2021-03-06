# RabbitMQ

[参考]

```
https://www.kubernetes.org.cn/4679.html
```

## 配置文件

### 原配置文件

[根据不同服务器配置文件不同，按照'原配置文件'进行修改]

```
apiVersion: v1
kind: Namespace
metadata:
  name: rabbitmq
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: rabbitmq 
  namespace: rabbitmq 
---
kind: Role
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: endpoint-reader
  namespace: rabbitmq 
rules:
- apiGroups: [""]
  resources: ["endpoints"]
  verbs: ["get"]
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: endpoint-reader
  namespace: rabbitmq
subjects:
- kind: ServiceAccount
  name: rabbitmq
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: endpoint-reader
---
apiVersion: v1
kind: PersistentVolume
metadata:
    name: rabbitmq-data
    labels:
      release: rabbitmq-data
    namespace: rabbitmq
spec:
    capacity:
      storage: 10Gi
    accessModes:
      - ReadWriteMany
    persistentVolumeReclaimPolicy: Retain
    nfs:
      path: /rabbit
      server: xxxxx  # nas地址
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: rabbitmq-data-claim
  namespace: rabbitmq
spec:
  accessModes:
    - ReadWriteMany
  resources:  
    requests:
      storage: 10Gi
  selector:
    matchLabels:
      release: rabbitmq-data
---
# headless service 用于使用hostname访问pod
kind: Service
apiVersion: v1
metadata:
  name: rabbitmq-headless
  namespace: rabbitmq
spec:
  clusterIP: None
  # publishNotReadyAddresses, when set to true, indicates that DNS implementations must publish the notReadyAddresses of subsets for the Endpoints associated with the Service. The default value is false. The primary use case for setting this field is to use a StatefulSet's Headless Service to propagate SRV records for its Pods without respect to their readiness for purpose of peer discovery. This field will replace the service.alpha.kubernetes.io/tolerate-unready-endpoints when that annotation is deprecated and all clients have been converted to use this field.
  # 由于使用DNS访问Pod需Pod和Headless service启动之后才能访问，publishNotReadyAddresses设置成true，防止readinessProbe在服务没启动时找不到DNS
  publishNotReadyAddresses: true 
  ports: 
   - name: amqp
     port: 5672
   - name: http
     port: 15672
  selector:
    app: rabbitmq
---
# 用于暴露dashboard到外网
kind: Service
apiVersion: v1
metadata:
  namespace: rabbitmq
  name: rabbitmq-service
spec:
  type: NodePort
  ports:
   - name: http
     protocol: TCP
     port: 15672
     targetPort: 15672 
     nodePort: 15672   # 注意k8s默认情况下，nodeport要在30000~32767之间，可以自行修改
   - name: amqp
     protocol: TCP
     port: 5672
     targetPort: 5672  # 注意如果你想在外网下访问mq，需要增配nodeport
  selector:
    app: rabbitmq
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: rabbitmq-config
  namespace: rabbitmq
data:
  enabled_plugins: |
      [rabbitmq_management,rabbitmq_peer_discovery_k8s].
  rabbitmq.conf: |
      cluster_formation.peer_discovery_backend  = rabbit_peer_discovery_k8s
      cluster_formation.k8s.host = kubernetes.default.svc.cluster.local
      cluster_formation.k8s.address_type = hostname
      cluster_formation.node_cleanup.interval = 10
      cluster_formation.node_cleanup.only_log_warning = true
      cluster_partition_handling = autoheal
      queue_master_locator=min-masters
      loopback_users.guest = false
​
      cluster_formation.randomized_startup_delay_range.min = 0
      cluster_formation.randomized_startup_delay_range.max = 2
      # 必须设置service_name，否则Pod无法正常启动，这里设置后可以不设置statefulset下env中的K8S_SERVICE_NAME变量
      cluster_formation.k8s.service_name = rabbitmq-headless
      # 必须设置hostname_suffix，否则节点不能成为集群
      cluster_formation.k8s.hostname_suffix = .rabbitmq-headless.rabbitmq.svc.cluster.local
      # 内存上限
      vm_memory_high_watermark.absolute = 1.6GB
      # 硬盘上限
      disk_free_limit.absolute = 2GB
---
# 使用apps/v1版本代替apps/v1beta
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: rabbitmq
  namespace: rabbitmq
spec:
  serviceName: rabbitmq-headless   # 必须与headless service的name相同，用于hostname传播访问pod
  selector:
    matchLabels:
      app: rabbitmq # 在apps/v1中，需与 .spec.template.metadata.label 相同，用于hostname传播访问pod，而在apps/v1beta中无需这样做
  replicas: 3
  template:
    metadata:
      labels:
        app: rabbitmq  # 在apps/v1中，需与 .spec.selector.matchLabels 相同
      # 设置podAntiAffinity
      annotations:
        scheduler.alpha.kubernetes.io/affinity: >
            {
              "podAntiAffinity": {
                "requiredDuringSchedulingIgnoredDuringExecution": [{
                  "labelSelector": {
                    "matchExpressions": [{
                      "key": "app",
                      "operator": "In",
                      "values": ["rabbitmq"]
                    }]
                  },
                  "topologyKey": "kubernetes.io/hostname"
                }]
              }
            }
    spec:
      serviceAccountName: rabbitmq
      terminationGracePeriodSeconds: 10
      containers:        
      - name: rabbitmq
        image: registry-vpc.cn-shenzhen.aliyuncs.com/heygears/rabbitmq:3.7
        resources:
          limits:
            cpu: 0.5
            memory: 2Gi
          requests:
            cpu: 0.3
            memory: 2Gi
        volumeMounts:
          - name: config-volume
            mountPath: /etc/rabbitmq
          - name: rabbitmq-data
            mountPath: /var/lib/rabbitmq/mnesia
        ports:
          - name: http
            protocol: TCP
            containerPort: 15672
          - name: amqp
            protocol: TCP
            containerPort: 5672
        livenessProbe:
          exec:
            command: ["rabbitmqctl", "status"]
          initialDelaySeconds: 60
          periodSeconds: 60
          timeoutSeconds: 5
        readinessProbe:
          exec:
            command: ["rabbitmqctl", "status"]
          initialDelaySeconds: 20
          periodSeconds: 60
          timeoutSeconds: 5
        imagePullPolicy: Always
        env:
          - name: HOSTNAME
            valueFrom:
              fieldRef:
                fieldPath: metadata.name
          - name: RABBITMQ_USE_LONGNAME
            value: "true"
          - name: RABBITMQ_NODENAME
            value: "rabbit@$(HOSTNAME).rabbitmq-headless.rabbitmq.svc.cluster.local"
          # 若在ConfigMap中设置了service_name，则此处无需再次设置
          # - name: K8S_SERVICE_NAME
          #   value: "rabbitmq-headless"
          - name: RABBITMQ_ERLANG_COOKIE
            value: "mycookie" 
      volumes:
        - name: config-volume
          configMap:
            name: rabbitmq-config
            items:
            - key: rabbitmq.conf
              path: rabbitmq.conf
            - key: enabled_plugins
              path: enabled_plugins
        - name: rabbitmq-data
          persistentVolumeClaim:
            claimName: rabbitmq-data-claim
```

[15672]端口是管理端口

[5672]端口是使用端口

## 部署

```
kubectl apply -f RabbitMQ.yaml
```

## 查看

```
kubectl get pods -n rabbitmq
```

等待全部running后

通过ip查看管理页面

```
202.107.190.8:10273
```

账号:guest

密码:guest

## 操作

### 用户管理

```
新增 rabbitmqctl add_user admin admin
删除 rabbitmqctl delete_user admin
修改 rabbitmqctl change_password admin admin123 
```

```
用户列表 rabbitmqctl  list_users
设置角色 rabbitmqctl set_user_tags admin administrator monitoring policymaker management
```

```
设置用户权限 rabbitmqctl  set_permissions  -p  VHostPath  admin  ConfP  WriteP  ReadP
查询所有权限 rabbitmqctl  list_permissions  [-p  VHostPath]
指定用户权限 rabbitmqctl  list_user_permissions  admin
清除用户权限 rabbitmqctl  clear_permissions  [-p VHostPath]  admin
```

### 查看集群

```
rabbitmqctl cluster_status
```

### 清空queue

```
清空指定queue队列的数据
rabbitmqctl purge_queue queue_name
```

