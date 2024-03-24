#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

DOCKERDATADIR=/dockerdata


echo -n "Ensure you have edited the setup.env file with values for your environment first, then confirm by entering 'y' to proceed with setup: "
read READY
if [[ $READY != "y" ]]
then
  echo aborting
else
  echo checking variables...
fi


source $SCRIPT_DIR/setup.env

# read yourdomain.tld
# read mailhost.fqdn

if [[ $NEXTCLOUD_FQDN == "" ]]
then
    echo 'The NEXTCLOUD_FQDN value entered was empty, aborting'
    exit 1
fi

if [[ $WEBMAILHOST_FQDN == "" ]]
then
    echo 'The WEBMAILHOST_FQDN value entered was empty, aborting'
    exit 1
fi


if [[ $MAILHOST_FQDN == "" ]]
then
    echo 'The MAILHOST_FQDN value entered was empty, aborting'
    exit 1
fi

if [[ $YOURDOMAIN_TLD == "" ]]
then
    echo 'The YOURDOMAIN_TLD value entered was empty, aborting'
    exit 1
fi

if [[ $OFFICEOAUTH2IDPNAME == "" ]]
then
    echo 'The OFFICEOAUTH2IDPNAME value entered was empty, aborting'
    exit 1
fi


if [[ $OFFICEOAUTH2CLIENTID == "" ]]
then
    echo 'The OFFICEOAUTH2CLIENTID value entered was empty, aborting'
    exit 1
fi

if [[ $OFFICEOAUTH2CLIENTSECRET == "" ]]
then
    echo 'The OFFICEOAUTH2CLIENTSECRET value entered was empty, aborting'
    exit 1
fi


if [[ $OFFICEOAUTH2AUTHURL == "" ]]
then
    echo 'The OFFICEOAUTH2AUTHURL endpoint value entered was empty, aborting'
    exit 1
fi


if [[ $OFFICEOAUTH2TOKENURL == "" ]]
then
    echo 'The OFFICEOAUTH2TOKENURL endpoint value entered was empty, aborting'
    exit 1
fi


if [[ $OAUTH2USERINFOURL == "" ]]
then
    echo 'The OAUTH2USERINFOURL endpoint value entered was empty, aborting'
    exit 1
fi

if [[ $RSPAMD_PSWD_HASH == "" ]]
then
    echo 'The RSPAMD_PSWD_HASH value entered was empty, aborting'
    exit 1
fi



# replace hostnames in nginx conf NEXTCLOUD_HOST_FQDN

NGINXDIR=$DOCKERDATADIR/nginx
mkdir -p $NGINXDIR


NC_CONF_FILE="$SCRIPT_DIR/nginx/nextcloud.conf"
cp $NC_CONF_FILE $NGINXDIR/nextcloud.conf
sed -i 's/NEXTCLOUD_HOST_FQDN/'$NEXTCLOUD_FQDN'/g' $NGINXDIR/nextcloud.conf

RCFPM_CONF_FILE="$SCRIPT_DIR/nginx/roundcube.conf"
cp $RCFPM_CONF_FILE $NGINXDIR/roundcube.conf
sed -i 's/WEBMAILHOST_FQDN/'$WEBMAILHOST_FQDN'/g' $NGINXDIR/roundcube.conf

MAIL_CONF_FILE="$SCRIPT_DIR/nginx/mail.conf"
cp $MAIL_CONF_FILE $NGINXDIR/mail.conf
sed -i 's/MAILHOST_FQDN/'$MAILHOST_FQDN'/g' $NGINXDIR/mail.conf


apt-get update
apt-get install -y wget unzip ca-certificates curl

# install docker docker-compose https://docs.docker.com/engine/install/debian/

if ! docker compose version &> /dev/null
then
echo installing docker and docker-compose-plugin
# Add Docker's official GPG key:
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
else
    echo docker appears to be already installed, skipping...
fi

# download nextcloud https://download.nextcloud.com/server/releases/nextcloud-27.1.4.zip OR	restore backup to /dockerdata/nextcloud

echo "Install nextcloud, choose from the following:"
echo "1. Download from the nextcloud releases server (internet)"
echo "2. extract from local file"
echo "3. do nothing at this step and later manually copy a backup to $DOCKERDATADIR/nextcloud"
echo -n "enter option: "
read NCINSTALLOPTION

EXTRACTNC=""

case $NCINSTALLOPTION in

  1)
    echo downloading nextcloud...
    wget -O /tmp/nc.zip https://download.nextcloud.com/server/releases/nextcloud-27.1.4.zip
    EXTRACTNC=1
    ;;

  2)
    echo -n "enter the full filesystem path to the nextcloud zip: "
    read NCINSTALLFSPATH
    if [[ $NCINSTALLFSPATH != "" && -f $NCINSTALLFSPATH ]]
    then
      rm -rf /tmp/nc.zip
      ln -sf $NCINSTALLFSPATH /tmp/nc.zip
    else
      echo no path entered or $NCINSTALLFSPATH is not a file or does not exist, aborting...
      exit 1
    fi
    EXTRACTNC=1
    ;;

  *)
    echo "manually copy nextcloud app webroot files to $DOCKERDATADIR/nextcloud now"
    echo -n "then hit enter to continue: "
    read ANYINPUT
    ;;
esac

if [[ $EXTRACTNC != "" ]]
then
  cd $DOCKERDATADIR
  unzip /tmp/nc.zip
  rm -rf /tmp/nc.zip
  cp "$SCRIPT_DIR/nextcloud/config.php" "$DOCKERDATADIR/nextcloud/config/config.php"
fi


mkdir -p $DOCKERDATADIR/certbot/conf
mkdir -p $DOCKERDATADIR/certbot/nextcloud
mkdir -p $DOCKERDATADIR/certbot/roundcube
mkdir -p $DOCKERDATADIR/certbot/mail


rsa_key_size=4096

echo generating temporary self-signed TLS certs...
echo "If you are not using certbot to manage certs, Copy your TLS certificates and keys to /dockerdata/certbot/conf/live/YOURDOMAIN after setup finishes"
TMPCERTPATH=$(mktemp -d)
openssl req -x509 -nodes -newkey rsa:$rsa_key_size -days 3650\
    -keyout "$TMPCERTPATH/privkey.pem" \
    -out "$TMPCERTPATH/fullchain.pem" \
    -subj "/CN=localhost"

CERTBASEDIR=$DOCKERDATADIR/certbot/conf/live
CERTDIR_NC=$CERTBASEDIR/$NEXTCLOUD_FQDN
CERTDIR_MAIL=$CERTBASEDIR/$MAILHOST_FQDN
CERTDIR_WEBMAIL=$CERTBASEDIR/$WEBMAILHOST_FQDN
mkdir -p $CERTDIR_NC
mkdir -p $CERTDIR_MAIL
mkdir -p $CERTDIR_WEBMAIL
cp "$TMPCERTPATH/privkey.pem" $CERTDIR_NC
cp "$TMPCERTPATH/fullchain.pem" $CERTDIR_NC
cp "$TMPCERTPATH/privkey.pem" $CERTDIR_MAIL
cp "$TMPCERTPATH/fullchain.pem" $CERTDIR_MAIL
cp "$TMPCERTPATH/privkey.pem" $CERTDIR_WEBMAIL
cp "$TMPCERTPATH/fullchain.pem" $CERTDIR_WEBMAIL


CERTCONFDIR=$DOCKERDATADIR/certbot/conf/
curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf > "$CERTCONFDIR/options-ssl-nginx.conf"
curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot/certbot/ssl-dhparams.pem > "$CERTCONFDIR/ssl-dhparams.pem"

# create www-data uid=33 gid=33 user
# this user owns the nextcloud webroot in the docker container
if ! id 33
then
groupadd -g 33 www-data
useradd www-data -u 33 -g 33 -m -s /bin/bash
fi

if [ -d $DOCKERDATADIR/nextcloud ]
then
cd $DOCKERDATADIR
chown -R 33:33 nextcloud
fi

# /dockerdata/dbdata/
mkdir -p "$DOCKERDATADIR/mariadb"
cp -r "$SCRIPT_DIR/mariadb/sqlscripts" "$DOCKERDATADIR/mariadb/scripts"
cp "$SCRIPT_DIR/mariadb/50server.cnf" "$DOCKERDATADIR/mariadb/"
mkdir -p $DOCKERDATADIR/dbdata

# /dockerdata/phpfpm/php.ini
# /dockerdata/phpfpm/www.conf
mkdir -p "$DOCKERDATADIR/nextconf"
cp "$SCRIPT_DIR/nextcloud/php.ini" "$DOCKERDATADIR/nextconf/"
cp "$SCRIPT_DIR/nextcloud/www.conf" "$DOCKERDATADIR/nextconf/"


# /dockerdata/secrets/db_password.txt
# /dockerdata/secrets/db_root_password.txt
SECRETSDIR="$DOCKERDATADIR/secrets"
mkdir -p $SECRETSDIR

echo -n "enter a password for the MySQL root user or leave blank to generate a random one: "
read ROOTPASS
if [[ $ROOTPASS != "" ]]
then
  echo using supplied password
else
  ROOTPASS=$(head -c 32 /dev/urandom | base64 -w0 | tr -dc 'A-Za-z0-9')
fi
echo -n $ROOTPASS > $SECRETSDIR/db_root_password.txt


echo -n "enter a password for the MySQL nextcloud/roundcube user or leave blank to generate a random one: "
read DBUSERPASS
if [[ $DBUSERPASS != "" ]]
then
  echo using supplied password
else
  DBUSERPASS=$(head -c 32 /dev/urandom | base64 -w0 | tr -dc 'A-Za-z0-9')
fi
echo -n $DBUSERPASS > $SECRETSDIR/db_password.txt


echo -e "MYSQL_ROOT_PASSWORD=$(cat /dockerdata/secrets/db_root_password.txt)\nMYSQL_PASSWORD=$(cat /dockerdata/secrets/db_password.txt)" > "$SCRIPT_DIR/.env"

if [[ $ZROK_ENABLE_TOKEN != "" ]] ; then echo 'ZROK_ENABLE_TOKEN="'$ZROK_ENABLE_TOKEN'"' >> "$SCRIPT_DIR/.env" ; fi


MAILSVCDIR=$DOCKERDATADIR/mailservices
POSTFIXDIR=$MAILSVCDIR/postfix
DOVECOTDIR=$MAILSVCDIR/dovecot

rm -rf $MAILSVCDIR
mkdir -p $MAILSVCDIR
cd $SCRIPT_DIR/mailservices
cp -r postfix $MAILSVCDIR
cp -r dovecot $MAILSVCDIR


# create the vmail user (which corresponds to the user in the mailservices Docker container for virtual mailboxes)
if ! id 5000
then
groupadd -g 5000 vmail
useradd -s /usr/sbin/nologin -u 5000 -g 5000 vmail
fi

# /dockerdata/mailservices/varmailvhosts
mkdir -p $MAILSVCDIR/varmailvhosts/${YOURDOMAIN_TLD}

chown -R 5000:5000 $MAILSVCDIR/varmailvhosts
chmod -R 775 $MAILSVCDIR/varmailvhosts

chgrp 5000 $DOVECOTDIR/log
chmod 660 $DOVECOTDIR/log

chmod 755 $POSTFIXDIR/vmaps
chmod 644 $POSTFIXDIR/vmaps/*


# find and replace...
# yourdomain.tld
# mailhost.fqdn
# OFFICEOAUTH2*
find $MAILSVCDIR -type f -exec sed -i 's/yourdomain\.tld/'$YOURDOMAIN_TLD'/g' {} \;
find $MAILSVCDIR -type f -exec sed -i 's/mailhost\.fqdn/'$MAILHOST_FQDN'/g' {} \;
find $MAILSVCDIR -type f -exec sed -i 's|OFFICEOAUTH2USERINFOURL|'$OAUTH2USERINFOURL'|g' {} \;
find $MAILSVCDIR -type f -exec sed -i 's|SMTPSMARTHOST_FQDN|'$SMTPSMARTHOST_FQDN'|g' {} \;
find $MAILSVCDIR -type f -exec sed -i 's|SMTPSMARTHOST_PORT|'$SMTPSMARTHOST_PORT'|g' {} \;
find $MAILSVCDIR -type f -exec sed -i 's|SMTPSMARTHOST_CREDS|'$SMTPSMARTHOST_CREDS'|g' {} \;


# create _rspamd uid=11333 gid=11333 user
# this user owns the /var/lib/rspamd directory in the docker container
if ! id 11333
then
groupadd -g 11333 _rspamd
useradd _rspamd -u 11333 -g 11333 -m -s /usr/sbin/nologin
fi

mkdir -p $DOCKERDATADIR/rspamd/db
chown 11333:11333 $DOCKERDATADIR/rspamd/db
chmod 750 $DOCKERDATADIR/rspamd/db
cp -r $SCRIPT_DIR/rspamd/config $DOCKERDATADIR/rspamd/config
chmod -R 755 $DOCKERDATADIR/rspamd/config

find $DOCKERDATADIR/rspamd/config -type f -exec sed -i 's|RSPAMD_PSWD_HASH|'$RSPAMD_PSWD_HASH'|g' {} \;



RCCONFPATH=roundcube/config
mkdir -p $DOCKERDATADIR/$RCCONFPATH
RCCONFIGFILE="$DOCKERDATADIR/$RCCONFPATH/oauth2.inc.php"
cp $SCRIPT_DIR/$RCCONFPATH/oauth2.inc.php $RCCONFIGFILE
chmod 644 $RCCONFIGFILE
sed -i 's|OFFICEOAUTH2IDPNAME|'$OFFICEOAUTH2IDPNAME'|g' $RCCONFIGFILE
sed -i 's|OFFICEOAUTH2CLIENTID|'$OFFICEOAUTH2CLIENTID'|g' $RCCONFIGFILE
sed -i 's|OFFICEOAUTH2CLIENTSECRET|'$OFFICEOAUTH2CLIENTSECRET'|g' $RCCONFIGFILE
sed -i 's|OFFICEOAUTH2AUTHURL|'$OFFICEOAUTH2AUTHURL'|g' $RCCONFIGFILE
sed -i 's|OFFICEOAUTH2TOKENURL|'$OFFICEOAUTH2TOKENURL'|g' $RCCONFIGFILE
sed -i 's|OFFICEOAUTH2USERINFOURL|'$OFFICEOAUTH2USERINFOURL'|g' $RCCONFIGFILE


export MYSQL_ROOT_PASSWORD=$(cat /dockerdata/secrets/db_root_password.txt)
export MYSQL_PASSWORD=$(cat /dockerdata/secrets/db_password.txt)

cd $SCRIPT_DIR

DC_NEXTCLOUD_FILE=
if [[ $USE_CERTBOT_NEXTCLOUD != "" ]] ; then DC_NEXTCLOUD_FILE=dcompose-cert-nextcloud.yaml ; fi

DC_ROUNDCUBE_FILE=
if [[ $USE_CERTBOT_ROUNDCUBE != "" ]] ; then DC_ROUNDCUBE_FILE=dcompose-cert-roundcube.yaml ; fi

DC_MAIL_FILE=
if [[ $USE_CERTBOT_MAIL != "" ]] ; then DC_MAIL_FILE=dcompose-cert-mail.yaml ; fi

DC_ZROK_FILE=
if [[ $ZROK_ENABLE_TOKEN != "" ]] ; then DC_ZROK_FILE=dcompose-zrok.yaml ; fi

cat docker-compose-head.yaml $DC_NEXTCLOUD_FILE $DC_ROUNDCUBE_FILE $DC_MAIL_FILE $DC_ZROK_FILE docker-compose-tail.yaml > docker-compose.yaml


docker compose build

# roundcube database initialisation seems broken, using fix from: https://www.centosdude.com/directadmin/fixing-broken-roundcube-installation-on-directadmin-servers/
docker compose run --rm roundcube cat /usr/src/roundcubemail/SQL/mysql.initial.sql > $DOCKERDATADIR/mariadb/scripts/roundcubeinit.sql

sleep 3

echo starting mariadb and creating databases...
docker compose up mariadb -d

MDBCONTAINER=$(docker ps | tr -s ' ' | cut -d ' ' -f 1-2 | grep -E 'mariadb')
MDBID=$(echo "$MDBCONTAINER" | cut -d ' ' -f1)
if [[ $MDBID != "" ]]
then
    while true
    do
      echo waiting for database to start
      sleep 1
      docker exec $MDBID healthcheck.sh --su-mysql --connect --innodb_initialized
      if [ $? == 0 ] ; then break ; fi
    done
    docker exec $MDBID bash /tmp/sqlscripts/createdb.sh
else
	echo 'error: mariadb docker container is not running - run database setup manually'
fi

docker compose down
sleep 3

#echo run docker compose up mariadb -d
#echo to create databases, run:
#echo 'docker exec -it {mariadb_container_name} bash /tmp/sqlscripts/createdb.sh'


if [[ $USE_CERTBOT_NEXTCLOUD != "" || $USE_CERTBOT_ROUNDCUBE != "" || $USE_CERTBOT_MAIL != "" ]]
then

  echo "### Starting nginx ..."
  docker compose up --force-recreate -d nginx
  echo

  echo waiting 30 secs for nginx to start/load...
  sleep 30

  echo "### Requesting Let's Encrypt certificate for hosts ..."

  # Select appropriate email arg
  case "$CERTBOT_EMAIL" in
    "") email_arg="--register-unsafely-without-email" ;;
    *) email_arg="--email $CERTBOT_EMAIL" ;;
  esac

  CERT_NC_OK=0
  CERT_RC_OK=0
  CERT_MAIL_OK=0

  if [[ $USE_CERTBOT_NEXTCLOUD != "" ]]
  then
    echo "### Deleting dummy certificates for $NEXTCLOUD_FQDN ..."
    rm -Rf /dockerdata/certbot/conf/live/$NEXTCLOUD_FQDN
    rm -Rf /dockerdata/certbot/conf/archive/$NEXTCLOUD_FQDN
    rm -Rf /dockerdata/certbot/conf/renewal/${NEXTCLOUD_FQDN}.conf

    docker compose run --rm --entrypoint "\
      certbot certonly --webroot -w /var/www/certbot \
        $email_arg \
        -d $NEXTCLOUD_FQDN \
        --rsa-key-size $rsa_key_size \
        --agree-tos \
        --force-renewal" certnextcloud
    CERT_NC_OK=$?
  fi

  if [[ $USE_CERTBOT_ROUNDCUBE != "" ]]
  then
    echo "### Deleting dummy certificates for $WEBMAILHOST_FQDN ..."
    rm -Rf /dockerdata/certbot/conf/live/$WEBMAILHOST_FQDN
    rm -Rf /dockerdata/certbot/conf/archive/$WEBMAILHOST_FQDN
    rm -Rf /dockerdata/certbot/conf/renewal/${WEBMAILHOST_FQDN}.conf

    docker compose run --rm --entrypoint "\
      certbot certonly --webroot -w /var/www/certbot \
        $email_arg \
        -d $WEBMAILHOST_FQDN \
        --rsa-key-size $rsa_key_size \
        --agree-tos \
        --force-renewal" certnextcloud
    CERT_RC_OK=$?
  fi

  if [[ $USE_CERTBOT_MAIL != "" ]]
  then
    echo "### Deleting dummy certificates for $MAILHOST_FQDN ..."
    rm -Rf /dockerdata/certbot/conf/live/$MAILHOST_FQDN
    rm -Rf /dockerdata/certbot/conf/archive/$MAILHOST_FQDN
    rm -Rf /dockerdata/certbot/conf/renewal/${MAILHOST_FQDN}.conf
    echo

    docker compose run --rm --entrypoint "\
      certbot certonly --webroot -w /var/www/certbot \
        $email_arg \
        -d $MAILHOST_FQDN \
        --rsa-key-size $rsa_key_size \
        --agree-tos \
        --force-renewal" certmail
    CERT_MAIL_OK=$?
  fi

  if [[ $CERT_NC_OK == 0 && $CERT_RC_OK == 0 && $CERT_MAIL_OK == 0 ]]
  then
    echo "### Reloading nginx ..."
    docker compose exec nginx nginx -s reload
  else
    echo obtaining at least one of the certs from letsencrypt failed, so we will not restart nginx as it will fail due to not finding the cert at the path in the .conf file
    echo troubleshoot the issue from the output above and attempt to run certbot again
  fi

  echo "After ensuring that letsencrypt certificates have been issued manually run 'docker compose down' to finish installation"
fi


#ZROK_ENABLE_TOKEN
mkdir -p "$DOCKERDATADIR/zrok/env"
mkdir -p "$DOCKERDATADIR/zrok/reserve"
chown -R 65534:65534 "$DOCKERDATADIR/zrok"

#/dockerdata/roundcube/config/
echo Next steps:
echo ./run.sh
echo to add mail accounts, run these scripts:
echo './mailservices/adduseremail.sh  <newuser@yourdomain.tld>'
echo './mailservices/addaliasemail.sh  <aliasname@yourdomain.tld> <newuser@yourdomain.tld>'
