# ActiveMQ

## Run

```
docker run -dt --name actiivemq -p 30003:61616 -p 30004:8161 activemq
```

### 注:

#### 端口

```
61616：客户端连接ActiveMQ的端口
8161：管理界面端口
```

#### 如果不设置，默认的账号名和密码为：

```
admin:admin admin #管理员权限
user:user user #用户权限
```

### 修改默认密码

- 由于基础镜像不支持`vi`，因此只有将文件拷贝出来

  

  ```ruby
  docker cp {container}:/opt/activemq/conf/jetty-realm.properties /root/jetty-realm.properties
  ```

- 删除`user`用户，修改`admin`用户的密码

  

  ```undefined
  admin: {password}, admin
  ```

- 替换文件

  

  ```ruby
  docker cp /root/jetty-realm.properties {container}:/opt/activemq/conf/jetty-realm.properties 
  ```

重启容器，访问`http://IP:8161`管理界面