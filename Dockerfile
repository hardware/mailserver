FROM debian:jessie
MAINTAINER Hardware <contact@meshup.net>

ENV TINI_VER=0.9.0

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    postfix postfix-mysql postfix-pcre \
    dovecot-core dovecot-imapd dovecot-lmtpd dovecot-mysql dovecot-sieve dovecot-managesieved \
    opendkim opendkim-tools opendmarc \
    amavisd-new amavisd-milter spamassassin spamc clamav clamav-milter \
    supervisor openssl rsyslog python-pip \
    wget ca-certificates \
 && pip install envtpl \
 && wget -q https://github.com/krallin/tini/releases/download/v$TINI_VER/tini_$TINI_VER.deb -P /tmp \
 && dpkg -i /tmp/tini_$TINI_VER.deb \
 && apt-get purge -y \
    wget \
 && apt-get clean \
 && rm -rf /tmp/* /var/lib/apt/lists/*

VOLUME /var/mail /var/lib/dovecot /etc/opendkim/keys /etc/letsencrypt
EXPOSE 25 143 465 587 993 4190

COPY rootfs /
CMD ["tini","--","startup"]
