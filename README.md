# "Piwik Docker Edition"

[![AGPLv3 License](http://img.shields.io/badge/license-AGPLv3-blue.svg) ](https://github.com/DINA-Web/piwik-docker/blob/master/LICENSE)

# Requirements

The installation requires a docker host under your control, ie a machine with the `docker` daemon running, see https://docs.docker.com/engine/installation/

You also need to install `docker-compose`, see https://docs.docker.com/compose/install/ and `make` and `git`.

# Usage

If you plan to start the system using a database dump from an old piwik instance, say from version 2.12.1-0, first make sure you have this dump file put in the `piwikdb-init.d` directory as it will then be automatically loaded when the db container starts. You can then migrate your data into newer versions of the `piwik`application.

To illustrate a common data migration path, you can proceed like this:

		# stash the current data, if any
		make backup-piwik
		make clean

		# load new data into db from dump file
		scp user@publicpiwikserver:piwik_dump.sql .
		mkdir piwikdb-init.d
		cp piwik_dump.sql piwikdb-init.d

		# start service again
		make up

Before you start you need to generate the SSL-certs, run `make ssl-certs`, the certs will end up in the 'certs'-directory.

Then use the Makefile to start the system and issue `make test` to open the service from your local browser - it will take you to "piwik.docker". 

The first time piwik starts, it may need to migrate the db to a newer version of the schema, so a wizard opens up, the details to provide then are the credentials you reference in the `docker-compose.yml`-file, for example: 

		servername: db
		login: root
		password: passw0rd12
		database: piwik

After that step, you should then be able to log in to the service in the normal fashion using your application specific piwik username and password.

To migrate again to the latest version of piwik, open "welcome.docker" and use that migration wizard.

At the end, you have the data migrated to the latest schema used in the current version of the `piwik` application, and you can make a backup with `make backup-piwik` again, but be careful not to overwrite a previous backup.

## Makefile

The `Makefile` provides various targets (which are actions, like VERBs), for example you can....

		# start all services
		make

		# try it out
		make discover-services
		make test

		# get cli to piwik mysql db
		make debug

		# stop and remove service
		make down


# More Details

This section provides more information on the setup and suggestions on how to configure DNS.

## Services

The `docker-compose.yml` file provides the various components of the system (NOUNs), providing the services, for example:

		proxy 
		dnsdock 
		web
		db
		piwik (in various versions)

## Explaining routing and name resolution

This is handled by dnsdock, proxy and web and requires DNS to be configured on the host machine.

For setting up DNS to work well on your host machine, please follow the setup instructions at https://github.com/mskyttner/dns-test-docker. This works well on various network setups, but you may need to tune settings depending on how the network where you are running deals with name resolution...

The "web" component provides a front or portal to the rest of the services that provide http services or management interfaces. This component (nginx) receives traffic from the "proxy" component that routes http traffic from the outside, this is an nginx reverse proxy that provides the only way in from the "outside" (port 80 and 443) so it also provides ssl termination and that way the rest of the services don't have to provide ssl individually. 

For details, see the "app.conf" file which provides the rules to route the web traffic to the various services available to the outside world.

The dnsdock component is used for service discovery from within the host machine, on the "inside" of the software defined network. With this component, it becomes possible for you to reach the various components inside the SDN using commands like "ping piwik.docker" from the host running the docker daemon. 

