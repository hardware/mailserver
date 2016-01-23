# hardware/mailserver

### Requirement

- Docker 1.0 or higher
- MySQL
- Postfixadmin (optional)

### Components

- Postfix 2.11.3
- Dovecot 2.2.13
- OpenDKIM 2.9.2
- OpenDMARC 1.3.0
- Spamassassin 3.4.0
- ClamAV 0.98.7
- Amavisd-new 2.10.1
- Supervisor 3.0r1
- ManageSieve server

### Ports

- **25** : SMTP
- **143** : IMAP (STARTTLS)
- **465** : SMTP (SSL/TLS)
- **587** : SMTP (STARTTLS)
- **993** : IMAP (SSL/TLS)
- **4190** : SIEVE (STARTTLS)

### Build

```
docker build -t hardware/mailserver
```

### How to use

```
docker run -d \
  -p 25:25 -p 143:143 -p 465:465 -p 587:587 -p 993:993 -p 4190:4190 \
  -e DBHOST=mysql \
  -e DBUSER=postfix \
  -e DBNAME=postfix \
  -e DBPASS=xxxxxxx \
  -v /docker/mail:/var/mail \
  -v /docker/dovecot:/var/lib/dovecot \
  -v /docker/opendkim:/etc/opendkim/keys \
  -h mail.domain.tld \
  hardware/mailserver
```

### Environment variables

- **VMAILUID** = vmail user id (*optional*, default: 1024)
- **VMAILGID** = vmail group id (*optional*, default: 1024)
- **DBHOST** = MySQL instance ip/hostname (*optional*, default: mariadb)
- **DBUSER** = MYSQL database username (*optional*, default: postfix)
- **DBNAME** = MYSQL database name (*optional*, default: postfix)
- **DBPASS** = MYSQL database (**required**)

### Docker-compose

#### Docker-compose.yml

```
mail:
  image: hardware/mailserver
  domainname: domain.tld
  hostname: mail
  links:
    - mariadb:mariadb
  ports:
    - "25:25"
    - "143:143"
    - "465:465"
    - "587:587"
    - "993:993"
    - "4190:4190"
  environment:
    - DBHOST=mariadb
    - DBUSER=postfix
    - DBNAME=postfix
    - DBPASS=xxxxxxx
  volumes:
    - /docker/mail:/var/mail
    - /docker/dovecot:/var/lib/dovecot
    - /docker/opendkim:/etc/opendkim/keys

mariadb:
  image: mariadb:10.1
  ports:
    - "3306:3306"
  volumes:
    - /docker/mysql/db:/var/lib/mysql
  environment:
    - MYSQL_ROOT_PASSWORD=xxxx
    - MYSQL_DATABASE=postfix
    - MYSQL_USER=postfix
    - MYSQL_PASSWORD=xxxx
```

#### Run !

```
docker-compose up -d
```

### DNS records

```
HOSTNAME            CLASS             RECORD TYPE          VALUE
------------------------------------------------------------------------------------------------
mail                IN                A                    SERVER_IPV4
@                   IN                MX          10       mail.domain.tld.
@                   IN                SPF                  "v=spf1 a mx ip4:SERVER_IPV4 ~all"
@                   IN                TXT                  "v=spf1 a mx ip4:SERVER_IPV4 ~all"
mail._domainkey     IN                TXT                  "v=DKIM1; k=rsa; p=DKIM Public Key"
_dmarc              IN                TXT                  "v=DMARC1; p=reject; rua=mailto:postmaster@domain.tld; ruf=mailto:admin@domain.tld; fo=0; adkim=s; aspf=s; pct=100; rf=afrf; sp=reject"
```

The DKIM public key is available on host here :

`/docker/opendkim/domain.tld/mail.txt`

### Let's encrypt

To use your Let's encrypt certificates, you may add another docker volume in this way :

```
docker run -d \
  ...
  -v /etc/letsencrypt:/etc/letsencrypt \
  ...
```

The common name of your ssl certifcate **MUST** must be the same as your server's FQDN.

### Email client settings :

- IMAP/SMTP username : user@domain.tld
- Incoming IMAP server : mail.domain.tld (your FQDN)
- Outgoing SMTP server : mail.domain.tld (your FQDN)
- IMAP port : 993
- SMTP port : 587
- IMAP Encryption protocol : SSL/TLS
- SMTP Encryption protocol : STARTTLS

## Roadmap

- POP3 optional support (port 110 & 995)

## Contribute

- Fork this repository
- Create a new feature branch for a new functionality or bugfix
- Commit your changes
- Push your code and open a new pull request
- Use [issues](https://github.com/hardware/mailserver/issues) for any questions

## Support

https://github.com/hardware/mailserver/issues

## Contact

- [contact@meshup.net](mailto:contact@meshup.net)
- [http://twitter.com/hardvvare](http://twitter.com/hardvvare)

## License

The MIT License (MIT)

Copyright (c) 2016 Hardware, <contact@meshup.net>