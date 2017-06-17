#
# system
#

@test "checking system: /etc/mailname (docker method)" {
  run docker exec mailserver_default cat /etc/mailname
  [ "$status" -eq 0 ]
  [ "$output" = "mail.domain.tld" ]
}

@test "checking system: /etc/mailname (env method)" {
  run docker exec mailserver_with_gross cat /etc/mailname
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

@test "checking system: all environment variables have been replaced" {
  run docker exec mailserver_default /bin/bash -c "egrep -R "{{.*}}" /etc/postfix /etc/postfixadmin/fetchmail.conf /etc/dovecot /etc/opendkim /etc/opendmarc /etc/amavis /etc/mailname /usr/local/bin/quota-warning"
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
  run docker exec mailserver_default /bin/bash -c "ps aux --forest | grep '[/]usr/lib/postfix/sbin/master -w'"
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

@test "checking process: gross (disabled in default configuration)" {
  run docker exec mailserver_default /bin/bash -c "ps aux --forest | grep '[/]usr/sbin/grossd -f /etc/gross/grossd.conf -d'"
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

# @test "checking process: clamd (enable in default configuration)" {
#   run docker exec mailserver_default /bin/bash -c "ps aux --forest | grep '[/]usr/sbin/clamd --foreground=true -c /etc/clamav/clamd.conf'"
#   [ "$status" -eq 0 ]
# }

# @test "checking process: freshclam (enable in default configuration)" {
#   run docker exec mailserver_default /bin/bash -c "ps aux --forest | grep '[/]usr/bin/freshclam -d --config-file=/etc/clamav/freshclam.conf'"
#   [ "$status" -eq 0 ]
# }

#
# processes (reverse configuration)
#

@test "checking process: postgrey (enable in reverse configuration)" {
  run docker exec mailserver_reverse /bin/bash -c "ps aux --forest | grep '[p]ostgrey --delay=120 --inet=127.0.0.1:10023 --dbdir=/var/mail/postgrey'"
  [ "$status" -eq 0 ]
}

@test "checking process: gross (disabled in reverse configuration)" {
  run docker exec mailserver_reverse /bin/bash -c "ps aux --forest | grep '[/]usr/sbin/grossd -f /etc/gross/grossd.conf -d'"
  [ "$status" -eq 1 ]
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

# @test "checking process: clamd (disabled in reverse configuration)" {
#   run docker exec mailserver_reverse /bin/bash -c "ps aux --forest | grep '[/]usr/sbin/clamd --foreground=true -c /etc/clamav/clamd.conf'"
#   [ "$status" -eq 1 ]
# }

# @test "checking process: freshclam (disabled in reverse configuration)" {
#   run docker exec mailserver_reverse /bin/bash -c "ps aux --forest | grep '[/]usr/bin/freshclam -d --config-file=/etc/clamav/freshclam.conf'"
#   [ "$status" -eq 1 ]
# }

#
# processes (gross configuration)
#

@test "checking process: postgrey (disabled in gross configuration)" {
  run docker exec mailserver_with_gross /bin/bash -c "ps aux --forest | grep '[p]ostgrey --delay=120 --inet=127.0.0.1:10023 --dbdir=/var/mail/postgrey'"
  [ "$status" -eq 1 ]
}

@test "checking process: gross (enabled in gross configuration)" {
  run docker exec mailserver_with_gross /bin/bash -c "ps aux --forest | grep '[/]usr/sbin/grossd -f /etc/gross/grossd.conf -d'"
  [ "$status" -eq 0 ]
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

@test "checking port  (4190): external port listening (default configuration)" {
  run docker exec mailserver_default /bin/sh -c "nc -z 0.0.0.0 4190"
  [ "$status" -eq 0 ]
}

@test "checking port  (4190): external port closed    (reverse configuration)" {
  run docker exec mailserver_reverse /bin/sh -c "nc -z 0.0.0.0 4190"
  [ "$status" -eq 1 ]
}

@test "checking port  (8891): internal port listening (default configuration)" {
  run docker exec mailserver_default /bin/sh -c "nc -z 127.0.0.1 8891"
  [ "$status" -eq 0 ]
}

@test "checking port  (8891): internal port listening (reverse configuration)" {
  run docker exec mailserver_reverse /bin/sh -c "nc -z 127.0.0.1 8891"
  [ "$status" -eq 0 ]
}

@test "checking port  (8893): internal port listening (default configuration)" {
  run docker exec mailserver_default /bin/sh -c "nc -z 127.0.0.1 8893"
  [ "$status" -eq 0 ]
}

@test "checking port  (8893): internal port listening (reverse configuration)" {
  run docker exec mailserver_reverse /bin/sh -c "nc -z 127.0.0.1 8893"
  [ "$status" -eq 0 ]
}

@test "checking port (10023): internal port closed    (default configuration)" {
  run docker exec mailserver_default /bin/sh -c "nc -z 127.0.0.1 10023"
  [ "$status" -eq 1 ]
}

@test "checking port (10023): internal port listening (reverse configuration)" {
  run docker exec mailserver_reverse /bin/sh -c "nc -z 127.0.0.1 10023"
  [ "$status" -eq 0 ]
}

@test "checking port (10023): internal port listening (gross configuration)" {
  run docker exec mailserver_with_gross /bin/sh -c "nc -z 127.0.0.1 10023"
  [ "$status" -eq 0 ]
}

@test "checking port (10024): internal port listening (default configuration)" {
  run docker exec mailserver_default /bin/sh -c "nc -z 127.0.0.1 10024"
  [ "$status" -eq 0 ]
}

@test "checking port (10024): internal port closed    (reverse configuration)" {
  run docker exec mailserver_reverse /bin/sh -c "nc -z 127.0.0.1 10024"
  [ "$status" -eq 1 ]
}

@test "checking port (10025): internal port listening (default configuration)" {
  run docker exec mailserver_default /bin/sh -c "nc -z 127.0.0.1 10025"
  [ "$status" -eq 0 ]
}

@test "checking port (10025): internal port listening (reverse configuration)" {
  run docker exec mailserver_reverse /bin/sh -c "nc -z 127.0.0.1 10025"
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

@test "checking smtp: sarah.connor should have received 3 mails (external + subaddress + hostmaster alias via fetchmail)" {
  run docker exec mailserver_default /bin/sh -c "ls -A /var/mail/vhosts/domain.tld/sarah.connor/mail/new/ | wc -l"
  [ "$status" -eq 0 ]
  [ "$output" = 3 ]
}

@test "checking smtp: john.doe should have received 1 spam (external mail stored in Spam folder by Sieve)" {
  run docker exec mailserver_default /bin/sh -c "ls -A /var/mail/vhosts/domain.tld/john.doe/mail/.Spam/new/ | wc -l"
  [ "$status" -eq 0 ]
  [ "$output" = 1 ]
}

@test "checking smtp: rejects mail to unknown user" {
  run docker exec mailserver_default /bin/sh -c "grep '<ghost@domain.tld>: Recipient address rejected: User unknown in virtual mailbox table' /var/log/mail.log | wc -l"
  [ "$status" -eq 0 ]
  [ "$output" = 1 ]
}

@test "checking smtp: delivers mail to existing alias" {
  run docker exec mailserver_default /bin/sh -c "grep 'to=<john.doe@domain.tld>, orig_to=<hostmaster@domain.tld>' /var/log/mail.log | grep 'status=sent' | wc -l"
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

@test "checking amavis: spam filtered" {
  run docker exec mailserver_default /bin/sh -c "grep -i 'Passed SPAM' /var/log/mail.log | grep spam@example.com | wc -l"
  [ "$status" -eq 0 ]
  [ "$output" = 1 ]
  run docker exec mailserver_default /bin/sh -c "find /var/lib/amavis/virusmails -type f | wc -l"
  [ "$status" -eq 0 ]
  [ "$output" = 1 ]
}

@test "checking amavis: no unchecked mail" {
  run docker exec mailserver_default /bin/sh -c "grep -i 'Passed UNCHECKED' /var/log/mail.log"
  [ "$status" -eq 1 ]
}

# @test "checking amavis: virus rejected" {
#   run docker exec mailserver_default /bin/sh -c "grep -i 'Blocked INFECTED' /var/log/mail.log | grep virus@example.com | wc -l"
#   [ "$status" -eq 0 ]
#   [ "$output" = 1 ]
# }

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

@test "checking postfix: main.cf overrides" {
  run docker exec mailserver_default /bin/sh -c "postconf -h max_idle"
  [ "$status" -eq 0 ]
  [ "$output" = "600s" ]

  run docker exec mailserver_default /bin/sh -c "postconf -h readme_directory"
  [ "$status" -eq 0 ]
  [ "$output" = "/tmp" ]
}

@test "checking postfix: headers cleanup" {
  run docker exec mailserver_default /bin/sh -c "grep 'replace: header Received' /var/log/mail.log | wc -l"
  [ "$status" -eq 0 ]
  [ "$output" -eq 1 ]
}

@test "checking postfix: myorigin value (docker method)" {
  run docker exec mailserver_default postconf -h myorigin
  [ "$status" -eq 0 ]
  [ "$output" = "mail.domain.tld" ]
}

@test "checking postfix: myorigin value (env method)" {
  run docker exec mailserver_with_gross postconf -h myorigin
  [ "$status" -eq 0 ]
  [ "$output" = "mail.domain.tld" ]
}

#
# fetchmail
#

@test "checking fetchmail: retrieve settings from fetchmail table" {
  run docker exec mailserver_default /bin/sh -c "grep -i 'fetch john.doe@domain.tld for sarah.connor@domain.tld' /var/log/mail.log | wc -l"
  [ "$status" -eq 0 ]
  [ "$output" = 1 ]
}

@test "checking fetchmail: 4 messages in john.doe@domain.tld inbox" {
  run docker exec mailserver_default /bin/sh -c "grep -i '4 messages for john.doe@domain.tld' /var/log/mail.log | wc -l"
  [ "$status" -eq 0 ]
  [ "$output" = 1 ]
}

@test "checking fetchmail: john.doe should now have 0 mail" {
  run docker exec mailserver_default /bin/sh -c "ls -A /var/mail/vhosts/domain.tld/john.doe/mail/new/ | wc -l"
  [ "$status" -eq 0 ]
  [ "$output" = 0 ]
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

@test "checking logs: /var/log/mail.err in mailserver_default have fetchmail certificate warnings and login_mismatch error, nothing else" {
  run docker exec mailserver_default /bin/sh -c "cat /var/log/mail.err | wc -l"
  [ "$status" -eq 0 ]
  [ "$output" -eq 4 ]
}

@test "checking logs: /var/log/mail.err in mailserver_reverse does not exist" {
  run docker exec mailserver_reverse [ -f /var/log/mail.err ]
  [ "$status" -eq 1 ]
}
