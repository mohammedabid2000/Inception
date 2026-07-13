#!/bin/sh
set -eu

: "${MYSQL_DATABASE:?MYSQL_DATABASE is required}"
: "${MYSQL_USER:?MYSQL_USER is required}"

case "$MYSQL_DATABASE:$MYSQL_USER" in
    *[!A-Za-z0-9_:]*) echo "Database and user names may contain only letters, numbers, and underscores." >&2; exit 1 ;;
esac

DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
DB_PASSWORD=$(cat /run/secrets/db_password)

mkdir -p /run/mysqld /var/lib/mysql
chown -R mysql:mysql /run/mysqld /var/lib/mysql

if [ ! -d /var/lib/mysql/mysql ]; then
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql --skip-test-db >/dev/null

    mariadbd --user=mysql --skip-networking --socket=/run/mysqld/mysqld.sock &
    server_pid=$!

    ready=0
    for attempt in $(seq 1 30); do
        if mariadb-admin --socket=/run/mysqld/mysqld.sock ping --silent; then
            ready=1
            break
        fi
        sleep 1
    done
    if [ "$ready" -ne 1 ]; then
        echo "Temporary MariaDB server did not become ready." >&2
        kill "$server_pid" 2>/dev/null || true
        exit 1
    fi

    sql_escape() {
        printf '%s' "$1" | sed "s/'/''/g"
    }
    escaped_root=$(sql_escape "$DB_ROOT_PASSWORD")
    escaped_password=$(sql_escape "$DB_PASSWORD")

    mariadb --socket=/run/mysqld/mysqld.sock -uroot <<-SQL
		CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
		CREATE USER IF NOT EXISTS '$MYSQL_USER'@'%' IDENTIFIED BY '$escaped_password';
		ALTER USER '$MYSQL_USER'@'%' IDENTIFIED BY '$escaped_password';
		GRANT ALL PRIVILEGES ON \`$MYSQL_DATABASE\`.* TO '$MYSQL_USER'@'%';
		ALTER USER 'root'@'localhost' IDENTIFIED BY '$escaped_root';
		DELETE FROM mysql.user WHERE User='';
		FLUSH PRIVILEGES;
	SQL

    mariadb-admin --socket=/run/mysqld/mysqld.sock -uroot --password="$DB_ROOT_PASSWORD" shutdown
    wait "$server_pid"
fi

exec "$@"
