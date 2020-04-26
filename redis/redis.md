# kubernetes-redis集群

## 1.创建配置文件redis.conf

```
appendonly yes
cluster-enabled yes
cluster-config-file /var/lib/redis/nodes.conf
cluster-node-timeout 5000
dir /var/lib/redis
port 6379
```

```
kubectl create configmap redis-conf --from-file=redis.conf
```

## 2.创建pv和pvc

### redis-pv.yml

```
apiVersion: v1
kind: PersistentVolume
metadata:
  name: redis-pv1
spec:
  capacity:
    storage: 1Gi
  volumeMode: redisFile
  accessModes:
    - ReadWriteMany
  storageClassName: redis
  cephfs:
    monitors:
      - 192.168.1.103:6789
    path: "/redis/pv1"
    user: admin
    secretRef:
      name: ceph-secret
    readOnly: false
  persistentVolumeReclaimPolicy: Recycle
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: redis-pv2
spec:
  capacity:
    storage: 1Gi
  volumeMode: redisFile
  accessModes:
    - ReadWriteMany
  storageClassName: redis
  cephfs:
    monitors:
      - 192.168.1.103:6789
    path: "/redis/pv2"
    user: admin
    secretRef:
      name: ceph-secret
    readOnly: false
  persistentVolumeReclaimPolicy: Recycle
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: redis-pv3
spec:
  capacity:
    storage: 1Gi
  volumeMode: redisFile
  accessModes:
    - ReadWriteMany
  storageClassName: redis
  cephfs:
    monitors:
      - 192.168.1.103:6789
    path: "/redis/pv3"
    user: admin
    secretRef:
      name: ceph-secret
    readOnly: false
  persistentVolumeReclaimPolicy: Recycle
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: redis-pv4
spec:
  capacity:
    storage: 1Gi
  volumeMode: redisFile
  accessModes:
    - ReadWriteMany
  storageClassName: redis
  cephfs:
    monitors:
      - 192.168.1.103:6789
    path: "/redis/pv4"
    user: admin
    secretRef:
      name: ceph-secret
    readOnly: false
  persistentVolumeReclaimPolicy: Recycle
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: redis-pv5
spec:
  capacity:
    storage: 1Gi
  volumeMode: redisFile
  accessModes:
    - ReadWriteMany
  storageClassName: redis
  cephfs:
    monitors:
      - 192.168.1.103:6789
    path: "/redis/pv5"
    user: admin
    secretRef:
      name: ceph-secret
    readOnly: false
  persistentVolumeReclaimPolicy: Recycle
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: redis-pv6
spec:
  capacity:
    storage: 1Gi
  volumeMode: redisFile
  accessModes:
    - ReadWriteMany
  storageClassName: redis
  cephfs:
    monitors:
      - 192.168.1.103:6789
    path: "/redis/pv6"
    user: admin
    secretRef:
      name: ceph-secret
    readOnly: false
  persistentVolumeReclaimPolicy: Recycle
```

```
kubectl apply -f redis-cluster-pv.yml
```

### redis-pvc.yml

```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: redis-pvc1
spec:
  accessModes:
    - ReadWriteMany
  volumeName: redis-pv1
  storageClassName: redis
  resources:
    requests:
      storage: 1Gi
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: redis-pvc2
spec:
  accessModes:
    - ReadWriteMany
  volumeName: redis-pv2
  storageClassName: redis
  resources:
    requests:
      storage: 1Gi
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: redis-pvc3
spec:
  accessModes:
    - ReadWriteMany
  volumeName: redis-pv3
  storageClassName: redis
  resources:
    requests:
      storage: 1Gi
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: redis-pvc4
spec:
  accessModes:
    - ReadWriteMany
  volumeName: redis-pv4
  storageClassName: redis
  resources:
    requests:
      storage: 1Gi
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: redis-pvc5
spec:
  accessModes:
    - ReadWriteMany
  volumeName: redis-pv5
  storageClassName: redis
  resources:
    requests:
      storage: 1Gi
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: redis-pvc6
spec:
  accessModes:
    - ReadWriteMany
  volumeName: redis-pv6
  storageClassName: redis
  resources:
    requests:
      storage: 1Gi
```

```
kubectl apply -f redis-cluster-pvc.yml
```

## 3.部署redis

### redis.yml

```
apiVersion: apps/v1beta1
kind: Deployment
metadata:
  name: redis-01
spec:
  replicas: 1
  template:
    metadata:
      labels:
        run: redis-01
    spec:
      containers:
      - name: redis-01
        image: registry.cn-qingdao.aliyuncs.com/caonima/redis:cnm
        command:
          - "redis-server"
        args:
          - "/etc/redis/redis.conf"
          - "--protected-mode"
          - "no"
        resources:
          requests:
            cpu: "100m"
            memory: "100Mi"
        ports:
            - name: redis
              containerPort: 6379
              protocol: "TCP"
            - name: cluster
              containerPort: 16379
              protocol: "TCP"
        volumeMounts:
          - name: "redis-conf"
            mountPath: "/etc/redis"
          - name: "redis-data"
            mountPath: "/var/lib/redis"
      volumes:
      - name: "redis-conf"
        configMap:
          name: "redis-conf"
          items:
            - key: "redis.conf"
              path: "redis.conf"
      - name: "redis-data"
        persistentVolumeClaim:
          claimName: redis-pvc1

---
apiVersion: apps/v1beta1
kind: Deployment
metadata:
  name: redis-02
spec:
  replicas: 1
  template:
    metadata:
      labels:
        run: redis-02
    spec:
      containers:
      - name: redis-02
        image: registry.cn-qingdao.aliyuncs.com/caonima/redis:cnm
        command:
          - "redis-server"
        args:
          - "/etc/redis/redis.conf"
          - "--protected-mode"
          - "no"
        resources:
          requests:
            cpu: "100m"
            memory: "100Mi"
        ports:
            - name: redis
              containerPort: 6379
              protocol: "TCP"
            - name: cluster
              containerPort: 16379
              protocol: "TCP"
        volumeMounts:
          - name: "redis-conf"
            mountPath: "/etc/redis"
          - name: "redis-data"
            mountPath: "/var/lib/redis"
      volumes:
      - name: "redis-conf"
        configMap:
          name: "redis-conf"
          items:
            - key: "redis.conf"
              path: "redis.conf"
      - name: "redis-data"
        persistentVolumeClaim:
          claimName: redis-pvc2

---
apiVersion: apps/v1beta1
kind: Deployment
metadata:
  name: redis-03
spec:
  replicas: 1
  template:
    metadata:
      labels:
        run: redis-03
    spec:
      containers:
      - name: redis-03
        image: registry.cn-qingdao.aliyuncs.com/caonima/redis:cnm
        command:
          - "redis-server"
        args:
          - "/etc/redis/redis.conf"
          - "--protected-mode"
          - "no"
        resources:
          requests:
            cpu: "100m"
            memory: "100Mi"
        ports:
            - name: redis
              containerPort: 6379
              protocol: "TCP"
            - name: cluster
              containerPort: 16379
              protocol: "TCP"
        volumeMounts:
          - name: "redis-conf"
            mountPath: "/etc/redis"
          - name: "redis-data"
            mountPath: "/var/lib/redis"
      volumes:
      - name: "redis-conf"
        configMap:
          name: "redis-conf"
          items:
            - key: "redis.conf"
              path: "redis.conf"
      - name: "redis-data"
        persistentVolumeClaim:
          claimName: redis-pvc3

---
apiVersion: apps/v1beta1
kind: Deployment
metadata:
  name: redis-04
spec:
  replicas: 1
  template:
    metadata:
      labels:
        run: redis-04
    spec:
      containers:
      - name: redis-04
        image: registry.cn-qingdao.aliyuncs.com/caonima/redis:cnm
        command:
          - "redis-server"
        args:
          - "/etc/redis/redis.conf"
          - "--protected-mode"
          - "no"
        resources:
          requests:
            cpu: "100m"
            memory: "100Mi"
        ports:
            - name: redis
              containerPort: 6379
              protocol: "TCP"
            - name: cluster
              containerPort: 16379
              protocol: "TCP"
        volumeMounts:
          - name: "redis-conf"
            mountPath: "/etc/redis"
          - name: "redis-data"
            mountPath: "/var/lib/redis"
      volumes:
      - name: "redis-conf"
        configMap:
          name: "redis-conf"
          items:
            - key: "redis.conf"
              path: "redis.conf"
      - name: "redis-data"
        persistentVolumeClaim:
          claimName: redis-pvc4

---
apiVersion: apps/v1beta1
kind: Deployment
metadata:
  name: redis-05
spec:
  replicas: 1
  template:
    metadata:
      labels:
        run: redis-05
    spec:
      containers:
      - name: redis-05
        image: registry.cn-qingdao.aliyuncs.com/caonima/redis:cnm
        command:
          - "redis-server"
        args:
          - "/etc/redis/redis.conf"
          - "--protected-mode"
          - "no"
        resources:
          requests:
            cpu: "100m"
            memory: "100Mi"
        ports:
            - name: redis
              containerPort: 6379
              protocol: "TCP"
            - name: cluster
              containerPort: 16379
              protocol: "TCP"
        volumeMounts:
          - name: "redis-conf"
            mountPath: "/etc/redis"
          - name: "redis-data"
            mountPath: "/var/lib/redis"
      volumes:
      - name: "redis-conf"
        configMap:
          name: "redis-conf"
          items:
            - key: "redis.conf"
              path: "redis.conf"
      - name: "redis-data"
        persistentVolumeClaim:
          claimName: redis-pvc5

---
apiVersion: apps/v1beta1
kind: Deployment
metadata:
  name: redis-06
spec:
  replicas: 1
  template:
    metadata:
      labels:
        run: redis-06
    spec:
      containers:
      - name: redis-06
        image: registry.cn-qingdao.aliyuncs.com/caonima/redis:cnm
        command:
          - "redis-server"
        args:
          - "/etc/redis/redis.conf"
          - "--protected-mode"
          - "no"
        resources:
          requests:
            cpu: "100m"
            memory: "100Mi"
        ports:
            - name: redis
              containerPort: 6379
              protocol: "TCP"
            - name: cluster
              containerPort: 16379
              protocol: "TCP"
        volumeMounts:
          - name: "redis-conf"
            mountPath: "/etc/redis"
          - name: "redis-data"
            mountPath: "/var/lib/redis"
      volumes:
      - name: "redis-conf"
        configMap:
          name: "redis-conf"
          items:
            - key: "redis.conf"
              path: "redis.conf"
      - name: "redis-data"
        persistentVolumeClaim:
          claimName: redis-pvc6

---
apiVersion: v1
kind: Service
metadata:
  name: redis-01
spec:
  selector:
    run: redis-01
  type: NodePort
  ports:
  - name: port
    nodePort: 32379
    port: 6379
    targetPort: 6379

---
apiVersion: v1
kind: Service
metadata:
  name: redis-02
spec:
  selector:
    run: redis-02
  type: NodePort
  ports:
  - name: port
    nodePort: 32380
    port: 6379
    targetPort: 6379

---
apiVersion: v1
kind: Service
metadata:
  name: redis-03
spec:
  selector:
    run: redis-03
  type: NodePort
  ports:
  - name: port
    nodePort: 32381
    port: 6379
    targetPort: 6379

---
apiVersion: v1
kind: Service
metadata:
  name: redis-04
spec:
  selector:
    run: redis-04
  type: NodePort
  ports:
  - name: port
    nodePort: 32382
    port: 6379
    targetPort: 6379

---
apiVersion: v1
kind: Service
metadata:
  name: redis-05
spec:
  selector:
    run: redis-05
  type: NodePort
  ports:
  - name: port
    nodePort: 32383
    port: 6379
    targetPort: 6379

---
apiVersion: v1
kind: Service
metadata:
  name: redis-06
spec:
  selector:
    run: redis-06
  type: NodePort
  ports:
  - name: port
    nodePort: 32384
    port: 6379
    targetPort: 6379
```

### redis-cluster-service.yml

```
apiVersion: v1
kind: Service
metadata:
  name: redis-01-cluster
spec:
  selector:
    run: redis-01
  ports:
  - name: cluster
    port: 16379
    targetPort: 16379
  - name: port
    port: 6379
    targetPort: 6379
---
apiVersion: v1
kind: Service
metadata:
  name: redis-02-cluster
spec:
  selector:
    run: redis-02
  ports:
  - name: cluster
    port: 16379
    targetPort: 16379
  - name: port
    port: 6379
    targetPort: 6379
---
apiVersion: v1
kind: Service
metadata:
  name: redis-03-cluster
spec:
  selector:
    run: redis-03
  ports:
  - name: cluster
    port: 16379
    targetPort: 16379
  - name: port
    port: 6379
    targetPort: 6379
---
apiVersion: v1
kind: Service
metadata:
  name: redis-04-cluster
spec:
  selector:
    run: redis-04
  ports:
  - name: cluster
    port: 16379
    targetPort: 16379
  - name: port
    port: 6379
    targetPort: 6379
---
apiVersion: v1
kind: Service
metadata:
  name: redis-05-cluster
spec:
  selector:
    run: redis-05
  ports:
  - name: cluster
    port: 16379
    targetPort: 16379
  - name: port
    port: 6379
    targetPort: 6379
---
apiVersion: v1
kind: Service
metadata:
  name: redis-06-cluster
spec:
  selector:
    run: redis-06
  ports:
  - name: cluster
    port: 16379
    targetPort: 16379
  - name: port
    port: 6379
    targetPort: 6379
```











## 4.创建集群

### 创建pod-centos

```
apiVersion: apps/v1beta1
kind: Deployment
metadata:
  name: centos
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: centos
    spec:
      containers:
      - name: centos
        image: centos
        command: [ "/bin/bash", "-c", "--" ]
        args: [ "while true; do sleep 30; done;" ]
```

```
之后进入centos容器
```

### 安装ruby

```
yum install ruby -y
```

```
yum install rubygems -y #如果是新版本ruby会在ruby安装时自动安装
```

```
yum install wget -y
```

### 安装RVM

#### 准备

```
yum install curl -y
```

```
yum install which -y
```

```
curl -sSL https://rvm.io/mpapis.asc | gpg2 --import -  
or
gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
```

```
curl -L get.rvm.io | bash -s stable  
```

```
find / -name rvm.sh  
```

```
source /etc/profile.d/rvm.sh  
```

```
rvm requirements 
```

```
find / -name rvm -print
```

↑出现很多打印列表 说明已经成功

```
source /usr/local/rvm/scripts/rvm #使rvm生效
```

#### 查看rvm库中ruby版本

```
rvm list known
```

#### 安装一个ruby版本

```
rvm install 2.4.1
```

#### 使用安装的版本

```
rvm use 2.4.1
```

#### 设为默认版本

```
rvm use 2.4.1 --default
```

#### 安装redis客户端

```
wget http://download.redis.io/releases/redis-4.0.11.tar.gz
```

```
tar -zxvf redis-4.0.11.tar.gz
```

```
cd redis-4.0.11
```

```
make
```

```
make install
```

```
cp src/redis-trib.rb /
```

```
gem install redis
```



### 创建redis集群

```
/redis-trib.rb create --replicas 1 10.105.3.17:6379 10.103.54.30:6379 10.109.184.103:6379 10.107.245.201:6379 10.110.196.108:6379 10.100.120.73:6379
```

打印出

```
>>> Creating cluster
>>> Performing hash slots allocation on 6 nodes...
Using 3 masters:
10.105.3.17:6379
10.103.54.30:6379
10.109.184.103:6379
Adding replica 10.110.196.108:6379 to 10.105.3.17:6379
Adding replica 10.100.120.73:6379 to 10.103.54.30:6379
Adding replica 10.107.245.201:6379 to 10.109.184.103:6379
M: 8fe956747f5c0e246b4a5a368cde9f251ccb3e3d 10.105.3.17:6379
   slots:0-5460 (5461 slots) master
M: 52a3da636d1162d7ff97f5f7e22935947c87f470 10.103.54.30:6379
   slots:5461-10922 (5462 slots) master
M: c8fb38ff9a8cb8d7e2c0f474dac96c8503d7f416 10.109.184.103:6379
   slots:10923-16383 (5461 slots) master
S: 42f286c80a8a7d48fe7897e0f75ae2201f241411 10.107.245.201:6379
   replicates c8fb38ff9a8cb8d7e2c0f474dac96c8503d7f416
S: 150d90263d006189e92e2fcff7be47158d471fc0 10.110.196.108:6379
   replicates 8fe956747f5c0e246b4a5a368cde9f251ccb3e3d
S: c9093c0abc9f40ef2a8014f9e270bc8db3e7458f 10.100.120.73:6379
   replicates 52a3da636d1162d7ff97f5f7e22935947c87f470
Can I set the above configuration? (type 'yes' to accept): yes
>>> Nodes configuration updated
>>> Assign a different config epoch to each node
>>> Sending CLUSTER MEET messages to join the cluster
Waiting for the cluster to join...
>>> Performing Cluster Check (using node 10.105.3.17:6379)
M: 8fe956747f5c0e246b4a5a368cde9f251ccb3e3d 10.105.3.17:6379
   slots:0-5460 (5461 slots) master
   1 additional replica(s)
M: 52a3da636d1162d7ff97f5f7e22935947c87f470 10.244.0.150:6379
   slots:5461-10922 (5462 slots) master
   1 additional replica(s)
M: c8fb38ff9a8cb8d7e2c0f474dac96c8503d7f416 10.244.0.151:6379
   slots:10923-16383 (5461 slots) master
   1 additional replica(s)
S: 150d90263d006189e92e2fcff7be47158d471fc0 10.244.0.153:6379
   slots: (0 slots) slave
   replicates 8fe956747f5c0e246b4a5a368cde9f251ccb3e3d
S: 42f286c80a8a7d48fe7897e0f75ae2201f241411 10.244.0.149:6379
   slots: (0 slots) slave
   replicates c8fb38ff9a8cb8d7e2c0f474dac96c8503d7f416
S: c9093c0abc9f40ef2a8014f9e270bc8db3e7458f 10.244.0.154:6379
   slots: (0 slots) slave
   replicates 52a3da636d1162d7ff97f5f7e22935947c87f470
[OK] All nodes agree about slots configuration.
>>> Check for open slots...
>>> Check slots coverage...
[OK] All 16384 slots covered.
```

注: IP地址为redis-cluster-service中生成的IP





# docker-redis哨兵(单一节点)

## 1.创建redis

## 2.下载sentinel配置文件

```
wget http://download.redis.io/redis-stable/sentinel.conf
```

## 3.找到并修改如下配置:

mymaster:自定义集群名，如果需要监控多个redis集群，只需要配置多次并定义不同的<master-name> <master-redis-ip>:主库ip <master-redis-port>:主库port <quorum>:最小投票数，由于有三台redis-sentinel实例，所以可以设置成2

```
sentinel monitor mymaster <master-redis-ip> <master-redis-port> <quorum>
sentinel monitor in <192.168.240.61> <6379> <1>
```

添加后台运行

```
daemonize yes
```

## 4.运行

```
docker run -dt --name redis-sentinel-1 -p 26379:26379 -v /root/redis/sentinel-1.conf:/usr/local/etc/redis/sentinel.conf --restart=always redis 
```

```
docker run -dt --name redis-sentinel-2 -p 26380:26379 -v /root/redis/sentinel-2.conf:/usr/local/etc/redis/sentinel.conf --restart=always redis 
```

## 5.开启sentinel

### 进入容器

```
docker exec -it redis-sentinel-1 /bin/bash
```

```
redis-sentinel /usr/local/etc/redis/sentinel.conf
```

### 连接并使用redis-sentinel API查看监控状况 

```
redis-cli -p 26379
```

```
sentinel master in
```



##### sentinel参考

```
https://blog.csdn.net/qq_28804275/article/details/80938659
```



# docker-redis集群

## 所在机器及端口

```
192.168.240.60:6379
192.168.240.62:6379
192.168.240.63:6379
192.168.240.64:6379
192.168.240.65:6379
192.168.240.66:6379
```

## 配置文件(最简配置)

```
appendonly yes
cluster-enabled yes
cluster-config-file /etc/redis/nodes.conf
cluster-node-timeout 5000
dir /data
port 6379
bind 59.212.147.44
maxclients 20000
masterauth 123123 
requirepass 123123
```

## 运行

### 非hosts模式

```
docker run -dt -p 6379:6379 -p 16379:16379 --name redis-01 --restart unless-stopped --net redis-network --ip 172.23.0.2 -v /home/data/redis/redis.conf:/etc/redis/redis.conf -v /home/data/redis/data:/data 59.212.147.64:5000/redis:6.0 redis-server /etc/redis/redis.conf --appendonly yes
```

```
docker run -dt -p 6379:6379 -p 16379:16379 --name redis-02 --restart unless-stopped --net redis-network --ip 172.23.0.3 -v /home/data/redis/redis.conf:/etc/redis/redis.conf -v /home/data/redis/data:/data 59.212.147.64:5000/redis:6.0 redis-server /etc/redis/redis.conf --appendonly yes
```

```
docker run -dt -p 6379:6379 -p 16379:16379 --name redis-03 --restart unless-stopped --net redis-network --ip 172.23.0.4 -v /home/data/redis/redis.conf:/etc/redis/redis.conf -v /home/data/redis/data:/data 59.212.147.64:5000/redis:6.0 redis-server /etc/redis/redis.conf --appendonly yes
```

```
docker run -dt -p 6379:6379 -p 16379:16379 --name redis-04 --restart unless-stopped --net redis-network --ip 172.23.0.5 -v /home/data/redis/redis.conf:/etc/redis/redis.conf -v /home/data/redis/data:/data 59.212.147.64:5000/redis:6.0 redis-server /etc/redis/redis.conf --appendonly yes
```

```
docker run -dt -p 6379:6379 -p 16379:16379 --name redis-05 --restart unless-stopped --net redis-network --ip 172.23.0.6 -v /home/data/redis/redis.conf:/etc/redis/redis.conf -v /home/data/redis/data:/data 59.212.147.64:5000/redis:6.0 redis-server /etc/redis/redis.conf --appendonly yes
```

```
docker run -dt -p 6379:6379 -p 16379:16379 --name redis-06 --restart unless-stopped --net redis-network --ip 172.23.0.7 -v /home/data/redis/redis.conf:/etc/redis/redis.conf -v /home/data/redis/data:/data 59.212.147.64:5000/redis:6.0 redis-server /etc/redis/redis.conf --appendonly yes
```

### host模式

```
docker run -dt --name redis-01 --restart unless-stopped --net host -v /root/redis/redis.conf:/etc/redis/redis.conf -v /root/redis/data:/data 192.168.240.73/fuck/redis redis-server /etc/redis/redis.conf --appendonly yes
```

```
docker run -dt --name redis-02 --restart unless-stopped --net host -v /root/redis/redis.conf:/etc/redis/redis.conf -v /root/redis/data:/data 192.168.240.73/fuck/redis redis-server /etc/redis/redis.conf --appendonly yes
```

```
docker run -dt --name redis-03 --restart unless-stopped --net host -v /root/redis/redis.conf:/etc/redis/redis.conf -v /root/redis/data:/data 192.168.240.73/fuck/redis redis-server /etc/redis/redis.conf --appendonly yes
```

```
docker run -dt --name redis-04 --restart unless-stopped --net host -v /root/redis/redis.conf:/etc/redis/redis.conf -v /root/redis/data:/data 192.168.240.73/fuck/redis redis-server /etc/redis/redis.conf --appendonly yes
```

```
docker run -dt --name redis-05 --restart unless-stopped --net host -v /root/redis/redis.conf:/etc/redis/redis.conf -v /root/redis/data:/data 192.168.240.73/fuck/redis redis-server /etc/redis/redis.conf --appendonly yes
```

```
docker run -dt --name redis-06 --restart unless-stopped --net host -v /root/redis/redis.conf:/etc/redis/redis.conf -v /root/redis/data:/data 192.168.240.73/fuck/redis redis-server /etc/redis/redis.conf --appendonly yes
```

## 集群设置

```
docker run -dt --name RedisCentos centos:redis
```

```
docker exec -it RedisCentos /bin/bash
```

### 编辑集群创建脚本

```
vi /usr/local/rvm/gems/ruby-2.4.1/gems/redis-4.1.0/lib/redis/client.rb 
```

```
/redis-trib.rb create --replicas 1 192.168.240.60:6379 192.168.240.62:6379 192.168.240.63:6379 192.168.240.64:6379 192.168.240.65:6379 192.168.240.66:6379
```

打印

```
>>> Creating cluster
>>> Performing hash slots allocation on 6 nodes...
Using 3 masters:
192.168.240.60:6379
192.168.240.62:6379
192.168.240.63:6379
Adding replica 192.168.240.65:6379 to 192.168.240.60:6379
Adding replica 192.168.240.66:6379 to 192.168.240.62:6379
Adding replica 192.168.240.64:6379 to 192.168.240.63:6379
M: 587b3887a310f0bfa21e3514c775aaa6f10c78d6 192.168.240.60:6379
   slots:0-5460 (5461 slots) master
M: f3fe2725a841d0599c5b0fad0727f62985a8ec67 192.168.240.62:6379
   slots:5461-10922 (5462 slots) master
M: 0c3ae975b41a8483782b097f35bb682c19173b96 192.168.240.63:6379
   slots:10923-16383 (5461 slots) master
S: c4d988cfad3239d12354506c420d878be8e461b3 192.168.240.64:6379
   replicates 0c3ae975b41a8483782b097f35bb682c19173b96
S: dfc691ba88759b5b10d250d613dbe7fce91894e5 192.168.240.65:6379
   replicates 587b3887a310f0bfa21e3514c775aaa6f10c78d6
S: d9123a13863f626e8158acc98a4e358e92b226cc 192.168.240.66:6379
   replicates f3fe2725a841d0599c5b0fad0727f62985a8ec67
Can I set the above configuration? (type 'yes' to accept): yes
>>> Nodes configuration updated
>>> Assign a different config epoch to each node
>>> Sending CLUSTER MEET messages to join the cluster
Waiting for the cluster to join.....
>>> Performing Cluster Check (using node 192.168.240.60:6379)
M: 587b3887a310f0bfa21e3514c775aaa6f10c78d6 192.168.240.60:6379
   slots:0-5460 (5461 slots) master
   1 additional replica(s)
S: dfc691ba88759b5b10d250d613dbe7fce91894e5 192.168.240.65:6379
   slots: (0 slots) slave
   replicates 587b3887a310f0bfa21e3514c775aaa6f10c78d6
M: 0c3ae975b41a8483782b097f35bb682c19173b96 192.168.240.63:6379
   slots:10923-16383 (5461 slots) master
   1 additional replica(s)
S: d9123a13863f626e8158acc98a4e358e92b226cc 192.168.240.66:6379
   slots: (0 slots) slave
   replicates f3fe2725a841d0599c5b0fad0727f62985a8ec67
S: c4d988cfad3239d12354506c420d878be8e461b3 192.168.240.64:6379
   slots: (0 slots) slave
   replicates 0c3ae975b41a8483782b097f35bb682c19173b96
M: f3fe2725a841d0599c5b0fad0727f62985a8ec67 192.168.240.62:6379
   slots:5461-10922 (5462 slots) master
   1 additional replica(s)
[OK] All nodes agree about slots configuration.
>>> Check for open slots...
>>> Check slots coverage...
[OK] All 16384 slots covered.
```



## 测试

```
/usr/local/bin/redis-cli -c -h 59.212.147.64 -p 6379 -a 123123
```

### 输入测试数据

```
set name test
```

```
get name
```

### 查看所有数据

```
keys *
```

### 清空测试数据

```
flushall
```



# 巴州版本

## Redis

### 所在机器及端口

```
192.168.100.7:6377
192.168.100.7:6378
192.168.100.7:6379
192.168.100.8:6377
192.168.100.8:6378
192.168.100.8:6379
```

### 配置文件(最简配置)

```
appendonly yes
daemonize no
cluster-enabled yes
cluster-config-file nodes-6379.conf
cluster-node-timeout 5000
dir /data
port 6377
bind 0.0.0.0
maxclients 20000
masterauth 123456
requirepass 123456
```

### 创建

```
sh /root/deploy/redis/start.sh
```

### 查看

```
docker ps
```

### 集群设置

```
docker run -dt --name RedisCentos redis:cluterinit
```

```
docker exec -it RedisCentos /bin/bash
```

#### 编辑集群创建脚本

```
vi /usr/local/rvm/gems/ruby-2.4.1/gems/redis-4.1.0/lib/redis/client.rb 
```

修改密码

```
    DEFAULTS = {
      :url => lambda { ENV["REDIS_URL"] },
      :scheme => "redis",
      :host => "127.0.0.1",
      :port => 6379,
      :path => nil,
      :timeout => 5.0,
      :password => 123456,
      :db => 0,
      :driver => nil,
      :id => nil,
      :tcp_keepalive => 0,
      :reconnect_attempts => 1,
      :reconnect_delay => 0,
      :reconnect_delay_max => 0.5,
      :inherit_socket => false
    }

```

创建

```
/redis-trib.rb create --replicas 1 192.168.100.7:6377 192.168.100.7:6378 192.168.100.7:6379 192.168.100.8:6377 192.168.100.8:6378 192.168.100.8:6379
```

打印

```
>>> Creating cluster
>>> Performing hash slots allocation on 6 nodes...
Using 3 masters:
192.168.100.7:6377
192.168.100.8:6377
192.168.100.7:6378
Adding replica 192.168.100.8:6379 to 192.168.100.7:6377
Adding replica 192.168.100.7:6378 to 192.168.100.8:6377
Adding replica 192.168.100.8:6378 to 192.168.100.7:6378
M: 909c295659a749b8d98cc52863e2f655ffdfa33a 192.168.100.7:6377
   slots:0-5460 (5461 slots) master
M: 734d2ae5db972cce3fe586d034ae83850e730609 192.168.100.7:6378
   slots:10923-16383 (5461 slots) master
S: 734d2ae5db972cce3fe586d034ae83850e730609 192.168.100.7:6378
   replicates f2275dcaa08bde5e5622d1c76fecf46204c3a330
M: f2275dcaa08bde5e5622d1c76fecf46204c3a330 192.168.100.8:6377
   slots:5461-10922 (5462 slots) master
S: 8213f9aa19a4bb79659667734679490bde217c1f 192.168.100.8:6378
   replicates 734d2ae5db972cce3fe586d034ae83850e730609
S: 1bc41b969eb76401234f36e3fcbe54ba0abbbec6 192.168.100.8:6379
   replicates 909c295659a749b8d98cc52863e2f655ffdfa33a
Can I set the above configuration? (type 'yes' to accept): yes
>>> Nodes configuration updated
>>> Assign a different config epoch to each node
>>> Sending CLUSTER MEET messages to join the cluster
Waiting for the cluster to join....
>>> Performing Cluster Check (using node 192.168.100.7:6377)
M: 909c295659a749b8d98cc52863e2f655ffdfa33a 192.168.100.7:6377
   slots:0-5460 (5461 slots) master
   1 additional replica(s)
M: f2275dcaa08bde5e5622d1c76fecf46204c3a330 192.168.100.8:6377
   slots:5461-10922 (5462 slots) master
   0 additional replica(s)
S: 1bc41b969eb76401234f36e3fcbe54ba0abbbec6 192.168.100.8:6379
   slots: (0 slots) slave
   replicates 909c295659a749b8d98cc52863e2f655ffdfa33a
M: 734d2ae5db972cce3fe586d034ae83850e730609 192.168.100.7:6378
   slots:10923-16383 (5461 slots) master
   1 additional replica(s)
S: 8213f9aa19a4bb79659667734679490bde217c1f 192.168.100.8:6378
   slots: (0 slots) slave
   replicates 734d2ae5db972cce3fe586d034ae83850e730609
[OK] All nodes agree about slots configuration.
>>> Check for open slots...
>>> Check slots coverage...
[OK] All 16384 slots covered.
```

### 测试

```
redis-cli -c -h 192.168.100.8 -p 6378 -a 123456
```

#### 输入测试数据

```
set name test
```

```
get name
```

#### 查看所有数据

```
keys *
```

#### 清空测试数据

```
flushall
```

#### 查看集群状态

```
cluster info
```

#### 查看集群信息

```
cluster nodes
```



## docker单机版

```
appendonly yes
#dir /var/lib/redis
port 6379
requirepass 123456
maxclients 99999
bind 0.0.0.0
daemonize no
protected-mode no
```

```
docker run -dt -p 30002:6379 --name redis --restart unless-stopped -v /home/redis/redis.conf:/etc/redis/redis.conf redis redis-server /etc/redis/redis.conf --appendonly yes
```









































```
/redis-trib.rb create --replicas 1 59.212.147.44:6379 59.212.147.45:6379 59.212.147.46:6379 59.212.147.62:6379 59.212.147.63:6379 59.212.147.64:6379
```



```
>>> Nodes configuration updated
>>> Assign a different config epoch to each node
>>> Sending CLUSTER MEET messages to join the cluster
Waiting for the cluster to join.
```



