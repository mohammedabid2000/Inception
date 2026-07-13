# Inception user guide

## Services provided

The stack serves one WordPress site over HTTPS:

- **NGINX** receives browser requests on port 443 and terminates TLS.
- **WordPress/PHP-FPM** generates the site and administration pages.
- **MariaDB** stores users, posts, settings, and other application data.

MariaDB and PHP-FPM are internal services. They intentionally have no host ports.

## Start and stop

From the repository root:

```sh
make          # create missing local files, build, and start
make ps       # show status and health
make logs     # follow logs; press Ctrl-C to stop following
make stop     # stop while retaining containers and data
make start    # restart stopped containers
make down     # remove containers and network, retaining data
```

Containers use `restart: unless-stopped`, so Docker restarts them after a crash and
after daemon/VM startup unless an operator explicitly stopped them.

## Access the site

The hostname in `srcs/.env` must resolve to the VM. With the default configuration:

- Website: `https://mohabid.42.fr`
- Administration: `https://mohabid.42.fr/wp-admin`

The generated certificate is self-signed. A browser warning is expected in development;
inspect the certificate and accept it only when you know you reached your VM.

## Credentials

Non-secret account names and email addresses are in `srcs/.env`. Passwords are local
files in `secrets/`:

| File | Purpose |
|---|---|
| `wp_admin_password.txt` | WordPress site-owner password |
| `wp_user_password.txt` | WordPress author password |
| `db_password.txt` | WordPress database-user password |
| `db_root_password.txt` | MariaDB root password |
| `tls.key`, `tls.crt` | HTTPS private key and certificate |

Read only the credential you need, do not paste it into logs or screenshots, restrict
its permissions, and never commit it. `make setup` generates missing files and preserves
existing ones.

Passwords are consumed during first initialization. Editing a secret later does not
automatically rotate a live database or WordPress password. Rotate it inside the
affected service as well, or recreate the stack only when losing stored content is okay.

## Health and troubleshooting

```sh
make ps
docker compose --env-file srcs/.env -f srcs/docker-compose.yml logs --tail=100
curl -kI https://mohabid.42.fr
```

All three containers should be `Up`; MariaDB and WordPress should become `healthy`.
If the hostname fails, check `/etc/hosts` or DNS. If port 443 fails, verify no other
process owns it and the VM firewall permits it. Service-specific logs are available by
adding `nginx`, `wordpress`, or `mariadb` after the Compose `logs` command above.

`make fclean` removes the Docker volume registrations and project images, but the
subject-required backing files under `/home/mohabid/data` remain persistent. A full
reset requires stopping the stack and deliberately emptying both data directories with
appropriate permissions. Back them up first; this permanently destroys the site.
