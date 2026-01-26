FROM	debian:oldstable

RUN	apt-get update && apt-get install -y --no-install-recommends \
		nginx \
		openssl \
		curl \
		procps \
		&& rm -rf /var/lib/apt/lists/*

RUN	mkdir -p /etc/nginx/ssl \
		&&mkdir -p /var/www/html \
		&&mkdir -p /var/log/nginx \
		&&mkdir -p /run/nginx

COPY	tools/setup-ssl.sh /usr/local/bin/setup-ssl.sh
RUN	chmod +x /usr/local/bin/setup-ssl.sh

RUN /usr/local/bin/setup-ssl.sh

COPY	conf/nginx.conf /etc/nginx/nginx.conf

RUN	chown -R www-data:www-data /var/www/html \
		&& chown -R www-data:www-data /var/log/nginx

EXPOSE 443

HEALTHCHECK --interval=10s --timeout=5s --start-period=10s --retries=5 \
	CMD curl -fsk https://localhost/health || exit 1

CMD ["nginx", "-g", "daemon off;"]
