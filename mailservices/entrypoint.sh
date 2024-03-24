#!/bin/bash

trap exit TERM

if [ ! -f /etc/postfix/vmaps/virtual_alias.db ]
then
    postmap /etc/postfix/vmaps/virtual_alias
fi

dovecot
postfix start

# this is required because DNS resolution when relaying to the smarthost fails
# postfix tries to copy resolv.conf to the chroot jail /var/spool/postfix before DHCP can create it
while true
do
    sleep 1
    if [ -f /etc/resolv.conf ]
    then
        cp /etc/resolv.conf /var/spool/postfix/etc/resolv.conf
        break
    fi
done

sleep infinity & wait ${!}
