FROM daocloud.io/library/java:8u40-b22
COPY . /usr/src/SyncUserZoneToIn
RUN chmod u+x /usr/src/SyncUserZoneToIn/entrypoint.sh
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
ENTRYPOINT ["/usr/src/SyncUserZoneToIn/entrypoint.sh"]
