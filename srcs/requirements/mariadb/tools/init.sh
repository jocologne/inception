#!/bin/bash

set -e

read_secret() {
	local secret_file="$1"
	if [ -f "$secret_file" ]; then
		tr -d '\n' < "$secret_file"
	else
		echo ""
	fi
}

MYSQL_ROOT_PASSWORD=$(read_secret "${MYSQL_ROOT_PASSWORD_FILE}")
MYSQL_PASSWORD=$(read_secret "${MYSQL_PASSWORD_FILE}")

if [ -z "$MYSQL_ROOT_PASSWORD" ]; then
	echo "[ERROR] MYSQL_ROOT_PASSWORD não definido"
	exit 1
fi

if [ -z "$MYSQL_DATABASE" ]; then
	echo "[ERROR] MYSQL_DATABASE não definido"
	exit 1
fi

if [ -z "$MYSQL_USER" ]; then
	echo "[ERROR] MYSQL_USER não definido"
	exit 1
fi

if [ -z "$MYSQL_PASSWORD" ]; then
	echo "[ERROR] MYSQL_PASSWORD não definido"
	exit 1
fi

init_database() {
	echo "[INFO] Inicializando banco de dados..."
	mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null 2>&1
	echo "[INFO] Inicializando MariaDB..."
	mysqld --user=mysql --datadir=/var/lib/mysql --skip-networking & pid="$!"
	echo "[INFO] Aguardando MariaDB..."
	for i in $(seq 1 30); do
		if mysqladmin ping --silent 2>/dev/null; then
			break
		fi
		sleep 1
	done
	if ! mysqladmin ping --silent 2>/dev/null; then
		echo "[ERROR] MariaDB não iniciou"
		exit 1
	fi
	
	echo "[INFO] Configurando banco de dados..."
	echo "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';" > /tmp/init.sql
	echo "CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" >> /tmp/init.sql
	echo "CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';" >> /tmp/init.sql
	echo "GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';" >> /tmp/init.sql
	echo "FLUSH PRIVILEGES;" >> /tmp/init.sql

	mysql -u root < /tmp/init.sql
	rm -f /tmp/init.sql

	echo "[INFO] Banco de dados configurado com sucesso"
	mysqladmin -u root -p"$MYSQL_ROOT_PASSWORD" shutdown
	wait "$pid"
}

setup_database() {
	mysqld --user=mysql --datadir=/var/lib/mysql --skip-networking & pid="$!"
	for i in $(seq 1 30); do
		if mysqladmin ping --silent 2>/dev/null; then
			break
		fi
		sleep 1
	done
	if ! mysqladmin ping --silent 2>/dev/null; then
		echo "[ERROR] MariaDB não iniciou corretamente"
		exit 1
	fi
	if ! mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "USE ${MYSQL_DATABASE}" 2>/dev/null; then
		echo "CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" > /tmp/setup.sql
		echo "CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';" >> /tmp/setup.sql
		echo "GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';" >> /tmp/setup.sql
		echo "FLUSH PRIVILEGES;" >> /tmp/setup.sql
		mysql -u root -p"${MYSQL_ROOT_PASSWORD}" < /tmp/setup.sql
		rm -f /tmp/setup.sql
	fi
	mysqladmin -u root -p"${MYSQL_ROOT_PASSWORD}" shutdown
	wait "$pid"
}

if [ ! -d "/var/lib/mysql/mysql" ]; then
	init_database
else
	setup_database
fi

echo "[INFO] MariaDB Concluido"
exec mysqld --user=mysql --datadir=/var/lib/mysql