#!/bin/bash

echo "[INFO] Setting up container"

export RECIPIENT_DELIMITER
export FETCHMAIL_INTERVAL
export RELAY_NETWORKS
export PASSWORD_SCHEME

TESTING=${TESTING:-false}
DEBUG_MODE=${DEBUG_MODE:-false}

ADD_DOMAINS=${ADD_DOMAINS:-}

DBPASS=$([ -f "$DBPASS" ] && cat "$DBPASS" || echo "${DBPASS:-}")
RSPAMD_PASSWORD=$([ -f "$RSPAMD_PASSWORD" ] && cat "$RSPAMD_PASSWORD" || echo "${RSPAMD_PASSWORD:-}")
WHITELIST_SPAM_ADDRESSES=${WHITELIST_SPAM_ADDRESSES:-}
OPENDKIM_KEY_LENGTH=${OPENDKIM_KEY_LENGTH:-1024}

DISABLE_RSPAMD_MODULE=${DISABLE_RSPAMD_MODULE:-}
DISABLE_SIEVE=${DISABLE_SIEVE:-false}
DISABLE_SIGNING=${DISABLE_SIGNING:-false}
DISABLE_GREYLISTING=${DISABLE_GREYLISTING:-false}
DISABLE_RATELIMITING=${DISABLE_RATELIMITING:-true}

ENABLE_POP3=${ENABLE_POP3:-false}
ENABLE_FETCHMAIL=${ENABLE_FETCHMAIL:-false}
ENABLE_ENCRYPTION=${ENABLE_ENCRYPTION:-false}

RECIPIENT_DELIMITER=${RECIPIENT_DELIMITER:-"+"}
FETCHMAIL_INTERVAL=${FETCHMAIL_INTERVAL:-10}
RELAY_NETWORKS=${RELAY_NETWORKS:-}
PASSWORD_SCHEME=${PASSWORD_SCHEME:-"SHA512-CRYPT"}

# SSL CERTIFICATES
# ---------------------------------------------------------------------------------------------

export CAFILE
export CERTFILE
export KEYFILE
export FULLCHAIN

FULLCHAIN=/ssl/fullchain.pem
CAFILE=/ssl/chain.pem
CERTFILE=/ssl/cert.pem
KEYFILE=/ssl/privkey.pem

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

# LDAP SUPPORT
# ---------------------------------------------------------------------------------------------

if [ "$DBDRIVER" = "ldap" ]; then
  export LDAP_TLS_ENABLED
  export LDAP_TLS_CA_FILE
  export LDAP_TLS_FORCE
  export LDAP_DEFAULT_SEARCH_BASE
  export LDAP_DEFAULT_SEARCH_SCOPE

  export LDAP_DOMAIN_SEARCH_BASE
  export LDAP_DOMAIN_SEARCH_SCOPE
  export LDAP_DOMAIN_FILTER
  export LDAP_DOMAIN_ATTRIBUTE
  export LDAP_DOMAIN_FORMAT

  export LDAP_MAILBOX_SEARCH_BASE
  export LDAP_MAILBOX_SEARCH_SCOPE
  export LDAP_MAILBOX_FILTER
  export LDAP_MAILBOX_ATTRIBUTE
  export LDAP_MAILBOX_FORMAT

  export LDAP_ALIAS_SEARCH_BASE
  export LDAP_ALIAS_SEARCH_SCOPE
  export LDAP_ALIAS_FILTER
  export LDAP_ALIAS_ATTRIBUTE
  export LDAP_ALIAS_FORMAT

  export LDAP_FORWARD_SEARCH_BASE
  export LDAP_FORWARD_SEARCH_SCOPE
  export LDAP_FORWARD_FILTER
  export LDAP_FORWARD_ATTRIBUTE
  export LDAP_FORWARD_FORMAT

  export LDAP_GROUP_SEARCH_BASE
  export LDAP_GROUP_SEARCH_SCOPE
  export LDAP_GROUP_FILTER
  export LDAP_GROUP_ATTRIBUTE
  export LDAP_GROUP_FORMAT

  export LDAP_SENDER_SEARCH_BASE
  export LDAP_SENDER_SEARCH_SCOPE
  export LDAP_SENDER_FILTER
  export LDAP_SENDER_ATTRIBUTE
  export LDAP_SENDER_FORMAT

  export LDAP_DOVECOT_USER_ATTRS
  export LDAP_DOVECOT_USER_FILTER
  export LDAP_DOVECOT_PASS_ATTRS
  export LDAP_DOVECOT_PASS_FILTER
  export LDAP_DOVECOT_ITERATE_ATTRS
  export LDAP_DOVECOT_ITERATE_FILTER

  export LDAP_MASTER_USER_ENABLED
  export LDAP_MASTER_USER_SEPARATOR
  export LDAP_MASTER_USER_SEARCH_BASE
  export LDAP_MASTER_USER_SEARCH_SCOPE
  export LDAP_DOVECOT_MASTER_PASS_ATTRS
  export LDAP_DOVECOT_MASTER_PASS_FILTER

  LDAP_TLS_ENABLED=${LDAP_TLS_ENABLED:-false}
  LDAP_TLS_CA_FILE=${LDAP_TLS_CA_FILE:-""}
  LDAP_TLS_FORCE=${LDAP_TLS_FORCE:-false}
  LDAP_DEFAULT_SEARCH_BASE=${LDAP_DEFAULT_SEARCH_BASE:-}
  LDAP_DEFAULT_SEARCH_SCOPE=${LDAP_DEFAULT_SEARCH_SCOPE:-"sub"}

  LDAP_DOMAIN_SEARCH_BASE=${LDAP_DOMAIN_SEARCH_BASE:-"${LDAP_DEFAULT_SEARCH_BASE}"}
  LDAP_DOMAIN_SEARCH_SCOPE=${LDAP_DOMAIN_SEARCH_SCOPE:-"${LDAP_DEFAULT_SEARCH_SCOPE}"}
  LDAP_DOMAIN_FILTER=${LDAP_DOMAIN_FILTER:-}
  LDAP_DOMAIN_ATTRIBUTE=${LDAP_DOMAIN_ATTRIBUTE:-}
  LDAP_DOMAIN_FORMAT=${LDAP_DOMAIN_FORMAT:-}

  LDAP_MAILBOX_SEARCH_BASE=${LDAP_MAILBOX_SEARCH_BASE:-"${LDAP_DEFAULT_SEARCH_BASE}"}
  LDAP_MAILBOX_SEARCH_SCOPE=${LDAP_MAILBOX_SEARCH_SCOPE:-"${LDAP_DEFAULT_SEARCH_SCOPE}"}
  LDAP_MAILBOX_FILTER=${LDAP_MAILBOX_FILTER:-}
  LDAP_MAILBOX_ATTRIBUTE=${LDAP_MAILBOX_ATTRIBUTE:-}
  LDAP_MAILBOX_FORMAT=${LDAP_MAILBOX_FORMAT:-}

  LDAP_ALIAS_SEARCH_BASE=${LDAP_ALIAS_SEARCH_BASE:-"${LDAP_DEFAULT_SEARCH_BASE}"}
  LDAP_ALIAS_SEARCH_SCOPE=${LDAP_ALIAS_SEARCH_SCOPE:-"${LDAP_DEFAULT_SEARCH_SCOPE}"}
  LDAP_ALIAS_FILTER=${LDAP_ALIAS_FILTER:-}
  LDAP_ALIAS_ATTRIBUTE=${LDAP_ALIAS_ATTRIBUTE:-}
  LDAP_ALIAS_FORMAT=${LDAP_ALIAS_FORMAT:-}

  LDAP_FORWARD_SEARCH_BASE=${LDAP_FORWARD_SEARCH_BASE:-"${LDAP_DEFAULT_SEARCH_BASE}"}
  LDAP_FORWARD_SEARCH_SCOPE=${LDAP_FORWARD_SEARCH_SCOPE:-"${LDAP_DEFAULT_SEARCH_SCOPE}"}
  LDAP_FORWARD_FILTER=${LDAP_FORWARD_FILTER:-}
  LDAP_FORWARD_ATTRIBUTE=${LDAP_FORWARD_ATTRIBUTE:-}
  LDAP_FORWARD_FORMAT=${LDAP_FORWARD_FORMAT:-}

  LDAP_GROUP_SEARCH_BASE=${LDAP_GROUP_SEARCH_BASE:-"${LDAP_DEFAULT_SEARCH_BASE}"}
  LDAP_GROUP_SEARCH_SCOPE=${LDAP_GROUP_SEARCH_SCOPE:-"${LDAP_DEFAULT_SEARCH_SCOPE}"}
  LDAP_GROUP_FILTER=${LDAP_GROUP_FILTER:-}
  LDAP_GROUP_ATTRIBUTE=${LDAP_GROUP_ATTRIBUTE:-}
  LDAP_GROUP_FORMAT=${LDAP_GROUP_FORMAT:-}

  LDAP_SENDER_SEARCH_BASE=${LDAP_SENDER_SEARCH_BASE:-"${LDAP_DEFAULT_SEARCH_BASE}"}
  LDAP_SENDER_SEARCH_SCOPE=${LDAP_SENDER_SEARCH_SCOPE:-"${LDAP_DEFAULT_SEARCH_SCOPE}"}
  LDAP_SENDER_FILTER=${LDAP_SENDER_FILTER:-}
  LDAP_SENDER_ATTRIBUTE=${LDAP_SENDER_ATTRIBUTE:-}
  LDAP_SENDER_FORMAT=${LDAP_SENDER_FORMAT:-}

  LDAP_DOVECOT_USER_ATTRS=${LDAP_DOVECOT_USER_ATTRS:-}
  LDAP_DOVECOT_USER_FILTER=${LDAP_DOVECOT_USER_FILTER:-}
  LDAP_DOVECOT_PASS_ATTRS=${LDAP_DOVECOT_PASS_ATTRS:-}
  LDAP_DOVECOT_PASS_FILTER=${LDAP_DOVECOT_PASS_FILTER:-}
  LDAP_DOVECOT_ITERATE_ATTRS=${LDAP_DOVECOT_ITERATE_ATTRS:-}
  LDAP_DOVECOT_ITERATE_FILTER=${LDAP_DOVECOT_ITERATE_FILTER:-}

  LDAP_MASTER_USER_ENABLED=${LDAP_MASTER_USER_ENABLED:-"false"}
  LDAP_MASTER_USER_SEPARATOR=${LDAP_MASTER_USER_SEPARATOR:-"*"}
  LDAP_MASTER_USER_SEARCH_BASE=${LDAP_MASTER_USER_SEARCH_BASE:-"${LDAP_DEFAULT_SEARCH_BASE}"}
  LDAP_MASTER_USER_SEARCH_SCOPE=${LDAP_MASTER_USER_SEARCH_SCOPE:-"${LDAP_DEFAULT_SEARCH_SCOPE}"}
  LDAP_DOVECOT_MASTER_USER_ATTRS=${LDAP_DOVECOT_USER_ATTRS:-}
  LDAP_DOVECOT_MASTER_USER_FILTER=${LDAP_DOVECOT_USER_FILTER:-}
fi

# ENVIRONMENT VARIABLES TEMPLATING
# ---------------------------------------------------------------------------------------------

# Avoid gucci error if cron file doesn't exist
if [ ! -f /etc/cron.d/fetchmail ]; then
  touch /etc/cron.d/fetchmail
fi

# Replace environment variables with Gucci
# https://github.com/noqcks/gucci
# Gucci requires files to have .tpl extension
_envtpl() {
  mv "$1" "$1.tpl" && gucci "$1.tpl" > "$1" && rm -f "$1.tpl"
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

_envtpl /etc/dovecot/conf.d/10-auth.conf
_envtpl /etc/dovecot/conf.d/10-mail.conf
_envtpl /etc/dovecot/conf.d/10-ssl.conf
_envtpl /etc/dovecot/conf.d/15-lda.conf
_envtpl /etc/dovecot/conf.d/20-lmtp.conf
_envtpl /etc/dovecot/conf.d/90-quota.conf

_envtpl /etc/rspamd/local.d/redis.conf
_envtpl /etc/rspamd/local.d/settings.conf
_envtpl /etc/rspamd/local.d/statistic.conf

_envtpl /etc/cron.d/fetchmail
_envtpl /etc/mailname
_envtpl /usr/local/bin/quota-warning.sh
_envtpl /usr/local/bin/fetchmail.pl

if [ "$DBDRIVER" = "ldap" ]; then

  _envtpl /etc/postfix/ldap/sender-login-maps.cf
  _envtpl /etc/postfix/ldap/virtual-mailbox-domains.cf
  _envtpl /etc/postfix/ldap/virtual-mailbox-maps.cf
  _envtpl /etc/postfix/ldap/virtual-alias-maps.cf
  _envtpl /etc/postfix/ldap/virtual-forward-maps.cf
  _envtpl /etc/postfix/ldap/virtual-group-maps.cf

  _envtpl /etc/dovecot/dovecot-ldap.conf.ext
  _envtpl /etc/dovecot/dovecot-ldap-master.conf.ext

  _envtpl /etc/dovecot/conf.d/auth-ldap.conf.ext

else

  rm -f /etc/postfix/ldap/sender-login-maps.cf \
        /etc/postfix/ldap/virtual-mailbox-domains.cf \
        /etc/postfix/ldap/virtual-mailbox-maps.cf \
        /etc/postfix/ldap/virtual-alias-maps.cf \
        /etc/postfix/ldap/virtual-forward-maps.cf \
        /etc/postfix/ldap/virtual-group-maps.cf \
        /etc/dovecot/dovecot-ldap.conf.ext \
        /etc/dovecot/dovecot-ldap-master.conf.ext \
        /etc/dovecot/conf.d/auth-ldap.conf.ext

fi

# POSTFIX CUSTOM CONFIG
# ---------------------------------------------------------------------------------------------

# Override Postfix configuration
if [ -f /var/mail/postfix/custom.conf ]; then
  # Ignore blank lines and comments
  sed -e '/^\s*$/d' -e '/^#/d' /var/mail/postfix/custom.conf | \
  while read line; do
    type=${line:0:2}
    value=${line:2}
    if [[ "$type" == 'S|' ]]; then
      postconf -M "$value"
      echo "[INFO] Override service entry in master.cf : ${value}"
    elif [[ "$type" == 'F|' ]]; then
      postconf -F "$value"
      echo "[INFO] Override service field in master.cf : ${value}"
    elif [[ "$type" == 'P|' ]]; then
      postconf -P "$value"
      echo "[INFO] Override service parameter in master.cf : ${value}"
    else
      echo "[INFO] Override parameter in main.cf : ${line}"
      postconf -e "$line"
    fi
  done
  echo "[INFO] Custom Postfix configuration file loaded"
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

# Enable Postfix, Dovecot and Rspamd verbose logging
if [ "$DEBUG_MODE" != false ]; then
  if [[ "$DEBUG_MODE" = *"postfix"* || "$DEBUG_MODE" = true ]]; then
    echo "[INFO] Postfix debug mode is enabled"
    sed -i '/^s.*inet/ s/$/ -v/' /etc/postfix/master.cf
  fi
  if [[ "$DEBUG_MODE" = *"dovecot"* || "$DEBUG_MODE" = true ]]; then
    echo "[INFO] Dovecot debug mode is enabled"
    sed -i 's/^#//g' /etc/dovecot/conf.d/10-logging.conf
  fi
  if [[ "$DEBUG_MODE" = *"rspamd"* || "$DEBUG_MODE" = true ]]; then
    echo "[INFO] Rspamd debug mode is enabled"
    sed -i 's/warning/info/g' /etc/rspamd/local.d/logging.inc
  fi
  if [[ "$DEBUG_MODE" = *"Unbound"* || "$DEBUG_MODE" = true ]]; then
    echo "[INFO] Unbound debug mode is enabled"
    sed -i -e 's/verbosity: 0/verbosity: 2/g' \
           -e 's/logfile: \/dev\/null/logfile: ""/g' /etc/unbound/unbound.conf
  fi
else
  echo "[INFO] Debug mode is disabled"
fi

# Disable virus check if asked
if [ "$DISABLE_CLAMAV" = true ]; then
  echo "[INFO] ClamAV is disabled, service will not start"
  rm -f /etc/rspamd/local.d/antivirus.conf /etc/logrotate.d/clamav-*
else
  echo "[INFO] ClamAV is enabled"
fi

# Disable fetchmail forwarding
if [ "$ENABLE_FETCHMAIL" = false ]; then
  echo "[INFO] Fetchmail forwarding is disabled"
  rm -f /etc/cron.d/fetchmail
else

echo "[INFO] Fetchmail forwarding is enabled"

if [ "$TESTING" = true ]; then
  rm -f /etc/cron.d/fetchmail
fi

# Fetchmail dedicated port (10025) with less restrictions
# https://github.com/hardware/mailserver/issues/276
cat >> /etc/postfix/master.cf <<EOF
127.0.0.1:10025 inet  n       -       -       -       10      smtpd
  -o content_filter=
  -o receive_override_options=no_unknown_recipient_checks,no_header_body_checks,no_milters
  -o smtpd_helo_restrictions=
  -o smtpd_client_restrictions=
  -o smtpd_sender_restrictions=
  -o smtpd_recipient_restrictions=permit_mynetworks,reject
  -o mynetworks=127.0.0.0/8,[::1]/128
  -o smtpd_authorized_xforward_hosts=127.0.0.0/8,[::1]/128
EOF

fi

# Disable automatic GPG encryption
if [ "$ENABLE_ENCRYPTION" = false ]; then
  echo "[INFO] Automatic GPG encryption is disabled"
  sed -i '/content_filter/ s/^/#/' /etc/postfix/main.cf
else
  # echo "[INFO] Automatic GPG encryption is enabled"
  sed -i '/content_filter/ s/^/#/' /etc/postfix/main.cf
  echo "[ERROR] Zeyple support has been temporarily disabled in the master branch following the Debian 10 update. Please, use the stable docker tag (1.1-stable) until the issue fixed. More information here : https://github.com/hardware/mailserver/issues/393"
  if [ "$TESTING" = false ]; then
    touch /etc/setup-error
  fi
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

# Disable Unbound DNS resolver
if [ "$DISABLE_DNS_RESOLVER" = true ]; then
  echo "[INFO] Unbound DNS resolver is disabled"
  # Disable DNSSEC in Postfix and Rspamd configuration
  sed -i -e 's|\(enable_dnssec.*=\).*|\1 false;|' \
         -e '/nameserver/ s/^/#/' /etc/rspamd/local.d/options.inc
  sed -i -e 's|\(smtp_tls_security_level.*=\).*|\1 may|' \
         -e '/smtp_dns_support_level/ s/^/#/' /etc/postfix/main.cf
else
  echo "[INFO] Unbound DNS resolver is enabled"
fi

if [ "$TESTING" = true ]; then
  echo "[INFO] DOCKER IMAGE UNDER TESTING"
  # Disable postfix virtual table
  sed -i '/etc\/postfix\/virtual/ s/^/#/' /etc/postfix/main.cf
  # Disable dkim and arc signing locally
  sed -i 's|\(sign_local.*=\).*|\1 false;|' /etc/rspamd/local.d/dkim_signing.conf
  sed -i 's|\(sign_local.*=\).*|\1 false;|' /etc/rspamd/local.d/arc.conf
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

if [ -s "/var/mail/postfix/sender_access" ]; then
  echo "[INFO] sender_access file found, sender access check enabled"
  cp /var/mail/postfix/sender_access /etc/postfix/sender_access
  postmap /etc/postfix/sender_access
else
  sed -i '/check_sender_access/ s/^/#/' /etc/postfix/main.cf
fi

# Set permissions
chgrp -R postdrop /var/mail/postfix/spool/public
chgrp -R postdrop /var/mail/postfix/spool/maildrop
postfix set-permissions &>/dev/null

# ZEYPLE
# ---------------------------------------------------------------------------------------------

# if [ "$ENABLE_ENCRYPTION" = true ]; then

#   # Add Zeyple user
#   adduser --quiet \
#           --system \
#           --group \
#           --home /var/mail/zeyple \
#           --no-create-home \
#           --disabled-login \
#           --gecos "zeyple automatic GPG encryption tool" \
#           zeyple

#   # Create all files and directories needed by Zeyple
#   mkdir -p /var/mail/zeyple/keys
#   chmod 700 /var/mail/zeyple/keys
#   chmod 744 /usr/local/bin/zeyple.py
#   chown -R zeyple:zeyple /var/mail/zeyple /usr/local/bin/zeyple.py

#   if [ "$TESTING" = true ]; then

#     touch /var/log/zeyple.log
#     chown zeyple:zeyple /var/log/zeyple.log

# # Generating John Doe GPG key
# s6-setuidgid zeyple gpg --homedir "/var/mail/zeyple/keys" --batch --generate-key <<EOF
#   %echo Generating John Doe GPG key
#   Key-Type: default
#   Key-Length: 1024
#   Subkey-Type: default
#   Subkey-Length: 1024
#   Name-Real: John Doe
#   Name-Comment: test key
#   Name-Email: john.doe@domain.tld
#   Expire-Date: 0
#   Passphrase: azerty
#   %commit
#   %echo done
# EOF

#   fi
# fi

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

if [ -s /var/mail/sieve/custom.sieve ]; then
  cp -f /var/mail/sieve/custom.sieve /var/mail/sieve/default.sieve
fi

# Compile sieve scripts
sievec /var/mail/sieve/default.sieve
sievec /etc/dovecot/sieve/report-ham.sieve
sievec /etc/dovecot/sieve/report-spam.sieve

# Set permissions
mkdir -p /var/run/dovecot
chown -R dovecot:dovecot /var/run/dovecot
chown -R vmail:vmail /var/mail/sieve
chmod +x /etc/dovecot/sieve/*.sh

# Check permissions of vhosts directories
find /var/mail/vhosts ! -user vmail -print0 | xargs -0 -r chown vmail:vmail

# Avoid file_dotlock_open function exception
rm -f /var/mail/dovecot/instances

if [ -f "/var/mail/dovecot/ssl-parameters.dat" ]; then
  mv /var/mail/dovecot/ssl-parameters.dat /var/mail/dovecot/ssl-parameters.dat.backup
fi

# UNBOUND
# ---------------------------------------------------------------------------------------------

if [ "$DISABLE_DNS_RESOLVER" = false ]; then

  # Get a copy of the latest root DNS servers list
  curl -s -o /etc/unbound/root.hints https://www.internic.net/domain/named.cache > /dev/null

  # Update the root trust anchor to perform cryptographic DNSSEC validation
  unbound-anchor -a /etc/unbound/root.key

  # Setting up unbound-control
  unbound-control-setup &> /dev/null

  # Set permissions
  chmod 775 /etc/unbound
  chown -R unbound:unbound /etc/unbound

fi

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
PASSWORD=$(rspamadm pw --quiet --encrypt --type pbkdf2 --password "${RSPAMD_PASSWORD}" | grep -v SSSE3)
if ! grep --quiet 'ssse3' /proc/cpuinfo; then
  if ! grep --quiet 'disable_hyperscan' /etc/rspamd/local.d/options.inc; then
    echo "disable_hyperscan = true;" >> /etc/rspamd/local.d/options.inc
  fi
  echo "[INFO] Missing SSSE3 CPU instructions, hyperscan is disabled"
fi

if [ -z "$PASSWORD" ]; then
  echo "[ERROR] rspamadm pw : bad output"
  touch /etc/setup-error
fi

sed -i "s|<PASSWORD>|${PASSWORD}|g" /etc/rspamd/local.d/worker-controller.inc

# Set permissions
mkdir -p /var/mail/rspamd /var/log/rspamd /run/rspamd
chown -R _rspamd:_rspamd /var/mail/rspamd /var/log/rspamd /run/rspamd
chmod 750 /var/mail/rspamd /var/log/rspamd

modules+=(${DISABLE_RSPAMD_MODULE//,/ })

if [ ${#modules[@]} -gt 0 ]; then
  echo "[INFO] $DISABLE_RSPAMD_MODULE rspamd module(s) disabled"
  for module in "${modules[@]}"; do
    echo "enabled = false;" > /etc/rspamd/local.d/"$module".conf
  done
fi

whitelist+=(${WHITELIST_SPAM_ADDRESSES//,/ })

if [ ${#whitelist[@]} -gt 0 ]; then

rcpts=""

echo "[INFO] $WHITELIST_SPAM_ADDRESSES added to rspamd whitelist"
for address in "${whitelist[@]}"; do
  rcpts+="\"$address\","
done

cat > /etc/rspamd/local.d/settings.conf <<EOF
whitelist {
  priority = low;
  rcpt = [${rcpts::-1}];
  want_spam = yes;
}
EOF

fi

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
DatabaseMirror db.local.clamav.net
DatabaseMirror switch.clamav.net
DatabaseMirror clamav.easynet.fr
DatabaseMirror clamav.begi.net
DatabaseMirror clamav.univ-nantes.fr
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
mkdir -p /var/run/clamav /var/mail/clamav /var/log/clamav
chown -R clamav:clamav /var/run/clamav /var/mail/clamav /var/log/clamav

# CLAMAV-UNOFFICIAL-SIGS
# ---------------------------------------------------------------------------------------------

if [ -f "/var/mail/clamav-unofficial-sigs/user.conf" ]; then
  echo "[INFO] clamav-unofficial-sigs is enabled (user configuration found)"
  rm -rf /var/lib/clamav-unofficial-sigs
  ln -s /var/mail/clamav-unofficial-sigs /var/lib/clamav-unofficial-sigs
  cp -f /var/mail/clamav-unofficial-sigs/user.conf /etc/clamav/unofficial-sigs
  mkdir -p /var/log/clamav-unofficial-sigs
  clamav-unofficial-sigs.sh --install-cron &>/dev/null
  clamav-unofficial-sigs.sh --install-logrotate &>/dev/null
else
  echo "[INFO] clamav-unofficial-sigs is disabled (user configuration not found)"
fi

# MISCELLANEOUS
# ---------------------------------------------------------------------------------------------

# Remove invoke-rc.d warning
sed -i 's|rsyslog-rotate|rsyslog-rotate \&>/dev/null|g' /etc/logrotate.d/rsyslog

# Folders and permissions
mkdir -p /var/run/fetchmail
chmod +x /usr/local/bin/*

# Fix old DKIM keys permissions
chown -R vmail:vmail /var/mail/dkim
chmod 444 /var/mail/dkim/*/{private.key,public.key}

# Ensure that hashes are calculated because Postfix require directory
# to be set up like this in order to find CA certificates.
c_rehash /etc/ssl/certs &>/dev/null

# S6 WATCHDOG
# ---------------------------------------------------------------------------------------------

mkdir -p /tmp/counters

for service in _parent clamd cron dovecot freshclam postfix rspamd rsyslogd unbound cert_watcher; do

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

echo "[INFO] Finished container setup"
