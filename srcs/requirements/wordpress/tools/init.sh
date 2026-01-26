#!/bin/bash
set -e

read_secret() {
	local  secret_file="$1"
	if [ -f "$secret_file" ]; then
		cat "$secret_file" | tr -d '\n'
	else
		echo ""
	fi
}

read_credentials() {
	local cred_file="/run/secrets/credentials"
	if [ -f "$cred_file" ]; then
		grep "^$1=" "$cred_file" | cut -d'=' -f2 | tr -d '\n'
	else
		echo ""
	fi
}

DB_PASSWORD=$(read_secret "${WORDPRESS_DB_PASSWORD_FILE}")
ADMIN_PASSWORD=$(read_credentials "WORDPRESS_ADMIN_PASSWORD")
USER_PASSWORD=$(read_credentials "WORDPRESS_USER_PASSWORD")
MYSQL_PASSWORD=$(read_secret "$MYSQL_PASSWORD_FILE")

REQUIRED_VARS=(
	"WORDPRESS_DB_HOST"
	"WORDPRESS_DB_NAME"
	"WORDPRESS_DB_USER"
	"DOMAIN_NAME"
	"WORDPRESS_ADMIN_USER"
	"WORDPRESS_USER"
	"WORDPRESS_ADMIN_EMAIL"
	"WORDPRESS_USER_EMAIL"
)

for var in "${REQUIRED_VARS[@]}"; do
	if [ -z "${!var}" ]; then
		echo "[ERROR] Variável $var não definida"
		exit 1
	fi
done

[ -z "$DB_PASSWORD" ] && echo "[ERROR] DB_PASSWORD missing" && exit 1
[ -z "$ADMIN_PASSWORD" ] && echo "[ERROR] ADMIN_PASSWORD missing" && exit 1
[ -z "$USER_PASSWORD" ] && echo "[ERROR] USER_PASSWORD missing" && exit 1

DB_HOST=$(echo "$WORDPRESS_DB_HOST" | cut -d':' -f1)
DB_PORT=$(echo "$WORDPRESS_DB_HOST" | cut -d':' -f2)
DB_PORT=${DB_PORT:-3306}

echo "[INFO] Aguardando MariaDB em $DB_HOST:$DB_PORT..."
max_attempts=60
attempt=0
while ! mysqladmin ping -h "$DB_HOST" -P "$DB_PORT" --silent 2>/dev/null; do
	attempt=$((attempt + 1))
	if [ $attempt -ge $max_attempts ]; then
		echo "[ERROR] MariaDB não respondeu"
		exit 1
	fi
	echo "[INFO] Tentativa $attempt/$max_attempts"
	sleep 2
done
echo "[INFO] MariaDB está pronto!"

cd /var/www/html

if [ ! -f "/var/www/html/wp-config.php" ]; then
	echo "[INFO] Primeira inicialização - Configurando WordPress..."
	if [ ! -f "/var/www/html/wp-load.php" ]; then
		echo "[INFO] Baixando WordPress..."
		wp core download --allow-root --locale=pt_BR
	fi
	echo "[INFO] Criando wp-config.php..."
	wp config create \
		--dbname="$WORDPRESS_DB_NAME" \
		--dbuser="$WORDPRESS_DB_USER" \
		--dbpass="$DB_PASSWORD" \
		--dbhost="$DB_HOST:$DB_PORT" \
		--dbcharset="utf8mb4" \
		--dbcollate="utf8mb4_unicode_ci" \
		--allow-root
	wp config set WP_DEBUG false --raw --allow-root
	wp config set WP_DEBUG_LOG false --raw --allow-root
	wp config set WP_DEBUG_DISPLAY false --raw --allow-root
	wp config set DISALLOW_FILE_EDIT true --raw --allow-root

	if [ -n "$REDIS_HOST" ]; then
		wp config set WP_REDIS_HOST "$REDIS_HOST" --allow-root
		wp config set WP_REDIS_PORT "${REDIS_PORT:-6379}" --allow-root
		wp config set WP_CACHE true --raw --allow-root
	fi

	echo "[INFO] Instalando WordPress..."
	wp core install \
		--url="https://${DOMAIN_NAME}" \
		--title="${WORDPRESS_TITLE:-Inception}" \
		--admin_user="$WORDPRESS_ADMIN_USER" \
		--admin_password="$ADMIN_PASSWORD" \
		--admin_email="$WORDPRESS_ADMIN_EMAIL" \
		--skip-email \
		--allow-root
	
	echo "[INFO] Criando segundo usuário..."
	wp user create \
		"$WORDPRESS_USER" \
		"$WORDPRESS_USER_EMAIL" \
		--role="${WORDPRESS_USER_ROLE:-editor}" \
		--user_pass="$USER_PASSWORD" \
		--allow-root || echo "[WARN] Usuário já existe"
	wp rewrite structure '/%postname%/' --allow-root
	wp rewrite flush --allow-root
	wp theme activate twentytwentythree --allow-root 2>/dev/null || true
	wp language core update --allow-root 2>/dev/null || true
	echo "[INFO] WordPress instalado!"
	echo "[INFO] - URL https://${DOMAIN_NAME}"
	echo "[INFO] - Admin: $WORDPRESS_ADMIN_USER"
	echo "[INFO] - Usuário: $WORDPRESS_USER"
else
	echo "[INFO] WordPress já configurado"
fi

chown -R www-data:www-data /var/www/html

echo "[INFO] Iniciando PHP-FPM..."

exec php-fpm -F