# Redis Enterprise Cluster

github

```
https://github.com/RedisLabs/redis-enterprise-k8s-docs
```

redislabs

```
https://docs.redislabs.com/latest/platforms/kubernetes/
```



## 创建Namespace

```
kubectl create namespace redis
```

## 更改默认Namespace

```
kubectl config set-context --current --namespace=redis
```

## 使用pod安全策略[选做]

```
kubectl apply -f psp.yaml
```

如果使用此选项，则应在redis-enterprise-cluster.yaml中将策略名称添加到REC配置中。

```
podSecurityPolicyName: "redis-enterprise-psp"
```

## 创建rbac

```
kubectl apply -f rbac.yaml
```

## 创建crd

```
kubectl apply -f crd.yaml
```

## 部署operator

```
kubectl apply -f operator.yaml
```

运行`kubectl get Deployment`并验证redis-enterprise-operator部署是否正在运行

## 创建redis企业集群

```
kubectl apply -f redis-enterprise-cluster.yaml
```

运行`kubectl get rec`并确认创建成功。“ rec”是RedisEnterpriseClusters的快捷方式

