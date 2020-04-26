FROM daocloud.io/library/java:8u40-b22
COPY . /usr/src/writer
RUN chmod u+x /usr/src/writer/entrypoint.sh
ENTRYPOINT ["/usr/src/writer/entrypoint.sh"]
