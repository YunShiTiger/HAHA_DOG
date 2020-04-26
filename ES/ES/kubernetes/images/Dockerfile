FROM docker.elastic.co/elasticsearch/elasticsearch:6.6.2

COPY run.sh /

COPY ik /usr/share/elasticsearch/plugins/ik

RUN chmod 775 /run.sh

CMD ["/run.sh"]

