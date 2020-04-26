source ~/.bash_profile ;
echo "I want to Fuck THE World!" ;
echo "##########;" ;

VERSION=`date "+%F"` ;

docker run -dt --name ZZZ registry.cn-qingdao.aliyuncs.com/caonima/tomcat7:1.8-redis ;
docker cp /var/lib/jenkins/workspace/FuckWorld/target/fuck-world.war ZZZ:/usr/local/tomcat/webapps/ ;
rm -rf /var/lib/jenkins/workspace/FuckWorld/target/fuck-world.war ;
rm -rf /var/lib/jenkins/workspace/FuckWorld/target/fuck-world ;
docker stop ZZZ ;
docker commit ZZZ registry.cn-qingdao.aliyuncs.com/caonima/fuck-world:$VERSION ;
docker push registry.cn-qingdao.aliyuncs.com/caonima/fuck-world:$VERSION ;
docker rm ZZZ ;

sed -i '14c \        \image: registry.cn-qingdao.aliyuncs.com/caonima/fuck-world:'$VERSION /root/FuckWorld/fuck-world.yml ;
kubectl apply -f /root/FuckWorld/fuck-world.yml --record ;
echo "##########" ;
echo "I have Fucked The World!" ;
