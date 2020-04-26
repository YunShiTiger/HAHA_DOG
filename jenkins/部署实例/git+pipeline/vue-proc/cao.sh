echo "I want to Fuck THE World!" ;
echo "##########;" ;

ssh -p 2223 -Tq 192.168.100.3 << 'EOF'
mkdir -p /root/Deploy/front-test/ ;
exit
EOF

VERSION=`date "+%F-%H-%M"` ;
cd /var/lib/jenkins/workspace/front-test/ ;
docker build -t 192.168.100.7/bzyq/front-test:$VERSION . ;
docker push 192.168.100.7/bzyq/front-test:$VERSION ;
sed -i '14c \          \image: 192.168.100.7/bzyq/front-test:'$VERSION front-test.yaml  ;
scp -P 2223 front-test.yaml 192.168.100.3:/root/Deploy/front-test/front-test.yaml

ssh -p 2223 -Tq 192.168.100.3 << 'EOF'
export KUBECONFIG=/etc/kubernetes/admin.conf ;
source ~/.bash_profile ;
kubectl apply -f /root/Deploy/front-test/front-test.yaml --record ;
exit
EOF

echo "##########" ;
echo "I have Fucked The World!" ;
