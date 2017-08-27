#!/bin/bash

# This script allow to import gpg public keys
# for one or all potential recipients in the
# mail server.

OPTIONS=$1
KEYID=$2
KEYSERVER=${3:-"hkp://keys.gnupg.net"}

# Zeyple home directory
ZEYPLE_DIR="/var/mail/zeyple"

case "$OPTIONS" in
  # Import a public key for one recipient
  "import-key")
    s6-setuidgid zeyple gpg --homedir "${ZEYPLE_DIR}/keys" --keyserver "${KEYSERVER}" --recv-keys "${KEYID}"
    ;;
  # Import public key for all recipients in the mailserver
  "import-all-keys")
    for dir in /var/mail/vhosts/*/
    do
        [ -z "$(ls -A ${dir})" ] && continue
        dir=${dir%*/}
        domain=${dir##*/}
        for subdir in /var/mail/vhosts/${domain}/*/
        do
            subdir=${subdir%*/}
            user=${subdir##*/}
            recipient="${user}@${domain}"
            s6-setuidgid zeyple gpg --homedir "${ZEYPLE_DIR}/keys" --keyserver "${KEYSERVER}" --recv-keys "${recipient}"
        done
    done
    ;;
  # Remove a public key
  "remove-key")
    s6-setuidgid zeyple gpg --homedir "${ZEYPLE_DIR}/keys" --delete-key "${KEYID}"
    ;;
  # Other GPG action
  *)
    s6-setuidgid zeyple gpg --homedir "${ZEYPLE_DIR}/keys" "$@"
    ;;
esac
