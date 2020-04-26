# Mysql主从集群-数据同步

## 进入数据库

```
mysql -uroot -p123456
```

## 在master进行锁表

```
flush  tables  with  read  lock;
```

注意：该处是锁定为只读状态，语句不区分大小写

## 进行数据备份

```
mysqldump -uroot -p123456 -hlocalhost  --all-databases > /var/lib/mysql/MysqlBak/MysqlBak-2019-07-25.sql 
```

命令行操作而非数据库命令行

（--all-databases表示所有数据库）

## 查看master状态

```
show master status;
```

## 把mysql备份文件传到从库机器,进行数据恢复

```
scp mysql.sql root@10.6.97.134:/tmp/
```

## 停止从库的状态，导入数据备份

```
stop slave;
```

```
source /var/lib/mysql/MysqlBak/MysqlBak-2019-07-24.sql
```

## 设置从库同步,并开启slave

```
change master to master_host = '192.168.100.11',MASTER_PORT = 30007, master_user =  'repl',master_password='123456', master_log_file = 'mysql-master-0-bin.000007',  master_log_pos= 154;
```

```
start slave;
```

```
show slave status\G;
```

## 在master上解锁

```
unlock tables;
```



## 若在slave上出现error

Got fatal error 1236 from master when reading data from binary log: 'Could not find first log file name in binary log index file'

### 停止slave服务

```
stop slave;
```

### 进入master清空日志

```
flush logs;
```

### 查看master状态

```
show master status;
```

记录下File和Position

### 在slave同步

```
CHANGE MASTER TO MASTER_LOG_FILE='mysql-master-0-bin.000012',MASTER_LOG_POS=154;
```

### 开启slave服务

```
start slave;
```

### 查看状态

```
show slave status\G;
```

查看IO和SQL

```
Slave_IO_Running: Yes
Slave_SQL_Running: Yes
```







