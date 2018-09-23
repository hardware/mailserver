NAME = hardware/mailserver:testing

all: build-no-cache init fixtures run clean
all-fast: build init fixtures run clean
no-build: init fixtures run clean

build-no-cache:
	docker build --no-cache -t $(NAME) .

build:
	docker build -t $(NAME) .

init:
	-docker rm -f \
		mariadb postgres redis \
		mailserver_default mailserver_reverse mailserver_ecdsa \
		mailserver_traefik_acmev1 mailserver_traefik_acmev2

	sleep 2

	docker run \
		-d \
		--name mariadb \
		-e MYSQL_RANDOM_ROOT_PASSWORD=yes \
		-e MYSQL_DATABASE=postfix \
		-e MYSQL_USER=postfix \
		-e MYSQL_PASSWORD=testpasswd \
		-v "`pwd`/test/config/mariadb":/docker-entrypoint-initdb.d \
		-t mariadb:10.2

	docker run \
		-d \
		--name postgres \
		-e POSTGRES_DB=postfix \
		-e POSTGRES_USER=postfix \
		-e POSTGRES_PASSWORD=testpasswd \
		-v "`pwd`/test/config/postgres":/docker-entrypoint-initdb.d \
		-t postgres:10.5-alpine

	docker run \
		-d \
		--name redis \
		-t redis:4.0-alpine

	sleep 10

	docker run \
		-d \
		--name mailserver_default \
		--link mariadb:mariadb \
		--link redis:redis \
		-e DBPASS=testpasswd \
		-e RSPAMD_PASSWORD=testpasswd \
		-e VMAILUID=`id -u` \
		-e VMAILGID=`id -g` \
		-e ADD_DOMAINS=domain2.tld,domain3.tld \
		-e RECIPIENT_DELIMITER=: \
		-e TESTING=true \
		-v "`pwd`/test/share/tests":/tmp/tests \
		-v "`pwd`/test/share/ssl/rsa":/var/mail/ssl \
		-v "`pwd`/test/share/postfix/custom.conf":/var/mail/postfix/custom.conf \
		-v "`pwd`/test/share/postfix/sender_access":/var/mail/postfix/sender_access \
		-v "`pwd`/test/share/dovecot/conf.d":/var/mail/dovecot/conf.d \
		-v "`pwd`/test/share/clamav/unofficial-sigs/user.conf":/var/mail/clamav-unofficial-sigs/user.conf \
		-h mail.domain.tld \
		-t $(NAME)

	docker run \
		-d \
		--name mailserver_reverse \
		--link postgres:postgres \
		--link redis:redis \
		-e FQDN=mail.domain.tld \
		-e DOMAIN=domain.tld \
		-e DBDRIVER=pgsql \
		-e DBHOST=postgres \
		-e DBPORT=5432 \
		-e DBPASS=/tmp/passwd/postgres \
		-e REDIS_HOST=redis \
		-e REDIS_PORT=6379 \
		-e REDIS_PASS=/tmp/passwd/redis \
		-e RSPAMD_PASSWORD=/tmp/passwd/rspamd \
		-e VMAILUID=`id -u` \
		-e VMAILGID=`id -g` \
		-e VMAIL_SUBDIR=subdir \
		-e RELAY_NETWORKS="192.168.0.0/16 172.16.0.0/12 10.0.0.0/8" \
		-e DISABLE_CLAMAV=true \
		-e DISABLE_SIEVE=true \
		-e DISABLE_SIGNING=true \
		-e DISABLE_GREYLISTING=true \
		-e DISABLE_RATELIMITING=true \
		-e DISABLE_DNS_RESOLVER=true \
		-e ENABLE_POP3=true \
		-e ENABLE_ENCRYPTION=true \
		-e ENABLE_FETCHMAIL=true \
		-e OPENDKIM_KEY_LENGTH=4096 \
		-e TESTING=true \
		-v "`pwd`/test/share/tests":/tmp/tests \
		-v "`pwd`/test/share/passwd":/tmp/passwd \
		-v "`pwd`/test/share/ssl/rsa":/var/mail/ssl \
		-v "`pwd`/test/share/sieve/custom.sieve":/var/mail/sieve/custom.sieve \
		-v "`pwd`/test/share/letsencrypt":/etc/letsencrypt \
		-t $(NAME)

	docker run \
		-d \
		--name mailserver_ecdsa \
		--link mariadb:mariadb \
		--link redis:redis \
		-e DBPASS=testpasswd \
		-e RSPAMD_PASSWORD=testpasswd \
		-e VMAILUID=`id -u` \
		-e VMAILGID=`id -g` \
		-e DISABLE_CLAMAV=true \
		-e DISABLE_RSPAMD_MODULE=rbl,mx_check,url_redirector \
		-e WHITELIST_SPAM_ADDRESSES=test@example.com,another@domain.tld \
		-e TESTING=true \
		-v "`pwd`/test/share/ssl/ecdsa":/var/mail/ssl \
		-v "`pwd`/test/share/postfix/custom.ecdsa.conf":/var/mail/postfix/custom.conf \
		-h mail.domain.tld \
		-t $(NAME)

	docker run \
		-d \
		--name mailserver_traefik_acmev1 \
		--link mariadb:mariadb \
		--link redis:redis \
		-e DEBUG_MODE=dovecot,postfix \
		-e DBPASS=testpasswd \
		-e RSPAMD_PASSWORD=testpasswd \
		-e VMAILUID=`id -u` \
		-e VMAILGID=`id -g` \
		-e DISABLE_CLAMAV=true \
		-e TESTING=true \
		-v "`pwd`/test/share/traefik/acme.v1.json":/etc/letsencrypt/acme/acme.json \
		-h mail.domain.tld \
		-t $(NAME)

	docker run \
		-d \
		--name mailserver_traefik_acmev2 \
		--link mariadb:mariadb \
		--link redis:redis \
		-e DEBUG_MODE=true \
		-e DBPASS=testpasswd \
		-e RSPAMD_PASSWORD=testpasswd \
		-e VMAILUID=`id -u` \
		-e VMAILGID=`id -g` \
		-e DISABLE_CLAMAV=true \
		-e TESTING=true \
		-v "`pwd`/test/share/traefik/acme.v2.json":/etc/letsencrypt/acme/acme.json \
		-h mail.domain.tld \
		-t $(NAME)

	docker exec mailserver_default /bin/sh -c "apt-get update && apt-get install -y -q netcat"
	docker exec mailserver_reverse /bin/sh -c "apt-get update && apt-get install -y -q netcat"

fixtures:

	# Wait for clamav unofficial sigs database update
	docker exec mailserver_default /bin/sh -c "while [ -f /var/lib/clamav-unofficial-sigs/pid/clamav-unofficial-sigs.pid ] ; do sleep 1 ; done"
	# Wait for clamav load databases
	docker exec mailserver_default /bin/sh -c "while ! echo PING | nc -z 0.0.0.0 3310 ; do sleep 1 ; done"

	docker exec mailserver_default /bin/sh -c "nc 0.0.0.0 25 < /tmp/tests/email-templates/external-to-existing-user.txt"
	docker exec mailserver_default /bin/sh -c "nc 0.0.0.0 25 < /tmp/tests/email-templates/external-to-existing-user-spam-learning.txt"
	docker exec mailserver_default /bin/sh -c "nc 0.0.0.0 25 < /tmp/tests/email-templates/external-to-valid-user-subaddress.txt"
	docker exec mailserver_default /bin/sh -c "nc 0.0.0.0 25 < /tmp/tests/email-templates/external-to-non-existing-user.txt"
	docker exec mailserver_default /bin/sh -c "nc 0.0.0.0 25 < /tmp/tests/email-templates/external-to-existing-alias.txt"
	docker exec mailserver_default /bin/sh -c "nc 0.0.0.0 25 < /tmp/tests/email-templates/external-spam-to-existing-user.txt"
	docker exec mailserver_default /bin/sh -c "nc 0.0.0.0 25 < /tmp/tests/email-templates/external-virus-to-existing-user.txt"
	docker exec mailserver_default /bin/sh -c "openssl s_client -ign_eof -connect 0.0.0.0:587 -starttls smtp < /tmp/tests/email-templates/internal-user-to-existing-user.txt"
	docker exec mailserver_default /bin/sh -c "openssl s_client -ign_eof -connect 0.0.0.0:587 -starttls smtp < /tmp/tests/email-templates/internal-rejected-user-to-existing-user.txt"
	sleep 2
	docker exec mailserver_default /bin/sh -c "openssl s_client -ign_eof -connect 0.0.0.0:993 < /tmp/tests/sieve/trigger-spam-ham-learning.txt"

	docker exec mailserver_reverse /bin/sh -c "nc 0.0.0.0 25 < /tmp/tests/email-templates/external-to-existing-user.txt"
	docker exec mailserver_reverse /bin/sh -c "nc 0.0.0.0 25 < /tmp/tests/email-templates/external-to-valid-user-subaddress-with-default-separator.txt"
	docker exec mailserver_reverse /bin/sh -c "nc 0.0.0.0 25 < /tmp/tests/email-templates/external-to-non-existing-user.txt"
	docker exec mailserver_reverse /bin/sh -c "nc 0.0.0.0 25 < /tmp/tests/email-templates/external-to-existing-alias.txt"
	docker exec mailserver_reverse /bin/sh -c "nc 0.0.0.0 25 < /tmp/tests/email-templates/external-spam-to-existing-user.txt"
	docker exec mailserver_reverse /bin/sh -c "openssl s_client -ign_eof -connect 0.0.0.0:587 -starttls smtp < /tmp/tests/email-templates/internal-user-to-existing-user.txt"

	# Wait until all mails have been processed
	sleep 10

run:
	./test/bats/bin/bats test/tests.bats

clean:
	docker images --quiet --filter=dangling=true | xargs --no-run-if-empty docker rmi
	docker volume ls -qf dangling=true | xargs -r docker volume rm
