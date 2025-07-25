#!/bin/sh

umask ${UMASK}

if [ "$1" = "version" ]; then
  ./iNoi version
else
  if [ "$RUN_ARIA2" = "true" ]; then
   cp -a /opt/service/stop/aria2 /opt/service/start 2>/dev/null
  fi

  chown -R ${PUID}:${PGID} /opt/inoi/
  exec su-exec ${PUID}:${PGID} ./iNoi server --no-prefix
fi