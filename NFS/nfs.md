#### NFS服务器搭建

##### 1).安装 NFS 服务器所需的软件包

```
yum install -y nfs-utils
```

##### 2).添加位置和权限

```
vim /etc/exports

```

```
/extends/ 192.168.136.0/24(rw,sync,no_root_squash,fsid=0)

```

或者可以这么设置

```
/home/lhcz/redis/ *(rw,all_squash)
/home/lhcz/redis-conf/ *(rw,all_squash)

```

注: *意思为所有人都可以访问 (rw,all_squash)意思为具有所有权限

##### 3).启动nfs服务

先为rpcbind和nfs做开机启动：(必须先启动rpcbind服务)

```
systemctl enable rpcbind.service
systemctl enable nfs-server.service

```

然后分别启动rpcbind和nfs服务：

```
systemctl start rpcbind.service
systemctl start nfs-server.service

```

确认NFS服务器启动成功：

```
exportfs -r
#使配置生效

exportfs
#可以查看到已经ok
/home/nfs 192.168.248.0/24

```

##### 4).客户端

###### 安装

```
yum install nfs-utils -y
```

###### 测试挂载

```
mount -t nfs 192.168.136.181:/extends/ /本地路径
```

###### 开机挂载

```
vi /etc/fstab
```

```
59.212.147.40:/home/data/40/ /home/data/40/ nfs defaults 0 0
59.212.147.41:/home/data/41/ /home/data/41/ nfs defaults 0 0
59.212.147.44:/home/data/44/ /home/data/44/ nfs defaults 0 0
59.212.147.45:/home/data/45/ /home/data/45/ nfs defaults 0 0
59.212.147.46:/home/data/46/ /home/data/46/ nfs defaults 0 0
59.212.147.62:/home/data/62/ /home/data/62/ nfs defaults 0 0
59.212.147.63:/home/data/63/ /home/data/63/ nfs defaults 0 0
59.212.147.64:/home/data/64/ /home/data/64/ nfs defaults 0 0
```



### 巴州实例

## NFS挂载

### 创建目录

```
mkdir /data/
```

#### 创建mysql目录

```
mkdir /data/mysql
mkdir /data/mysql/master1
mkdir /data/mysql/slave1
mkdir /data/mysql/slave2
```

#### 创建ES目录

```
mkdir -p /data/ES/ES-data-1
```

```
mkdir -p /data/ES/ES-data-2
```

### 分配目录权限

```
vim /etc/exports
```

```
/data/mysql 192.168.100.0/24(rw,sync,no_root_squash,fsid=0)
```

```
/data/ES 192.168.100.0/24(rw,sync,no_root_squash,fsid=0)
```

### 使配置生效

```
exportfs -r
```

#### 查看

```
exportfs
```

打印

```
/data/mysql   	192.168.100.0/24
```

```
/data/ES      	192.168.100.0/24
```

### 挂载

```
mount -t nfs 192.168.100.3:/data/mysql /data/mysql
```

```
mount -t nfs 192.168.100.4:/data/ES /data/ES
```



