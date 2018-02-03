load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

#
# system
#

@test "checking system: /etc/mailname (docker method)" {
  run docker exec mailserver_default cat /etc/mailname
  assert_success
  assert_output "mail.domain.tld"
}

@test "checking system: /etc/mailname (env method)" {
  run docker exec mailserver_reverse cat /etc/mailname
  assert_success
  assert_output "mail.domain.tld"
}

@test "checking system: /etc/hostname" {
  run docker exec mailserver_default cat /etc/hostname
  assert_success
  assert_output "mail.domain.tld"
}

@test "checking system: /etc/hosts" {
  run docker exec mailserver_default grep "mail.domain.tld" /etc/hosts
  assert_success
}

@test "checking system: fqdn" {
  run docker exec mailserver_default hostname -f
  assert_success
  assert_output "mail.domain.tld"
}

@test "checking system: domain" {
  run docker exec mailserver_default hostname -d
  assert_success
  assert_output "domain.tld"
}

@test "checking system: hostname" {
  run docker exec mailserver_default hostname -s
  assert_success
  assert_output "mail"
}

@test "checking system: all environment variables have been replaced (default configuration)" {
  run docker exec mailserver_default /bin/bash -c "egrep -R "{{.*}}" /etc/postfix /etc/postfixadmin/fetchmail.conf /etc/dovecot /etc/rspamd /etc/mailname /usr/local/bin"
  assert_failure
}

@test "checking system: all environment variables have been replaced (reverse configuration)" {
  run docker exec mailserver_reverse /bin/bash -c "egrep -R "{{.*}}" /etc/postfix /etc/postfixadmin/fetchmail.conf /etc/dovecot /etc/rspamd /etc/mailname /usr/local/bin"
  assert_failure
}

#
# processes (default configuration)
#

@test "checking process: s6        (default configuration)" {
  run docker exec mailserver_default /bin/bash -c "ps aux --forest | grep '[s]6-svscan /services'"
  assert_success
}

@test "checking process: rsyslog   (default configuration)" {
  run docker exec mailserver_default /bin/bash -c "ps aux --forest | grep '[s]6-supervise rsyslogd'"
  assert_success
  run docker exec mailserver_default /bin/bash -c "ps aux --forest | grep '[r]syslogd -n -f /etc/rsyslog/rsyslog.conf'"
  assert_success
}

@test "checking process: cron      (default configuration)" {
  run docker exec mailserver_default /bin/bash -c "ps aux --forest | grep '[s]6-supervise cron'"
  assert_success
  run docker exec mailserver_default /bin/bash -c "ps aux --forest | grep '[c]ron -f'"
  assert_success
}

@test "checking process: postfix   (default configuration)" {
  run docker exec mailserver_default /bin/bash -c "ps aux --forest | grep '[s]6-supervise postfix'"
  assert_success
  run docker exec mailserver_default /bin/bash -c "ps aux --forest | grep '[/]usr/lib/postfix/sbin/master -w'"
  assert_success
}

@test "checking process: dovecot   (default configuration)" {
  run docker exec mailserver_default /bin/bash -c "ps aux --forest | grep '[s]6-supervise dovecot'"
  assert_success
  run docker exec mailserver_default /bin/bash -c "ps aux --forest | grep '[/]usr/sbin/dovecot -F'"
  assert_success
}

@test "checking process: rspamd    (default configuration)" {
  run docker exec mailserver_default /bin/bash -c "ps aux --forest | grep '[s]6-supervise rspamd'"
  assert_success
  run docker exec mailserver_default /bin/bash -c "ps aux --forest | grep '[r]spamd: main process'"
  assert_success
  run docker exec mailserver_default /bin/bash -c "ps aux --forest | grep '[r]spamd: rspamd_proxy process'"
  assert_success
  run docker exec mailserver_default /bin/bash -c "ps aux --forest | grep '[r]spamd: controller process'"
  assert_success
}

@test "checking process: clamd     (default configuration)" {
  run docker exec mailserver_default /bin/bash -c "ps aux --forest | grep '[s]6-supervise clamd'"
  assert_success
  run docker exec mailserver_default /bin/bash -c "ps aux --forest | grep -v 's6' | grep '[c]lamd'"
  assert_success
}

@test "checking process: freshclam (default configuration)" {
  run docker exec mailserver_default /bin/bash -c "ps aux --forest | grep '[s]6-supervise freshclam'"
  assert_success
  run docker exec mailserver_default /bin/bash -c "ps aux --forest | grep '[f]reshclam -d'"
  assert_success
}

@test "checking process: unbound   (default configuration)" {
  run docker exec mailserver_default /bin/bash -c "ps aux --forest | grep '[s]6-supervise unbound'"
  assert_success
  run docker exec mailserver_default /bin/bash -c "ps aux --forest | grep -v 's6' | grep '[u]nbound'"
  assert_success
}

#
# processes (reverse configuration)
#

@test "checking process: s6        (reverse configuration)" {
  run docker exec mailserver_reverse /bin/bash -c "ps aux --forest | grep '[s]6-svscan /services'"
  assert_success
}

@test "checking process: rsyslog   (reverse configuration)" {
  run docker exec mailserver_reverse /bin/bash -c "ps aux --forest | grep '[s]6-supervise rsyslogd'"
  assert_success
  run docker exec mailserver_reverse /bin/bash -c "ps aux --forest | grep '[r]syslogd -n -f /etc/rsyslog/rsyslog.conf'"
  assert_success
}

@test "checking process: cron      (reverse configuration)" {
  run docker exec mailserver_reverse /bin/bash -c "ps aux --forest | grep '[s]6-supervise cron'"
  assert_success
  run docker exec mailserver_reverse /bin/bash -c "ps aux --forest | grep '[c]ron -f'"
  assert_success
}

@test "checking process: postfix   (reverse configuration)" {
  run docker exec mailserver_reverse /bin/bash -c "ps aux --forest | grep '[s]6-supervise postfix'"
  assert_success
  run docker exec mailserver_reverse /bin/bash -c "ps aux --forest | grep '[/]usr/lib/postfix/sbin/master -w'"
  assert_success
}

@test "checking process: dovecot   (reverse configuration)" {
  run docker exec mailserver_reverse /bin/bash -c "ps aux --forest | grep '[s]6-supervise dovecot'"
  assert_success
  run docker exec mailserver_reverse /bin/bash -c "ps aux --forest | grep '[/]usr/sbin/dovecot -F'"
  assert_success
}

@test "checking process: rspamd    (reverse configuration)" {
  run docker exec mailserver_reverse /bin/bash -c "ps aux --forest | grep '[s]6-supervise rspamd'"
  assert_success
  run docker exec mailserver_reverse /bin/bash -c "ps aux --forest | grep '[r]spamd: main process'"
  assert_success
  run docker exec mailserver_reverse /bin/bash -c "ps aux --forest | grep '[r]spamd: rspamd_proxy process'"
  assert_success
  run docker exec mailserver_reverse /bin/bash -c "ps aux --forest | grep '[r]spamd: controller process'"
  assert_success
}

@test "checking process: clamd     (reverse configuration)" {
  run docker exec mailserver_reverse /bin/bash -c "ps aux --forest | grep '[s]6-supervise clamd'"
  assert_success
  run docker exec mailserver_reverse /bin/bash -c "ps aux --forest | grep -v 's6' | grep '[c]lamd'"
  assert_failure
}

@test "checking process: freshclam (reverse configuration)" {
  run docker exec mailserver_reverse /bin/bash -c "ps aux --forest | grep '[s]6-supervise freshclam'"
  assert_success
  run docker exec mailserver_reverse /bin/bash -c "ps aux --forest | grep '[f]reshclam -d'"
  assert_failure
}

@test "checking process: unbound   (reverse configuration)" {
  run docker exec mailserver_reverse /bin/bash -c "ps aux --forest | grep '[s]6-supervise unbound'"
  assert_success
  run docker exec mailserver_reverse /bin/bash -c "ps aux --forest | grep -v 's6' | grep '[u]nbound'"
  assert_failure
}

#
# processes restarting
#

@test "checking process: 9 cron tasks to reset all the process counters" {
  run docker exec mailserver_default /bin/bash -c "cat /etc/cron.d/counters | wc -l"
  assert_success
  assert_output 9
  run docker exec mailserver_reverse /bin/bash -c "cat /etc/cron.d/counters | wc -l"
  assert_success
  assert_output 9
}

@test "checking process: no service restarted (default configuration)" {
  run docker exec mailserver_default cat /tmp/counters/_parent
  assert_success
  assert_output 0
  run docker exec mailserver_default cat /tmp/counters/clamd
  assert_success
  assert_output 0
  run docker exec mailserver_default cat /tmp/counters/cron
  assert_success
  assert_output 0
  run docker exec mailserver_default cat /tmp/counters/dovecot
  assert_success
  assert_output 0
  run docker exec mailserver_default cat /tmp/counters/freshclam
  assert_success
  assert_output 0
  run docker exec mailserver_default cat /tmp/counters/postfix
  assert_success
  assert_output 0
  run docker exec mailserver_default cat /tmp/counters/rspamd
  assert_success
  assert_output 0
  run docker exec mailserver_default cat /tmp/counters/rsyslogd
  assert_success
  assert_output 0
  run docker exec mailserver_default cat /tmp/counters/unbound
  assert_success
  assert_output 0
}

@test "checking process: no service restarted (reverse configuration)" {
  run docker exec mailserver_default cat /tmp/counters/_parent
  assert_success
  assert_output 0
  run docker exec mailserver_reverse cat /tmp/counters/clamd
  assert_success
  assert_output 0
  run docker exec mailserver_reverse cat /tmp/counters/cron
  assert_success
  assert_output 0
  run docker exec mailserver_reverse cat /tmp/counters/dovecot
  assert_success
  assert_output 0
  run docker exec mailserver_reverse cat /tmp/counters/freshclam
  assert_success
  assert_output 0
  run docker exec mailserver_reverse cat /tmp/counters/postfix
  assert_success
  assert_output 0
  run docker exec mailserver_reverse cat /tmp/counters/rspamd
  assert_success
  assert_output 0
  run docker exec mailserver_reverse cat /tmp/counters/rsyslogd
  assert_success
  assert_output 0
  run docker exec mailserver_reverse cat /tmp/counters/unbound
  assert_success
  assert_output 0
}

#
# ports
#

@test "checking port    (25): external port listening (default configuration)" {
  run docker exec mailserver_default /bin/sh -c "nc -z 0.0.0.0 25"
  assert_success
}

@test "checking port    (25): external port listening (reverse configuration)" {
  run docker exec mailserver_reverse /bin/sh -c "nc -z 0.0.0.0 25"
  assert_success
}

@test "checking port    (53): internal port listening (default configuration)" {
  run docker exec mailserver_default /bin/sh -c "nc -z 127.0.0.1 53"
  assert_success
}

@test "checking port    (53): internal port listening (reverse configuration)" {
  run docker exec mailserver_reverse /bin/sh -c "nc -z 127.0.0.1 53"
  assert_failure
}

@test "checking port   (110): external port closed    (default configuration)" {
  run docker exec mailserver_default /bin/sh -c "nc -z 0.0.0.0 110"
  assert_failure
}

@test "checking port   (110): external port listening (reverse configuration)" {
  run docker exec mailserver_reverse /bin/sh -c "nc -z 0.0.0.0 110"
  assert_success
}

@test "checking port   (143): external port listening (default configuration)" {
  run docker exec mailserver_default /bin/sh -c "nc -z 0.0.0.0 143"
  assert_success
}

@test "checking port   (143): external port listening (reverse configuration)" {
  run docker exec mailserver_reverse /bin/sh -c "nc -z 0.0.0.0 143"
  assert_success
}

@test "checking port   (465): external port listening (default configuration)" {
  run docker exec mailserver_default /bin/sh -c "nc -z 0.0.0.0 465"
  assert_success
}

@test "checking port   (465): external port listening (reverse configuration)" {
  run docker exec mailserver_reverse /bin/sh -c "nc -z 0.0.0.0 465"
  assert_success
}

@test "checking port   (587): external port listening (default configuration)" {
  run docker exec mailserver_default /bin/sh -c "nc -z 0.0.0.0 587"
  assert_success
}

@test "checking port   (587): external port listening (reverse configuration)" {
  run docker exec mailserver_reverse /bin/sh -c "nc -z 0.0.0.0 587"
  assert_success
}

@test "checking port   (993): external port listening (default configuration)" {
  run docker exec mailserver_default /bin/sh -c "nc -z 0.0.0.0 993"
  assert_success
}

@test "checking port   (993): external port listening (reverse configuration)" {
  run docker exec mailserver_reverse /bin/sh -c "nc -z 0.0.0.0 993"
  assert_success
}

@test "checking port   (995): external port closed    (default configuration)" {
  run docker exec mailserver_default /bin/sh -c "nc -z 0.0.0.0 995"
  assert_failure
}

@test "checking port   (995): external port listening (reverse configuration)" {
  run docker exec mailserver_reverse /bin/sh -c "nc -z 0.0.0.0 995"
  assert_success
}

@test "checking port  (3310): external port listening (default configuration)" {
  run docker exec mailserver_default /bin/sh -c "nc -z 0.0.0.0 3310"
  assert_success
}

@test "checking port  (3310): external port closed    (reverse configuration)" {
  run docker exec mailserver_reverse /bin/sh -c "nc -z 0.0.0.0 3310"
  assert_failure
}

@test "checking port  (4190): external port listening (default configuration)" {
  run docker exec mailserver_default /bin/sh -c "nc -z 0.0.0.0 4190"
  assert_success
}

@test "checking port  (4190): external port closed    (reverse configuration)" {
  run docker exec mailserver_reverse /bin/sh -c "nc -z 0.0.0.0 4190"
  assert_failure
}

@test "checking port  (8953): internal port listening (default configuration)" {
  run docker exec mailserver_default /bin/sh -c "nc -z 127.0.0.1 8953"
  assert_success
}

@test "checking port  (8953): internal port listening (reverse configuration)" {
  run docker exec mailserver_reverse /bin/sh -c "nc -z 127.0.0.1 8953"
  assert_failure
}

@test "checking port (10026): internal port listening (default configuration)" {
  run docker exec mailserver_default /bin/sh -c "nc -z 127.0.0.1 10026"
  assert_success
}

@test "checking port (10026): internal port listening (reverse configuration)" {
  run docker exec mailserver_reverse /bin/sh -c "nc -z 127.0.0.1 10026"
  assert_success
}

@test "checking port (11332): external port listening (default configuration)" {
  run docker exec mailserver_default /bin/sh -c "nc -z 0.0.0.0 11332"
  assert_success
}

@test "checking port (11332): external port listening (reverse configuration)" {
  run docker exec mailserver_reverse /bin/sh -c "nc -z 0.0.0.0 11332"
  assert_success
}

@test "checking port (11333): external port listening (default configuration)" {
  run docker exec mailserver_default /bin/sh -c "nc -z 0.0.0.0 11333"
  assert_success
}

@test "checking port (11333): external port listening (reverse configuration)" {
  run docker exec mailserver_reverse /bin/sh -c "nc -z 0.0.0.0 11333"
  assert_success
}

@test "checking port (11334): external port listening (default configuration)" {
  run docker exec mailserver_default /bin/sh -c "nc -z 0.0.0.0 11334"
  assert_success
}

@test "checking port (11334): external port listening (reverse configuration)" {
  run docker exec mailserver_reverse /bin/sh -c "nc -z 0.0.0.0 11334"
  assert_success
}

#
# sasl
#

@test "checking sasl: dovecot auth with good password" {
  run docker exec mailserver_default /bin/sh -c "doveadm auth test sarah.connor@domain.tld testpasswd12 | grep 'auth succeeded'"
  assert_success
}

@test "checking sasl: dovecot auth with bad password" {
  run docker exec mailserver_default /bin/sh -c "doveadm auth test sarah.connor@domain.tld badpassword | grep 'auth failed'"
  assert_success
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
  assert_success
}

@test "checking smtp (25): STARTTLS AUTH PLAIN fails with bad password" {
  run docker exec mailserver_default /bin/sh -c "openssl s_client -ign_eof -connect 0.0.0.0:25 -starttls smtp < /tmp/tests/auth/smtp-auth-plain-wrong.txt 2>&1 | grep -i 'authentication failed'"
  assert_success
}

@test "checking smtp (25): clear auth disabled" {
  run docker exec mailserver_default /bin/sh -c "nc -w 2 0.0.0.0 25 < /tmp/tests/auth/smtp-auth-plain.txt | grep -i 'authentication not enabled'"
  assert_success
}

@test "checking submission (587): STARTTLS AUTH LOGIN works with good password" {
  run docker exec mailserver_default /bin/sh -c "openssl s_client -ign_eof -connect 0.0.0.0:587 -starttls smtp < /tmp/tests/auth/smtp-auth-login.txt 2>&1 | grep -i 'authentication successful'"
  assert_success
}

@test "checking submission (587): STARTTLS AUTH LOGIN fails with bad password" {
  run docker exec mailserver_default /bin/sh -c "openssl s_client -ign_eof -connect 0.0.0.0:587 -starttls smtp < /tmp/tests/auth/smtp-auth-login-wrong.txt 2>&1 | grep -i 'authentication failed'"
  assert_success
}

@test "checking submission (587): Auth without STARTTLS fail" {
  run docker exec mailserver_default /bin/sh -c "nc -w 2 0.0.0.0 587 < /tmp/tests/auth/smtp-auth-plain.txt | grep -i 'Must issue a STARTTLS command first'"
  assert_success
}

@test "checking smtps (465): SSL/TLS AUTH LOGIN works with good password" {
  run docker exec mailserver_default /bin/sh -c "openssl s_client -ign_eof -connect 0.0.0.0:465 < /tmp/tests/auth/smtp-auth-login.txt 2>&1 | grep -i 'authentication successful'"
  assert_success
}

@test "checking smtps (465): SSL/TLS AUTH LOGIN fails with bad password" {
  run docker exec mailserver_default /bin/sh -c "openssl s_client -ign_eof -connect 0.0.0.0:465 < /tmp/tests/auth/smtp-auth-login-wrong.txt 2>&1 | grep -i 'authentication failed'"
  assert_success
}

@test "checking smtp: john.doe should have received 4 mails (internal + external + subaddress + hostmaster alias) (default configuration)" {
  run docker exec mailserver_default /bin/sh -c "ls -A /var/mail/vhosts/domain.tld/john.doe/mail/new/ | wc -l"
  assert_success
  assert_output 4
}

@test "checking smtp: john.doe should have received 4 mails (internal + external + subaddress + hostmaster alias) (reverse configuration)" {
  run docker exec mailserver_reverse /bin/sh -c "ls -A /var/mail/vhosts/domain.tld/john.doe/subdir/new/ | wc -l"
  assert_success
  assert_output 4
}

@test "checking smtp: sarah.connor should have received 1 mail (internal spam-ham test) (default configuration)" {
  run docker exec mailserver_default /bin/sh -c "ls -A /var/mail/vhosts/domain.tld/sarah.connor/mail/new/ | wc -l"
  assert_success
  assert_output 1
}

@test "checking smtp: sarah.connor should have received 1 spam (with manual IMAP COPY to Spam folder)" {
  run docker exec mailserver_default /bin/sh -c "ls -A /var/mail/vhosts/domain.tld/sarah.connor/mail/.Spam/cur/ | wc -l"
  assert_success
  assert_output 1
}

@test "checking smtp: rejects mail to unknown user (default configuration)" {
  run docker exec mailserver_default /bin/sh -c "grep '<ghost@domain.tld>: Recipient address rejected: User unknown in virtual mailbox table' /var/log/mail.log | wc -l"
  assert_success
  assert_output 1
}

@test "checking smtp: rejects mail to unknown user (reverse configuration)" {
  run docker exec mailserver_default /bin/sh -c "grep '<ghost@domain.tld>: Recipient address rejected: User unknown in virtual mailbox table' /var/log/mail.log | wc -l"
  assert_success
  assert_output 1
}

@test "checking smtp: delivers mail to existing alias (default configuration)" {
  run docker exec mailserver_default /bin/sh -c "grep 'to=<john.doe@domain.tld>, orig_to=<hostmaster@domain.tld>' /var/log/mail.log | grep 'status=sent' | wc -l"
  assert_success
  assert_output 1
}

@test "checking smtp: delivers mail to existing alias (reverse configuration)" {
  run docker exec mailserver_reverse /bin/sh -c "grep 'to=<john.doe@domain.tld>, orig_to=<hostmaster@domain.tld>' /var/log/mail.log | grep 'status=sent' | wc -l"
  assert_success
  assert_output 1
}

#
# imap
#

@test "checking imap (143): STARTTLS login works with good password" {
  run docker exec mailserver_default /bin/sh -c "openssl s_client -ign_eof -connect 0.0.0.0:143 -starttls imap < /tmp/tests/auth/imap-auth.txt 2>&1 | grep -i 'logged in'"
  assert_success
}

@test "checking imap (143): STARTTLS login fails with bad password" {
  run docker exec mailserver_default /bin/sh -c "openssl s_client -ign_eof -connect 0.0.0.0:143 -starttls imap < /tmp/tests/auth/imap-auth-wrong.txt 2>&1 | grep -i 'authentication failed'"
  assert_success
}

@test "checking imaps (993): SSL/TLS login works with good password" {
  run docker exec mailserver_default /bin/sh -c "openssl s_client -ign_eof -connect 0.0.0.0:993 < /tmp/tests/auth/imap-auth.txt 2>&1 | grep -i 'logged in'"
  assert_success
}

@test "checking imaps (993): SSL/TLS login fails with bad password" {
  run docker exec mailserver_default /bin/sh -c "openssl s_client -ign_eof -connect 0.0.0.0:993 < /tmp/tests/auth/imap-auth-wrong.txt 2>&1 | grep -i 'authentication failed'"
  assert_success
}

#
# pop
#

@test "checking pop3 (110): STARTTLS login works with good password" {
  run docker exec mailserver_reverse /bin/sh -c "openssl s_client -ign_eof -connect 0.0.0.0:110 -starttls pop3 < /tmp/tests/auth/pop3-auth.txt 2>&1 | grep -i 'ok logged in'"
  assert_success
}

@test "checking pop3 (110): STARTTLS login fails with bad password" {
  run docker exec mailserver_reverse /bin/sh -c "openssl s_client -ign_eof -connect 0.0.0.0:110 -starttls pop3 < /tmp/tests/auth/pop3-auth-wrong.txt 2>&1 | grep -i 'authentication failed'"
  assert_success
}

@test "checking pop3s (995): SSL/TLS login works with good password" {
  run docker exec mailserver_reverse /bin/sh -c "openssl s_client -ign_eof -connect 0.0.0.0:995 < /tmp/tests/auth/pop3-auth.txt 2>&1 | grep -i 'ok logged in'"
  assert_success
}

@test "checking pop3s (995): SSL/TLS login fails with bad password" {
  run docker exec mailserver_reverse /bin/sh -c "openssl s_client -ign_eof -connect 0.0.0.0:995 < /tmp/tests/auth/pop3-auth-wrong.txt 2>&1 | grep -i 'authentication failed'"
  assert_success
}

# rspamd

@test "checking rspamd: spam filtered (default configuration)" {
  run docker exec mailserver_default /bin/sh -c "grep -i 'Gtube pattern; from=<spam@example.com> to=<john.doe@domain.tld> ' /var/log/mail.log | wc -l"
  assert_success
  assert_output 1
}

@test "checking rspamd: spam filtered (reverse configuration)" {
  run docker exec mailserver_reverse /bin/sh -c "grep -i 'Gtube pattern; from=<spam@example.com> to=<john.doe@domain.tld> ' /var/log/mail.log | wc -l"
  assert_success
  assert_output 1
}

@test "checking rspamd: existing rrd file" {
  run docker exec mailserver_default [ -f /var/mail/rspamd/rspamd.rrd ]
  assert_success
}

@test "checking rspamd: 7 messages scanned" {
  run docker exec mailserver_default /bin/sh -c "rspamc stat | grep -i 'Messages scanned: 7'"
  assert_success
}

@test "checking rspamd: 5 messages with action no action" {
  run docker exec mailserver_default /bin/sh -c "rspamc stat | grep -i 'Messages with action no action: 5'"
  assert_success
}

@test "checking rspamd: 2 messages with action reject" {
  run docker exec mailserver_default /bin/sh -c "rspamc stat | grep -i 'Messages with action reject: 2'"
  assert_success
}

@test "checking rspamd: 2 messages learned" {
  run docker exec mailserver_default /bin/sh -c "rspamc stat | grep -i 'Messages learned: 2'"
  assert_success
}

@test "checking rspamd: dkim/arc signing is disabled (reverse configuration)" {
  run docker exec mailserver_reverse cat /etc/rspamd/local.d/arc.conf
  assert_success
  assert_output "enabled = false;"
  run docker exec mailserver_reverse cat /etc/rspamd/local.d/dkim_signing.conf
  assert_success
  assert_output "enabled = false;"
}

@test "checking rspamd: greylisting policy is disabled (reverse configuration)" {
  run docker exec mailserver_reverse cat /etc/rspamd/local.d/greylisting.conf
  assert_success
  assert_output "enabled = false;"
}

@test "checking rspamd: ratelimiting policy is disabled (reverse configuration)" {
  run docker exec mailserver_reverse cat /etc/rspamd/local.d/ratelimit.conf
  assert_success
  assert_output "enabled = false;"
}

@test "checking rspamd: 3 modules disabled in ecdsa configuration" {
  run docker exec mailserver_ecdsa cat /etc/rspamd/local.d/rbl.conf
  assert_success
  assert_output "enabled = false;"
  run docker exec mailserver_ecdsa cat /etc/rspamd/local.d/mx_check.conf
  assert_success
  assert_output "enabled = false;"
  run docker exec mailserver_ecdsa cat /etc/rspamd/local.d/url_redirector.conf
  assert_success
  assert_output "enabled = false;"
}

#
# accounts
#

@test "checking accounts: user accounts" {
  run docker exec mailserver_default doveadm user '*'
  assert_success
  [ "${lines[0]}" = "john.doe@domain.tld" ]
  [ "${lines[1]}" = "sarah.connor@domain.tld" ]
}

@test "checking accounts: user quotas" {
  run docker exec mailserver_default /bin/bash -c "doveadm quota get -A 2>&1 | grep '1000' | wc -l"
  assert_success
  assert_output 2
}

@test "checking accounts: user mail folders for john.doe" {
  run docker exec mailserver_default /bin/bash -c "ls -A /var/mail/vhosts/domain.tld/john.doe/mail/ | grep -E 'cur|new|tmp' | wc -l"
  assert_success
  assert_output 3
}

@test "checking accounts: user mail folders for sarah.connor" {
  run docker exec mailserver_default /bin/bash -c "ls -A /var/mail/vhosts/domain.tld/sarah.connor/mail/ | grep -E '.Spam|cur|new|subscriptions|tmp' | wc -l"
  assert_success
  assert_output 5
}

#
# dkim
#

@test "checking dkim: all key pairs are generated (default configuration)" {
  run docker exec mailserver_default /bin/bash -c "ls -A /var/mail/dkim/*/{private.key,public.key} | wc -l"
  assert_success
  assert_output 6
}

@test "checking dkim: all key pairs are generated (reverse configuration)" {
  run docker exec mailserver_reverse /bin/bash -c "ls -A /var/mail/dkim/*/{private.key,public.key} | wc -l"
  assert_success
  assert_output 2
}

@test "checking dkim: control the size of the RSA key pair (4096bits)" {
  run docker exec mailserver_reverse /bin/bash -c "openssl rsa -in /var/mail/dkim/domain.tld/private.key -text -noout | grep -i 'Private-Key: (4096 bit)'"
  assert_success
}

#
# postfix
#

@test "checking postfix: mynetworks value (default configuration)" {
  run docker exec mailserver_default /bin/sh -c "postconf -h mynetworks"
  assert_success
  assert_output "127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128"
}

@test "checking postfix: mynetworks value (reverse configuration)" {
  run docker exec mailserver_reverse /bin/sh -c "postconf -h mynetworks"
  assert_success
  assert_output "127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128 192.168.0.0/16 172.16.0.0/12 10.0.0.0/8"
}

@test "checking postfix: main.cf overrides" {
  run docker exec mailserver_default /bin/sh -c "postconf -h max_idle"
  assert_success
  assert_output "600s"

  run docker exec mailserver_default /bin/sh -c "postconf -h readme_directory"
  assert_success
  assert_output "/tmp"
}

@test "checking postfix: headers cleanup" {
  run docker exec mailserver_default /bin/sh -c "grep -i 'replace: header Received' /var/log/mail.log | wc -l"
  assert_success
  assert_output 1
}

@test "checking postfix: myorigin value (docker method)" {
  run docker exec mailserver_default postconf -h myorigin
  assert_success
  assert_output "mail.domain.tld"
}

@test "checking postfix: myorigin value (env method)" {
  run docker exec mailserver_reverse postconf -h myorigin
  assert_success
  assert_output "mail.domain.tld"
}

@test "checking postfix: two milter rejects (GTUBE + EICAR)" {
  run docker exec mailserver_default /bin/sh -c "grep -i 'milter-reject' /var/log/mail.log | wc -l"
  assert_success
  assert_output 2
}

@test "checking postfix: milter-reject - clamav virus found" {
  run docker exec mailserver_default grep -i 'milter-reject.*clamav: virus found' /var/log/mail.log
  assert_success
}

@test "checking postfix: check 'etc' files in queue directory" {
  run docker exec mailserver_default [ -f /var/mail/postfix/spool/etc/services ]
  assert_success
  run docker exec mailserver_default [ -f /var/mail/postfix/spool/etc/hosts ]
  assert_success
  run docker exec mailserver_default [ -f /var/mail/postfix/spool/etc/localtime ]
  assert_success
}

@test "checking postfix: check some folders in queue directory" {
  run docker exec mailserver_default [ -d /var/mail/postfix/spool/usr/lib/sasl2 ]
  assert_success
  run docker exec mailserver_default [ -d /var/mail/postfix/spool/usr/lib/zoneinfo ]
  assert_success
}

@test "checking postfix: check dovecot unix sockets in queue directory" {
  run docker exec mailserver_default [ -S /var/mail/postfix/spool/private/dovecot-lmtp ]
  assert_success
  run docker exec mailserver_default [ -S /var/mail/postfix/spool/private/auth ]
  assert_success
}

@test "checking postfix: check group of 'public' and 'maildrop' folders in queue directory" {
  run docker exec mailserver_default /bin/sh -c "stat -c '%G' /var/mail/postfix/spool/public"
  assert_success
  assert_output "postdrop"
  run docker exec mailserver_default /bin/sh -c "stat -c '%G' /var/mail/postfix/spool/maildrop"
  assert_success
  assert_output "postdrop"
}

@test "checking postfix: smtp_tls_security_level value (default configuration)" {
  run docker exec mailserver_default postconf -h smtp_tls_security_level
  assert_success
  assert_output "dane"
}

@test "checking postfix: smtp_tls_security_level value (reverse configuration)" {
  run docker exec mailserver_reverse postconf -h smtp_tls_security_level
  assert_success
  assert_output "may"
}

@test "checking postfix: smtp_dns_support_level value (default configuration)" {
  run docker exec mailserver_default postconf -h smtp_dns_support_level
  assert_success
  assert_output "dnssec"
}

@test "checking postfix: smtp_dns_support_level value (reverse configuration)" {
  run docker exec mailserver_reverse postconf -h smtp_dns_support_level
  assert_success
  assert_output ""
}

#
# dovecot
#

@test "checking dovecot: existing ssl-parameters file" {
  run docker exec mailserver_default [ -f /var/mail/dovecot/ssl-parameters.dat ]
  assert_success
}

@test "checking dovecot: existing instances file" {
  run docker exec mailserver_default [ -f /var/mail/dovecot/instances ]
  assert_success
}

@test "checking dovecot: default lib directory is a symlink" {
  run docker exec mailserver_default [ -L /var/lib/dovecot ]
  assert_success
}

@test "checking dovecot: password scheme is correct" {
  run docker exec mailserver_default /bin/sh -c "grep 'SHA512-CRYPT' /etc/dovecot/dovecot-sql.conf.ext | wc -l"
  assert_success
  assert_output 1
}

@test "checking dovecot: piped ham message with sieve" {
  run docker exec mailserver_default /bin/sh -c "grep -i 'sieve: pipe action: piped message to program.*rspamd-pipe-ham.sh' /var/log/mail.log | wc -l"
  assert_success
  assert_output 1
}

@test "checking dovecot: piped spam message with sieve" {
  run docker exec mailserver_default /bin/sh -c "grep -i 'sieve: pipe action: piped message to program.*rspamd-pipe-spam.sh' /var/log/mail.log | wc -l"
  assert_success
  assert_output 1
}

@test "checking dovecot: custom sieve file is used" {
  run docker exec mailserver_reverse /bin/sh -c "wc -l < /var/mail/sieve/default.sieve"
  assert_success
  assert_output 4
}

@test "checking dovecot: login_greeting value (default configuration)" {
  run docker exec mailserver_default /bin/sh -c "doveconf -h login_greeting 2>/dev/null"
  assert_success
  assert_output "Do. Or do not. There is no try."
}

@test "checking dovecot: login_greeting value (reverse configuration)" {
  run docker exec mailserver_reverse /bin/sh -c "doveconf -h login_greeting 2>/dev/null"
  assert_success
  assert_output "Dovecot ready."
}

@test "checking dovecot: mail_max_userip_connections imap value" {
  run docker exec mailserver_default /bin/sh -c "doveconf -h -f protocol=imap mail_max_userip_connections 2>/dev/null"
  assert_success
  assert_output "100"
}

@test "checking dovecot: mail_max_userip_connections pop3 value" {
  run docker exec mailserver_default /bin/sh -c "doveconf -h -f protocol=pop3 mail_max_userip_connections 2>/dev/null"
  assert_success
  assert_output "50"
}

#
# clamav
#

@test "checking clamav: TCP Bound to 3310 port" {
  run docker exec mailserver_default grep -i 'TCP: Bound to \[0.0.0.0\]:3310' /var/log/mail.log
  assert_success
}

@test "checking clamav: all databases downloaded" {
  run docker exec mailserver_default /bin/sh -c "ls /var/lib/clamav | wc -l"
  assert_success
  assert_output 4
}

@test "checking clamav: self checking every 3600 seconds" {
  run docker exec mailserver_default grep -i 'clamd\[.*\]: Self checking every 3600 seconds' /var/log/mail.log
  assert_success
}

@test "checking clamav: mirrors.dat exist" {
  run docker exec mailserver_default [ -f /var/lib/clamav/mirrors.dat ]
  assert_success
}

@test "checking clamav: default lib directory is a symlink" {
  run docker exec mailserver_default [ -L /var/lib/clamav ]
  assert_success
}

@test "checking clamav: Eicar-Test-Signature FOUND" {
  run docker exec mailserver_default grep -i 'Eicar-Test-Signature(.*) FOUND' /var/log/mail.log
  assert_success
}

@test "checking clamav: 6 database mirrors" {
  run docker exec mailserver_default /bin/sh -c "grep 'DatabaseMirror' /etc/clamav/freshclam.conf | wc -l"
  assert_success
  assert_output 6
}

#
# zeyple
#

@test "checking zeyple: 4 messages delivered via zeyple service" {
  run docker exec mailserver_reverse /bin/sh -c "grep -i 'delivered via zeyple service' /var/log/mail.log | wc -l"
  assert_success
  assert_output 4
}

@test "checking zeyple: 'processing outgoing message' 4 times in logs" {
  run docker exec mailserver_reverse /bin/sh -c "grep -i 'Processing outgoing message' /var/log/zeyple.log | wc -l"
  assert_success
  assert_output 4
}

@test "checking zeyple: zeyple.py exist (reverse configuration)" {
  run docker exec mailserver_reverse [ -f /usr/local/bin/zeyple.py ]
  assert_success
}

@test "checking zeyple: zeyple.log exist (reverse configuration)" {
  run docker exec mailserver_reverse [ -f /var/log/zeyple.log ]
  assert_success
}

@test "checking zeyple: zeyple.log doesn't exist (default configuration)" {
  run docker exec mailserver_default [ -f /var/log/zeyple.log ]
  assert_failure
}

@test "checking zeyple: pubring.kbx exist (reverse configuration)" {
  run docker exec mailserver_reverse [ -f /var/mail/zeyple/keys/pubring.kbx ]
  assert_success
}

@test "checking zeyple: pubring.kbx doesn't exist (default configuration)" {
  run docker exec mailserver_default [ -f /var/mail/zeyple/keys/pubring.kbx ]
  assert_failure
}

@test "checking zeyple: trustdb.gpg exist (reverse configuration)" {
  run docker exec mailserver_reverse [ -f /var/mail/zeyple/keys/trustdb.gpg ]
  assert_success
}

@test "checking zeyple: trustdb.gpg doesn't exist (default configuration)" {
  run docker exec mailserver_default [ -f /var/mail/zeyple/keys/trustdb.gpg ]
  assert_failure
}

@test "checking zeyple: content_filter value (default configuration)" {
  run docker exec mailserver_default /bin/sh -c "postconf -h content_filter"
  assert_success
  assert_output ""
}

@test "checking zeyple: content_filter value (reverse configuration)" {
  run docker exec mailserver_reverse /bin/sh -c "postconf -h content_filter"
  assert_success
  assert_output "zeyple"
}

@test "checking zeyple: user zeyple doesn't exist (default configuration)" {
  run docker exec mailserver_default /bin/sh -c "id -u zeyple"
  assert_failure
}

@test "checking zeyple: user zeyple exist (reverse configuration)" {
  run docker exec mailserver_reverse /bin/sh -c "id -u zeyple"
  assert_success
}

@test "checking zeyple: retrieve john doe gpg key in public keyring" {
  run docker exec mailserver_reverse /bin/sh -c "s6-setuidgid zeyple gpg --homedir /var/mail/zeyple/keys --with-colons --list-keys | grep 'John Doe (test key) <john.doe@domain.tld>' | wc -l"
  assert_success
  assert_output 1
}

@test "checking zeyple: retrieve john doe gpg key in public keyring (using custom script)" {
  run docker exec mailserver_reverse /bin/sh -c "encryption.sh --with-colons --list-keys | grep 'John Doe (test key) <john.doe@domain.tld>' | wc -l"
  assert_success
  assert_output 1
}

@test "checking zeyple: 3 emails encrypted in john.doe folder" {
  run docker exec mailserver_reverse /bin/sh -c "grep -i 'multipart/encrypted' /var/mail/vhosts/domain.tld/john.doe/subdir/new/* | wc -l"
  assert_success
  assert_output 3
  run docker exec mailserver_reverse /bin/sh -c "grep -i 'BEGIN PGP MESSAGE' /var/mail/vhosts/domain.tld/john.doe/subdir/new/* | wc -l"
  assert_success
  assert_output 3
  run docker exec mailserver_reverse /bin/sh -c "grep -i 'END PGP MESSAGE' /var/mail/vhosts/domain.tld/john.doe/subdir/new/* | wc -l"
  assert_success
  assert_output 3
}

#
# unbound
#

@test "checking unbound: /etc/resolv.conf (default configuration)" {
  run docker exec mailserver_default cat /etc/resolv.conf
  assert_success
  assert_output "nameserver 127.0.0.1"
}

@test "checking unbound: /etc/resolv.conf (reverse configuration)" {
  run docker exec mailserver_reverse cat /etc/resolv.conf
  assert_success
  refute_output "nameserver 127.0.0.1"
}

@test "checking unbound: /var/mail/postfix/spool/etc/resolv.conf (default configuration)" {
  run docker exec mailserver_default cat /var/mail/postfix/spool/etc/resolv.conf
  assert_success
  assert_output "nameserver 127.0.0.1"
}

@test "checking unbound: /var/mail/postfix/spool/etc/resolv.conf (reverse configuration)" {
  run docker exec mailserver_reverse cat /var/mail/postfix/spool/etc/resolv.conf
  assert_success
  refute_output "nameserver 127.0.0.1"
}

@test "checking unbound: root.hints exist (default configuration)" {
  run docker exec mailserver_default [ -f /etc/unbound/root.hints ]
  assert_success
}

@test "checking unbound: root.hints doesn't exist (reverse configuration)" {
  run docker exec mailserver_reverse [ ! -f /etc/unbound/root.hints ]
  assert_success
}

@test "checking unbound: root.key exist (default configuration)" {
  run docker exec mailserver_default [ -f /etc/unbound/root.key ]
  assert_success
}

@test "checking unbound: root.key doesn't exist (reverse configuration)" {
  run docker exec mailserver_reverse [ ! -f /etc/unbound/root.key ]
  assert_success
}

@test "checking unbound: unbound_control.key exist" {
  run docker exec mailserver_default [ -f /etc/unbound/unbound_control.key ]
  assert_success
}

@test "checking unbound: unbound_control.pem exist" {
  run docker exec mailserver_default [ -f /etc/unbound/unbound_control.pem ]
  assert_success
}

@test "checking unbound: unbound_server.key exist" {
  run docker exec mailserver_default [ -f /etc/unbound/unbound_server.key ]
  assert_success
}

@test "checking unbound: unbound_server.pem exist" {
  run docker exec mailserver_default [ -f /etc/unbound/unbound_server.pem ]
  assert_success
}

@test "checking unbound: server is running and unbound-control works" {
  run docker exec -ti mailserver_default unbound-control status
  assert_success
  assert_output --partial 'is running'
}

@test "checking unbound: get stats" {
  run docker exec -ti mailserver_default unbound-control stats_noreset
  assert_success
}

@test "checking unbound: testing DNSSEC validation" {
  run docker exec mailserver_default /bin/sh -c "dig com. SOA +nocmd +noall +dnssec +comments | grep 'flags: qr rd ra ad' | wc -l"
  assert_success
  assert_output 1
}

#
# ssl
#

@test "checking ssl: ECDSA P-384 cert works correctly" {
  run docker exec mailserver_ecdsa /bin/sh -c "timeout 1 openssl s_client -ign_eof -connect 0.0.0.0:587 -starttls smtp | grep 'Verify return code: 18 (self signed certificate)'"
  assert_success
}

@test "checking ssl: generated default cert works correctly" {
  run docker exec mailserver_default /bin/sh -c "timeout 1 openssl s_client -ign_eof -connect 0.0.0.0:587 -starttls smtp | grep 'Verify return code: 18 (self signed certificate)'"
  assert_success
}

@test "checking ssl: let's encrypt cert works correctly" {
  run docker exec mailserver_reverse /bin/sh -c "timeout 1 openssl s_client -ign_eof -connect 0.0.0.0:587 -starttls smtp | grep 'Verify return code: 10 (certificate has expired)'"
  assert_success
}

@test "checking ssl: traefik cert works correctly" {
  run docker exec mailserver_traefik_acme /bin/sh -c "timeout 1 openssl s_client -ign_eof -connect 0.0.0.0:587 -starttls smtp | grep 'Verify return code: 21 (unable to verify the first certificate)'"
  assert_success
}

@test "checking ssl: default configuration is correct" {
  run docker exec mailserver_default /bin/sh -c "grep '/var/mail/ssl/selfsigned' /etc/postfix/main.cf | wc -l"
  assert_success
  assert_output 2
  run docker exec mailserver_default /bin/sh -c "grep '/var/mail/ssl/selfsigned' /etc/dovecot/conf.d/10-ssl.conf | wc -l"
  assert_success
  assert_output 2
}

@test "checking ssl: let's encrypt configuration is correct" {
  run docker exec mailserver_reverse /bin/sh -c "grep '/etc/letsencrypt/live/mail.domain.tld' /etc/postfix/main.cf | wc -l"
  assert_success
  assert_output 3
  run docker exec mailserver_reverse /bin/sh -c "grep '/etc/letsencrypt/live/mail.domain.tld' /etc/dovecot/conf.d/10-ssl.conf | wc -l"
  assert_success
  assert_output 2
}

#
# traefik acme
#

@test "checking traefik acme: acme.json exist" {
  run docker exec mailserver_traefik_acme [ -f /etc/letsencrypt/acme/acme.json ]
  assert_success
}

@test "checking traefik acme: dump.log doesn't exist" {
  run docker exec mailserver_traefik_acme [ -f /etc/letsencrypt/acme/dump.log ]
  assert_failure
}

@test "checking traefik acme: all certificates were generated" {
  run docker exec mailserver_traefik_acme [ -f /etc/letsencrypt/live/mail.domain.tld/cert.pem ]
  assert_success
  run docker exec mailserver_traefik_acme [ -f /etc/letsencrypt/live/mail.domain.tld/chain.pem ]
  assert_success
  run docker exec mailserver_traefik_acme [ -f /etc/letsencrypt/live/mail.domain.tld/fullchain.pem ]
  assert_success
  run docker exec mailserver_traefik_acme [ -f /etc/letsencrypt/live/mail.domain.tld/privkey.pem ]
  assert_success
}

@test "checking traefik acme: check private key" {
  run docker exec mailserver_traefik_acme /bin/sh -c "openssl rsa -in /etc/letsencrypt/live/mail.domain.tld/privkey.pem -check 2>/dev/null | head -n 1"
  assert_success
  assert_output "RSA key ok"
}

@test "checking traefik acme: private key matches the certificate" {
  run docker exec mailserver_traefik_acme /bin/sh -c "(openssl x509 -noout -modulus -in /etc/letsencrypt/live/mail.domain.tld/cert.pem | openssl md5 ; openssl rsa -noout -modulus -in /etc/letsencrypt/live/mail.domain.tld/privkey.pem | openssl md5) | uniq | wc -l"
  assert_success
  assert_output 1
}

#
# index files
#

@test "checking hash tables: existing header_checks and virtual index files" {
  run docker exec mailserver_default [ -f /etc/postfix/header_checks.db ]
  assert_success
  run docker exec mailserver_default [ -f /etc/postfix/virtual.db ]
  assert_success
}

#
# logs
#

@test "checking logs: /var/log/mail.log in mailserver_default is error free" {
  run docker exec mailserver_default grep -i ': error:' /var/log/mail.log
  assert_failure
  run docker exec mailserver_default grep -i 'is not writable' /var/log/mail.log
  assert_failure
  run docker exec mailserver_default grep -i 'permission denied' /var/log/mail.log
  assert_failure
}

@test "checking logs: /var/log/mail.log in mailserver_reverse is error free " {
  run docker exec mailserver_reverse grep -i ': error:' /var/log/mail.log
  assert_failure
  run docker exec mailserver_reverse grep -i 'is not writable' /var/log/mail.log
  assert_failure
  run docker exec mailserver_reverse grep -i 'permission denied' /var/log/mail.log
  assert_failure
}

@test "checking logs: /var/log/mail.err in mailserver_default does not exist" {
  run docker exec mailserver_default cat /var/log/mail.err
  assert_failure
  assert_output --partial 'No such file or directory'
}

@test "checking logs: /var/log/mail.err in mailserver_reverse does not exist" {
  run docker exec mailserver_reverse cat /var/log/mail.err
  assert_failure
  assert_output --partial 'No such file or directory'
}
