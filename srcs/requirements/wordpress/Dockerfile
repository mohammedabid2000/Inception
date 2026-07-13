FROM debian:12-slim

ARG WORDPRESS_VERSION=6.8.2

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates curl mariadb-client libfcgi-bin \
        php8.2-fpm php8.2-mysql php8.2-curl php8.2-gd php8.2-intl \
        php8.2-mbstring php8.2-xml php8.2-zip \
    && curl -fsSL "https://wordpress.org/wordpress-${WORDPRESS_VERSION}.tar.gz" -o /tmp/wordpress.tar.gz \
    && tar -xzf /tmp/wordpress.tar.gz -C /usr/src \
    && curl -fsSL https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -o /usr/local/bin/wp \
    && chmod 755 /usr/local/bin/wp \
    && rm -f /tmp/wordpress.tar.gz \
    && rm -rf /var/lib/apt/lists/*

COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf
COPY tools/setup.sh /usr/local/bin/wordpress-entrypoint

RUN chmod 755 /usr/local/bin/wordpress-entrypoint \
    && mkdir -p /run/php /var/www/html \
    && chown -R www-data:www-data /run/php /var/www/html /usr/src/wordpress

EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/wordpress-entrypoint"]
CMD ["php-fpm8.2", "-F"]
