#!/bin/bash

logger -t syslog-wait "waiting for Observium config and database"
while [ ! -f /opt/observium/config.php ] || ! mariadb -uroot -e "SELECT 1" >/dev/null 2>&1; do
    sleep 2
done

logger -t syslog-wait "ready after ${SECONDS}s, starting syslog.php"
exec /opt/observium/syslog.php
