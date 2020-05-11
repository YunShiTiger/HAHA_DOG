# MySql

## Master

### 1.创建pv

```
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mysql-master1-pv
spec:
  capacity:
    storage: 30G
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Recycle
  storageClassName: nfs
  nfs:
    server: 10.1.11.26
    path: /home/lhcz/mysql/master/master1/
```

```
kubectl apply -f mysql-master-pv.yml
```

### 2.创建pvc

```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mysql-master-data-mysql-master-0
spec:
  accessModes:
    - ReadWriteMany
  volumeName: mysql-master1-pv
  resources:
    requests:
      storage: 30G
  storageClassName: nfs
```

```
kubectl apply -f mysql-master-pvc.yml
```

### 3.创建master

```
apiVersion: apps/v1beta1
kind: StatefulSet
metadata:
  name: mysql-master
spec:
  serviceName: mysql-master-service
  replicas: 1
  template:
    metadata:
      labels:
        app: mysql-master
    spec:
      containers:
      - name: mysql-masterr
        image: registry.cn-qingdao.aliyuncs.com/caonima/mysql:master 
        ports:
        - containerPort: 3306
        env:
        - name: MYSQL_ROOT_PASSWORD
          value: "123456"
        - name: MYSQL_REPLICATION_USER
          value: "repl"
        - name: MYSQL_REPLICATION_PASSWORD
          value: "123456"
        volumeMounts:
          - name: mysql-master-data
            mountPath: /var/lib/mysql
  volumeClaimTemplates:
  - metadata:
      name: mysql-master-data
    spec: 
      accessModes: [ "ReadWriteMany" ]
      resources:
        requests:
          storage: 30G
---
apiVersion: v1
kind: Service
metadata:
  name: mysql-master
spec:
  selector:
    app: mysql-master
  type: NodePort
  ports:
  - nodePort: 31521
    port: 3306
    targetPort: 3306
```

```
kubectl apply -f mysql-master.yml
```



## Slave

### 1.创建pv

```
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mysql-slave1-pv
spec:
  capacity:
    storage: 30G
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Recycle
  storageClassName: nfs
  nfs:
    server: 10.1.11.26
    path: /home/lhcz/mysql/slave/slave1/

---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mysql-slave2-pv
spec:
  capacity:
    storage: 30G
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Recycle
  storageClassName: nfs
  nfs:
    server: 10.1.11.26
    path: /home/lhcz/mysql/slave/slave2/

---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mysql-slave3-pv
spec:
  capacity:
    storage: 30G
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Recycle
  storageClassName: nfs
  nfs:
    server: 10.1.11.26
    path: /home/lhcz/mysql/slave/slave3/
```

```
kubectl apply -f mysql-slave-pv.yml
```

### 2.创建pvc

```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mysql-slave-data-mysql-slave-0
spec:
  accessModes:
    - ReadWriteMany
  volumeName: mysql-slave1-pv
  resources:
    requests:
      storage: 30G
  storageClassName: nfs

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mysql-slave-data-mysql-slave-1
spec:
  accessModes:
    - ReadWriteMany
  volumeName: mysql-slave2-pv
  resources:
    requests:
      storage: 30G
  storageClassName: nfs

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mysql-slave-data-mysql-slave-2
spec:
  accessModes:
    - ReadWriteMany
  volumeName: mysql-slave3-pv
  resources:
    requests:
      storage: 30G
  storageClassName: nfs
```

```
kubectl apply -f mysql-slave-pvc.yml
```

### 3.创建slave

```
apiVersion: apps/v1beta1
kind: StatefulSet
metadata:
  name: mysql-slave
spec:
  serviceName: mysql-slave-service
  replicas: 1
  template:
    metadata:
      labels:
        app: mysql-slave
    spec:
      containers:
      - name: mysql-slave
        image: registry.cn-qingdao.aliyuncs.com/caonima/mysql:slave
        ports:
        - containerPort: 3306
        env:
        - name: MYSQL_ROOT_PASSWORD
          value: "123456"
        - name: MYSQL_REPLICATION_USER
          value: "repl"
        - name: MYSQL_REPLICATION_PASSWORD
          value: "123456"
        volumeMounts:
          - name: mysql-slave-data
            mountPath: /var/lib/mysql
  volumeClaimTemplates:
  - metadata:
      name: mysql-slave-data
    spec:
      accessModes: [ "ReadWriteMany" ]
      resources:
        requests:
          storage: 30G
---
apiVersion: v1
kind: Service
metadata:
  name: mysql-slave
spec:
  selector:
    app: mysql-slave
  type: NodePort
  ports:
  - nodePort: 32521
    port: 3306
    targetPort: 3306
```

```
kubectl apply -f mysql-slave.yml
```



## 创建集群

### 1.进入master容器

```
kubectl exec -it mysql-master-0 /bin/bash
```

#### 进入mysql

```
mysql -uroot -p
```

##### 执行命令

```
show master status;
```

##### 查看状态

```
+---------------------------+----------+--------------+------------------+-------------------+
| File                      | Position | Binlog_Do_DB | Binlog_Ignore_DB | Executed_Gtid_Set |
+---------------------------+----------+--------------+------------------+-------------------+
| mysql-master-0-bin.000003 |      154 |              |                  |                   |
+---------------------------+----------+--------------+------------------+-------------------+
1 row in set (0.00 sec)
```

#### 执行下面的命令创建数据库以及表，以测试数据同步：

```
create database paul_test_sync_db; use paul_test_sync_db; create table test_tb(id int(3),name char(10)); insert into test_tb values(001,'ok');
```

### 2.进入slave容器

 ```
kubectl exec -it mysql-slave-0 /bin/bash
 ```

#### 进入mysql

```
mysql -uroot -p
```

##### 执行命令

```
show slave status\G
```

##### 查看状态

```
*************************** 1. row ***************************
               Slave_IO_State: Waiting for master to send event
                  Master_Host: 10.99.168.137
                  Master_User: repl
                  Master_Port: 3306
                Connect_Retry: 60
              Master_Log_File: mysql-master-0-bin.000003
          Read_Master_Log_Pos: 852
               Relay_Log_File: mysql-slave-2-relay-bin.000005
                Relay_Log_Pos: 1083
        Relay_Master_Log_File: mysql-master-0-bin.000003
             Slave_IO_Running: Yes
            Slave_SQL_Running: Yes
              Replicate_Do_DB: 
          Replicate_Ignore_DB: 
           Replicate_Do_Table: 
       Replicate_Ignore_Table: 
      Replicate_Wild_Do_Table: 
  Replicate_Wild_Ignore_Table: 
                   Last_Errno: 0
                   Last_Error: 
                 Skip_Counter: 0
          Exec_Master_Log_Pos: 852
              Relay_Log_Space: 2997458
              Until_Condition: None
               Until_Log_File: 
                Until_Log_Pos: 0
           Master_SSL_Allowed: No
           Master_SSL_CA_File: 
           Master_SSL_CA_Path: 
              Master_SSL_Cert: 
            Master_SSL_Cipher: 
               Master_SSL_Key: 
        Seconds_Behind_Master: 0
Master_SSL_Verify_Server_Cert: No
                Last_IO_Errno: 0
                Last_IO_Error: 
               Last_SQL_Errno: 0
               Last_SQL_Error: 
  Replicate_Ignore_Server_Ids: 
             Master_Server_Id: 1
                  Master_UUID: 9d22f129-f462-11e8-815e-0a580af400dc
             Master_Info_File: /var/lib/mysql/master.info
                    SQL_Delay: 0
          SQL_Remaining_Delay: NULL
      Slave_SQL_Running_State: Slave has read all relay log; waiting for more updates
           Master_Retry_Count: 86400
                  Master_Bind: 
      Last_IO_Error_Timestamp: 
     Last_SQL_Error_Timestamp: 
               Master_SSL_Crl: 
           Master_SSL_Crlpath: 
           Retrieved_Gtid_Set: 
            Executed_Gtid_Set: 
                Auto_Position: 0
         Replicate_Rewrite_DB: 
                 Channel_Name: 
           Master_TLS_Version: 
1 row in set (0.00 sec)
```

### 3.测试

##### 执行以下命令，可以看到刚才在master上创建的库表已经同步过来了

```
show databases; use paul_test_sync_db; select * from test_tb; 
```









注:一个大目录只能有一个NFS系统

```
https://www.jianshu.com/p/509b65e9a4f5
```



## 最大连接数[configmap]

### master

```
vi mysql.cnf
```

```
# Copyright (c) 2014, 2016, Oracle and/or its affiliates. All rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301 USA

#
# The MySQL  Server configuration file.
#
# For explanations see
# http://dev.mysql.com/doc/mysql/en/server-system-variables.html

[mysqld]
server-id=1
log-bin
skip-host-cache
skip-name-resolve
pid-file	= /var/run/mysqld/mysqld.pid
socket		= /var/run/mysqld/mysqld.sock
datadir		= /var/lib/mysql
#log-error	= /var/log/mysql/error.log
# Disabling symbolic-links is recommended to prevent assorted security risks
symbolic-links=0
max_connections=10000
sql_mode=STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION
```

```
kubectl create configmap mysql-master-conf --from-file=mysqld.cnf
```

```
apiVersion: apps/v1beta1
kind: StatefulSet
metadata:
  name: mysql-master
spec:
  serviceName: mysql-master-service
  replicas: 1
  template:
    metadata:
      labels:
        app: mysql-master
    spec:
      containers:
      - name: mysql-masterr
        image: 192.168.240.73/fuck/mysql:master 
        ports:
        - containerPort: 3306
        env:
        - name: MYSQL_ROOT_PASSWORD
          value: "123456"
        - name: MYSQL_REPLICATION_USER
          value: "repl"
        - name: MYSQL_REPLICATION_PASSWORD
          value: "123456"
        - name: MAX_CONNECTIONS
          value: "10000"
        volumeMounts:
          - name: mysql-master-data
            mountPath: /var/lib/mysql
          - name: mysql-master-conf
            mountPath: /etc/mysql/mysql.conf.d/
      volumes:
      - name: mysql-master-conf
        configMap:
          name: mysql-master-conf
          items:
            - key: "mysqld.cnf"
              path: "mysqld.cnf"
  volumeClaimTemplates:
  - metadata:
      name: mysql-master-data
    spec: 
      accessModes: [ "ReadWriteMany" ]
      resources:
        requests:
          storage: 50G
---
apiVersion: v1
kind: Service
metadata:
  name: mysql-master
spec:
  selector:
    app: mysql-master
  type: NodePort
  ports:
  - nodePort: 30306
    port: 3306
    targetPort: 3306
```

### slave

```
vi mysql.cnf
```

```
# Copyright (c) 2014, 2016, Oracle and/or its affiliates. All rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301 USA

#
# The MySQL  Server configuration file.
#
# For explanations see
# http://dev.mysql.com/doc/mysql/en/server-system-variables.html

[mysqld]
server-id=06
log-bin
skip-host-cache
skip-name-resolve
pid-file        = /var/run/mysqld/mysqld.pid
socket          = /var/run/mysqld/mysqld.sock
datadir         = /var/lib/mysql
#log-error      = /var/log/mysql/error.log
# Disabling symbolic-links is recommended to prevent assorted security risks
symbolic-links=0
max_connections=10000
sql_mode=STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION
```

```
kubectl create configmap mysql-slave-conf --from-file=mysqld.cnf
```

```
apiVersion: apps/v1beta1
kind: StatefulSet
metadata:
  name: mysql-slave
spec:
  serviceName: mysql-slave-service
  replicas: 2
  template:
    metadata:
      labels:
        app: mysql-slave
    spec:
      containers:
      - name: mysql-slave
        image: 192.168.240.73/fuck/mysql:slave
        ports:
        - containerPort: 3306
        env:
        - name: MYSQL_ROOT_PASSWORD
          value: "123456"
        - name: MYSQL_REPLICATION_USER
          value: "repl"
        - name: MYSQL_REPLICATION_PASSWORD
          value: "123456"
        - name: MAX_CONNECTIONS
          value: "10000"
        volumeMounts:
          - name: mysql-slave-data
            mountPath: /var/lib/mysql
          - name: mysql-slave-conf
            mountPath: /etc/mysql/mysql.conf.d/
      volumes:
      - name: mysql-slave-conf
        configMap:
          name: mysql-slave-conf
          items:
            - key: "mysqld.cnf"
              path: "mysqld.cnf"
  volumeClaimTemplates:
  - metadata:
      name: mysql-slave-data
    spec: 
      accessModes: [ "ReadWriteMany" ]
      resources:
        requests:
          storage: 50G
---
apiVersion: v1
kind: Service
metadata:
  name: mysql-slave
spec:
  selector:
    app: mysql-slave
  type: NodePort
  ports:
  - nodePort: 30307
    port: 3306
    targetPort: 3306
```

### 查看

```
show variables like 'max_connections';
```



## 修改时区

### 修改

#### 在mysql-[master/slave].yaml部署模板中加入

```
        - name: MYSQL_ROOT_PASSWORD
          value: "123456"
        - name: MYSQL_REPLICATION_USER
          value: "repl"
        - name: MYSQL_REPLICATION_PASSWORD
          value: "123456"
        - name: TZ
          value: "Asia/Shanghai"
```

加入时区环境配置

### 检测

#### 系统

```
date
```

#### mysql

```
select sysdate();
```



## 备份

```
crontab -e
```

加入

```
30 23 * * * /root/kubernetes/mysql/bak/bak.sh
```

根据bak.sh创建备份目录

bak.sh内容

```
export KUBECONFIG=/etc/kubernetes/admin.conf
source ~/.bash_profile
###
kubectl exec -i mysql-master-0 /bin/bash << 'EOF'
time=`date "+%F"`
mysqldump -u root -p123456 --all-databases > /var/lib/mysql/MysqlBak/MysqlBak-$time.sql
find /var/lib/mysql/MysqlBak/ -name "*" -type f -mtime +7 -exec rm -rf {} \; > /dev/null 2>&1
exit
EOF
###
kubectl exec -i mysql-slave-0 /bin/bash << 'EOF'
time=`date "+%F"`
mysqldump -u root -p123456 --all-databases > /var/lib/mysql/MysqlBak/MysqlBak-$time.sql
find /var/lib/mysql/MysqlBak/ -name "*" -type f -mtime +7 -exec rm -rf {} \; > /dev/null 2>&1
exit
EOF
###
kubectl exec -i mysql-slave-1 /bin/bash << 'EOF'
time=`date "+%F"`
mysqldump -u root -p123456 --all-databases > /var/lib/mysql/MysqlBak/MysqlBak-$time.sql
find /var/lib/mysql/MysqlBak/ -name "*" -type f -mtime +7 -exec rm -rf {} \; > /dev/null 2>&1
exit
EOF
```



## 设置特定IP访问

### 查看MYSQL数据库中所有用户

```
SELECT DISTINCT CONCAT('User: ''',user,'''@''',host,''';') AS query FROM mysql.user;
```

```
如果有：
User: 'root'@'%';  表示所有IP都可以用root账号访问，需要把它删掉
```

### 删除账户及权限：

```
drop user root@'%';
```

### 赋予权限：

```
GRANT ALL ON *.* to root@'176.16.0.3' IDENTIFIED BY 'asdlkjCS123..'; 
```

```
FLUSH PRIVILEGES;
```

## 