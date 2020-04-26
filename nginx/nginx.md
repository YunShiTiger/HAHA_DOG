# Nginx

## 配置文件

容器内路径为:`/etc/nginx/conf.d/*.conf;`

```
server {
    listen       30306;
    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
        proxy_pass http://192.168.159.131:31000;
    }

    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
     root   /usr/share/nginx/html;
    }
}

```

```
a）转发到后端Tomcat

 

      location /location名称/ {
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_pass http://127.0.0.1:8080/服务名/;
      }
tomcat的转发是很简单的了，这里不需要多说。
```



### 创建configmap

```
kubectl create configmap nginx-conf --from-file=nginx.conf
```

```
kubectl delete configmap nginx-conf
```



## 部署nginx

```
apiVersion: apps/v1beta1
kind: Deployment
metadata:
  name: nginx-proxy
spec:
  replicas: 5
  template:
    metadata:
      labels:
        run: nginx-proxy
    spec:
      containers:
      - name: nginx-proxy
        image: 192.168.188.77:5000/nginx:k8s
        ports:
        - containerPort: 31002
        volumeMounts:
        - name: "nginx-conf"
          mountPath: "/etc/nginx/conf.d/"
      volumes:
      - name: "nginx-conf"
        configMap:
          name: "nginx-conf"
          items:  
            - key: "nginx.conf"
              path: "nginx.conf"

---
apiVersion: v1
kind: Service
metadata:
  name: nginx-proxy
spec:
  selector:
    run: nginx-proxy
  type: NodePort
  ports:
  - nodePort: 31002
    port: 31002
    targetPort: 31002
```

```
kubectl apply -f nginx.yaml
```



## 多节点跳转

```
server {
listen       31003;

    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
        proxy_pass http://192.168.159.131:31000;
    }

    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
     root   /usr/share/nginx/html;
    }
}

server {
listen       31004;

    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
        proxy_pass http://39.105.150.112:3001;
    }

    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
     root   /usr/share/nginx/html;
    }
}

server {
listen       31005;

    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
        proxy_pass http://39.105.150.112:3002;
    }

    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
     root   /usr/share/nginx/html;
    }
}
```



```
apiVersion: apps/v1beta1
kind: Deployment
metadata:
  name: nginx-proxy-many
spec:
  replicas: 5
  template:
    metadata:
      labels:
        run: nginx-proxy-many
    spec:
      containers:
      - name: nginx-proxy-many
        image: 192.168.188.77:5000/nginx:k8s
        ports:
        - containerPort: 31003
        - containerPort: 31004
        - containerPort: 31005
        volumeMounts:
        - name: "nginx-many-conf"
          mountPath: "/etc/nginx/conf.d/"
      volumes:
      - name: "nginx-many-conf"
        configMap:
          name: "nginx-many-conf"
          items:  
            - key: "nginx-many.conf"
              path: "nginx.conf"

---
apiVersion: v1
kind: Service
metadata:
  name: nginx-proxy-many
spec:
  selector:
    run: nginx-proxy-many
  type: NodePort
  ports:
  - name: cao
    nodePort: 31003
    port: 31003
    targetPort: 31003
  - name: caoni
    nodePort: 31004
    port: 31004
    targetPort: 31004
  - name: caonima
    nodePort: 31005
    port: 31005
    targetPort: 31005
```



## SSL

### 创建私钥

```
openssl genrsa -out server.key 1024
```

### 证书请求

```
openssl req -new -out server.csr -key server.key
```

//填写信息，注意！！将Common Name (eg, your name or your server's hostname行填写成服务器的IP地址)

### 自签署证书

```
openssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt
```

### 将证书变成浏览器支持的.p12格式

```
openssl pkcs12 -export -clcerts -in server.crt -inkey server.key -out server.p12
```

### 由于创建私钥后，每次开启nginx都需输入密码，用以下命令即可无需输入

```
cp server.key server.key.org
```

```
openssl rsa -in server.key.org -out server.key
```

### nginx配置

```
server {
listen       30015;
ssl on;
root html;
index index.html index.htm;
#ssl_certificate   cert/server.pem;
#或者
ssl_certificate  /home/server.crt;
ssl_certificate_key  /home/server.key;
ssl_session_timeout 5m;
ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE:ECDH:AES:HIGH:!NULL:!aNULL:!MD5:!ADH:!RC4;
#ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
ssl_protocols SSLv2 SSLv3 TLSv1;
ssl_prefer_server_ciphers on;
    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
        proxy_pass http://192.168.100.11:30012;
                    proxy_http_version 1.1;
        proxy_connect_timeout 600;
        proxy_read_timeout 600;
        proxy_send_timeout 600;
	    	proxy_set_header Upgrade $http_upgrade;
	    	proxy_set_header Connection "upgrade";
    }

    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
     root   /usr/share/nginx/html;
    }
}


```

```
apiVersion: apps/v1beta1
kind: Deployment
metadata:
  name: nginx-ssl
spec:
  replicas: 5
  template:
    metadata:
      labels:
        run: nginx-ssl
    spec:
      containers:
      - name: nginx-ssl
        image: nginx
        ports:
        - containerPort: 30015
        volumeMounts:
        - name: "nginx-ssl-conf"
          mountPath: "/etc/nginx/conf.d/"
        volumeMounts:
        - name: "server-crt"
          mountPath: "/root"
        volumeMounts:
        - name: "server-key"
          mountPath: "/home"
      volumes:
      - name: "nginx-ssl-conf"
        configMap:
          name: "nginx-ssl-conf"
          items:  
            - key: "nginx.conf"
              path: "nginx.conf"
      - name: "server-crt"
        configMap:
          name: "server-crt"
          items:
            - key: "server.crt"
              path: "server.crt"
      - name: "server-key"
        configMap:
          name: "server-key"
          items:
            - key: "server.key"
              path: "server.key"

---
apiVersion: v1
kind: Service
metadata:
  name: nginx-ssl
spec:
  selector:
    run: nginx-ssl
  type: NodePort
  ports:
  - name: nginx-ssl
    nodePort: 30015
    port: 30015
    targetPort: 30015

```



## 文件系统

### 配置文件

```
server {
    listen       10250;
    server_name  localhost;

    #charset koi8-r;
    #access_log  /var/log/nginx/host.access.log  main;

    root   /data/data/;

    location / {
         autoindex on;             #开启索引功能
         autoindex_exact_size off; # 关闭计算文件确切大小（单位bytes），只显示大概大小（单位kb、mb、gb）
         autoindex_localtime on;   # 显示本机时间而非 GMT 时间
         charset utf-8; # 避免中文乱码
         # root   /data/data/videos/;
         # index  index.html index.htm;
    }

    #error_page  404              /404.html;

    # redirect server error pages to the static page /50x.html
    #
    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }

    # proxy the PHP scripts to Apache listening on 127.0.0.1:80
    #
    #location ~ \.php$ {
    #    proxy_pass   http://127.0.0.1;
    #}

    # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
    #
    #location ~ \.php$ {
    #    root           html;
    #    fastcgi_pass   127.0.0.1:9000;
    #    fastcgi_index  index.php;
    #    fastcgi_param  SCRIPT_FILENAME  /scripts$fastcgi_script_name;
    #    include        fastcgi_params;
    #}

    # deny access to .htaccess files, if Apache's document root
    # concurs with nginx's one
    #
    #location ~ /\.ht {
    #    deny  all;
    #}
}

```







