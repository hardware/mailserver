## hardware/mailserver [![](https://badges.gitter.im/hardware-mailserver/Lobby.svg)](https://gitter.im/hardware-mailserver/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

### Build

[![](https://travis-ci.org/hardware/mailserver.svg?branch=master)](https://travis-ci.org/hardware/mailserver) [![](https://images.microbadger.com/badges/version/hardware/mailserver.svg)](https://microbadger.com/images/hardware/mailserver)

### Docker image

[![](https://images.microbadger.com/badges/image/hardware/mailserver.svg)](https://microbadger.com/images/hardware/mailserver) [![](https://img.shields.io/docker/automated/hardware/mailserver.svg)](https://hub.docker.com/r/hardware/mailserver/builds/) [![](https://img.shields.io/docker/pulls/hardware/mailserver.svg)](https://hub.docker.com/r/hardware/mailserver/) [![](https://img.shields.io/docker/stars/hardware/mailserver.svg)](https://hub.docker.com/r/hardware/mailserver/)

hardware/mailserver is a simple and full-featured mail server suite based on open source software as a set of multiple docker images including :

- **Postfix** : a full set smtp email server supporting custom rules
- **Dovecot** : secure imap and pop3 email server
- **Amavis** : content filter implementing decoding, processing and checking e-mails
- **Spamassassin** : anti-spam filter
- **Clamav** : antivirus with automatic updates
- **OpenDKIM** : implementation of DKIM (Domain Keys Identified Mail)
- **OpenDMARC** : implementation of DMARC (Domain-based Message Authentication, Reporting & Conformance)
- **Sieve** : email filtering (vacation auto-responder, auto-forward...etc)
- **Fetchmail** : fetch e-mails from external IMAP/POP3 server into local mailbox
- **Postgrey** : greylisting policy server
- **Gross** : greylisting of suspicious sources
- **Rainloop** : web based email client
- **Postfixadmin** : web based administration interface
- **NSD** : authoritative DNS server with DNSSEC support
- **Nginx** : web server with HTTP/2 and TLS 1.3 (DRAFT), statically linked against BoringSSL
- **SSL** : lets encrypt and self-signed certificates support
- Supporting multiple virtual domains over MySQL backend
- Integration tests with Travis CI
- Automated builds on DockerHub

### System Requirements

Please check, if your system meets the following minimum system requirements :

| Type | Without ClamAV | With ClamAV |
| ---- | -------------- | ----------- |
| CPU | 1 GHz | 1 GHz |
| RAM | 500 MiB | 1 GiB |
| Disk | 5 GiB (without emails) | 5 GiB (without emails) |
| System | x86_64 | x86_64 |

### Prerequisites

#### Cleaning

Please remove any web server and mail services running on your server. I recommend using a clean installation of your prefered distro. If you are using Debian, remember to remove the default MTA **Exim4** :

```
# apt-get purge exim4*
```

Also make sure that no other application is interferring with mail server configuration :

```
# netstat -tulpn | grep -E -w '25|80|110|143|443|465|587|993|995|4190'
```

If this command returns any results please remove or stop the application running on that port.

#### Ports

If you have a firewall, unblock the following ports, according to your needs :

| Service | Software | Protocol | Port |
| ------- | -------- | -------- | ---- |
| SMTP | Postfix | TCP | 25 |
| HTTP | Nginx | TCP | 80 |
| POP3 | Dovecot | TCP | 110 |
| IMAP | Dovecot | TCP | 143 |
| HTTPS | Nginx | TCP | 443 |
| SMTPS | Postfix | TCP | 465 |
| Submission | Postfix | TCP | 587 |
| IMAPS | Dovecot | TCP | 993 |
| POP3S | Dovecot | TCP | 995 |
| ManageSieve | Dovecot | TCP | 4190 |

#### DNS setup

I recommend you to use [hardware/nsd-dnssec](https://github.com/hardware/nsd-dnssec) as an authoritative name server with DNSSEC capabilities. NSD is an authoritative only, high performance, simple and open source name server. This docker image is really easy to use.

**How to setup :** [NSD initial configuration](https://github.com/hardware/mailserver/wiki/NSD-initial-configuration)

#### Mandatory DNS records (A/MX) and reverse PTR :

A correct DNS setup is required, this step is very important.

| HOSTNAME | CLASS | TYPE | PRIORITY | VALUE |
| -------- | ----- | ---- | -------- | ----- |
| mail | IN | A/AAAA | any | 1.2.3.4 |
| @ | IN | MX | 10 | mail.domain.tld. |

Make sure that the **PTR record** of your IP matches the FQDN of your mailserver host. This record is usually set in your web hosting interface.

#### Recommended DNS records

DKIM, SPF and DMARC are recommended to build a good reputation score.

| HOSTNAME | CLASS | TYPE | PRIORITY | VALUE |
| -------- | ----- | ---- | -------- | ----- |
| @ | IN | TXT | any | "v=spf1 a mx ip4:SERVER_IPV4 ~all" |
| mail._domainkey | IN | TXT | any | "v=DKIM1; k=rsa; p=YOUR DKIM Public Key" |
| _dmarc | IN | TXT | any | "v=DMARC1; p=reject; rua=mailto:postmaster@domain.tld; ruf=mailto:admin@domain.tld; fo=0; adkim=s; aspf=s; pct=100; rf=afrf; sp=reject" |

**Note:** The DKIM public key will be available on host after the container startup :

```
/mnt/docker/mail/opendkim/domain.tld/mail.txt
```

These DNS record will raise your trust reputation score and reduce abuse of your domain name. You can find more information here :

* http://www.openspf.org/
* http://www.opendkim.org/
* https://dmarc.org/

#### Testing

You can audit your mailserver with the following assessment services :

* https://www.mail-tester.com/
* https://www.hardenize.com/
* https://observatory.mozilla.org/

### Installation

#### 1 - Pull the latest image from docker hub

```bash
# Pull from hub.docker.com :
docker pull hardware/mailserver

# or build it manually :
docker build -t hardware/mailserver https://github.com/hardware/mailserver.git#master
```

For security reasons, you should regularly update the mail setup and docker images.

#### 2 - Get the latest docker-compose.yml

Change your hostname and domain name, adapt to your needs : [docker-compose.sample.yml](https://github.com/hardware/mailserver/blob/master/docker-compose.sample.yml)

**Run the stack :**

```
mv docker-compose.sample.yml docker-compose.yml
docker-compose -f docker-compose.yml up -d
```

#### 3 - Reverse proxy setup

I recommend you to use [wonderfall/boring-nginx](https://github.com/Wonderfall/dockerfiles/tree/master/boring-nginx) as a reverse proxy. Nginx is statically linked against BoringSSL, with embedded Brotli support, TLS 1.3, X25519, HTTP/2 and hardening standards.

**More information here :** [Reverse proxy configuration](https://github.com/hardware/mailserver/wiki/Reverse-proxy-configuration)

#### 4 - Postfixadmin installation

PostfixAdmin is a web based interface used to manage mailboxes, virtual domains and aliases.

* **Docker image :** https://github.com/hardware/postfixadmin
* **How to setup :** [Postfixadmin initial configuration](https://github.com/hardware/mailserver/wiki/Postfixadmin-initial-configuration)

#### 5 - Rainloop installation (optional)

Rainloop is a simple, modern and fast webmail with Sieve scripts support (filters and vacation message), GPG and a modern user interface.

* **Docker image :** https://github.com/hardware/rainloop
* **How to setup :** [Rainloop initial configuration](https://github.com/hardware/mailserver/wiki/Rainloop-initial-configuration)

#### 6 - Done, congratulation ! :tada:

At first launch, the container takes few minutes to generate SSL certificates (if needed), Diffie-Hellman parameters, DKIM keypair and update clamav database, all of this takes some time (2/3 minutes), be patient...

This image comes with a snake-oil self-signed certificate, please use your own trusted certificates. [See below](https://github.com/hardware/mailserver#ssl-certificates) for configuration.

You can check the startup logs with this command :

```
docker logs -f mailserver
```

### Environment variables

:warning: Use only ASCII printable characters in environment variables : https://en.wikipedia.org/wiki/ASCII#Printable_characters

Github issue : https://github.com/hardware/mailserver/issues/118

| Variable | Description | Type | Default value |
| -------- | ----------- | ---- | ------------- |
| **VMAILUID** | vmail user id | *optional* | 1024
| **VMAILGID** | vmail group id | *optional* | 1024
| **VMAIL_SUBDIR** | Individual mailbox' subdirectory | *optional* | mail
| **OPENDKIM_KEY_LENGTH** | Size of your DKIM RSA key pair | *optional* | 2048
| **DBHOST** | MariaDB instance ip/hostname | *optional* | mariadb
| **DBPORT** | MariaDB instance port | *optional* | 3306
| **DBUSER** | MariaDB database username | *optional* | postfix
| **DBNAME** | MariaDB database name | *optional* | postfix
| **DBPASS** | MariaDB database password | **required** | null
| **ADD_DOMAINS** | Add additional domains to the mailserver separated by commas (needed for dkim keys etc.) | *optional* | null
| **RELAY_NETWORKS** | Additional IPs or networks the mailserver relays without authentication | *optional* | null
| **DISABLE_CLAMAV** | Disable virus scanning | *optional* | false
| **DISABLE_SPAMASSASSIN** | Disable SPAM checking | *optional* | false
| **DISABLE_SIEVE** | Disable ManageSieve protocol | *optional* | false
| **GREYLISTING** | Enable greylisting policy server | *optional* | off
| **ENABLE_POP3** | Enable POP3 protocol | *optional* | false
| **ENABLE_FETCHMAIL** | Enable fetchmail forwarding | *optional* | false
| **FETCHMAIL_INTERVAL** | Fetchmail polling interval | *optional* | 10
| **RECIPIENT_DELIMITER** | RFC 5233 subaddress extension separator (single character only) | *optional* | +

* If **DISABLE_CLAMAV** and **DISABLE_SPAMASSASSIN** are both set to **true**, Amavis is also completely disabled.
* The supported values for **GREYLISTING** are `off`, `gross` or `postgrey`. Gross is a more advanced greylisting server which blocks only hosts with a bad DNSBL reputation.
* Currently, only a single **RECIPIENT_DELIMITER** is supported. Support for multiple delimiters will arrive with Dovecot v2.3.
* **FETCHMAIL_INTERVAL** must be a number between **1** and **59** minutes.

### Relaying from other networks

The **RELAY_NETWORKS** is a space separated list of additional IP addresses and subnets (in CIDR notation) which the mailserver relays without authentication. Hostnames are possible, but generally disadvised. IPv6 addresses must be surrounded by square brackets. You can also specify an absolut path to a file with IPs and networks so you can keep it on a mounted volume. Note that the file is not monitored for changes.

You can use this variable to allow other local containers to relay via the mailserver. Typically you would set this to the IP range of the default docker bridge (172.17.0.0/16) or the default network of your compose. If you are unable to determine, you might just add all RFC 1918 addresses `192.168.0.0/16 172.16.0.0/12 10.0.0.0/8`

:warning: A value like `0.0.0.0/0` will turn your mailserver into an open relay!

### SSL certificates

#### Let's Encrypt certificate authority

This mail setup uses 3 domain names that should be covered by your new certificate :

* **mail.domain.tld** (mandatory)
* **postfixadmin.domain.tld** (recommended)
* **webmail.domain.tld** (optional)

To use the Let's Encrypt certificates, you can setup your `docker-compose.yml` like this :

```
mailserver:
  image: hardware/mailserver
  volumes:
    - /mnt/docker/nginx/certs:/etc/letsencrypt
    ...

nginx:
  image: wonderfall/boring-nginx
  volumes:
    - /mnt/docker/nginx/certs:/certs
    ...
```

And request the certificate with [xataz/letsencrypt](https://github.com/xataz/dockerfiles/tree/master/letsencrypt) or [cerbot](https://certbot.eff.org/) :

```
docker-compose stop nginx

docker run -it --rm \
  -v /mnt/docker/nginx/certs:/etc/letsencrypt \
  -p 80:80 -p 443:443 \
  xataz/letsencrypt \
    certonly --standalone \
    --rsa-key-size 4096 \
    --agree-tos \
    -m contact@domain.tld \
    -d mail.domain.tld \ # <--- Mail FQDN is the first domain name, very important !
    -d webmail.domain.tld \
    -d postfixadmin.domain.tld

docker-compose up -d
```

* **Important :** When renewing certificates, you must restart affected containers.

* :warning: The common name of your ssl certifcate **MUST** be the same as your server's FQDN (for example, let's encrypt live subfolder name must be equal to **domainname** & **hostname** values of docker-compose file). Don't forget to add your FQDN in command above **in first position**.

* If you do not use let's encrypt, a default self-signed certificate (RSA 4096 bits SHA2) is generated here : `/mnt/docker/mail/ssl/selfsigned/{cert.pem, privkey.pem}`.

#### Another certificate authority (other than Let's Encrypt)

Place all your certificates in `/mnt/docker/nginx/certs/live/mail.domain.tld`

**Required files in this folder :**

| Filename | Description |
|----------|-------------|
| privkey.pem | Private key for the certificate |
| cert.pem | Server certificate only |
| chain.pem | Root and intermediate certificates only, excluding server certificate |
| fullchain.pem | All certificates, including server certificate. This is concatenation of cert.pem and chain.pem |

Then mount the volume like this :

```
mailserver:
  image: hardware/mailserver
  volumes:
    - /mnt/docker/nginx/certs:/etc/letsencrypt
    ...
```

You must restart affected containers.

#### Testing

```bash
# IMAP STARTTLS - 143 port (IMAP)
openssl s_client -connect mail.domain.tld:143 -starttls imap -tlsextdebug

# SMTP STARTTLS - 587 port (Submission)
openssl s_client -connect mail.domain.tld:587 -starttls smtp -tlsextdebug

# IMAP SSL/TLS - 993 port (IMAPS)
openssl s_client -connect mail.domain.tld:993 -tlsextdebug
```

### Files/Folders tree

```
/mnt/docker
└──mail
   ├──postfix
   │     custom.conf
   |  ├──spool (Postfix queues directory)
   │  │     defer
   │  │     flush
   │  │     hold
   │  │     maildrop
   │  │     ...
   ├──clamav (ClamAV databases directory)
   │     bytecode.cvd
   │     daily.cld
   │     main.cvd
   ├──amavis
   |  ├──bayes
   |  ├──quarantine
   ├──postgrey
   │     postgrey.db
   │     ...
   ├──gross
   │     grossd.state
   ├──sieve
   │     default.sieve
   │     default.svbin
   ├──opendkim
   │  ├──domain.tld
   │  │     mail.private
   │  │     mail.txt
   ├──ssl
   │  ├──dhparams
   │  │     dh512.pem
   │  │     dh2048.pem
   │  ├──live (Let's Encrypt or other CA)
   │  │  ├──mail.domain.tld
   │  │  │     privkey.pem
   │  │  │     cert.pem
   │  │  │     chain.pem
   │  │  │     fullchain.pem
   │  ├──selfsigned (Auto-generated if no certificate found)
   │  │     cert.pem
   │  │     privkey.pem
   ├──vhosts
   │  ├──domain.tld
   │  │  ├──user
   │  │  │     .dovecot.sieve -> sieve/rainloop.user.sieve
   │  │  │     .dovecot.svbin
   │  │  │  ├──mail
   │  │  │  │  ├──.Archive
   │  │  │  │  ├──.Drafts
   │  │  │  │  ├──.Sent
   │  │  │  │  ├──.Spam
   │  │  │  │  ├──.Trash
   │  │  │  │  ├──cur
   │  │  │  │  ├──new
   │  │  │  │     ...
   │  │  │  ├──sieve
   │  │  │  │     rainloop.user.sieve (if using rainloop webmail)
```

### Override postfix configuration

Postfix default configuration can be overrided providing a custom configuration file at postfix format. This can be
used to also add configuration that are not in default configuration. [Postfix documentation](http://www.postfix.org/documentation.html) remains the best place
to find configuration options.

Each line in the provided file will be loaded into Postfix. Create a new file here `/mnt/docker/mail/postfix/custom.conf`
and add your custom options inside.

Example :

```
# /mnt/docker/mail/postfix/custom.conf

smtpd_banner = $myhostname ESMTP MyGreatMailServer
inet_protocols = ipv4
delay_notice_recipient = admin@domain.tld
delay_warning_time = 2h
```

```
docker logs -f mailserver

[INFO] Override : smtpd_banner = $myhostname ESMTP MyGreatMailServer
[INFO] Override : inet_protocols = ipv4
[INFO] Override : delay_notice_recipient = postmaster@domain.tld
[INFO] Override : delay_warning_time = 2h
[INFO] Custom Postfix configuration file loaded
```

### Email client settings :

- IMAP/SMTP username : user@domain.tld
- Incoming IMAP server : mail.domain.tld (your FQDN)
- Outgoing SMTP server : mail.domain.tld (your FQDN)
- IMAP port : 993
- SMTP port : 587
- IMAP Encryption protocol : SSL/TLS
- SMTP Encryption protocol : STARTTLS

### Components

- Postfix 2.11.3
- Dovecot 2.2.13
- OpenDKIM 2.9.2
- OpenDMARC 1.3.0
- Spamassassin 3.4.0
- Postgrey 1.35
- Fetchmail 6.3.26
- ClamAV 0.98.7
- Amavisd-new 2.10.1
- Amavisd-milter 1.5.0
- Supervisor 3.0r1
- Rsyslog 8.4.2
- ManageSieve server

## How to contribute

- Fork this repository
- Create a new feature branch for a new functionality or bugfix
- Code...
- Add integration tests in test/tests.bats
- Use `make` to build image locally and run tests
- Document your improvements
- Commit your changes
- Push your code and open a new pull request
- Use [issues](https://github.com/hardware/mailserver/issues) for any questions

