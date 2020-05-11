# EFK[Filebeat]

```
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: filebeat-config
  labels:
    k8s-app: filebeat
data:
  filebeat.yml: |-
    filebeat.inputs:
    - type: log
      paths:
        - /logdata/*.log
      tail_files: true
      fields:
        pod_name: '${pod_name}'
        POD_IP: '${POD_IP}'
    setup.ilm.enabled: false
    setup.template.name: "nginx-test"
    setup.template.pattern: "nginx-test-"
    output.elasticsearch:
      hosts: ["http://202.107.190.8:10381"]
      username: "elastic"
      password: "8gkfcr67l2w7knbgbqhssn26"
      index: "nginx-test-log"
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-test-config
  labels:
    k8s-app: nginx-test-config
data:
  nginx-test-config: |-
    # log_format access '[$time_local] - '
    log_format access '[$request] - '
                      '[$status]';
    server {
        listen       80;
        server_name  localhost;
        access_log  /logdata/access.log  access;
        location / {
            root   /usr/share/nginx/html;
            index  index.html index.htm;
        }
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   /usr/share/nginx/html;
        }
    }

---
apiVersion: apps/v1
kind: Deployment  
metadata: 
  name: nginx-log
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx-log
  template:
    metadata:
      labels:
        app: nginx-log
    spec:
      containers:
      - name: nginx
        image: nginx:local
        ports:
        - containerPort: 80
          protocol: TCP
        resources: {}
        volumeMounts:
        - name: logdata
          mountPath: /logdata
        - name: nginx-test-config
          mountPath:  /etc/nginx/conf.d/
      - name: filebeat
        image: filebeat:7.6.1-local
        args: [
          "-c", "/opt/filebeat/filebeat.yml",
          "-e",
        ]
        env:
        - name: POD_IP
          valueFrom:
            fieldRef:
              apiVersion: v1
              fieldPath: status.podIP
        - name: pod_name
          valueFrom:
            fieldRef:
              apiVersion: v1
              fieldPath: metadata.name
        - name: ELASTICSEARCH_HOST
          value: 202.107.190.8
        - name: ELASTICSEARCH_PORT
          value: "10381"
        - name: ELASTICSEARCH_USERNAME
          value: elastic
        - name: ELASTICSEARCH_PASSWORD
          value: x5ph5xhk7jtdzpmbqbbdlfzk
        securityContext:
          runAsUser: 0
        resources:
          limits:
            memory: 200Mi
          requests:
            cpu: 100m
            memory: 100Mi
        volumeMounts:
        - name: config
          mountPath: /opt/filebeat/
        - name: data
          mountPath: /usr/share/filebeat/data
        - name: logdata
          mountPath: /logdata
      volumes:
      - name: nginx-test-config
        configMap:
          name: nginx-test-config
          items:
          - key: nginx-test-config
            path: test.conf
      - name: logdata
        emptyDir: {}
      - name: config
        configMap:
          name: filebeat-config
          items:
          - key: filebeat.yml
            path: filebeat.yml
      - name: data
        emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-log
spec:
  selector:
    app: nginx-log
  type: NodePort
  ports:
    - nodePort: 30003
      port: 80
      targetPort: 80
```