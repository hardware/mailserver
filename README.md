# hardware/mailserver

![Mailserver](https://i.imgur.com/7romRth.png "Mailserver")

### Components

- Postfix 2.11.3
- Dovecot 2.2.13
- OpenDKIM 2.9.2
- OpenDMARC 1.3.0
- Spamassassin 3.4.0
- Postgrey 1.35
- ClamAV 0.98.7
- Amavisd-new 2.10.1
- Amavisd-milter 1.5.0
- Supervisor 3.0r1
- Rsyslog 8.4.2
- ManageSieve server

### How to use

#### 1 - Get latest image

```
docker pull hardware/mailserver
sudo groupadd -g 1024 vmail
sudo useradd -g vmail -u 1024 vmail -d /mnt/docker/mail
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

The DKIM public key is available on host here :

`/mnt/docker/opendkim/domain.tld/mail.txt`

Test your configuration with this website : https://www.mail-tester.com/

#### 7 - Done, congratulation ! :tada:

At first launch, the container takes few minutes to generate SSL certificates (if needed), Diffie-Hellman parameters, DKIM keypair and update clamav database, all of this takes some time, be patient...

You can check startup logs with this command :

```
docker logs -f mailserver
```

Once it's over (5/10 minutes approximately), you can check with `telnet` and `openssl s_client` commands :

```
# SMTP - 25 port (MTA <-> MTA)
telnet mail.domain.tld 25

# IMAP STARTTLS - 143 port (IMAP)
openssl s_client -connect mail.domain.tld:143 -starttls imap -tlsextdebug

# SMTP SSL/TLS - 465 port (SMTPS)
openssl s_client -connect mail.domain.tld:465 -tlsextdebug

# SMTP STARTTLS - 587 port (Submission)
openssl s_client -connect mail.domain.tld:587 -starttls smtp -tlsextdebug

# IMAP SSL/TLS - 993 port (IMAPS)
openssl s_client -connect mail.domain.tld:993 -tlsextdebug
```

### Environment variables

| Variable | Description | Type | Default value |
| -------- | ----------- | ---- | ------------- |
| **VMAILUID** | vmail user id | *optional* | 1024
| **VMAILGID** | vmail group id | *optional* | 1024
| **OPENDKIM_KEY_LENGTH** | Size of your DKIM RSA key pair | *optional* | 2048
| **DBHOST** | MariaDB instance ip/hostname | *optional* | mariadb
| **DBUSER** | MariaDB database username | *optional* | postfix
| **DBNAME** | MariaDB database name | *optional* | postfix
| **DBPASS** | MariaDB database password | **required** | null
| **ADD_DOMAINS** | Add additional domains to the mailserver separated by commas (needed for dkim keys etc.) | *optional* | null
| **DISABLE_CLAMAV** | Disable virus scanning | *optional* | false
| **DISABLE_SPAMASSASSIN** | Disable SPAM checking | *optional* | false
| **ENABLE_POSTGREY** | Enable Postgrey greylisting policy server | *optional* | false
| **ENABLE_POP3** | Enable POP3 protocol | *optional* | false

If **DISABLE_CLAMAV** and **DISABLE_SPAMASSASSIN** are both set to **true**, Amavis is also completely disabled.

### Files/Folders tree

```
/mnt/docker
└──opendkim
   ├──domain.tld
   |    mail.private
   |    mail.txt
└──mail
   ├──postfix
   │     custom.conf
   ├──postgrey
   │     postgrey.db
   │     ...
   ├──sieve
   │     default.sieve
   │     default.svbin
   ├──ssl
   |  ├──dhparams
   │  |     dh512.pem
   │  |     dh2048.pem
   |  ├──live (Let's Encrypt or other CA)
   |  |  ├──mail.domain.tld
   |  |  |     privkey.pem
   |  |  |     cert.pem
   |  |  |     chain.pem
   |  |  |     fullchain.pem
   |  ├──selfsigned (Auto-generated if no certificate found)
   │  |     cert.pem
   │  |     privkey.pem
   ├──vhosts
   |  ├──domain.tld
   |  |  ├──user
   |  |  |     .dovecot.sieve -> sieve/rainloop.user.sieve
   |  |  |     .dovecot.svbin
   |  |  |  ├──mail
   |  |  |  |  ├──.Archive
   |  |  |  |  ├──.Drafts
   |  |  |  |  ├──.Sent
   |  |  |  |  ├──.Spam
   |  |  |  |  ├──.Trash
   |  |  |  |  ├──cur
   |  |  |  |  ├──new
   |  |  |  |     ...
   |  |  |  ├──sieve
   |  |  |  |     rainloop.user.sieve (if using rainloop webmail)
```

### Let's encrypt

To use your Let's encrypt certificates, you may add another docker volume like this :

```
mailserver:
  image: hardware/mailserver
  volumes:
    /etc/letsencrypt:/etc/letsencrypt
  ...
```

- The common name of your ssl certifcate **MUST** be the same as your server's FQDN (for exemple, let's encrypt live subfolder name must be egual to **domainname** & **hostname** values of docker-compose file).

- If you do not use let's encrypt, a default self-signed certificate (RSA 4096 bits SHA2) is generated here : `/mnt/docker/mail/ssl/selfsigned/{cert.pem, privkey.pem}`.

- If you use another CA (other than Let's Encrypt) :

```
mkdir -p /mnt/docker/ssl/live/mail.domain.tld
```

Required files in this folder :

- **privkey.pem** : Private key for the certificate
- **cert.pem** : Server certificate only
- **chain.pem** : Root and intermediate certificates only, excluding server certificate
- **fullchain.pem** : All certificates, including server certificate. This is concatenation of cert.pem and chain.pem

And then mount the volume like this :

```
mailserver:
  image: hardware/mailserver
  volumes:
    /mnt/docker/ssl:/etc/letsencrypt
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
