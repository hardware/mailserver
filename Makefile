NAME = hardware/mailserver:testing

all: build-no-cache init fixtures run clean
all-fast: build init fixtures run clean
no-build: init fixtures run clean

build-no-cache:
	docker build --no-cache -t $(NAME) .

build:
	docker build -t $(NAME) .

init:
	docker run \
		-d \
		--name mariadb \
		-e MYSQL_ROOT_PASSWORD=testpasswd \
		-e MYSQL_DATABASE=postfix \
		-e MYSQL_USER=postfix \
		-e MYSQL_PASSWORD=testpasswd \
		-v "`pwd`/test/config/mariadb":/docker-entrypoint-initdb.d \
		-t mariadb:10.1

	# Wait until the db fully set up
	sleep 10

	docker run \
		-d \
		--name mailserver_default \
		--link mariadb:mariadb \
		-e DBPASS=testpasswd \
		-e VMAILUID=`id -u` \
		-e VMAILGID=`id -g` \
		-e DISABLE_CLAMAV=true \
		-e ADD_DOMAINS=domain2.tld,domain3.tld \
		-e RECIPIENT_DELIMITER=: \
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
		-e DBPASS=testpasswd \
		-e VMAILUID=`id -u` \
		-e VMAILGID=`id -g` \
		-e DISABLE_CLAMAV=true \
		-e DISABLE_SPAMASSASSIN=true \
		-e DISABLE_SIEVE=true \
		-e ENABLE_POSTGREY=true \
		-e ENABLE_POP3=true \
		-e OPENDKIM_KEY_LENGTH=4096 \
		-e TESTING=true \
		-v "`pwd`/test/share/tests":/tmp/tests \
		-v "`pwd`/test/share/ssl":/var/mail/ssl \
		-v "`pwd`/test/share/letsencrypt":/etc/letsencrypt \
		-h mail.domain.tld \
		-t $(NAME)

	docker exec mailserver_default /bin/sh -c "apt-get update && apt-get install -y -q netcat"
	docker exec mailserver_reverse /bin/sh -c "apt-get update && apt-get install -y -q netcat"

fixtures:
	docker exec mailserver_default /bin/sh -c "nc 0.0.0.0 25 < /tmp/tests/email-templates/external-to-existing-user.txt"
	docker exec mailserver_default /bin/sh -c "nc 0.0.0.0 25 < /tmp/tests/email-templates/external-to-valid-user-subaddress.txt"
	docker exec mailserver_default /bin/sh -c "nc 0.0.0.0 25 < /tmp/tests/email-templates/external-to-non-existing-user.txt"
	docker exec mailserver_default /bin/sh -c "nc 0.0.0.0 25 < /tmp/tests/email-templates/external-to-existing-alias.txt"
	docker exec mailserver_default /bin/sh -c "nc 0.0.0.0 25 < /tmp/tests/email-templates/external-spam-to-existing-user.txt"
	docker exec mailserver_default /bin/sh -c "openssl s_client -ign_eof -connect 0.0.0.0:587 -starttls smtp < /tmp/tests/email-templates/internal-user-to-existing-user.txt"
	sleep 10
	docker exec mailserver_default /bin/sh -c "/usr/bin/perl /usr/local/bin/fetchmail.pl"
	sleep 10

	# docker exec mailserver_default /bin/sh -c "nc 0.0.0.0 25 < /tmp/tests/email-templates/external-to-existing-system-account.txt"
	# docker exec mailserver_default /bin/sh -c "nc 0.0.0.0 25 < /tmp/tests/email-templates/external-virus-to-existing-user.txt"

run:
	./test/bin/bats test/tests.bats

clean:
	docker rm -f mariadb mailserver_default mailserver_reverse
