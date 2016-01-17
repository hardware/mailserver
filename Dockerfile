FROM debian:jessie
MAINTAINER Hardware <contact@meshup.net>

ENV FQDN=mail.domain.tld
ENV DBHOST=localhost
ENV DBNAME=postfix
ENV DBUSER=postfix
ENV DBPASS=xxxxxxx

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends --no-install-suggests \
    postfix postfix-mysql \
    dovecot-core dovecot-imapd dovecot-lmtpd dovecot-mysql dovecot-sieve dovecot-managesieved \
    opendkim opendkim-tools opendmarc \
    amavisd-new spamassassin spamc \
    supervisor openssl dnsutils \
    # dovecot-pop3d \ # clamav-milter \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

ADD rootfs /
RUN chmod +x /usr/bin/startup

VOLUME /var/mail /ssl
EXPOSE 25 143 587 993 4190

CMD ["/usr/bin/startup"]