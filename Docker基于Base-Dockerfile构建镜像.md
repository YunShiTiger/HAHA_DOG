# Docker基于Base-Dockerfile构建镜像

## 解决问题：

***1. 翻墙下不到镜像***

***2. 镜像地址是带 digest 引用的，直接用 Docker tag 其实是解决不了问题的，如下会报*refusing to create a tag with a digest reference*的错误：***

```
docker tag doopymc/knative-queue gcr.io/knative-releases/queue-7204c16e44715cd30f78443fb99e0f58@sha256:2e26a33aaf0e21db816fb75ea295a323e8deac0a159e8cf8cffbefc5415f78f1
```

打印

```
refusing to create a tag with a digest reference
```



## 步骤：

***1. 将docker hub 与 github做关联***

***2. 在github上创建仓库***

***3. 创建Dockerfile并上传至github***

*Dockerfile:*

```
FROM gcr.io/knative-releases/knative.dev/serving/cmd/activator@sha256:3b530bbcf892aff098444ae529a9d4150dfd0cd35c97babebd90eedae34ad8af
MAINTAINER hatchin
```

***4. 在docker hub上创建仓库然后选择github-connect***

***5.等待构建成功***



