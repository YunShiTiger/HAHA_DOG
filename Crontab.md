# Crontab(mysql数据备份)

## 安装

### 配置阿里源

```
tee /etc/apt/xiaojb.list <<-'EOF'
deb-src http://archive.ubuntu.com/ubuntu xenial main restricted #Added by software-properties
deb http://mirrors.aliyun.com/ubuntu/ xenial main restricted
deb-src http://mirrors.aliyun.com/ubuntu/ xenial main restricted multiverse universe #Added by software-properties
deb http://mirrors.aliyun.com/ubuntu/ xenial-updates main restricted
deb-src http://mirrors.aliyun.com/ubuntu/ xenial-updates main restricted multiverse universe #Added by software-properties
deb http://mirrors.aliyun.com/ubuntu/ xenial universe
deb http://mirrors.aliyun.com/ubuntu/ xenial-updates universe
deb http://mirrors.aliyun.com/ubuntu/ xenial multiverse
deb http://mirrors.aliyun.com/ubuntu/ xenial-updates multiverse
deb http://mirrors.aliyun.com/ubuntu/ xenial-backports main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ xenial-backports main restricted universe multiverse #Added by software-properties
deb http://archive.canonical.com/ubuntu xenial partner
deb-src http://archive.canonical.com/ubuntu xenial partner
deb http://mirrors.aliyun.com/ubuntu/ xenial-security main restricted
deb-src http://mirrors.aliyun.com/ubuntu/ xenial-security main restricted multiverse universe #Added by software-properties
deb http://mirrors.aliyun.com/ubuntu/ xenial-security universe
deb http://mirrors.aliyun.com/ubuntu/ xenial-security multiverse
EOF
```

```
apt get update
```

### 安装crontab

```
apt-get install cron
```

```
service cron restart
```



## 配置脚本

### 配置

```
tee /home/hn_cb-bak.sh <<-'EOF'
# Name:test_database_backup.sh
# This is a ShellScript For Auto DB Backup and Delete old Backup
#备份地址
backupdir=/var/lib/mysql/
#备份文件后缀时间
time=_` date +%Y_%m_%d_%H_%M_%S `
#需要备份的数据库名称
db_name=HN_CB
#mysql 用户名
db_user=root
#mysql 密码
db_pass=123456
#mysqldump命令使用绝对路径
/home/server/mysql-5.6.21/bin/mysqldump -u root -p 123456 $db_name | gzip > $backupdir/$db_name$time.sql.gz
#删除10天之前的备份文件
find $backupdir -name $db_name"*.sql.gz" -type f -mtime +10 -exec rm -rf {} \; > /dev/null 2>&1
EOF
```



容器数据备份

```
docker exec -i mysql /bin/bash << 'EOF'
time=`date "+%F"`
mysqldump -u root -p123456 --all-databases > /var/lib/mysql/MysqlBak-$time.sql
exit
EOF
docker cp mysql:/var/lib/mysql/MysqlBak-$(date "+%F").sql /home/jb/MysqlBak-$(date "+%F").sql
#find /home -name $(date "+%:F") -type f -mtime +5 -exec rm -rf {} \; > /dev/null 2>&1
find /home/jb/ -name "*" -type f -mtime +7 -exec rm -rf {} \; > /dev/null 2>&1
```



k8s

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



### 设定

```
crontab -e
```

加入

```
14 8 * * * /home/hn_cb-bak.sh
```



#### 时间说明

```
* * * * *                  # 每隔一分钟执行一次任务  
0 * * * *                  # 每小时的0点执行一次任务，比如6:00，10:00  
6,10 * 2 * *               # 每个月2号，每小时的6分和10分执行一次任务  
*/3,*/5 * * * *            # 每隔3分钟或5分钟执行一次任务，比如10:03，10:05，10:06 
前5个部分分别代表：分钟，小时，天，月，星期，每个部分的取值范围如下：
分钟	0 - 59
小时	0 - 23
天	1 - 31
月	1 - 12
星期	0 - 6    (0表示星期天)

举例如下：
00 21 * * * /var/lib/mysqlbackup/dbbackup.sh 若每天晚上21点00备份
5  *  *  *  *  每小时的第5分钟执行一次ls命令
30 5  *  *  *  天的 5:30 执行ls命令
30 7  8  *  *  指定每月8号的7：30分执行ls命令
30 5  8  6  *  指定每年的6月8日5：30执行ls命令
30 6  *  *  0  指定每星期日的6:30执行ls命令[注：0表示星期天，1表示星期1
```

