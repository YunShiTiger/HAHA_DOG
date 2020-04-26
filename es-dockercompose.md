## docker-compose

### 编辑/etc/sysctl.conf 

```
vi /etc/sysctl.conf
```

加入

```
vm.max_map_count = 262144
```

实时设置

```
sysctl -w vm.max_map_count=262144
```



### 编辑docker-compose.yaml

```
version: '2.2'
services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:6.6.2
    container_name: elasticsearch
    environment:
      - cluster.name=docker-cluster
      - bootstrap.memory_lock=true
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    ulimits:
      memlock:
        soft: -1
        hard: -1
    volumes:
      - esdata1:/usr/share/elasticsearch/data
    ports:
      - 9200:9200
    networks:
      - esnet
  elasticsearch2:
    image: docker.elastic.co/elasticsearch/elasticsearch:6.6.2
    container_name: elasticsearch2
    environment:
      - cluster.name=docker-cluster
      - bootstrap.memory_lock=true
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
      - "discovery.zen.ping.unicast.hosts=elasticsearch"
    ulimits:
      memlock:
        soft: -1
        hard: -1
    volumes:
      - esdata2:/usr/share/elasticsearch/data
    networks:
      - esnet

volumes:
  esdata1:
    driver: local
  esdata2:
    driver: local

networks:
  esnet:
```

#### 启动

```
docker-compose up
```

#### 停止

```
docker-compose down
```

#### 删除数据+停止

```
docker-compose down -v
```

#### 检查集群的状态

```
curl http://127.0.0.1:9200/_cat/health
```

或者用logs

#### 安装插件

##### 进入容器

```
docker exec -it elasticsearch /bin/bash
```

##### 安装插件

```
./bin/elasticsearch-plugin install https://github.com/medcl/elasticsearch-analysis-ik/releases/download/v6.6.2/elasticsearch-analysis-ik-6.6.2.zip
```

##### 重启

```
docker-compose restart
```



# Kibana

```
docker run -d --name kibana -e ELASTICSEARCH_URL=http://192.168.240.73:10000 -p 10001:5601 docker.elastic.co/kibana/kibana:6.6.2
```

```
或者用docker-compose
```

