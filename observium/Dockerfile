# syntax=docker/dockerfile:1
# Use phusion/baseimage as base image. To make your builds reproducible, make
# sure you lock down to a specific version, not to `latest`!
# See https://github.com/phusion/baseimage-docker/blob/master/Changelog.md for
# a list of version numbers.
FROM phusion/baseimage:resolute-1.0.13
LABEL org.opencontainers.image.authors="uberchuckie@gmail.com"

# Set correct environment variables.
ENV HOME=/root \
    DEBIAN_FRONTEND=noninteractive \
    LC_ALL=C.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8

# Use baseimage-docker's init system
CMD ["/sbin/my_init"]

# Configure user nobody to match unRAID's settings, and disable SSH
RUN usermod -u 99 nobody && usermod -g 100 nobody && usermod -d /home nobody \
    && chown -R nobody:users /home \
    && rm -rf /etc/service/sshd /etc/my_init.d/00_regen_ssh_host_keys.sh

# Install locales
RUN locale-gen cs_CZ.UTF-8 de_DE.UTF-8 en_US.UTF-8 es_ES.UTF-8 fr_FR.UTF-8 \
    it_IT.UTF-8 pl_PL.UTF-8 pt_BR.UTF-8 ru_RU.UTF-8 sl_SI.UTF-8 uk_UA.UTF-8

# Install Observium prereqs, tweak MariaDB configuration, and clean up APT
RUN curl -LsS https://r.mariadb.com/downloads/mariadb_repo_setup | bash -s -- --mariadb-server-version=mariadb-11.8 --skip-maxscale \
    && apt-get update -q \
    && apt-get upgrade -y -q \
    && apt-get install -y --no-install-recommends mariadb-server mariadb-client \
        libapache2-mod-php8.5 php8.5-cli php8.5-mysql php8.5-gd php8.5-bcmath php8.5-mbstring \
        php8.5-curl php-apcu php-pear snmp fping rrdtool subversion \
        whois mtr-tiny ipmitool graphviz imagemagick apache2 python3-mysqldb python3-pymysql python-is-python3 \
        nmap wget pwgen at libvirt-clients libvirt-daemon-system openssl sendmail \
    && sed -i -e 's#\(bind-address.*=\).*#\1 127.0.0.1#g' /etc/mysql/mariadb.conf.d/50-server.cnf \
    && sed -i -e 's#\#\(log_error.*=\).*#\1 /config/databases/mysql_safe.log#g' /etc/mysql/mariadb.conf.d/50-server.cnf \
    && sed -i -e 's/#\(user.*=\).*/\1 nobody/g' /etc/mysql/mariadb.conf.d/50-server.cnf \
    && printf '[mysqld]\ninnodb_file_per_table\n' > /etc/mysql/conf.d/innodb_file_per_table.cnf \
    && chown -R nobody:users /var/log/mysql* /var/lib/mysql /etc/mysql \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Download and extract Observium with correct ownership
RUN mkdir -p /opt/observium/firstrun /opt/observium/logs /opt/observium/rrd /config \
    && cd /opt \
    && wget https://www.observium.org/observium-community-latest.tar.gz \
    && tar xzf observium-community-latest.tar.gz --owner=nobody --group=users \
    && rm observium-community-latest.tar.gz \
    && chmod 755 -R /opt/observium \
    && chown -R nobody:users /config \
    && chmod 755 -R /config \
    && chmod u+s /usr/bin/fping

# Runit service scripts and init hooks
COPY --chmod=755 apache2.sh /etc/service/apache2/run
COPY --chmod=755 firstrun.sh /etc/my_init.d/firstrun.sh
COPY --chmod=755 mariadb.sh /etc/service/mariadb/run

# Configure apache2 to serve Observium app
COPY apache2.conf /etc/apache2/apache2.conf
COPY ports.conf /etc/apache2/ports.conf
COPY apache-observium /etc/apache2/sites-available/000-default.conf
RUN a2enmod rewrite ssl remoteip headers \
    && rm /etc/apache2/sites-available/default-ssl.conf \
    && echo www-data > /etc/container_environment/APACHE_RUN_USER \
    && echo www-data > /etc/container_environment/APACHE_RUN_GROUP \
    && echo /var/log/apache2 > /etc/container_environment/APACHE_LOG_DIR \
    && echo /var/lock/apache2 > /etc/container_environment/APACHE_LOCK_DIR \
    && echo /var/run/apache2.pid > /etc/container_environment/APACHE_PID_FILE \
    && echo /var/run/apache2 > /etc/container_environment/APACHE_RUN_DIR \
    && chown -R www-data:www-data /var/log/apache2 \
    && rm -Rf /var/www \
    && ln -s /opt/observium/html /var/www

# Setup Observium cron jobs and syslog config
COPY --chmod=744 cron-observium /etc/cron.d/observium
COPY --chmod=755 syslog-wait.sh /usr/local/sbin/syslog-wait
COPY observium.conf /etc/syslog-ng/conf.d/observium.conf

EXPOSE 514/udp
EXPOSE 8668/tcp
EXPOSE 8669/tcp

VOLUME ["/config","/opt/observium/logs","/opt/observium/rrd","/opt/observium/certificates"]
