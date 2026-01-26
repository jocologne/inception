FROM	debian:oldstable

RUN	apt-get update && apt-get install -y --no-install-recommends \
		php-fpm \
		php-mysql \
		php-curl \
		php-gd \
		php-intl \
		php-mbstring \
		php-xml \
		php-zip \
		php-cmath \
		php-imagick \
		php-redis \
		curl \
		mariadb-client \
		ca-certificates \
		procps \
		&& rm -rf /var/lib/apt/lists/*

RUN	curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
		&& chmod +x wp-cli.phar \
		&& mv wp-cli.phar /usr/local/bin/wp

RUN	mkdir -p /var/www/html \
		&& chown -R www-data:www-data /var/www/html

RUN	mkdir -p /run/php \
		&& chown -R www-data:www-data /run/php

COPY	conf/www.conf /etc/php/*/fpm/pool.d/www.conf

COPY	tools/init.sh /usr/local/bin/init.sh
RUN	chmod +x /usr/local/bin/init.sh

WORKDIR /var/www/html

EXPOSE 9000

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=5 \
	CMD pgrep php-fpm > /dev/null || exit 1

ENTRYPOINT [ "/usr/local/bin/init.sh" ]