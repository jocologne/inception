# Developer Documentation — Inception

This document describes how to set up, build, and manage the Inception project from a developer's perspective.

---

## Prerequisites

Before starting, make sure you have the following installed on your Virtual Machine:

- **Docker** (>= 24.x)
- **Docker Compose** (>= 2.x, the `docker compose` plugin — not the standalone `docker-compose`)
- **make**
- **sudo** access (needed to create data directories under `/home/jcologne/data`)

Check versions:
```bash
docker --version
docker compose version
make --version
```

---

## Project Structure

```
.
├── Makefile
├── README.md
├── DEV_DOC.md
├── USER_DOC.md
├── secrets/                        # Gitignored — never commit these
│   ├── credentials.txt             # WordPress admin/user passwords
│   ├── db_password.txt             # MariaDB wpuser password
│   └── db_root_password.txt        # MariaDB root password
└── srcs/
    ├── .env                        # Non-secret environment variables
    ├── docker-compose.yml
    └── requirements/
        ├── nginx/
        │   ├── Dockerfile
        │   ├── .dockerignore
        │   ├── conf/nginx.conf
        │   └── tools/setup-ssl.sh
        ├── wordpress/
        │   ├── Dockerfile
        │   ├── .dockerignore
        │   ├── conf/www.conf        # PHP-FPM pool config
        │   └── tools/init.sh       # Entrypoint: installs and configures WP
        ├── mariadb/
        │   ├── Dockerfile
        │   ├── .dockerignore
        │   ├── conf/50-server.cnf  # MariaDB server config
        │   └── tools/init.sh       # Entrypoint: initializes DB
        └── bonus/
            ├── redis/
            ├── ftp/
            ├── adminer/
            ├── static-site/
            └── portainer/
```

---

## Environment Configuration

### `srcs/.env`

Contains non-sensitive configuration. Key variables:

| Variable | Value | Description |
|----------|-------|-------------|
| `DOMAIN_NAME` | `jcologne.42.fr` | Domain used by NGINX and WordPress |
| `MYSQL_DATABASE` | `wordpress` | Database name |
| `MYSQL_USER` | `wpuser` | DB user for WordPress |
| `WORDPRESS_ADMIN_USER` | `manager` | WP admin username (must not contain "admin") |
| `WORDPRESS_USER` | `editor` | Second WP user |
| `WORDPRESS_USER_ROLE` | `editor` | Role of second user |
| `REDIS_HOST` / `REDIS_PORT` | `redis` / `6379` | Used if Redis bonus is active |

### `secrets/` files

Must be created manually and are gitignored. Format:

```bash
# secrets/db_password.txt
supersecurepassword

# secrets/db_root_password.txt
anotherpassword

# secrets/credentials.txt
WORDPRESS_ADMIN_PASSWORD=adminpass123
WORDPRESS_USER_PASSWORD=userpass456
```

Each `.txt` file should contain only the password (a single line, no trailing newlines — the init scripts use `tr -d '\n'` to strip them).

---

## Building and Launching the Project

### Step 1 — Create data directories and start services

```bash
make
```

Internally this runs:
```bash
sudo mkdir -p /home/jcologne/data/wordpress
sudo mkdir -p /home/jcologne/data/mariadb
docker compose -f srcs/docker-compose.yml up -d --build nginx wordpress mariadb
```

### Step 2 — Verify everything is running

```bash
docker ps
```

Expected output: three containers (`nginx`, `wordpress`, `mariadb`) all in `Up (healthy)` state.

The first startup takes longer because:
1. MariaDB initializes the database from scratch
2. WordPress waits for MariaDB, then downloads WP core and runs the install

---

## Container Management Commands

### View logs
```bash
docker logs -f nginx
docker logs -f wordpress
docker logs -f mariadb
```

### Execute a shell inside a container
```bash
docker exec -it nginx bash
docker exec -it wordpress bash
docker exec -it mariadb bash
```

### Restart a single container
```bash
docker compose -f srcs/docker-compose.yml restart wordpress
```

### Rebuild a single service after changes
```bash
docker compose -f srcs/docker-compose.yml up -d --build wordpress
```

### Stop all services (keep volumes)
```bash
make clean
# equivalent to: docker compose -f srcs/docker-compose.yml down
```

### Full teardown (removes images, volumes, data)
```bash
make fclean
```

---

## Data Persistence

### Where data lives

| Data | Container path | Host path |
|------|---------------|-----------|
| WordPress files | `/var/www/html` | `/home/jcologne/data/wordpress` |
| MariaDB data | `/var/lib/mysql` | `/home/jcologne/data/mariadb` |

Both are configured as named volumes with `type: none` and `o: bind`, meaning Docker manages the volume metadata but the actual files sit at the host paths above.

### How persistence works

- **MariaDB**: The `init.sh` script checks if `/var/lib/mysql/mysql` exists. If yes, it runs a lighter `setup_database()` path. If not, it does a full `mysql_install_db` initialization.
- **WordPress**: The `init.sh` script checks if `/var/www/html/wp-config.php` exists. If yes, it skips the install and just starts PHP-FPM.

This means data survives `make clean` (containers down, volumes intact) but is destroyed by `make fclean` (which runs `sudo rm -rf /home/jcologne/data`).

---

## SSL/TLS

The SSL certificate is generated at **build time** by `nginx/tools/setup-ssl.sh` using OpenSSL. It creates a self-signed RSA 2048-bit certificate valid for 365 days, stored inside the NGINX image at `/etc/nginx/ssl/`.

The certificate is generated for `jcologne.42.fr` and `www.jcologne.42.fr`. To regenerate, rebuild the NGINX image:
```bash
docker compose -f srcs/docker-compose.yml build --no-cache nginx
```

---

## Healthchecks

Each service defines a Docker healthcheck:

| Service | Healthcheck command | Interval | Start period |
|---------|---------------------|----------|--------------|
| nginx | `curl -fsk https://localhost/health` | 30s | 30s |
| wordpress | `pgrep php-fpm` | 30s | 60s |
| mariadb | `mysqladmin ping -h localhost --silent` | 10s | 30s |

NGINX depends on WordPress being healthy, and WordPress depends on MariaDB being healthy (`depends_on: condition: service_healthy`). This prevents startup race conditions.

---

## Network

All containers connect to the `inception` bridge network. They communicate by service name (e.g., `wordpress:9000`, `mariadb:3306`). Only NGINX exposes a port to the host (`443:443`). The MariaDB and WordPress ports are internal only.

---

## Known Issues

- **Password leak in logs**: `wordpress/tools/init.sh` contains `echo "ADMIN__$ADMIN_PASSWORD"` which prints the admin password in plaintext to container logs. This line should be removed before production use or evaluation.

- **`debian:oldstable` tag**: This tag is semantic and its meaning changes over time as new Debian releases are made. For reproducibility, consider pinning to a specific version like `debian:bullseye` (Debian 11, penultimate stable).