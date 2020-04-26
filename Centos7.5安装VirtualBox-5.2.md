

```
 ./genymotion-3.0.2-linux_x64.bin 
```

```
docker run -dt --name zzz --privileged=true vbox
```



```
 ./genymotion-3.0.2-linux_x64.bin  --uninstall
```



## Centos7.5安装VirtualBox-5.2

### 查看自己的内核版本

```
rpm -qa |grep kernel
```

### 查看yum中VirtualBox版本

```
yum list | grep VirtualBox
```

### 导入epel安装源

```
yum install epel-release -y
```

### 添加VirtualBox安装源

```
cd /etc/yum.repos.d/
```

```
wget http://download.virtualbox.org/virtualbox/rpm/rhel/virtualbox.repo 
```

### 安装相关依赖包

```
yum update
```

```
yum install binutils qt gcc make patch libgomp glibc-headers glibc-devel kernel-headers kernel-devel dkms -y
```

### 查看内核

```
 rpm -qa |grep kernel
```

### 安装VirtualBox

```
yum list | grep VirtualBox
```

```
yum install VirtualBox-6.0.x86_64 -y
```

```
warning: VirtualBox-6.0-6.0.8_130520_el7-1.x86_64.rpm: Header V4 DSA/SHA1 Signature, key ID 98ab5139: NOKEY
Preparing...                          ################################# [100%]
Updating / installing...
   1:SDL-1.2.15-14.el7                ################################# [ 50%]
   2:VirtualBox-6.0-6.0.8_130520_el7-1################################# [100%]

Creating group 'vboxusers'. VM users must be member of that group!

This system is currently not set up to build kernel modules.
Please install the Linux kernel "header" files matching the current kernel
for adding new hardware support to the system.
The distribution packages containing the headers are probably:
    kernel-devel kernel-devel-3.10.0-693.el7.x86_64
This system is currently not set up to build kernel modules.
Please install the Linux kernel "header" files matching the current kernel
for adding new hardware support to the system.
The distribution packages containing the headers are probably:
    kernel-devel kernel-devel-3.10.0-693.el7.x86_64

There were problems setting up VirtualBox.  To re-start the set-up process, run
  /sbin/vboxconfig
as root.  If your system is using EFI Secure Boot you may need to sign the
kernel modules (vboxdrv, vboxnetflt, vboxnetadp, vboxpci) before you can load
them. Please see your Linux system's documentation for more information.
```

### 启动

```
VirtualBox
```

打印出

```
WARNING: The vboxdrv kernel module is not loaded. Either there is no module
         available for the current kernel (3.10.0-693.el7.x86_64) or it failed to
         load. Please recompile the kernel module and install it by

           sudo /sbin/vboxconfig

         You will not be able to start VMs until this problem is fixed.
Qt FATAL: QXcbConnection: Could not connect to display 
Aborted (core dumped)
```

↑内核不行 太高了

### 重建内核

```
/usr/lib/virtualbox/vboxdrv.sh setup
```

### 重启

```
systemctl restart vboxdrv.service
```

### 查看状态

```
systemctl status vboxdrv.service
```



```
https://www.cnblogs.com/hongdada/p/9578849.html
```



先装一套gcc

然后装个m4

最后装

```
https://www.cnblogs.com/freeweb/p/5990860.html
```

```
https://www.jianshu.com/p/92c7a042d8ba
```

```
https://blog.csdn.net/sinat_24820331/article/details/53895244
```

```
https://blog.csdn.net/sinat_24820331/article/details/53895244
```









