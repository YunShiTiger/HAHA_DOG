# fastdfs

把FastDFS目录贴入服务器。

## 构建镜像

### 修改配置文件

进入部署包的FastDFS文件夹中，修改mod_fastdfs.conf跟storage.conf文件中的参数（修改为计划安装为tracker服务器的公网IP和端口）修改参数如下：

```
tracker_server=192.168.188.10:22122
tracker_server=192.168.188.10:22222
tracker_server=192.168.188.10:22322
tracker_server=192.168.188.10:22422
tracker_server=192.168.188.10:22522
tracker_server=192.168.188.36:22122
tracker_server=192.168.188.36:22222
tracker_server=192.168.188.36:22322
tracker_server=192.168.188.36:22422
tracker_server=192.168.188.36:22522
```

### 构建

在当前目录下执行

```
docker  build  -t  fastdfs  --rm=true .
```



## 创建tracker

fastdfs镜像安装完后,先启动tracker，后启动storage。

```
docker run -d --name tracker1 -v /data/tracker/data01:/fastdfs/tracker/data -e TR_PORT=22122 -p 22122:22122 192.168.188.77:5000/fastdfs tracker
```

```
docker run -d --name tracker2 -v /data/tracker/data02:/fastdfs/tracker/data -e TR_PORT=22222 -p 22222:22222 192.168.188.77:5000/fastdfs tracker
```

```
docker run -d --name tracker3 -v /data/tracker/data03:/fastdfs/tracker/data -e TR_PORT=22322 -p 22322:22322 192.168.188.77:5000/fastdfs tracker
```

```
docker run -d --name tracker4 -v /data/tracker/data04:/fastdfs/tracker/data -e TR_PORT=22422 -p 22422:22422 192.168.188.77:5000/fastdfs tracker
```

```
docker run -d --name tracker5 -v /data/tracker/data05:/fastdfs/tracker/data -e TR_PORT=22522 -p 22522:22522 192.168.188.77:5000/fastdfs tracker
```



## 创建storage

```
docker run -d --name storage1 -v /data/storage/data01:/fastdfs/storage/data -v /data/storage/store_path01:/fastdfs/store_path -e ST_PORT=23001 -e NGX_PORT=3001 -e GROUP_NAME=group1 -p 23001:23001 -p 3001:3001 192.168.188.77:5000/fastdfs storage
```

```
docker run -d --name storage2 -v /data/storage/data02:/fastdfs/storage/data -v /data/storage/store_path02:/fastdfs/store_path -e ST_PORT=23002 -e NGX_PORT=3002 -e GROUP_NAME=group2 -p 23002:23002 -p 3002:3002 192.168.188.77:5000/fastdfs storage
```

```
docker run -d --name storage3 -v /data/storage/data03:/fastdfs/storage/data -v /data/storage/store_path03:/fastdfs/store_path -e ST_PORT=23003 -e NGX_PORT=3003 -e GROUP_NAME=group3 -p 23003:23003 -p 3003:3003 192.168.188.77:5000/fastdfs storage
```

```
docker run -d --name storage4 -v /data/storage/data04:/fastdfs/storage/data -v /data/storage/store_path04:/fastdfs/store_path -e ST_PORT=23004 -e NGX_PORT=3004 -e GROUP_NAME=group4 -p 23004:23004 -p 3004:3004 192.168.188.77:5000/fastdfs storage
```

```
docker run -d --name storage5 -v /data/storage/data05:/fastdfs/storage/data -v /data/storage/store_path05:/fastdfs/store_path -e ST_PORT=23005 -e NGX_PORT=3005 -e GROUP_NAME=group5 -p 23005:23005 -p 3005:3005 192.168.188.77:5000/fastdfs storage
```

```
docker run -d --name storage6 -v /data/storage/data06:/fastdfs/storage/data -v /data/storage/store_path06:/fastdfs/store_path -e ST_PORT=23006 -e NGX_PORT=3006 -e GROUP_NAME=group6 -p 23006:23006 -p 3006:3006 192.168.188.77:5000/fastdfs storage
```

```
docker run -d --name storage7 -v /data/storage/data07:/fastdfs/storage/data -v /data/storage/store_path07:/fastdfs/store_path -e ST_PORT=23007 -e NGX_PORT=3007 -e GROUP_NAME=group7 -p 23007:23007 -p 3007:3007 192.168.188.77:5000/fastdfs storage
```

```
docker run -d --name storage8 -v /data/storage/data08:/fastdfs/storage/data -v /data/storage/store_path08:/fastdfs/store_path -e ST_PORT=23008 -e NGX_PORT=3008 -e GROUP_NAME=group8 -p 23008:23008 -p 3008:3008 192.168.188.77:5000/fastdfs storage
```

```
docker run -d --name storage9 -v /data/storage/data09:/fastdfs/storage/data -v /data/storage/store_path09:/fastdfs/store_path -e ST_PORT=23009 -e NGX_PORT=3009 -e GROUP_NAME=group9 -p 23009:23009 -p 3009:3009 192.168.188.77:5000/fastdfs storage
```

```
docker run -d --name storage10 -v /data/storage/data10:/fastdfs/storage/data -v /data/storage/store_path10:/fastdfs/store_path -e ST_PORT=23010 -e NGX_PORT=3010 -e GROUP_NAME=group10 -p 23010:23010 -p 3010:3010 192.168.188.77:5000/fastdfs storage
```



## 查看

```
docker ps
```



## 测试

### 进入容器

```
docker exec -it storage1 /bin/bash
```

### 测试

进入目录

```
cd /usr/bin
```

```
fdfs_upload_file /etc/fdfs/storage.conf /20171217185523127.png
```



