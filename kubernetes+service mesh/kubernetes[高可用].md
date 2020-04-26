# kubernetes

高可用方案部署[3主5从]

## 基本操作

### 关闭防火墙

```
systemctl disable firewalld
```

验证

```
service firewalld status
打印出dead为成功
```

### 关闭selinux

```
vi /etc/selinux/config
```

```
将SELINUX=enforcing 改为SELINUX=disabled
```

验证

```
getenforce
打印出disabled为修改成功
```

### 关闭交换空间

```
vi /etc/fstab
```

```
注释swap项
```

### 修改节点名

```
vi /etc/hostname
```

```
修改为节点名
```

### 将节点IP加入到hosts中

查看IP

```
ifconfig
```

我的节点IP为

192.168.136.181---master    192.168.136.176---node-1  192.168.136.176---node-2

```
vi /etc/hosts
```

加入地址

```
192.168.136.181 master
192.168.136.176 node-1
192.168.136.176 node-2
```

### 配置系统内核参数使流过网桥的流量

```
vi /etc/sysctl.conf
```

添加

```
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_nonlocal_bind = 1
net.ipv4.ip_forward = 1
```

#### 生效配置文件

```
sysctl -p
```

##### 如果有如下报错:

```
sysctl: cannot stat /proc/sys/net/bridge/bridge-nf-call-ip6tables: No such file or directory
sysctl: cannot stat /proc/sys/net/bridge/bridge-nf-call-iptables: No such file or directory
```

##### 挂载br_netfilter

```
modprobe br_netfilter
```

##### 或者安装bridge-util软件，加载bridge模块，加载br_netfilter模块

```
yum install -y bridge-utils.x86_64
```

```
modprobe bridge
modprobe br_netfilter
```

### 配置阿里源

```
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0 
EOF
```

或

```
cat>>/etc/yum.repos.d/kubernetes.repo<<EOF
[kubernetes]
name=Kubernetes Repo
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
gpgcheck=0
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg
EOF
```



## ##重启

```
reboot
```



## 部署keepalive+HAproxy

### 配置转发

```
vim /etc/sysctl.conf
```

#### 加入

```
net.ipv4.ip_nonlocal_bind = 1
net.ipv4.ip_forward = 1
```

#### source

```
sysctl -p
```

### Keepalive

#### 安装

```
yum install -y ipvsadm
yum install -y keepalived
```

#### 配置

##### 注解

```
! Configuration File for keepalived                                                                                 

global_defs {
   notification_email {    #收件邮箱地址
     ws1018ws@qq.com
   }
   notification_email_from ws1018ws@163.com   #发件邮箱地址
   smtp_server 192.168.200.1
   smtp_connect_timeout 30
   router_id keepalived1    #虚拟路由标识，一般写本机的hostname名称
   vrrp_skip_check_adv_addr  #所有报文都检查比较消耗性能，此配置为如果收到的报文和上一个报文是同一个路由器则跳过检查报文中的源地址
   #vrrp_strict   #严格遵守VRRP协议。本实验是基于单播配置，此项注释
   vrrp_iptables  #禁止自动生成防火墙策略
   vrrp_garp_interval 0  #ARP报文发送延迟
   vrrp_gna_interval 0  #消息发送延迟

}

vrrp_instance VIP1 {      注：自定义实例名字
    state MASTER  #当前节点在此虚拟路由器上的初始状态，状态为MASTER或者BACKUP
    interface eth0    #绑定为当前虚拟路由器使用的物理接口
    virtual_router_id 18  #当前虚拟路由器惟一标识，范围是0-255
    priority 100   #当前物理节点在此虚拟路由器中的优先级；范围1-254
    advert_int 2   #vrrp通告的时间间隔，默认1s
 
    unicast_src_ip 192.168.18.7    #单播地址，源地址即本机地址                                                                                
    unicast_peer {
        192.168.18.8   #对端地址
    }
注：两个或以上VIP分别运行在不同的keepalived服务器，以实现服务器并行提供web访问的目的，提高服务器资源利用率。 

    authentication {       #认证机制
        auth_type PASS
        auth_pass 12345678   #设置的密码仅前8位有效
    }
    virtual_ipaddress {   #虚拟IP,此虚拟vip可以设置成多个，和备份节点配置要一致
        192.168.18.99 dev eth0 label eth0:0
    }
}

```

##### master1

```
cat > /etc/keepalived/keepalived.conf << EOF
! Configuration File for keepalived

global_defs {
    router_id LVS_DEVEL
}

vrrp_script check_haproxy {
    script "killall -0 haproxy"
    interval 3
    weight -2
    fall 10
    rise 2
}

vrrp_instance VIP1 {
    state MASTER
    interface enp2s0f1
    virtual_router_id 51
    priority 150
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass LHCZ@BZ@YQ
    }
    virtual_ipaddress {
        192.168.100.11
    }
    track_script {
        check_haproxy
    }
    
}
EOF
```

##### master2

```
cat > /etc/keepalived/keepalived.conf << EOF
! Configuration File for keepalived

global_defs {
	router_id LVS_DEVEL
}

vrrp_script check_haproxy {
    script "killall -0 haproxy"
    interval 3
    weight -2
    fall 10
    rise 2
}

vrrp_instance VIP1 {
    state BACKUP
    interface enp2s0f1
    virtual_router_id 51
    priority 120
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass LHCZ@BZ@YQ
    }
    virtual_ipaddress {
        192.168.100.11
    }
    track_script {
        check_haproxy
    }

}
EOF
```

##### master3

```
cat > /etc/keepalived/keepalived.conf << EOF
! Configuration File for keepalived

global_defs {
	router_id LVS_DEVEL
}

vrrp_script check_haproxy {
    script "killall -0 haproxy"
    interval 3
    weight -2
    fall 10
    rise 2
}

vrrp_instance VIP1 {
    state BACKUP
    interface enp2s0f1
    virtual_router_id 51
    priority 100
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass LHCZ@BZ@YQ
    }
    virtual_ipaddress {
        192.168.100.11
    }
    track_script {
        check_haproxy
    }

}
EOF
```

```
#配置说明
killall -0 haproxy #根据进程名称检测进程是否存活
bj-ft-vm-master-01节点为MASTER，其余节点为BACKUP
priority各个几点到优先级相差50（直接设置相同，效果相同），范围：0～250（非强制要求）
interface 选择有ip地址的网卡
```

#### 重启服务设置开机启动

```
systemctl restart keepalived
```

```
systemctl enable keepalived
```

```
systemctl enable ipvsadm
```

若ipvsadm出现`/bin/bash: /etc/sysconfig/ipvsadm: No such file or directory`无法启动

```
ipvsadm --save > /etc/sysconfig/ipvsadm
```

再进行重启服务



#### 查看

```
ip address
```

查看主服务器网卡是否有虚拟IP地址



### HAproxy

#### 安装

```
yum install -y haproxy
```

#### 设置haproxy配置文件

```
vim /etc/haproxy/haproxy.cfg
```

```
cat > /etc/haproxy/haproxy.cfg << EOF
#---------------------------------------------------------------------
# Global settings
#---------------------------------------------------------------------
global
    # to have these messages end up in /var/log/haproxy.log you will
    # need to:
    #
    # 1) configure syslog to accept network log events.  This is done
    #    by adding the '-r' option to the SYSLOGD_OPTIONS in
    #    /etc/sysconfig/syslog
    #
    # 2) configure local2 events to go to the /var/log/haproxy.log
    #   file. A line like the following can be added to
    #   /etc/sysconfig/syslog
    #
    #    local2.*                       /var/log/haproxy.log
    #
    log         127.0.0.1 local2

    chroot      /var/lib/haproxy
    pidfile     /var/run/haproxy.pid
    maxconn     40000
    user        haproxy
    group       haproxy
    daemon

    # turn on stats unix socket
    stats socket /var/lib/haproxy/stats

#---------------------------------------------------------------------
# common defaults that all the 'listen' and 'backend' sections will
# use if not designated in their block
#---------------------------------------------------------------------
defaults
    mode                    http
    log                     global
    option                  httplog
    option                  dontlognull
    option http-server-close
    option forwardfor       except 127.0.0.0/8
    option                  redispatch
    retries                 3
    timeout http-request    10s
    timeout queue           1m
    timeout connect         10s
    timeout client          1m
    timeout server          1m
    timeout http-keep-alive 10s
    timeout check           10s
    maxconn                 3000

#---------------------------------------------------------------------
# kubernetes apiserver frontend which proxys to the backends
#---------------------------------------------------------------------
frontend kubernetes-apiserver
    mode                 tcp
    bind                 *:16443
    option               tcplog
    default_backend      kubernetes-apiserver

#---------------------------------------------------------------------
# round robin balancing between the various backends
#---------------------------------------------------------------------
backend kubernetes-apiserver
    mode        tcp
    balance     roundrobin
    server  master-1 192.168.100.3:6443
    server  master-2 192.168.100.4:6443
    server  master-2 192.168.100.5:6443

#---------------------------------------------------------------------
# collection haproxy statistics message
#---------------------------------------------------------------------
listen stats
    bind                 *:1080
    stats auth           admin:awesomePassword
    stats refresh        5s
    stats realm          HAProxy\ Statistics
    stats uri            /admin?stats

EOF
```

###### [三个节点相同]

#### 重启服务并设置开机启动

```
systemctl restart haproxy
```

```
systemctl enable haproxy
```

#### 查看

```
systemctl status haproxy
```

```
ss -lnt | grep -E "16443|1080"
```

 

## 安装Docker

### 卸载旧版本

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

### 安装相关组件

```
yum install -y yum-utils \
  device-mapper-persistent-data \
  lvm2
```

### 配置yum源

```
yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
```

### 安装

```
yum install docker-ce docker-ce-cli containerd.io -y
```

或

#### 查看docker-ce所有可安装版本

```
yum list docker-ce --showduplicates | sort -r
```

#### 安装指定docker版本

```
yum install docker-ce-18.06.1.ce-3.el7 -y
```

### 设置启动项

```
systemctl enable docker
```

### 配置docker阿里源加速器

```
mkdir -p /etc/docker
```

```
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://tsqluof3.mirror.aliyuncs.com"]
}
EOF
```

```
systemctl daemon-reload
```

```
systemctl restart docker
```

### 查看状态

```
systemctl status docker
```

### 选：

#### 配置docker

```
vi /lib/systemd/system/docker.service
```

找到ExecStart=xxx，在这行上面加入一行，内容如下：（实践发现不需要）

```
ExecStartPost=/sbin/iptables -I FORWARD -s 0.0.0.0/0 -j ACCEPT
```

##### 修改docker工作目录路径

```
ExecStart=/usr/bin/docker --graph /apps/docker
```

```
sudo systemctl daemon-reload
```

```
systemctl restart docker
```



## 安装kubernetes

### 安装组件

```
yum install kubeadm-1.13.3-0  kubectl-1.13.3-0  kubelet-1.13.3-0 kubernetes-cni-0.6.0-0 -y
```

```
systemctl enable kubelet
```

查看版本

```
yum list kubelet --showduplicates
```

```
yum list kubeadm --showduplicates
```

```
yum list kubectl --showduplicates
```

安装指定版本

```
yum install kubelet-1.13.3-0 -y
```

### 镜像

#### 查看该版本镜像

```
kubeadm config images list
```

输出

```
k8s.gcr.io/kube-apiserver:v1.13.4
k8s.gcr.io/kube-controller-manager:v1.13.4
k8s.gcr.io/kube-scheduler:v1.13.4
k8s.gcr.io/kube-proxy:v1.13.4
k8s.gcr.io/pause:3.1
k8s.gcr.io/etcd:3.2.24
k8s.gcr.io/coredns:1.2.6
```

#### 镜像拉取脚本

```
echo ""
echo "=========================================================="
echo "Pull Kubernetes v1.13.3 Images from aliyuncs.com ......"
echo "=========================================================="
echo ""

MY_REGISTRY=registry.cn-hangzhou.aliyuncs.com/openthings

## 拉取镜像
docker pull ${MY_REGISTRY}/k8s-gcr-io-kube-apiserver:v1.13.3
docker pull ${MY_REGISTRY}/k8s-gcr-io-kube-controller-manager:v1.13.3
docker pull ${MY_REGISTRY}/k8s-gcr-io-kube-scheduler:v1.13.3
docker pull ${MY_REGISTRY}/k8s-gcr-io-kube-proxy:v1.13.3
docker pull ${MY_REGISTRY}/k8s-gcr-io-etcd:3.2.24
docker pull ${MY_REGISTRY}/k8s-gcr-io-pause:3.1
docker pull ${MY_REGISTRY}/k8s-gcr-io-coredns:1.2.6


## 添加Tag
docker tag ${MY_REGISTRY}/k8s-gcr-io-kube-apiserver:v1.13.3 k8s.gcr.io/kube-apiserver:v1.13.3
docker tag ${MY_REGISTRY}/k8s-gcr-io-kube-scheduler:v1.13.3 k8s.gcr.io/kube-scheduler:v1.13.3
docker tag ${MY_REGISTRY}/k8s-gcr-io-kube-controller-manager:v1.13.3 k8s.gcr.io/kube-controller-manager:v1.13.3
docker tag ${MY_REGISTRY}/k8s-gcr-io-kube-proxy:v1.13.3 k8s.gcr.io/kube-proxy:v1.13.3
docker tag ${MY_REGISTRY}/k8s-gcr-io-etcd:3.2.24 k8s.gcr.io/etcd:3.2.24
docker tag ${MY_REGISTRY}/k8s-gcr-io-pause:3.1 k8s.gcr.io/pause:3.1
docker tag ${MY_REGISTRY}/k8s-gcr-io-coredns:1.2.6 k8s.gcr.io/coredns:1.2.6

echo ""
echo "=========================================================="
echo "Pull Kubernetes v1.13.3 Images FINISHED."
echo "into registry.cn-hangzhou.aliyuncs.com/openthings, "
echo "           by openthings@https://my.oschina.net/u/2306127."
echo "=========================================================="

echo ""
```

### 创建主节点集群

#### master-1节点

##### 测试(会报refuse)

```
nc -v 192.168.240.59 6443
nc -v 192.168.240.60 6443
nc -v 192.168.240.61 6443
```



#### 创建初始化文件

```
vi kubeadm-config.yaml
```

内容为

```
apiVersion: kubeadm.k8s.io/v1beta1
kind: ClusterConfiguration
kubernetesVersion: v1.13.3
controlPlaneEndpoint: "192.168.240.59:6443"
networking:
  podSubnet: "172.16.0.0/16"
```

##### keepalive+haproxy选用:

```
cat > kubeadm-config.yaml << EOF
apiServer:
  certSANs:
    - 192.168.100.11
  extraArgs:
    authorization-mode: Node,RBAC
  timeoutForControlPlane: 4m0s
apiVersion: kubeadm.k8s.io/v1beta1
certificatesDir: /etc/kubernetes/pki
clusterName: kubernetes
controlPlaneEndpoint: "192.168.100.11:16443"
controllerManager: {}
dns:
  type: CoreDNS
etcd:
  local:
    dataDir: /var/lib/etcd
imageRepository: registry.aliyuncs.com/google_containers
kind: ClusterConfiguration
kubernetesVersion: v1.13.3
networking:
  dnsDomain: cluster.local
  podSubnet: 172.16.0.0/16
  serviceSubnet: 172.15.0.0/16
scheduler: {}
EOF
```

```
#配置说明
imageRepository: registry.aliyuncs.com/google_containers #使用阿里云镜像仓库
podSubnet: 10.20.0.0/16 #pod地址池
serviceSubnet: 10.10.0.0/16 #service地址池
```

#### 创建主节点集群

```
kubeadm init --config=kubeadm-config.yaml
```

##### 打印

```
Your Kubernetes master has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

You can now join any number of machines by running the following on each node
as root:

  kubeadm join 192.168.240.59:6443 --token sh7c93.kqtqk7eos8qvpgd6 --discovery-token-ca-cert-hash sha256:eb027d403e256b5fec40cf5085247bb52ae1568351baaa5439f3e2d7be84d93b
```

##### 配置kubectl

```
echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> ~/.bash_profile
```

或

```
export KUBECONFIG=/etc/kubernetes/admin.conf
```

```
source ~/.bash_profile
```

或

```
mkdir -p $HOME/.kube
```

```
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
```

```
chown $(id -u):$(id -g) $HOME/.kube/config
```

##### 创建网络

```
kubectl apply -f https://docs.projectcalico.org/v3.3/getting-started/kubernetes/installation/hosted/rbac-kdd.yaml
```

```
kubectl apply -f https://docs.projectcalico.org/v3.3/getting-started/kubernetes/installation/hosted/kubernetes-datastore/calico-networking/1.7/calico.yaml
```

注:修改calico的ip value为172.16.X.X

##### 证书共享

###### send.sh[master-1执行]

```
USER=root # customizable
CONTROL_PLANE_IPS="192.168.240.60 192.168.240.61"
for host in ${CONTROL_PLANE_IPS}; do
    scp /etc/kubernetes/pki/ca.crt "${USER}"@$host:
    scp /etc/kubernetes/pki/ca.key "${USER}"@$host:
    scp /etc/kubernetes/pki/sa.key "${USER}"@$host:
    scp /etc/kubernetes/pki/sa.pub "${USER}"@$host:
    scp /etc/kubernetes/pki/front-proxy-ca.crt "${USER}"@$host:
    scp /etc/kubernetes/pki/front-proxy-ca.key "${USER}"@$host:
    scp /etc/kubernetes/pki/etcd/ca.crt "${USER}"@$host:etcd-ca.crt
    scp /etc/kubernetes/pki/etcd/ca.key "${USER}"@$host:etcd-ca.key
    scp /etc/kubernetes/admin.conf "${USER}"@$host:
done
```

###### revice.sh[从节点执行]

```
USER=root # customizable
mkdir -p /etc/kubernetes/pki/etcd
mv /${USER}/ca.crt /etc/kubernetes/pki/
mv /${USER}/ca.key /etc/kubernetes/pki/
mv /${USER}/sa.pub /etc/kubernetes/pki/
mv /${USER}/sa.key /etc/kubernetes/pki/
mv /${USER}/front-proxy-ca.crt /etc/kubernetes/pki/
mv /${USER}/front-proxy-ca.key /etc/kubernetes/pki/
mv /${USER}/etcd-ca.crt /etc/kubernetes/pki/etcd/ca.crt
mv /${USER}/etcd-ca.key /etc/kubernetes/pki/etcd/ca.key
mv /${USER}/admin.conf /etc/kubernetes/admin.conf
```

#### master-2、master-3节点

执行revice.sh进行证书共享后

##### 加入master集群

```
kubeadm join 192.168.240.59:6443 --token 8airfo.h524w155v0rxadua --discovery-token-ca-cert-hash sha256:efb6b918827da2e50a939eb821665f29127786224e4f1e7c1bd7f397bb1cec93 --experimental-control-plane
```

##### keepalive+haproxy选用:

```
kubeadm join 192.168.100.11:16443 --token hbzumv.y6axxdil4i7an58v --discovery-token-ca-cert-hash sha256:f0fe12758a25db126a85a68707fbe66bafaa2a41a31f44d3d55d39a17d62d5ff --experimental-control-plane 
```



↑上述token为两小时有效

加入后打印

```
This node has joined the cluster and a new control plane instance was created:

* Certificate signing request was sent to apiserver and approval was received.
* The Kubelet was informed of the new secure connection details.
* Master label and taint were applied to the new node.
* The Kubernetes control plane instances scaled up.
* A new etcd member was added to the local/stacked etcd cluster.

To start administering your cluster from this node, you need to run the following as a regular user:

        mkdir -p $HOME/.kube
        sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
        sudo chown $(id -u):$(id -g) $HOME/.kube/config

Run 'kubectl get nodes' to see this node join the cluster.

```

##### 生成新token[master-1]

```
kubeadm init phase upload-certs --experimental-upload-certs
```

##### 注:token过期后加入集群[从节点适用]

###### 查看token

```
kubeadm token list
```

###### 生成token

```
kubeadm token create
```

打印

```
5didvk.d09sbcov8ph2amjw
```

###### 获取token

```
openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | \
   openssl dgst -sha256 -hex | sed 's/^.* //'
```

打印

```
8cb2de97839780a412b93877f8507ad6c94f73add17d5d7058e91741c9d5ec78
```

#### 可选:主节点加入工作

```
kubectl taint nodes --all node-role.kubernetes.io/master-
```

输出

```\
node/k8s-m untainted
error: taint "node-role.kubernetes.io/master:" not found
```

将主节点从工作节点中脱离

```
kubectl taint node k8s-master node-role.kubernetes.io/master="":NoSchedule
```

### 

### 从节点加入[slave1-slave5]

#### 加入集群

```
kubeadm join 192.168.240.59:6443 --token sh7c93.kqtqk7eos8qvpgd6 --discovery-token-ca-cert-hash sha256:eb027d403e256b5fec40cf5085247bb52ae1568351baaa5439f3e2d7be84d93b
```

打印

```
This node has joined the cluster:
* Certificate signing request was sent to apiserver and a response was received.
* The Kubelet was informed of the new secure connection details.

Run 'kubectl get nodes' on the master to see this node join the cluster.
```



## 卸载kubernetes

```
kubectl drain <node name> --delete-local-data --force --ignore-daemonsets
```

```
kubectl delete node <node name>
```

```
kubeadm reset
```

```
iptables -F && iptables -t nat -F && iptables -t mangle -F && iptables -X
```

```
ipvsadm -C
```

```
yum remove kubeadm-1.13.3-0  kubectl-1.13.3-0  kubelet-1.13.3-0 kubernetes-cni-0.6.0-0 -y
```

```
modprobe -r ipip
rm -rf /etc/kubernetes/
rm -rf /etc/systemd/system/kubelet.service.d
rm -rf /etc/systemd/system/kubelet.service
rm -rf /usr/bin/kube*
rm -rf /etc/cni
rm -rf /opt/cni
rm -rf /var/lib/etcd
rm -rf /var/etcd
```

```
sh /root/delete.sh
```



## 安装DashBoard

### 镜像准备

```
docker pull registry.cn-beijing.aliyuncs.com/minminmsn/kubernetes-dashboard:v1.10.1
```

```
docker tag registry.cn-beijing.aliyuncs.com/minminmsn/kubernetes-dashboard:v1.10.1 k8s.gcr.io/kubernetes-dashboard-amd64:v1.10.1
```

```
docker rmi registry.cn-beijing.aliyuncs.com/minminmsn/kubernetes-dashboard:v1.10.1
```

### 证书生成(1)

#### 生成

```
mkdir certs
```

```
openssl genrsa -des3 -passout pass:x -out dashboard.pass.key 2048
```

```
openssl rsa -passin pass:x -in dashboard.pass.key -out dashboard.key
```

```
rm dashboard.pass.key
```

```
openssl req -new -key dashboard.key -out dashboard.csr
```

反馈输入:

```
...
Country Name (2 letter code) [AU]: US
...
A challenge password []:
...
```

#### 密钥生成

```
openssl x509 -req -sha256 -days 365 -in dashboard.csr -signkey dashboard.key -out dashboard.crt
```

#### 检查

```
ls certs
```

#### 创建

```
kubectl create secret generic kubernetes-dashboard-certs --from-file=certs -n kube-system
```

### 证书生成(2)

#### 生成

````
openssl req -x509 -sha256 -nodes -days 3650 -newkey rsa:2048 -keyout tls.key -out tls.crt -subj "/CN=dashboard.test.local/O=dashboard.test.local"
````

#### 创建

```
kubectl create secret tls kubernetes-dashboard-certs --key tls.key --cert tls.crt -n kube-system
```

### 获取dashboard.yaml

```
wget https://raw.githubusercontent.com/kubernetes/dashboard/master/aio/deploy/recommended/kubernetes-dashboard.yaml
```

注:修改service为NodePort访问

#### 部署

```
kubectl create -f kubernetes-dashboard.yaml 
```

#### 配置dashboard-admin.yaml

```
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: admin
  annotations:
    rbac.authorization.kubernetes.io/autoupdate: "true"
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
subjects:
- kind: ServiceAccount
  name: admin
  namespace: kube-system
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin
  namespace: kube-system
  labels:
    kubernetes.io/cluster-service: "true"
    addonmanager.kubernetes.io/mode: Reconcile
```

```
kubectl apply -f dashboard-admin.yaml
```

### Token获取

```
kubectl describe secret/$(kubectl get secret -nkube-system |grep admin|awk '{print $1}') -n kube-system
```

### 访问

```
https://192.168.240.59
```

选择token进入



## 安装Helm

### helm

```
tar -zxvf helm-v2.13.0-linux-amd64.tar.gz
```

```
mv linux-amd64/helm /usr/local/bin/helm
```

测试

```
helm help
```

### tiller

安装tiller到群集中的最简单方法就是运行

```
helm init
```

安装成功后在kubernetes的pods中查看tiller已为running

### 查看版本

```
helm version
```

打印

```
Client: &version.Version{SemVer:"v2.13.0", GitCommit:"79d07943b03aea2b76c12644b4b54733bc5958d6", GitTreeState:"clean"}
Server: &version.Version{SemVer:"v2.13.0", GitCommit:"79d07943b03aea2b76c12644b4b54733bc5958d6", GitTreeState:"clean"}
```

### 添加服务目录到Helm存储库

```
helm repo add ali https://kubernetes.oss-cn-hangzhou.aliyuncs.com/charts
```

打印

```
"ali" has been added to your repositories
```

使用`helm repo list`查看

### 查看服务

```
helm search service-catalog
```

打印

```
NAME           	CHART VERSION	APP VERSION	DESCRIPTION              
svc-cat/catalog	0.1.42       	           	service-catalog API server and controller-manager helm chart
```

### 启用RBAC

```
kubectl create clusterrolebinding tiller-cluster-admin \
    --clusterrole=cluster-admin \
    --serviceaccount=kube-system:default
```

打印

```
clusterrolebinding.rbac.authorization.k8s.io/tiller-cluster-admin created
```

### 更新helm repo

```
helm repo update
```



## 安装Harbor

```
docker save -o 1.tar goharbor/chartmuseum-photon:dev
docker save -o 2.tar goharbor/clair-photon:dev
docker save -o 3.tar goharbor/harbor-core:dev
docker save -o 4.tar goharbor/harbor-db:dev
docker save -o 5.tar goharbor/harbor-jobservice:dev
docker save -o 6.tar goharbor/notary-server-photon:dev
docker save -o 7.tar goharbor/notary-signer-photon:dev
docker save -o 8.tar goharbor/harbor-portal:dev
docker save -o 9.tar goharbor/redis-photon:dev
docker save -o 10.tar goharbor/registry-photon:dev
```





