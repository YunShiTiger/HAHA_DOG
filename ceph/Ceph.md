# Ceph

使用rook部署ceph于kubernetes集群

```
https://github.com/rook/rook/tree/master
```

↑rook的github安装配置yaml文件仓库地址



# Ceph部署

```
https://rook.io/docs/rook/v1.1/ceph-quickstart.html
```

```
https://mp.weixin.qq.com/s/mawVIlS6PeC3S6vk0KzJxw
```

## 部署rook

```
cd cluster/examples/kubernetes/ceph
```

```
kubectl create -f common.yaml
```

```
kubectl create -f operator.yaml
```

## 部署ceph

```
kubectl create -f cluster.yaml
```

注:

```
生产环境部署cluster,测试环境部署cluster-test
但是生产环境部署时要修改Yaml文件
```



## Ceph toolbox部署

但是生产环境部署时要修改Yaml文件

## Ceph toolbox部署

ceph命令工具盒子

```
kubectl create -f toolbox.yaml
```

### 查看健康状态

#### 进入容器

```
kubectl -n rook-ceph exec -it rook-ceph-tools-7989879b44-hvrz5 /bin/bash
```

#### 查看

```
ceph status
```



## 删除Ceph集群

删除已创建的Ceph集群，可执行下面命令：

```
kubectl delete -f cluster.yaml
```

删除Ceph集群后，在之前部署Ceph组件节点的/var/lib/rook/目录，会遗留下Ceph集群的配置信息。

若之后再部署新的Ceph集群，先把之前Ceph集群的这些信息删除，不然启动monitor会失败；

脚本内容

```
hosts=(
  ke-dev1-master3
  ke-dev1-worker1
  ke-dev1-worker3
  ke-dev1-worker4
)for host in ${hosts[@]} ; do
  ssh $host "rm -rf /var/lib/rook/*"done
```



# RBD服务

```
https://rook.io/docs/rook/v1.1/ceph-block.html
```

## 创建storageclass

```
vi storageclass.yaml
```

```
apiVersion: ceph.rook.io/v1
kind: CephBlockPool
metadata:
  name: replicapool
  namespace: rook-ceph
spec:
  failureDomain: host
  replicated:
    size: 3
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
   name: rook-ceph-block
# Change "rook-ceph" provisioner prefix to match the operator namespace if needed
provisioner: rook-ceph.rbd.csi.ceph.com
parameters:
    # clusterID is the namespace where the rook cluster is running
    clusterID: rook-ceph
    # Ceph pool into which the RBD image shall be created
    pool: replicapool

    # RBD image format. Defaults to "2".
    imageFormat: "2"

    # RBD image features. Available for imageFormat: "2". CSI RBD currently supports only `layering` feature.
    imageFeatures: layering

    # The secrets contain Ceph admin credentials.
    csi.storage.k8s.io/provisioner-secret-name: rook-csi-rbd-provisioner
    csi.storage.k8s.io/provisioner-secret-namespace: rook-ceph
    csi.storage.k8s.io/node-stage-secret-name: rook-csi-rbd-node
    csi.storage.k8s.io/node-stage-secret-namespace: rook-ceph

    # Specify the filesystem type of the volume. If not specified, csi-provisioner
    # will set default as `ext4`.
    csi.storage.k8s.io/fstype: xfs

# Delete the rbd volume when a PVC is deleted
reclaimPolicy: Delete
```

```
如果使用Retain回收策略时，PersistentVolume及时删除了，任何由a支持的Ceph RBD也将继续存在。这些Ceph RBD将需要使用手动清理rbd rm。
```

```
kubectl create -f storageclass.yaml
或者
kubectl create -f cluster/examples/kubernetes/ceph/csi/rbd/storageclass.yaml
```

## 消耗存储空间：Wordpress示例

从`cluster/examples/kubernetes`目录启动mysql和wordpress ：

```
kubectl create -f mysql.yaml
kubectl create -f wordpress.yaml
```

## 卸载RBD

```
kubectl delete -n rook-ceph cephblockpools.ceph.rook.io replicapool
```

```
kubectl delete storageclass rook-ceph-block
```

## Flex Driver

```
要基于Flex驱动程序而不是CSI驱动程序创建卷，确保通过Ceph CSI启用了flex驱动。operator.yaml部署中要将其ROOK_ENABLE_FLEX_DRIVER设置为TRUE。POOL定义与CSI驱动相同。
```

```
kubectl create -f cluster/examples/kubernetes/ceph/flex/storageclass.yaml
```

# 对象存储CRD

```
- 对象存储至少需要3个bluestore OSD，每个OSD位于不同的节点上。
- 每个OSD必须位于不同的节点上，而且failureDomain要切设置为host，并且erasureCoded块设置至少需要3个不同的OSD（2 dataChunks+ 1 codingChunks）。
```

## 创建对象存储

```
apiVersion: ceph.rook.io/v1
kind: CephObjectStore
metadata:
  name: my-store
  namespace: rook-ceph
spec:
  metadataPool:
    failureDomain: host
    replicated:
      size: 3
  dataPool:
    failureDomain: host
    erasureCoded:
      dataChunks: 2
      codingChunks: 1
  gateway:
    type: s3
    sslCertificateRef:
    port: 80
    securePort:
    instances: 1
```

`CephObjectStore`创建完成后，Rook操作员将创建启动服务所需的所有池和其他资源。(这可能需要一分钟才能完成)

```
# Create the object store
kubectl create -f object.yaml

# To confirm the object store is configured, wait for the rgw pod to start
kubectl -n rook-ceph get pod -l app=rook-ceph-rgw
```

## 创建一个用户

创建一个`CephObjectStoreUser`，它将用于使用S3 API连接到集群中的RGW服务。

### 创建

```
kubectl create -f object-user.yaml
```

### 查看

```
kubectl -n rook-ceph describe secret rook-ceph-object-user-my-store-my-user
```

### 查看账号密码

#### 账号

```
kubectl -n rook-ceph get secret rook-ceph-object-user-my-store-my-user -o yaml | grep AccessKey | awk '{print $2}' | base64 --decode
```

打印

```
FXYV502ECG5HKINZGUE8
```

#### 密码

```
kubectl -n rook-ceph get secret rook-ceph-object-user-my-store-my-user -o yaml | grep SecretKey | awk '{print $2}' | base64 --decode
```

打印

```
W9IzPSjctVsLBiyNGibXOKsYJSu4BZKNcZgS92tx
```

## 消耗对象存储

### 进入toolbox安装s3cmd

```
yum --assumeyes install s3cmd -y
```

### 连接环境变量(toolbox内)

```
export AWS_HOST=<host>
export AWS_ENDPOINT=<endpoint>
export AWS_ACCESS_KEY_ID=<accessKey>
export AWS_SECRET_ACCESS_KEY=<secretKey>
```

- `Host`：在群集中找到rgw服务的DNS主机名。假设默认`rook-ceph`群集，则为`rook-ceph-rgw-my-store.rook-ceph`。
- `Endpoint`：rgw服务正在侦听的端点。运行`kubectl -n rook-ceph get svc rook-ceph-rgw-my-store`，然后组合clusterIP和端口。
- `Access key`：`access_key`如上打印的用户
- `Secret key`：`secret_key`如上打印的用户

```
export AWS_HOST=rook-ceph-rgw-my-store.rook-ceph
export AWS_ENDPOINT=10.10.118.65:80
export AWS_ACCESS_KEY_ID=FXYV502ECG5HKINZGUE8
export AWS_SECRET_ACCESS_KEY=W9IzPSjctVsLBiyNGibXOKsYJSu4BZKNcZgS92tx
```

### 创建bucket

#### 创建bucket

```
s3cmd mb --no-ssl --host=${AWS_HOST} --region=":default-placement" --host-bucket="" s3://rookbucket
```

打印

```
Bucket 's3://rookbucket/' created
```

#### 查看bucket

```
s3cmd ls --no-ssl --host=${AWS_HOST}
```

打印

```
2019-10-31 06:54  s3://rookbucket
```

### 上传和下载[PUT or GET an object]

#### 创建文件

```
echo "Hello Rook" > /tmp/rookObj
```

##### 上传文件

```
s3cmd put /tmp/rookObj --no-ssl --host=${AWS_HOST} --host-bucket=  s3://rookbucket
```

#### 下载文件

```
s3cmd get s3://rookbucket/rookObj /tmp/rookObj-download --no-ssl --host=${AWS_HOST} --host-bucket=
```

##### 验证

```
cat /tmp/rookObj-download
```

## 集群外部访问

#### 查看当前service

```
kubectl -n rook-ceph get service rook-ceph-rgw-my-store
```

```
apiVersion: v1
kind: Service
metadata:
  name: rook-ceph-rgw-my-store-external
  namespace: rook-ceph
  labels:
    app: rook-ceph-rgw
    rook_cluster: rook-ceph
    rook_object_store: my-store
spec:
  ports:
  - name: rgw
    port: 80
    protocol: TCP
    targetPort: 80
    nodePort: 30000
  selector:
    app: rook-ceph-rgw
    rook_cluster: rook-ceph
    rook_object_store: my-store
  sessionAffinity: None
  type: NodePort
```

#### 创建service

```
kubectl create -f rgw-external.yaml
```

#### 查看service

```
kubectl -n rook-ceph get service rook-ceph-rgw-my-store rook-ceph-rgw-my-store-external
```

# CephFS

```
在operator.yaml中将ROOK_ALLOW_MULTIPLE_FILESYSTEMS设定为true
```

## 创建文件系统

### 创建

```
kubectl create -f filesystem.yaml
```

这可能需要一分钟才能完成。

### 查看

#### 查看pod

```
kubectl -n rook-ceph get pod -l app=rook-ceph-mds
```

#### 进入toolbox查看ceph集群状态

```
kubectl -n rook-ceph exec -it rook-ceph-tools-7989879b44-kml5s /bin/bash
```

```
ceph status
```

打印

```
  cluster:
    id:     e072f83f-dc39-4371-92ce-ad5bdaa8b9b2
    health: HEALTH_OK
 
  services:
    mon: 3 daemons, quorum a,b,c (age 5h)
    mgr: a(active, since 4m)
    mds: myfs:1 {0=myfs-a=up:active} 1 up:standby-replay #这呢
    osd: 3 osds: 3 up (since 5h), 3 in (since 5h)
    rgw: 1 daemon active (my.store.a)
 
  data:
    pools:   10 pools, 80 pgs
    objects: 336 objects, 228 MiB
    usage:   36 GiB used, 6.1 TiB / 6.1 TiB avail
    pgs:     80 active+clean
 
  io:
    client:   938 B/s rd, 170 B/s wr, 1 op/s rd, 0 op/s wr

```

##### toolbox中挂载cephfs

```
ceph-fuse /mnt/
```

打印

```
ceph-fuse[608]: starting ceph client2019-11-01 02:59:43.876 7f924c9e2e00 -1 init, newargv = 0x56348e3dd570 newargc=7

ceph-fuse[608]: starting fuse
```

##### 查看

```
df -h
```

##### 告警

###### 1.HEALTH_WARN too few PGs per OSD (24 < min 30)

```
  cluster:
    id:     666c6231-ce29-42f7-9089-4bf202084bf8
    health: HEALTH_WARN
            too few PGs per OSD (24 < min 30)
 
  services:
    mon: 3 daemons, quorum a,b,c (age 11d)
    mgr: a(active, since 11d)
    mds: myfs:1 {0=myfs-a=up:active} 1 up:standby-replay
    osd: 3 osds: 3 up (since 11d), 3 in (since 11d)
 
  data:
    pools:   3 pools, 24 pgs
    objects: 33 objects, 79 KiB
    usage:   44 GiB used, 6.1 TiB / 6.1 TiB avail
    pgs:     24 active+clean
 
  io:
    client:   853 B/s rd, 1 op/s rd, 0 op/s wr
```

解决:

```
ceph osd pool create pool_1 100
```

```
https://www.jianshu.com/p/e628da68328d
```

## 挂载使用

### 创建StorageClass

```
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: rook-cephfs
# Change "rook-ceph" provisioner prefix to match the operator namespace if needed
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

reclaimPolicy: Delete
```

如果将Rook运算符部署在“ rook-ceph”以外的名称空间中，请更改预配器中的前缀以匹配所使用的名称空间。例如，如果Rook运算符在“ rook-op”中运行，则配置程序的值应为“ rook-op.rbd.csi.ceph.com”。

```
kubectl create -f cluster/examples/kubernetes/ceph/csi/cephfs/storageclass.yaml
```

### 消费cephfs

```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: cephfs-pvc
spec:
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 1Gi
  storageClassName: csi-cephfs
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kube-registry
  namespace: kube-system
  labels:
    k8s-app: kube-registry
    kubernetes.io/cluster-service: "true"
spec:
  replicas: 3
  selector:
    matchLabels:
      k8s-app: kube-registry
  template:
    metadata:
      labels:
        k8s-app: kube-registry
        kubernetes.io/cluster-service: "true"
    spec:
      containers:
      - name: registry
        image: registry:2
        imagePullPolicy: Always
        resources:
          limits:
            cpu: 100m
            memory: 100Mi
        env:
        # Configuration reference: https://docs.docker.com/registry/configuration/
        - name: REGISTRY_HTTP_ADDR
          value: :5000
        - name: REGISTRY_HTTP_SECRET
          value: "Ple4seCh4ngeThisN0tAVerySecretV4lue"
        - name: REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY
          value: /var/lib/registry
        volumeMounts:
        - name: image-store
          mountPath: /var/lib/registry
        ports:
        - containerPort: 5000
          name: registry
          protocol: TCP
        livenessProbe:
          httpGet:
            path: /
            port: registry
        readinessProbe:
          httpGet:
            path: /
            port: registry
      volumes:
      - name: image-store
        persistentVolumeClaim:
          claimName: cephfs-pvc
          readOnly: false
```

## 拆除

要清除文件系统演示创建的所有工件：

```
kubectl delete -f kube-registry.yaml
```

要删除文件系统组件和备份数据，请删除文件系统CRD。**警告：数据将被删除**

```
kubectl -n rook-ceph delete cephfilesystem myfs
```



# 全部卸载

```
https://rook.io/docs/rook/v1.1/ceph-teardown.html
```

















