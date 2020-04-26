FROM tomcat:8-jre8-alpine
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
ADD target/liam.jar /liam.jar
RUN sh -c 'touch / liam.jar'
ENTRYPOINT [ "sh", "-c", "java -jar /liam.jar" ]
