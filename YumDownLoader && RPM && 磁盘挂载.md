# YumDownLoader && RPM && 磁盘挂载

## YumDownLoader

### 安装

```
yum install yum-utils -y
```

### 使用

```
yumdownloader --resolve --destdir=/root/zzz/ftp/ vsftpd
```

## RPM

### 安装软件

```
rpm -ivh apache-1.3.6.i386.rpm
```

### 升级软件

```
rpm -Uvh rpm包名
```

### 反安装(卸载)

#### 查找

```
rpm -qa | grep -i mysql
```

#### 卸载

```
rpm -e rpm包名
```

### 查询软件包的详细信息

```
rpm -qpi rpm包名
```

### 查询某个文件是属于那个rpm包的

```
rpm -qf rpm包名
```

### 查该软件包会向系统里面写入哪些文件

```
rpm -qpl rpm包名
```



## 磁盘挂载

### 查找未挂载磁盘

```
fdisk -l
```

### 创建挂载目录

```
 mkdir /data
```

### 格式化

```
#mkfs -t xfs -c /dev/xvdb
mkfs.xfs /dev/xvdb
```

### 挂载

```
mount /dev/xvdb /data
```

### 开机挂载

```
vi /etc/fstab
```

#### 加入

```
/dev/xvdb       /data   xfs     defaults,nofail 0       0
```

### 验证

```
df -h
```



## 磁盘扩容

### 查找未挂在磁盘

```
fdisk -l
```

以下以vdb为例

### 创建分区

```
fdisk /dev/vdb
```

操作如下

```
[root@slave01 ~]# fdisk /dev/vdb
欢迎使用 fdisk (util-linux 2.23.2)。

更改将停留在内存中，直到您决定将更改写入磁盘。
使用写入命令前请三思。

Device does not contain a recognized partition table
使用磁盘标识符 0x4472a336 创建新的 DOS 磁盘标签。

命令(输入 m 获取帮助)：n
Partition type:
   p   primary (0 primary, 0 extended, 4 free)
   e   extended
Select (default p): p
分区号 (1-4，默认 1)：1
起始 扇区 (2048-4194303，默认为 2048)：
将使用默认值 2048
Last 扇区, +扇区 or +size{K,M,G} (2048-4194303，默认为 4194303)：+1G
分区 1 已设置为 Linux 类型，大小设为 1 GiB

命令(输入 m 获取帮助)：w
The partition table has been altered!

Calling ioctl() to re-read partition table.
正在同步磁盘。
```

### 创建物理卷

```
pvcreate /dev/vdb1
```

### 将物理卷加入centos组

```
vgextend centos /dev/vdb1
```

### 扩展挂载

```
lvextend -L +910G /dev/mapper/centos-root
```

### 扩展文件系统

```
xfs_growfs /dev/mapper/centos-root
```

### 查看

```
df -h
```





