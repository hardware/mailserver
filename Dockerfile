FROM hardware/debian-mail-overlay:latest

LABEL description "Simple and full-featured mail server using Docker" \
      maintainer="Hardware <contact@meshup.net>"

ARG DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y -q --no-install-recommends \
    postfix postfix-pgsql postfix-mysql postfix-pcre libsasl2-modules \
    dovecot-core dovecot-imapd dovecot-lmtpd dovecot-pgsql dovecot-mysql dovecot-sieve dovecot-managesieved dovecot-pop3d \
    fetchmail libdbi-perl libdbd-pg-perl libdbd-mysql-perl liblockfile-simple-perl \
    clamav clamav-daemon \
    python3-pip python3-setuptools python3-wheel \
    rsyslog dnsutils curl unbound jq rsync \
    inotify-tools \
 && rm -rf /var/spool/postfix \
 && ln -s /var/mail/postfix/spool /var/spool/postfix \
 && apt-get autoremove -y \
 && apt-get clean \
 && rm -rf /tmp/* /var/lib/apt/lists/* /var/cache/debconf/*-old \
 && pip3 install watchdog

EXPOSE 25 143 465 587 993 4190 11334
COPY rootfs /
RUN chmod +x /usr/local/bin/* /services/*/run /services/.s6-svscan/finish
CMD ["run.sh"]
