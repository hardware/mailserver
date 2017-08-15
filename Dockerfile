FROM debian:jessie-slim

LABEL description "Simple and full-featured mail server using Docker" \
      maintainer="Hardware <contact@meshup.net>"

ARG TINI_VER=0.14.0

# https://pgp.mit.edu/pks/lookup?search=0x0B588DFF0527A9B7&fingerprint=on&op=index
# pub  4096R/7001A4E5 2012-07-23 Thomas Orozco <thomas@orozco.fr>
ARG TINI_GPG_SHORTID="0x0527A9B7"
ARG TINI_GPG_FINGERPRINT="6380 DC42 8747 F6C3 93FE  ACA5 9A84 159D 7001 A4E5"
ARG TINI_SHA256_HASH="420e47096487f72e3e48cca85ce379f18f9c6d2c3809ecc4bcf34e2b35f7c490"

RUN BUILD_DEPS=" \
    wget" \
 && apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y -q --no-install-recommends \
    ${BUILD_DEPS} \
    postfix \
    postfix-mysql \
    postfix-pcre \
    postgrey \
    gross \
    dovecot-core \
    dovecot-imapd \
    dovecot-lmtpd \
    dovecot-mysql \
    dovecot-sieve \
    dovecot-managesieved \
    dovecot-pop3d \
    opendkim \
    opendkim-tools \
    opendmarc \
    amavisd-new \
    amavisd-milter \
    spamassassin \
    clamav-daemon \
    clamav-milter \
    libsasl2-modules \
    libsys-syslog-perl \
    libmail-spf-perl \
    libhttp-message-perl \
    fetchmail \
    libdbi-perl \
    libdbd-mysql-perl \
    liblockfile-simple-perl \
    altermime \
    supervisor \
    openssl \
    rsyslog \
    python-pip \
    pigz \
    pxz \
    pbzip2 \
    dnsutils \
    ca-certificates \
 && rm -rf /var/spool/postfix && ln -s /var/mail/postfix/spool /var/spool/postfix \
 && pip install envtpl \
 && cd /tmp \
 && wget -q https://github.com/krallin/tini/releases/download/v$TINI_VER/tini_$TINI_VER.deb \
 && wget -q https://github.com/krallin/tini/releases/download/v$TINI_VER/tini_$TINI_VER.deb.asc \
 && echo "Verifying both integrity and authenticity of tini_${TINI_VER}.deb..." \
 && CHECKSUM=$(sha256sum tini_${TINI_VER}.deb | awk '{print $1}') \
 && if [ "${CHECKSUM}" != "${TINI_SHA256_HASH}" ]; then echo "Warning! tini_${TINI_VER}.deb checksum does not match!" && exit 1; fi \
 && gpg --keyserver keys.gnupg.net --recv-keys ${TINI_GPG_SHORTID} \
 && FINGERPRINT="$(LANG=C gpg --verify tini_${TINI_VER}.deb.asc tini_${TINI_VER}.deb 2>&1 \
  | sed -n "s#Primary key fingerprint: \(.*\)#\1#p")" \
 && if [ -z "${FINGERPRINT}" ]; then echo "Warning! tini_${TINI_VER}.deb.asc invalid GPG signature!" && exit 1; fi \
 && if [ "${FINGERPRINT}" != "${TINI_GPG_FINGERPRINT}" ]; then echo "Warning! tini_${TINI_VER}.deb.asc wrong GPG fingerprint!" && exit 1; fi \
 && echo "All seems good, now unpacking tini_${TINI_VER}.deb..." \
 && dpkg -i tini_$TINI_VER.deb \
 && apt-get purge -y ${BUILD_DEPS} \
 && apt-get autoremove -y \
 && apt-get clean \
 && rm -rf /tmp/* /var/lib/apt/lists/* /var/cache/debconf/*-old

VOLUME /var/mail /etc/opendkim/keys /etc/letsencrypt
EXPOSE 25 143 465 587 993 4190

COPY rootfs /
CMD ["tini","--","startup"]
