# Nextcloud + OnlyOffice + Whiteboard on Docker for Linux

A practical guide for running **Nextcloud**, **OnlyOffice Document Server**, and **Nextcloud Whiteboard** with Docker, PostgreSQL, Redis, RabbitMQ, and **SWAG (NGINX + Let's Encrypt)**.

This guide is intended to be adaptable rather than tied to one specific server layout. The examples use placeholder domains, paths, usernames, and passwords that you should replace with your own values.

> **Guide status:** This guide currently focuses on Nextcloud, OnlyOffice, Whiteboard, Docker networking, and SWAG. Additional sections such as Nextcloud Talk and other integrations can be added later.

---

## Table of Contents

1. [What This Guide Builds](#what-this-guide-builds)
2. [Architecture Overview](#architecture-overview)
3. [Prerequisites](#prerequisites)
4. [Public vs. LAN-Only Deployments](#public-vs-lan-only-deployments)
5. [DNS Configuration](#dns-configuration)
6. [Choosing a Reverse Proxy](#choosing-a-reverse-proxy)
7. [Directory Layout](#directory-layout)
8. [Docker Networks](#docker-networks)
9. [Create the `.env` File](#create-the-env-file)
10. [Generating Secrets](#generating-secrets)
11. [Docker Compose](#docker-compose)
12. [Understanding the Docker Compose File](#understanding-the-docker-compose-file)
13. [SWAG Configuration](#swag-configuration)
14. [Initial Startup](#initial-startup)
15. [Configure Nextcloud](#configure-nextcloud)
16. [Configure OnlyOffice](#configure-onlyoffice)
17. [Configure Whiteboard](#configure-whiteboard)
18. [Verification](#verification)
19. [Security Considerations](#security-considerations)
20. [Maintenance](#maintenance)
21. [Updating the Stack](#updating-the-stack)
22. [Backups](#backups)
23. [Troubleshooting](#troubleshooting)
24. [Common Mistakes](#common-mistakes)
25. [Removing Optional Components](#removing-optional-components)
26. [Useful `occ` Commands](#useful-occ-commands)
27. [Conclusion](#conclusion)

---

# What This Guide Builds

The completed deployment consists of several Docker containers working together:

| Component                 | Purpose                                                |
| ------------------------- | ------------------------------------------------------ |
| **Nextcloud**             | File synchronization, sharing, and collaboration       |
| **PostgreSQL**            | Nextcloud database                                     |
| **Redis**                 | Nextcloud caching and file locking                     |
| **OnlyOffice**            | Browser-based editing of Office documents              |
| **OnlyOffice PostgreSQL** | Database used by OnlyOffice                            |
| **RabbitMQ**              | Message broker used by OnlyOffice                      |
| **Whiteboard**            | Real-time collaborative drawing                        |
| **SWAG**                  | Reverse proxy and Let's Encrypt certificate management |

The goal is to expose only the web-facing services while keeping databases and other internal services on Docker's internal network.

---

# Architecture Overview

Before installing anything, it helps to understand how the components communicate.

The general architecture looks like this:

```text
                         Internet / LAN
                              │
                              │ HTTPS
                              ▼
                    ┌──────────────────┐
                    │       SWAG       │
                    │      NGINX       │
                    │   Ports 80/443   │
                    └────────┬─────────┘
                             │
                ┌────────────┼────────────┐
                │            │            │
                ▼            ▼            ▼
          ┌──────────┐ ┌───────────┐ ┌───────────┐
          │ Nextcloud│ │ OnlyOffice│ │ Whiteboard│
          │   :80    │ │    :80    │ │   :3002   │
          └────┬─────┘ └─────┬─────┘ └───────────┘
               │              │
        ┌──────┴──────┐  ┌────┴─────────┐
        │             │  │              │
        ▼             ▼  ▼              ▼
   PostgreSQL      Redis PostgreSQL   RabbitMQ
```

## Docker Networks

Two Docker networks are used:

### `webnet`

The reverse-proxy network.

Services connected to this network include:

* SWAG
* Nextcloud
* OnlyOffice
* Whiteboard

SWAG uses Docker's internal DNS to reach services by their Docker service name.

For example:

```text
nextcloud:80
onlyoffice:80
whiteboard:3002
```

### `internal_net`

The private service network.

It is used for communication between application containers and their supporting services:

```text
Nextcloud → PostgreSQL
Nextcloud → Redis

OnlyOffice → PostgreSQL
OnlyOffice → RabbitMQ
```

The databases and Redis do not need to be exposed directly to the host.

---

# Prerequisites

Before beginning, make sure you have the following.

| Requirement            | Why it is needed                        |
| ---------------------- | --------------------------------------- |
| Linux server           | Docker host                             |
| Docker                 | Runs the containers                     |
| Docker Compose         | Defines and manages the stack           |
| Domain name            | Provides stable hostnames               |
| DNS access             | Creates records for the services        |
| Persistent storage     | Stores databases and application data   |
| Basic Linux knowledge  | Required for commands and configuration |
| Basic Docker knowledge | Helpful when troubleshooting            |

For an Internet-facing installation, you will generally also need:

* A public IP address
* TCP port `80`
* TCP port `443`
* DNS records pointing to your server
* A firewall/router configuration allowing the required traffic

---

# Public vs. LAN-Only Deployments

This guide can be adapted for either an Internet-facing or LAN-only installation.

## Internet-Facing Installation

A typical Internet deployment looks like:

```text
Internet
   │
   ▼
Router / Firewall
   │
   │ TCP 80/443
   ▼
SWAG
   │
   ├── Nextcloud
   ├── OnlyOffice
   └── Whiteboard
```

In this configuration:

* DNS points your domain to your public IP.
* Your router forwards TCP 80/443 to the server.
* SWAG obtains and manages Let's Encrypt certificates.
* Only SWAG needs to be directly exposed to the Internet.

---

## LAN-Only Installation

For a private home network, you may not need to expose the server to the Internet.

A LAN-only deployment can instead look like:

```text
LAN
 │
 ├── Client PC
 ├── Phone
 └── Tablet
       │
       ▼
     SWAG
       │
       ├── Nextcloud
       ├── OnlyOffice
       └── Whiteboard
```

Possible approaches include:

* Internal DNS
* A local DNS server
* Hosts-file entries
* An internal certificate authority
* A VPN

The exact certificate and DNS setup depends on how you want clients to access the services.

---

# DNS Configuration

You will normally want separate hostnames for Nextcloud and OnlyOffice.

For example:

```text
nextcloud.example.com
onlyoffice.example.com
```

Both records should point to the server that runs SWAG.

For a public installation:

```text
nextcloud.example.com  → PUBLIC_IP
onlyoffice.example.com → PUBLIC_IP
```

A wildcard record can also be used:

```text
*.example.com → PUBLIC_IP
```

The exact DNS configuration depends on your DNS provider.

## DNS vs. Port Forwarding

These are separate concepts.

**DNS answers:**

> "Where is this hostname located?"

**Port forwarding answers:**

> "How does traffic from the Internet reach my server?"

For example:

```text
nextcloud.example.com
        │
        ▼
   Public IP
        │
        ▼
Router port forwarding
        │
        ▼
Server TCP 443
        │
        ▼
SWAG
```

---

# Choosing a Reverse Proxy

This guide uses **SWAG**, but it is not the only option.

Common choices include:

| Reverse Proxy           | General Characteristics                                   |
| ----------------------- | --------------------------------------------------------- |
| **SWAG**                | NGINX-based and integrates well with Docker               |
| **Caddy**               | Simple configuration and automatic HTTPS                  |
| **Traefik**             | Strong Docker integration and automatic service discovery |
| **NGINX Proxy Manager** | GUI-based NGINX configuration                             |
| **Direct exposure**     | Simpler, but provides less centralized proxy management   |

This guide uses SWAG because it provides:

* NGINX
* Let's Encrypt integration
* Reverse proxy functionality
* Persistent configuration
* Docker-based deployment

If you already have a reverse proxy running, you generally do not need to deploy another one just for this stack.

---

# Directory Layout

Create a project directory for the stack.

For example:

```text
project-root/
├── docker-compose.yml
├── .env
├── swag/
│   ├── nginx/
│   │   ├── nextcloud.subdomain.conf
│   │   └── onlyoffice.subdomain.conf
│   └── config/
│       └── nginx/
└── README.md
```

All paths in this guide are relative to `project-root`.

You can use a different directory structure if desired. The important part is that the paths in `docker-compose.yml` match your actual filesystem.

---

# Docker Networks

The Compose configuration expects an external Docker network named:

```text
webnet
```

If this network does not already exist:

```bash
docker network create webnet
```

Verify it:

```bash
docker network ls
```

You should see:

```text
webnet
```

## Why is `webnet` external?

The purpose of making `webnet` external is to allow this stack to communicate with an existing reverse-proxy stack.

For example:

```text
Other Docker Services
        │
        ▼
     webnet
        ▲
        │
This Nextcloud Stack
```

If you are deploying SWAG and this stack together for the first time, you can create `webnet` manually as shown above.

---

# Create the `.env` File

Create:

```text
project-root/.env
```

Do not commit this file to a public repository.

It contains passwords and authentication secrets.

Use the following as a starting point:

```dotenv
# ============================================================
# General
# ============================================================

DOMAIN=example.com
EMAIL=admin@example.com


# ============================================================
# Nextcloud PostgreSQL
# ============================================================

POSTGRES_DB=nextcloud
POSTGRES_USER=nextcloud_user
POSTGRES_PASSWORD=CHANGE_ME


# ============================================================
# Nextcloud Administrator
# ============================================================

NEXTCLOUD_ADMIN_USER=admin
NEXTCLOUD_ADMIN_PASSWORD=CHANGE_ME

NEXTCLOUD_TRUSTED_DOMAINS=nextcloud.${DOMAIN}


# ============================================================
# OnlyOffice PostgreSQL
# ============================================================

ONLYOFFICE_DB_PASSWORD=CHANGE_ME


# ============================================================
# OnlyOffice JWT
# ============================================================

JWT_SECRET=CHANGE_ME


# ============================================================
# Redis
# ============================================================

REDIS_HOST_PASSWORD=CHANGE_ME


# ============================================================
# RabbitMQ
# ============================================================

RABBITMQ_USER=rabbituser
RABBITMQ_PASSWORD=CHANGE_ME


# ============================================================
# Whiteboard
# ============================================================

WHITEBOARD_JWT_SECRET=CHANGE_ME
```

## What These Variables Do

| Variable                    | Purpose                                     |
| --------------------------- | ------------------------------------------- |
| `DOMAIN`                    | Base domain used to build service hostnames |
| `EMAIL`                     | Email address used by SWAG/Let's Encrypt    |
| `POSTGRES_DB`               | Nextcloud database name                     |
| `POSTGRES_USER`             | Nextcloud database user                     |
| `POSTGRES_PASSWORD`         | Nextcloud database password                 |
| `NEXTCLOUD_ADMIN_USER`      | Initial Nextcloud administrator             |
| `NEXTCLOUD_ADMIN_PASSWORD`  | Initial administrator password              |
| `NEXTCLOUD_TRUSTED_DOMAINS` | Hostnames Nextcloud accepts                 |
| `ONLYOFFICE_DB_PASSWORD`    | OnlyOffice PostgreSQL password              |
| `JWT_SECRET`                | OnlyOffice authentication secret            |
| `REDIS_HOST_PASSWORD`       | Redis authentication password               |
| `RABBITMQ_USER`             | RabbitMQ username                           |
| `RABBITMQ_PASSWORD`         | RabbitMQ password                           |
| `WHITEBOARD_JWT_SECRET`     | Whiteboard authentication secret            |

---

# Generating Secrets

Do not use the example passwords from this guide on an actual server.

For random secrets, you can use:

```bash
openssl rand -base64 32
```

For example:

```bash
openssl rand -base64 32
```

Copy the resulting value into `.env`.

You need to keep the following secrets consistent between the services that use them:

```text
JWT_SECRET
WHITEBOARD_JWT_SECRET
```

The OnlyOffice JWT secret must match between OnlyOffice and the Nextcloud OnlyOffice app.

The Whiteboard JWT secret must match between the Whiteboard container and its Nextcloud configuration.

> **Security:** Keep `.env` private. Treat it like a password file.

---

# Docker Compose

Create:

```text
project-root/docker-compose.yml
```

Use:

```yaml
version: "3.9"

services:

  # ==========================================================
  # PostgreSQL - Nextcloud
  # ==========================================================

  db:
    container_name: ncdb
    image: postgres:16-alpine
    restart: unless-stopped

    environment:
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}

    volumes:
      - db:/var/lib/postgresql/data

    networks:
      - internal_net

    healthcheck:
      test:
        [
          "CMD-SHELL",
          "pg_isready -U $${POSTGRES_USER} -d $${POSTGRES_DB}"
        ]
      interval: 10s
      timeout: 5s
      retries: 5


  # ==========================================================
  # Redis - Nextcloud cache / file locking
  # ==========================================================

  redis:
    container_name: ncredis
    image: redis:7-alpine
    restart: unless-stopped

    command:
      - redis-server
      - --requirepass
      - ${REDIS_HOST_PASSWORD}

    networks:
      - internal_net

    healthcheck:
      test:
        [
          "CMD",
          "redis-cli",
          "--no-auth-warning",
          "-a",
          "${REDIS_HOST_PASSWORD}",
          "ping"
        ]
      interval: 10s
      timeout: 5s
      retries: 5


  # ==========================================================
  # Nextcloud
  # ==========================================================

  nextcloud:
    container_name: nextcloud
    image: nextcloud:31-apache
    restart: unless-stopped

    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_healthy

    environment:
      NEXTCLOUD_ADMIN_USER: ${NEXTCLOUD_ADMIN_USER}
      NEXTCLOUD_ADMIN_PASSWORD: ${NEXTCLOUD_ADMIN_PASSWORD}
      NEXTCLOUD_TRUSTED_DOMAINS: ${NEXTCLOUD_TRUSTED_DOMAINS}

      POSTGRES_HOST: db
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}

      REDIS_HOST: redis
      REDIS_HOST_PASSWORD: ${REDIS_HOST_PASSWORD}

    ports:
      - "5080:80"

    volumes:
      - nextcloud:/var/www/html
      - /media/ncdata/external_data1:/mnt/data_main1
      - /media/ncdata/external_data2:/mnt/data_main2

    networks:
      - webnet
      - internal_net


  # ==========================================================
  # OnlyOffice Document Server
  # ==========================================================

  onlyoffice:
    container_name: onlyoffice
    image: onlyoffice/documentserver:latest
    restart: unless-stopped

    depends_on:
      onlyoffice-db:
        condition: service_healthy
      onlyoffice-rabbitmq:
        condition: service_started

    environment:
      DB_TYPE: postgres
      DB_HOST: onlyoffice-db
      DB_PORT: 5432
      DB_NAME: onlyoffice
      DB_USER: onlyoffice
      DB_PASSWORD: ${ONLYOFFICE_DB_PASSWORD}

      AMQP_URI: amqp://${RABBITMQ_USER}:${RABBITMQ_PASSWORD}@onlyoffice-rabbitmq:5672

      VIRTUAL_HOST: onlyoffice.${DOMAIN}
      LETSENCRYPT_HOST: onlyoffice.${DOMAIN}
      LETSENCRYPT_EMAIL: ${EMAIL}

      JWT_ENABLED: "true"
      JWT_SECRET: ${JWT_SECRET}
      JWT_HEADER: Authorization
      JWT_IN_BODY: "true"

    ports:
      - "8080:80"

    volumes:
      - onlyoffice-data:/var/www/onlyoffice/Data
      - onlyoffice-logs:/var/log/onlyoffice
      - onlyoffice-cache:/var/lib/onlyoffice/documentserver/App_Data/cache/files
      - onlyoffice-files:/var/www/onlyoffice/documentserver-example/public/files
      - fonts:/usr/share/fonts

    networks:
      - webnet
      - internal_net


  # ==========================================================
  # OnlyOffice PostgreSQL
  # ==========================================================

  onlyoffice-db:
    container_name: onlyoffice-db
    image: postgres:16-alpine
    restart: unless-stopped

    environment:
      POSTGRES_DB: onlyoffice
      POSTGRES_USER: onlyoffice
      POSTGRES_PASSWORD: ${ONLYOFFICE_DB_PASSWORD}

    volumes:
      - onlyoffice-pg:/var/lib/postgresql/data

    networks:
      - internal_net

    healthcheck:
      test:
        [
          "CMD-SHELL",
          "pg_isready -U onlyoffice -d onlyoffice"
        ]
      interval: 10s
      timeout: 5s
      retries: 5


  # ==========================================================
  # OnlyOffice RabbitMQ
  # ==========================================================

  onlyoffice-rabbitmq:
    container_name: onlyoffice-rabbitmq
    image: rabbitmq:3-management-alpine
    restart: unless-stopped

    environment:
      RABBITMQ_DEFAULT_USER: ${RABBITMQ_USER}
      RABBITMQ_DEFAULT_PASS: ${RABBITMQ_PASSWORD}

    networks:
      - internal_net


  # ==========================================================
  # Nextcloud Whiteboard
  # ==========================================================

  whiteboard:
    container_name: whiteboard
    image: ghcr.io/nextcloud-releases/whiteboard:stable
    restart: unless-stopped

    depends_on:
      - nextcloud

    environment:
      NEXTCLOUD_URL: https://nextcloud.${DOMAIN}
      JWT_SECRET_KEY: ${WHITEBOARD_JWT_SECRET}

    networks:
      - webnet


  # ==========================================================
  # SWAG - NGINX + Let's Encrypt
  # ==========================================================

  swag:
    container_name: swag
    image: ghcr.io/linuxserver/swag:latest

    cap_add:
      - NET_ADMIN

    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
      - URL=${DOMAIN}
      - VALIDATION=http
      - EMAIL=${EMAIL}

    volumes:
      - ./swag/config:/config
      - ./swag/nginx/nextcloud.subdomain.conf:/config/nginx/site-confs/nextcloud.subdomain.conf:ro
      - ./swag/nginx/onlyoffice.subdomain.conf:/config/nginx/site-confs/onlyoffice.subdomain.conf:ro

    ports:
      - "80:80"
      - "443:443"

    networks:
      - webnet

    restart: unless-stopped


# ============================================================
# Networks
# ============================================================

networks:

  webnet:
    external: true

  internal_net:
    driver: bridge


# ============================================================
# Volumes
# ============================================================

volumes:

  db:
  nextcloud:

  onlyoffice-data:
  onlyoffice-logs:
  onlyoffice-cache:
  onlyoffice-files:
  fonts:
  onlyoffice-pg:
```

---

# Understanding the Docker Compose File

You do not need to memorize the entire Compose file. Each service has a specific purpose.

## PostgreSQL

```text
db
```

Stores the Nextcloud database.

It is connected only to:

```text
internal_net
```

It does not need to be publicly exposed.

---

## Redis

```text
redis
```

Provides caching and file-locking functionality for Nextcloud.

It is also internal-only.

---

## Nextcloud

```text
nextcloud
```

This is the main application.

It connects to:

```text
db
redis
```

and also connects to:

```text
webnet
```

so SWAG can proxy requests to it.

---

## OnlyOffice

```text
onlyoffice
```

Provides the browser-based document editing service.

It connects to:

```text
onlyoffice-db
onlyoffice-rabbitmq
```

and `webnet`.

---

## RabbitMQ

RabbitMQ provides the message broker used by OnlyOffice.

It does not need to be publicly exposed.

---

## Whiteboard

Whiteboard provides collaborative drawing functionality.

It listens internally on:

```text
3002
```

SWAG exposes it through:

```text
/whiteboard/
```

on the Nextcloud hostname.

---

## SWAG

SWAG is the public entry point.

It handles:

* HTTP
* HTTPS
* TLS certificates
* Reverse proxying
* WebSocket proxying

Ideally, Internet traffic only needs to reach SWAG.

---

# Ports: Host vs. Container

Docker port mappings use this format:

```text
HOST_PORT:CONTAINER_PORT
```

For example:

```yaml
ports:
  - "5080:80"
```

means:

```text
Server port 5080
       │
       ▼
Container port 80
```

The Nextcloud container itself listens on port `80`.

The host can optionally expose that as port `5080`.

However, SWAG does **not** need to use:

```text
localhost:5080
```

Instead, it can communicate directly with the container:

```text
http://nextcloud:80
```

through Docker networking.

---

# Do I Need `ports:` for Every Service?

No.

Only services that need to be accessed from the Docker host or outside the Docker networks need host port mappings.

For this setup:

| Service    | Host Port   | Reason                        |
| ---------- | ----------- | ----------------------------- |
| SWAG       | `80`, `443` | Public HTTPS/HTTP entry point |
| Nextcloud  | `5080`      | Optional direct testing       |
| OnlyOffice | `8080`      | Optional direct testing       |
| PostgreSQL | None        | Docker-internal               |
| Redis      | None        | Docker-internal               |
| RabbitMQ   | None        | Docker-internal               |
| Whiteboard | None        | Accessed through SWAG         |

If you do not need direct testing access to Nextcloud or OnlyOffice, the `5080` and `8080` mappings can be removed.

---

# SWAG Configuration

Create:

```text
swag/nginx/onlyoffice.subdomain.conf
```

with:

```nginx
server {
    listen 443 ssl;
    listen [::]:443 ssl;

    server_name onlyoffice.*;

    include /config/nginx/ssl.conf;

    client_max_body_size 0;

    location / {
        include /config/nginx/proxy.conf;
        include /config/nginx/resolver.conf;

        set $upstream_app onlyoffice;
        set $upstream_port 80;
        set $upstream_proto http;

        proxy_pass $upstream_proto://$upstream_app:$upstream_port;

        proxy_buffering off;
    }
}
```

---

## Nextcloud SWAG Configuration

Create:

```text
swag/nginx/nextcloud.subdomain.conf
```

with:

```nginx
server {
    listen 443 ssl;
    listen [::]:443 ssl;

    server_name nextcloud.*;

    include /config/nginx/ssl.conf;

    client_max_body_size 0;

    # ======================================================
    # Whiteboard WebSocket
    # ======================================================

    location /whiteboard/ {

        set $upstream_app whiteboard;
        set $upstream_port 3002;
        set $upstream_proto http;

        proxy_pass $upstream_proto://$upstream_app:$upstream_port/;

        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        include /config/nginx/proxy.conf;
        include /config/nginx/resolver.conf;
    }


    # ======================================================
    # Nextcloud
    # ======================================================

    location / {

        set $upstream_app nextcloud;
        set $upstream_port 80;
        set $upstream_proto http;

        proxy_pass $upstream_proto://$upstream_app:$upstream_port;

        proxy_hide_header Referrer-Policy;
        proxy_hide_header X-Content-Type-Options;
        proxy_hide_header X-Frame-Options;
        proxy_hide_header X-XSS-Protection;

        include /config/nginx/proxy.conf;
        include /config/nginx/resolver.conf;
    }
}
```

Restart SWAG:

```bash
docker restart swag
```

Then check its logs:

```bash
docker logs swag
```

---

# Why Does SWAG Proxy Using HTTP?

It is normal for the connection between SWAG and the application containers to use HTTP.

The flow is:

```text
Browser
   │
   │ HTTPS
   ▼
SWAG
   │
   │ HTTP over Docker network
   ▼
Nextcloud
```

TLS terminates at SWAG.

The Docker network is separate from the public connection.

The same concept applies to OnlyOffice:

```text
Browser
   │
   │ HTTPS
   ▼
SWAG
   │
   │ HTTP
   ▼
OnlyOffice
```

---

# Initial Startup

From `project-root`:

```bash
docker compose pull
```

Then:

```bash
docker compose up -d
```

Check the containers:

```bash
docker compose ps
```

You should see the services running.

For services with health checks, wait until they report:

```text
healthy
```

If a container is repeatedly restarting, check its logs before continuing.

For example:

```bash
docker compose logs nextcloud
```

or:

```bash
docker compose logs onlyoffice
```

---

# Configure Nextcloud

Enter the Nextcloud container:

```bash
docker exec -it --user root nextcloud bash
```

Then:

```bash
cd /var/www/html
```

---

## Configure the External URL

Run:

```bash
php occ config:system:set overwrite.cli.url \
  --value="https://nextcloud.${DOMAIN}"

php occ config:system:set overwritehost \
  --value="nextcloud.${DOMAIN}"

php occ config:system:set overwriteprotocol \
  --value="https"
```

These settings tell Nextcloud that its externally accessible address is HTTPS through the reverse proxy.

---

# Configure the Trusted Proxy

Find the SWAG container's IP address:

```bash
docker inspect swag \
  --format '{{range $k, $v := .NetworkSettings.Networks}}{{$k}}: {{$v.IPAddress}}{{"\n"}}{{end}}'
```

Example:

```text
webnet: 172.20.0.2
```

Use the returned address:

```bash
php occ config:system:set trusted_proxies 0 \
  --value="172.20.0.2"
```

> **Important:** Container IP addresses can change when containers are recreated. If the SWAG container receives a different IP, update this setting accordingly.

---

# Configure Trusted Domains

Run:

```bash
php occ config:system:set trusted_domains 0 \
  --value="localhost"

php occ config:system:set trusted_domains 1 \
  --value="nextcloud.${DOMAIN}"
```

Trusted domains prevent Nextcloud from accepting requests for unexpected hostnames.

---

# Verify Nextcloud Configuration

Run:

```bash
php occ config:system:get overwrite.cli.url
php occ config:system:get overwritehost
php occ config:system:get overwriteprotocol
php occ config:system:get trusted_proxies
php occ config:system:get trusted_domains
```

Verify that the values correspond to your actual deployment.

---

# Configure OnlyOffice

OnlyOffice uses JWT authentication to ensure that requests between Nextcloud and the Document Server are authenticated.

The secret must match on both sides.

First, make sure `.env` contains:

```dotenv
JWT_SECRET=your-generated-secret
```

The Compose file passes it to OnlyOffice:

```yaml
JWT_ENABLED: "true"
JWT_SECRET: ${JWT_SECRET}
JWT_HEADER: Authorization
JWT_IN_BODY: "true"
```

Inside the Nextcloud container, configure the OnlyOffice app:

```bash
php occ config:app:set onlyoffice JWTSecret \
  --value="${JWT_SECRET}"
```

Then configure the Document Server URL:

```bash
php occ config:app:set onlyoffice DocumentServerUrl \
  --value="https://onlyoffice.${DOMAIN}/"
```

Test the connection:

```bash
php occ onlyoffice:documentserver --check
```

A successful test should report that the document server is reachable.

---

# Configure Whiteboard

Whiteboard uses its own JWT secret.

Make sure `.env` contains:

```dotenv
WHITEBOARD_JWT_SECRET=your-generated-secret
```

The Compose file passes that secret to the Whiteboard container:

```yaml
JWT_SECRET_KEY: ${WHITEBOARD_JWT_SECRET}
```

Configure the corresponding Nextcloud setting:

```bash
php occ config:app:set whiteboard JWTSecret \
  --value="${WHITEBOARD_JWT_SECRET}"
```

Enable the Whiteboard app in Nextcloud if it is not already enabled.

---

# Verification

At this point, test each layer separately.

## 1. Docker

```bash
docker compose ps
```

All required containers should be running.

---

## 2. SWAG

Check:

```bash
docker logs swag
```

Look for certificate and NGINX errors.

---

## 3. Nextcloud

Open:

```text
https://nextcloud.example.com
```

You should reach the Nextcloud login page.

---

## 4. OnlyOffice

Open:

```text
https://onlyoffice.example.com
```

The OnlyOffice Document Server landing page should be accessible.

---

## 5. OnlyOffice Integration

From the Nextcloud container:

```bash
php occ onlyoffice:documentserver --check
```

A successful result confirms that Nextcloud can communicate with the configured Document Server.

---

## 6. Whiteboard

Open Whiteboard from Nextcloud and verify that the collaborative drawing interface loads.

If the browser reports a WebSocket problem, continue to the Whiteboard troubleshooting section below.

---

# Security Considerations

## Only expose what you need

For an Internet-facing deployment, the normal public entry points should be:

```text
TCP 80
TCP 443
```

Avoid forwarding internal service ports directly to the Internet.

For example, these generally do not need Internet exposure:

```text
5432  PostgreSQL
6379  Redis
5672  RabbitMQ
8080  OnlyOffice test port
5080  Nextcloud test port
3002  Whiteboard
```

---

## Protect `.env`

The `.env` file contains secrets.

Make sure it is not accidentally committed:

```gitignore
.env
```

If using Git, add this to `.gitignore`.

---

## Use Strong Passwords

Generate unique passwords for:

* PostgreSQL
* Nextcloud administrator
* OnlyOffice PostgreSQL
* Redis
* RabbitMQ
* JWT secrets

Do not reuse the same password everywhere.

---

# Maintenance

Enter the Nextcloud container:

```bash
docker exec -it --user root nextcloud bash
```

Then:

```bash
cd /var/www/html
```

Useful commands include:

### List system configuration

```bash
php occ config:system:list
```

### List application configuration

```bash
php occ config:app:list
```

### List installed/enabled apps

```bash
php occ app:list
```

### Enable maintenance mode

```bash
php occ maintenance:mode --on
```

### Disable maintenance mode

```bash
php occ maintenance:mode --off
```

### Check data integrity

```bash
php occ integrity:check --output=json
```

---

# Updating the Stack

Before performing updates, make sure you have a current backup.

Pull new images:

```bash
docker compose pull
```

Recreate containers:

```bash
docker compose up -d
```

Check their status:

```bash
docker compose ps
```

Then inspect logs if anything looks incorrect:

```bash
docker compose logs
```

## Version Tags

This Compose file uses a mixture of versioned and floating image tags.

For example:

```yaml
image: nextcloud:31-apache
```

versus:

```yaml
image: onlyoffice/documentserver:latest
```

Floating tags such as `latest` and `stable` can receive newer versions automatically.

### Floating tags

Advantages:

* Easier updates
* Less manual version management

Disadvantages:

* Updates may introduce unexpected changes
* Troubleshooting can become harder
* Reproducing an older deployment can be more difficult

### Pinned versions

Pinned versions provide more predictable deployments.

For a production environment, consider deciding on a version-management strategy rather than blindly updating every container whenever a new image appears.

---

# Backups

A working self-hosted server should have a backup strategy.

At minimum, consider backing up:

```text
Nextcloud database
Nextcloud application/configuration
Nextcloud user data
.env
OnlyOffice database
Other persistent Docker volumes that contain important data
```

The exact backup method depends on your storage and backup system.

## Important

A backup is not the same thing as a recovery plan.

Periodically test restoring your backups.

A backup that has never been restored is not proven to be usable.

---

# Troubleshooting

## HTTPS Does Not Work

Check:

```bash
docker logs swag
```

Then verify:

* DNS points to the correct IP
* TCP port 80 is reachable
* TCP port 443 is reachable
* The certificate was successfully obtained
* SWAG is running
* The NGINX configuration is valid

---

## "Trusted Domain" Error

Check:

```bash
php occ config:system:get trusted_domains
```

Make sure the hostname you are using appears in the list.

---

## 502 Bad Gateway

A `502` usually means the reverse proxy cannot successfully reach the upstream service.

Check:

```bash
docker compose ps
```

Then:

```bash
docker logs swag
```

Verify Docker DNS:

```bash
docker exec swag getent hosts nextcloud
```

and:

```bash
docker exec swag getent hosts onlyoffice
```

Also verify that the target containers are connected to `webnet`.

---

# OnlyOffice Troubleshooting

## JWT Validation Failed

Check the secret in `.env`:

```bash
grep JWT_SECRET .env
```

Then verify the secret configured in Nextcloud:

```bash
php occ config:app:get onlyoffice JWTSecret
```

The values need to correspond.

---

## OnlyOffice Cannot Connect

Run:

```bash
php occ onlyoffice:documentserver --check
```

Then check:

```bash
docker compose logs onlyoffice
```

Also verify:

```text
https://onlyoffice.example.com/
```

is reachable.

If Nextcloud can reach the public URL but OnlyOffice cannot reach Nextcloud, check the reverse direction as well.

---

# Whiteboard Troubleshooting

If Whiteboard reports a WebSocket error:

Check that the container is running:

```bash
docker compose ps whiteboard
```

Check its logs:

```bash
docker compose logs whiteboard
```

Verify that the container is connected to `webnet`.

The NGINX configuration should contain:

```nginx
proxy_set_header Upgrade $http_upgrade;
proxy_set_header Connection "upgrade";
```

The proxy should forward:

```text
/whiteboard/
```

to:

```text
whiteboard:3002
```

Also verify that the Whiteboard JWT secret matches between Nextcloud and the container.

---

# Database Troubleshooting

For Nextcloud:

```bash
docker compose logs db
```

For OnlyOffice:

```bash
docker compose logs onlyoffice-db
```

Check that the configured database names, users, and passwords match the corresponding `.env` values.

Also verify the health status:

```bash
docker compose ps
```

---

# Container Restart Loop

If a container repeatedly restarts:

```bash
docker compose ps
```

Then inspect its logs:

```bash
docker compose logs <service>
```

For example:

```bash
docker compose logs nextcloud
```

or:

```bash
docker compose logs onlyoffice
```

Common causes include:

* Incorrect passwords
* Missing environment variables
* Database initialization problems
* Permission problems
* Invalid configuration
* Network problems
* Failed health checks

---

# Common Mistakes

## Using `localhost` Between Containers

Inside Docker:

```text
localhost
```

means:

> This container.

It does **not** mean another container.

For example, Nextcloud should communicate with PostgreSQL using:

```text
db
```

rather than:

```text
localhost
```

Similarly, SWAG communicates with Nextcloud using:

```text
nextcloud
```

and with OnlyOffice using:

```text
onlyoffice
```

---

## Using Container IP Addresses

Avoid configuring services with hard-coded Docker IP addresses when a Docker service name can be used instead.

Prefer:

```text
http://nextcloud:80
```

over:

```text
http://172.20.0.5:80
```

Container IP addresses can change.

---

## Forgetting `webnet`

If SWAG cannot resolve:

```text
nextcloud
```

or:

```text
onlyoffice
```

verify that the services share the same Docker network.

```bash
docker network inspect webnet
```

---

## JWT Secrets Do Not Match

OnlyOffice and Nextcloud must use the same OnlyOffice JWT secret.

Whiteboard must likewise use the same Whiteboard JWT secret between the application and server.

---

## DNS Works but HTTPS Does Not

DNS resolution alone does not guarantee that traffic can reach the server.

Check both:

```text
DNS
↓
Public IP
↓
Firewall
↓
Port forwarding
↓
SWAG
```

---

# Removing Optional Components

Not every installation needs every service.

## Don't Need Whiteboard?

You can remove:

```text
whiteboard
```

from Compose and remove its NGINX location:

```nginx
location /whiteboard/
```

---

## Don't Need OnlyOffice?

You can remove:

```text
onlyoffice
onlyoffice-db
onlyoffice-rabbitmq
```

and their associated volumes.

You would also remove the OnlyOffice reverse-proxy configuration and the OnlyOffice app configuration from Nextcloud.

---

## Already Have PostgreSQL?

If you already operate a PostgreSQL server, you may be able to use it instead of deploying another PostgreSQL container.

The same concept applies to Redis.

However, externalizing these services changes the configuration and backup requirements, so make sure you understand the existing service before removing the bundled container.

---

# Useful `occ` Commands

Enter the container:

```bash
docker exec -it --user root nextcloud bash
```

Then:

```bash
cd /var/www/html
```

## Show Nextcloud Version

```bash
php occ status
```

## List Apps

```bash
php occ app:list
```

## List System Configuration

```bash
php occ config:system:list
```

## List Application Configuration

```bash
php occ config:app:list
```

## Enable Maintenance Mode

```bash
php occ maintenance:mode --on
```

## Disable Maintenance Mode

```bash
php occ maintenance:mode --off
```

## Check Integrity

```bash
php occ integrity:check --output=json
```

---

# Useful Docker Commands

## Show Running Containers

```bash
docker compose ps
```

## Follow Logs

```bash
docker compose logs -f
```

## Follow One Service

```bash
docker compose logs -f nextcloud
```

## Restart One Service

```bash
docker compose restart nextcloud
```

## Restart the Entire Stack

```bash
docker compose restart
```

## Pull Images

```bash
docker compose pull
```

## Recreate Containers

```bash
docker compose up -d
```

## Inspect Networks

```bash
docker network ls
```

```bash
docker network inspect webnet
```

## Remove Unused Docker Images

```bash
docker image prune -af
```

---

# Installation Checklist

Use this checklist when setting up a new server.

## Preparation

* [ ] Docker installed
* [ ] Docker Compose available
* [ ] Domain/subdomains selected
* [ ] DNS configured
* [ ] Storage locations created
* [ ] Firewall configured
* [ ] `.env` created
* [ ] Strong secrets generated
* [ ] `webnet` created

## Docker

* [ ] Compose file created
* [ ] Images pulled
* [ ] Containers started
* [ ] PostgreSQL healthy
* [ ] Redis healthy
* [ ] OnlyOffice database healthy
* [ ] Remaining containers running

## Reverse Proxy

* [ ] Nextcloud NGINX configuration created
* [ ] OnlyOffice NGINX configuration created
* [ ] SWAG started
* [ ] HTTPS certificate obtained
* [ ] Nextcloud hostname works
* [ ] OnlyOffice hostname works

## Nextcloud

* [ ] Trusted domains configured
* [ ] Trusted proxy configured
* [ ] External URL configured
* [ ] HTTPS overwrite configured

## OnlyOffice

* [ ] JWT enabled
* [ ] JWT secret configured
* [ ] Document Server URL configured
* [ ] `occ` connection test succeeds

## Whiteboard

* [ ] Whiteboard container running
* [ ] Whiteboard app enabled
* [ ] JWT configured
* [ ] WebSocket connection works

## Maintenance

* [ ] Backup procedure created
* [ ] Restore procedure tested
* [ ] Update procedure documented

---

# Conclusion

You now have a Docker-based collaboration stack consisting of:

* **Nextcloud** for file synchronization, sharing, and collaboration
* **PostgreSQL** for the Nextcloud database
* **Redis** for caching and file locking
* **OnlyOffice** for browser-based Office document editing
* **RabbitMQ** for OnlyOffice messaging
* **Whiteboard** for real-time collaborative drawing
* **SWAG** for reverse proxying and HTTPS

The important concepts to take away from this guide are not just the individual commands, but how the components fit together:

```text
                     HTTPS
                       │
                       ▼
                     SWAG
                       │
          ┌────────────┼────────────┐
          ▼            ▼            ▼
      Nextcloud     OnlyOffice   Whiteboard
          │            │
      ┌───┴───┐    ┌───┴────┐
      ▼       ▼    ▼        ▼
   Postgres Redis Postgres RabbitMQ
```

Once you understand that architecture, the individual configuration files become much easier to adapt to your own environment.

> **Remember:** There is no single "correct" Docker layout for every server. Use this guide as a starting point and adapt the networking, storage, reverse proxy, DNS, backup, and security configuration to your own environment.
