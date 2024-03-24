#!/bin/bash
USAGE="Usage: $0 ALIAS_EMAIL DEST_EMAIL\n   example: $0 aliasemail@example.com realuser@example.com";

if [ ! -n "$2" ]
then
	echo -e $USAGE;
	exit 1;
fi


ALIAS_ADDRESS=$1;
DEST_ADDRESS=$2;
VALIASFILE="/etc/postfix/vmaps/virtual_alias";
ALIASFILE="/dockerdata/mailservices/postfix/vmaps/virtual_alias";

MSCONTAINER=$(docker ps | tr -s ' ' | cut -d ' ' -f 1-2 | grep -E '\-mailservices$')
MSCID=$(echo "$MSCONTAINER" | cut -d ' ' -f1)
if [[ $MSCID != "" ]]
then
        if [ -f $ALIASFILE ]
        then
                echo "Adding Postfix virtual alias configuration..."
                echo $ALIAS_ADDRESS $DEST_ADDRESS >> $ALIASFILE

                docker exec $MSCID postmap $VALIASFILE
                sleep 1
                docker exec $MSCID postfix reload
        else
                echo error: $ALIASFILE does not exist
        fi
else
        echo 'error: mailservices docker container is not running. Run "docker compose up -d" first then try running the script again'
fi
