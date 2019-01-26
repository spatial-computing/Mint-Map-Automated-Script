#!/usr/bin/env bash
################################################################################
# Parse the command.
################################################################################

case "$1" in
  start)
    docker run --rm -d -v /data:/data -p 127.0.0.1:8080:80 klokantech/tileserver-gl > /data/container.id
    ;;
  stop)
    docker stop $(cat /data/container.id)
    rm -rf /data/container.id
    ;;
  status)
    docker ps
    ;;
  restart)
    docker restart $(cat /data/container.id)
    ;;
  *)
  echo "\033[31;5;148mError\033[39m: usage $0 { start | stop | restart | status }"
  exit 1
esac

exit 0