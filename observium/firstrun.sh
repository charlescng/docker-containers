#!/bin/bash

# Generate self signed certificate if certificates folder is empty
# Define the folder to check and certificate details
CERT_DIR="/opt/observium/certificates"
CERT_FILE="$CERT_DIR/fullchain.pem"
KEY_FILE="$CERT_DIR/privkey.pem"

# Check if the folder exists and is empty
if [ ! -d "$CERT_DIR" ]; then
  echo "Directory $CERT_DIR does not exist. Creating it..."
  mkdir -p "$CERT_DIR"
fi

if [ "$(ls -A $CERT_DIR)" ]; then
  echo "Directory $CERT_DIR is not empty. No certificate will be generated."
else
  echo "Directory $CERT_DIR is empty. Generating self-signed certificate..."

  # Generate a self-signed certificate
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout "$KEY_FILE" \
    -out "$CERT_FILE" \
    -subj "/C=DE/ST=Mecklenburg-Vorpommern/L=Dummerstorf/O=FBN/OU=IT/CN=localhost"

  if [ $? -eq 0 ]; then
    echo "Self-signed certificate and key generated successfully:"
    echo "Certificate: $CERT_FILE"
    echo "Key: $KEY_FILE"
  else
    echo "Failed to generate the self-signed certificate."
  fi
fi

atd

# Check if PHP database config exists. If not, copy in the default config
if [ -f /config/config.php ]; then
  echo "Using existing PHP database config file."
  echo "/opt/observium/discovery.php -u" | at -M now + 1 minute
  echo "/usr/bin/mariadb-upgrade -uroot" | at -M now + 1 minute
else
  echo "Loading PHP config from default."
  mkdir -p /config/databases
  cp /opt/observium/config.php.default /config/config.php
  chown nobody:users /config/config.php
  PW=$(pwgen -1snc 32)
  sed -i -e 's/PASSWORD/'$PW'/g' /config/config.php
  sed -i -e 's/USERNAME/observium/g' /config/config.php
fi

# if syslog config line is not already in config.php then add it
grep -qF 'enable_syslog' /config/config.php || echo "\$config['enable_syslog'] = 1;" >> /config/config.php

ln -s /config/config.php /opt/observium/config.php
chown nobody:users -R /opt/observium
chmod 755 -R /opt/observium

if [ -f /etc/container_environment/TZ ] ; then
  sed -i "s#\;date\.timezone\ \=#date\.timezone\ \=\ $TZ#g" /etc/php/8.3/cli/php.ini
  sed -i "s#\;date\.timezone\ \=#date\.timezone\ \=\ $TZ#g" /etc/php/8.3/apache2/php.ini
else
  echo "Timezone not specified by environment variable"
  echo UTC > /etc/container_environment/TZ
  sed -i "s#\;date\.timezone\ \=#date\.timezone\ \=\ UTC#g" /etc/php/8.3/cli/php.ini
  sed -i "s#\;date\.timezone\ \=#date\.timezone\ \=\ UTC#g" /etc/php/8.3/apache2/php.ini
fi

# Workaround graph times not using system/php/database TZ or TZ environment
rm /etc/localtime
ln -s /usr/share/zoneinfo/$(cat /etc/container_environment/TZ) /etc/localtime
