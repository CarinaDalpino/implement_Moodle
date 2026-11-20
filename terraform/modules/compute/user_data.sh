#!/bin/bash
# Executado pelo cloud-init no primeiro boot da EC2 (Amazon Linux 2023).
# Instala Docker e Compose v2, constroi a imagem do Moodle e sobe o container.
# Nota: o templatefile do Terraform interpreta a sintaxe de cifrao com chaves,
# entao as variaveis de shell abaixo nao usam chaves.
set -euo pipefail
exec > >(tee /var/log/user-data.log) 2>&1

echo "[1/6] Criando swap de 2 GB (t3.micro tem 1 GB de RAM)"
if [ ! -f /swapfile ]; then
  dd if=/dev/zero of=/swapfile bs=1M count=2048
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  echo "/swapfile none swap sw 0 0" >> /etc/fstab
fi

echo "[2/6] Instalando Docker e Git"
dnf install -y docker git
systemctl enable --now docker
usermod -aG docker ec2-user

echo "[3/6] Instalando Docker Compose v2"
mkdir -p /usr/local/lib/docker/cli-plugins
curl -fsSL "https://github.com/docker/compose/releases/download/v2.29.7/docker-compose-linux-x86_64" \
  -o /usr/local/lib/docker/cli-plugins/docker-compose
chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
docker --version
docker compose version

echo "[4/6] Clonando o repositorio do Moodle"
git clone --branch "${repo_branch}" --depth 1 "${repo_url}" /opt/moodle-src

echo "[5/6] Gerando .env e docker-compose.yml da EC2"
mkdir -p /opt/moodle
cat > /opt/moodle/.env <<'ENVEOF'
MOODLE_DATABASE_TYPE=pgsql
MOODLE_DATABASE_HOST=${db_host}
MOODLE_DATABASE_PORT_NUMBER=${db_port}
MOODLE_DATABASE_NAME=${db_name}
MOODLE_DATABASE_USER=${db_username}
MOODLE_DATABASE_PASSWORD=${db_password}
ENVEOF
chmod 600 /opt/moodle/.env

cat > /opt/moodle/docker-compose.yml <<'COMPOSEEOF'
services:
  moodle:
    build:
      context: /opt/moodle-src/docker
      dockerfile: Dockerfile
    restart: unless-stopped
    ports:
      - "80:80"
    env_file:
      - .env
    volumes:
      - moodle_data:/var/www/html
      - moodle_www:/var/moodledata
volumes:
  moodle_data:
  moodle_www:
COMPOSEEOF

echo "[6/6] Subindo o Moodle"
cd /opt/moodle
docker compose up -d --build
docker compose ps
echo "Moodle no ar. Conclua a instalacao pelo navegador em http://<DNS-PUBLICO>"