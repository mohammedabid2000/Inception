#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/../../.." && pwd)
ENV_FILE="$ROOT_DIR/srcs/.env"
SECRETS_DIR="$ROOT_DIR/secrets"

if [ ! -f "$ENV_FILE" ]; then
    echo "Missing $ENV_FILE; create it with the project configuration before running setup." >&2
    exit 1
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
create_password "$SECRETS_DIR/credentials.txt"

printf '\nSetup complete. Add this hosts entry if it is missing:\n'
printf '127.0.0.1 %s\n' "$DOMAIN_NAME"
