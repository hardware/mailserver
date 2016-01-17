# hardware/mailserver

## IN DEVELOPMENT !!

## Requirement

- MySQL
- Postfixadmin

## Components

- Postfix
- Dovecot
- OpenDKIM
- OpenDMARC
- Spamassassin
- ClamAV
- Amavis
- Supervisor

## Install

```
docker build -t hardware/mailserver
```

### How to use

```
docker run -d \
  -e "FQDN=mail.domain.tld"
  -e "DOMAIN=domain.tld"
  -e "DBHOST=localhost" \
  -e "DBUSER=postfix" \
  -e "DBNAME=postfix" \
  -e "DBPASS=xxxxxxx" \
  -v /docker/mail:/var/mail \
  -v /docker/ssl:/ssl \
  hardware/mailserver
```

### Docker-compose

```
mail:
  image: hardware/mailserver
  ports:
    - "25:25"
    - "143:143"
    - "587:587"
    - "993:993"
    - "4190:4190"
  environment:
    - FQDN=mail.domain.tld
    - DOMAIN=domain.tld
    - DBHOST=localhost
    - DBUSER=postfix
    - DBNAME=postfix
    - DBPASS=xxxxxxx
  volumes:
    - /docker/mail:/var/mail
    - /docker/ssl:/ssl

mysql:
  image: mysql:5.7.10
  ports:
    - "3306:3306"
  environment:
    - MYSQL_ROOT_PASSWORD=xxxx
    - MYSQL_DATABASE=postfix
    - MYSQL_USER=postfix
    - MYSQL_PASSWORD=xxxx
```