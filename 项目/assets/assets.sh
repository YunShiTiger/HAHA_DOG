source ~/.bash_profile ;
echo "I want to Fuck THE World!" ;
echo "##########;" ;

VERSION=`date "+%F-%H-%M"` ;

docker run -dt --name ZZZ registry.cn-qingdao.aliyuncs.com/caonima/tomcat:7.0.92-jre8-alpine ;
docker cp /var/lib/jenkins/workspace/assets/target/assets.war ZZZ:/usr/local/tomcat/webapps/ ;
rm -rf /var/lib/jenkins/workspace/assets/target/assets.war ;
rm -rf /var/lib/jenkins/workspace/assets/target/assets ;
docker stop ZZZ ;
docker commit ZZZ registry.cn-qingdao.aliyuncs.com/caonima/assets:$VERSION ;
docker push registry.cn-qingdao.aliyuncs.com/caonima/assets:$VERSION ;
docker rm ZZZ ;

sed -i '14c \        \image: registry.cn-qingdao.aliyuncs.com/caonima/assets:'$VERSION /root/assets/assets.yml ;
kubectl apply -f /root/assets/assets.yml --record ;
echo "##########" ;
echo "I have Fucked The World!" ;
