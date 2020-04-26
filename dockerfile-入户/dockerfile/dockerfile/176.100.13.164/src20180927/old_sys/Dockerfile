FROM daocloud.io/library/java:8u40-b22
COPY . /usr/src/SyncInFromOut
RUN chmod u+x /usr/src/SyncInFromOut/entrypoint.sh
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
ENTRYPOINT ["/usr/src/SyncInFromOut/entrypoint.sh"]
