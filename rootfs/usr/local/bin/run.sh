#!/bin/bash

# ENV
export FQDN
export DOMAIN
export VMAILUID
export VMAILGID
export VMAIL_SUBDIR
export DBHOST
export DBPORT
export DBNAME
export DBUSER
export REDIS_HOST
export REDIS_PORT
export REDIS_PASS
export REDIS_NUMB
export CAFILE
export CERTFILE
export KEYFILE
export FULLCHAIN
export DISABLE_CLAMAV
export RECIPIENT_DELIMITER
export FETCHMAIL_INTERVAL
export RELAY_NETWORKS
export PASSWORD_SCHEME

FQDN=${FQDN:-$(hostname --fqdn)}
DOMAIN=${DOMAIN:-$(hostname --domain)}
VMAILUID=${VMAILUID:-1024}
VMAILGID=${VMAILGID:-1024}
VMAIL_SUBDIR=${VMAIL_SUBDIR:-"mail"}
DBHOST=${DBHOST:-mariadb}
DBPORT=${DBPORT:-3306}
DBNAME=${DBNAME:-postfix}
DBUSER=${DBUSER:-postfix}
REDIS_HOST=${REDIS_HOST:-redis}
REDIS_PORT=${REDIS_PORT:-6379}
REDIS_PASS=${REDIS_PASS:-}
REDIS_NUMB=${REDIS_NUMB:-0}
DISABLE_CLAMAV=${DISABLE_CLAMAV:-false}
DISABLE_SIEVE=${DISABLE_SIEVE:-false}
DISABLE_SIGNING=${DISABLE_SIGNING:-false}
DISABLE_GREYLISTING=${DISABLE_GREYLISTING:-false}
DISABLE_RATELIMITING=${DISABLE_RATELIMITING:-false}
ENABLE_POP3=${ENABLE_POP3:-false}
ENABLE_FETCHMAIL=${ENABLE_FETCHMAIL:-false}
ENABLE_ENCRYPTION=${ENABLE_ENCRYPTION:-false}
TESTING=${TESTING:-false}
OPENDKIM_KEY_LENGTH=${OPENDKIM_KEY_LENGTH:-1024}
ADD_DOMAINS=${ADD_DOMAINS:-}
RECIPIENT_DELIMITER=${RECIPIENT_DELIMITER:-"+"}
FETCHMAIL_INTERVAL=${FETCHMAIL_INTERVAL:-10}
RELAY_NETWORKS=${RELAY_NETWORKS:-}
PASSWORD_SCHEME=${PASSWORD_SCHEME:-"SHA512-CRYPT"}

if [ -z "$DBPASS" ]; then
  echo "[ERROR] Mariadb database password must be set !"
  exit 1
fi

if [ -z "$RSPAMD_PASSWORD" ]; then
  echo "[ERROR] Rspamd password must be set !"
  exit 1
fi

if [ -z "$FQDN" ]; then
  echo "[ERROR] The fully qualified domain name must be set !"
  exit 1
fi

if [ -z "$DOMAIN" ]; then
  echo "[ERROR] The domain name must be set !"
  exit 1
fi

# https://github.com/docker-library/redis/issues/53
if [[ "$REDIS_PORT" =~ [^[:digit:]] ]]
then
  REDIS_PORT=6379
fi

# SSL certificates
LETS_ENCRYPT_LIVE_PATH=/etc/letsencrypt/live/"$FQDN"

if [ -d "$LETS_ENCRYPT_LIVE_PATH" ]; then

  echo "[INFO] Let's encrypt live directory found"
  echo "[INFO] Using $LETS_ENCRYPT_LIVE_PATH folder"

  FULLCHAIN="$LETS_ENCRYPT_LIVE_PATH"/fullchain.pem
  CAFILE="$LETS_ENCRYPT_LIVE_PATH"/chain.pem
  CERTFILE="$LETS_ENCRYPT_LIVE_PATH"/cert.pem
  KEYFILE="$LETS_ENCRYPT_LIVE_PATH"/privkey.pem

  # When using https://github.com/JrCs/docker-nginx-proxy-letsencrypt
  # and https://github.com/jwilder/nginx-proxy there is only key.pem and fullchain.pem
  # so we look for key.pem and extract cert.pem and chain.pem
  if [ ! -e "$KEYFILE" ]; then
    KEYFILE="$LETS_ENCRYPT_LIVE_PATH"/key.pem
  fi

  if [ ! -e "$KEYFILE" ]; then
    echo "[ERROR] No keyfile found in $LETS_ENCRYPT_LIVE_PATH !"
    exit 1
  fi

  if [ ! -e "$CAFILE" ] || [ ! -e "$CERTFILE" ]; then
    if [ ! -e "$FULLCHAIN" ]; then
      echo "[ERROR] No fullchain found in $LETS_ENCRYPT_LIVE_PATH !"
      exit 1
    fi

    awk -v path="$LETS_ENCRYPT_LIVE_PATH" 'BEGIN {c=0;} /BEGIN CERT/{c++} { print > path"/cert" c ".pem"}' < "$FULLCHAIN"
    mv "$LETS_ENCRYPT_LIVE_PATH"/cert1.pem "$CERTFILE"
    mv "$LETS_ENCRYPT_LIVE_PATH"/cert2.pem "$CAFILE"
  fi

else

  echo "[INFO] No Let's encrypt live directory found"
  echo "[INFO] Using /var/mail/ssl/selfsigned/ folder"

  FULLCHAIN=/var/mail/ssl/selfsigned/cert.pem
  CAFILE=
  CERTFILE=/var/mail/ssl/selfsigned/cert.pem
  KEYFILE=/var/mail/ssl/selfsigned/privkey.pem

  if [ ! -e "$CERTFILE" ] || [ ! -e "$KEYFILE" ]; then
    echo "[INFO] No SSL certificates found, generating new selfsigned certificate"
    mkdir -p /var/mail/ssl/selfsigned/
    openssl req -new -newkey rsa:4096 -days 3658 -sha256 -nodes -x509 \
      -subj "/C=FR/ST=France/L=Paris/O=Mailserver certificate/OU=Mail/CN=*.${DOMAIN}/emailAddress=postmaster@${DOMAIN}" \
      -keyout "$KEYFILE" \
      -out "$CERTFILE"
  fi
fi

if [ ! -d "$LETS_ENCRYPT_LIVE_PATH" ]; then
  sed -i '/^\(smtp_tls_CAfile\|smtpd_tls_CAfile\)/s/^/#/' /etc/postfix/main.cf
fi

# Diffie-Hellman parameters
if [ ! -e /var/mail/ssl/dhparams/dh2048.pem ] || [ ! -e /var/mail/ssl/dhparams/dh512.pem ]; then
  echo "[INFO] Diffie-Hellman parameters not found, generating new DH params"
  mkdir -p /var/mail/ssl/dhparams/
  openssl dhparam -out /var/mail/ssl/dhparams/dh2048.pem 2048
  openssl dhparam -out /var/mail/ssl/dhparams/dh512.pem 512
fi

# Add domains from ENV DOMAIN and ADD_DOMAINS
domains=(${DOMAIN})
domains+=(${ADD_DOMAINS//,/ })

for domain in "${domains[@]}"; do

  mkdir -p /var/mail/vhosts/"$domain"
  mkdir -p /var/mail/dkim/"$domain"

  if [ -f /var/mail/opendkim/"$domain"/mail.private ]; then
    echo "[INFO] Found an old DKIM keys, migrating files to the new location"
    mv /var/mail/opendkim/"$domain"/mail.private /var/mail/dkim/"$domain"/private.key
    mv /var/mail/opendkim/"$domain"/mail.txt /var/mail/dkim/"$domain"/public.key
    rm -rf /var/mail/opendkim/"$domain"
    rmdir --ignore-fail-on-non-empty /var/mail/opendkim
  elif [ ! -f /var/mail/dkim/"$domain"/private.key ]; then
    echo "[INFO] Creating DKIM keys for domain $domain"
    rspamadm dkim_keygen \
      --selector=mail \
      --domain="$domain" \
      --bits="$OPENDKIM_KEY_LENGTH" \
      --privkey=/var/mail/dkim/"$domain"/private.key \
      > /var/mail/dkim/"$domain"/public.key
  else
    echo "[INFO] Found DKIM key pair for domain $domain - skip creation"
  fi

done

# Avoid envtpl error if cron file doesn't exist
if [ ! -f /etc/cron.d/fetchmail ]; then
  touch /etc/cron.d/fetchmail
fi

# Replace ENV vars
_envtpl() {
  mv "$1" "$1.tpl" # envtpl requires files to have .tpl extension
  envtpl "$1.tpl"
}

_envtpl /etc/postfix/main.cf
_envtpl /etc/postfix/virtual
_envtpl /etc/postfix/header_checks
_envtpl /etc/postfix/sql/sender-login-maps.cf
_envtpl /etc/postfix/sql/virtual-mailbox-domains.cf
_envtpl /etc/postfix/sql/virtual-mailbox-maps.cf
_envtpl /etc/postfix/sql/virtual-alias-domain-mailbox-maps.cf
_envtpl /etc/postfix/sql/virtual-alias-maps.cf
_envtpl /etc/postfix/sql/virtual-alias-domain-maps.cf
_envtpl /etc/postfix/sql/virtual-alias-domain-catchall-maps.cf
_envtpl /etc/postfixadmin/fetchmail.conf
_envtpl /etc/dovecot/dovecot-sql.conf.ext
_envtpl /etc/dovecot/dovecot-dict-sql.conf.ext
_envtpl /etc/dovecot/conf.d/10-mail.conf
_envtpl /etc/dovecot/conf.d/10-ssl.conf
_envtpl /etc/dovecot/conf.d/15-lda.conf
_envtpl /etc/dovecot/conf.d/20-lmtp.conf
_envtpl /etc/rspamd/local.d/redis.conf
_envtpl /etc/rspamd/local.d/statistic.conf
_envtpl /etc/cron.d/fetchmail
_envtpl /etc/mailname
_envtpl /usr/local/bin/quota-warning.sh
_envtpl /usr/local/bin/fetchmail.pl

# Override Postfix configuration
if [ -f /var/mail/postfix/custom.conf ]; then
  while read line; do
    echo "[INFO] Override : ${line}"
    postconf -e "$line"
  done < /var/mail/postfix/custom.conf
  echo "[INFO] Custom Postfix configuration file loaded"
else
  echo "[INFO] No extra postfix settings loaded because optional custom configuration file (/var/mail/postfix/custom.conf) is not provided."
fi

# Check mariadb hostname
grep -q "${DBHOST}" /etc/hosts

if [ $? -ne 0 ]; then
  echo "[INFO] MariaDB hostname not found in /etc/hosts, try to find container IP with docker embedded DNS server"
  IP=$(dig A ${DBHOST} +short)
  if [ -n "$IP" ]; then
    echo "[INFO] Container IP found, adding a new record in /etc/hosts"
    echo "${IP} ${DBHOST}" >> /etc/hosts
  else
    echo "[ERROR] Container IP not found with embedded DNS server... Abort !"
    exit 1
  fi
else
  echo "[INFO] MariaDB hostname found in /etc/hosts"
fi

# Check redis hostname
grep -q "${REDIS_HOST}" /etc/hosts

if [ $? -ne 0 ]; then
  echo "[INFO] Redis hostname not found in /etc/hosts, try to find container IP with docker embedded DNS server"
  IP=$(dig A ${REDIS_HOST} +short)
  if [ -n "$IP" ]; then
    echo "[INFO] Container IP found, adding a new record in /etc/hosts"
    echo "${IP} ${REDIS_HOST}" >> /etc/hosts
  else
    echo "[ERROR] Container IP not found with embedded DNS server... Abort !"
    exit 1
  fi
else
  echo "[INFO] Redis hostname found in /etc/hosts"
fi

# DOVECOT TUNING
# ---------------
# process_min_avail = number of CPU cores, so that all of them will be used
DOVECOT_MIN_PROCESS=$(nproc)

# NbMaxUsers = ( 500 * nbCores ) / 5
# So on a two-core server that's 1000 processes/200 users
# with ~5 open connections per user
DOVECOT_MAX_PROCESS=$((`nproc` * 500))

sed -i -e "s/DOVECOT_MIN_PROCESS/${DOVECOT_MIN_PROCESS}/" \
       -e "s/DOVECOT_MAX_PROCESS/${DOVECOT_MAX_PROCESS}/" /etc/dovecot/conf.d/10-master.conf

# Disable virus check if asked
if [ "$DISABLE_CLAMAV" = true ]; then
  echo "[INFO] ClamAV is disabled, service will not start."
  rm -f /etc/rspamd/local.d/antivirus.conf
fi

# Disable fetchmail forwarding
if [ "$ENABLE_FETCHMAIL" = false ]; then
  echo "[INFO] Fetchmail forwarding is disabled."
  rm -f /etc/cron.d/fetchmail
else
  echo "[INFO] Fetchmail forwarding is enabled."
fi

# Disable automatic GPG encryption
if [ "$ENABLE_ENCRYPTION" = false ]; then
  echo "[INFO] Automatic GPG encryption is disabled."
  sed -i '/content_filter/ s/^/#/' /etc/postfix/main.cf
else
  echo "[INFO] Automatic GPG encryption is enabled."
fi

# Enable ManageSieve protocol
if [ "$DISABLE_SIEVE" = false ]; then
  echo "[INFO] ManageSieve protocol is enabled."
  sed -i '/^protocols/s/$/ sieve/' /etc/dovecot/dovecot.conf
else
  echo "[INFO] ManageSieve protocol is disabled."
fi

# Disable DKIM/ARC signing
if [ "$DISABLE_SIGNING" = true ]; then
  echo "[INFO] DKIM/ARC signing is disabled."
  echo "enabled = false;" > /etc/rspamd/local.d/arc.conf
  echo "enabled = false;" > /etc/rspamd/local.d/dkim_signing.conf
fi

# Disable greylisting policy
if [ "$DISABLE_GREYLISTING" = true ]; then
  echo "[INFO] Greylisting policy is disabled."
  echo "enabled = false;" > /etc/rspamd/local.d/greylisting.conf
fi

# Disable ratelimiting policy
if [ "$DISABLE_RATELIMITING" = true ]; then
  echo "[INFO] Ratelimiting policy is disabled."
  echo "enabled = false;" > /etc/rspamd/local.d/ratelimit.conf
fi

# Enable POP3 protocol
if [ "$ENABLE_POP3" = true ]; then
  echo "[INFO] POP3 protocol is enabled."
  sed -i '/^protocols/s/$/ pop3/' /etc/dovecot/dovecot.conf
fi

if [ "$TESTING" = true ]; then
  echo "[INFO] DOCKER IMAGE UNDER TESTING"
  # Disable postfix virtual table
  sed -i '/etc\/postfix\/virtual/ s/^/#/' /etc/postfix/main.cf
  # Disable dkim and arc signing locally
  sed -i 's|\(sign_local.*=\).*|\1 false;|' /etc/rspamd/local.d/dkim_signing.conf
  sed -i 's|\(sign_local.*=\).*|\1 false;|' /etc/rspamd/local.d/arc.conf
  # Speed up dovecot startup with smaller dh params
  sed -i 's|\(ssl_dh_parameters_length.*=\).*|\1 512|' /etc/dovecot/conf.d/10-ssl.conf
  # Zeyple logs are needed for testing (default: logs are redirected to /dev/null)
  sed -i 's|\(log_file.*=\).*|\1 /var/log/zeyple.log|' /etc/zeyple/zeyple.conf
  # Disable fetchmail scheduled Task
  rm -f /etc/cron.d/fetchmail
else
  # /var/log/mail.log is not needed in production
  sed -i '/mail.log/d' /etc/rsyslog/rsyslog.conf
fi

# Move clamav databases and dovecot lib directory to /var/mail
if [ -d "/var/mail/dovecot" ]; then
  rm -rf /var/lib/dovecot
else
  mv /var/lib/dovecot /var/mail/dovecot
fi

rm -rf /var/lib/clamav
ln -s /var/mail/clamav /var/lib/clamav
ln -s /var/mail/dovecot /var/lib/dovecot

# Folders and permissions
groupadd -g "$VMAILGID" vmail &> /dev/null
useradd -g vmail -u "$VMAILUID" vmail -d /var/mail &> /dev/null
mkdir -p /var/run/fetchmail
chmod +x /usr/local/bin/*

# Fix old DKIM keys permissions
chown -R vmail:vmail /var/mail/dkim
chmod 444 /var/mail/dkim/*/{private.key,public.key}

mkdir -p /tmp/counters

for service in clamd cron dovecot freshclam postfix rspamd rsyslogd unbound; do

# Init process counters
echo 0 > /tmp/counters/$service

# Create a finish script for all services
cat > /services/$service/finish <<EOF
#!/bin/bash
# $1 = exit code from the run script
if [ "\$1" -eq 0 ]; then
  # Send a SIGTERM and do not restart the service
  logger -p mail.info "s6-supervise : stopping ${service} process"
  s6-svc -d /services/${service}
else
  COUNTER=\$((\$(cat /tmp/counters/${service})+1))
  if [ "\$COUNTER" -ge 20 ]; then
    # Permanent failure for the service, s6-supervise does not restart it
    logger -p mail.err "s6-supervise : ${service} has restarted too many times (permanent failure)"
    exit 125
  else
    echo "\$COUNTER" > /tmp/counters/${service}
  fi
fi
exit 0
EOF

done

chmod +x /services/*/finish

# RUN !
exec s6-svscan /services
