FROM ubuntu:jammy
RUN apt update && apt upgrade -y
RUN apt  install -y  software-properties-common
RUN add-apt-repository -y ppa:ondrej/php
RUN apt install -y php8.2-fpm

RUN apt install -y imagemagick \
php8.2-imagick \
php8.2-memcached \
libmemcached-tools \
php8.2-apcu \
php8.2-gd \
php8.2-mysql \
php8.2-curl \
php8.2-mbstring \
php8.2-intl \
php8.2-gmp \
php8.2-bcmath \
php8.2-xml \
php8.2-zip \
unzip \
smbclient
RUN apt install -y php8.2-redis

RUN mkdir -p /run/php
RUN touch /run/php/php8.2-fpm.pid

EXPOSE 9000

ENTRYPOINT ["php-fpm8.2","--nodaemonize"]
