# Docker

## 基本命令

### 1).安装

#### (1).卸载

```
yum remove docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine
```

#### (2).安装yum-utils(可选)

```
yum install -y yum-utils \
  device-mapper-persistent-data \
  lvm2
```

#### (3).添加yum源

```
yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
```

#### (4).安装

```
yum install docker-ce-18.06.2.ce-3.el7 docker-ce-cli-1:18.09.2-3.el7 containerd.io
```

### 2).获取镜像

```
docker pull node ---获取node镜像
docker search node ---查询node相关镜像
```

### 3).获取镜像列表

```
docker ps ---查询运行中的镜像
docker ps -a ---查询所有镜像
```

### 4).通过镜像启动容器

```
docker run -dt --name demo node
注：d---不占用控制台 -t---使用控制台 --name---容器名字 最后为镜像类型
在镜像类型后面还可以再加上命令

docker run -d --name jenkins \
    --privileged \
    -p 8000:8080 \
    -p 10000:10000 \
    -p 50000:50000 \
    -v /opt/jenkins_data:/var/jenkins_home \
    -v /usr/bin/docker:/usr/bin/docker \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v /usr/lib64/libltdl.so.7:/usr/lib/x86_64-linux-gnu/libltdl.so.7 \
    jenkins/jenkins:2.72
注：privileged给予容器内root最高权限 -p将容器端口与主机做映射 -v磁盘挂载

在容器中可能无法使用“service XXX start”
报这个错的原因是dbus-daemon没能启动。systemctl并不是不能使用。将CMD或者entrypoint设置为/usr/sbin/init即可。docker容器会自动将dbus等服务启动起来。如下：
docker run --privileged--name test  XXXXXXXXXXXXXXXXX /usr/sbin/init
加一个 /usr/sbin/init

```

### 5).启动、关闭容器

```
docker start 容器
docker stop 容器
docker restart 容器
```

### 6).进入容器

```
docker exec -it 容器名 /bin/bash
注：-it参数表示具有交互模式
exit ---退出容器
```

### 7).删除容器

```
docker rm 容器名
或
docker rm 容器ID
```

### 8).删除镜像

```
docker rmi 镜像名
或
docker rmi 镜像ID
```

### 9).将容器保存成镜像

```
docker commit 容器名 保存名
```

### 10).镜像的导入导出

```
docker import cloudera-quickstart-vm-5.13.0-0-beta-docker tar cloudera ---镜像的导入(1)
docker load -i 镜像.tar ---镜像的导入(2)
docker save -o 镜像名.tar 镜像名 ---镜像的导出
注：镜像名可更改
```

### 11).容器与主机导入导出

```
docker cp /www/runoob 容器ID/容器名:容器内路径 ---向容器内导入
docker cp 容器ID/容器名:容器内路径 /www/runoob ---从容器内导出
```

### 12).查看容器日志

```
docker logs 容器名 --- 查看容器日志
```

### 13).显示容器IP

```
docker inspect --format='{{.Name}} - {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps -aq)
```

### 14).docker网络

创建新的docker网络模式

```
docker network create --subnet=172.18.0.0/16 oracle-network
```

查看

```
docker network ls
```

使用

```
docker run -dt --name ZZZ --net oracle-network --ip 172.18.0.2 -p 8888:8080 oracle:helowin
```

### 15).docker更换阿里镜像加速器

```
tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://tsqluof3.mirror.aliyuncs.com"]
}
EOF
```

### 16).登录DockerHub(阿里云)

```
docker login --username=hatchin666 registry.cn-qingdao.aliyuncs.com

密码:zxc11011
```

#### 推送镜像

````
docker push registry.cn-qingdao.aliyuncs.com/fuck-k8s/alpine:1.0
````

### 17).docker查看容器/镜像元信息

```
docker inspect 容器/镜像
```



## DockerFile

### 例:

```
FROM jenkins/jenkins:2.72
#↑继承之前的jenkins镜像，基于之前jenkins镜像再进行丰富
# Install docker
USER root
RUN curl -sSL https://get.docker.com/ | sh

# Install maven
ENV MAVEN_VERSION 3.5.0
RUN curl -fsSLo m.tgz http://apache.fayea.com/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz && \
    tar -xvzf m.tgz && \
    mv apache-maven-${MAVEN_VERSION} /var/maven && \
    rm m.tgz
#↑用“&&”并 + “\“换行 把命令连起来
#在docker build 中 每执行一次run都会创建一个层
ENV PATH /var/maven/bin:$PATH

# Install jenkins plugin
RUN /usr/local/bin/install-plugins.sh \
  git \
  workflow-aggregator 
```

### NodeJS环境的DockerFile 

```
FROM ubuntu

# install nodejs
USER root

RUN apt-get update &&\ 
    apt-get install gcc -y &&\ 
    apt-get install g++ -y &&\
    apt-get install make -y &&\
    apt-get install python -y 
    
RUN apt-get install wget -y &&\
    wget https://npm.taobao.org/mirrors/node/v8.9.3/node-v8.9.3.tar.gz

RUN tar -zxvf node-v8.9.3.tar.gz &&\
    cd node-v8.9.3 &&\
    ./configure &&\
    make &&\
    make install

RUN npm install -g pm2
```

### 运行springboot所用的DockerFile

```
FROM registry.cn-qingdao.aliyuncs.com/caonima/java:8-jre-alpine 
VOLUME /tmp 
ADD excel-0.0.1-SNAPSHOT.jar  excel-0.0.1-SNAPSHOT.jar
RUN sh -c 'touch /excel-0.0.1-SNAPSHOT.jar'
ENTRYPOINT [ "sh", "-c", "java -jar /excel-0.0.1-SNAPSHOT.jar" ] 
```

### 构建命令

`docker build -t 名儿:TAG .`

### 参数详解

```
http://www.dockerinfo.net/695.html
```

### build大全

```
http://www.runoob.com/docker/docker-build-command.html
```

## 镜像究极操作

### 1).查看docker磁盘使用情况

#### (1).linux

```
du -hs /var/lib/docker/ 
```

#### (2).docker

```
docker system df
```

### 2).停止/删除全部容器

#### (1).停止全部容器

```
docker stop $(docker ps -a -q)
```

#### (2).删除全部容器(先停止后删除)

```
docker rm $(docker ps -a -q)
```

### 3).删除images

#### (1).删除untagged images(id为<None>的image)

```
docker rmi $(docker images | grep "^<none>" | awk "{print $3}")
```

#### (2).删除全部image

```
docker rmi $(docker images -q)
```

### 4).清理磁盘

#### (1).清理磁盘,删除关闭的容器,无用的数据卷和网络,无tag的镜像

```
docker system prune
```

##### 进阶清理——(没有容器使用Docker镜像都删掉)

```
docker system prune -a
```

注:这两个命令会把你暂时关闭的容器，以及暂时没有用到的Docker镜像都删掉了…所以使用之前一定要想清楚.。我没用过，因为会清理 没有开启的  Docker 镜像。

### 5).迁移 /var/lib/docker 目录。

#### (1).停止docker服务

```
systemctl stop docker
```

#### (2).创建新的docker目录，执行命令`df -h`,找到一个大磁盘创建目录

```
mkdir -p /home/docker/lib
```

#### (3).迁移/var/lib/docker目录下面的文件到 /home/docker/lib：

```
rsync -avz /var/lib/docker /home/docker/lib/
```

#### (4).`/etc/systemd/system/docker.service.d/devicemapper.conf`——进行配置

查看 devicemapper.conf 是否存在。如果不存在，就新建。

```
sudo mkdir -p /etc/systemd/system/docker.service.d/
```

```
sudo vi /etc/systemd/system/docker.service.d/devicemapper.conf
```

#### (5).然后在 `devicemapper.conf `中写入（同步的时候把父文件夹一并同步过来，实际上的目录应在 /home/docker/lib/docker ）

```
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd  --graph=/home/docker/lib/docker
```

#### (6).重新加载 docker

```
systemctl daemon-reload
systemctl restart docker
systemctl enable docker
```

#### (7).为了确认一切顺利，运行

```
# docker info
```

检查Docker 的根目录是否被更改为 `/home/docker/lib/docker`

```
...
Docker Root Dir: /home/docker/lib/docker
Debug Mode (client): false
Debug Mode (server): false
Registry: https://index.docker.io/v1/
...
```

#### (8).启动成功后，确认之前的镜像是否存在

```
docker images
```

#### (9).确定容器没问题后删除`/var/lib/docker/`目录中的文件。

### 6).修改cgroup

```
vi /etc/docker/daemon.json
```

加入

```
{
  "exec-opts": ["native.cgroupdriver=systemd"]
}
```

#### 重启docker

```
systemctl restart docker
```

#### 查看

```
docker info | grep Cgroup
```

打印

```
Cgroup Driver: systemd
```

### 7).kubernetes与docker的cgroup

```
https://www.cnblogs.com/hongdada/p/9771857.html
```

# Jenkins

### 1).安装

#### ※docker 安装

通过docker pull或load的镜像构建容器创建jenkins

```
docker run -d --name jenkins \
    --privileged \
    -p 8000:8080 \
    -p 10000:10000 \
    -p 50000:50000 \
    -v /opt/jenkins_data:/var/jenkins_home \
    jenkins/jenkins:2.72
注：privileged给予容器内root最高权限 -p将容器端口与主机做映射 -v磁盘挂载(前面本地，后面容器) --restart unless-stopped(随机器启动)


docker run -d --name jenkins \
    --privileged \
    --restart unless-stopped \
    -p 8000:8080 \
    -p 10000:10000 \
    -p 50000:50000 \
    -v /home/aaa/jenkins:/var/jenkins_home \
    jenkins/jenkins:lts

```

#### ※yum 安装

##### (1).下载yum源

```
wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
```

```
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
```

##### (2).安装

```
yum install jenkins
```

或者直接下一个 不用更新源在源内个目录里

##### (3).安装jdk

```
export JAVA_HOME=/usr/lib/jdk1.8.0_181
export PATH=${JAVA_HOME}/bin:${PATH}
export MAVEN_HOME=/usr/lib/apache-maven-3.5.4
export PATH=${MAVEN_HOME}/bin:${PATH}
```

配置好jdk 后进行关联

```
 vim /etc/init.d/jenkins
```

```
candidates="
/opt/soft/jdk1.8.0_60/bin/java
/etc/alternatives/java
/usr/lib/jvm/java-1.6.0/bin/java
/usr/lib/jvm/jre-1.6.0/bin/java
/usr/lib/jvm/java-1.7.0/bin/java
/usr/lib/jvm/jre-1.7.0/bin/java
/usr/lib/jvm/java-1.8.0/bin/java
/usr/lib/jvm/jre-1.8.0/bin/java
/usr/bin/java
"
```

##### (4).修改启动端口和运行用户

````
vi /etc/sysconfig/jenkins
````

```
JENKINS_USER="root"
JENKINS_PORT="9999"
```

##### (5).编辑/etc/profiles文件添加jenkins的环境变量

```
export JENKINS_HOME=/var/lib/jenkins/
```

```
source /etc/profile
```

##### (6).启动jenkins

#### 注:

插件安装

```
vim /root/.jenkins/hudson.model.UpdateCenter.xml 将下面一行换成下面所示就行

 <url>https://mirrors.tuna.tsinghua.edu.cn/jenkins/updates/update-center.json</url>

就好了(war包安装方式选择)
```

或者

```
安装插件那个页面，就是提示你offline的那个页面，不要动。然后打开一个新的tab，输入网址http://localhost:8080/pluginManager/advanced。 这里面最底下有个【升级站点】，把其中的链接改成http的就好了，http://updates.jenkins.io/update-center.json。 然后在服务列表中关闭jenkins，再启动，这样就能正常联网了。*
```



### 2).解锁jenkins

网址输入 <主机IP:9999>进入jenkins页面

#### docker解锁密码为

```
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

#### yum解锁密码为

```
/var/lib/jenkins/secrets/initialAdminPassword
```

将打印出的密码填入网页

### 3).选择插件

### 4).Jenkins挂载远程服务器

```
jenkins页面→系统管理→系统设置→Publish over SSH
选择"SSH Servers"→"添加"
输入"服务器名称" "IP" "服务器中的用户名" "远程工作目录" 点击"高级"输入"服务器中的用户名密码"
保存
```

### 5).Jenkins挂载节点

#### (1).jenkins安装ssh插件

```
jenkins页面→系统管理→管理插件
```

#### (2).子节点安装ssh服务

```
apt-get install ssh -y
```

#### (3).修改子节点ssh服务配置文件

```
vi /etc/ssh/sshd_config
```

注释

```
PermitRootLogin prohibit-password
```

添加

```
PermitRootLogin yes
```

重启ssh服务

```
service ssh restart
```

#### (4).子节点安装jdk

#### (5).修改容器root密码

```
passwd root
```

#### (6).用jenkins节点的ssh服务连接子节点

```
用jenkins节点的ssh服务连接子节点
```

#### (7).在jenkins页面中添加节点

```
jenkins页面→系统管理→管理节点→新建节点
选择"固定代理" "OK"
添加"名字"
添加"远程工作目录"---一个目录(不是webapps)
添加"标签"---用户jenkins pipeline部署时的节点选择
选择启动方式为"Launch slave agents via SSH"
输入主机IP
点击"钥匙ADD"添加子节点中的用户名密码用于登录
选择"Non verify verification strategy"
点击"高级"设置子节点中的java路径"/jdk.1.8.0_161/bin/java"
保存

```

### 6).挂载kubernetes

#### (1).点击`系统管理` →`管理插件` →`可选插件` →`Kubernetes`     -----安装插件

#### (2).点击`系统管理`→`系统设置`

#### (3).点击`新增一个云`选择`kubernetes`

#### (4).添加参数

##### 1).如果jenkins on kubernetes

随便填填就可以了

##### 2).jenkins not on kubernetes

###### ①`Name`

```
随便填
```

###### ②`Kubernetes URL`

```
https://10.1.11.26:6443  
--- Kubernetes API地址:端口
```

###### ③`Kubernetes server certificate key`

将`cat /etc/kubernetes/pki/ca.crt`内容贴进去

```
-----BEGIN CERTIFICATE-----
MIICyDCCAbCgAwIBAgIBADANBgkqhkiG9w0BAQsFADAVMRMwEQYDVQQDEwprdWJl
cm5ldGVzMB4XDTE4MDcyNTExNTEwOVoXDTI4MDcyMjExNTEwOVowFTETMBEGA1UE
AxMKa3ViZXJuZXRlczCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBANb7
4S3URvpVBOjHirzs7exU+3AktuCwpqkOKY2nzddwajiw5xLTv5n5ahLht2KDeyR2
8yuHmhUmFhXcF5rrAf2kDe9cUaiAVbQ6aaiMmm8M/jfJqeRxL4IJvf6TW82YZBdv
IBaYF4ZO7gGqbQlkRRzSnbOdmUkmWDGcK6zvFP7NUDboIfg1M2U0C2SNicdZgiZz
ia8qUwAgRHdC9v9eNLnPrzyzBOrjMTSQwpqdchGe8udYhnHy5xDdMP8g14MfeymK
iLQxEURcExkmpA/gFdWb1rR6CSd4YgV1/kdkReEeo7kdzXZgMDwLZ1XfspnJZwSa
fjggtb/VmxWZt6U2n2cCAwEAAaMjMCEwDgYDVR0PAQH/BAQDAgKkMA8GA1UdEwEB
/wQFMAMBAf8wDQYJKoZIhvcNAQELBQADggEBALYM/5HOYiqd8WKgFRTJ2+kwpB8g
SIYW783COoc13ca3O9OxgUkaNfrO6XLIO8pwGACSoyUXIc67NzNAggO55CW2dWVr
+vh47qI3tQikrB55OdCcbSWmTwCQ5n245HXXzgt6dj7loTNSxpKqiCt16KIQbNhU
RRSpFIVNFiMfdMEo0akIQO+izPpNJFATVlTPnDGc+vavLqLxEOFxH2bAqt3nywof
iOER8N+DVTeF4havkypn2+ZHl1hlczVQOpeowwKr3Sbk4RpyJHLkNKftOJlVVf+w
gx/j0gWj46j63gp1NDM5OAeInB8MKtAIkkzGFwT7QH62SsqEb91pPGkLeM8=
-----END CERTIFICATE-----
```



###### ④`Disable https certificate check`

```
不够上
```

###### ⑤`Kubernetes Namespace`

```
default
```

###### ⑥制作证书

[1].复制`/etc/kubernetes/pki `下的`ca.crt  `、`apiserver-kubelet-client.crt `、`apiserver-kubelet-client.key `至其他目录

[2].进入至放入三个文件的目录执行

```
openssl pkcs12 -export -out cert.pfx -inkey apiserver-kubelet-client.key -in apiserver-kubelet-client.crt -certfile ca.crt
```

[3].输入密码(一会儿上传到jenkins要用到)

[4].点击`Add`选择`Jenkins`

[5].Domain---`全区凭证`、类型---`Certificate`、范围---`全局`、选择`上传` 将刚刚生成的`cert.pfx`上传、输入`用户名`和`密码`、`添加`

[6].在Add边上的选择栏选择`"新出来的"`

###### ⑦点击`Test Connection`

```
显示 	Connection test successful 则配置成功
```

###### ⑧`Jenkins URL`

```
http://117.191.65.86:9999
--- Jenkins地址:端口
```

#### (5).保存

### 7).部署实例(含k8s)

#### (1)Kubernetes插件连接kubernetes

有待更新。。。

#### (2).脚本连接kubernetes

##### ☆如果是jenkins和kubernetes的master节点不在同一服务器则挂载kubernetes的master节点至jenkins再执行。

##### ☆如果是jenkins和kubernetes的master节点在同一服务器则可直接执行

##### ①General

```
随便写一写
如果是有挂载节点则要选择工作节点(master节点)
```

##### ②源码管理

###### 选择`Subversion`

[1].` Repository URL`

```
svn://39.106.103.164/code/test/fuck-world

svn地址
```

[2].`Credentials`

点击`Add`添加svn的账号密码然后选择

[3].其余不动

##### ③构建触发器

[1].勾选`Build whenever a SNAPSHOT dependency is built`

[2].勾选`轮询 SCM`

```
* * * * *
```

↑↑↑意思为提交代码后的一分钟开始构建

##### ④Build

` Root POM`

```
pom.xml
```

##### ⑤Post Steps

勾选`Run only if build succeeds`

点击`Add post-build step`选择`执行shell`

```
sh /xxx/xxx/xxx.sh ;
```

##### 所执行shell内容

```
source ~/.bash_profile ;
echo "I want to Fuck THE World!" ;
echo "##########;" ;

VERSION=`date "+%F"` ;

docker run -dt --name ZZZ registry.cn-qingdao.aliyuncs.com/caonima/tomcat7:1.8-redis ;
docker cp /var/lib/jenkins/workspace/FuckWorld/target/fuck-world.war ZZZ:/usr/local/tomcat/webapps/ ;
rm -rf /var/lib/jenkins/workspace/FuckWorld/target/fuck-world.war ;
rm -rf /var/lib/jenkins/workspace/FuckWorld/target/fuck-world ;
docker stop ZZZ ;
docker commit ZZZ registry.cn-qingdao.aliyuncs.com/caonima/fuck-world:$VERSION ;
docker push registry.cn-qingdao.aliyuncs.com/caonima/fuck-world:$VERSION ;
docker rm ZZZ ;

sed -i '14c \        \image: registry.cn-qingdao.aliyuncs.com/caonima/fuck-world:'$VERSION /root/FuckWorld/fuck-world.yml ;
kubectl apply -f /root/FuckWorld/fuck-world.yml --record ;
echo "##########" ;
echo "I have Fucked The World!" ;
```

##### 注:次实例支持部署、更新、回滚、备份(至Aliyun-DockerHub)



# MySql数据库安装及调试

### 1.拉取镜像

```
docker pull mysql:5.7
```

### 2.启动

```
docker run -dt --name mysql -p 3306:3306 -v /Users/HatChin/ZZZ/mysql:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=123456 mysql:5.7 
```











# oracle数据库安装及调试

### 1.拉取镜像

```
docker pull registry.cn-hangzhou.aliyuncs.com/helowin/oracle_11g
```

### 2.安装

```
docker run -d --name oracle \
    --net oracle-network \
    --ip 172.18.0.3 \
    --privileged=true \
    --restart unless-stopped \
    -p 1521:1521 \
    -v /root/oracle/helowin:/home/oracle/app/oracle/oradata/helowin \
    registry.cn-qingdao.aliyuncs.com/caonima/oracle:helowin
```

### 3.调试bug

#### 1).进入

```
source /home/oracle/.bash_profile
sqlplus /nolog
conn /as sysdba
```

#### 2).调试

```
1.找控制文件
show parameter control_files;
看到输出后查找对应目录是否有控制文件
2.关闭数据库
shutdown immediate
3.粘贴缺少的控制文件
(有可能需要修改权限)
4.以nomount方式启动实例 
startup nomount
5.修改参数文件
alter system set control_files='/home/oracle/app/oracle/oradata/helowin/control01.ctl' , '/home/oracle/app/oracle/flash_recovery_area/helowin/control02.ctl' scope=spfile;
弹出"System altered"
6.关闭数据库
shutdown immediate
7.开启数据库
startup
```

### 4.导入数据

```
imp userid=firm/firm@helowin file=firm.dmp full=y
```

### 5.导出数据

```
exp userid=firm/firm@helowin file=/home/firm.dmp full=y;
```

### 6.创建/删除用户及赋予权限

#### 1).创建用户

```
create user firm identified by firm;
```

#### 2).赋予权限

```
grant connect,resource,dba to firm;
```

#### 3).删除用户

```
drop user firm cascade;
```



### 7.数据库坏块问题

问题:

```
ORA-00600: internal error code, arguments: [kcratr_scan_lastbwr], [], [], [],
[], [], [], [], [], [], [], []
```

#### 1).关闭数据库

```
shutdown immediate;
```

#### 2).开启数据库

```
startup mount;
```

#### 3).恢复介质

```
recover database;
alter database open;
```

#### 4).关闭数据库

```
shutdown immediate;
```

#### 5).开启数据库

```
startup
```







# 杂项

### WebStorm常用设置和常用快捷键

```
https://www.cnblogs.com/yiguozhi/p/5328405.html
```

### CentOS Mirror(ISO)

```
http://isoredirect.centos.org/centos/7/isos/x86_64/CentOS-7-x86_64-DVD-1708.iso
```

### 追踪命令(进程)

```
strace -t -p 4545
```



### layui 后台大框架布局

```
https://www.layui.com/demo/admin.html
```

### ※※※CentOS※※※

#### 1.yum

##### 1).列出所有已安装的软件包

```
yum list installed 
```

##### 2).列出所有可安装的软件包

```
yum list 
```

##### 3).列出所有可更新的软件包

```
yum list updates 
```

##### 4).列出所有已安装但不在 Yum Repository 内的软件包

```
yum list extras
```

##### 5).列出所有已安装但不在 Yum Repository 内的软件包信息

```
yum info extras
```

##### 6).列出所指定的软件包

```
yum list
```

##### 7).列出所有可更新的软件包信息

```
yum info updates 
```

##### 8).列出软件包提供哪些文件 

```
yum provides
```

#### 2.查看目录空间使用

##### 1).查看所有

```
df -h
```

##### 2).查看目录

```
du -h --max-depth=1 目录名
```

#### 3.NFS服务器搭建

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

```
yum install nfs-utils -y
"vi /etc/fstab" 添加 192.168.136.181:/extends/ nfs defaults 0 0
mount -t 192.168.136.181:/extends/
```

#### 4.后台运行程序

```
nohup java -jar /usr/local/tomcat/excel-0.0.1-SNAPSHOT.jar &
```

#### 5.定位查找文件

##### 1).which---`从path中找出文件的位置`

```
which命令的作用是，在PATH变量指定的路径中，搜索某个系统命令的位置，并且返回第一个搜索结果。在找到第一个符合条件的程序文件时，就立刻停止搜索，省略其余未搜索目录。也就是说，使用which命令，就可以看到某个系统命令是否存在，以及执行的到底是哪一个位置的命令。
```

###### 例:`which java`

```
/jdk1.8.0_181/bin/java
```

##### 2).whereis---`找出特定程序的路径 `

```
找出特定程序的可执行文件、源代码文件以及manpage的路径。你所提供的name会被先除去前置的路径以及任何.ext形式的扩展名。
whereis 只会在标准的Linux目录中进行搜索。
常用选项
-b
只搜索可执行文件。
-m
只搜索manpage。
-s
只搜索源代码文件。
-B directory
更改或限定搜索可执行的文件的目录。
-M directory
更改或限定搜索manpage的目录。
-S directory
更改或限定搜索源代码文件的目录。
```

###### 例:`whereis java`

```
java: /usr/bin/java /usr/lib/java /etc/java /usr/share/java /jdk1.8.0_181/bin/java /usr/share/man/man1/java.1.gz
```

##### 3).find---`找出所有符合要求的文件`

```
以paths为搜索起点逐层往下找出每一个符合expression条件的文件，并对该文件执行action所代表的动作。expression是搜索条件，它由一个代表匹配项目的选项以及一个代表匹配模式的参数构成。
$ find <指定目录> <指定条件> <指定动作>
　　- <指定目录>： 所要搜索的目录及其所有子目录。默认为当前目录。
　　- <指定条件>： 所要搜索的文件的特征。
　　- <指定动作>： 对搜索结果进行特定的处理。

如果什么参数也不加，find默认搜索当前目录及其子目录，并且不过滤任何结果（也就是返回所有文件），将它们全都显示在屏幕上。

action是处理动作，它有一个代表“处理方式”的选项以及一个操作参数构成。若不指定action，则默认动作是显示出文件名。

常用的搜索条件
-name pattern 
-path pattern  
-lname pattern
找出名称、路径名称或符号链接的目标匹配pattern模式的文件。pattern可以包含shell的文件名通配符，路径是相对于搜索起点的。

常见处理动作
-print
显示出文件的相对路径（相对于搜索起点）。
-exec cmd /;

执行指定的shell命令。若cmd含有任何shell特殊字符，则他们之前都必须加上/符号，以免shell立刻执行他们。在cmd里，可以用”{}”符号(包括双引号)表示find所找出的文件。

1.按照文件名查找
(1)find / -name httpd.conf　　#在根目录下查找文件httpd.conf，表示在整个硬盘查找
(2)find /etc -name httpd.conf　　#在/etc目录下文件httpd.conf
(3)find /etc -name '*srm*'　　#使用通配符*(0或者任意多个)。表示在/etc目录下查找文件名中含有字符串‘srm’的文件
(4)find . -name 'srm*' 　　#表示当前目录下查找文件名开头是字符串‘srm’的文件
2.按照文件特征查找 　　　　
(1)find / -amin -10 　　# 查找在系统中最后10分钟访问的文件(access time)
(2)find / -atime -2　　 # 查找在系统中最后48小时访问的文件
(3)find / -empty 　　# 查找在系统中为空的文件或者文件夹
(4)find / -group cat 　　# 查找在系统中属于 group为cat的文件
(5)find / -mmin -5 　　# 查找在系统中最后5分钟里修改过的文件(modify time)
(6)find / -mtime -1 　　#查找在系统中最后24小时里修改过的文件
(7)find / -user fred 　　#查找在系统中属于fred这个用户的文件
(8)find / -size +10000c　　#查找出大于10000000字节的文件(c:字节，w:双字，k:KB，M:MB，G:GB)
(9)find / -size -1000k 　　#查找出小于1000KB的文件
3.使用混合查找方式查找文件
参数有： ！，-and(-a)，-or(-o)。
(1)find /tmp -size +10000c -and -mtime +2
#在/tmp目录下查找大于10000字节并在最后2分钟内修改的文件
(2)find / -user fred -or -user george 　　#在/目录下查找用户是fred或者george的文件文件
(3)find /tmp ! -user panda　　
#在/tmp目录中查找所有不属于panda用户的文件
```

例:`find / -name redis.conf`

```
/home/lhcz/redis/redis.conf
/home/lhcz/redis.conf
find: ‘/run/user/42/gvfs’: 权限不够
/root/k8s/Configmap/redis.conf
/var/lib/kubelet/pods/d43ac2b4-9491-11e8-8de3-6c92bf321ac4/volumes/kubernetes.io~nfs/redis-pv/redis.conf
/var/lib/kubelet/pods/d43ac2b4-9491-11e8-8de3-6c92bf321ac4/volumes/kubernetes.io~configmap/redis-conf/..2018_07_31_07_17_48.174040174/redis.conf
/var/lib/kubelet/pods/d43ac2b4-9491-11e8-8de3-6c92bf321ac4/volumes/kubernetes.io~configmap/redis-conf/redis.conf
```

例:`find /www/server/nginx/conf -name nginx.conf`

```
/www/server/nginx/conf/nginx.conf
```

#### 6.SED

##### 常用参数:

```
-n∶使用安静(silent)模式。在一般 sed 的用法中，所有来自 STDIN的资料一般都会被列出到萤幕上。但如果加上 -n 参数后，则只有经过sed 特殊处理的那一行(或者动作)才会被列出来。

-e∶直接在指令列模式上进行 sed 的动作编辑；

-f∶直接将 sed 的动作写在一个档案内， -f filename 则可以执行 filename 内的sed 动作；

-r∶sed 的动作支援的是延伸型正规表示法的语法。(预设是基础正规表示法语法)

-i∶直接修改读取的档案内容，而不是由萤幕输出。       
```

##### 常用命令:

```
a∶新增---a 的后面可以接字串，而这些字串会在新的一行出现(目前的下一行)
c∶取代---c 的后面可以接字串，这些字串可以取代n1,n2之间的行
d∶删除---因为是删除啊，所以 d 后面通常不接任何东西
i∶插入---i 的后面可以接字串，而这些字串会在新的一行出现(目前的上一行)
p∶列印---亦即将某个选择的资料印出。通常p会与参数 sed -n一起运作
s∶取代---可以直接进行取代的工作。通常这个s的动作可以搭配正规表示法
```

##### 举例:

###### 1).删除某行

```
sed '1d' ab             #删除第一行 
sed '$d' ab             #删除最后一行
sed '1,2d' ab           #删除第一行到第二行
sed '2,$d' ab           #删除第二行到最后一行
```

###### 2).显示某行

```
sed -n '1p' ab          #显示第一行 
sed -n '$p' ab          #显示最后一行
sed -n '1,2p' ab        #显示第一行到第二行
sed -n '2,$p' ab        #显示第二行到最后一行
```

###### 3).使用模式进行查询

```
sed -n '/ruby/p' ab     
#查询包括关键字ruby所在所有行
sed -n '/\$/p' ab       
#查询包括关键字$所在所有行，使用反斜线\屏蔽特殊含义
```

###### 4).增加一行或多行字符串

```
sed '1a drink tea' ab   
#第一行后增加字符串"drink tea"
sed '1,3a drink tea' ab 
#第一行到第三行后增加字符串"drink tea
sed '1a drink tea\nor coffee' ab   
#第一行后增加多行，使用换行符\n
```

###### 5).代替一行或多行

```
sed '1c Hi' ab 
#第一行代替为Hi
sed '1,2c Hi' ab
#第一行到第二行全部代替为Hi
```

###### 6).替换一行中的某部分

格式：sed 's/要替换的字符串/新的字符串/g'   （要替换的字符串可以用正则表达式）

```
sed -n '/ruby/p' ab | sed 's/ruby/bird/g'    #替换ruby为bird
sed -n '/ruby/p' ab | sed 's/ruby//g'        #删除ruby
```

###### 7).插入

```
sed -i '$a bye' ab         #在文件ab中最后一行直接输入"bye"
```

#### 7.安装ifconfig/ping

##### ifconfig

```
yum install net-tools -y
```

##### ping

```
 yum install iputils -y
```

#### 8.固定IP

```
TYPE=Ethernet
PROXY_METHOD=none
BROWSER_ONLY=no
BOOTPROTO=static
DEFROUTE=yes
IPV4_FAILURE_FATAL=no
IPV6INIT=yes
IPV6_AUTOCONF=yes
IPV6_DEFROUTE=yes
IPV6_FAILURE_FATAL=no
IPV6_ADDR_GEN_MODE=stable-privacy
NAME=eno1
UUID=223db612-b4fc-4e7b-87aa-61691e73ddd2
DEVICE=eno1
ONBOOT=yes

IPADDR=192.168.1.133
NETMASK=255.255.255.0
GATEWAY=192.168.1.1
BROADCAST=192.168.1.255
DNS1=8.8.8.8
```





### GIT

```
https://blog.csdn.net/tiweeny/article/details/78514092
```









mac-navicat-premium铭文和手动秘钥

```
{
  "K" : "NAVFZCE3FDCB46BX",
  "P" : "Mac 10.11",
  "DI" : "MWZiOGJlMzljOGI0YjEw"
}

Vo1YXVMkbM185P675VMnNUJcgznKrzH8GO1LSYP4xKOCXK3xFBihEgVEKWxDQsC2c5cB7EiMznyrdjdEXC3GR2zfbFubcczu4ygypPF1hp5+9dwSYMp+vfqKfEatu+CdZZNHJ54UE/jg2myEA/3c9KMN7SLRI2/GoTA5NBIn4L5V5ngHWnsZzh+aQsFeh1eBFaLINXBWGvM9xMQbot3eQhODol7ESVGWFfbBVDb4rb9OjP/642svdDiOtylGc/dEU9iHcg/8aiOyvC6b2HIOfCi9LJ+66U2N69ewo0xCleRP3Ge7TMcrfWgfo986ZoLAHrBdaDuoT3pxxGLBCYyNbw==
```





# Redis

### 1).安装

```
docker search  redis   查找Docker Hub上的redis镜像

docker pull  redis   拉取官方的镜像
```

### 2).启动容器

```
docker run -p 6699:6379 --name myredis -v $PWD/redis.conf:/etc/redis/redis.conf -v $PWD/data:/data -d redis:3.2 redis-server /etc/redis/redis.conf --appendonly yes
```

```
命令说明：

--name myredis : 指定容器名称，这个最好加上，不然在看docker进程的时候会很尴尬。

-p 6699:6379 ： 端口映射，默认redis启动的是6379，至于外部端口，随便玩吧，不冲突就行。

-v $PWD/redis.conf:/etc/redis/redis.conf ： 将主机中当前目录下的redis.conf配置文件映射。

-v $PWD/data:/data -d redis:3.2 ： 将主机中当前目录下的data挂载到容器的/data

--redis-server --appendonly yes :在容器执行redis-server启动命令，并打开redis持久化配置\

注意事项：

如果不需要指定配置，-v $PWD/redis.conf:/etc/redis/redis.conf 可以不用 ，redis-server 后面的那段 /etc/redis/redis.conf 也可以不用。

主要我是用来给redis设置了密码，我怕别人偷偷用我的redis。
```

```
设置密码只需要加上–requirepass
docker run -d --name myredis -p 6379:6379 redis --requirepass "mypassword"
```

```
本地测试:
docker run -dt -v /work/redis.conf:/etc/redis.conf  --name myredis --privileged -p 6379:6379 docker.io/redis:latest redis-server /etc/redis.conf  --appendonly yes

如果不成功需要修改redis.conf文件。
daemonize no#用守护线程的方式启动
requirepass yourpassword#给redis设置密码
bind 192.168.1.1 #注释掉这部分，这是限制redis只能本地访问
appendonly yes#redis持久化

进入客户端：
docker exec -it 17cae8f2d6bb redis-cli
```

