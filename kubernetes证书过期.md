# kubernetes证书过期

## 查看证书日期

```
cd /etc/kubernetes/pki
```

```
openssl x509 -in apiserver.crt -noout -text  |grep Not
```

## 备份证书

```
cp -r /etc/kubernetes/pki /root/k8s-pki-bak/
```

## 准备kubeadm.conf 配置文件一份

```
kind: ClusterConfiguration
kubernetesVersion: v1.13.3
controlPlaneEndpoint: "192.168.240.59:6443"
networking:
  podSubnet: "172.30.0.0/16"
imageRepository: registry.cn-hangzhou.aliyuncs.com/google_containers 
```

## 重新签发命令

```
kubeadm alpha certs renew all --config=kubeadm-config.yaml
```

```
kubeadm init phase kubeconfig all --config kubeadm-config.yaml
```

```
systemctl restart docker kubelet
```