*This project has been created as part of the 42 curriculum by jcologne.*

# Inception

## Description

Inception is a System Administration project from the 42 curriculum. The goal is to set up a small but complete web infrastructure using Docker and Docker Compose, running entirely inside a Virtual Machine.

---

## Project Description

### Use of Docker

Docker is used to package each service into an isolated, reproducible container. Instead of installing NGINX, PHP, and MariaDB directly on the host machine, each one lives in its own container with only the dependencies it needs. This makes the infrastructure portable, easier to maintain, and consistent across environments.

The entire setup is orchestrated by **Docker Compose**, which defines all services, their dependencies, the shared network, volumes, and secrets in a single `docker-compose.yml` file. The **Makefile** at the project root drives the build — running `make` is all that is needed to bring the full infrastructure up.

All images are built from scratch using custom **Dockerfiles**, one per service. Pulling ready-made images from DockerHub is forbidden by the subject (except for the base OS image). This means every configuration decision — what packages to install, how to start the process, how to pass credentials — is explicit and under full control.

Containers are configured to **restart automatically** on crash, and each one defines a **healthcheck** so that Docker knows when a service is truly ready before starting dependent services. For example, WordPress only starts after MariaDB reports healthy, and NGINX only starts after WordPress is healthy.

### Sources Included in the Project

The infrastructure is composed of three services, each in its own dedicated container built from `debian:oldstable`:

**NGINX** (`srcs/requirements/nginx/`)
NGINX is the sole entry point to the infrastructure. It listens exclusively on port 443 and uses a self-signed TLS certificate generated at build time with OpenSSL. It enforces TLSv1.2 and TLSv1.3 only, with a strong cipher suite. Incoming PHP requests are forwarded to the WordPress container via FastCGI on port 9000. Static assets (CSS, JS, images) are served directly by NGINX with long cache headers. The configuration also blocks access to sensitive files like `wp-config.php` and dotfiles.

**WordPress + PHP-FPM** (`srcs/requirements/wordpress/`)
WordPress is the content management system running the website. It uses PHP-FPM (FastCGI Process Manager) to process PHP requests received from NGINX. The container does not include NGINX — it only runs PHP-FPM on port 9000. On first boot, the entrypoint script (`init.sh`) waits for MariaDB to be ready, then uses **WP-CLI** to download WordPress, generate `wp-config.php`, run the installation, and create two users: an administrator (`manager`) and an editor (`editor`). On subsequent boots it skips the install and starts PHP-FPM directly. WordPress files are stored in a shared volume also mounted by NGINX.

**MariaDB** (`srcs/requirements/mariadb/`)
MariaDB is the relational database that stores all WordPress content — posts, pages, users, settings, and metadata. It runs on port 3306 and is only reachable from within the Docker network (not exposed to the host). On first boot, the entrypoint script (`init.sh`) initializes the data directory, sets the root password, creates the `wordpress` database, and creates the `wpuser` account with the appropriate grants. Database files are stored in a dedicated volume that persists across container restarts.

### Main Design Choices

- **One process per container**: each container runs a single foreground process (`nginx -g 'daemon off'`, `php-fpm8.2 -F`, `mysqld`), following Docker best practices. No `tail -f`, `sleep infinity`, or background daemons.
- **Credentials via Docker Secrets**: passwords are mounted as files in `/run/secrets/` at runtime and read by the init scripts. They are never passed as environment variables and never appear in Dockerfiles or the compose file.
- **Healthchecks + `depends_on`**: startup ordering is enforced by Docker's healthcheck mechanism rather than arbitrary `sleep` calls, making the boot sequence reliable.
- **WP-CLI for WordPress setup**: instead of a web-based installer, the entire WordPress configuration is automated via WP-CLI in the entrypoint script, enabling fully reproducible and scriptable deployments.

### Comparisons

#### Virtual Machines vs Docker
A Virtual Machine virtualizes an entire operating system including the kernel, making it heavier and slower to start. Docker uses OS-level containerization — containers share the host kernel and are isolated via namespaces and cgroups. Docker is faster, lighter, and more reproducible, but VMs offer stronger isolation. In this project, Docker runs **inside** a VM to combine both layers of separation.

#### Secrets vs Environment Variables
Environment variables are accessible to any process in the container and can leak through logs or inspection (`docker inspect` reveals them in plain text). Docker Secrets mount sensitive data as files in `/run/secrets/`, which are only accessible to the container at runtime and never stored in images or compose files. All passwords in this project (MariaDB and WordPress passwords) are passed via Secrets.

#### Docker Network vs Host Network
`network: host` removes network isolation — the container shares the host's network stack directly, exposing all ports and bypassing Docker's routing. A custom Docker bridge network (`inception`) isolates containers so they can communicate by service name (e.g., `mariadb:3306`, `wordpress:9000`) while remaining unreachable from outside except through the defined port (443 on NGINX). `network: host` and `--link` are explicitly forbidden by the subject.

#### Docker Volumes vs Bind Mounts
Bind mounts link a specific host directory directly into the container — straightforward but tightly coupled to the host's filesystem layout. Docker named volumes are managed by Docker and abstracted from the host path. This project uses **bind-mount-backed named volumes**: named volumes in `docker-compose.yml` configured with `type: none` and `o: bind` pointing to `/home/jcologne/data/wordpress` and `/home/jcologne/data/mariadb`. This gives the portability and explicitness of named volumes while keeping data at a known host location.

---

## Instructions

### Prerequisites

- Docker and Docker Compose installed
- `sudo` access (for creating data directories)
- Domain `jcologne.42.fr` resolving to `127.0.0.1` — add to `/etc/hosts`:
  ```
  127.0.0.1 jcologne.42.fr
  ```

### Setup

1. Clone the repository and navigate to the project root.

2. Create the secrets files (they are gitignored and must be created manually):
   ```bash
   echo "your_db_password" > secrets/db_password.txt
   echo "your_db_root_password" > secrets/db_root_password.txt
   printf "WORDPRESS_ADMIN_PASSWORD=your_admin_pass\nWORDPRESS_USER_PASSWORD=your_user_pass" > secrets/credentials.txt
   ```

3. Edit `srcs/.env` if needed to change domain, usernames, or emails.

4. Build and start the mandatory services:
   ```bash
   make
   ```

5. Access the site at `https://jcologne.42.fr` (accept the self-signed certificate warning).

### Makefile Targets

| Target | Description |
|--------|-------------|
| `make` / `make all` | Build and start NGINX, WordPress, MariaDB |
| `make bonus` | Start all services including Redis, FTP, Adminer, Static Site, Portainer |
| `make clean` | Stop and remove containers |
| `make fclean` | Full cleanup: containers, volumes, images, and data directories |
| `make re` | Full rebuild from scratch |

---

## Resources

### Documentation
- [Docker official docs](https://docs.docker.com/)
- [Docker Compose reference](https://docs.docker.com/compose/)
- [NGINX docs](https://nginx.org/en/docs/)
- [WP-CLI commands](https://developer.wordpress.org/cli/commands/)
- [MariaDB Docker setup](https://mariadb.com/kb/en/installing-and-using-mariadb-via-docker/)
- [PHP-FPM configuration](https://www.php.net/manual/en/install.fpm.configuration.php)
- [Docker Secrets](https://docs.docker.com/engine/swarm/secrets/)
- [PID 1 and init systems in containers](https://cloud.google.com/architecture/best-practices-for-building-containers#signal-handling)
