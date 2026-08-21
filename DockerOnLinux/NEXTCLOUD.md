# Nextcloud + OnlyOffice + Whiteboard on Docker for Linux  

Please note I plan on adding a bunch of more details to this guide, including Nextcloud Talk and other instructions later on. I highly recommend using a service like dynu.com (4 free subdomains and unlimited sub-subdomains) instead of no-ip or namecheap.com for a paid service for unlimited subdomains per paid domain name and unlimited sub-subdomains.

A step‑by‑step guide to run **Nextcloud**, **OnlyOffice Document Server**, and the **Nextcloud Whiteboard** behind a **SWAG (Secure Web‑Application Gateway)** reverse proxy.  
All sensitive values (passwords, secrets, domain names, etc.) are replaced with environment variables that you define in a `.env` file.

---  

## Table of Contents  

1. [Prerequisites](#prerequisites)  
2. [Directory layout](#directory-layout)  
3. [Create a `.env` file](#create-a-env-file)  
4. [Docker Compose file](#docker-compose-file)  
5. [SWAG (NGINX) configuration](#swag-nginx-configuration)  
6. [Initialize the containers](#initialize-the-containers)  
7. [Configure Nextcloud via `occ`](#configure-nextcloud-via-occ)  
8. [Configure OnlyOffice JWT](#configure-onlyoffice-jwt)  
9. [Whiteboard WebSocket configuration](#whiteboard-websocket-configuration)  
10. [Maintenance tips](#maintenance-tips)  
11. [Troubleshooting checklist](#troubleshooting-checklist)  

---  

## Prerequisites  

| Requirement | Why it’s needed |
|------------|-----------------|
| Docker ≥ 20.10 & Docker‑Compose | Runs the services in isolated containers |
| A domain name (e.g., `nextcloud.example.com`) | Public HTTPS endpoint |
| DNS A‑record pointing to your host’s IP | Lets the reverse proxy obtain certificates |
| Port 80 and 443 open on the host | Required for Let’s Encrypt challenges and HTTPS traffic |
| Basic knowledge of Linux command line | To edit files, run `docker` commands, and use `occ` |

---  

## Directory layout  

```
project-root/
├─ docker-compose.yml
├─ .env               # **personal values go here**
├─ swag/
│  ├─ nginx/
│  │  ├─ nextcloud.subdomain.conf
│  │  └─ onlyoffice.subdomain.conf
│  └─ config/
│     └─ nginx/       # default SWAG files (ssl.conf, proxy.conf, etc.)
└─ README.md          # <-- this file
```

All files referenced below are placed relative to `project‑root`.

---  

## Create a `.env` file  

Copy the template below into `project-root/.env` and replace the placeholders with your own values. **Do not commit this file to a public repository.**

```dotenv
# ── General ─────────────────────────────────────────────────────
DOMAIN=example.com               # your base domain, e.g. example.com
EMAIL=admin@example.com          # email for Let's Encrypt notifications

# ── Nextcloud ───────────────────────────────────────────────────
POSTGRES_DB=nextcloud
POSTGRES_USER=nextcloud_user
POSTGRES_PASSWORD=SuperSecretDBPassword
NEXTCLOUD_ADMIN_USER=admin
NEXTCLOUD_ADMIN_PASSWORD=SuperSecretAdminPassword
NEXTCLOUD_TRUSTED_DOMAINS=nextcloud.${DOMAIN}

# ── OnlyOffice DB ─────────────────────────────────────────────────
ONLYOFFICE_DB_PASSWORD=OnlyOfficeDBPass

# ── OnlyOffice JWT ─────────────────────────────────────────────────
JWT_SECRET=$(openssl rand -base64 32)   # or generate at https://jwtsecrets.com/#generator
# The JWT token itself is generated on‑the‑fly by OnlyOffice; keep the secret safe.

# ── Redis ───────────────────────────────────────────────────────
REDIS_HOST_PASSWORD=RedisSecretPass

# ── RabbitMQ ─────────────────────────────────────────────────────
RABBITMQ_USER=rabbituser
RABBITMQ_PASSWORD=RabbitSecretPass

# ── Whiteboard ───────────────────────────────────────────────────
WHITEBOARD_JWT_SECRET=$(openssl rand -base64 32)
```

> **Tip:** The `openssl` commands generate random base‑64 strings that are suitable for JWT secrets. You can also use the online generator at **https://jwtsecrets.com/#generator**.

---  

## Docker Compose file  

Save the following as `docker-compose.yml` in the project root. It pulls official images, creates two Docker networks (`webnet` for the reverse proxy and `internal_net` for inter‑service traffic), and defines persistent volumes.

```yaml
version: "3.9"

services:
  # -------------------------------------------------
  # PostgreSQL – Nextcloud database
  # -------------------------------------------------
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
      test: ["CMD-SHELL", "pg_isready -U $${POSTGRES_USER} -d $${POSTGRES_DB}"]
      interval: 10s
      timeout: 5s
      retries: 5

  # -------------------------------------------------
  # Redis – Nextcloud cache / file locking
  # -------------------------------------------------
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
      test: ["CMD", "redis-cli", "--no-auth-warning", "-a", "${REDIS_HOST_PASSWORD}", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  # -------------------------------------------------
  # Nextcloud
  # -------------------------------------------------
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
      - "5080:80"                # optional local testing port
    volumes:
      - nextcloud:/var/www/html
      - /media/ncdata/external_data1:/mnt/data_main1
      - /media/ncdata/external_data2:/mnt/data_main2
    networks:
      - webnet
      - internal_net

  # -------------------------------------------------
  # OnlyOffice Document Server
  # -------------------------------------------------
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

  # -------------------------------------------------
  # OnlyOffice PostgreSQL
  # -------------------------------------------------
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
      test: ["CMD-SHELL", "pg_isready -U onlyoffice -d onlyoffice"]
      interval: 10s
      timeout: 5s
      retries: 5

  # -------------------------------------------------
  # OnlyOffice RabbitMQ
  # -------------------------------------------------
  onlyoffice-rabbitmq:
    container_name: onlyoffice-rabbitmq
    image: rabbitmq:3-management-alpine
    restart: unless-stopped
    environment:
      RABBITMQ_DEFAULT_USER: ${RABBITMQ_USER}
      RABBITMQ_DEFAULT_PASS: ${RABBITMQ_PASSWORD}
    networks:
      - internal_net

  # -------------------------------------------------
  # Nextcloud Whiteboard WebSocket Server
  # -------------------------------------------------
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

  # -------------------------------------------------
  # SWAG – Secure Web‑Application Gateway (NGINX + Let's Encrypt)
  # -------------------------------------------------
  swag:
    container_name: swag
    image: ghcr.io/linuxserver/swag:latest
    cap_add:
      - NET_ADMIN
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
      - URL=${DOMAIN}          # primary domain for the root cert (optional)
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

networks:
  webnet:
    external: true               # created once with your reverse‑proxy network
  internal_net:
    driver: bridge

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

> **Important:** The `webnet` network must already exist (created by your existing reverse‑proxy stack). Use `docker network create webnet` if it does not.

---  

## SWAG (NGINX) configuration  

Place the two site‑conf files in `swag/nginx/` as shown in the directory layout.

### `onlyoffice.subdomain.conf`

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

### `nextcloud.subdomain.conf`

```nginx
server {
    listen 443 ssl;
    listen [::]:443 ssl;

    server_name nextcloud.*;

    include /config/nginx/ssl.conf;

    client_max_body_size 0;   # nextcloud handles its own limits

    # ---------- Whiteboard WebSocket ----------
    location /whiteboard/ {
        set $upstream_app   whiteboard;
        set $upstream_port  3002;
        set $upstream_proto http;

        proxy_pass $upstream_proto://$upstream_app:$upstream_port/;

        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";

        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        include /config/nginx/proxy.conf;
        include /config/nginx/resolver.conf;
    }

    # ---------- Main Nextcloud application ----------
    location / {
        set $upstream_app   nextcloud;
        set $upstream_port  80;
        set $upstream_proto http;

        proxy_pass $upstream_proto://$upstream_app:$upstream_port;

        # Hide headers that collide with generic SSL block
        proxy_hide_header Referrer-Policy;
        proxy_hide_header X-Content-Type-Options;
        proxy_hide_header X-Frame-Options;
        proxy_hide_header X-XSS-Protection;

        include /config/nginx/proxy.conf;
        include /config/nginx/resolver.conf;
    }
}
```

After editing, **restart the SWAG container**:  

```bash
docker restart swag
```

---  

## Initialize the containers  

```bash
# From the project‑root directory
docker compose pull      # fetch latest images
docker compose up -d    # start everything in detached mode
```

Wait a minute for health checks to pass (`docker compose ps`).  

---  

## Configure Nextcloud via `occ`  

Enter the Nextcloud container as root, then run the configuration commands.  

```bash
docker exec -it --user root nextcloud bash
cd /var/www/html
```

### 1. Reverse‑proxy / external URL settings  

```bash
php occ config:system:set overwrite.cli.url --value="https://nextcloud.${DOMAIN}"
php occ config:system:set overwritehost --value="nextcloud.${DOMAIN}"
php occ config:system:set overwriteprotocol --value="https"
```

### 2. Trusted proxy  

Find the SWAG container’s IP on the `webnet` network:

```bash
docker inspect swag --format '{{range $k, $v := .NetworkSettings.Networks}}{{$k}}: {{$v.IPAddress}}{{"\n"}}{{end}}'
```

Assume the output is `webnet: 172.20.0.2`. Apply it:

```bash
php occ config:system:set trusted_proxies 0 --value="172.20.0.2"
```

If the IP changes after a container rebuild, repeat the step.

### 3. Trusted domains  

```bash
php occ config:system:set trusted_domains 0 --value="localhost"
php occ config:system:set trusted_domains 1 --value="nextcloud.${DOMAIN}"
```

### 4. Verify settings  

```bash
php occ config:system:get overwrite.cli.url
php occ config:system:get overwritehost
php occ config:system:get overwriteprotocol
php occ config:system:get trusted_proxies
php occ config:system:get trusted_domains
```

All should reflect the values you set.

---  

## Configure OnlyOffice JWT  

OnlyOffice needs a shared secret to validate the token that Nextcloud sends.

1. **Generate a secret** (if you haven’t already) using the online generator at **https://jwtsecrets.com/#generator** or locally with `openssl`.  

2. Add the secret to your `.env` as `JWT_SECRET`.  

3. The secret is already passed to the OnlyOffice container via `JWT_SECRET` env var (see Compose file).  

4. In Nextcloud, tell the OnlyOffice app to use JWT:

```bash
php occ config:app:set onlyoffice JWTSecret --value="${JWT_SECRET}"
php occ config:app:set onlyoffice DocumentServerUrl --value="https://onlyoffice.${DOMAIN}/"
php occ onlyoffice:documentserver --check
```

A successful test prints something like:  

```
Document server https://onlyoffice.example.com/ version 9.4.0.129 is successfully connected
```

---  

## Whiteboard WebSocket configuration  

The Whiteboard service authenticates through its own JWT secret.

1. Generate a secret (again, via the generator or `openssl`).  
2. Store it in `.env` as `WHITEBOARD_JWT_SECRET`.  
3. The environment variable is passed to the `whiteboard` container.  
4. In Nextcloud, enable the Whiteboard app and set the JWT secret:

```bash
php occ config:app:set whiteboard JWTSecret --value="${WHITEBOARD_JWT_SECRET}"
```

---  

## Maintenance tips  

| Task | Command |
|------|---------|
| List all system config keys | `php occ config:system:list` |
| List all app config keys | `php occ config:app:list` |
| Show enabled apps | `php occ app:list` |
| Put Nextcloud in maintenance mode | `php occ maintenance:mode --on` |
| Disable maintenance mode | `php occ maintenance:mode --off` |
| Run a manual data‑directory integrity check | `php occ integrity:check --output=json` |
| Clean up old Docker images | `docker image prune -af` |

---  

## Troubleshooting checklist  

- **HTTPS not working** – Verify that SWAG obtained a certificate (`docker logs swag`).  
- **“Forbidden – trusted domain” error** – Ensure `trusted_domains` includes your full sub‑domain.  
- **OnlyOffice “Bad request – JWT validation failed”** – Double‑check the `JWT_SECRET` value in `.env` and that it matches what you set in Nextcloud.  
- **Whiteboard cannot connect (WebSocket 502)** – Confirm the `whiteboard` container is reachable on port 3002 via the `whiteboard` service name (NGINX upstream).  
- **Database connection errors** – Verify that the `.env` values for PostgreSQL (`POSTGRES_*`) line up with the `db` service.  
- **Container restarts repeatedly** – Look at `docker compose logs <service>` for health‑check failures and adjust passwords or network settings.

---  

### 🎉 You’re all set!  

Your self‑hosted suite now provides:

- **Nextcloud** for file sync, sharing, and collaboration  
- **OnlyOffice** for in‑browser editing of Office documents, secured with JWT  
- **Whiteboard** for real‑time collaborative drawing (WebSocket)  

All traffic is encrypted end‑to‑end via Let’s Encrypt certificates managed by SWAG. Enjoy a fully private productivity stack!
