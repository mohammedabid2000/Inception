#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/../../.." && pwd)
ENV_FILE="$ROOT_DIR/srcs/.env"
EXAMPLE_ENV="$ROOT_DIR/srcs/.env.example"
SECRETS_DIR="$ROOT_DIR/secrets"

if [ ! -f "$ENV_FILE" ]; then
    cp "$EXAMPLE_ENV" "$ENV_FILE"
    printf 'Created %s; review it before starting the stack.\n' "$ENV_FILE"
fi

# Export DATA_PATH and DOMAIN_NAME without executing arbitrary text from .env.
DATA_PATH=$(sed -n 's/^DATA_PATH=//p' "$ENV_FILE" | tail -n 1)
DOMAIN_NAME=$(sed -n 's/^DOMAIN_NAME=//p' "$ENV_FILE" | tail -n 1)

if [ -z "$DATA_PATH" ] || [ -z "$DOMAIN_NAME" ]; then
    echo "DATA_PATH and DOMAIN_NAME must be set in $ENV_FILE" >&2
    exit 1
fi

mkdir -p "$SECRETS_DIR" "$DATA_PATH/mariadb" "$DATA_PATH/wordpress"

create_password() {
    destination=$1
    if [ ! -s "$destination" ]; then
        umask 077
        openssl rand -base64 36 | tr -d '\n' > "$destination"
        printf '\n' >> "$destination"
        printf 'Generated %s\n' "$destination"
    fi
}

create_password "$SECRETS_DIR/db_root_password.txt"
create_password "$SECRETS_DIR/db_password.txt"
create_password "$SECRETS_DIR/wp_admin_password.txt"
create_password "$SECRETS_DIR/wp_user_password.txt"

if [ ! -s "$SECRETS_DIR/tls.crt" ] || [ ! -s "$SECRETS_DIR/tls.key" ]; then
    umask 077
    openssl req -x509 -nodes -newkey rsa:2048 -sha256 -days 365 \
        -keyout "$SECRETS_DIR/tls.key" \
        -out "$SECRETS_DIR/tls.crt" \
        -subj "/C=MA/O=42/CN=$DOMAIN_NAME" \
        -addext "subjectAltName=DNS:$DOMAIN_NAME"
    chmod 600 "$SECRETS_DIR/tls.key"
    chmod 644 "$SECRETS_DIR/tls.crt"
    printf 'Generated a self-signed TLS certificate for %s.\n' "$DOMAIN_NAME"
fi

printf '\nSetup complete. Add this hosts entry if it is missing:\n'
printf '127.0.0.1 %s\n' "$DOMAIN_NAME"
