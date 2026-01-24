FROM	debian:oldstable

RUN	apt-get update && apt-get install -y --no-install-recomends \
		mariadb-server \
		mariadb-client \
		procps \
		&& rm -rf /var/lib/apt/lists/*

RUN	mkdir -p /var/run/mysqld \
		&& chown -R mysql:mysql /var/run/mysqld \
		&& chmod 755 /var/run/mysqld

RUN	mkdir -p /var/lib/mysql \
		&& chown -R mysql:mysql /var/lib/mysql

COPY	conf/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf

COPY	tools/init.sh /usr/local/bin/init.sh
RUN	chmod +x /usr/local/bin/init.sh

EXPOSE 3306

HEALTHCHECK	--interval=10s --timeout=5s --start-period=30s --retries=5 \
	CMD mysqladmin ping -h localhost --silent || exit 1

ENTRYPOINT [ "/usr/local/bin/init.sh" ]