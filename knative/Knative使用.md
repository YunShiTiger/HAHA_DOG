# Knative使用



## 部署服务

### 创建一个名为的新文件`service.yaml`

```
apiVersion: serving.knative.dev/v1 # Current version of Knative
kind: Service
metadata:
  name: helloworld-go # The name of the app
  namespace: default # The namespace the app will use
spec:
  template:
    spec:
      containers:
        # - image: gcr.io/knative-samples/helloworld-go # The URL to the image of the app
        - image: hatchin/knative-helloworld
          env:
            - name: TARGET # The environment variable printed out by the sample app
              value: "Go Sample v1"

```

### 部署

```
kubectl apply --filename service.yaml
```

### 查看

```
kubectl get ksvc
```

打印

```
NAME            URL                                           LATESTCREATED         LATESTREADY           READY   REASON
helloworld-go   http://helloworld-go.default.www.xjlhcz.com   helloworld-go-zpxvx   helloworld-go-zpxvx   True    
```

### 测试

```
curl http://helloworld-go.default.www.xjlhcz.com
```

#### 实际测试[需要添加header]

```
curl -HHost:helloworld-go.default.xjlhcz.com http://192.168.240.121:31380
```

注：

*一段时间未访问会发现服务副本为0，原因是autoscala的作用。*







