# Self-Hosting Reconboard v5

How to build, push, and deploy Reconboard on your own VPS/server.

---

## Prerequisites

**On your local machine (build box):**
- Docker + Docker Compose
- Git

**On your server:**
- Docker + Docker Compose
- A domain name (optional, for HTTPS)
- Ports 8443 (or 443) open in your firewall

---

## Step 1: Build the Images Locally

```bash
cd reconboard-v5

# Build both server and worker images
docker compose build
```

This takes 15-20 minutes the first time (Kali base + 50 tools).

---

## Step 2: Push to a Container Registry

Pick one of these options:

### Option A: Docker Hub

```bash
# Log in
docker login

# Tag
docker tag reconboard-v5-redrecon:latest YOUR_DOCKERHUB_USER/reconboard:latest
docker tag reconboard-v5-worker:latest YOUR_DOCKERHUB_USER/reconboard-worker:latest

# Push
docker push YOUR_DOCKERHUB_USER/reconboard:latest
docker push YOUR_DOCKERHUB_USER/reconboard-worker:latest
```

### Option B: GitHub Container Registry (GHCR)

```bash
# Log in (use a personal access token with write:packages scope)
echo YOUR_GITHUB_PAT | docker login ghcr.io -u YOUR_GITHUB_USER --password-stdin

# Tag
docker tag reconboard-v5-redrecon:latest ghcr.io/YOUR_GITHUB_USER/reconboard:latest
docker tag reconboard-v5-worker:latest ghcr.io/YOUR_GITHUB_USER/reconboard-worker:latest

# Push
docker push ghcr.io/YOUR_GITHUB_USER/reconboard:latest
docker push ghcr.io/YOUR_GITHUB_USER/reconboard-worker:latest
```

### Option C: Self-Hosted Private Registry

Run a registry on your server, push directly to it. No third party involved.

```bash
# On your server — start the registry
docker run -d -p 5000:5000 --restart always --name registry registry:2

# On your local machine — tag and push
docker tag reconboard-v5-redrecon:latest YOUR_SERVER_IP:5000/reconboard:latest
docker tag reconboard-v5-worker:latest YOUR_SERVER_IP:5000/reconboard-worker:latest
docker push YOUR_SERVER_IP:5000/reconboard:latest
docker push YOUR_SERVER_IP:5000/reconboard-worker:latest
```

> **Note:** Docker requires HTTPS for remote registries by default. For a private
> registry over plain HTTP, add `{"insecure-registries": ["YOUR_SERVER_IP:5000"]}`
> to `/etc/docker/daemon.json` on your local machine and restart Docker.

---

## Step 3: Deploy on Your Server

SSH into your server and create the deployment files.

### 3a. Create a project directory

```bash
ssh you@your-server

mkdir -p ~/reconboard/data/scans
cd ~/reconboard
```

### 3b. Create the `.env` file

```bash
cat > .env << 'EOF'
REDRECON_PORT=8443
REDRECON_PASSWORD=CHANGE_THIS_TO_A_STRONG_PASSWORD
REDRECON_API_KEY=CHANGE_THIS_TO_A_RANDOM_KEY
WORKER_MODE=distributed
MAX_CONCURRENT_SCANS=5
WORKER_CONCURRENCY=3
SCAN_TIMEOUT=1800
SECRET_KEY=CHANGE_THIS_TO_A_RANDOM_SECRET
EOF
```

Generate random values:
```bash
# Generate a random password and API key
sed -i "s/CHANGE_THIS_TO_A_STRONG_PASSWORD/$(openssl rand -hex 16)/" .env
sed -i "s/CHANGE_THIS_TO_A_RANDOM_KEY/$(openssl rand -hex 24)/" .env
sed -i "s/CHANGE_THIS_TO_A_RANDOM_SECRET/$(openssl rand -hex 32)/" .env
```

### 3c. Create `docker-compose.yml`

Replace `YOUR_REGISTRY/reconboard` with your actual image path from Step 2
(e.g., `ghcr.io/youruser/reconboard` or `yourdockerhubuser/reconboard`).

```yaml
services:
  redis:
    image: redis:7-alpine
    container_name: reconboard-redis
    restart: unless-stopped
    command: redis-server --appendonly yes --maxmemory 256mb --maxmemory-policy allkeys-lru
    volumes:
      - redis_data:/data
    ports:
      - "127.0.0.1:6379:6379"
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 5

  redrecon:
    image: YOUR_REGISTRY/reconboard:latest
    container_name: reconboard
    restart: unless-stopped
    depends_on:
      redis:
        condition: service_healthy
    network_mode: "host"
    privileged: true
    volumes:
      - ./data:/opt/redrecon/data
    env_file: .env
    environment:
      - REDIS_URL=redis://127.0.0.1:6379/0

  worker:
    image: YOUR_REGISTRY/reconboard-worker:latest
    restart: unless-stopped
    depends_on:
      redis:
        condition: service_healthy
    network_mode: "host"
    privileged: true
    volumes:
      - ./data:/opt/redrecon/data
    environment:
      - REDIS_URL=redis://127.0.0.1:6379/0
      - CONCURRENCY=${WORKER_CONCURRENCY:-3}
      - SCAN_TIMEOUT=${SCAN_TIMEOUT:-1800}
      - SCAN_OUTPUT_DIR=/opt/redrecon/data/scans

volumes:
  redis_data:
```

### 3d. Pull and start

```bash
# Pull the images from your registry
docker compose pull

# Start with 3 workers
docker compose up -d --scale worker=3
```

Reconboard is now running at `http://your-server-ip:8443`.

---

## Step 4: Set Up HTTPS with Nginx (Recommended)

Running over plain HTTP on the internet is a bad idea. Put nginx + Let's Encrypt in front.

### 4a. Install nginx and certbot

```bash
# Debian/Ubuntu
sudo apt install nginx certbot python3-certbot-nginx

# Or on Arch
sudo pacman -S nginx certbot certbot-nginx
```

### 4b. Create the nginx config

```bash
sudo tee /etc/nginx/sites-available/reconboard << 'EOF'
server {
    listen 80;
    server_name recon.yourdomain.com;

    location / {
        proxy_pass http://127.0.0.1:8443;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # WebSocket support (if needed later)
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";

        # Long-running scan requests
        proxy_read_timeout 3600;
        proxy_send_timeout 3600;
    }
}
EOF

sudo ln -sf /etc/nginx/sites-available/reconboard /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
```

### 4c. Get a TLS certificate

```bash
sudo certbot --nginx -d recon.yourdomain.com
```

Certbot will auto-modify the nginx config to add HTTPS and set up auto-renewal.

Now access at: `https://recon.yourdomain.com`

### 4d. (Optional) Restrict access by IP

Add to the `server` block in nginx:

```nginx
    # Only allow your IP
    allow 203.0.113.50;   # your IP
    allow 10.0.0.0/8;     # your VPN range
    deny all;
```

---

## Step 5: Firewall Rules

Lock down your server so only the necessary ports are exposed.

```bash
# UFW example
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80/tcp      # HTTP (certbot + redirect)
sudo ufw allow 443/tcp     # HTTPS
# Do NOT expose 8443 publicly if using nginx reverse proxy
# sudo ufw allow 8443/tcp  # Only if accessing directly without nginx
sudo ufw enable
```

---

## Updating the Deployment

When you make changes and want to deploy a new version:

```bash
# On your local machine — rebuild and push
cd reconboard-v5
docker compose build
docker tag reconboard-v5-redrecon:latest YOUR_REGISTRY/reconboard:latest
docker tag reconboard-v5-worker:latest YOUR_REGISTRY/reconboard-worker:latest
docker push YOUR_REGISTRY/reconboard:latest
docker push YOUR_REGISTRY/reconboard-worker:latest

# On your server — pull and restart
cd ~/reconboard
docker compose pull
docker compose up -d --scale worker=3
```

---

## Quick Reference

| Task | Command (on server) |
|------|---------------------|
| Start | `docker compose up -d --scale worker=3` |
| Stop | `docker compose down` |
| View logs | `docker compose logs -f` |
| Scale workers | `docker compose up -d --scale worker=5` |
| Update images | `docker compose pull && docker compose up -d --scale worker=3` |
| Shell into server | `docker exec -it reconboard bash` |
| Check health | `curl -s http://localhost:8443/api/health \| jq` |
| Backup data | `tar czf reconboard-backup.tar.gz data/` |
| Restore data | `tar xzf reconboard-backup.tar.gz` |

---

## Troubleshooting

**Images won't push (auth error)**
- Make sure you're logged in: `docker login` or `docker login ghcr.io`
- For GHCR, your PAT needs `write:packages` scope

**Can't pull on server (connection refused)**
- Self-hosted registry: add `insecure-registries` to daemon.json
- GHCR private images: `docker login ghcr.io` on the server too

**Port 8443 already in use**
- Change `REDRECON_PORT` in `.env` or check `ss -tlnp | grep 8443`

**Scans not running (permission denied)**
- The container needs `privileged: true` for raw sockets (SYN scans)
- Make sure your VPS provider allows privileged containers

**Workers not connecting**
- Both server and workers must reach Redis on `127.0.0.1:6379`
- With `network_mode: "host"` this works automatically
