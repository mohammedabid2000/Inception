#!/bin/sh
set -eu

: "${DOMAIN_NAME:?DOMAIN_NAME is required}"

mkdir -p /etc/nginx/ssl
openssl req -x509 -nodes -newkey rsa:2048 -sha256 -days 365 \
    -keyout /etc/nginx/ssl/tls.key \
    -out /etc/nginx/ssl/tls.crt \
    -subj "/C=MA/O=42/CN=$DOMAIN_NAME" \
    -addext "subjectAltName=DNS:$DOMAIN_NAME" >/dev/null 2>&1
chmod 600 /etc/nginx/ssl/tls.key

envsubst '${DOMAIN_NAME}' \
    < /etc/nginx/templates/default.conf.template \
    > /etc/nginx/conf.d/default.conf

nginx -t
exec "$@"
