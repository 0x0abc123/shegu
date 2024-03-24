#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
sed -i 's/password/'$MYSQL_PASSWORD'/g' $SCRIPT_DIR/createdb.sql
mariadb -u root -p$MYSQL_ROOT_PASSWORD < $SCRIPT_DIR/createdb.sql
if [ -f $SCRIPT_DIR/roundcubeinit.sql ]
then
    mariadb -u root -p$MYSQL_ROOT_PASSWORD -D roundcubemail < $SCRIPT_DIR/roundcubeinit.sql
fi
