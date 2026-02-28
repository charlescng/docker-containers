#!/bin/bash
start_mariadb(){
    /usr/bin/mariadbd-safe --datadir=/config/databases > /dev/null 2>&1 &
    RET=1
    while [[ RET -ne 0 ]]; do
        mariadb -uroot -e "status" > /dev/null 2>&1
        RET=$?
        sleep 1
    done
}

# If databases do not exist, create them
if [ -f /config/databases/observium/users.ibd ]; then
  echo "Database exists."
else
  echo "Initializing Data Directory."
  /usr/bin/mariadb-install-db --datadir=/config/databases >/dev/null 2>&1
  echo "Installation complete."
  start_mariadb
  echo "Creating database."
  mariadb -uroot -e "CREATE DATABASE IF NOT EXISTS observium DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;"
  PW=$(cat /config/config.php | grep -m 1 "'db_pass'" | sed -r 's/.*(.{34})/\1/;s/.{2}$//')
  echo "Creating database user."
  mariadb -uroot -e "CREATE USER 'observium'@'localhost' IDENTIFIED BY '$PW'"
  echo "Granting database access to 'observium' user for localhost."
  mariadb -uroot -e "GRANT ALL PRIVILEGES ON observium.* TO 'observium'@'localhost'"
  mariadb -uroot -e "FLUSH PRIVILEGES"
  cd /opt/observium
  echo "Running Observium's discovery script."
  ./discovery.php -u
  echo "Adding the 'observium' user to the app."
  php adduser.php observium observium 10
  echo "Shutting down."
  mariadb-admin -u root shutdown
  sleep 1
  echo "Initialization complete."
fi

echo "Fixing file permissions."
chown -R nobody:users /config/databases
chmod -R 755 /config/databases
chown -R nobody:users /run/mysqld
chmod -R 755 /run/mysqld

sleep 3

echo "Starting MariaDB..."
/usr/bin/mariadbd-safe --skip-syslog --datadir='/config/databases'
