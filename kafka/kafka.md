# Kafka

## zookeeper

### Service

```
apiVersion: v1
kind: Service
metadata:
  name: zoo1
  labels:
    app: zookeeper-1
spec:
  ports:
  - name: client
    port: 2181
    protocol: TCP
  - name: follower
    port: 2888
    protocol: TCP
  - name: leader
    port: 3888
    protocol: TCP
  selector:
    app: zookeeper-1
---
apiVersion: v1
kind: Service
metadata:
  name: zoo2
  labels:
    app: zookeeper-2
spec:
  ports:
  - name: client
    port: 2181
    protocol: TCP
  - name: follower
    port: 2888
    protocol: TCP
  - name: leader
    port: 3888
    protocol: TCP
  selector:
    app: zookeeper-2
---
apiVersion: v1
kind: Service
metadata:
  name: zoo3
  labels:
    app: zookeeper-3
spec:
  ports:
  - name: client
    port: 2181
    protocol: TCP
  - name: follower
    port: 2888
    protocol: TCP
  - name: leader
    port: 3888
    protocol: TCP
  selector:
    app: zookeeper-3
```

### Service-NodePort

```
apiVersion: v1
kind: Service
metadata:
  name: zoo1-nodeport
  labels:
    app: zookeeper-1
spec:
  type: NodePort
  ports:
  - name: client
    port: 2181
    nodePort: 32181
    targetPort: 2181
  selector:
    app: zookeeper-1
---
apiVersion: v1
kind: Service
metadata:
  name: zoo2-nodeport
  labels:
    app: zookeeper-2
spec:
  type: NodePort
  ports:
  - name: client
    port: 2181
    nodePort: 32182
    targetPort: 2181
  selector:
    app: zookeeper-2
---
apiVersion: v1
kind: Service
metadata:
  name: zoo3-nodeport
  labels:
    app: zookeeper-3
spec:
  type: NodePort
  ports:
  - name: client
    port: 2181
    nodePort: 32183
    targetPort: 2181
  selector:
    app: zookeeper-3
```

### Deployment

```
kind: Deployment
apiVersion: extensions/v1beta1
metadata:
  name: zookeeper-deployment-1
spec:
  replicas: 1
  selector:
    matchLabels:
      app: zookeeper-1
      name: zookeeper-1
  template:
    metadata:
      labels:
        app: zookeeper-1
        name: zookeeper-1
    spec:
      containers:
      - name: zoo1
        image: 192.168.159.130:5000/zookeeper
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 2181
        env:
        - name: ZOOKEEPER_ID
          value: "1"
        - name: ZOOKEEPER_SERVER_1
          value: zoo1
        - name: ZOOKEEPER_SERVER_2
          value: zoo2
        - name: ZOOKEEPER_SERVER_3
          value: zoo3
---
kind: Deployment
apiVersion: extensions/v1beta1
metadata:
  name: zookeeper-deployment-2
spec:
  replicas: 1
  selector:
    matchLabels:
      app: zookeeper-2
      name: zookeeper-2
  template:
    metadata:
      labels:
        app: zookeeper-2
        name: zookeeper-2
    spec:
      containers:
      - name: zoo2
        image: 192.168.159.130:5000/zookeeper
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 2181
        env:
        - name: ZOOKEEPER_ID
          value: "2"
        - name: ZOOKEEPER_SERVER_1
          value: zoo1
        - name: ZOOKEEPER_SERVER_2
          value: zoo2
        - name: ZOOKEEPER_SERVER_3
          value: zoo3
---
kind: Deployment
apiVersion: extensions/v1beta1
metadata:
  name: zookeeper-deployment-3
spec:
  replicas: 1
  selector:
    matchLabels:
      app: zookeeper-3
      name: zookeeper-3
  template:
    metadata:
      labels:
        app: zookeeper-3
        name: zookeeper-3
    spec:
      containers:
      - name: zoo3
        image: 192.168.159.130:5000/zookeeper
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 2181
        env:
        - name: ZOOKEEPER_ID
          value: "3"
        - name: ZOOKEEPER_SERVER_1
          value: zoo1
        - name: ZOOKEEPER_SERVER_2
          value: zoo2
        - name: ZOOKEEPER_SERVER_3
          value: zoo3
```

### 测试

#### 进入zookeeper各容器

只以单个为例

```
kubectl exec -it zookeeper-deployment-1-7bb6bbccc6-xwpwt /bin/bash
```

#### 查看集群信息

##### 进入目录

```
cd /opt/zookeeper/bin
```

##### 查看节点信息

```
./zkServer.sh status
```



## kafka

### Service

```
apiVersion: v1
kind: Service
metadata:
  name: kafka-service-1
  labels:
    app: kafka-service-1
spec:
  type: NodePort
  ports:
  - port: 9092
    name: kafka-service-1
    targetPort: 9092
    nodePort: 30901
    protocol: TCP
  selector:
    app: kafka-service-1
---
apiVersion: v1
kind: Service
metadata:
  name: kafka-service-2
  labels:
    app: kafka-service-2
spec:
  type: NodePort
  ports:
  - port: 9092
    name: kafka-service-2
    targetPort: 9092
    nodePort: 30902
    protocol: TCP
  selector:
    app: kafka-service-2
---
apiVersion: v1
kind: Service
metadata:
  name: kafka-service-3
  labels:
    app: kafka-service-3
spec:
  type: NodePort
  ports:
  - port: 9092
    name: kafka-service-3
    targetPort: 9092
    nodePort: 30903
    protocol: TCP
  selector:
    app: kafka-service-3
```

### Deployment

```
kind: Deployment
apiVersion: extensions/v1beta1
metadata:
  name: kafka-deployment-1
spec:
  replicas: 1
  selector:
    matchLabels:
      name: kafka-service-1
  template:
    metadata:
      labels:
        name: kafka-service-1
        app: kafka-service-1
    spec:
      containers:
      - name: kafka-1
        image: 192.168.159.130:5000/kafka
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 9092
        env:
        - name: KAFKA_LISTENERS
          value: PLAINTEXT://:9092
        - name: KAFKA_ADVERTISED_LISTENERS
          value: PLAINTEXT://192.168.1.103:30902
        - name: KAFKA_ZOOKEEPER_CONNECT
          value: zoo1:2181,zoo2:2181,zoo3:2181
        - name: KAFKA_BROKER_ID
          value: "1"
        - name: KAFKA_CREATE_TOPICS
          value: mytopic:2:1
---
kind: Deployment
apiVersion: extensions/v1beta1
metadata:
  name: kafka-deployment-2
spec:
  replicas: 1
  selector:
  selector:
    matchLabels:
      name: kafka-service-2
  template:
    metadata:
      labels:
        name: kafka-service-2
        app: kafka-service-2
    spec:
      containers:
      - name: kafka-2
        image: 192.168.159.130:5000/kafka
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 9092
        env:        
        - name: KAFKA_LISTENERS
          value: PLAINTEXT://:9092
        - name: KAFKA_ADVERTISED_LISTENERS
          value: PLAINTEXT://192.168.1.103:30903
        - name: KAFKA_ZOOKEEPER_CONNECT
          value: zoo1:2181,zoo2:2181,zoo3:2181
        - name: KAFKA_BROKER_ID
          value: "2"
---
kind: Deployment
apiVersion: extensions/v1beta1
metadata:
  name: kafka-deployment-3
spec:
  replicas: 1
  selector:
  selector:
    matchLabels:
      name: kafka-service-3
  template:
    metadata:
      labels:
        name: kafka-service-3
        app: kafka-service-3
    spec:
      containers:
      - name: kafka-3
        image: 192.168.159.130:5000/kafka
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 9092
        env:
        - name: KAFKA_LISTENERS
          value: PLAINTEXT://:9092
        - name: KAFKA_ADVERTISED_LISTENERS
          value: PLAINTEXT://192.168.1.103:30904
        - name: KAFKA_ZOOKEEPER_CONNECT
          value: zoo1:2181,zoo2:2181,zoo3:2181
        - name: KAFKA_BROKER_ID
          value: "3"
```

### 测试

#### 进入kafka各容器

只以单个为例

```
kubectl exec -it kafka-deployment-1-5f8569fd69-8l4hj /bin/bash
```

#### Topic

##### 创建topic

```
kafka-topics.sh --create --zookeeper 59.212.147.64:32181 --replication-factor 3 --partitions 3 --topic test1
```

```
# --create：表示创建
# --zookeeper 后面的参数是zk的集群节点
# --replication-factor 3 ：表示复本数
# --partitions 3：表示分区数
# --topic test：表示topic的主题名称
```

##### 查看topic

```
kafka-topics.sh --list --zookeeper 59.212.147.64:32181
```

##### 查看topic详细信息

```
kafka-topics.sh --describe --zookeeper 59.212.147.64:32181
```

##### 删除topic

```
kafka-topics.sh --delete --zookeeper 59.212.147.64:32181 --topic test
```

#### 生产者

##### 创建生产者

```
kafka-console-producer.sh --broker-list 59.212.147.64:30901 --topic test
```

注:之后进入输入模式，便可随便输入。

#### 消费者

##### 创建消费者

```
kafka-console-consumer.sh --bootstrap-server 59.212.147.64:30902 --from-beginning --topic test
```

