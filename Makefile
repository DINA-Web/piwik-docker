#! make

PWD = $(shell pwd)
TS = $(shell date +%Y%d%mT%H%M)

all: up

up:
	@docker-compose up -d

discover-services:
	@curl -s http://dnsdock.docker/services | json_pp

ssl-certs:
	@echo "Generating SSL certs using https://hub.docker.com/r/paulczar/omgwtfssl/"
	@mkdir -p certs
	docker run -v /tmp/certs:/certs \
		-e SSL_SUBJECT=piwik.docker \
		-e SSL_DNS=piwik.docker,www.piwik.docker,welcome.docker \
	paulczar/omgwtfssl
	cp -r /tmp/certs .
	cp certs/cert.pem certs/piwik.docker.crt
	cp certs/key.pem certs/piwik.docker.key
	cp certs/cert.pem certs/shared.crt
	cp certs/key.pem certs/shared.key

	@echo "Using self-signed certificates will require either the CA cert to be imported system-wide or into apps"
	@echo "if you don't do this, apps will fail to request data using SSL (https)"
	@echo "WARNING! You now need to import the ./certs/ca.pem file into Firefox/Chrome etc"
	@echo "WARNING! For curl to work, you need to provide '--cacert ./certs/ca.pem' switch or SSL requests will fail."

ssl-certs-clean:
	rm -rf certs
	rm -f /tmp/certs

ssl-certs-show:
	#openssl x509 -in certs/dina-web.net.crt -text
	openssl x509 -noout -text -in certs/cert.pem


down:
	@docker-compose down

clean: down
	rm -rf srv

blaha:
	echo $(date +%Y%d%mT%H%M)

backup-piwik:
	docker run -it --net piwikdocker_default --link piwikdocker_piwikdb_1:mysql --rm mysql \
		bash -c 'mysqldump --skip-lock-tables --single-transaction --databases piwik --events --protocol=tcp -h mysql -u root -ppassw0rd12' | gzip --best > piwik_$(TS).sql.gz

#	docker-compose run piwikdb bash -c 'mysqldump --skip-lock-tables --single-transaction --all-databases --events -h 127.0.0.1 -u root -ppassw0rd12' | gzip --best > piwik_$(TS).sql.gz

debug:
	docker-compose run cli

debug1:
	docker run -it --net piwikdocker_default --link piwikdocker_piwikdb_1:mysql --rm mysql \
	sh -c 'exec mysql -h mysql -u root -p'

test:
	curl --cacert ./certs/ca.pem https://piwik.docker


