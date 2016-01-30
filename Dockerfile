FROM debian:jessie
MAINTAINER Hardware <contact@meshup.net>

ENV DBHOST=mariadb DBUSER=postfix DBNAME=postfix VMAILUID=1024 VMAILGID=1024

RUN export DEBIAN_FRONTEND=noninteractive \
  && apt-get update && apt-get install -y \
    postfix postfix-mysql \
    dovecot-core dovecot-imapd dovecot-lmtpd dovecot-mysql dovecot-sieve dovecot-managesieved \
    opendkim opendkim-tools opendmarc \
    amavisd-new amavisd-milter spamassassin spamc clamav-milter \
    supervisor openssl rsyslog \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

COPY rootfs /
RUN chmod +x /usr/local/bin/*

VOLUME /var/mail /var/lib/dovecot /etc/opendkim/keys /etc/letsencrypt /var/log/mail
EXPOSE 25 143 465 587 993 4190

CMD ["/usr/local/bin/startup"]