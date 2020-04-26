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

```
vi /etc/sysconfig/jenkins
```

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
不钩上

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

##### 注:此实例支持部署、更新、回滚、备份(至Aliyun-DockerHub)



# Pipeline

## 语法

```
pipeline {
    agent any #①
    stages {
        stage('Stage 1') {
            steps {
                echo 'Hello world!' #②
            }
        }
    }
}
```

①`agent` 指示Jenkins为整个管道分配执行程序（在Jenkins环境中的任何可用代理程序/节点上）和工作空间。 

②`echo` 在控制台输出中写入简单的字符串。 

Declarative Pipeline中的基本语句和表达式遵循与Groovy语法相同的规则 ，但有以下例外：

- 　　a.Pipeline的顶层必须是块，具体来说是：pipeline { }
- 　　b.没有分号作为语句分隔符。每个声明必须在自己的一行
- 　　c.块只能包含Sections, Directives, Steps或赋值语句。
- 　　d.属性引用语句被视为无参方法调用。所以例如，输入被视为input（）

### agent

　　agent部分指定整个Pipeline或特定阶段将在Jenkins环境中执行的位置，具体取决于该agent 部分的放置位置。该部分必须在pipeline块内的顶层定义 ，但stage级使用是可选的。

#### 参数

##### any

在任何可用的agent 上执行Pipeline或stage。例如：agent any

##### none

当在pipeline块的顶层使用none时，将不会为整个Pipeline运行分配全局agent ，每个stage部分将需要包含其自己的agent部分。

##### label

使用提供的label标签，在Jenkins环境中可用的代理上执行Pipeline或stage。例如：agent { label 'my-defined-label' }

##### node

agent { node { label 'labelName' } }，等同于 agent { label 'labelName' }，但node允许其他选项（如customWorkspace）。

##### docker

定义此参数时，执行Pipeline或stage时会动态供应一个docker节点去接受Docker-based的Pipelines。docker还可以接受一个args，直接传递给docker run调用。例如：agent { docker 'maven:3-alpine' }或dockerfile 。使用从Dockerfile源存储库中包含的容器来构建执行Pipeline或stage 。为了使用此选项，Jenkinsfile必须从Multibranch Pipeline或“Pipeline from SCM"加载。

默认是在Dockerfile源库的根目录：agent { dockerfile true }。如果Dockerfile需在另一个目录中建立，请使用以下dir选项：agent { dockerfile { dir 'someSubDir' } }。您可以通过docker build ...使用additionalBuildArgs选项，如agent {dockerfile { additionalBuildArgs '--build-arg foo=bar' } }。 

```
docker
agent {
    docker {
        image 'maven:3-alpine'
        label 'my-defined-label'
        args  '-v /tmp:/tmp'
    }
}
```

#### 常用选项

##### label 　　　　

一个字符串。标记在哪里运行pipeline或stage。此选项适用于node，docker和dockerfile，并且 node是必需的。 

##### customWorkspace 

一个字符串。自定义运行的工作空间内。它可以是相对路径，在这种情况下，自定义工作区将位于节点上的工作空间根目录下，也可以是绝对路径。例如： 

```
agent {
    node {
        label 'my-defined-label'
        customWorkspace '/some/other/path'
    }
}
```

##### reuseNode

一个布尔值，默认为false。如果为true，则在同一工作空间中。

此选项适用于docker和dockerfile，并且仅在 individual stage中使用agent才有效。 

```
pipeline {
    agent { docker 'maven:3-alpine' }
    stages {
        stage('Example Build') {
            steps {
                sh 'mvn -B clean verify'
            }
        }
    }
}
```

```
pipeline {
    agent none
    stages {
        stage('Example Build') {
            agent { docker 'maven:3-alpine' }
            steps {
                echo 'Hello, Maven'
                sh 'mvn --version'
            }
        }
        stage('Example Test') {
            agent { docker 'openjdk:8-jre' }
            steps {
                echo 'Hello, JDK'
                sh 'java -version'
            }
        }
    }
}
```

##### post

定义Pipeline或stage运行结束时的操作。post-condition块支持post部件：always，changed，failure，success，unstable，和aborted。这些块允许在Pipeline或stage运行结束时执行步骤，具体取决于Pipeline的状态。

###### conditions项： 　　

always 　　　　

```
运行，无论Pipeline运行的完成状态如何。
```

changed 　　　　

```
只有当前Pipeline运行的状态与先前完成的Pipeline的状态不同时，才能运行。 　　
```

failure 　　　　

```
仅当当前Pipeline处于“失败”状态时才运行，通常在Web UI中用红色指示表示。 　　
```

success 　　　　

```
仅当当前Pipeline具有“成功”状态时才运行，通常在具有蓝色或绿色指示的Web UI中表示。 
```

unstable 　　　　

```
只有当前Pipeline具有“不稳定”状态，通常由测试失败，代码违例等引起，才能运行。通常在具有黄色指示的Web UI中表示。
```

aborted 　　　　

```
只有当前Pipeline处于“中止”状态时，才会运行，通常是由于Pipeline被手动中止。通常在具有灰色指示的Web UI中表示。 
```

###### 示例:

```
pipeline {
    agent any
    stages {
        stage('Example') {
            steps {
                echo 'Hello World'
            }
        }
    }
    post {
        always {
            echo 'I will always say Hello again!'
        }
    }
}
```

### stages

包含一个或多个stage的序列，Pipeline的大部分工作在此执行。建议stages至少包含至少一个stage指令，用于连接各个交付过程，如构建，测试和部署等。  

#### steps

steps包含一个或多个在stage块中执行的step序列。  

```
pipeline {
    agent any
    stages {
        stage('Example') {
            steps {
                echo 'Hello World'
            }
        }
    }
}
```

### Directives （指令）

#### environment

environment指令指定一系列键值对，这些键值对将被定义为所有step或stage-specific step的环境变量，具体取决于environment指令在Pipeline中的位置。 该指令支持一种特殊的方法credentials()，可以通过其在Jenkins环境中的标识符来访问预定义的凭据。 对于类型为“Secret Text”的凭据，该 credentials()方法将确保指定的环境变量包含Secret Text内容；对于“标准用户名和密码”类型的凭证，指定的环境变量将被设置为username:password。 

```
pipeline {
    agent any
    environment {
        CC = 'clang'
    }
    stages {
        stage('Example') {
            environment {
                AN_ACCESS_KEY = credentials('my-prefined-secret-text')
            }
            steps {
                sh 'printenv'
            }
        }
    }
}
```

#### options

options指令允许在Pipeline本身内配置Pipeline专用选项。Pipeline本身提供了许多选项，例如buildDiscarder，但它们也可能由插件提供，例如 timestamps。

##### 可用选项

###### buildDiscarder 　　　　

pipeline保持构建的最大个数。

例如：

```
options { buildDiscarder(logRotator(numToKeepStr: '1')) }
```

###### disableConcurrentBuilds

不允许并行执行Pipeline,可用于防止同时访问共享资源等。

例如：

```
options { disableConcurrentBuilds() } 
```

###### skipDefaultCheckout

默认跳过来自源代码控制的代码。

例如：

```
options { skipDefaultCheckout() } 
```

###### skipStagesAfterUnstable 

一旦构建状态进入了“Unstable”状态，就跳过此stage。

例如：

```
options { skipStagesAfterUnstable() } 
```

###### timeout 

设置Pipeline运行的超时时间。

例如：

```
options { timeout(time: 1, unit: 'HOURS') }
```

###### retry

失败后，重试整个Pipeline的次数。

例如：

```
options { retry(3) } 
```

###### timestamps 

预定义由Pipeline生成的所有控制台输出时间。

例如：

```
options { timestamps() } 
```

```
pipeline {
    agent any
    options {
        timeout(time: 1, unit: 'HOURS')
    }
    stages {
        stage('Example') {
            steps {
                echo 'Hello World'
            }
        }
    }
}　
```

#### parameters

parameters指令提供用户在触发Pipeline时的参数列表。这些参数值通过该params对象可用于Pipeline步骤。

##### 可用参数

###### string

```
{ string(name: 'DEPLOY_ENV', defaultValue: 'staging', description: '') } 
```

###### booleanParam

```
parameters { booleanParam(name: 'DEBUG_BUILD', defaultValue: true, description: '') } 
```

目前只支持[booleanParam, choice, credentials, file, text, password, run, string]这几种参数类型，其他高级参数化类型还需等待社区支持。 

```
pipeline {
    agent any
    parameters {
        string(name: 'PERSON', defaultValue: 'Mr Jenkins', description: 'Who should I say hello to?')
    }
    stages {
        stage('Example') {
            steps {
                echo "Hello ${params.PERSON}"
            }
        }
    }
}
```

#### triggers

triggers指令定义了Pipeline自动化触发的方式。对于与源代码集成的Pipeline，如GitHub或BitBucket，triggers可能不需要基于webhook的集成也已经存在。目前只有两个可用的触发器：cron和pollSCM。

cron

接受一个cron风格的字符串来定义Pipeline触发的常规间隔。

```
triggers { cron('H 4/* 0 0 1-5') } 
```

pollSCM

接受一个cron风格的字符串来定义Jenkins检查SCM源更改的常规间隔。如果存在新的更改，则Pipeline将被重新触发。

```
triggers { pollSCM('H 4/* 0 0 1-5') } 
```

```
pipeline {
    agent any
    triggers {
        cron('H 4/* 0 0 1-5')
    }
    stages {
        stage('Example') {
            steps {
                echo 'Hello World'
            }
        }
    }
}
```

#### stage

stage指令在stages部分中，应包含stop部分，可选agent部分或其他特定于stage的指令。实际上，Pipeline完成的所有实际工作都将包含在一个或多个stage指令中。

 ```
pipeline {
    agent any
    stages {
        stage('Example') {
            steps {
                echo 'Hello World'
            }
        }
    }
}
 ```

#### tools

通过tools可自动安装工具，并放置环境变量到PATH。如果agent none，这将被忽略。

 ```
Supported Tools(Global Tool Configuration)
　　maven
　　jdk
　　gradle
 ```

```
pipeline {
    agent any
    tools {
        //工具名称必须在Jenkins 管理Jenkins → 全局工具配置中预配置。
        maven 'apache-maven-3.0.1'
    }
    stages {
        stage('Example') {
            steps {
                sh 'mvn --version'
            }
        }
    }
}
```

#### when

when指令允许Pipeline根据给定的条件确定是否执行该阶段。该when指令必须至少包含一个条件。如果when指令包含多个条件，则所有子条件必须为stage执行返回true。这与子条件嵌套在一个allOf条件中相同（见下面的例子）。 更复杂的条件结构可使用嵌套条件建：not，allOf或anyOf。嵌套条件可以嵌套到任意深度。 

##### 内置条件

###### branch

当正在构建的分支与给出的分支模式匹配时执行。

```
when { branch 'master' }
```

请注意，这仅适用于多分支Pipeline。

###### environment

当指定的环境变量设置为给定值时执行。

```
when { environment name: 'DEPLOY_TO', value: 'production' }
```

###### expression

当指定的Groovy表达式求值为true时执行。

```
when { expression { return params.DEBUG_BUILD } }
```

###### not

当嵌套条件为false时执行。必须包含一个条件。

```
when { not { branch 'master' } }
```

###### allOf

当所有嵌套条件都为真时执行。必须至少包含一个条件。

```
when { allOf { branch 'master'; environment name: 'DEPLOY_TO', value: 'production' } }
```

###### anyOf

当至少一个嵌套条件为真时执行。必须至少包含一个条件。

```
when { anyOf { branch 'master'; branch 'staging' } }
```

```
pipeline {
    agent any
    stages {
        stage('Example Build') {
            steps {
                echo 'Hello World'
            }
        }
        stage('Example Deploy') {
            when {
                allOf {
                    branch 'production'
                    environment name: 'DEPLOY_TO', value: 'production'
                }
            }
            steps {
                echo 'Deploying'
            }
        }
    }
}
```

### Parallel(并行)

Declarative Pipeline近期新增了对并行嵌套stage的支持，对耗时长，相互不存在依赖的stage可以使用此方式提升运行效率。除了parallel stage，单个parallel里的多个step也可以使用并行的方式运行。

```
pipeline {
    agent any
    stages {
        stage('Non-Parallel Stage') {
            steps {
                echo 'This stage will be executed first.'
            }
        }
        stage('Parallel Stage') {
            when {
                branch 'master'
            }
            parallel {
                stage('Branch A') {
                    agent {
                        label "for-branch-a"
                    }
                    steps {
                        echo "On Branch A"
                    }
                }
                stage('Branch B') {
                    agent {
                        label "for-branch-b"
                    }
                    steps {
                        echo "On Branch B"
                    }
                }
            }
        }
    }
}
```

### Steps（步骤）

Declarative Pipeline可以使用 Pipeline Steps reference中的所有可用步骤 ，并附加以下仅在Declarative Pipeline中支持的步骤。

#### script

script步骤需要一个script Pipeline，并在Declarative Pipeline中执行。对于大多数用例，script在Declarative Pipeline中的步骤不是必须的，但它可以提供一个有用的加强。

```
pipeline {
    agent any
    stages {
        stage('Example') {
            steps {
                echo 'Hello World'
 
                script {
                    def browsers = ['chrome', 'firefox']
                    for (int i = 0; i < browsers.size(); ++i) {
                        echo "Testing the ${browsers[i]} browser"
                    }
                }
            }
        }
    }
}
```

## Scripted Pipeline

Groovy脚本不一定适合所有使用者，因此jenkins创建了Declarative pipeline，为编写Jenkins管道提供了一种更简单、更有主见的语法。但是不可否认，由于脚本化的pipeline是基于groovy的一种DSL语言，所以与Declarative pipeline相比为jenkins用户提供了更巨大的灵活性和可扩展性。 

### 流程控制

pipeline脚本同其它脚本语言一样，从上至下顺序执行，它的流程控制取决于Groovy表达式，如if/else条件语句，举例如下：

```
Jenkinsfile (Scripted Pipeline)
node {
    stage('Example') {
        if (env.BRANCH_NAME == 'master') {
            echo 'I only execute on the master branch'
        } else {
            echo 'I execute elsewhere'
        }
    }
}
```

pipeline脚本流程控制的另一种方式是Groovy的异常处理机制。当任何一个步骤因各种原因而出现异常时，都必须在Groovy中使用try/catch/finally语句块进行处理，举例如下：

 ```
Jenkinsfile (Scripted Pipeline)
node {
    stage('Example') {
        try {
            sh 'exit 1'
        }
        catch (exc) {
            echo 'Something failed, I should sound the klaxons!'
            throw
        }
    }
}
 ```

### Steps

pipeline最核心和基本的部分就是“step”，从根本上来说，steps作为Declarative pipeline和Scripted pipeline语法的最基本的语句构建块来告诉jenkins应该执行什么操作。 Scripted pipeline没有专门将steps作为它的语法的一部分来介绍，但是在Pipeline Steps reference这篇文档中对pipeline及其插件涉及的steps做了很详细的介绍。如有需要可参考jenkins官网对该部分的介绍Pipeline Steps reference 

### Differences from plain Groovy

由于pipeline的一些个性化需求，比如在重新启动jenkins后要求pipeline脚本仍然可以运行，那么pipeline脚本必须将相关数据做序列化，然而这一点 Groovy并不能完美的支持，例如collection.each { item -> /* perform operation */ } 

## Declarative pipeline和Scripted pipeline的比较

### 共同点：

两者都是pipeline代码的持久实现，都能够使用pipeline内置的插件或者插件提供的steps，两者都可以利用共享库扩展。 

### 区别：

两者不同之处在于语法和灵活性。Declarative pipeline对用户来说，语法更严格，有固定的组织结构，更容易生成代码段，使其成为用户更理想的选择。但是Scripted pipeline更加灵活，因为Groovy本身只能对结构和语法进行限制，对于更复杂的pipeline来说，用户可以根据自己的业务进行灵活的实现和扩展。 



## Pipline + Gogs + Shell

### Gogs

#### 添加webhook

##### 流程

`仓库`→`仓库设置`→`管理web钩子`→`添加钩子`→`Gogs`

##### 推送地址

```
http://admin:123123@202.107.190.8:10125/generic-webhook-trigger/invoke?token=123123123
```

`admin:123123`为用户名密码

`202.107.190.8:10125`为jenkins的URL地址

`token=123123123`为jenkins配置`Generic Webhook Trigger `时写入的token

其他不用选择

### Pipline

```
node{

    stage('get clone'){
        //check CODE
        echo 'Checkout==========》》》'
            git branch: 'dev', credentialsId: '57a41cca-2873-4406-96de-7294688f116c', url: 'http://39.105.150.112:33000/Fuck_Girl/liam.git'
    }

    //定义mvn环境
    def maven = tool 'maven-3.5.4'
    env.PATH = "${maven}/bin:${env.PATH}"

    def jdk = tool 'jdk-1,8.0.181'
    env.PATH = "${jdk}/bin:${env.PATH}"

    stage('mvn test'){
        //mvn 测试
        sh "mvn test"
    }
    
    stage('mvn build'){
        //mvn构建
        sh "mvn clean install -Dmaven.test.skip=true"
    }
    
    stage('deploy'){
        //执行部署脚本
        echo "deploy ......" 
        sh "cd /root/test/FuckWorld && sh cao.sh"
    }
}
```



## Pipline + Email

### 使用插件`Email Extension Plugin`

邮箱一定要开启smtp服务

管理员邮箱要与发送邮件的邮箱一致

Password: QQ邮箱需要token码、网易邮箱需要密码

### 流程

`配置`→`Extended E-mail Notification`

### 配置见图

### Pipline设置

```
    post {
        success {
            emailext (
                subject: "SUCCESSFUL: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'",
                body: """<p>SUCCESSFUL: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]':</p>
                    <p>Check console output at "<a href="${env.BUILD_URL}">${env.JOB_NAME} [${env.BUILD_NUMBER}]</a>"</p>""",
                to: "user1@qq.com,user2@qq.com",
                from: "admin@sina.com"
            )
        }
        failure {
            emailext (
                subject: "FAILED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'",
                body: """<p>FAILED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]':</p>
                    <p>Check console output at "<a href="${env.BUILD_URL}">${env.JOB_NAME} [${env.BUILD_NUMBER}]</a>"</p>""",
                to: "user1@qq.com,user2@qq.com",
                from: "admin@sina.com"
            )
        }
    }
```









