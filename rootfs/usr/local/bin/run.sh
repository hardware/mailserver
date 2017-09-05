#!/bin/bash

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

# SSL CERTIFICATES
# ---------------------------------------------------------------------------------------------

LETS_ENCRYPT_LIVE_PATH=/etc/letsencrypt/live/"$FQDN"

if [ -d "$LETS_ENCRYPT_LIVE_PATH" ]; then

  echo "[INFO] Let's encrypt live directory found"
  echo "[INFO] Using $LETS_ENCRYPT_LIVE_PATH folder"

  FULLCHAIN="$LETS_ENCRYPT_LIVE_PATH"/fullchain.pem
  CAFILE="$LETS_ENCRYPT_LIVE_PATH"/chain.pem
  CERTFILE="$LETS_ENCRYPT_LIVE_PATH"/cert.pem
  KEYFILE="$LETS_ENCRYPT_LIVE_PATH"/privkey.pem

  # When using https://github.com/jwilder/nginx-proxy there is only key.pem
  # and fullchain.pem so we look for key.pem and extract cert.pem and chain.pem
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
    echo "[INFO] No SSL certificates found, generating a new selfsigned certificate"
    mkdir -p /var/mail/ssl/selfsigned/
    openssl req -new -newkey rsa:4096 -days 3658 -sha256 -nodes -x509 \
      -subj "/C=FR/ST=France/L=Paris/O=Mailserver certificate/OU=Mail/CN=*.${DOMAIN}/emailAddress=postmaster@${DOMAIN}" \
      -keyout "$KEYFILE" \
      -out "$CERTFILE"
  fi
fi

# Comment CAfile directives if Let's Encrypt CA is not used
if [ ! -d "$LETS_ENCRYPT_LIVE_PATH" ]; then
  sed -i '/^\(smtp_tls_CAfile\|smtpd_tls_CAfile\)/s/^/#/' /etc/postfix/main.cf
fi

# DIFFIE-HELLMAN PARAMETERS
# ---------------------------------------------------------------------------------------------

if [ ! -e /var/mail/ssl/dhparams/dh2048.pem ] || [ ! -e /var/mail/ssl/dhparams/dh512.pem ]; then
  echo "[INFO] Diffie-Hellman parameters not found, generating new DH params"
  mkdir -p /var/mail/ssl/dhparams/
  openssl dhparam -out /var/mail/ssl/dhparams/dh2048.pem 2048
  openssl dhparam -out /var/mail/ssl/dhparams/dh512.pem 512
fi

# DKIM KEYS
# ---------------------------------------------------------------------------------------------

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

# ENVIRONMENT VARIABLES TEMPLATING
# ---------------------------------------------------------------------------------------------

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

# POSTFIX CUSTOM CONFIG
# ---------------------------------------------------------------------------------------------

# Override Postfix configuration
if [ -f /var/mail/postfix/custom.conf ]; then
  while read line; do
    echo "[INFO] Override : ${line}"
    postconf -e "$line"
  done < /var/mail/postfix/custom.conf
  echo "[INFO] Custom Postfix configuration file loaded"
fi

# DATABASES HOSTNAME CHECKING
# ---------------------------------------------------------------------------------------------

# Check mariadb hostname
grep -q "${DBHOST}" /etc/hosts

if [ $? -ne 0 ]; then
  echo "[INFO] MariaDB hostname not found in /etc/hosts"
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
  echo "[INFO] Redis hostname not found in /etc/hosts"
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
# ---------------------------------------------------------------------------------------------

# process_min_avail = number of CPU cores, so that all of them will be used
DOVECOT_MIN_PROCESS=$(nproc)

# NbMaxUsers = ( 500 * nbCores ) / 5
# So on a two-core server that's 1000 processes/200 users
# with ~5 open connections per user
DOVECOT_MAX_PROCESS=$(($(nproc) * 500))

sed -i -e "s/DOVECOT_MIN_PROCESS/${DOVECOT_MIN_PROCESS}/" \
       -e "s/DOVECOT_MAX_PROCESS/${DOVECOT_MAX_PROCESS}/" /etc/dovecot/conf.d/10-master.conf

# ENABLE / DISABLE MAIL SERVER FEATURES
# ---------------------------------------------------------------------------------------------

# Disable virus check if asked
if [ "$DISABLE_CLAMAV" = true ]; then
  echo "[INFO] ClamAV is disabled, service will not start"
  rm -f /etc/rspamd/local.d/antivirus.conf
else
  echo "[INFO] ClamAV is enabled"
fi

# Disable fetchmail forwarding
if [ "$ENABLE_FETCHMAIL" = false ]; then
  echo "[INFO] Fetchmail forwarding is disabled"
  rm -f /etc/cron.d/fetchmail
else
  echo "[INFO] Fetchmail forwarding is enabled"
fi

# Disable automatic GPG encryption
if [ "$ENABLE_ENCRYPTION" = false ]; then
  echo "[INFO] Automatic GPG encryption is disabled"
  sed -i '/content_filter/ s/^/#/' /etc/postfix/main.cf
else
  echo "[INFO] Automatic GPG encryption is enabled"
fi

# Enable ManageSieve protocol
if [ "$DISABLE_SIEVE" = false ]; then
  echo "[INFO] ManageSieve protocol is enabled"
  sed -i '/^protocols/s/$/ sieve/' /etc/dovecot/dovecot.conf
else
  echo "[INFO] ManageSieve protocol is disabled"
fi

# Disable DKIM/ARC signing
if [ "$DISABLE_SIGNING" = true ]; then
  echo "[INFO] DKIM/ARC signing is disabled"
  echo "enabled = false;" > /etc/rspamd/local.d/arc.conf
  echo "enabled = false;" > /etc/rspamd/local.d/dkim_signing.conf
else
  echo "[INFO] DKIM/ARC signing is enabled"
fi

# Disable greylisting policy
if [ "$DISABLE_GREYLISTING" = true ]; then
  echo "[INFO] Greylisting policy is disabled"
  echo "enabled = false;" > /etc/rspamd/local.d/greylisting.conf
else
  echo "[INFO] Greylisting policy is enabled"
fi

# Disable ratelimiting policy
if [ "$DISABLE_RATELIMITING" = true ]; then
  echo "[INFO] Ratelimiting policy is disabled"
  echo "enabled = false;" > /etc/rspamd/local.d/ratelimit.conf
else
  echo "[INFO] Ratelimiting policy is enabled"
fi

# Enable POP3 protocol
if [ "$ENABLE_POP3" = true ]; then
  echo "[INFO] POP3 protocol is enabled"
  sed -i '/^protocols/s/$/ pop3/' /etc/dovecot/dovecot.conf
else
  echo "[INFO] POP3 protocol is disabled"
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
  # Ignore temporary dns failure in rspamd
  sed -i '/$IncludeConfig/a :msg,contains,"Temporary failure in name resolution" ~' /etc/rsyslog/rsyslog.conf
  sed -i '/$IncludeConfig/a :msg,contains,"cannot read servers definition" ~' /etc/rsyslog/rsyslog.conf
else
  # /var/log/mail.log is not needed in production
  sed -i '/mail.log/d' /etc/rsyslog/rsyslog.conf
fi

# MOVE DATA DIRECTORIES TO /VAR/MAIL (PERSISTENCE)
# ---------------------------------------------------------------------------------------------

if [ -d "/var/mail/dovecot" ]; then
  rm -rf /var/lib/dovecot
else
  mv /var/lib/dovecot /var/mail/dovecot
fi

rm -rf /var/lib/clamav
ln -s /var/mail/clamav /var/lib/clamav
ln -s /var/mail/dovecot /var/lib/dovecot

# POSTFIX
# ---------------------------------------------------------------------------------------------

# Create vmail user
groupadd -g "$VMAILGID" vmail &> /dev/null
useradd -g vmail -u "$VMAILUID" vmail -d /var/mail &> /dev/null

# Create all needed folders in queue directory
for subdir in "" etc dev usr usr/lib usr/lib/sasl2 usr/lib/zoneinfo public maildrop; do
  mkdir -p  /var/mail/postfix/spool/$subdir
  chmod 755 /var/mail/postfix/spool/$subdir
done

# Add etc files to Postfix chroot jail
cp -f /etc/services /var/mail/postfix/spool/etc/services
cp -f /etc/hosts /var/mail/postfix/spool/etc/hosts
cp -f /etc/localtime /var/mail/postfix/spool/etc/localtime

# Build header_checks and virtual index files
postmap /etc/postfix/header_checks
postmap /etc/postfix/virtual

# Set permissions
chgrp -R postdrop /var/mail/postfix/spool/public
chgrp -R postdrop /var/mail/postfix/spool/maildrop
postfix set-permissions &>/dev/null

# ZEYPLE
# ---------------------------------------------------------------------------------------------

if [ "$ENABLE_ENCRYPTION" = true ]; then

  # Add Zeyple user
  adduser --quiet \
          --system \
          --group \
          --home /var/mail/zeyple \
          --no-create-home \
          --disabled-login \
          --gecos "zeyple automatic GPG encryption tool" \
          zeyple

  # Create all files and directories needed by Zeyple
  mkdir -p /var/mail/zeyple/keys
  chmod 700 /var/mail/zeyple/keys
  chmod 744 /usr/local/bin/zeyple.py
  chown -R zeyple:zeyple /var/mail/zeyple /usr/local/bin/zeyple.py

  if [ "$TESTING" = true ]; then

    touch /var/log/zeyple.log
    chown zeyple:zeyple /var/log/zeyple.log

# Generating John Doe GPG key
s6-setuidgid zeyple gpg --homedir "/var/mail/zeyple/keys" --batch --generate-key <<EOF
  %echo Generating John Doe GPG key
  Key-Type: default
  Key-Length: 1024
  Subkey-Type: default
  Subkey-Length: 1024
  Name-Real: John Doe
  Name-Comment: test key
  Name-Email: john.doe@domain.tld
  Expire-Date: 0
  Passphrase: azerty
  %commit
  %echo done
EOF

  fi
fi

# DOVECOT
# ---------------------------------------------------------------------------------------------

# Sieve
mkdir -p /var/mail/sieve

# Default rule
cat > /var/mail/sieve/default.sieve <<EOF
require ["fileinto"];
if anyof(
    header :contains ["X-Spam-Flag"] "YES",
    header :contains ["X-Spam"] "Yes",
    header :contains ["Subject"] "*** SPAM ***"
)
{
    fileinto "Spam";
    stop;
}
EOF

# Compile sieve scripts
sievec /var/mail/sieve/default.sieve
sievec /etc/dovecot/sieve/report-ham.sieve
sievec /etc/dovecot/sieve/report-spam.sieve

# Set permissions
mkdir -p /var/run/dovecot
chown -R dovecot:dovecot /var/run/dovecot
chown -R vmail:vmail /var/mail/sieve
chmod +x /etc/dovecot/sieve/*.sh

# Check permissions of vhosts directory.
# Do not do this every start-up, it may take a very long time. So we use a stat check here.
if [[ $(stat -c %U /var/mail/vhosts) != "vmail" ]] ; then chown -R vmail:vmail /var/mail/vhosts ; fi

# Avoid file_dotlock_open function exception
rm -f /var/mail/dovecot/instances

# UNBOUND
# ---------------------------------------------------------------------------------------------

# Get a copy of the latest root DNS servers list
curl -s -o /etc/unbound/root.hints https://www.internic.net/domain/named.cache > /dev/null

# Update the root trust anchor to perform cryptographic DNSSEC validation
unbound-anchor -a /etc/unbound/root.key

# Setting up unbound-control
unbound-control-setup &> /dev/null

# Set permissions
chmod 775 /etc/unbound
chown -R unbound:unbound /etc/unbound

# RSPAMD
# ---------------------------------------------------------------------------------------------

# Add a rspamd user with DBDIR as home
# https://github.com/hardware/debian-mail-overlay
adduser --quiet \
        --system \
        --group \
        --home /var/mail/rspamd \
        --no-create-home \
        --disabled-login \
        --gecos "rspamd spam filtering system" \
        --force-badname \
        _rspamd

# Setting the controller password
PASSWORD=$(rspamadm pw --quiet --encrypt --type pbkdf2 --password ${RSPAMD_PASSWORD})
sed -i "s|<PASSWORD>|${PASSWORD}|g" /etc/rspamd/local.d/worker-controller.inc

# Set permissions
mkdir -p /var/mail/rspamd /var/log/rspamd /run/rspamd
chown -R _rspamd:_rspamd /var/mail/rspamd /var/log/rspamd /run/rspamd
chmod 750 /var/mail/rspamd /var/log/rspamd

# CLAMD
# ---------------------------------------------------------------------------------------------

grep -qiF 'TCPSocket' /etc/clamav/clamd.conf || \
     echo 'TCPSocket 3310' >> /etc/clamav/clamd.conf

sed -i -e 's/^Foreground .*$/Foreground true/g' \
       -e 's/^LogSyslog .*$/LogSyslog true/g' \
       -e 's/^LogFacility .*$/LogFacility LOG_MAIL/g' \
       /etc/clamav/clamd.conf

# FRESHCLAM
# ---------------------------------------------------------------------------------------------

# Remove all default mirrors
sed -i '/^DatabaseMirror/ d' /etc/clamav/freshclam.conf

# Add some database mirrors
cat <<EOT >> /etc/clamav/freshclam.conf
DatabaseMirror clamav.univ-nantes.fr
DatabaseMirror switch.clamav.net
DatabaseMirror clamav.iol.cz
DatabaseMirror db.fr.clamav.net
EOT

if [ "$TESTING" = true ]; then
  # When testing, disable syslog logging to avoid random freshclam databases
  # download timeouts to be logged in /var/log/mail.err and speed-up clamd
  # startup with lower attempts value (default 5 attempts)
  sed -i -e 's/^Foreground .*$/Foreground true/g' \
         -e 's/^LogSyslog .*$/LogSyslog false/g' \
         -e 's/^MaxAttempts .*$/MaxAttempts 1/g' \
         /etc/clamav/freshclam.conf
else
  sed -i -e 's/^Foreground .*$/Foreground true/g' \
         -e 's/^LogSyslog .*$/LogSyslog true/g' \
         -e 's/^LogFacility .*$/LogFacility LOG_MAIL/g' \
         -e 's/^MaxAttempts .*$/MaxAttempts 3/g' \
         -e 's/^Checks .*$/Checks 4/g' \
         /etc/clamav/freshclam.conf
fi

# Create clamd directories
mkdir -p /var/run/clamav /var/mail/clamav
chown -R clamav:clamav /var/run/clamav /var/mail/clamav

# MISCELLANEOUS
# ---------------------------------------------------------------------------------------------

# Remove invoke-rc.d warning
sed -i 's|invoke-rc.d rsyslog rotate |invoke-rc.d --quiet rsyslog rotate \&|g' /etc/logrotate.d/rsyslog

# Folders and permissions
mkdir -p /var/run/fetchmail
chmod +x /usr/local/bin/*

# Fix old DKIM keys permissions
chown -R vmail:vmail /var/mail/dkim
chmod 444 /var/mail/dkim/*/{private.key,public.key}

# S6 WATCHDOG
# ---------------------------------------------------------------------------------------------

mkdir -p /tmp/counters

for service in _parent clamd cron dovecot freshclam postfix rspamd rsyslogd unbound; do

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

# LAUNCH ALL SERVICES
# ---------------------------------------------------------------------------------------------

exec s6-svscan /services
