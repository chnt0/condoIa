#!/bin/bash
# =============================================================
# deploy.sh — Subir nueva versión al servidor Oracle Cloud
# Ejecutar desde tu Mac cada vez que quieras actualizar
# Uso: bash deploy/deploy.sh ubuntu@TU-IP-PUBLICA
# =============================================================

set -e

SERVER=${1:?"Uso: bash deploy/deploy.sh ubuntu@IP_DEL_SERVIDOR"}

echo "=== [1/4] Compilando JAR ==="
cd "$(dirname "$0")/.."
cd backend && ./mvnw clean package -DskipTests -q && cd ..
JAR=$(ls backend/target/condos-*.jar | head -1)
echo "JAR: $JAR"

echo "=== [2/4] Subiendo JAR al servidor ==="
scp "$JAR" "$SERVER:/opt/condos/condos.jar"

echo "=== [3/4] Reiniciando servicio ==="
ssh "$SERVER" "sudo systemctl restart condos"

echo "=== [4/4] Verificando estado ==="
sleep 5
ssh "$SERVER" "sudo systemctl is-active condos && echo '✓ App corriendo' || echo '✗ App falló — ver: sudo journalctl -u condos -n 50'"

echo ""
echo "Deploy completado. Logs en tiempo real:"
echo "  ssh $SERVER 'sudo journalctl -u condos -f'"
