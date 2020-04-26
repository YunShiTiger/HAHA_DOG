source ~/.bash_profile ;

echo "I want to Fuck THE World!" ;
echo "##########;" ;

cd /root/test/suede ;
VERSION=`date "+%F-%H-%M"` ;
mv /var/lib/jenkins/workspace/suede /root/test/suede/;
docker build -t 192.168.240.73/test/suede:$VERSION . ;
rm -rf /root/test/suede/suede ;
docker push 192.168.240.73/test/suede:$VERSION ;
sed -i '15c \        \image: 192.168.240.73/test/suede:'$VERSION /root/test/suede/suede.yaml ;
kubectl apply -f /root/test/suede/suede.yaml --record ;

echo "##########" ;
echo "I have Fucked The World!" ;
