FROM debian:12-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends nginx gettext-base openssl ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && rm -f /etc/nginx/sites-enabled/default

COPY conf/default.conf.template /etc/nginx/templates/default.conf.template
COPY tools/setup.sh /usr/local/bin/nginx-entrypoint

RUN chmod 755 /usr/local/bin/nginx-entrypoint

EXPOSE 443

ENTRYPOINT ["/usr/local/bin/nginx-entrypoint"]
CMD ["nginx", "-g", "daemon off;"]
