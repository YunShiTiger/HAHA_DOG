# ElasticSearch-Kubernetes

## ElasticSearch

### 部署operator

```
kubectl apply -f https://download.elastic.co/downloads/eck/1.0.1/all-in-one.yaml
```

### 查看日志

```
kubectl -n elastic-system logs -f statefulset.apps/elastic-operator
```

### 部署elasticsearch

```
cat <<EOF | kubectl apply -f -
apiVersion: elasticsearch.k8s.elastic.co/v1
kind: Elasticsearch
metadata:
  name: quickstart
spec:
  version: 7.6.1
  http:
    tls:
      selfSignedCertificate:
        disabled: true
  nodeSets:
  - name: default
    count: 2
    podTemplate:
      spec:
        containers:
        - name: elasticsearch
          env:
          - name: ES_JAVA_OPTS
            value: -Xms8g -Xmx8g
          resources:
            requests:
              memory: 5Gi
              cpu: 2
            limits:
              memory: 10Gi
              cpu: 8
        affinity:
          podAntiAffinity:
            requiredDuringSchedulingIgnoredDuringExecution:
            - labelSelector:
                matchExpressions:
                - key: elasticsearch.k8s.elastic.co/cluster-name
                  operator: In
                  values:
                  - quickstart
              topologyKey: kubernetes.io/hostname
    volumeClaimTemplates:
    - metadata:
        name: elasticsearch-data
      spec:
        accessModes:
        - ReadWriteMany
        resources:
          requests:
            storage: 50Gi
        storageClassName: csi-cephfs
    config:
      node.master: true
      node.data: true
      node.ingest: true
      node.store.allow_mmap: false
EOF
```

```
注:
上述前提是提前创建StorageClass
```

#### 查看

```
kubectl get pods --selector='elasticsearch.k8s.elastic.co/cluster-name=quickstart'
```

##### 打印日志

```
kubectl logs -f quickstart-es-default-0
```

### 查看集群状态

```
kubectl get elasticsearch
```

### 查看service

```
kubectl get service quickstart-es-http
```

### 获取密码

```
kubectl get secret quickstart-es-elastic-user -o=jsonpath='{.data.elastic}' | base64 --decode
```

打印

```
8gkfcr67l2w7knbgbqhssn26
```

#### 用户名密码

```
username: elastic
password: 8gkfcr67l2w7knbgbqhssn26
```

### 集群内部登录测试

```
curl -u "elastic:8gkfcr67l2w7knbgbqhssn26" -k "http://quickstart-es-http:9200"
```

### 编辑service为nodeport

```
 kubectl edit service quickstart-es-http
```

修改为

```
  ports:
  - name: https
    nodePort: 30000
    port: 9200
    protocol: TCP
    targetPort: 9200
```

### 集群外访问

#### 页面访问

```
http://202.107.190.8:10381/
```

输入用户名密码

#### ElasticSearch-Head访问

```
http://202.107.190.8:10381/
```

## Kibana

### 部署kibana

```
cat <<EOF | kubectl apply -f -
apiVersion: kibana.k8s.elastic.co/v1
kind: Kibana
metadata:
  name: quickstart
spec:
  version: 7.6.1
  count: 1
  elasticsearchRef:
    name: quickstart
  podTemplate:
    spec:
      containers:
      - name: kibana
        resources:
          requests:
            memory: 2Gi
            cpu: 1.0
          limits:
            memory: 5Gi
            cpu: 4
EOF
```

#### 查看

```
kubectl get kibana
```

```
kubectl get pod --selector='kibana.k8s.elastic.co/name=quickstart'
```

### 查看service

```
kubectl get service quickstart-kb-http
```

#### 编辑service

```
kubectl edit service quickstart-kb-http
```

改为

```
ports:
  - name: https
    nodePort: 30001
    port: 5601
    protocol: TCP
    targetPort: 5601
  selector:
    common.k8s.elastic.co/type: kibana
    kibana.k8s.elastic.co/name: quickstart
  sessionAffinity: None
  type: NodePort
```

### 获取密码

```
kubectl get secret quickstart-es-elastic-user -o=jsonpath='{.data.elastic}' | base64 --decode; echo
```

### 使用页面访问

```
https://202.107.190.8:10382/
```

```
username: elastic
password: 8gkfcr67l2w7knbgbqhssn26
```











