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
export RECIPIENT_DELIMITER
export FETCHMAIL_INTERVAL
export RELAY_NETWORKS
export PASSWORD_SCHEME

FQDN=${FQDN:-$(hostname --fqdn)}
DOMAIN=${DOMAIN:-$(hostname --domain)}
VMAILUID=${VMAILUID:-1024}
VMAILGID=${VMAILGID:-1024}
VMAIL_SUBDIR=${VMAIL_SUBDIR:-"mail"}
DEBUG_MODE=${DEBUG_MODE:-false}
DBDRIVER=${DBDRIVER:-mysql}
DBHOST=${DBHOST:-mariadb}
DBPORT=${DBPORT:-3306}
DBNAME=${DBNAME:-postfix}
DBUSER=${DBUSER:-postfix}
DBPASS=$([ -f "$DBPASS" ] && cat "$DBPASS" || echo "${DBPASS:-}")
REDIS_HOST=${REDIS_HOST:-redis}
REDIS_PORT=${REDIS_PORT:-6379}
REDIS_PASS=$([ -f "$REDIS_PASS" ] && cat "$REDIS_PASS" || echo "${REDIS_PASS:-}")
REDIS_NUMB=${REDIS_NUMB:-0}
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
if [[ "$REDIS_PORT" =~ [^[:digit:]] ]]
then
  REDIS_PORT=6379
fi

# DATABASES HOSTNAME CHECKING
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

# Make sure that configuration is only run once
if [ ! -f "/etc/configuration_built" ]; then
  touch "/etc/configuration_built"
  setup.sh
fi

# LAUNCH ALL SERVICES
# ---------------------------------------------------------------------------------------------

exec s6-svscan /services
