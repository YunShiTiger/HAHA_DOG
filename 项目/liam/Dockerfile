FROM tomcat:8-jre8-alpine 
VOLUME /tmp 
ADD  liam.jar   /liam.jar
RUN sh -c 'touch / liam.jar'
ENTRYPOINT [ "sh", "-c", "java -jar /liam.jar" ] 
