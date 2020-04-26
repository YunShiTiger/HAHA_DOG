# FTP

## 安装

```
yum install vsftpd -y 
```

### 设置开机启动

```
systemctl enable vsftpd
```

### 启动

```
systemctl restart vsftpd
```



## 配置

### 进入目录

```
vi /etc/vsftpd/vsftpd.conf
```

修改如下参数

主动模式

```
pasv_enable=NO     （passive模式关闭）
pasv_min_port=3000
pasv_max_port=4000
port_enable=YES    （active模式开启）
connect_from_port_20=YES  （即默认情况下，FTP PORT主动模式进行数据传输时使用20端口(ftp-data)。YES使用，NO不使用。）
```

被动模式

```
pasv_enable=YES
pasv_min_port=3000  
pasv_max_port=4000
```



```
anonymous_enable=NO
chroot_local_user=YES
allow_writeable_chroot=YES
pasv_address=www.susheyougou.club    //(公网 IP)
pasv_addr_resolve=YES
pasv_enable=YES
port_enable=YES
pasv_min_port=60000
pasv_max_port=62000
```

注:

```
1> active mode:   ftp -A 3.3.3.3   

active模式连接ftp server时一定要加-A

2> passive mode: 可以直接使用  ftp 3.3.3.3   也可以使用 ftp -p 3.3.3.3
```



### 创建FTP虚拟宿主帐户

```
mkdir /opt/ftp
```

```
useradd -d /opt/ftp/ryxx   -g  ftp -s /sbin/nologin  ryxx
```

```
passwd  ryxx
```

```
chown -R  ryxx /opt/ftp
```

```
chown -R 777 /opt/ftp
```

```
mkdir  /opt/ftp/ryxx/out2in
```

```
mkdir  /opt/ftp/ryxx/in2out
```

```
cd  /opt/ftp
```

```
chmod -R 777 *
```

## 重启设置开机启动

```
systemctl start vsftpd.service
```

```
systemctl enable vsftpd.service
```

## 测试

### 连接ftp服务器

```
ftp 192.168.159.130
```

后就进入ftp命令行

### 下载文件

#### get

格式：get [remote-file] [local-file]
将文件从远端主机中传送至本地主机中。
如要获取远程服务器上/usr/your/1.htm，则

```
get /usr/your/1.htm 1.htm
```

#### mget

格式：mget [remote-files]
从远端主机接收一批文件至本地主机。
如要获取服务器上/usr/your/下的所有文件，则

```
cd /usr/your/
```

```
mget *.*
```

### 上传文件

#### put

格式：put local-file [remote-file]
将本地一个文件传送至远端主机中。
如要把本地的1.htm传送到远端主机/usr/your,并改名为2.htm

```
put 1.htm /usr/your/2.htm 
```

#### mput

格式：mput local-files
将本地主机中一批文件传送至远端主机。
如要把本地当前目录下所有html文件上传到服务器/usr/your/ 下

```
cd /usr/your
```

```
mput *.htm
```



