FROM debian:bullseye-slim
RUN apt update && apt upgrade -y
RUN apt  install -y dovecot-core dovecot-imapd libsasl2-modules

COPY postfix.debconf /tmp/postfix.debconf
RUN debconf-set-selections /tmp/postfix.debconf
RUN apt-get install -y postfix

RUN groupadd -g 5000 vmail
RUN useradd -s /usr/sbin/nologin -u 5000 -g 5000 vmail
RUN usermod -aG vmail postfix
RUN usermod -aG vmail dovecot


COPY entrypoint.sh /entrypoint.sh
#RUN mkdir -p /run/php
#RUN touch /run/php/php8.2-fpm.pid

EXPOSE 25
EXPOSE 587
EXPOSE 465


ENTRYPOINT ["/bin/bash","/entrypoint.sh"]
