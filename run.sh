#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

DOCKERDATADIR=/dockerdata

export MYSQL_ROOT_PASSWORD=$(cat $DOCKERDATADIR/secrets/db_root_password.txt) MYSQL_PASSWORD=$(cat $DOCKERDATADIR/secrets/db_password.txt)
cd $SCRIPT_DIR
docker compose up -d
