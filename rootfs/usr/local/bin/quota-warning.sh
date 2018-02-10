#!/bin/bash

PERCENT=$1
USER=$2

cat << EOF | /usr/lib/dovecot/dovecot-lda -d $USER -o "plugin/quota=dict:User quota::noenforcing:proxy::sqlquota"
From: postmaster@{{ .DOMAIN }}
Subject: Mailbox quota warning

Your mailbox is now $PERCENT% full.
EOF
