NAME = hardware/mailserver:testing

all: build-no-cache init fixtures run
all-fast: build init fixtures run
no-build: init fixtures run

build-no-cache:
	docker build --no-cache -t $(NAME) .

build:
	docker build -t $(NAME) .

init:
	-docker rm -f mariadb redis mailserver_default mailserver_reverse
	sleep 2

	docker run \
		-d \
		--name mariadb \
		-e MYSQL_ROOT_PASSWORD=testpasswd \
		-e MYSQL_DATABASE=postfix \
		-e MYSQL_USER=postfix \
		-e MYSQL_PASSWORD=testpasswd \
		-v "`pwd`/test/config/mariadb":/docker-entrypoint-initdb.d \
		-t mariadb:10.1

	docker run \
		-d \
		--name redis \
		-t redis:3.2-alpine

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
		-e DISABLE_CLAMAV=true \
		-e ADD_DOMAINS=domain2.tld,domain3.tld \
		-e TESTING=true \
		-v "`pwd`/test/share/tests":/tmp/tests \
		-v "`pwd`/test/share/ssl":/var/mail/ssl \
		-v "`pwd`/test/share/postfix":/var/mail/postfix \
		-h mail.domain.tld \
		-t $(NAME)

	docker run \
		-d \
		--name mailserver_reverse \
		--link mariadb:mariadb \
		--link redis:redis \
		-e FQDN=mail.domain.tld \
		-e DOMAIN=domain.tld \
		-e DBPASS=testpasswd \
		-e REDIS_HOST=redis \
		-e REDIS_PORT=6379 \
		-e RSPAMD_PASSWORD=testpasswd \
		-e VMAILUID=`id -u` \
		-e VMAILGID=`id -g` \
		-e VMAIL_SUBDIR=subdir \
		-e RECIPIENT_DELIMITER=: \
		-e RELAY_NETWORKS="192.168.0.0/16 172.16.0.0/12 10.0.0.0/8" \
		-e DISABLE_CLAMAV=true \
		-e DISABLE_SIEVE=true \
		-e DISABLE_SIGNING=true \
		-e DISABLE_GREYLISTING=true \
		-e DISABLE_RATELIMITING=true \
		-e ENABLE_POP3=true \
		-e OPENDKIM_KEY_LENGTH=4096 \
		-e TESTING=true \
		-v "`pwd`/test/share/tests":/tmp/tests \
		-v "`pwd`/test/share/ssl":/var/mail/ssl \
		-v "`pwd`/test/share/letsencrypt":/etc/letsencrypt \
		-t $(NAME)

	docker exec mailserver_default /bin/sh -c "apt-get update && apt-get install -y -q netcat"
	docker exec mailserver_reverse /bin/sh -c "apt-get update && apt-get install -y -q netcat"

fixtures:
	docker exec mailserver_default /bin/sh -c "nc 0.0.0.0 25 < /tmp/tests/email-templates/external-to-existing-user.txt"
	docker exec mailserver_default /bin/sh -c "nc 0.0.0.0 25 < /tmp/tests/email-templates/external-to-valid-user-subaddress-with-default-separator.txt"
	docker exec mailserver_default /bin/sh -c "nc 0.0.0.0 25 < /tmp/tests/email-templates/external-to-non-existing-user.txt"
	docker exec mailserver_default /bin/sh -c "nc 0.0.0.0 25 < /tmp/tests/email-templates/external-to-existing-alias.txt"
	docker exec mailserver_default /bin/sh -c "nc 0.0.0.0 25 < /tmp/tests/email-templates/external-spam-to-existing-user.txt"
	docker exec mailserver_default /bin/sh -c "openssl s_client -ign_eof -connect 0.0.0.0:587 -starttls smtp < /tmp/tests/email-templates/internal-user-to-existing-user.txt"

	docker exec mailserver_reverse /bin/sh -c "nc 0.0.0.0 25 < /tmp/tests/email-templates/external-to-existing-user.txt"
	docker exec mailserver_reverse /bin/sh -c "nc 0.0.0.0 25 < /tmp/tests/email-templates/external-to-valid-user-subaddress.txt"
	docker exec mailserver_reverse /bin/sh -c "nc 0.0.0.0 25 < /tmp/tests/email-templates/external-to-non-existing-user.txt"
	docker exec mailserver_reverse /bin/sh -c "nc 0.0.0.0 25 < /tmp/tests/email-templates/external-to-existing-alias.txt"
	docker exec mailserver_reverse /bin/sh -c "nc 0.0.0.0 25 < /tmp/tests/email-templates/external-spam-to-existing-user.txt"
	docker exec mailserver_reverse /bin/sh -c "openssl s_client -ign_eof -connect 0.0.0.0:587 -starttls smtp < /tmp/tests/email-templates/internal-user-to-existing-user.txt"
	sleep 10

run:
	./test/bin/bats test/tests.bats
