## hardware/mailserver [![](https://badges.gitter.im/hardware-mailserver/Lobby.svg)](https://gitter.im/hardware-mailserver/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

### Build

[![](https://travis-ci.org/hardware/mailserver.svg?branch=master)](https://travis-ci.org/hardware/mailserver) [![](https://images.microbadger.com/badges/version/hardware/mailserver:1.1-latest.svg)](https://microbadger.com/images/hardware/mailserver:1.1-latest)

### Docker image

[![](https://images.microbadger.com/badges/image/hardware/mailserver:1.1-latest.svg)](https://microbadger.com/images/hardware/mailserver:1.1-latest) [![](https://img.shields.io/docker/automated/hardware/mailserver.svg)](https://hub.docker.com/r/hardware/mailserver/builds/) [![](https://img.shields.io/docker/pulls/hardware/mailserver.svg)](https://hub.docker.com/r/hardware/mailserver/) [![](https://img.shields.io/docker/stars/hardware/mailserver.svg)](https://hub.docker.com/r/hardware/mailserver/) [![](https://img.shields.io/badge/bitcoin-donate-green.svg)](https://keybase.io/hardware)

Simple and full-featured mail server as a set of multiple docker images includes :

- **Postfix** : a full set smtp email server
- **Dovecot** : secure imap and pop3 email server
- **Rspamd** : anti-spam filter with SPF, DKIM, DMARC, ARC, ratelimit and greylisting capabilities
- **Clamav** : antivirus with automatic updates
- **Zeyple** : automatic GPG encryption of all your e-mails
- **Sieve** : email filtering (vacation auto-responder, auto-forward...etc)
- **Fetchmail** : fetch e-mails from external IMAP/POP3 server into local mailbox
- **Rainloop** : web based email client
- **Postfixadmin** : web based administration interface
- **Unbound**: recursive caching DNS resolver with DNSSEC support
- **NSD** : authoritative DNS server with DNSSEC support
- **Træfik** : modern HTTP reverse proxy
- **SSL** : lets encrypt with auto-renewal, custom and self-signed certificates support
- Supporting multiple virtual domains over MySQL backend
- Integration tests with Travis CI
- Automated builds on DockerHub

### System Requirements

Please check, if your system meets the following minimum system requirements :

| Type | Without ClamAV | With ClamAV |
| ---- | -------------- | ----------- |
| CPU | 1 GHz | 1 GHz |
| RAM | 1.5 GiB | 2 GiB |
| Disk | 5 GiB (without emails) | 5 GiB (without emails) |
| System | x86_64 | x86_64 |

### Prerequisites

#### Cleaning

Please remove any web server and mail services running on your server. I recommend using a clean installation of your prefered distro. If you are using Debian, remember to remove the default MTA **Exim4** :

```
# apt-get purge exim4*
```

Also make sure that no other application is interfering with mail server configuration :

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

I recommend you to use [hardware/nsd-dnssec](https://github.com/hardware/nsd-dnssec) as an authoritative name server with DNSSEC capabilities. NSD is an authoritative only, high performance, simple and open source name server.

#### DNS records and reverse PTR :

A correct DNS setup is required, this step is very important.

| HOSTNAME | CLASS | TYPE | PRIORITY | VALUE |
| -------- | ----- | ---- | -------- | ----- |
| mail | IN | A/AAAA | any | 1.2.3.4 |
| spam | IN | CNAME | any | mail.domain.tld. |
| webmail | IN | CNAME | any | mail.domain.tld. |
| postfixadmin | IN | CNAME | any | mail.domain.tld. |
| @ | IN | MX | 10 | mail.domain.tld. |
| @ | IN | TXT | any | "v=spf1 a mx ip4:SERVER_IPV4 ~all" |
| mail._domainkey | IN | TXT | any | "v=DKIM1; k=rsa; p=YOUR DKIM Public Key" |
| _dmarc | IN | TXT | any | "v=DMARC1; p=reject; rua=mailto:postmaster@domain.tld; ruf=mailto:admin@domain.tld; fo=0; adkim=s; aspf=s; pct=100; rf=afrf; sp=reject" |

**Notes:**

* Make sure that the **PTR record** of your IP matches the FQDN of your mailserver host. This record is usually set in your web hosting interface.
* DKIM, SPF and DMARC records are recommended to build a good reputation score.
* The DKIM public key will be available on host after the container startup :

```
/mnt/docker/mail/dkim/domain.tld/public.key
```

To regenerate your public and private keys, remove the `/mnt/docker/mail/dkim/domain.tld` folder. By default a **1024-bit** key is generated, you can increase this size by setting the `OPENDKIM_KEY_LENGTH` environment variable with a higher value. Check your domain registrar support to verify that it supports a TXT record long enough for a key larger than 1024 bits.

These DNS record will raise your trust reputation score and reduce abuse of your domain name. You can find more information here :

* http://www.openspf.org/
* http://www.opendkim.org/
* https://dmarc.org/
* http://arc-spec.org/

#### Testing

You can audit your mailserver with the following assessment services :

* https://www.mail-tester.com/
* https://www.hardenize.com/
* https://observatory.mozilla.org/

### Installation

#### 1 - Prepare your environment

```bash
# Create a new docker network for Traefik
docker network create http_network

# Create the required folders and files
mkdir -p /mnt/docker/traefik/acme && cd /mnt/docker
touch docker-compose.yml traefik/traefik.toml traefik/acme/acme.json
chmod 600 docker-compose.yml traefik/traefik.toml traefik/acme/acme.json
```

#### 2 - Get the latest docker-compose.yml and traefik.toml

| Tags | Description |
| ---- | ----------- |
| **1.1-stable** | Stable version (v1.1-stable branch) |
| **1.1-latest** | Latest development build* (master branch) |

\*These builds have been validated through the CI automation system but they are not meant for deployment in production.

* [docker-compose.yml](https://github.com/hardware/mailserver/blob/master/docker-compose.sample.yml)
* [traefik.toml](https://github.com/hardware/mailserver/blob/master/traefik.sample.toml)

Don't forget to replace all values surrounded by **{{ }}** mark. Then, start all services :

```
docker-compose up -d
```

#### 3 - Postfixadmin installation

PostfixAdmin is a web based interface used to manage mailboxes, virtual domains and aliases.

* Docker image : https://github.com/hardware/postfixadmin
* How to setup : [Postfixadmin initial configuration](https://github.com/hardware/mailserver/wiki/Postfixadmin-initial-configuration)

#### 4 - Rainloop installation (optional)

Rainloop is a simple, modern and fast webmail with Sieve scripts support (filters and vacation message), GPG and a modern user interface.

* Docker image : https://github.com/hardware/rainloop
* How to setup : [Rainloop initial configuration](https://github.com/hardware/mailserver/wiki/Rainloop-initial-configuration)

#### 5 - Done, congratulation ! :tada:

At first launch, the container takes few minutes to generate SSL certificates (if needed), DKIM keypair and update clamav database, all of this takes some time (1/2 minutes). This image comes with a snake-oil self-signed certificate, please use your own trusted certificates. [See below](https://github.com/hardware/mailserver#ssl-certificates) for configuration.

**List of webservices available:**

| Service | URI |
| ------- | --- |
| **Traefik dashboard** | https://mail.domain.tld/ |
| **Rspamd dashboard** | https://spam.domain.tld/ |
| **Administration** | https://postfixadmin.domain.tld/ |
| **Webmail** | https://webmail.domain.tld/ |

Traefik dashboard use a basic authentication (user:admin, password:12345), the password can be encoded in MD5, SHA1 and BCrypt. You can use [htpasswd ](https://httpd.apache.org/docs/2.4/programs/htpasswd.html) to generate those ones. Users can be specified directly in the `traefik.toml` file. Rspamd dashboard use the password defined in your `docker-compose.yml`.

You can check the startup logs with this command :

```
# docker logs -f mailserver

[INFO] Let's encrypt live directory found
[INFO] Using /etc/letsencrypt/live/mail.domain.tld folder
[INFO] Creating DKIM keys for domain domain.tld
[INFO] Database hostname found in /etc/hosts
[INFO] Fetchmail forwarding is enabled.
[INFO] Automatic GPG encryption is enabled.
[INFO] ManageSieve protocol is enabled.
[INFO] POP3 protocol is enabled.
-------------------------------------------------------------------------------------
2017-08-26T11:06:58.885562+00:00 mail root: s6-supervise : spawning clamd process
2017-08-26T11:06:59.059077+00:00 mail root: s6-supervise : spawning freshclam process
2017-08-26T11:06:59.395214+00:00 mail root: s6-supervise : spawning rspamd process
2017-08-26T11:07:01.615597+00:00 mail root: s6-supervise : spawning unbound process
2017-08-26T11:07:01.870856+00:00 mail root: s6-supervise : spawning postfix process
2017-08-26T11:07:03.303536+00:00 mail root: s6-supervise : spawning dovecot process
...
```

### Ansible Playbooks

![logo](https://i.imgur.com/tvTG8pN.png)

If you use Ansible, I recommend you to go to see @ksylvan playbooks here : https://github.com/ksylvan/docker-mail-server

### Environment variables

:warning: Use only ASCII printable characters in environment variables : https://en.wikipedia.org/wiki/ASCII#Printable_characters

| Variable | Description | Type | Default value |
| -------- | ----------- | ---- | ------------- |
| **VMAILUID** | vmail user id | *optional* | 1024
| **VMAILGID** | vmail group id | *optional* | 1024
| **VMAIL_SUBDIR** | Individual mailbox' subdirectory | *optional* | mail
| **OPENDKIM_KEY_LENGTH** | Size of your DKIM RSA key pair | *optional* | 1024
| **PASSWORD_SCHEME** | Passwords encryption scheme | *optional* | `SHA512-CRYPT`
| **DBHOST** | MariaDB instance ip/hostname | *optional* | mariadb
| **DBPORT** | MariaDB instance port | *optional* | 3306
| **DBUSER** | MariaDB database username | *optional* | postfix
| **DBNAME** | MariaDB database name | *optional* | postfix
| **DBPASS** | MariaDB database password or location of a file containing it | **required** | null
| **REDIS_HOST** | Redis instance ip/hostname | *optional*  | redis
| **REDIS_PORT** | Redis instance port | *optional*  | 6379
| **REDIS_PASS** | Redis database password or location of a file containing it | *optional* | null
| **REDIS_NUMB** | Redis database number | *optional* | 0
| **RSPAMD_PASSWORD** | Rspamd WebUI and controller password or location of a file containing it | **required** | null
| **ADD_DOMAINS** | Add additional domains to the mailserver separated by commas (needed for dkim keys etc.) | *optional* | null
| **RELAY_NETWORKS** | Additional IPs or networks the mailserver relays without authentication | *optional* | null
| **DISABLE_RSPAMD_MODULE** | List of disabled modules separated by commas | *optional* | null
| **DISABLE_CLAMAV** | Disable virus scanning | *optional* | false
| **DISABLE_SIEVE** | Disable ManageSieve protocol | *optional* | false
| **DISABLE_SIGNING** | Disable DKIM/ARC signing | *optional* | false
| **DISABLE_GREYLISTING** | Disable greylisting policy | *optional* | false
| **DISABLE_RATELIMITING** | Disable ratelimiting policy | *optional* | false
| **DISABLE_DNS_RESOLVER** | Disable the local DNS resolver | *optional* | false
| **ENABLE_POP3** | Enable POP3 protocol | *optional* | false
| **ENABLE_FETCHMAIL** | Enable fetchmail forwarding | *optional* | false
| **ENABLE_ENCRYPTION** | Enable automatic GPG encryption | *optional* | false
| **FETCHMAIL_INTERVAL** | Fetchmail polling interval | *optional* | 10
| **RECIPIENT_DELIMITER** | RFC 5233 subaddress extension separator (single character only) | *optional* | +

* **VMAIL_SUBDIR** is the mail location subdirectory name `/var/mail/vhosts/%domain/%user/$subdir`. For more information, read this : https://wiki.dovecot.org/VirtualUsers/Home
* **PASSWORD_SCHEME** for compatible schemes, read this : https://wiki.dovecot.org/Authentication/PasswordSchemes
* Currently, only a single **RECIPIENT_DELIMITER** is supported. Support for multiple delimiters will arrive with Dovecot v2.3.
* **FETCHMAIL_INTERVAL** must be a number between **1** and **59** minutes.
* Use **DISABLE_DNS_RESOLVER** if you have some DNS troubles and DNSSEC lookup issues with the local DNS resolver.
* Use **DISABLE_RSPAMD_MODULE** to disable any module listed here : https://rspamd.com/doc/modules/

### Automatic GPG encryption of all your e-mails

#### How does it work ?

[Zeyple](https://infertux.com/labs/zeyple/) catches email from the postfix queue, then encrypts it if a corresponding recipient's GPG public key is found. Finally, it puts it back into the queue.

![zeyple](https://i.imgur.com/gGQZL4V.png)

#### Enable automatic GPG encryption

:heavy_exclamation_mark: **Please enable this option carefully and only if you know what you are doing.**

Switch `ENABLE_ENCRYPTION` environment variable to `true`. The public keyring will be saved in `/var/mail/zeyple/keys`.
Please don't change the default value of `RECIPIENT_DELIMITER` (default = "+"). If encryption is enabled with another delimiter, Zeyple could have an unpredictable behavior.

#### Import your public key

:warning: Make sure to send your public key on a gpg keyserver before to run the following command.

```
docker exec -ti mailserver encryption.sh import-key YOUR_KEY_ID
```

#### Import all recipients public keys

This command browses all `/var/mail/vhosts/*` domains directories and users subdirectories to find all the recipients addresses in the mailserver.

```
docker exec -ti mailserver encryption.sh import-all-keys
```

#### Specify another gpg keyserver

```
docker exec -ti mailserver encryption.sh import-key YOUR_KEY_ID hkp://pgp.mit.edu
docker exec -ti mailserver encryption.sh import-all-keys hkp://keys.gnupg.net
```

#### Run other GPG options

You can use all options of gpg command line except an already assigned parameter called `--homedir`.


```bash
docker exec -ti mailserver encryption.sh --list-keys
docker exec -ti mailserver encryption.sh --fingerprint
docker exec -ti mailserver encryption.sh --refresh-keys
docker exec -ti mailserver encryption.sh ...
```

Documentation : https://www.gnupg.org/documentation/manuals/gnupg/Operational-GPG-Commands.html

### Relaying from other networks

The **RELAY_NETWORKS** is a space separated list of additional IP addresses and subnets (in CIDR notation) which the mailserver relays without authentication. Hostnames are possible, but generally disadvised. IPv6 addresses must be surrounded by square brackets. You can also specify an absolut path to a file with IPs and networks so you can keep it on a mounted volume. Note that the file is not monitored for changes.

You can use this variable to allow other local containers to relay via the mailserver. Typically you would set this to the IP range of the default docker bridge (172.17.0.0/16) or the default network of your compose. If you are unable to determine, you might just add all RFC 1918 addresses `192.168.0.0/16 172.16.0.0/12 10.0.0.0/8`

:warning: A value like `0.0.0.0/0` will turn your mailserver into an open relay!

### SSL certificates

#### Let's Encrypt certificates generated by Traefik

To use Let's Encrypt certificates generated by Traefik, mount a new docker volume like this :

```yml
mailserver:
  image: hardware/mailserver
  volumes:
    - /mnt/docker/traefik/acme:/etc/letsencrypt/acme
    ...
```

The startup script read the `acme.json` file generated by Traefik and split into pem files all appropriate certificates (CN = mail.domain.tld).

```
docker logs -f mailserver

[INFO] Search for SSL certificates generated by Traefik
[INFO] acme.json found, dumping into pem files
[INFO] Let's encrypt live directory found
[INFO] Using /etc/letsencrypt/live/mail.domain.tld folder
```

#### Custom certificates

You can use Let's Encrypt or any other certification authority. Setup your `docker-compose.yml` like this :

```yml
mailserver:
  image: hardware/mailserver
  volumes:
    - /mnt/docker/ssl:/etc/letsencrypt
    ...
```

Request your certificates in `/mnt/docker/ssl/live/mail.domain.tld` with an [ACME client](https://letsencrypt.org/docs/client-options/) if you use Let's Encrypt, otherwise get your SSL certificates with the method provided by your CA and put everything needed in this directory.

Required files in this folder :

| Filename | Description |
|----------|-------------|
| privkey.pem | Private key for the certificate |
| cert.pem | Server certificate only |
| chain.pem | Root and intermediate certificates only, excluding server certificate |
| fullchain.pem | All certificates, including server certificate. This is concatenation of cert.pem and chain.pem |

**Notes** :

* Important : When renewing certificates, you must restart the mailserver container.

* If you do not use your own trusted certificates or those generated by Traefik, a default self-signed certificate (RSA 4096 bits SHA2) is added here : `/mnt/docker/mail/ssl/selfsigned/{cert.pem, privkey.pem}`.

* If you have generated a ECDSA certificate with a curve other than `prime256v1` (NIST P-256), you need to change the Postfix TLS configuration because of a change in OpenSSL >= 1.1.0. For example, if you use `secp384r1` elliptic curve with your ECDSA certificate, change the `tls_eecdh_strong_curve` value :

```ini
# /mnt/docker/mail/postfix/custom.conf

tls_eecdh_strong_curve = secp384r1
```

Additional informations about this issue :

* https://github.com/openssl/openssl/issues/2033
* https://bugzilla.redhat.com/show_bug.cgi?id=1473971

#### Testing

```bash
# IMAP STARTTLS - 143 port (IMAP)
openssl s_client -connect mail.domain.tld:143 -starttls imap -tlsextdebug

# SMTP STARTTLS - 587 port (Submission)
openssl s_client -connect mail.domain.tld:587 -starttls smtp -tlsextdebug

# IMAP SSL/TLS - 993 port (IMAPS)
openssl s_client -connect mail.domain.tld:993 -tlsextdebug
```

### Unbound DNS resolver

Unbound is a validating, recursive, and caching DNS resolver inside the container, you can control it with the remote server control utility.

Some examples :

```bash
# Display server status
docker exec -ti mailserver unbound-control status

# Print server statistics
docker exec -ti mailserver unbound-control stats_noreset

# Reload the server. This flushes the cache and reads the config file.
docker exec -ti mailserver unbound-control reload
```

Documentation : https://www.unbound.net/documentation/unbound-control.html

### Persistent files and folders in /mnt/docker/mail Docker volume

```
/mnt/docker
└──mail
   ├──postfix
   |     custom.conf
   |  ├──spool (Postfix queues directory)
   │  │     defer
   │  │     flush
   │  │     hold
   │  │     maildrop
   │  │     ...
   ├──dovecot
   |     instances
   |     ssl-parameters.dat
   |  ├──conf.d (Custom dovecot configuration)
   ├──clamav (ClamAV databases directory)
   │     bytecode.cvd
   │     daily.cld
   │     main.cvd
   ├──rspamd (Rspamd databases directory)
   │     rspamd.rrd
   |     stats.ucl
   ├──zeyple
   │  ├──keys (GPG public keyring)
   │  │     pubring.kbx
   │  │     trustdb.gpg
   │  │     ...
   ├──sieve
   │     default.sieve
   │     custom.sieve (custom default sieve rules for all users)
   ├──dkim
   │  ├──domain.tld
   │  │     private.key
   │  │     public.key
   ├──ssl
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

```ini
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

### Custom configuration for dovecot

Sometimes you might want to add additional configuration parameters or override the default ones. You can do so by placing configuration files to the persistent folder `/mnt/docker/mail/dovecot/conf.d`.

Example:

```bash
# /mnt/docker/mail/dovecot/conf.d/20-imap.conf

protocol imap {

  mail_max_userip_connections = 100

}

# /mnt/docker/mail/dovecot/conf.d/90-quota.conf

plugin {

  quota_rule2 = Trash:storage=+200M
  quota_exceeded_message = You have exceeded your mailbox quota.

}
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

- Postfix 3.1.4
- Dovecot 2.2.27
- Rspamd 1.6.5
- Fetchmail 6.3.26
- ClamAV 0.99.2
- Zeyple 1.2.1
- Unbound 1.6.0
- s6 2.6.1.1
- Rsyslog 8.24.0
- ManageSieve server

### Community projects

- [ksylvan/docker-mail-server](https://github.com/ksylvan/docker-mail-server) : Ansible playbooks to easily deploy hardware/mailserver.
- [rubentrancoso/mailserver-quicksetup](https://github.com/rubentrancoso/mailserver-quicksetup) : Automatic hardware/mailserver deployment on a digitalocean droplet.

### Some useful Thunderbird extensions :

* https://www.enigmail.net/
* https://github.com/moisseev/rspamd-spamness
* https://github.com/lieser/dkim_verifier

[![](https://i.imgur.com/Em7M8F0.png)](https://i.imgur.com/Em7M8F0.png)

### Donation

My Bitcoin address : **1LwRr6jvzPHnZsxjk6u3wcfP555ZeC47Tg**

This address is [signed cryptographically](https://keybase.io/hardware/sigchain#6f79301eac777d7aad942bdf2c32171e1e8f59694ea7125e7973a4f3ed4539d90f) to prove that it belongs to **me**. https://keybase.io/hardware
