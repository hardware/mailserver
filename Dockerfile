FROM debian:jessie
MAINTAINER Hardware <contact@meshup.net>

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    mysql-client curl python-pip \
    postfix postfix-mysql \
    dovecot-core dovecot-imapd dovecot-lmtpd dovecot-mysql dovecot-sieve dovecot-managesieved \
    opendkim opendkim-tools opendmarc \
    amavisd-new amavisd-milter spamassassin spamc clamav clamav-milter \
    supervisor openssl rsyslog \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* \
 && pip install envtpl

VOLUME /var/mail /var/lib/dovecot /etc/opendkim/keys /etc/letsencrypt
EXPOSE 25 143 465 587 993 4190

COPY rootfs /
CMD ["/usr/local/bin/startup"]
