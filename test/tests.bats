#
# files
#

@test "checking file: /etc/mailname" {
  run docker exec mailserver_default cat /etc/mailname
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "mail.domain.tld" ]
}

@test "checking file: /etc/hostname" {
  run docker exec mailserver_default cat /etc/hostname
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "mail.domain.tld" ]
}

@test "checking file: /etc/hosts" {
  run docker exec mailserver_default grep "mail.domain.tld" /etc/hosts
  [ "$status" -eq 0 ]
}

@test "checking file: all environment variables have been replaced" {
  run docker exec mailserver_default /bin/bash -c "egrep -R "{{.*}}" /etc/postfix /etc/dovecot /etc/opendkim /etc/opendmarc /etc/amavis /usr/local/bin/quota-warning"
  [ "$status" -eq 1 ]
}


#
# processes (default configuration)
#

@test "checking process: supervisor" {
  run docker exec mailserver_default /bin/bash -c "ps aux --forest | grep '[/]usr/bin/supervisord -c /etc/supervisor/supervisord.conf'"
  [ "$status" -eq 0 ]
}

@test "checking process: rsyslog" {
  run docker exec mailserver_default /bin/bash -c "ps aux --forest | grep '[/]usr/sbin/rsyslogd -n'"
  [ "$status" -eq 0 ]
}

@test "checking process: cron" {
  run docker exec mailserver_default /bin/bash -c "ps aux --forest | grep '[/]usr/sbin/cron -f'"
  [ "$status" -eq 0 ]
}

@test "checking process: postfix" {
  run docker exec mailserver_default /bin/bash -c "ps aux --forest | grep '[/]usr/lib/postfix/master -w'"
  [ "$status" -eq 0 ]
}

@test "checking process: dovecot" {
  run docker exec mailserver_default /bin/bash -c "ps aux --forest | grep '[/]usr/sbin/dovecot -c /etc/dovecot/dovecot.conf -F'"
  [ "$status" -eq 0 ]
}

@test "checking process: postgrey (disabled in default configuration)" {
  run docker exec mailserver_default /bin/bash -c "ps aux --forest | grep '[p]ostgrey --delay=120 --inet=127.0.0.1:10023 --dbdir=/var/mail/postgrey'"
  [ "$status" -eq 1 ]
}

@test "checking process: spamd (enable in default configuration)" {
  run docker exec mailserver_default /bin/bash -c "ps aux --forest | grep '[/]usr/sbin/spamd --create-prefs --max-children 5 --helper-home-dir'"
  [ "$status" -eq 0 ]
}

@test "checking process: opendkim" {
  run docker exec mailserver_default /bin/bash -c "ps aux --forest | grep '[/]usr/sbin/opendkim -f -l -x /etc/opendkim/opendkim.conf'"
  [ "$status" -eq 0 ]
}

@test "checking process: opendmarc" {
  run docker exec mailserver_default /bin/bash -c "ps aux --forest | grep '[/]usr/sbin/opendmarc -f -l -c /etc/opendmarc/opendmarc.conf'"
  [ "$status" -eq 0 ]
}

@test "checking process: amavis-new (enable in default configuration)" {
  run docker exec mailserver_default /bin/bash -c "ps aux --forest | grep '[/]usr/sbin/amavisd-new'"
  [ "$status" -eq 0 ]
}

@test "checking process: amavis-milter (enable in default configuration)" {
  run docker exec mailserver_default /bin/bash -c "ps aux --forest | grep '[/]usr/sbin/amavisd-milter -f'"
  [ "$status" -eq 0 ]
}

@test "checking process: clamd (enable in default configuration)" {
  run docker exec mailserver_default /bin/bash -c "ps aux --forest | grep '[/]usr/sbin/clamd --foreground=true -c /etc/clamav/clamd.conf'"
  [ "$status" -eq 0 ]
}

@test "checking process: freshclam (enable in default configuration)" {
  run docker exec mailserver_default /bin/bash -c "ps aux --forest | grep '[/]usr/bin/freshclam -d --config-file=/etc/clamav/freshclam.conf'"
  [ "$status" -eq 0 ]
}

#
# processes (reverse configuration)
#

@test "checking process: postgrey (enable in reverse configuration)" {
  run docker exec mailserver_reverse /bin/bash -c "ps aux --forest | grep '[p]ostgrey --delay=120 --inet=127.0.0.1:10023 --dbdir=/var/mail/postgrey'"
  [ "$status" -eq 0 ]
}

@test "checking process: spamd (disabled in reverse configuration)" {
  run docker exec mailserver_reverse /bin/bash -c "ps aux --forest | grep '[/]usr/sbin/spamd --create-prefs --max-children 5 --helper-home-dir'"
  [ "$status" -eq 1 ]
}

@test "checking process: amavis-new (disabled in reverse configuration)" {
  run docker exec mailserver_reverse /bin/bash -c "ps aux --forest | grep '[/]usr/sbin/amavisd-new'"
  [ "$status" -eq 1 ]
}

@test "checking process: amavis-milter (disabled in reverse configuration)" {
  run docker exec mailserver_reverse /bin/bash -c "ps aux --forest | grep '[/]usr/sbin/amavisd-milter -f'"
  [ "$status" -eq 1 ]
}

@test "checking process: clamd (disabled in reverse configuration)" {
  run docker exec mailserver_reverse /bin/bash -c "ps aux --forest | grep '[/]usr/sbin/clamd --foreground=true -c /etc/clamav/clamd.conf'"
  [ "$status" -eq 1 ]
}

@test "checking process: freshclam (disabled in reverse configuration)" {
  run docker exec mailserver_reverse /bin/bash -c "ps aux --forest | grep '[/]usr/bin/freshclam -d --config-file=/etc/clamav/freshclam.conf'"
  [ "$status" -eq 1 ]
}

#
# sasl
#

@test "checking sasl: dovecot auth with good password" {
  run docker exec mailserver_default /bin/sh -c "doveadm auth test sarah.connor@domain.tld testpasswd12 | grep 'auth succeeded'"
  [ "$status" -eq 0 ]
}

@test "checking sasl: dovecot auth with bad password" {
  run docker exec mailserver_default /bin/sh -c "doveadm auth test sarah.connor@domain.tld badpassword | grep 'auth failed'"
  [ "$status" -eq 0 ]
}

#
# smtp
# http://www.postfix.org/SASL_README.html#server_test
#

# Base64 AUTH STRINGS
# AHNhcmFoLmNvbm5vckBkb21haW4udGxkAHRlc3RwYXNzd2QxMg==
#   echo -ne '\000sarah.connor@domain.tld\000testpasswd12' | openssl base64
# AHNhcmFoLmNvbm5vckBkb21haW4udGxkAGJhZHBhc3N3b3Jk
#   echo -ne '\000sarah.connor@domain.tld\000badpassword' | openssl base64
# c2FyYWguY29ubm9yQGRvbWFpbi50bGQ=
#   echo -ne 'sarah.connor@domain.tld' | openssl base64
# dGVzdHBhc3N3ZDEy
#   echo -ne 'testpasswd12' | openssl base64
# YmFkcGFzc3dvcmQ=
#   echo -ne 'badpassword' | openssl base64

@test "checking smtp (25): STARTTLS AUTH PLAIN works with good password" {
  run docker exec mailserver_default /bin/sh -c "openssl s_client -ign_eof -connect 0.0.0.0:25 -starttls smtp < /tmp/tests/auth/smtp-auth-plain.txt 2>&1 | grep -i 'authentication successful'"
  [ "$status" -eq 0 ]
}

@test "checking smtp (25): STARTTLS AUTH PLAIN fails with bad password" {
  run docker exec mailserver_default /bin/sh -c "openssl s_client -ign_eof -connect 0.0.0.0:25 -starttls smtp < /tmp/tests/auth/smtp-auth-plain-wrong.txt 2>&1 | grep -i 'authentication failed'"
  [ "$status" -eq 0 ]
}

@test "checking smtp (25): clear auth disabled" {
  run docker exec mailserver_default /bin/sh -c "nc -w 2 0.0.0.0 25 < /tmp/tests/auth/smtp-auth-plain.txt | grep -i 'authentication not enabled'"
  [ "$status" -eq 0 ]
}

@test "checking submission (587): STARTTLS AUTH LOGIN works with good password" {
  run docker exec mailserver_default /bin/sh -c "openssl s_client -ign_eof -connect 0.0.0.0:587 -starttls smtp < /tmp/tests/auth/smtp-auth-login.txt 2>&1 | grep -i 'authentication successful'"
  [ "$status" -eq 0 ]
}

@test "checking submission (587): STARTTLS AUTH LOGIN fails with bad password" {
  run docker exec mailserver_default /bin/sh -c "openssl s_client -ign_eof -connect 0.0.0.0:587 -starttls smtp < /tmp/tests/auth/smtp-auth-login-wrong.txt 2>&1 | grep -i 'authentication failed'"
  [ "$status" -eq 0 ]
}

@test "checking submission (587): Auth without STARTTLS fail" {
  run docker exec mailserver_default /bin/sh -c "nc -w 2 0.0.0.0 587 < /tmp/tests/auth/smtp-auth-plain.txt | grep -i 'Must issue a STARTTLS command first'"
  [ "$status" -eq 0 ]
}

@test "checking smtps (465): SSL/TLS AUTH LOGIN works with good password" {
  run docker exec mailserver_default /bin/sh -c "openssl s_client -ign_eof -connect 0.0.0.0:465 < /tmp/tests/auth/smtp-auth-login.txt 2>&1 | grep -i 'authentication successful'"
  [ "$status" -eq 0 ]
}

@test "checking smtps (465): SSL/TLS AUTH LOGIN fails with bad password" {
  run docker exec mailserver_default /bin/sh -c "openssl s_client -ign_eof -connect 0.0.0.0:465 < /tmp/tests/auth/smtp-auth-login-wrong.txt 2>&1 | grep -i 'authentication failed'"
  [ "$status" -eq 0 ]
}

@test "checking smtp: john.doe should have received 3 mails (external, internal + alias)" {
  run docker exec mailserver_default /bin/sh -c "ls -A /var/mail/vhosts/domain.tld/john.doe/mail/new/ | wc -l"
  [ "$status" -eq 0 ]
  [ "$output" = 3 ]
}

@test "checking smtp: john.doe should have received 1 spam (external mail stored in Spam folder by Sieve)" {
  run docker exec mailserver_default /bin/sh -c "ls -A /var/mail/vhosts/domain.tld/john.doe/mail/.Spam/new/ | wc -l"
  [ "$status" -eq 0 ]
  [ "$output" = 1 ]
}


#
# imap
#

@test "checking imap (143): STARTTLS login works with good password" {
  run docker exec mailserver_default /bin/sh -c "openssl s_client -ign_eof -connect 0.0.0.0:143 -starttls imap < /tmp/tests/auth/imap-auth.txt 2>&1 | grep -i 'logged in'"
  [ "$status" -eq 0 ]
}

@test "checking imap (143): STARTTLS login fails with bad password" {
  run docker exec mailserver_default /bin/sh -c "openssl s_client -ign_eof -connect 0.0.0.0:143 -starttls imap < /tmp/tests/auth/imap-auth-wrong.txt 2>&1 | grep -i 'authentication failed'"
  [ "$status" -eq 0 ]
}

@test "checking imaps (993): SSL/TLS login works with good password" {
  run docker exec mailserver_default /bin/sh -c "openssl s_client -ign_eof -connect 0.0.0.0:993 < /tmp/tests/auth/imap-auth.txt 2>&1 | grep -i 'logged in'"
  [ "$status" -eq 0 ]
}

@test "checking imaps (993): SSL/TLS login fails with bad password" {
  run docker exec mailserver_default /bin/sh -c "openssl s_client -ign_eof -connect 0.0.0.0:993 < /tmp/tests/auth/imap-auth-wrong.txt 2>&1 | grep -i 'authentication failed'"
  [ "$status" -eq 0 ]
}

#
# pop
#

@test "checking pop3 (110): STARTTLS login works with good password" {
  run docker exec mailserver_reverse /bin/sh -c "openssl s_client -ign_eof -connect 0.0.0.0:110 -starttls pop3 < /tmp/tests/auth/pop3-auth.txt 2>&1 | grep -i 'ok logged in'"
  [ "$status" -eq 0 ]
}

@test "checking pop3 (110): STARTTLS login fails with bad password" {
  run docker exec mailserver_reverse /bin/sh -c "openssl s_client -ign_eof -connect 0.0.0.0:110 -starttls pop3 < /tmp/tests/auth/pop3-auth-wrong.txt 2>&1 | grep -i 'authentication failed'"
  [ "$status" -eq 0 ]
}

@test "checking pop3s (995): SSL/TLS login works with good password" {
  run docker exec mailserver_reverse /bin/sh -c "openssl s_client -ign_eof -connect 0.0.0.0:995 < /tmp/tests/auth/pop3-auth.txt 2>&1 | grep -i 'ok logged in'"
  [ "$status" -eq 0 ]
}

@test "checking pop3s (995): SSL/TLS login fails with bad password" {
  run docker exec mailserver_reverse /bin/sh -c "openssl s_client -ign_eof -connect 0.0.0.0:995 < /tmp/tests/auth/pop3-auth-wrong.txt 2>&1 | grep -i 'authentication failed'"
  [ "$status" -eq 0 ]
}

#
# amavis
#

@test "checking amavis: 1 spam discarded and 1 virus quarantined" {
  run docker exec mailserver_default /bin/sh -c "find /var/lib/amavis/virusmails -type f | wc -l"
  [ "$status" -eq 0 ]
  [ "$output" = 2 ]
}

#
# sieve
#

@test "checking managesieve (4190): port listening" {
  run docker exec mailserver_default /bin/sh -c "nc -vz 127.0.0.1 4190"
  [ "$status" -eq 0 ]
}

@test "checking managesieve (4190): port closed" {
  run docker exec mailserver_reverse /bin/sh -c "nc -vz 127.0.0.1 4190"
  [ "$status" -eq 1 ]
}

#
# accounts
#

@test "checking accounts: user accounts" {
  run docker exec mailserver_default doveadm user '*'
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "john.doe@domain.tld" ]
  [ "${lines[1]}" = "sarah.connor@domain.tld" ]
}

@test "checking accounts: user quotas" {
  run docker exec mailserver_default /bin/bash -c "doveadm quota get -A 2>&1 | grep '1000' | wc -l"
  [ "$status" -eq 0 ]
  [ "$output" -eq 2 ]
}

@test "checking accounts: user mail folders for john.doe" {
  run docker exec mailserver_default /bin/bash -c "ls -A /var/mail/vhosts/domain.tld/john.doe/mail/ | grep -E '.Spam|cur|new|subscriptions|tmp' | wc -l"
  [ "$status" -eq 0 ]
  [ "$output" -eq 5 ]
}

@test "checking accounts: user mail folders for sarah.connor" {
  run docker exec mailserver_default /bin/bash -c "ls -A /var/mail/vhosts/domain.tld/sarah.connor/mail/ | grep -E '.Spam|cur|new|subscriptions|tmp' | wc -l"
  [ "$status" -eq 0 ]
  [ "$output" -eq 3 ]
}

#
# opendmarc
#

@test "checking opendmarc: internals domains are in /etc/opendmarc/IgnoreDomains file" {
  run docker exec mailserver_default /bin/bash -c "egrep 'domain(.*).tld' /etc/opendmarc/IgnoreDomains | wc -l"
  [ "$status" -eq 0 ]
  [ "$output" -eq 3 ]
}

#
# opendkim
#

@test "checking opendkim: internals domains are in /etc/opendkim/TrustedHosts file" {
  run docker exec mailserver_default /bin/bash -c "egrep 'domain(.*).tld' /etc/opendkim/TrustedHosts | wc -l"
  [ "$status" -eq 0 ]
  [ "$output" -eq 3 ]
}

@test "checking opendkim: internals domains are in /etc/opendkim/SigningTable file" {
  run docker exec mailserver_default /bin/bash -c "egrep 'domain(.*).tld' /etc/opendkim/SigningTable | wc -l"
  [ "$status" -eq 0 ]
  [ "$output" -eq 3 ]
}

@test "checking opendkim: internals domains are in /etc/opendkim/KeyTable file" {
  run docker exec mailserver_default /bin/bash -c "egrep 'domain(.*).tld' /etc/opendkim/KeyTable | wc -l"
  [ "$status" -eq 0 ]
  [ "$output" -eq 3 ]
}

@test "checking opendkim: internals domains are in /etc/opendkim/KeyTable file" {
  run docker exec mailserver_default /bin/bash -c "egrep 'domain(.*).tld' /etc/opendkim/KeyTable | wc -l"
  [ "$status" -eq 0 ]
  [ "$output" -eq 3 ]
}

@test "checking opendkim: all key pairs are generated" {
  run docker exec mailserver_default /bin/bash -c "ls -A /etc/opendkim/keys/*/{mail.txt,mail.private} | wc -l"
  [ "$status" -eq 0 ]
  [ "$output" -eq 6 ]
}

@test "checking opendkim: control the size of the RSA key pair (4096bits)" {
  run docker exec mailserver_reverse /bin/bash -c "openssl rsa -in /etc/opendkim/keys/domain.tld/mail.private -text -noout | grep -i 'Private-Key: (4096 bit)'"
  [ "$status" -eq 0 ]
}

#
# postfix
#

# @test "checking postfix: main.cf overrides" {
#  run docker exec mailserver_default /bin/sh -c "postconf -n | grep 'max_idle = 600s'"
#  [ "$status" -eq 0 ]
#  run docker exec mailserver_default /bin/sh -c "postconf -n | grep 'readme_directory = /tmp'"
#  [ "$status" -eq 0 ]
# }
