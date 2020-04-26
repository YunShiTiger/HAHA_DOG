# Harbor

## HELM

### 下载

```
git clone https://github.com/goharbor/harbor-helm
```

### 切换分支

```
cd harbor-helm
```

```
git checkout 0.3.0
```

### 修改源

```
vi requirements.yaml
```

替换为

```
dependencies:
- name: redis
  version: 1.1.15
  repository: https://kubernetes.oss-cn-hangzhou.aliyuncs.com/charts
  # repository: https://kubernetes-charts.storage.googleapis.com
```

### 更新依赖

```
helm dependency update
```

会生成一个charts目录 修改里面的redis

### 修改配置文件

```
sed -i 's@# storageClass: "-"@storageClass: "nfs"@g' values.yaml
```

```
:%s/ReadWriteOnce/ReadWriteMany/g
```

### 挂载创建

```
apiVersion: v1
kind: PersistentVolume
metadata:
  name: harbor-pv-1
spec:
  capacity:
    storage: 100G
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Recycle
  storageClassName: nfs
  nfs:
    server: 192.168.240.59
    path: /data/harbor/data1
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: harbor-pv-2
spec:
  capacity:
    storage: 100G
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Recycle
  storageClassName: nfs
  nfs:
    server: 192.168.240.59
    path: /data/harbor/data2
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: harbor-pv-3
spec:
  capacity:
    storage: 100G
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Recycle
  storageClassName: nfs
  nfs:
    server: 192.168.240.59
    path: /data/harbor/data3
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: harbor-pv-4
spec:
  capacity:
    storage: 100G
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Recycle
  storageClassName: nfs
  nfs:
    server: 192.168.240.59
    path: /data/harbor/data1
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: harbor-pv-1
spec:
  capacity:
    storage: 100G
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Recycle
  storageClassName: nfs
  nfs:
    server: 192.168.240.59
    path: /data/harbor/data4
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: harbor-pv-5
spec:
  capacity:
    storage: 100G
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Recycle
  storageClassName: nfs
  nfs:
    server: 192.168.240.59
    path: /data/harbor/data5
```

## 安装

```
helm install --name tachibana .
```

## 卸载

```
helm delete --purge tachibana
```

```
kubectl delete pvc database-data-tachibana-harbor-database-0 
```

```
rm -rf /data/harbor/data*/*
```

## 镜像:

```
docker pull goharbor/chartmuseum-photon:v0.7.1-v1.6.0
docker pull goharbor/harbor-adminserver:v1.6.0
docker pull goharbor/harbor-jobservice:v1.6.0
docker pull goharbor/harbor-ui:v1.6.0
docker pull goharbor/harbor-db:v1.6.0
docker pull goharbor/registry-photon:v2.6.2-v1.6.0
docker pull goharbor/chartmuseum-photon:v0.7.1-v1.6.0
docker pull goharbor/clair-photon:v2.0.5-v1.6.0
docker pull goharbor/notary-server-photon:v0.5.1-v1.6.0
docker pull goharbor/notary-signer-photon:v0.5.1-v1.6.0
docker pull bitnami/redis:4.0.8-r2
```

```
tachibana-harbor-ingress  core.harbor.domain,notary.harbor.domain
```

```
NOTES:
Please wait for several minutes for Harbor deployment to complete.
Then you should be able to visit the UI portal at https://core-harbor.yourfather.xyz. 
For more details, please visit https://github.com/goharbor/harbor.

```



# Harbor

## Docker-Compose[Offline installer]

## 下载

```
wget https://storage.googleapis.com/harbor-releases/release-1.7.0/harbor-offline-installer-v1.7.5.tgz
```

### 解压

```
tar xvf harbor-offline-installer-v1.7.5.tgz
```

### 修改配置文件

```
vim harbor.cfg
```

### 内容修改

```
hostname = 192.168.240.59
```

登录地址

```
ui_url_protocol = http
```

协议选择http，不用配置证书

```
ssl_cert = /data/cert/server.crt  
```

若没有此目录则需要手动建立

```
harbor_admin_password = 12345
```

启动Harbor后，管理员UI登录的密码，默认是Harbor1

### 修改docker-compose.yml

```
将80端口修改为自己需要的端口
```

## 安装

```
./install.sh 
```

## 测试

### 页面访问192.168.240.59操作

用户名:admin

密码:12345

#### 创建仓库

①.点击`项目`

②.点击`新建项目`

### 命令行

#### 配置docker设置添加仓库

```
vi /lib/systemd/system/docker.service
```

修改

```
ExecStart=/usr/bin/dockerd --insecure-registry 192.168.240.59
```

#### 重启docker

```
systemctl daemon-reload
```

```
systemctl restart docker
```

#### 登录测试

```
docker login 192.168.240.59
```

用户名密码同页面

```
docker login -u admin -p 12345 192.168.240.73
```

#### 上传镜像

##### tag

```
docker tag alpine 192.168.240.59/test/alpine:v1
```

##### push

```
docker push 192.168.240.59/test/alpine:v1
```

#### 启动、停止、重启

进入docker-compose目录

```
docker-compose up -d
```

```
docker-compose stop
```

```
docker-compose restart
```











