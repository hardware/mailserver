#!/bin/bash

export FQDN
export DOMAIN
export VMAILUID
export VMAILGID
export VMAIL_SUBDIR

export DBDRIVER
export DBHOST
export DBPORT
export DBNAME
export DBUSER

export REDIS_HOST
export REDIS_PORT
export REDIS_PASS
export REDIS_NUMB

export DISABLE_CLAMAV
export DISABLE_DNS_RESOLVER

FQDN=${FQDN:-$(hostname --fqdn)}
DOMAIN=${DOMAIN:-$(hostname --domain)}
VMAILUID=${VMAILUID:-1024}
VMAILGID=${VMAILGID:-1024}
VMAIL_SUBDIR=${VMAIL_SUBDIR:-"mail"}

DBDRIVER=${DBDRIVER:-mysql}
DBHOST=${DBHOST:-mariadb}
DBPORT=${DBPORT:-3306}
DBNAME=${DBNAME:-postfix}
DBUSER=${DBUSER:-postfix}

REDIS_HOST=${REDIS_HOST:-redis}
REDIS_PORT=${REDIS_PORT:-6379}
REDIS_PASS=$([ -f "$REDIS_PASS" ] && cat "$REDIS_PASS" || echo "${REDIS_PASS:-}")
REDIS_NUMB=${REDIS_NUMB:-0}
<<<<<<< HEAD

DISABLE_CLAMAV=${DISABLE_CLAMAV:-false} # --
DISABLE_DNS_RESOLVER=${DISABLE_DNS_RESOLVER:-false} # --
=======
RSPAMD_PASSWORD=$([ -f "$RSPAMD_PASSWORD" ] && cat "$RSPAMD_PASSWORD" || echo "${RSPAMD_PASSWORD:-}")
WHITELIST_SPAM_ADDRESSES=${WHITELIST_SPAM_ADDRESSES:-}
DISABLE_RSPAMD_MODULE=${DISABLE_RSPAMD_MODULE:-}
DISABLE_CLAMAV=${DISABLE_CLAMAV:-false}
DISABLE_SIEVE=${DISABLE_SIEVE:-false}
DISABLE_SIGNING=${DISABLE_SIGNING:-false}
DISABLE_GREYLISTING=${DISABLE_GREYLISTING:-false}
DISABLE_RATELIMITING=${DISABLE_RATELIMITING:-true}
DISABLE_DNS_RESOLVER=${DISABLE_DNS_RESOLVER:-false}
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

export LDAP_ENABLED
export LDAP_HOST
export LDAP_TLS_ENABLED
export LDAP_TLS_CA_FILE
export LDAP_TLS_FORCE
export LDAP_BIND
export LDAP_BIND_DN
export LDAP_BIND_PW
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


LDAP_ENABLED=${LDAP_ENABLED:-false}
LDAP_HOST=${LDAP_HOST:-ldap}
LDAP_TLS_ENABLED=${LDAP_TLS_ENABLED:-false}
LDAP_TLS_CA_FILE=${LDAP_TLS_CA_FILE:-""}
LDAP_TLS_FORCE=${LDAP_TLS_FORCE:-false}
LDAP_BIND=${LDAP_BIND:-true}
LDAP_BIND_DN=${LDAP_BIND_DN:-}
LDAP_BIND_PW=$([ -f "$LDAP_BIND_PW" ] && cat "$LDAP_BIND_PW" || echo "${LDAP_BIND_PW:-}")
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

LDAP_SENDER_SEARCH_BASE=${LDAP_MAILBOX_SEARCH_BASE:-"${LDAP_DEFAULT_SEARCH_BASE}"}
LDAP_SENDER_SEARCH_SCOPE=${LDAP_MAILBOX_SEARCH_SCOPE:-"${LDAP_DEFAULT_SEARCH_SCOPE}"}
LDAP_SENDER_FILTER=${LDAP_MAILBOX_FILTER:-}
LDAP_SENDER_ATTRIBUTE=${LDAP_MAILBOX_ATTRIBUTE:-}
LDAP_SENDER_FORMAT=${LDAP_SENDER_FORMAT:-}

LDAP_DOVECOT_USER_ATTRS=${LDAP_DOVECOT_USER_ATTRS:-}
LDAP_DOVECOT_USER_FILTER=${LDAP_DOVECOT_USER_FILTER:-}
LDAP_DOVECOT_PASS_ATTRS=${LDAP_DOVECOT_PASS_ATTRS:-}
LDAP_DOVECOT_PASS_FILTER=${LDAP_DOVECOT_PASS_FILTER:-}
LDAP_DOVECOT_ITERATE_ATTRS=${LDAP_DOVECOT_ITERATE_ATTRS:-}
LDAP_DOVECOT_ITERATE_FILTER=${LDAP_DOVECOT_ITERATE_FILTER:-}
>>>>>>> First LDAP commit

if [ -z "$DBPASS" ]; then
  echo "[ERROR] MariaDB/PostgreSQL database password must be set !"
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
if [[ "$REDIS_PORT" =~ [^[:digit:]] ]]; then
  REDIS_PORT=6379
fi

# DATABASES HOSTNAME CHECKING
# We need to set these in the hosts file before Unbound takes over for DNS
# ---------------------------------------------------------------------------------------------

# Check mariadb/postgres hostname
grep -q "${DBHOST}" /etc/hosts

if [ $? -ne 0 ]; then
  echo "[INFO] MariaDB/PostgreSQL hostname not found in /etc/hosts"
  IP=$(dig A ${DBHOST} +short +search)
  if [ -n "$IP" ]; then
    echo "[INFO] Container IP found, adding a new record in /etc/hosts"
    echo "${IP} ${DBHOST}" >> /etc/hosts
  else
    echo "[ERROR] Container IP not found with embedded DNS server... Abort !"
    echo "[ERROR] Check your DBHOST environment variable"
    exit 1
  fi
else
  echo "[INFO] MariaDB/PostgreSQL hostname found in /etc/hosts"
fi

# Check redis hostname
grep -q "${REDIS_HOST}" /etc/hosts

if [ $? -ne 0 ]; then
  echo "[INFO] Redis hostname not found in /etc/hosts"
  IP=$(dig A ${REDIS_HOST} +short +search)
  if [ -n "$IP" ]; then
    echo "[INFO] Container IP found, adding a new record in /etc/hosts"
    echo "${IP} ${REDIS_HOST}" >> /etc/hosts
  else
    echo "[ERROR] Container IP not found with embedded DNS server... Abort !"
    echo "[ERROR] Check your REDIS_HOST environment variable"
    exit 1
  fi
else
  echo "[INFO] Redis hostname found in /etc/hosts"
fi

# SETUP CONFIG FILES
# ---------------------------------------------------------------------------------------------

certs_helper.sh update_certs

# Make sure that configuration is only run once
if [ ! -f "/etc/configuration_built" ]; then
  touch "/etc/configuration_built"
  setup.sh
fi

# LAUNCH ALL SERVICES
# ---------------------------------------------------------------------------------------------

echo "[INFO] Starting services"
exec s6-svscan /services
