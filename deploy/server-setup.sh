#!/bin/bash
# =============================================================
# server-setup.sh — Configuración inicial del VM Oracle Cloud
# Ejecutar UNA VEZ como root o con sudo en Ubuntu 22.04
# Uso: sudo bash server-setup.sh
# =============================================================

set -e  # Detener si cualquier comando falla

echo "=== [1/7] Actualizando paquetes ==="
apt-get update -q && apt-get upgrade -y -q

echo "=== [2/7] Instalando Java 21 ==="
apt-get install -y -q openjdk-21-jdk-headless
java -version

echo "=== [3/7] Instalando PostgreSQL 15 ==="
apt-get install -y -q postgresql postgresql-contrib
systemctl enable postgresql
systemctl start postgresql

echo "=== [4/7] Creando usuario y base de datos PostgreSQL ==="
# Cambia 'condos_pass_seguro' por una contraseña real
DB_PASS="condos_pass_seguro"
sudo -u postgres psql <<EOF
CREATE USER condos_user WITH PASSWORD '${DB_PASS}';
CREATE DATABASE condos_db OWNER condos_user;
GRANT ALL PRIVILEGES ON DATABASE condos_db TO condos_user;
EOF
echo "DB creada. Usuario: condos_user / Password: ${DB_PASS}"

echo "=== [5/7] Instalando Caddy (proxy HTTPS) ==="
apt-get install -y -q debian-keyring debian-archive-keyring apt-transport-https curl
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' \
  | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' \
  | tee /etc/apt/sources.list.d/caddy-stable.list
apt-get update -q && apt-get install -y -q caddy

echo "=== [6/7] Creando usuario de sistema para la app ==="
useradd -r -s /bin/false condos || echo "Usuario condos ya existe"
mkdir -p /opt/condos
chown condos:condos /opt/condos

echo "=== [7/7] Abriendo puertos en el firewall del sistema ==="
# Oracle Cloud también requiere abrir los puertos en la consola web
# Security List → Ingress Rules → TCP 80, 443
iptables -I INPUT 6 -m state --state NEW -p tcp --dport 80 -j ACCEPT
iptables -I INPUT 6 -m state --state NEW -p tcp --dport 443 -j ACCEPT
iptables -I INPUT 6 -m state --state NEW -p tcp --dport 8080 -j ACCEPT
netfilter-persistent save 2>/dev/null || apt-get install -y iptables-persistent && netfilter-persistent save

echo ""
echo "======================================================"
echo "  Servidor configurado. Próximos pasos:"
echo "  1. Subir el JAR: scp target/*.jar ubuntu@TU-IP:/opt/condos/condos.jar"
echo "  2. Copiar: sudo cp /ruta/condos.service /etc/systemd/system/"
echo "  3. Copiar: sudo cp /ruta/Caddyfile /etc/caddy/Caddyfile"
echo "  4. Editar variables en /etc/systemd/system/condos.service"
echo "  5. sudo systemctl daemon-reload && sudo systemctl enable condos && sudo systemctl start condos"
echo "  6. sudo systemctl reload caddy"
echo "======================================================"
