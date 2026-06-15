#!/bin/bash
# =============================================================
# build-apk.sh — Compilar APK apuntando al servidor de Oracle
# Uso: bash deploy/build-apk.sh https://api.tu-dominio.com
# =============================================================

BASE_URL=${1:?"Uso: bash deploy/build-apk.sh https://api.tu-dominio.com"}

echo "=== Compilando APK para: $BASE_URL ==="
cd "$(dirname "$0")/.."

flutter build apk \
  --dart-define=BASE_URL="$BASE_URL" \
  --release

APK="build/app/outputs/flutter-apk/app-release.apk"
echo ""
echo "✓ APK generado: $APK"
echo "  Tamaño: $(du -h $APK | cut -f1)"
echo ""
echo "Para instalar en un Android conectado por USB:"
echo "  adb install $APK"
echo ""
echo "Para compartir por WhatsApp/email: adjunta el archivo $APK"
