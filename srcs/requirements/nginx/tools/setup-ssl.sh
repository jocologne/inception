#!/bin/bash
set -e

SSL_DIR="/etc/nginx/ssl"
DOMAIN="${DOMAIN_NAME:-jcologne.42.fr}"
DAYS_VALID=365

echo "[INFO] Gerando SSL..."

mkdir -p "$SSL_DIR"

openssl req -x509 \
	-nodes \
	-days $DAYS_VALID \
	-newkey rsa:2048 \
	-keyout "$SSL_DIR/inception.key" \
	-out "$SSL_DIR/inception.crt" \
	-subj "/C=BR/ST=SP/L=Sao Paulo/O=42SP/OU=Inception/CN=$DOMAIN" \
	-addext "subjectAltName=DNS:$DOMAIN,DNS:www.$DOMAIN,IP:127.0.0.1"

chmod 600 "$SSL_DIR/inception.key"
chmod 644 "$SSL_DIR/inception.crt"

echo "[INFO] Certificados gerados"
ls -la "$SSL_DIR"
