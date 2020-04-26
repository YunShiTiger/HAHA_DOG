

# Cloudera-CDH6-Hadoop

## 配置主机网络名称

### 编辑hostname和hosts

### hostsname

```
vi /etc/hostname
```

改为

```
master.cdh.com
```

### hosts

```
vi /etc/hosts
```

加入

```
192.168.1.132 master.cdh.com

192.168.1.133 node.cdh.com
```

### 修改网络主机名

```
vi /etc/sysconfig/network
```

加入或改为

```
HOSTNAME=master.cdh.com
```

### 执行

```
hostname master.cdh.com
```

```
hostnamectl set-hostname master.cdh.com
```



## ssh免密登录

### 生成ssh密钥对并复制到各节点

```
ssh-keygen -t rsa
一路回车
```

### 将公钥添加到认证文件中 

```
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
```

### 设置权限

```
chmod 777 ~/.ssh/authorized_keys
```

### 复制公钥到各服务器

```
scp ~/.ssh/authorized_keys root@node.cdh.com:~/.ssh/
```





## 禁用防火墙

```
systemctl stop firewalld
systemctl disable firewalld
```



## 设置SELINUX

```
vi /etc/sysconfig/selinux
```

改为

```
# This file controls the state of SELinux on the system.
# SELINUX= can take one of these three values:
#     enforcing - SELinux security policy is enforced.
#     permissive - SELinux prints warnings instead of enforcing.
#     disabled - No SELinux policy is loaded.
SELINUX=permissive
# SELINUXTYPE= can take one of three two values:
#     targeted - Targeted processes are protected,
#     minimum - Modification of targeted policy. Only selected processes are protected.
#     mls - Multi Level Security protection.
SELINUXTYPE=targeted
```



## 安装NTP时间服务器

### 安装

```
yum install ntp -y
```

### 修改配置文件

```
vi /etc/ntp.conf
```

改为

#### 主节点

```
# For more information about this file, see the man pages
# ntp.conf(5), ntp_acc(5), ntp_auth(5), ntp_clock(5), ntp_misc(5), ntp_mon(5).

driftfile /var/lib/ntp/drift

# Permit time synchronization with our time source, but do not
# permit the source to query or modify the service on this system.
restrict default nomodify notrap nopeer noquery

# Permit all access over the loopback interface.  This could
# be tightened as well, but to do so would effect some of
# the administrative functions.
restrict 192.168.1.132 nomodify notrap nopeer noquery
restrict 127.0.0.1
restrict ::1

# Hosts on local network are less restricted.
#restrict 192.168.1.1 mask 255.255.255.0 nomodify notrap

# Use public servers from the pool.ntp.org project.
# Please consider joining the pool (http://www.pool.ntp.org/join.html).
server 127.127.1.0
Fudge 127.127.1.0 stratum 10

#broadcast 192.168.1.255 autokey        # broadcast server
#broadcastclient                        # broadcast client
#broadcast 224.0.1.1 autokey            # multicast server
#multicastclient 224.0.1.1              # multicast client
#manycastserver 239.255.254.254         # manycast server
#manycastclient 239.255.254.254 autokey # manycast client
```

#### 从节点

```
# For more information about this file, see the man pages
# ntp.conf(5), ntp_acc(5), ntp_auth(5), ntp_clock(5), ntp_misc(5), ntp_mon(5).

driftfile /var/lib/ntp/drift

# Permit time synchronization with our time source, but do not
# permit the source to query or modify the service on this system.
restrict default nomodify notrap nopeer noquery

# Permit all access over the loopback interface.  This could
# be tightened as well, but to do so would effect some of
# the administrative functions.
restrict 192.168.1.133 nomodify notrap nopeer noquery
restrict 127.0.0.1
restrict ::1

# Hosts on local network are less restricted.
#restrict 192.168.1.1 mask 255.255.255.0 nomodify notrap

# Use public servers from the pool.ntp.org project.
# Please consider joining the pool (http://www.pool.ntp.org/join.html).
server 192.168.1.132
Fudge 192.168.1.132 stratum 10

#broadcast 192.168.1.255 autokey        # broadcast server
#broadcastclient                        # broadcast client
#broadcast 224.0.1.1 autokey            # multicast server
#multicastclient 224.0.1.1              # multicast client
#manycastserver 239.255.254.254         # manycast server
#manycastclient 239.255.254.254 autokey # manycast client
```

### 重启并设置开机自启

```
systemctl restart ntpd
systemctl enable ntpd
```

### 同步系统时钟

```
hwclock --systohc
```

### 注:

```
https://www.cnblogs.com/quchunhui/p/7658853.html
```



## 配置yum源

### 下载

```
sudo wget https://archive.cloudera.com/cm6/6.1.0/redhat7/yum/cloudera-manager.repo -P /etc/yum.repos.d/
```

### 加入签名秘钥

```
rpm --import https://archive.cloudera.com/cm6/6.1.0/redhat7/yum/RPM-GPG-KEY-cloudera
```



## 安装JDK

### 卸载之前版本JDK

```
rpm -qa|grep java
rpm -qa|grep jdk
yum remove java -y
```

### 安装OracleJDK

```
yum install oracle-j2sdk1.8 -y
```



## 安装Cloudera Manager

### 安装

```
yum install cloudera-manager-server -y
```



### 启用Auto-TLS

```
JAVA_HOME=/usr/java/jdk1.8.0_141-cloudera /opt/cloudera/cm-agent/bin/certmanager setup --configure-services
```

```
JAVA_HOME=/usr/java/jdk1.8.0_141-cloudera /opt/cloudera/cm-agent/bin/certmanager --location /opt/cloudera/CMCA setup --configure-services
```



## mysql数据库

### 安装

```
wget http://repo.mysql.com/mysql-community-release-el7-5.noarch.rpm
```

```
rpm -ivh mysql-community-release-el7-5.noarch.rpm
```

```
yum install mysql-server -y
```

### 停止服务配置mysql

```
systemctl stop mysqld
```

#### 备份文件

```
/var/lib/mysql/ib_logfile0
/var/lib/mysql/ib_logfile1
/etc/my.cnf
```

#### 修改配置文件

```
vi /etc/my.cnf
```

改为

```
[mysqld]
datadir=/var/lib/mysql
socket=/var/lib/mysql/mysql.sock
transaction-isolation = READ-COMMITTED
# Disabling symbolic-links is recommended to prevent assorted security risks;
# to do so, uncomment this line:
symbolic-links = 0

key_buffer_size = 32M
max_allowed_packet = 32M
thread_stack = 256K
thread_cache_size = 64
query_cache_limit = 8M
query_cache_size = 64M
query_cache_type = 1

max_connections = 550
#expire_logs_days = 10
#max_binlog_size = 100M

#log_bin should be on a disk with enough free space.
#Replace '/var/lib/mysql/mysql_binary_log' with an appropriate path for your
#system and chown the specified folder to the mysql user.
log_bin=/var/lib/mysql/mysql_binary_log

#In later versions of MySQL, if you enable the binary log and do not set
#a server_id, MySQL will not start. The server_id must be unique within
#the replicating group.
server_id=1

binlog_format = mixed

read_buffer_size = 2M
read_rnd_buffer_size = 16M
sort_buffer_size = 8M
join_buffer_size = 8M

# InnoDB settings
innodb_file_per_table = 1
innodb_flush_log_at_trx_commit  = 2
innodb_log_buffer_size = 64M
innodb_buffer_pool_size = 4G
innodb_thread_concurrency = 8
innodb_flush_method = O_DIRECT
innodb_log_file_size = 512M

[mysqld_safe]
log-error=/var/log/mysqld.log
pid-file=/var/run/mysqld/mysqld.pid

sql_mode=STRICT_ALL_TABLES
```

### 重启mysql并添加开机自启

```
systemctl enable mysqld
systemctl restart mysqld
```

### 设置数据库

```
/usr/bin/mysql_secure_installation
```

按照下述输入

```
[...]
Enter current password for root (enter for none):
OK, successfully used password, moving on...
[...]
Set root password? [Y/n] Y
New password:
Re-enter new password:
Remove anonymous users? [Y/n] Y
[...]
Disallow root login remotely? [Y/n] N
[...]
Remove test database and access to it [Y/n] Y
[...]
Reload privilege tables now? [Y/n] Y
All done!
```

### 安装mysql的JDBC驱动

```
wget https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.46.tar.gz
```

```
tar zxvf mysql-connector-java-5.1.46.tar.gz
```

```
mkdir -p /usr/share/java/
```

```
cd mysql-connector-java-5.1.46
```

```
cp mysql-connector-java-5.1.46-bin.jar /usr/share/java/mysql-connector-java.jar
```

### 创建Cloudera相关数据库

```
mysql -u root -p
```

```
CREATE DATABASE scm DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
CREATE DATABASE amon DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
CREATE DATABASE rman DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
CREATE DATABASE hue DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
CREATE DATABASE metastore DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
CREATE DATABASE sentry DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
CREATE DATABASE nav DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
CREATE DATABASE navms DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
CREATE DATABASE oozie DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
CREATE DATABASE reportsm DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
CREATE DATABASE activitym DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
```

```
grant all on *.* to 'root'@'%' identified by '123123' with grant option;
```

```
GRANT ALL ON scm.* TO 'scm'@'%' IDENTIFIED BY '123123';
GRANT ALL ON amon.* TO 'amon'@'%' IDENTIFIED BY '123123';
GRANT ALL ON rman.* TO 'rman'@'%' IDENTIFIED BY '123123';
GRANT ALL ON hue.* TO 'hue'@'%' IDENTIFIED BY '123123';
GRANT ALL ON metastore.* TO 'metastore'@'%' IDENTIFIED BY '123123';
GRANT ALL ON sentry.* TO 'sentry'@'%' IDENTIFIED BY '123123';
GRANT ALL ON nav.* TO 'nav'@'%' IDENTIFIED BY '123123';
GRANT ALL ON navms.* TO 'navms'@'%' IDENTIFIED BY '123123';
GRANT ALL ON oozie.* TO 'oozie'@'%' IDENTIFIED BY '123123';
GRANT ALL ON reportsm.* TO 'reportsm'@'%' IDENTIFIED BY '123123';
GRANT ALL ON activitym.* TO 'activitym'@'%' IDENTIFIED BY '123123';
```

### 设置Cloudera Manager相关数据库

```
/opt/cloudera/cm/schema/scm_prepare_database.sh mysql scm scm 123123

or

/opt/cloudera/cm/schema/scm_prepare_database.sh mysql -h master.cdh.com --scm-host master.cdh.com scm scm 123123
```

输出类似

```
JAVA_HOME=/usr/java/jdk1.8.0_141-cloudera
Verifying that we can write to /etc/cloudera-scm-server
Creating SCM configuration file in /etc/cloudera-scm-server
Executing:  /usr/java/jdk1.8.0_141-cloudera/bin/java -cp /usr/share/java/mysql-connector-java.jar:/usr/share/java/oracle-connector-java.jar:/usr/share/java/postgresql-connector-java.jar:/opt/cloudera/cm/schema/../lib/* com.cloudera.enterprise.dbutil.DbCommandExecutor /etc/cloudera-scm-server/db.properties com.cloudera.cmf.db.
[                          main] DbCommandExecutor              INFO  Successfully connected to database.
All done, your SCM database is configured correctly!
```



## 安装CDH

### 启动Cloudera Manager

```
systemctl start cloudera-scm-server
```

#### 日志查看

```
tail -f /var/log/cloudera-scm-server/cloudera-scm-server.log
```

#### 进入Web界面

```
https://192.168.1.132:7183
```

##### 用户名

```
admin
```

##### 密码

```
admin
```

### 导入安装包

#### 进入路径

```
cd /opt/cloudera/parcel-repo
```

#### 下载安装包链接

```
https://archive.cloudera.com/cdh6/6.1.0/parcels/
```

```
wget https://archive.cloudera.com/cdh6/6.1.0/parcels/CDH-6.1.0-1.cdh6.1.0.p0.770702-el7.parcel
```

```
wget https://archive.cloudera.com/cdh6/6.1.0/parcels/CDH-6.1.0-1.cdh6.1.0.p0.770702-el7.parcel.sha256
```

```
wget https://archive.cloudera.com/cdh6/6.1.0/parcels/manifest.json
```

#### 将sha256重新命名为sha

不然导入/下载的安装包则白下

```
mv CDH-6.1.0-1.cdh6.1.0.p0.770702-el7.parcel.sha256 CDH-6.1.0-1.cdh6.1.0.p0.770702-el7.parcel.sha
```





## 卸载

```
service cloudera-scm-agent stop
```

```
service supervisord stop
```

```
systemctl stop cloudera-scm-server
```

```
yum remove cloudera-manager-daemons cloudera-manager-agent cloudera-manager-server -y
```

```
rm -rf /opt/cloudera/*
```

```
#数据库部分
drop database scm;
```







```
Sudo –u hdfs Hadoop fs –ls /路径 ---显示hdfs中的目录/文件。
Sudo –u hdfs Hadoop fs –cat /路径 ---显示hdfs中的文件内容。
Sudo –u hdfs Hadoop fs –mkdir /路径 ---在hdfs中创建目录。
Sudo –u hdfs Hadoop fs –rmr /路径 ---删除hdfs中的内容。
Sudo –u hdfs Hadoop fs –mv /路径 ---移动（剪切）hdfs中的文件。
Sudo –u hdfs Hadoop fs –lsr /   ---查看hdfs的回收站内容。
Sudo –u hdfs Hadoop fs –put /本地路径 /hdfs路径 ---向hdfs中上传文件。
Sudo –u hdfs Hadoop fs –get /hdfs路径 /本地路径 ---从hdfs中获取文件。
Sudo –u hdfs Hadoop fs –getmerge /hdfs路径 /本地路径 ---从hdfs中打包获取文件。
Sudo –u hdfs Hadoop jar jar包名.jar package名.函数名 /路径 /路径 ---执行jar包进行MapReduce程序。

```

