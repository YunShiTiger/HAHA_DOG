FROM jdk8 
VOLUME /tmp 
ADD  apkDownload.jar   /apkDownload.jar
RUN sh -c 'touch / apkDownload.jar'
ENTRYPOINT [ "sh", "-c", "java -jar /apkDownload.jar" ]
