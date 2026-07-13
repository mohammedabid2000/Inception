# Inception developer guide

## Prerequisites and initial setup

Use a Linux virtual machine with Docker Engine, the Compose v2 plugin, GNU Make, and
OpenSSL. Confirm them with:

```sh
docker --version
docker compose version
make --version
openssl version
```

Clone the repository, copy `srcs/.env.example` to `srcs/.env`, and edit it.
`DOMAIN_NAME` must be `<login>.42.fr`, and `DATA_PATH` must be
`/home/<login>/data`. The file contains no passwords. Ensure the administrator user
does not contain `admin` in any letter case.

Run `make setup`. It creates the data directories, generates four random password
files without replacing existing ones, and creates a self-signed certificate. Map the
domain to the VM IP in DNS or a hosts file.

## Build and launch

```sh
make config   # render and validate Compose interpolation
make build    # create the three custom images
make up       # build if needed and start in the background
# or simply:
make
```

Health checks sequence initialization: MariaDB starts first, WordPress then creates
`wp-config.php`, installs the site and two users, and NGINX starts after PHP-FPM
responds. Entrypoints finish by `exec`-ing the real daemon so it becomes PID 1 and
receives stop signals correctly. They use no infinite-loop keepalive hacks.

## Architecture

```text
client -- HTTPS :443 --> nginx -- FastCGI :9000 --> wordpress
                                                   |
                                                   +-- MariaDB :3306 --> mariadb

host /home/mohabid/data/wordpress --> inception_wordpress_data
host /home/mohabid/data/mariadb   --> inception_mariadb_data
```

Only NGINX publishes a port. Containers resolve one another by service name on the
`inception` bridge. Passwords and TLS files are read from `/run/secrets`. The website
volume is read/write in WordPress and read-only in NGINX.

## Management commands

```sh
make ps
make logs
make stop
make start
make restart
make down

docker compose --env-file srcs/.env -f srcs/docker-compose.yml config
docker compose --env-file srcs/.env -f srcs/docker-compose.yml images
docker compose --env-file srcs/.env -f srcs/docker-compose.yml exec wordpress wp --allow-root user list
docker compose --env-file srcs/.env -f srcs/docker-compose.yml exec mariadb mariadb -uroot -p
docker network inspect inception
docker volume inspect inception_wordpress_data inception_mariadb_data
```

To rebuild a changed service, run Compose `build <service>` followed by `up -d
<service>` with the same file and environment arguments shown above.

## Persistence and cleanup

The Compose-managed named volumes store their content at:

- `/home/mohabid/data/mariadb` for database files.
- `/home/mohabid/data/wordpress` for WordPress core, config, themes, plugins, uploads.

`make down` and `make clean` preserve data. `make fclean` asks Docker to remove the
named volumes. Because their backing directories are host paths, inspect and remove
leftover contents deliberately before expecting a completely fresh initialization.
For backups, stop writes first and archive both paths; a `mariadb-dump` logical database
backup is more portable than raw database files.

## Validation checklist

```sh
make config
find srcs/requirements -name '*.sh' -exec sh -n {} \;
docker compose --env-file srcs/.env -f srcs/docker-compose.yml ps
openssl s_client -connect mohabid.42.fr:443 -tls1_2 </dev/null
openssl s_client -connect mohabid.42.fr:443 -tls1_3 </dev/null
openssl s_client -connect mohabid.42.fr:443 -tls1 </dev/null
```

The first two TLS checks should connect and the TLS 1.0 check should fail. Before a
commit, ensure local `.env`, passwords, and private keys are not tracked.
