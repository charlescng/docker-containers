#!/bin/bash

while [ ! -f /opt/observium/config.php ] || ! mariadb -uroot -e "SELECT 1" >/dev/null 2>&1; do
    sleep 2
done

exec /opt/observium/syslog.php
