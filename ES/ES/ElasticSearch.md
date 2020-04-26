# ElasticSearch

## k8s

### 制作镜像

#### Dockerfile

```
FROM docker.elastic.co/elasticsearch/elasticsearch:6.6.2

COPY run.sh /

COPY ik /usr/share/elasticsearch/plugins/ik

RUN chmod 775 /run.sh

CMD ["/run.sh"]
```

#### run.sh

```
ulimit -l unlimited

exec su elasticsearch /usr/local/bin/docker-entrypoint.sh
```

###### 注:插件解压出到当前目录在dockerfile中copy

#### build镜像

### 创建namespace

```
apiVersion: v1
kind: Namespace
metadata:
  name: ns-elasticsearch
  labels:
    name: ns-elasticsearch
```

### 创建pv

```
apiVersion: v1
kind: PersistentVolume
metadata:
  name: es-pv-1
  namespace: ns-elasticsearch
spec:
  capacity:
    storage: 900G
  accessModes:
    - ReadWriteMany
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

### 创建pvc

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

### 部署

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

### 查看

```
通过elasticsearch-head查看
```



```
https://blog.csdn.net/chenleiking/article/details/79453460
```

## 设置最大链接超1w

### 进入容器

```
kubectl -n ns-elasticsearch exec -it elasticsearch-data-1-75fbfbd645-kgnl2 /bin/bash
```

### 设置

```
curl -H "Content-Type: application/json" -XPUT 'http://218.84.186.2:30006/_all/_settings?preserve_existing=true' -d '{
  "index.max_result_window" : "100000000"
}'
```





## docker-compose

### 编辑/etc/sysctl.conf 

```
vi /etc/sysctl.conf
```

加入

```
vm.max_map_count = 262144
```

实时设置

```
sysctl -w vm.max_map_count=262144
```



### 编辑docker-compose.yaml

```
version: '2.2'
services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:6.6.2
    container_name: elasticsearch
    environment:
      - cluster.name=docker-cluster
      - bootstrap.memory_lock=true
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    ulimits:
      memlock:
        soft: -1
        hard: -1
    volumes:
      - esdata1:/usr/share/elasticsearch/data
    ports:
      - 9200:9200
    networks:
      - esnet
  elasticsearch2:
    image: docker.elastic.co/elasticsearch/elasticsearch:6.6.2
    container_name: elasticsearch2
    environment:
      - cluster.name=docker-cluster
      - bootstrap.memory_lock=true
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
      - "discovery.zen.ping.unicast.hosts=elasticsearch"
    ulimits:
      memlock:
        soft: -1
        hard: -1
    volumes:
      - esdata2:/usr/share/elasticsearch/data
    networks:
      - esnet

volumes:
  esdata1:
    driver: local
  esdata2:
    driver: local

networks:
  esnet:
```

#### 启动

```
docker-compose up
```

#### 停止

```
docker-compose down
```

#### 删除数据+停止

```
docker-compose down -v
```

#### 检查集群的状态

```
curl http://127.0.0.1:9200/_cat/health
```

或者用logs

#### 安装插件

##### 进入容器

```
docker exec -it elasticsearch /bin/bash
```

##### 安装插件

```
./bin/elasticsearch-plugin install https://github.com/medcl/elasticsearch-analysis-ik/releases/download/v6.6.2/elasticsearch-analysis-ik-6.6.2.zip
```

##### 重启

```
docker-compose restart
```



## docker

```
docker run -d \
--name es \
--restart always \
-p 9200:9200 -p 9300:9300 \
-e "discovery.type=single-node" -e ES_JAVA_OPTS="-Xms4096m -Xmx4096m" \
-v /esbak:/esbak \
elasticsearch:6.6.2
```

若是docker或者实体服务器安装的es,在需要做snapshot的时候先修改配置文件

```
vim /usr/local/suninfo/siem/elasticsearch/config/elasticsearch.yml
加上这个配置：
path.repo: ["/usr/local/suninfo/siem/backup"] 
```



## 备份[snapshot]

### 设置共享目录进行挂载

```
mount -t nfs 192.168.100.7:/esbak /data/esbak
```

### 添加pv内容

```
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: es-pv-bak
  namespace: ns-elasticsearch
spec:
  capacity:
    storage: 1024G
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Recycle
  nfs:
    server: 192.168.100.7
    path: /data/esbak
```

### 添加pvc内容

```
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: es-pvc-bak
  namespace: ns-elasticsearch
spec:
  accessModes:
    - ReadWriteMany
  volumeName: es-pv-bak
  resources:
    requests:
      storage: 1024G
```

### 添加es-deployment内容

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
          image: 192.168.100.7/bzyq/elasticsearch:k8s
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
            - name: esbak
              mountPath: /esbak
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
              value: "-Xms5120m -Xmx5120m"
            - name: "path.repo"
              value: "/esbak"
          securityContext:
            privileged: true
      serviceAccountName: elasticsearch-admin
      tolerations:
        - key: node-role.kubernetes.io/master
          effect: NoSchedule
      volumes:
        - name: esbak
          persistentVolumeClaim:
            claimName: es-pvc-bak

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
          image: 192.168.100.7/bzyq/elasticsearch:k8s
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
            - name: esbak
              mountPath: /esbak
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
              value: "-Xms20480m -Xmx20480m"
            - name: "path.repo"
              value: "/esbak"
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
      - name: esbak
        persistentVolumeClaim:
          claimName: es-pvc-bak

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
      nodePort: 30006
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
          image: 192.168.100.7/bzyq/elasticsearch:k8s
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
            - name: esbak
              mountPath: /esbak
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
              value: "-Xms20480m -Xmx20480m"
            - name: "path.repo"
              value: "/esbak"
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
        - name: esbak
          persistentVolumeClaim:
            claimName: es-pvc-bak


```

### 创建快照备份仓库

```
curl -X PUT "218.84.186.2:30006/_snapshot/test_bak" -H 'Content-Type: application/json' -d'
{
  "type": "fs",
  "settings": {
        "compress": true,
        "location": "/esbak/"
  }
}'
```

查看快照备份仓库信息

```
curl -XGET 'http://218.84.186.2:30006/_snapshot?pretty'
```

查看快照备份仓库列表

```
curl -XGET "218.84.186.2:30006/_cat/repositories?v"
```

### 创建索引备份

```
curl -XPUT 'http://218.84.186.2:30006/_snapshot/test_bak/qwert' -H 'Content-Type: application/json' -d '{"indices": "video_bz"}'
```

#### 注:假设要备份多个索引, 比如idx_1, idx_2, idx_3, 则可以

```
curl -XPUT 'http://192.168.1.10:9200/_snapshot/EsBackup_zip/snapshot_some_name'  -H 'Content-Type: application/json' -d '{"indices": "idx_1,idx_2,idx_3"}'
```

#### 查看备份进度

```
curl -XGET http://218.84.186.2:30006/_snapshot/test_bak/snapshot_all/_status
```

#### 提交备份快照请求后, 查看备份状态

```
curl -XGET 'http://218.84.186.2:30006/_snapshot/test_bak/qwert?pretty' -H 'Content-Type: application/json'
```

#### 创建全部索引数据备份

```
curl -XPUT 'http://218.84.186.2:30006/_snapshot/test_bak/snapshot_all' -H 'Content-Type: application/json' 
```

#####  查看单个备份全索引信息

```
curl -XGET "http://218.84.186.2:30006/_snapshot/test_bak/snapshot_all?pretty"
```

### 删除备份

```
curl -XDELETE "http://218.84.186.2:30006/qwert"  -H 'Content-Type: application/json'
```

### 恢复数据

#### 恢复单个索引

```
curl -XPOST 'http://192.168.1.10:9200/_snapshot/EsBackup_zip/snapshot_user_behavior_201702/_restore' -d '{
    "indices": "user_behavior_201702", 
    "rename_replacement": "restored_ub_201702"
}'
```

#### 恢复整个快照索引

```
curl -XPOST 'http://http://218.84.186.2:30006/_snapshot/test_bak/snapshot_some_name/_restore'
```

#### 查看恢复状态

```
curl -XGET "http://192.168.1.10:9200/_snapshot/EsBackup_zip/snapshot_user_behavior_201702/_status"
```



# Elasticdump

## 安装

```
npm install elasticdump

或

cnpm install elasticdump
```

### 使用时去`node_modules`目录下查找

```
/root/node_modules/elasticdump/bin
```

## 使用

### 查看远程服务器节点

```
curl '218.84.186.2:30006/_cat/nodes?v'
```

### 查看远程服务器索引

```
curl '218.84.186.2:30006/_cat/indices?v'
```

### 拷贝analyzer分词

```
./elasticdump \
  --input=http://218.84.186.2:30006/video_result \
  --output=http://127.0.0.1:9200/video_result \
  --type=analyzer
```

### 拷贝映射

```
./elasticdump \
  --input=http://218.84.186.2:30006/video_result \
  --output=http://127.0.0.1:9200/video_result \
  --type=mapping
```

### 拷贝数据

```
./elasticdump \
  --input=http://218.84.186.2:30006/video_result \
  --output=http://127.0.0.1:9200/video_result \
  --type=data
```



```
'#拷贝analyzer分词
./elasticdump \
  --input=http://218.84.186.2:30006/video_bz \
  --output=http://127.0.0.1:9200/video_bz \
  --type=analyzer
'#拷贝映射
./elasticdump \
  --input=http://218.84.186.2:30006/video_bz \
  --output=http://127.0.0.1:9200/video_bz \
  --type=mapping
'#拷贝数据
./elasticdump \
  --input=http://218.84.186.2:30006/video_bz \
  --output=http://127.0.0.1:9200/video_bz \
  --type=data
```

```

```





# Kibana

```
docker run -d --name kibana -e ELASTICSEARCH_URL=http://192.168.240.73:10000 -p 10001:5601 docker.elastic.co/kibana/kibana:6.6.2
```

```
或者用docker-compose
```

