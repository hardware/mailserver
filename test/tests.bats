#
# system
#

@test "checking system: /etc/mailname (docker method)" {
  run docker exec mailserver_default cat /etc/mailname
  [ "$status" -eq 0 ]
  [ "$output" = "mail.domain.tld" ]
}

@test "checking system: /etc/mailname (env method)" {
  run docker exec mailserver_reverse cat /etc/mailname
  [ "$status" -eq 0 ]
  [ "$output" = "mail.domain.tld" ]
}

@test "checking system: /etc/hostname" {
  run docker exec mailserver_default cat /etc/hostname
  [ "$status" -eq 0 ]
  [ "$output" = "mail.domain.tld" ]
}

@test "checking system: /etc/hosts" {
  run docker exec mailserver_default grep "mail.domain.tld" /etc/hosts
  [ "$status" -eq 0 ]
}

@test "checking system: fqdn" {
  run docker exec mailserver_default hostname -f
  [ "$status" -eq 0 ]
  [ "$output" = "mail.domain.tld" ]
}

@test "checking system: domain" {
  run docker exec mailserver_default hostname -d
  [ "$status" -eq 0 ]
  [ "$output" = "domain.tld" ]
}

@test "checking system: hostname" {
  run docker exec mailserver_default hostname -s
  [ "$status" -eq 0 ]
  [ "$output" = "mail" ]
}

@test "checking system: all environment variables have been replaced (default configuration)" {
  run docker exec mailserver_default /bin/bash -c "egrep -R "{{.*}}" /etc/postfix /etc/postfixadmin/fetchmail.conf /etc/dovecot /etc/rspamd /etc/mailname /usr/local/bin"
  [ "$status" -eq 1 ]
}

@test "checking system: all environment variables have been replaced (reverse configuration)" {
  run docker exec mailserver_reverse /bin/bash -c "egrep -R "{{.*}}" /etc/postfix /etc/postfixadmin/fetchmail.conf /etc/dovecot /etc/rspamd /etc/mailname /usr/local/bin"
  [ "$status" -eq 1 ]
}

#
# processes (default configuration)
#

@test "checking process: s6        (default configuration)" {
  run docker exec mailserver_default /bin/bash -c "ps aux --forest | grep '[s]6-svscan /etc/s6.d'"
  [ "$status" -eq 0 ]
}

@test "checking process: rsyslog   (default configuration)" {
  run docker exec mailserver_default /bin/bash -c "ps aux --forest | grep '[s]6-supervise rsyslogd'"
  [ "$status" -eq 0 ]
  run docker exec mailserver_default /bin/bash -c "ps aux --forest | grep '[r]syslogd -n -f /etc/rsyslog/rsyslog.conf'"
  [ "$status" -eq 0 ]
}

@test "checking process: cron      (default configuration)" {
  run docker exec mailserver_default /bin/bash -c "ps aux --forest | grep '[s]6-supervise cron'"
  [ "$status" -eq 0 ]
  run docker exec mailserver_default /bin/bash -c "ps aux --forest | grep '[c]ron -f'"
  [ "$status" -eq 0 ]
}

@test "checking process: postfix   (default configuration)" {
  run docker exec mailserver_default /bin/bash -c "ps aux --forest | grep '[s]6-supervise postfix'"
  [ "$status" -eq 0 ]
  run docker exec mailserver_default /bin/bash -c "ps aux --forest | grep '[/]usr/lib/postfix/sbin/master -w'"
  [ "$status" -eq 0 ]
}

@test "checking process: dovecot   (default configuration)" {
  run docker exec mailserver_default /bin/bash -c "ps aux --forest | grep '[s]6-supervise dovecot'"
  [ "$status" -eq 0 ]
  run docker exec mailserver_default /bin/bash -c "ps aux --forest | grep '[/]usr/sbin/dovecot -F'"
  [ "$status" -eq 0 ]
}

@test "checking process: rspamd    (default configuration)" {
  run docker exec mailserver_default /bin/bash -c "ps aux --forest | grep '[s]6-supervise rspamd'"
  [ "$status" -eq 0 ]
  run docker exec mailserver_default /bin/bash -c "ps aux --forest | grep '[r]spamd: main process'"
  [ "$status" -eq 0 ]
  run docker exec mailserver_default /bin/bash -c "ps aux --forest | grep '[r]spamd: rspamd_proxy process'"
  [ "$status" -eq 0 ]
  run docker exec mailserver_default /bin/bash -c "ps aux --forest | grep '[r]spamd: controller process'"
  [ "$status" -eq 0 ]
}

@test "checking process: clamd     (default configuration)" {
  run docker exec mailserver_default /bin/bash -c "ps aux --forest | grep '[s]6-supervise clamd'"
  [ "$status" -eq 0 ]
  run docker exec mailserver_default /bin/bash -c "ps aux --forest | grep '[c]lamd'"
  [ "$status" -eq 0 ]
}

@test "checking process: freshclam (default configuration)" {
  run docker exec mailserver_default /bin/bash -c "ps aux --forest | grep '[s]6-supervise freshclam'"
  [ "$status" -eq 0 ]
  run docker exec mailserver_default /bin/bash -c "ps aux --forest | grep '[f]reshclam -d'"
  [ "$status" -eq 0 ]
}

#
# processes (reverse configuration)
#

@test "checking process: s6        (reverse configuration)" {
  run docker exec mailserver_reverse /bin/bash -c "ps aux --forest | grep '[s]6-svscan /etc/s6.d'"
  [ "$status" -eq 0 ]
}

@test "checking process: rsyslog   (reverse configuration)" {
  run docker exec mailserver_reverse /bin/bash -c "ps aux --forest | grep '[s]6-supervise rsyslogd'"
  [ "$status" -eq 0 ]
  run docker exec mailserver_reverse /bin/bash -c "ps aux --forest | grep '[r]syslogd -n -f /etc/rsyslog/rsyslog.conf'"
  [ "$status" -eq 0 ]
}

@test "checking process: cron      (reverse configuration)" {
  run docker exec mailserver_reverse /bin/bash -c "ps aux --forest | grep '[s]6-supervise cron'"
  [ "$status" -eq 0 ]
  run docker exec mailserver_reverse /bin/bash -c "ps aux --forest | grep '[c]ron -f'"
  [ "$status" -eq 0 ]
}

@test "checking process: postfix   (reverse configuration)" {
  run docker exec mailserver_reverse /bin/bash -c "ps aux --forest | grep '[s]6-supervise postfix'"
  [ "$status" -eq 0 ]
  run docker exec mailserver_reverse /bin/bash -c "ps aux --forest | grep '[/]usr/lib/postfix/sbin/master -w'"
  [ "$status" -eq 0 ]
}

@test "checking process: dovecot   (reverse configuration)" {
  run docker exec mailserver_reverse /bin/bash -c "ps aux --forest | grep '[s]6-supervise dovecot'"
  [ "$status" -eq 0 ]
  run docker exec mailserver_reverse /bin/bash -c "ps aux --forest | grep '[/]usr/sbin/dovecot -F'"
  [ "$status" -eq 0 ]
}

@test "checking process: rspamd    (reverse configuration)" {
  run docker exec mailserver_reverse /bin/bash -c "ps aux --forest | grep '[s]6-supervise rspamd'"
  [ "$status" -eq 0 ]
  run docker exec mailserver_reverse /bin/bash -c "ps aux --forest | grep '[r]spamd: main process'"
  [ "$status" -eq 0 ]
  run docker exec mailserver_reverse /bin/bash -c "ps aux --forest | grep '[r]spamd: rspamd_proxy process'"
  [ "$status" -eq 0 ]
  run docker exec mailserver_reverse /bin/bash -c "ps aux --forest | grep '[r]spamd: controller process'"
  [ "$status" -eq 0 ]
}

@test "checking process: clamd     (reverse configuration)" {
  run docker exec mailserver_reverse /bin/bash -c "ps aux --forest | grep '[s]6-supervise clamd'"
  [ "$status" -eq 0 ]
  run docker exec mailserver_reverse /bin/bash -c "ps aux --forest | grep -v 's6' | grep '[c]lamd'"
  [ "$status" -eq 1 ]
}

@test "checking process: freshclam (reverse configuration)" {
  run docker exec mailserver_reverse /bin/bash -c "ps aux --forest | grep '[s]6-supervise freshclam'"
  [ "$status" -eq 0 ]
  run docker exec mailserver_reverse /bin/bash -c "ps aux --forest | grep '[f]reshclam -d'"
  [ "$status" -eq 1 ]
}

#
# ports
#

@test "checking port    (25): external port listening (default configuration)" {
  run docker exec mailserver_default /bin/sh -c "nc -z 0.0.0.0 25"
  [ "$status" -eq 0 ]
}

@test "checking port    (25): external port listening (reverse configuration)" {
  run docker exec mailserver_reverse /bin/sh -c "nc -z 0.0.0.0 25"
  [ "$status" -eq 0 ]
}

@test "checking port   (110): external port closed    (default configuration)" {
  run docker exec mailserver_default /bin/sh -c "nc -z 0.0.0.0 110"
  [ "$status" -eq 1 ]
}

@test "checking port   (110): external port listening (reverse configuration)" {
  run docker exec mailserver_reverse /bin/sh -c "nc -z 0.0.0.0 110"
  [ "$status" -eq 0 ]
}

@test "checking port   (143): external port listening (default configuration)" {
  run docker exec mailserver_default /bin/sh -c "nc -z 0.0.0.0 143"
  [ "$status" -eq 0 ]
}

@test "checking port   (143): external port listening (reverse configuration)" {
  run docker exec mailserver_reverse /bin/sh -c "nc -z 0.0.0.0 143"
  [ "$status" -eq 0 ]
}

@test "checking port   (465): external port listening (default configuration)" {
  run docker exec mailserver_default /bin/sh -c "nc -z 0.0.0.0 465"
  [ "$status" -eq 0 ]
}

@test "checking port   (465): external port listening (reverse configuration)" {
  run docker exec mailserver_reverse /bin/sh -c "nc -z 0.0.0.0 465"
  [ "$status" -eq 0 ]
}

@test "checking port   (587): external port listening (default configuration)" {
  run docker exec mailserver_default /bin/sh -c "nc -z 0.0.0.0 587"
  [ "$status" -eq 0 ]
}

@test "checking port   (587): external port listening (reverse configuration)" {
  run docker exec mailserver_reverse /bin/sh -c "nc -z 0.0.0.0 587"
  [ "$status" -eq 0 ]
}

@test "checking port   (993): external port listening (default configuration)" {
  run docker exec mailserver_default /bin/sh -c "nc -z 0.0.0.0 993"
  [ "$status" -eq 0 ]
}

@test "checking port   (993): external port listening (reverse configuration)" {
  run docker exec mailserver_reverse /bin/sh -c "nc -z 0.0.0.0 993"
  [ "$status" -eq 0 ]
}

@test "checking port   (995): external port closed    (default configuration)" {
  run docker exec mailserver_default /bin/sh -c "nc -z 0.0.0.0 995"
  [ "$status" -eq 1 ]
}

@test "checking port   (995): external port listening (reverse configuration)" {
  run docker exec mailserver_reverse /bin/sh -c "nc -z 0.0.0.0 995"
  [ "$status" -eq 0 ]
}

@test "checking port  (3310): external port listening (default configuration)" {
  run docker exec mailserver_default /bin/sh -c "nc -z 0.0.0.0 3310"
  [ "$status" -eq 0 ]
}

@test "checking port  (3310): external port closed    (reverse configuration)" {
  run docker exec mailserver_reverse /bin/sh -c "nc -z 0.0.0.0 3310"
  [ "$status" -eq 1 ]
}

@test "checking port  (4190): external port listening (default configuration)" {
  run docker exec mailserver_default /bin/sh -c "nc -z 0.0.0.0 4190"
  [ "$status" -eq 0 ]
}

@test "checking port  (4190): external port closed    (reverse configuration)" {
  run docker exec mailserver_reverse /bin/sh -c "nc -z 0.0.0.0 4190"
  [ "$status" -eq 1 ]
}

@test "checking port (11332): external port listening (default configuration)" {
  run docker exec mailserver_default /bin/sh -c "nc -z 0.0.0.0 11332"
  [ "$status" -eq 0 ]
}

@test "checking port (11332): external port listening (reverse configuration)" {
  run docker exec mailserver_reverse /bin/sh -c "nc -z 0.0.0.0 11332"
  [ "$status" -eq 0 ]
}

@test "checking port (11333): external port listening (default configuration)" {
  run docker exec mailserver_default /bin/sh -c "nc -z 0.0.0.0 11333"
  [ "$status" -eq 0 ]
}

@test "checking port (11333): external port listening (reverse configuration)" {
  run docker exec mailserver_reverse /bin/sh -c "nc -z 0.0.0.0 11333"
  [ "$status" -eq 0 ]
}

@test "checking port (11334): external port listening (default configuration)" {
  run docker exec mailserver_default /bin/sh -c "nc -z 0.0.0.0 11334"
  [ "$status" -eq 0 ]
}

@test "checking port (11334): external port listening (reverse configuration)" {
  run docker exec mailserver_reverse /bin/sh -c "nc -z 0.0.0.0 11334"
  [ "$status" -eq 0 ]
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

@test "checking smtp: john.doe should have received 4 mails (internal + external + subaddress + hostmaster alias) (default configuration)" {
  run docker exec mailserver_default /bin/sh -c "ls -A /var/mail/vhosts/domain.tld/john.doe/mail/new/ | wc -l"
  [ "$status" -eq 0 ]
  [ "$output" = 4 ]
}

@test "checking smtp: john.doe should have received 4 mails (internal + external + subaddress + hostmaster alias) (reverse configuration)" {
  run docker exec mailserver_reverse /bin/sh -c "ls -A /var/mail/vhosts/domain.tld/john.doe/subdir/new/ | wc -l"
  [ "$status" -eq 0 ]
  [ "$output" = 4 ]
}

#@test "checking smtp: john.doe should have received 1 spam (external mail stored in Spam folder by Sieve)" {
#  run docker exec mailserver_default /bin/sh -c "ls -A /var/mail/vhosts/domain.tld/john.doe/mail/.Spam/new/ | wc -l"
#  [ "$status" -eq 0 ]
#  [ "$output" = 1 ]
#}

@test "checking smtp: rejects mail to unknown user (default configuration)" {
  run docker exec mailserver_default /bin/sh -c "grep '<ghost@domain.tld>: Recipient address rejected: User unknown in virtual mailbox table' /var/log/mail.log | wc -l"
  [ "$status" -eq 0 ]
  [ "$output" = 1 ]
}

@test "checking smtp: rejects mail to unknown user (reverse configuration)" {
  run docker exec mailserver_default /bin/sh -c "grep '<ghost@domain.tld>: Recipient address rejected: User unknown in virtual mailbox table' /var/log/mail.log | wc -l"
  [ "$status" -eq 0 ]
  [ "$output" = 1 ]
}

@test "checking smtp: delivers mail to existing alias (default configuration)" {
  run docker exec mailserver_default /bin/sh -c "grep 'to=<john.doe@domain.tld>, orig_to=<hostmaster@domain.tld>' /var/log/mail.log | grep 'status=sent' | wc -l"
  [ "$status" -eq 0 ]
  [ "$output" = 1 ]
}

@test "checking smtp: delivers mail to existing alias (reverse configuration)" {
  run docker exec mailserver_reverse /bin/sh -c "grep 'to=<john.doe@domain.tld>, orig_to=<hostmaster@domain.tld>' /var/log/mail.log | grep 'status=sent' | wc -l"
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

# rspamd

@test "checking rspamd: spam filtered (default configuration)" {
  run docker exec mailserver_default /bin/sh -c "grep -i 'Gtube pattern; from=<spam@example.com> to=<john.doe@domain.tld> ' /var/log/mail.log | wc -l"
  [ "$status" -eq 0 ]
  [ "$output" = 1 ]
}

@test "checking rspamd: spam filtered (reverse configuration)" {
  run docker exec mailserver_reverse /bin/sh -c "grep -i 'Gtube pattern; from=<spam@example.com> to=<john.doe@domain.tld> ' /var/log/mail.log | wc -l"
  [ "$status" -eq 0 ]
  [ "$output" = 1 ]
}

@test "checking rspamd: existing rrd file" {
  run docker exec mailserver_default [ -f /var/mail/rspamd/rspamd.rrd ]
  [ "$status" -eq 0 ]
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
  run docker exec mailserver_default /bin/bash -c "ls -A /var/mail/vhosts/domain.tld/john.doe/mail/ | grep -E 'cur|new|tmp' | wc -l"
  [ "$status" -eq 0 ]
  [ "$output" -eq 3 ]
}

@test "checking accounts: user mail folders for sarah.connor" {
  run docker exec mailserver_default /bin/bash -c "ls -A /var/mail/vhosts/domain.tld/sarah.connor/mail/ | grep -E 'cur|new|tmp' | wc -l"
  [ "$status" -eq 0 ]
  [ "$output" -eq 3 ]
}

#
# dkim
#

@test "checking dkim: all key pairs are generated (default configuration)" {
  run docker exec mailserver_default /bin/bash -c "ls -A /var/mail/dkim/*/{private.key,public.key} | wc -l"
  [ "$status" -eq 0 ]
  [ "$output" -eq 6 ]
}

@test "checking dkim: all key pairs are generated (reverse configuration)" {
  run docker exec mailserver_reverse /bin/bash -c "ls -A /var/mail/dkim/*/{private.key,public.key} | wc -l"
  [ "$status" -eq 0 ]
  [ "$output" -eq 2 ]
}

@test "checking dkim: control the size of the RSA key pair (4096bits)" {
  run docker exec mailserver_reverse /bin/bash -c "openssl rsa -in /var/mail/dkim/domain.tld/private.key -text -noout | grep -i 'Private-Key: (4096 bit)'"
  [ "$status" -eq 0 ]
}

#
# postfix
#

@test "checking postfix: mynetworks value (default configuration)" {
  run docker exec mailserver_default /bin/sh -c "postconf -h mynetworks"
  [ "$status" -eq 0 ]
  [ "$output" = "127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128" ]
}

@test "checking postfix: mynetworks value (reverse configuration)" {
  run docker exec mailserver_reverse /bin/sh -c "postconf -h mynetworks"
  [ "$status" -eq 0 ]
  [ "$output" = "127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128 192.168.0.0/16 172.16.0.0/12 10.0.0.0/8" ]
}

@test "checking postfix: main.cf overrides" {
  run docker exec mailserver_default /bin/sh -c "postconf -h max_idle"
  [ "$status" -eq 0 ]
  [ "$output" = "600s" ]

  run docker exec mailserver_default /bin/sh -c "postconf -h readme_directory"
  [ "$status" -eq 0 ]
  [ "$output" = "/tmp" ]
}

@test "checking postfix: headers cleanup" {
  run docker exec mailserver_default /bin/sh -c "grep -i 'replace: header Received' /var/log/mail.log | wc -l"
  [ "$status" -eq 0 ]
  [ "$output" -eq 1 ]
}

@test "checking postfix: myorigin value (docker method)" {
  run docker exec mailserver_default postconf -h myorigin
  [ "$status" -eq 0 ]
  [ "$output" = "mail.domain.tld" ]
}

@test "checking postfix: myorigin value (env method)" {
  run docker exec mailserver_reverse postconf -h myorigin
  [ "$status" -eq 0 ]
  [ "$output" = "mail.domain.tld" ]
}

@test "checking postfix: two milter rejects (GTUBE + EICAR)" {
  run docker exec mailserver_default /bin/sh -c "grep -i 'milter-reject' /var/log/mail.log | wc -l"
  [ "$status" -eq 0 ]
  [ "$output" -eq 2 ]
}

@test "checking postfix: milter-reject - clamav virus found" {
  run docker exec mailserver_default grep -i 'milter-reject.*clamav: virus found' /var/log/mail.log
  [ "$status" -eq 0 ]
}

#
# dovecot
#

@test "checking dovecot: existing ssl-parameters file" {
  run docker exec mailserver_default [ -f /var/mail/dovecot/ssl-parameters.dat ]
  [ "$status" -eq 0 ]
}

@test "checking dovecot: existing instances file" {
  run docker exec mailserver_default [ -f /var/mail/dovecot/instances ]
  [ "$status" -eq 0 ]
}

@test "checking dovecot: default lib directory is a symlink" {
  run docker exec mailserver_default [ -L /var/lib/dovecot ]
  [ "$status" -eq 0 ]
}

#
# clamav
#

@test "checking clamav: TCP Bound to 3310 port" {
  run docker exec mailserver_default grep -i 'TCP: Bound to \[0.0.0.0\]:3310' /var/log/mail.log
  [ "$status" -eq 0 ]
}

@test "checking clamav: all databases downloaded" {
  run docker exec mailserver_default [ -f /var/lib/clamav/main.cvd ]
  [ "$status" -eq 0 ]
  run docker exec mailserver_default [ -f /var/lib/clamav/daily.cvd ]
  [ "$status" -eq 0 ]
  run docker exec mailserver_default [ -f /var/lib/clamav/bytecode.cvd ]
  [ "$status" -eq 0 ]
}

@test "checking clamav: all databases correctly reloaded" {
  run docker exec mailserver_default grep -i 'clamd\[.*\]: Database correctly reloaded' /var/log/mail.log
  [ "$status" -eq 0 ]
}

@test "checking clamav: mirrors.dat exist" {
  run docker exec mailserver_default [ -f /var/lib/clamav/mirrors.dat ]
  [ "$status" -eq 0 ]
}

@test "checking clamav: default lib directory is a symlink" {
  run docker exec mailserver_default [ -L /var/lib/clamav ]
  [ "$status" -eq 0 ]
}

@test "checking clamav: Eicar-Test-Signature FOUND" {
  run docker exec mailserver_default grep -i 'Eicar-Test-Signature(.*) FOUND' /var/log/mail.log
  [ "$status" -eq 0 ]
}

@test "checking clamav: 5 Database mirrors" {
  run docker exec mailserver_default /bin/sh -c "grep 'DatabaseMirror' /etc/clamav/freshclam.conf | wc -l"
  [ "$status" -eq 0 ]
  [ "$output" -eq 5 ]
}


#
# ssl
#

@test "checking ssl: generated default cert works correctly" {
  run docker exec mailserver_default /bin/sh -c "timeout 1 openssl s_client -ign_eof -connect 0.0.0.0:587 -starttls smtp | grep 'Verify return code: 18 (self signed certificate)'"
  [ "$status" -eq 0 ]
}

@test "checking ssl: let's encrypt cert works correctly" {
  run docker exec mailserver_reverse /bin/sh -c "timeout 1 openssl s_client -ign_eof -connect 0.0.0.0:587 -starttls smtp | grep 'Verify return code: 10 (certificate has expired)'"
  [ "$status" -eq 0 ]
}

@test "checking ssl: default configuration is correct" {
  run docker exec mailserver_default /bin/sh -c "grep '/var/mail/ssl/selfsigned' /etc/postfix/main.cf | wc -l"
  [ "$status" -eq 0 ]
  [ "$output" -eq 2 ]
  run docker exec mailserver_default /bin/sh -c "grep '/var/mail/ssl/selfsigned' /etc/dovecot/conf.d/10-ssl.conf | wc -l"
  [ "$status" -eq 0 ]
  [ "$output" -eq 2 ]
}

@test "checking ssl: let's encrypt configuration is correct" {
  run docker exec mailserver_reverse /bin/sh -c "grep '/etc/letsencrypt/live/mail.domain.tld' /etc/postfix/main.cf | wc -l"
  [ "$status" -eq 0 ]
  [ "$output" -eq 3 ]
  run docker exec mailserver_reverse /bin/sh -c "grep '/etc/letsencrypt/live/mail.domain.tld' /etc/dovecot/conf.d/10-ssl.conf | wc -l"
  [ "$status" -eq 0 ]
  [ "$output" -eq 2 ]
}

#
# index files
#

@test "checking hash tables: existing header_checks and virtual index files" {
  run docker exec mailserver_default [ -f /etc/postfix/header_checks.db ]
  [ "$status" -eq 0 ]
  run docker exec mailserver_default [ -f /etc/postfix/virtual.db ]
  [ "$status" -eq 0 ]
}

#
# logs
#

@test "checking logs: /var/log/mail.log in mailserver_default is error free" {
  run docker exec mailserver_default grep -i ': error:' /var/log/mail.log
  [ "$status" -eq 1 ]
  run docker exec mailserver_default grep -i 'is not writable' /var/log/mail.log
  [ "$status" -eq 1 ]
  run docker exec mailserver_default grep -i 'permission denied' /var/log/mail.log
  [ "$status" -eq 1 ]
}

@test "checking logs: /var/log/mail.log in mailserver_reverse is error free " {
  run docker exec mailserver_reverse grep -i ': error:' /var/log/mail.log
  [ "$status" -eq 1 ]
  run docker exec mailserver_reverse grep -i 'is not writable' /var/log/mail.log
  [ "$status" -eq 1 ]
  run docker exec mailserver_reverse grep -i 'permission denied' /var/log/mail.log
  [ "$status" -eq 1 ]
}

@test "checking logs: /var/log/mail.err in mailserver_default does not exist" {
  run docker exec mailserver_default [ -f /var/log/mail.err ]
  [ "$status" -eq 1 ]
}

@test "checking logs: /var/log/mail.err in mailserver_reverse does not exist" {
  run docker exec mailserver_reverse [ -f /var/log/mail.err ]
  [ "$status" -eq 1 ]
}
