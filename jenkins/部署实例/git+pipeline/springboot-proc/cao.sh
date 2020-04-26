echo "I want to Fuck THE World!" ;
echo "##########;" ;

VERSION=`date "+%F-%H-%M"` ;
cd /var/lib/jenkins/workspace/end-test/ ;
docker build -t 192.168.100.7/bzyq/end-test:$VERSION . ;
docker push 192.168.100.7/bzyq/end-test:$VERSION ;
sed -i '14c \          \image: 192.168.100.7/bzyq/end-test:'$VERSION end-test.yaml  ;
scp -P 2223 end-test.yaml 192.168.100.3:/root/Deploy/end-test/end-test.yaml

ssh -p 2223 -Tq 192.168.100.3 << 'EOF'
export KUBECONFIG=/etc/kubernetes/admin.conf ;
source ~/.bash_profile ;
kubectl apply -f /root/Deploy/end-test/end-test.yaml --record ;
exit
EOF

echo "##########" ;
echo "I have Fucked The World!" ;

