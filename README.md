# Self Hosted Email and Groupware

## About

This repo contains some scripts and config files to deploy a self-hosted webmail and groupware server using Docker Compose.

The open source projects Nextcloud (groupware) and Roundcube (webmail) are the main components of the server.

Other (Dockerized) services that support the server include:

- Dovecot (IMAP)
- Postfix (SMTP)
- Rspamd (SMTP milter for spam)
- MariaDB (MySQL database server)
- Redis (in-memory key/value store)
- NGINX (webserver)
- Certbot (TLS certificate management)
- Zrok (zero trust remote access)

## Requirements

- A Debian 11/12 Linux host server (at least 2 x vCPU and 4GB RAM recommended)
- network access to the internet for the host server
- allow these inbound ports on the firewall/security-groups:
    - SMTP 25/tcp, 587/tcp
    - HTTP 80/tcp, 443/tcp
    - SSH 22/tcp (optional if you have another means of obtaining a remote shell)
- A domain and access to DNS record management
    - DNS `A` record for `yourmailhostname.yourdomain.tld` pointing to the host server
    - DNS `A` record for `yourwebmailhostname.yourdomain.tld` pointing to the host server
    - DNS `A` record for `yournextcloudhostname.yourdomain.tld` pointing to the host server
    - DNS `MX` records for `yourdomain.tld` pointing to `yourmailhostname.yourdomain.tld`
- An Identity Provider and OpenIDConnect (OIDC) application where you have the client ID and client secret, plus OAuth2 authorize/token/userinfo URLs
    - allow the app to redirect to these URLs:
        - https://yournextcloudhostname.yourdomain.tld/apps/sociallogin/custom_oidc/cognito
        - https://yourwebmailhostname.yourdomain.tld/index.php/login/oauth
- An SMTP smarthost for relaying outgoing mail (eg. smtp2go, AWS SES etc.) with an SMTP username and password
- (optional) your own TLS certificate and private key to install for the mail, webmail and Nextcloud hosts
- (optional) or if you choose to use LetsEncrypt, then an email address to register with the Certbot/LetsEncrypt certificate

### Notes

- ! If proxying the NextCloud server via CloudFlare, you need to add a page rule to **disable RocketLoader** for any NextCloud URLs because it will break the app
- ! You need to generate and install valid TLS certificates for Nginx (the CloudFlare origin certificates will do) and **set CloudFlare SSL/TLS encryption mode to Full(Strict)**

## Installation

1. clone this repo, for example to `/root/shegu`
1. `cd /root/shegu`
1. edit `./setup.env` and replace the default values with values appropriate to your domain, apps and environment
1. `./setup.sh`
1. `./run.sh`
1. ensure you have created users in your IDP OIDC application with `<user@yourdomain.tld>` email addresses
1. add users to Dovecot/Postfix with `./mailservices/adduseremail.sh <newuser@yourdomain.tld>`
1. add email aliases to Dovecot/Postfix with `./mailservices/addaliasemail.sh <aliasforuser@yourdomain.tld> <user@yourdomain.tld>`
1. open `yournextcloudhostname.yourdomain.tld` and setup Nextcloud:
    - set up the installation choosing admin credentials and using the following values:
        - database name: `nextcloud`
        - database user: `nc`
        - database password: `<the value you chose when you ran ./setup.sh or that was auto generated>`
        - database host: `mariadb:3306`
    - install the Social Login app
1. remote access for SSH or the Rspamd web UI is via zrok reserved private access, to get the share tokens:
    - `cat /dockerdata/zrok/reserve/ssh`
    - `cat /dockerdata/zrok/reserve/rspamd`
    - use `zrok access private <token>` to connect

## Maintenance

You can bring down the Docker services using `./stop.sh` (which calls `docker compose down`)

You can manually stop and start services using `docker compose stop|start|restart <servicename>` but you will have to ensure the required environment variables are set

After following the above instructions and installation is complete, you can change some of the docker compose service configuration files by directly editing them in `/dockerdata` and restarting the related service(s).

## Backup

To backup all data, archive the following folder:
```
/dockerdata
```

## Restore

To restore, stop all services with `./stop.sh`, then just `rm -rf /dockerdata` and extract the backup to `/dockerdata` again. Start everything again with `./start.sh`
