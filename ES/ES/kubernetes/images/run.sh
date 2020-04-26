ulimit -l unlimited

exec su elasticsearch /usr/local/bin/docker-entrypoint.sh
