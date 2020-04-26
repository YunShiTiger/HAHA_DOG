

# Redis(Docker集群模式)

### 所在机器及端口

```
59.212.147.44:6379
59.212.147.45:6380
59.212.147.46:6381
59.212.147.62:6382
59.212.147.63:6383
59.212.147.64:6384
```



### 配置文件(最简配置)

```
appendonly yes
cluster-enabled yes
cluster-config-file /etc/redis/nodes.conf
cluster-node-timeout 5000
dir /data
port 6379
bind 59.212.147.44
masterauth 123123 
requirepass 123123
```



### 运行

```
docker run -dt -p 6379:6379 -p 16379:16379 --name redis-01 --restart unless-stopped --net redis-network --ip 172.23.0.2 -v /home/data/redis/redis.conf:/etc/redis/redis.conf -v /home/data/redis/data:/data 59.212.147.64:5000/redis:6.0 redis-server /etc/redis/redis.conf --appendonly yes
```

### 集群设置

```
docker run -dt --name RedisCentos centos:redis
```

```
docker exec -it RedisCentos /bin/bash
```

#### 编辑集群创建脚本

```
vi /usr/local/rvm/gems/ruby-2.3.3/gems/redis-4.0.0/lib/redis/client.rb
```

```
/redis-trib.rb create --replicas 1 172.23.0.2:6379 172.23.0.3:6380 172.23.0.4:6381 172.23.0.5:6382 172.23.0.6:6383 172.23.0.7:6384
```

### 测试

```
/usr/local/bin/redis-cli -c -h 59.212.147.64 -p 6379 -a 123456
```

#### 输入测试数据

```
set name test
```

```
get name
```

##### 查看所有数据

```
keys *
```

### 清空测试数据

```
flushall
```



















```
docker run -dt -p 6379:6379 -p 16379:16379 --name redis-01 --restart unless-stopped --net redis-network --ip 172.23.0.2 -v /home/data/redis/redis.conf:/etc/redis/redis.conf -v /home/data/redis/data:/data 59.212.147.64:5000/redis:6.0 redis-server /etc/redis/redis.conf --appendonly yes
```

```
docker run -dt -p 6379:6379 -p 16379:16379 --name redis-02 --restart unless-stopped --net redis-network --ip 172.23.0.3 -v /home/data/redis/redis.conf:/etc/redis/redis.conf -v /home/data/redis/data:/data 59.212.147.64:5000/redis:6.0 redis-server /etc/redis/redis.conf --appendonly yes
```

```
docker run -dt -p 6379:6379 -p 16379:16379 --name redis-03 --restart unless-stopped --net redis-network --ip 172.23.0.4 -v /home/data/redis/redis.conf:/etc/redis/redis.conf -v /home/data/redis/data:/data 59.212.147.64:5000/redis:6.0 redis-server /etc/redis/redis.conf --appendonly yes
```

```
docker run -dt -p 6379:6379 -p 16379:16379 --name redis-04 --restart unless-stopped --net redis-network --ip 172.23.0.5 -v /home/data/redis/redis.conf:/etc/redis/redis.conf -v /home/data/redis/data:/data 59.212.147.64:5000/redis:6.0 redis-server /etc/redis/redis.conf --appendonly yes
```

```
docker run -dt -p 6379:6379 -p 16379:16379 --name redis-05 --restart unless-stopped --net redis-network --ip 172.23.0.6 -v /home/data/redis/redis.conf:/etc/redis/redis.conf -v /home/data/redis/data:/data 59.212.147.64:5000/redis:6.0 redis-server /etc/redis/redis.conf --appendonly yes
```

```
docker run -dt -p 6379:6379 -p 16379:16379 --name redis-06 --restart unless-stopped --net redis-network --ip 172.23.0.7 -v /home/data/redis/redis.conf:/etc/redis/redis.conf -v /home/data/redis/data:/data 59.212.147.64:5000/redis:6.0 redis-server /etc/redis/redis.conf --appendonly yes
```





```
/redis-trib.rb create --replicas 1 59.212.147.44:6379 59.212.147.45:6379 59.212.147.46:6379 59.212.147.62:6379 59.212.147.63:6379 59.212.147.64:6379
```



```
>>> Nodes configuration updated
>>> Assign a different config epoch to each node
>>> Sending CLUSTER MEET messages to join the cluster
Waiting for the cluster to join.
```

