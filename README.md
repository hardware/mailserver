## hardware/mailserver [![](https://badges.gitter.im/hardware-mailserver/Lobby.svg)](https://gitter.im/hardware-mailserver/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

### Build

[![](https://travis-ci.org/hardware/mailserver.svg?branch=master)](https://travis-ci.org/hardware/mailserver) [![](https://images.microbadger.com/badges/version/hardware/mailserver.svg)](https://microbadger.com/images/hardware/mailserver)

### Docker image

[![](https://images.microbadger.com/badges/image/hardware/mailserver.svg)](https://microbadger.com/images/hardware/mailserver) [![](https://img.shields.io/docker/automated/hardware/mailserver.svg)](https://hub.docker.com/r/hardware/mailserver/builds/) [![](https://img.shields.io/docker/stars/hardware/mailserver.svg)](https://hub.docker.com/r/hardware/mailserver/)


Simple and full-featured mail server as a set of multiple docker images includes :

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

### How to use

#### 1 - Get latest image

```
# Pull from hub.docker.com :
docker pull hardware/mailserver

# or build it manually :
docker build -t hardware/mailserver https://github.com/hardware/mailserver.git#master
```

#### 2 - Get latest docker-compose.yml

See [docker-compose.sample.yml](https://github.com/hardware/mailserver/blob/master/docker-compose.sample.yml)

**Note :** Change your hostname / domain name, and adapt to your needs

#### 3 - Reverse proxy setup

See [Reverse proxy configuration](https://github.com/hardware/mailserver/wiki/Reverse-proxy-configuration)

Start the mailstack :

```
docker-compose up -d
```

#### 4 - Control panel setup / virtual domains and mailboxes creation

See [Postfixadmin initial configuration](https://github.com/hardware/mailserver/wiki/Postfixadmin-initial-configuration)

#### 5 - Webmail setup (optional)

See [Rainloop initial configuration](https://github.com/hardware/mailserver/wiki/Rainloop-initial-configuration)

#### 6 - DNS records

```
HOSTNAME            CLASS             RECORD TYPE          VALUE
------------------------------------------------------------------------------------------------
mail                IN                A                    SERVER_IPV4
@                   IN                MX          10       mail.domain.tld.
@                   IN                TXT                  "v=spf1 a mx ip4:SERVER_IPV4 ~all"
mail._domainkey     IN                TXT                  "v=DKIM1; k=rsa; p=DKIM Public Key"
_dmarc              IN                TXT                  "v=DMARC1; p=reject; rua=mailto:postmaster@domain.tld; ruf=mailto:admin@domain.tld; fo=0; adkim=s; aspf=s; pct=100; rf=afrf; sp=reject"
```

**The DKIM public key is available on host here** :
`/mnt/docker/mail/opendkim/domain.tld/mail.txt`

See [NSD initial configuration](https://github.com/hardware/mailserver/wiki/NSD-initial-configuration), if you want to setup your own authoritative dns server with dnssec support :lock:

You can audit your mailserver with the following assessment services :

- https://www.mail-tester.com/
- https://observatory.mozilla.org/
- https://www.hardenize.com/

#### 7 - Done, congratulation ! :tada:

At first launch, the container takes few minutes to generate SSL certificates (if needed), Diffie-Hellman parameters, DKIM keypair and update clamav database, all of this takes some time, be patient...

You can check startup logs with this command :

```
docker logs -f mailserver
```

### Environment variables

| Variable | Description | Type | Default value |
| -------- | ----------- | ---- | ------------- |
| **VMAILUID** | vmail user id | *optional* | 1024
| **VMAILGID** | vmail group id | *optional* | 1024
| **VMAIL_SUBDIR** | Individual mailbox' subdirectory | *optional* | mail
| **OPENDKIM_KEY_LENGTH** | Size of your DKIM RSA key pair | *optional* | 2048
| **DBHOST** | MariaDB instance ip/hostname | *optional* | mariadb
| **DBUSER** | MariaDB database username | *optional* | postfix
| **DBNAME** | MariaDB database name | *optional* | postfix
| **DBPASS** | MariaDB database password | **required** | null
| **ADD_DOMAINS** | Add additional domains to the mailserver separated by commas (needed for dkim keys etc.) | *optional* | null
| **DISABLE_CLAMAV** | Disable virus scanning | *optional* | false
| **DISABLE_SPAMASSASSIN** | Disable SPAM checking | *optional* | false
| **DISABLE_SIEVE** | Disable ManageSieve protocol | *optional* | false
| **GREYLISTING** | Enable greylisting policy server | *optional* | off
| **ENABLE_POP3** | Enable POP3 protocol | *optional* | false
| **ENABLE_FETCHMAIL** | Enable fetchmail forwarding | *optional* | false
| **FETCHMAIL_INTERVAL** | Fetchmail polling interval | *optional* | 10
| **RECIPIENT_DELIMITER** | RFC 5233 subaddress extension separator (single character only) | *optional* | +

If **DISABLE_CLAMAV** and **DISABLE_SPAMASSASSIN** are both set to **true**, Amavis is also completely disabled.

The supported values for **GREYLISTING** are `off`, `gross` or `postgrey`. Gross is a more advanced greylisting server which blocks only hosts with a bad DNSBL reputation.

Currently, only a single **RECIPIENT_DELIMITER** is supported. Support for multiple delimiters will arrive with Dovecot v2.3.

**FETCHMAIL_INTERVAL** must be a number between **1** and **59** minutes.

### Files/Folders tree

```
/mnt/docker
└──mail
   ├──postfix
   │     custom.conf
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

### Let's Encrypt certificate authority

To use Let's Encrypt certificates, setup your `docker-compose.yml` file like this :

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

Then generate Let's Encrypt certificates with [xataz/letsencrypt](https://github.com/xataz/dockerfiles/tree/master/letsencrypt), you can use other tools like [lego](https://github.com/xenolf/lego) if you want.

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

- :warning: The common name of your ssl certifcate **MUST** be the same as your server's FQDN (for exemple, let's encrypt live subfolder name must be egual to **domainname** & **hostname** values of docker-compose file). Don't forget to add your FQDN in command above **in first position**.

- If you do not use let's encrypt, a default self-signed certificate (RSA 4096 bits SHA2) is generated here : `/mnt/docker/mail/ssl/selfsigned/{cert.pem, privkey.pem}`.

### Another certificate authority (other than Let's Encrypt)

Put your certificates in `/mnt/docker/nginx/certs/live/mail.domain.tld`

:warning: **Required files in this folder :**

- **privkey.pem** : Private key for the certificate
- **cert.pem** : Server certificate only
- **chain.pem** : Root and intermediate certificates only, excluding server certificate
- **fullchain.pem** : All certificates, including server certificate. This is concatenation of cert.pem and chain.pem

Then mount the volume like this :

```
mailserver:
  image: hardware/mailserver
  volumes:
    - /mnt/docker/nginx/certs:/etc/letsencrypt
    ...
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

## Roadmap

- Use Rspamd instead of Spamassassin
- ClueGetter integration
- LDAP authentification (need contributors)

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

