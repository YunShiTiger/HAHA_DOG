# BeeGO

## 创建和运行

### 查看工作目录

```
$GOPATH/src
```

### 创建

```
bee new quickstart
```

### 运行

#### 进入工作目录中的项目

```
cd $GOPATH/src
cd quickstart
```

#### 运行①

```
bee run
```

#### 运行②

在工作目录(项目外)

```
bee run quickstart
```

#### 查看端口

```
lsof -i tcp:port
```

#### 杀进程

```
kill PID
```



## 路由设置

