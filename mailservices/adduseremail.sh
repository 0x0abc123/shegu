#!/bin/bash
USAGE="Usage: $0 EMAIL\n   example: $0 alex.human@example.com";

if [ ! -n "$1" ]
then
	echo -e $USAGE;
	exit 1;
fi

DOCKERPFDIR=/dockerdata/mailservices/postfix
USERNAME=$(echo "$1" | cut -f1 -d@);
DOMAIN=$(echo "$1" | cut -f2 -d@);
ADDRESS=$1;
#PASSWD=$2;
VBASEDIR="/var/mail/vhosts";
BASEDIR="/dockerdata/mailservices/varmailvhosts";
VMAILBOX="$DOCKERPFDIR/vmaps/vmailbox"

MSCONTAINER=$(docker ps | tr -s ' ' | cut -d ' ' -f 1-2 | grep -E '\-mailservices$')
MSCID=$(echo "$MSCONTAINER" | cut -d ' ' -f1)
if [[ $MSCID != "" ]]
then

	if [ -f $VMAILBOX ]
	then
		echo "Adding Postfix user configuration..."
		echo $ADDRESS $DOMAIN/$USERNAME/ >> $VMAILBOX
		echo "Adding Dovecot user configuration..."
		echo $ADDRESS::5000:5000::$VBASEDIR/$DOMAIN/$ADDRESS>> $BASEDIR/$DOMAIN/passwd
		chown 5000:5000 $BASEDIR/$DOMAIN/passwd && chmod 775 $BASEDIR/$DOMAIN/passwd

		docker exec $MSCID postmap /etc/postfix/vmaps/vmailbox
		sleep 1
		docker exec $MSCID postfix reload
	else
		echo error: $VMAILBOX does not exist
	fi
else
	echo 'error: mailservices docker container is not running. Run "docker compose up -d" first then try running the script again'
fi
