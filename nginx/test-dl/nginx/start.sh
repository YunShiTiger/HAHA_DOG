kubectl create configmap dl-connect-conf --from-file=nginx.conf
kubectl apply -f nginx.yaml
