# hardware/mailserver

![Mailserver](https://i.imgur.com/7romRth.png "Mailserver")

### Requirement

- Docker 1.0 or higher
- MariaDB
- [Postfixadmin](https://github.com/hardware/postfixadmin) (optional)

### Components

- Postfix 2.11.3
- Dovecot 2.2.13
- OpenDKIM 2.9.2
- OpenDMARC 1.3.0
- Spamassassin 3.4.0
- ClamAV 0.98.7
- Amavisd-new 2.10.1
- Amavisd-milter 1.5.0
- Supervisor 3.0r1
- Rsyslog 8.4.2
- ManageSieve server

### Ports

- **25** : SMTP
- **143** : IMAP (STARTTLS)
- **465** : SMTP (SSL/TLS)
- **587** : SMTP (STARTTLS)
- **993** : IMAP (SSL/TLS)
- **4190** : SIEVE (STARTTLS)

### Install

```
docker pull hardware/mailserver
sudo groupadd -g 1024 vmail
sudo useradd -g vmail -u 1024 vmail -d /mnt/docker/mail
```

### How to use

```
docker run -d \
  --name mailserver \
  -p 25:25 -p 143:143 -p 465:465 -p 587:587 -p 993:993 -p 4190:4190 \
  -e DBHOST=mariadb \
  -e DBUSER=postfix \
  -e DBNAME=postfix \
  -e DBPASS=xxxxxxx \
  -e ADD_DOMAINS=domain2.tld,another-domain.tld \
  -v /mnt/docker/mail:/var/mail \
  -v /mnt/docker/dovecot:/var/lib/dovecot \
  -v /mnt/docker/opendkim:/etc/opendkim/keys \
  -h mail.domain.tld \
  --link mariadb:mariadb \
  hardware/mailserver
```

At first launch, the container takes few minutes to generate SSL certificates (if needed), Diffie-Hellman parameters, DKIM keypair and update clamav database, all of this takes some time, be patient...

You can check startup logs with this command :

```
docker logs -f mailserver
```

Once it's over (5/10 minutes approximately), you can check with `openssl s_client` :

#### SMTP - 25 port (MTA <-> MTA)
```
telnet mail.domain.tld 25
...
Connected to mail.domain.tld.
Escape character is '^]'.
220 mail.domain.tld ESMTP Postfix (Debian/GNU)
ehlo localhost
250-mail.domain.tld
250-PIPELINING
250-SIZE 502400000
250-ETRN
250-STARTTLS
250-ENHANCEDSTATUSCODES
250-8BITMIME
250 DSN
...
quit
```

#### IMAP SSL/TLS - 993 port (IMAPS)
```
openssl s_client -connect mail.domain.tld:993 -tlsextdebug
...
OK [CAPABILITY IMAP4rev1 LITERAL+ SASL-IR LOGIN-REFERRALS ID ENABLE IDLE AUTH=PLAIN AUTH=LOGIN] Dovecot ready.
```

#### IMAP STARTTLS - 143 port (IMAP)
```
openssl s_client -connect mail.domain.tld:143 -starttls imap -tlsextdebug
...
OK Pre-login capabilities listed, post-login capabilities have more.
```

#### SMTP STARTTLS - 587 port (Submission)
```
openssl s_client -connect mail.domain.tld:587 -starttls smtp -tlsextdebug
...
250 DSN
```

#### SMTP SSL/TLS - 465 port (SMTPS)
```
openssl s_client -connect mail.domain.tld:465 -tlsextdebug
...
220 mail.domain.tld ESMTP Postfix (Debian/GNU)
```

### Environment variables

- **VMAILUID** = vmail user id (*optional*, default: 1024)
- **VMAILGID** = vmail group id (*optional*, default: 1024)
- **OPENDKIM_KEY_LENGTH** = Size of your DKIM RSA key pair (*optional*, default: 2048)
- **DBHOST** = MariaDB instance ip/hostname (*optional*, default: mariadb)
- **DBUSER** = MariaDB database username (*optional*, default: postfix)
- **DBNAME** = MariaDB database name (*optional*, default: postfix)
- **DBPASS** = MariaDB database (**required**)
- **ADD_DOMAINS** = add additional domains to the mailserver (needed for dkim keys etc.) (*optional*, default: null)

### Docker-compose

#### Docker-compose.yml

```
mailserver:
  image: hardware/mailserver
  container_name: mailserver
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
    - /mnt/docker/mail:/var/mail
    - /mnt/docker/dovecot:/var/lib/dovecot
    - /mnt/docker/opendkim:/etc/opendkim/keys

postfixadmin:
  image: hardware/postfixadmin
  container_name: postfixadmin
  domainname: domain.tld
  hostname: mail
  links:
    - mariadb:mariadb
  environment:
    - DBHOST=mariadb
    - DBUSER=postfix
    - DBNAME=postfix
    - DBPASS=xxxxxxx

rainloop:
  image: hardware/rainloop
  container_name: rainloop
  links:
    - mailserver:mailserver
    - mariadb:mariadb
  environment:
    - GID=991
    - UID=991
  volumes:
    - /mnt/docker/rainloop:/rainloop/data

nginx:
  image: wonderfall/reverse
  container_name: nginx
  links:
    - postfixadmin:postfixadmin
    - rainloop:rainloop
  ports:
    - "80:8000"
    - "443:4430"
  volumes:
    - /mnt/docker/nginx/sites-enabled:/sites-enabled
    - /mnt/docker/nginx/conf:/conf.d
    - /mnt/docker/nginx/log:/var/log/nginx
    - /mnt/docker/nginx/certs:/certs

mariadb:
  image: mariadb:10.1
  container_name: mariadb
  volumes:
    - /mnt/docker/mysql/db:/var/lib/mysql
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

### Additional configuration

#### Reverse proxy example :

https://github.com/hardware/mailserver/wiki/Reverse-proxy-configuration

#### Postfixadmin initial configuration :

https://github.com/hardware/mailserver/wiki/Postfixadmin-initial-configuration

#### Rainloop initial configuration :

https://github.com/hardware/mailserver/wiki/Rainloop-initial-configuration

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

`/mnt/docker/opendkim/domain.tld/mail.txt`

Test your configuration with this website : https://www.mail-tester.com/

### Let's encrypt

To use your Let's encrypt certificates, you may add another docker volume in this way :

```
docker run -d \
  ...
  -v /etc/letsencrypt:/etc/letsencrypt \
  ...
```

The common name of your ssl certifcate **MUST** be the same as your server's FQDN (for exemple, let's encrypt live subfolder name must be egual to **domainname** & **hostname** values of docker-compose file).


If you do not use let's encrypt, a default self-signed certificate (RSA 4096 bits SHA2) is generated here : `/mnt/docker/mail/ssl/selfsigned/{cert.pem, privkey.pem}`.

### Email client settings :

- IMAP/SMTP username : user@domain.tld
- Incoming IMAP server : mail.domain.tld (your FQDN)
- Outgoing SMTP server : mail.domain.tld (your FQDN)
- IMAP port : 993
- SMTP port : 587
- IMAP Encryption protocol : SSL/TLS
- SMTP Encryption protocol : STARTTLS

## Roadmap

- Quota support

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
