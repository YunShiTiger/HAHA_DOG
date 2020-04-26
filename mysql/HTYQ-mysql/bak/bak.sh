export KUBECONFIG=/etc/kubernetes/admin.conf
source ~/.bash_profile
###
kubectl exec -i mysql-master-0 /bin/bash << 'EOF'
time=`date "+%F"`
mysqldump -u root -pasdlkjcs123.. --all-databases > /var/lib/mysql/MysqlBak/MysqlBak-$time.sql
find /var/lib/mysql/MysqlBak/ -name "*" -type f -mtime +5 -exec rm -rf {} \; > /dev/null 2>&1
exit
EOF
###
kubectl exec -i mysql-slave-0 /bin/bash << 'EOF'
time=`date "+%F"`
mysqldump -u root -pasdlkjcs123.. --all-databases > /var/lib/mysql/MysqlBak/MysqlBak-$time.sql
find /var/lib/mysql/MysqlBak/ -name "*" -type f -mtime +5 -exec rm -rf {} \; > /dev/null 2>&1
exit
EOF
