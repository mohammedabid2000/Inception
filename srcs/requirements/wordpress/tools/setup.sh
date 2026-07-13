#!/bin/sh
set -eu

required_variables="DOMAIN_NAME MYSQL_DATABASE MYSQL_USER WP_TITLE WP_ADMIN_USER WP_ADMIN_EMAIL WP_USER WP_USER_EMAIL"
for variable in $required_variables; do
    eval "value=\${$variable:-}"
    if [ -z "$value" ]; then
        echo "$variable is required" >&2
        exit 1
    fi
done

case "$WP_ADMIN_USER" in
    *[Aa][Dd][Mm][Ii][Nn]*) echo 'WP_ADMIN_USER must not contain "admin".' >&2; exit 1 ;;
esac

DB_PASSWORD=$(cat /run/secrets/db_password)
WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password)

if [ ! -f /var/www/html/wp-includes/version.php ]; then
    cp -a /usr/src/wordpress/. /var/www/html/
fi

chown -R www-data:www-data /var/www/html

wp_cmd() {
    wp --allow-root --path=/var/www/html "$@"
}

if [ ! -f /var/www/html/wp-config.php ]; then
    wp_cmd config create \
        --dbname="$MYSQL_DATABASE" \
        --dbuser="$MYSQL_USER" \
        --dbpass="$DB_PASSWORD" \
        --dbhost=mariadb:3306 \
        --dbcharset=utf8mb4 \
        --skip-check
fi

if ! wp_cmd core is-installed; then
    wp_cmd core install \
        --url="https://$DOMAIN_NAME" \
        --title="$WP_TITLE" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$WP_ADMIN_PASSWORD" \
        --admin_email="$WP_ADMIN_EMAIL" \
        --skip-email
fi

if ! wp_cmd user get "$WP_USER" --field=ID >/dev/null 2>&1; then
    wp_cmd user create "$WP_USER" "$WP_USER_EMAIL" \
        --user_pass="$WP_USER_PASSWORD" \
        --role=author
fi

wp_cmd option update home "https://$DOMAIN_NAME"
wp_cmd option update siteurl "https://$DOMAIN_NAME"
chown -R www-data:www-data /var/www/html

exec "$@"
