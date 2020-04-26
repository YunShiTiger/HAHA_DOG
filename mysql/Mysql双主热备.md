# Mysql双主热备

## 下载

```
wget https://dev.mysql.com/get/Downloads/MySQL-5.7/mysql-5.7.27-1.el7.x86_64.rpm-bundle.tar
```

## 解压

```
tar xvf mysql-5.7.27-1.el7.x86_64.rpm-bundle.tar
```

## 按顺序安装

```
rpm -ivh mysql-community-common-5.7.27-1.el7.x86_64.rpm
rpm -ivh mysql-community-libs-5.7.27-1.el7.x86_64.rpm 
rpm -ivh mysql-community-client-5.7.27-1.el7.x86_64.rpm
rpm -ivh mysql-community-server-5.7.27-1.el7.x86_64.rpm
rpm -ivh mysql-community-devel-5.7.27-1.el7.x86_64.rpm
```

或者

```
rpm -ivh *.rpm
```

### 若出现

`error: Failed dependencies:
        mariadb-libs is obsoleted by mysql-community-libs-5.7.27-1.el7.x86_64
        mariadb-libs is obsoleted by mysql-community-libs-compat-5.7.27-1.el7.x86_64`

由于CentOS默认为MariaDB所以才会出现如上报错

#### 先卸载MariaDB

```
rpm -qa | grep mariadb
```

```
rpm -e mariadb-libs-5.5.64-1.el7.x86_64
```

##### 若由于依赖关系无法卸载则使用

```
rpm -e --nodeps mariadb-libs-5.5.64-1.el7.x86_64
```

## 启动

```
systemctl start mysqld
```

## 查看

```
systemctl status mysqld
```

## 设置开机启动

```
systemctl enable mysqld
```

## 查找初始密码

```
vi /var/log/mysqld.log
```

找到`root@localhost`后面就是密码

### 修改密码(不修改密码控制台输入命令会一直报错)

#### 改密码前需要先修改配置

```
set global validate_password_policy=0;

set global validate_password_length=4;
```

第一个是把验证规则去掉,第二条修改密码长度,如果不输第二条命令,默认长度为8以上

```
alter user 'root'@'localhost' identified by 'Admin0991';
```

## 重启

```
service mysqld restart
```

## 配置数据库配置文件

开始配置互备,修改配置文件,主要是设置id,其他是为了可能性的出错

```
vi /etc/my.cnf
```

### 节点A

```
[mysqld]
datadir=/var/lib/mysql
user=mysql
port = 3306
socket= /var/lib/mysql/mysql.sock
log-bin=mysql-bin
gtid-mode=on
enforce-gtid-consistency=true
master-info-repository=TABLE
relay-log-info-repository=TABLE
sync-master-info=1
slave-parallel-workers=2
binlog-checksum=CRC32
master-verify-checksum=1
slave-sql-verify-checksum=1
binlog-rows-query-log_events=1
report-port=3306
report-host=172.16.11.81
#replicate-same-server-id #主要用于同时写的情况
server_id=1      #从写 server_id = 2
log-slave-updates
slave-skip-errors=all
auto_increment_increment=2
auto_increment_offset=1     #从写 auto_increment_offset = 2
#skip-grant-tables
```

### 节点B

```
[mysqld]
datadir=/var/lib/mysql
user=mysql
port = 3306
socket= /var/lib/mysql/mysql.sock
log-bin=mysql-bin
gtid-mode=on
enforce-gtid-consistency=true
master-info-repository=TABLE
relay-log-info-repository=TABLE
sync-master-info=1
slave-parallel-workers=2
binlog-checksum=CRC32
master-verify-checksum=1
slave-sql-verify-checksum=1
binlog-rows-query-log_events=1
report-port=3306
report-host=172.16.11.82
#replicate-same-server-id #主要用于同时写的情况
server_id=2     
log-slave-updates
slave-skip-errors=all
auto_increment_increment=2
auto_increment_offset=2 
#skip-grant-tables
```

## 重启

```
service mysqld restart
```

查看状态

```
service mysqld status
```

## 配置集群

进入mysql

```
mysql -u root -p
```

### 节点A执行[复制账户]

```
grant replication slave on *.* to 'slave'@'172.16.11.82' identified by 'root';
```

```
show master status\G;
```

记录打印

```
*************************** 1. row ***************************
             File: mysql-bin.000002
         Position: 194
     Binlog_Do_DB: 
 Binlog_Ignore_DB: 
Executed_Gtid_Set: e6b38b41-df57-11e9-9a4a-fa163ed54c36:1
1 row in set (0.00 sec)

ERROR: 
No query specified
```

### 节点B执行[复制账户]

```
grant replication slave on *.* to 'slave'@'172.16.11.81' identified by 'root';
```

```
show master status\G;
```

记录打印

```
mysql> show master status\G;
*************************** 1. row ***************************
             File: mysql-bin.000002
         Position: 194
     Binlog_Do_DB: 
 Binlog_Ignore_DB: 
Executed_Gtid_Set: e8e4a4d9-df57-11e9-9c0c-fa163ef70f67:1
1 row in set (0.00 sec)

ERROR: 
No query specified
```

### 节点A执行[节点挂载]

```
change master  to master_host='172.16.11.82',master_user='slave',
master_password='root',master_log_file='mysql-bin.000005',
master_log_pos=743;
start slave;
show slave status\G;
```

### 节点B执行[节点挂载]

```
change master  to master_host='172.16.11.81',master_user='slave',
master_password='root',master_log_file='mysql-bin.000005',
master_log_pos=743;
start slave;
show slave status\G;
```

## 查看

```
show slave status\G;
```

```
Slave_IO_Running: Yes
Slave_SQL_Running: Yes
两项均为yes则没有问题
```



## 注:

### 1130 - Host '36.112.90.28' is not allowed to connect to this MySQL server

```
use mysql;
```

```
select host from user where user='root';
```

打印

```
mysql> select host from user where user='root';
+-----------+
| host      |
+-----------+
| localhost |
+-----------+
1 row in set (0.00 sec)
```

执行update user set host = '%' where user ='root'将Host设置为通配符%。

```
update user set host = '%' where user ='root';
```

```
mysql> select host from user where user='root';
+-----------+
| host      |
+-----------+
| localhost |
+-----------+
1 row in set (0.00 sec)
```

```
flush privileges;
```



### ERROR 1819 (HY000): Your password does not satisfy the current policy requirements

```
再次执行一下密码策略,前面的执行为重启还原(一次性策略)
```

