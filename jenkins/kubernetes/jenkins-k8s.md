# Jenkins on Kubernetes

## 安装jx

```
mkdir -p ~/.jx/bin
```

```
curl -L https://github.com/jenkins-x/jx/releases/download/v2.0.118/jx-linux-amd64.tar.gz | tar xzv -C ~/.jx/bin
```

```
export PATH=$PATH:~/.jx/bin
```

```
echo 'export PATH=$PATH:~/.jx/bin' >> ~/.bashrc
```

或者将`.jx/bin/`下的`jx`拷贝到`/usr/local/bin/`目录

```
mv jx /usr/local/bin
```

## 验证集群

```
jx compliance run
```

### 查看状态

```
jx compliance status
```

### 查看结果

```
jx compliance results
```

### 删除验证

```
jx compliance delete
```

## 安装Jenkins X

```
jx install --provider=kubernetes --external-ip 192.168.240.59 \
--ingress-service= jenkins-x \
--ingress-deployment= jenkins-x \
--ingress-namespace=kube-system
```

