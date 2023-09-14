# Use phusion/baseimage as base image. To make your builds reproducible, make
# sure you lock down to a specific version, not to `latest`!
# See https://github.com/phusion/baseimage-docker/blob/master/Changelog.md for
# a list of version numbers.
FROM phusion/baseimage:jammy-1.0.1
MAINTAINER uberchuckie <uberchuckie@gmail.com>

# Set correct environment variables.
ENV HOME /root
ENV DEBIAN_FRONTEND noninteractive
ENV LC_ALL C.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

# Use baseimage-docker's init system
CMD ["/sbin/my_init"]

# Configure user nobody to match unRAID's settings
 RUN \
 usermod -u 99 nobody && \
 usermod -g 100 nobody && \
 usermod -d /home nobody && \
 chown -R nobody:users /home

# Disable SSH
RUN rm -rf /etc/service/sshd /etc/my_init.d/00_regen_ssh_host_keys.sh

# Install locales
RUN locale-gen cs_CZ.UTF-8
RUN locale-gen de_DE.UTF-8
RUN locale-gen en_US.UTF-8
RUN locale-gen es_ES.UTF-8
RUN locale-gen fr_FR.UTF-8
RUN locale-gen it_IT.UTF-8
RUN locale-gen pl_PL.UTF-8
RUN locale-gen pt_BR.UTF-8
RUN locale-gen ru_RU.UTF-8
RUN locale-gen sl_SI.UTF-8
RUN locale-gen uk_UA.UTF-8

RUN curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | bash -s -- --mariadb-server-version=mariadb-10.11 --skip-maxscale

# Install Observium prereqs
RUN apt-get update -q && \
    apt-get upgrade -y -q && \
    apt-get install -y --no-install-recommends mariadb-server mariadb-client \
      libapache2-mod-php8.1 php8.1-cli php8.1-mysql php8.1-gd php8.1-bcmath php8.1-mbstring \
      php8.1-opcache php8.1-curl php-apcu php-pear snmp fping rrdtool subversion \
      whois mtr-tiny ipmitool graphviz imagemagick apache2 python3-mysqldb python3-pymysql python-is-python3 \
      nmap wget pwgen at libvirt-clients libvirt-daemon-system && \
    apt-get update -q -y

# Tweak MariaDB configuration
RUN sed -i -e 's#\(bind-address.*=\).*#\1 127.0.0.1#g' /etc/mysql/mariadb.conf.d/50-server.cnf && \
    sed -i -e 's#\#\(log_error.*=\).*#\1 /config/databases/mysql_safe.log#g' /etc/mysql/mariadb.conf.d/50-server.cnf && \
    sed -i -e 's/#\(user.*=\).*/\1 nobody/g' /etc/mysql/mariadb.conf.d/50-server.cnf && \
    echo '[mysqld]' > /etc/mysql/conf.d/innodb_file_per_table.cnf && \
    echo 'innodb_file_per_table' >> /etc/mysql/conf.d/innodb_file_per_table.cnf

RUN mkdir -p /opt/observium/firstrun /opt/observium/logs /opt/observium/rrd /opt/observium/certificates /config && \
    cd /opt && \
    wget http://www.observium.org/observium-community-latest.tar.gz && \
    tar zxvf observium-community-latest.tar.gz && \
    rm observium-community-latest.tar.gz

# Patch schema upgrade SQL
COPY patches/update/184.sql /opt/observium/update
RUN chown nobody:users /opt/observium/update/184.sql && \
    chmod 755 /opt/observium/update/184.sql

RUN a2enmod rewrite
RUN a2enmod ssl

RUN mkdir /etc/service/apache2
COPY apache2.sh /etc/service/apache2/run
RUN chmod +x /etc/service/apache2/run

COPY firstrun.sh /etc/my_init.d/firstrun.sh
COPY mariadb.sh /etc/service/mariadb/run
RUN chmod +x /etc/my_init.d/firstrun.sh && \
    chmod +x /etc/service/mariadb/run && \
    chown -R nobody:users /opt/observium && \
    chmod 755 -R /opt/observium && \
    chown -R nobody:users /config && \
    chmod 755 -R /config && \
    chown -R nobody:users /var/log/mysql* && \
    chown -R nobody:users /var/lib/mysql && \
    chown -R nobody:users /etc/mysql && \
    chmod u+s /usr/bin/fping

# Configure apache2 to serve Observium app
COPY apache2.conf /etc/apache2/apache2.conf
COPY ports.conf /etc/apache2/ports.conf
COPY apache-observium /etc/apache2/sites-available/000-default.conf
RUN rm /etc/apache2/sites-available/default-ssl.conf && \
    echo www-data > /etc/container_environment/APACHE_RUN_USER && \
    echo www-data > /etc/container_environment/APACHE_RUN_GROUP && \
    echo /var/log/apache2 > /etc/container_environment/APACHE_LOG_DIR && \
    echo /var/lock/apache2 > /etc/container_environment/APACHE_LOCK_DIR && \
    echo /var/run/apache2.pid > /etc/container_environment/APACHE_PID_FILE && \
    echo /var/run/apache2 > /etc/container_environment/APACHE_RUN_DIR && \
    chown -R www-data:www-data /var/log/apache2 && \
    rm -Rf /var/www && \
    ln -s /opt/observium/html /var/www


# Setup Observium cron jobs
COPY cron-observium /etc/cron.d/observium
RUN chmod 744 /etc/cron.d/observium

# syslog config
COPY observium.conf /etc/syslog-ng/conf.d/observium.conf

EXPOSE 514/udp
EXPOSE 8668/tcp

VOLUME ["/config","/opt/observium/logs","/opt/observium/rrd","/opt/observium/certificates"]

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
