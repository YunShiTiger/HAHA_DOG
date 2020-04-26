source ~/.bash_profile ;

echo "I want to Fuck THE World!" ;
echo "##########;" ;

cd /root/test/liam ;
VERSION=`date "+%F-%H-%M"` ;
cp /var/lib/jenkins/workspace/liam/target/liam.jar /root/test/liam/;
rm -rf /var/lib/jenkins/workspace/liam/target/liam.jar ;
docker build -t 192.168.240.73/test/liam:$VERSION . ;
rm -rf /root/test/liam/liam.jar ;
docker push 192.168.240.73/test/liam:$VERSION ;
sed -i '15c \        \image: 192.168.240.73/test/liam:'$VERSION /root/test/liam/liam.yaml ;
kubectl apply -f /root/test/liam/liam.yaml --record ;

echo "##########" ;
echo "I have Fucked The World!" ;
