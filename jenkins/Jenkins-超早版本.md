# 练习步骤

> DevOps工程师速成班 第二课 交付流水线

## 练习零 Jenkins服务端部署

### 1.准备预装Linux系统环境

> 在Mac或Windows系统也可部署，但具体步骤会有差异，建议统一使用Linux系统

- 物理机或虚拟机均可，建议使用虚拟机，因为后续课程练习会需要使用两台机器
- 简单起见可以使用免费的Virtualbox虚拟机，自己有云主机或其他虚拟机也可
- Linux内核版本建议至少3.10，例如`CentOS 7.0`或`Ubuntu 16.04`及以上版本的发行版

### 2.安装Docker容器

使用Docker主要是为了减少部署过程中的环境差异和保存系统的干净，在第五次课里我们会详细介绍Docker的使用。

```
curl -sSL get.docker.com | bash
```

如果当前用户不是`root`，还需要将用户加入到`docker`的用户组里，然后重新登录用户

```
sudo usermod -aG docker `whoami`
```

### 3.导入离线镜像

> 导入离线镜像主要是为了减少容器启动时自动下载镜像的时间<br>
> 如果使用的是国外的云服务器，如AWS，则此步骤可省略

课程中使用到的Docker镜像（均来自DockerHub）：

- gogs/gogs
- jenkins/jenkins:2.72
- maven:3.5.0-jdk-8-alpine

离线镜像打包文件下载地址：

- [https://pan.baidu.com/s/1skCgto5](https://pan.baidu.com/s/1skCgto5)

将下载的devops-1.tgz文件拷贝到虚拟机中，然后解压并导入到Docker

```
tar zxf devops-1.tgz
docker load -i jenkins.tar
docker load -i gogs.tar
docker load -i maven.tar
```

### 4.通过Docker部署Gogs

```
docker run -dt --name=gogs \
    -p 10022:22 \
    -p 3000:3000 \
    -v /tmp/gogs_data:/data \
    gogs/gogs
```

### 5.通过Docker部署Jenkins

由于需要在Docker里再使用主机的Docker创建容器提供构建环境，使用了额外的参数挂载必要的文件到容器中。以下命令已在`Ubuntu 16.04`和`CentOS 7.2`系统中测试过。

若为`Ubuntu`或`Debian`系统，使用以下命令：

```
docker run -d --name jenkins \
    -p 8000:8080 \
    -p 10000:10000 \
    -p 50000:50000 \
    -v /opt/jenkins_data:/var/jenkins_home \
    -v /usr/bin/docker:/usr/bin/docker \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v /usr/lib/x86_64-linux-gnu/libltdl.so.7:/usr/lib/x86_64-linux-gnu/libltdl.so.7 \
    --user root \
    jenkins/jenkins:2.72
```

若为`RHEL`或`CentOS`系统，使用以下命令：

```
docker run -d --name jenkins \
    -p 8000:8080 \
    -p 10000:10000 \
    -p 50000:50000 \
    -v /opt/jenkins_data:/var/jenkins_home \
    -v /usr/bin/docker:/usr/bin/docker \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v /usr/lib64/libltdl.so.7:/usr/lib/x86_64-linux-gnu/libltdl.so.7 \
    --user root \
    jenkins/jenkins:2.72
```

### 6.解锁Jenkins

在浏览器打开`http://<Linux机器IP>:8000`会打开Jenkins的操作页面，并进入`Unlock Jenkins`画面。

<img src='1.png' width='50%'/>

根据提示在容器中找到密钥文件内容：

```
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

将密钥内容输入到界面上，完成解锁。

### 7.插件初始化

解锁后进入`Customize Jenkins`页面。

<img src='2.png' width='50%'/>

这一步不论选择那种方式在国内网络都经常会出错失败，此时可以直接点右上角关闭初始化配置对话框。完成Jenkins的部署。

（也不妨试一下右侧的定制安装，若没有出错，可以直接在这里选择安装`Git`和`Pipeline`插件）

## 练习一 Jenkins的基本配置

```
启动jenkins
docker start jenkins
```

### 1.用户管理

点左侧菜单栏“Manage Jenkins”，在管理页面点击“Manage Users”。

左侧的“Create User”按钮可以添加用户，右侧每个用户的齿轮图表可以修改用户配置。

点击`admin`的齿轮图标，修改此用户密码，点击保存。

### 2.安装插件

如果在练习零的最后一步是直接关闭对话框的，接下来需要额外安装Pipeline插件。

再次点左侧菜单栏“Manage Jenkins”，然后点击“Manage Plugins”，选择“Available”标签。

在列表中找到`Pipeline`插件（搜索关键字"solutions/pipeline"）和`Git`（搜索关键字"GIT SCM"），点击“Download now and install after restart”。

<img src='3.png' width='80%'/>
<img src='4.png' width='80%'/>

进入安装界面，勾选进度列表末尾的“Restart Jenkins when installation is complete and no jobs are running”，等待安装完成，Jenkins自动重启。

> 这两个插件以及依赖一共约50+M，如果实在由于网络原因无法下载，可以从以下百度盘下载压缩文件，放到虚拟机内，然后直接拷贝进容器
>
> - [https://pan.baidu.com/s/1bp7z3P1](https://pan.baidu.com/s/1bp7z3P1)
>
> ```
> tar zxf jenkins-plugins.tgz
> docker cp plugins jenkins:/var/jenkins_home/
> ```

进入jenkins中的家目录

```
docker exec -it c9b221cd80a7 /bin/bash
//↑其中c9b221cd80a7为docker ps中的jenkins的id号
```



## 练习二 体验可视化流水线

### 1.创建流水线项目

点击菜单栏左侧的“New Item”，在新建项目页面给新项目起名，选择类型为“Pipeline”。点击“OK”。

<img src='5.png' width='80%'/>

### 2.简单的多步骤流水线

在“Pipeline”的部分写入流水线描述，然后点击“Save”。

```
pipeline {
    agent any
    stages {
        stage('步骤一') {
            steps {
                  sh 'echo "Single line step"'
            }
        }
        stage('步骤二') {
            steps {
                sh '''
                    echo "Multiline shell steps"
                    ls -la
                '''
            }
        }
    }
}
```

### 3.执行流水线

在流水线页面点击“Build Now”，如果没有错误发生，每个步骤都会以绿色的方块表示出来。

<img src='6.png' width='50%'/>

执行完成后，可以点击每一个步骤，查看该步骤执行日志。

### 4.稍复杂的流水线

这个流水线会自己从Git仓库拉取代码，然后在一个提供构建环境的Docker容器里进行代码构建。

新建一个项目，命名“parent-pom”，使用如下配置信息：

```
pipeline {
    agent {
        docker {
            reuseNode true
            image "maven:3.5.0-jdk-8-alpine"
            args "-v /opt/m2:/root/.m2"
        }
    }
    stages {
        stage('代码更新') {
            steps {
                git url: "https://github.com/microservices-kata/petstore-parent-pom.git"
            }
        }
        stage('构建代码') {
            steps {
                sh "mvn clean install"
            }
        }
    }
}
```

### 5.接近真实项目的构建流水线

再次新建一个流水线，命名为“account-service”。这个流水线在完成构建以后还会接着执行项目的单元测试、生成发布的包，最后执行接口测试。

```
pipeline {
    agent {
        docker {
            reuseNode true
            image "maven:3.5.0-jdk-8-alpine"
            args "-v /opt/m2:/root/.m2"
        }
    }
    stages {
        stage('代码更新') {
            steps {
                git url: "https://github.com/microservices-kata/petstore-account-service.git"            }
        }
        stage('构建代码') {
            steps {
                sh "mvn clean compile"
            }
        }
        stage('单元测试') {
            steps {
                sh "mvn test"
            }
        }
        stage('生成运行包') {
            steps {
                sh "mvn package"
            }
        }
        stage('集成测试') {
            steps {
                sh "mvn verify"
            }
        }
    }
}
```

在最后一步执行契约测试的地方会失败，因为连接不到放契约文件的服务器。观察失败时流水线的表现。

> 如果在构建时下载依赖的速度非常慢，可将依赖源替换为国内服务器：
>
> ```
> cat <<EOF | sudo tee /opt/m2/settings.xml
> <settings>
>   <mirrors>
>     <mirror>
>         <id>nexus-aliyun</id>
>         <mirrorOf>*</mirrorOf>
>         <name>Nexus aliyun</name>
>         <url>http://maven.aliyun.com/nexus/content/groups/public</url>
>     </mirror>
>   </mirrors>
> </settings>
> EOF
> ```

## 练习三 使用Jenkinsfile快速生成流水线

### 1.将Github仓库中的代码导入到私有仓库

在`petstore-account-service`项目中已经包含了生成流水线的`Jenkinsfile`文件，但其中的内容有些超出了这次的课程范围，需要对这个文件进行修改。

利用在第一次课中学习的内容，将`https://github.com/microservices-kata/petstore-account-service.git`仓库的代码复制到Gogs仓库中，以方便对其中的内容进行修改。

```
git clone https://github.com/microservices-kata/petstore-account-service.git
git remote add stuq http://<Gogs服务器的IP>:3000/<用户名>/<仓库名>
git push -u stuq
```

### 2.修改Jenkinsfile并删除契约测试

在Jenkinsfile中删除“创建镜像”和“部署Dev环境”两个步骤。
删除`src/test/scala/com/thoughtworks/petstore/contract/VerifyPacts.scala`文件

### 3.创建使用Jenkinsfile生成的流水线

在Jenkins新创建一个Pipeline类型的项目。

将Pipeline的`Definition`属性选择“Pipeline script from SCM”，选择SCM类型为“Git”，填入Gogs仓库地址。

执行流水线，Jenkins会自动从Git仓库获得代码以及流水线的信息，完成整个流程的自动化。

### 4.添加自动构建

在项目的Build Triggers配置下面勾选`Poll SCM`，填写一个定时检查代码更新的Crontab时间表达式。

<img src='7.png' width='30%'/>

## 练习四 使用API批量创建流水线

### 1.开启远程访问许可

在Jenkins主页点击`Manage Jenkins`，选择`Configure Global Security`，找到最下方的“SSH Server”功能，开启此功能并选择固定端口：10000.

<img src='8.png' width='50%'/>

### 2.生成SSH密钥

在Linux服务器上生成一个密钥文件，并查看公钥内容

```
ssh-keygen
cat ~/.ssh/id_rsa.pub
```

### 3.添加用户公钥到Jenkins

进入`Manage Jenkins`中的`Manage Users`页面，点击当前用户列的小齿轮，在“SSH Public Key”配置中填入用户的公钥。

<img src='9.png' width='50%'/>

### 4.使用API创建流水线

先拿一个项目做模板

```
ssh -l admin -p 10000 <Jenkins机器IP> get-job <流水线项目名称> > template.xml
```

将输出内容保存成template.xml文件，修改其中的项目配置，然后用这个文件批量创建流水线

```
ssh -l admin -p 10000 <Jenkins机器IP> <新的项目名称> < template.xml
```
