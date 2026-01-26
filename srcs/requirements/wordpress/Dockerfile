FROM	debian:oldstable

RUN	apt-get update && apt-get install -y --no-install-recommends \
		php8.2-fpm \
		php8.2=mysql \
		php8.2-curl \
		php8.2-gd \
		php8.2-intl \
		php8.2-mbstring \
		php8.2-xml \
		php8.2-zip \
		php8.2-cmath \
		php8.2-imagick \
		php8.2-redis \
		curl \
		mariadb-client \
		ca-certificates \
		procps \
		&& rm -rf /var/lib/apt/lists/*

RUN	curl -o https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
		&& chmod +x wp-cli.phar \
		&& mv wp-cli.phar /usr/local/bin/wp

RUN	mkdir -p /var/www/html \
		&& chown -R www-data:www-data /var/www/html

RUN	mkdir -p /run/php \
		&& chown -R www-data:www-data /run/php

COPY	conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf

COPY	tools/init.sh /usr/local/bin/init.sh
RUN	chmod +x /usr/local/bin/init.sh

WORKDIR /var/www/html

EXPOSE 9000

HEALTHCHECK --interval=10s --timeout=5s --start-period=60s --retries=5 \
	CMD pgrep php-fpm > /dev/null || exit 1

ENTRYPOINT [ "/usr/local/bin/init.sh" ]