# User Documentation — Inception

This document explains how to use and operate the Inception infrastructure as an end user or administrator.

---

## What Services Are Provided

The stack runs three services accessible through a single HTTPS entry point:

| Service | Description | Access |
|---------|-------------|--------|
| **WordPress** | Content management system | `https://jcologne.42.fr` |
| **WordPress Admin Panel** | Site administration | `https://jcologne.42.fr/wp-admin` |
| **MariaDB** | Database (internal only) | Not publicly accessible |

All traffic goes through **NGINX on port 443** using HTTPS (TLS 1.2/1.3). There is no HTTP access.

---

## Starting and Stopping the Project

### Start
From the project root directory:
```bash
make
```
This builds the Docker images and starts all three containers. On first run, WordPress is automatically downloaded and configured — this may take a minute or two.

### Stop (keep data)
```bash
make clean
```
Stops and removes the containers. All data in the volumes is preserved.

### Full reset (delete all data)
```bash
make fclean
```
⚠️ This removes containers, images, volumes, **and all site data**. Use only when you want to start completely fresh.

### Restart from scratch
```bash
make re
```
Equivalent to `fclean` followed by `make`.

---

## Accessing the Website

1. Make sure `jcologne.42.fr` is in your `/etc/hosts` file:
   ```
   127.0.0.1   jcologne.42.fr
   ```

2. Open your browser and go to:
   ```
   https://jcologne.42.fr
   ```

3. Your browser will warn about the self-signed certificate. This is expected — click **"Advanced"** and **"Accept the risk"** (or equivalent in your browser) to proceed.

---

## Accessing the Administration Panel

Go to `https://jcologne.42.fr/wp-admin` and log in with the admin credentials.

The site has two user accounts:

| Role | Username | Description |
|------|----------|-------------|
| Administrator | `manager` | Full access to all WordPress settings |
| Editor | `editor` | Can create and edit posts, but cannot change site settings |

---

## Locating and Managing Credentials

Credentials are stored in the `secrets/` directory at the project root. These files are **never committed to Git**.

| File | Contents |
|------|----------|
| `secrets/db_password.txt` | MariaDB password for the `wpuser` account |
| `secrets/db_root_password.txt` | MariaDB root password |
| `secrets/credentials.txt` | WordPress admin and editor passwords |

The format of `credentials.txt` is:
```
WORDPRESS_ADMIN_PASSWORD=your_password_here
WORDPRESS_USER_PASSWORD=your_password_here
```

To change a password after the site is already set up, you must run `make fclean` and then rebuild with the new values — or change the password directly through the WordPress admin panel or via WP-CLI.

---

## Checking That Services Are Running

### Check container status
```bash
docker ps
```
All three containers (`nginx`, `wordpress`, `mariadb`) should appear with status `Up` and a healthy healthcheck.

### Check a specific container's logs
```bash
docker logs nginx
docker logs wordpress
docker logs mariadb
```

### Check NGINX is responding
```bash
curl -fsk https://jcologne.42.fr/health
```
Should return `OK`.

### Check MariaDB is responding
```bash
docker exec mariadb mysqladmin ping -h localhost --silent
```
Should return `mysqld is alive`.

### Check WordPress (PHP-FPM) is running
```bash
docker exec wordpress pgrep php-fpm
```
Should return one or more process IDs.