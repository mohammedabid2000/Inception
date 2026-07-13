*This project has been created as part of the 42 curriculum by mohabid.*

# Inception

## Description

Inception is a small web infrastructure built entirely from custom Docker images. It
runs three isolated services:

- **NGINX** is the only public entry point. It listens on port 443 and accepts only
  TLS 1.2 or TLS 1.3.
- **WordPress + PHP-FPM** serves the application on the internal port 9000. It does
  not contain a web server.
- **MariaDB** stores the WordPress database and is reachable only through the private
  Docker network.

The images are built from Debian 12 (`debian:12-slim`), rather than pulled as prepared
NGINX, WordPress, or MariaDB images. Docker Compose defines the services, the private
bridge network, secrets, health checks, restart policies, and persistent named volumes.
The database and website remain on the host below `/home/mohabid/data` when containers
are recreated.

Project sources are organized as follows:

```text
.
├── Makefile
├── secrets/                     # ignored runtime secrets and safe examples
└── srcs/
    ├── .env                     # ignored, non-secret local settings
    ├── .env.example
    ├── docker-compose.yml
    └── requirements/
        ├── mariadb/             # database Dockerfile, config, entrypoint
        ├── nginx/               # TLS proxy Dockerfile, config, entrypoint
        ├── tools/setup.sh       # host setup and secret generation
        └── wordpress/           # PHP-FPM Dockerfile, config, entrypoint
```

### Design choices

| Topic | Choice and reason |
|---|---|
| Virtual machines vs Docker | A VM virtualizes a complete machine and kernel, providing stronger isolation at a higher resource cost. Docker containers share the host kernel and package only each service and its dependencies. This project uses a required VM as its host, then containers for lightweight, reproducible service isolation. |
| Secrets vs environment variables | Environment variables are convenient for non-confidential configuration but are visible in container metadata and process environments. Passwords and TLS private material are mounted read-only under `/run/secrets`; `.env` contains only names, email addresses, paths, and the domain. |
| Docker network vs host network | Host networking removes network isolation and exposes services directly. The dedicated `inception` bridge gives services DNS names and isolates MariaDB/PHP-FPM; only NGINX publishes a host port. |
| Docker volumes vs bind mounts | Bind mounts directly expose an arbitrary host path to a service. Compose-managed named volumes provide stable lifecycle and service declarations. The two named volumes use the local driver to keep their data in the subject-required `/home/mohabid/data` location. |

## Instructions

### Prerequisites

- A Linux virtual machine with Docker Engine, Docker Compose v2, Make, and OpenSSL.
- Port 443 available.
- Permission to create `/home/mohabid/data`.

### Configure and run

1. Review `srcs/.env.example`. Copy it to `srcs/.env` if the local file is absent and
   adapt `DOMAIN_NAME`, `DATA_PATH`, users, and email addresses. `WP_ADMIN_USER` must
   not contain `admin` in any letter case.
2. Run `make setup`. It creates strong local passwords, a self-signed certificate, and
   both persistent data directories. Existing secrets are never overwritten.
3. Point `mohabid.42.fr` at the VM IP. For local testing, add
   `127.0.0.1 mohabid.42.fr` to `/etc/hosts`; use the VM's reachable IP when browsing
   from another machine.
4. Run `make`. This builds all custom images and starts the stack.
5. Open `https://mohabid.42.fr`. The development certificate is self-signed, so the
   browser will display a warning. WordPress administration is at `/wp-admin`.

Useful commands:

```sh
make ps       # container state and health
make logs     # follow all logs
make stop     # stop containers without removing them
make start    # start stopped containers
make down     # remove containers/network; preserve volumes
make fclean   # remove containers, images, and Docker volume registrations
make re       # rebuild while retaining data in the required host directories
```

See [USER_DOC.md](USER_DOC.md) for day-to-day operation and
[DEV_DOC.md](DEV_DOC.md) for setup, architecture, troubleshooting, and persistence.

## Security notes

- Never commit `srcs/.env`, generated files in `secrets/`, database dumps, or private
  keys. Only `.example` templates belong in Git.
- NGINX is the only published service and only port `443` is mapped.
- Changing a secret file does not alter an initialized WordPress/database volume. Use
  the application/database tools to rotate live credentials. A true reset also requires
  intentionally emptying the two host data directories after the stack is stopped.

## Resources

- [Docker documentation](https://docs.docker.com/)
- [Docker Compose file reference](https://docs.docker.com/reference/compose-file/)
- [Docker volumes](https://docs.docker.com/engine/storage/volumes/)
- [Docker secrets in Compose](https://docs.docker.com/compose/how-tos/use-secrets/)
- [NGINX HTTPS configuration](https://nginx.org/en/docs/http/configuring_https_servers.html)
- [PHP-FPM configuration](https://www.php.net/manual/en/install.fpm.configuration.php)
- [MariaDB Server documentation](https://mariadb.com/docs/server/)
- [WP-CLI command reference](https://developer.wordpress.org/cli/commands/)

AI was used to help translate the subject requirements into an initial infrastructure,
write repetitive configuration and documentation, and suggest validation checks. The
generated work must still be read, tested in the target VM, explained by the student,
and reviewed with peers; responsibility for the submitted project remains with its author.
