kubectl create configmap nginx-ssl-conf --from-file=nginx.conf
kubectl apply -f nginx.yaml
