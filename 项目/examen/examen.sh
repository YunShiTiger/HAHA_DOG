source ~/.bash_profile ;
echo "I want to RI NI DIE" ;
echo "##########;" ;

VERSION=`date "+%F-%H-%M"` ;

docker run -dt --name ZZZ docker.io/tomcat:7.0.90-jre8-alpine;
docker cp /var/lib/jenkins/workspace/RND/target/examen.war ZZZ:/usr/local/tomcat/webapps/ ;
rm -rf /var/lib/jenkins/workspace/RND/target/examen.war ;
rm -rf /var/lib/jenkins/workspace/RND/target/examen ;
docker stop ZZZ ;
docker commit ZZZ registry.cn-qingdao.aliyuncs.com/caonima/examen:$VERSION ;
docker push registry.cn-qingdao.aliyuncs.com/caonima/examen:$VERSION ;
docker rm ZZZ ;

sed -i '14c \        \image: registry.cn-qingdao.aliyuncs.com/caonima/examen:'$VERSION /root/examen/examen.yml ;
kubectl apply -f /root/examen/examen.yml --record ;
echo "##########" ;
echo "I have RI NI DIE" ;
