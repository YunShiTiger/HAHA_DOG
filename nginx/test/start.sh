kubectl create configmap test-conf --from-file=nginx.conf
kubectl apply -f nginx.yaml
