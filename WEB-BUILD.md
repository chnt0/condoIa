# Guía de builds — Condominios App

## Variables de entorno requeridas (pegar en terminal antes de cualquier build)

```bash
export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
export JAVA_TOOL_OPTIONS="-Djavax.net.ssl.trustStoreType=KeychainStore"
```

---

## 🌐 Web — publicar en Render

### Compilar y desplegar (un solo comando)

```bash
cd ~/flutter/condos && \
~/flutter/condos/flutter/bin/flutter build web --dart-define=BASE_URL=https://condoia.onrender.com && \
cp -r build/web/* web-dist/ && \
git add web-dist/ && \
git commit -m "chore: update web build" && \
git push
```

Render despliega automáticamente en ~30 segundos.  
App disponible en: **https://condov.onrender.com**

### Paso a paso

```bash
# 1. Compilar
cd ~/flutter/condos
~/flutter/condos/flutter/bin/flutter build web --dart-define=BASE_URL=https://condoia.onrender.com

# 2. Copiar resultado
cp -r build/web/* web-dist/

# 3. Publicar
git add web-dist/ && git commit -m "chore: update web build" && git push
```

---

## 📱 Android APK — instalar en dispositivo

```bash
cd ~/flutter/condos
~/flutter/condos/flutter/bin/flutter build apk --dart-define=BASE_URL=https://condoia.onrender.com --release
```

El APK queda en:
```
build/app/outputs/flutter-apk/app-release.apk
```

Compartir por WhatsApp, email o instalar con cable USB:
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

---

## 🏪 Android AAB — subir a Play Store

El AAB es el formato que requiere Google Play (más pequeño que el APK).

```bash
cd ~/flutter/condos
~/flutter/condos/flutter/bin/flutter build appbundle --dart-define=BASE_URL=https://condoia.onrender.com
```

El AAB queda en:
```
build/app/outputs/bundle/release/app-release.aab
```

Subir este archivo en: **play.google.com/console**

---

## 💻 Correr en local (desarrollo)

### 1. Arrancar el backend

```bash
cd ~/flutter/condos/backend
./mvnw spring-boot:run
```

El backend queda en `http://localhost:8080`.

### 2. App web en Chrome

```bash
cd ~/flutter/condos
~/flutter/condos/flutter/bin/flutter run -d chrome --web-port 5000
```

Abre Chrome en `http://localhost:5000`. No necesitas `--dart-define`.

### 3. App Android en emulador/dispositivo

```bash
cd ~/flutter/condos
~/flutter/condos/flutter/bin/flutter run --dart-define=BASE_URL=http://10.0.2.2:8080
```

> Nota: en emulador Android usar `10.0.2.2` en vez de `localhost`.  
> En dispositivo físico usar la IP local de tu Mac (ej. `192.168.1.x:8080`).

### Credenciales de prueba

| Usuario | Contraseña | Rol |
|---|---|---|
| `admin` | `admin123` | ADMIN |
| `superadmin` | `admin123` | SUPERADMIN |
| `residente1` | `pass123` | USUARIO |
| `guardia1` | `pass123` | GUARDIA |

---

## Notas

- La pantalla de **Escanear QR** no funciona en web — solo en app móvil.
- Usuarios creados por CSV reciben contraseña temporal `Condos2024!`.
- El keystore de Play Store está en `~/flutter/condos/condos-release.keystore` — **NO subir a git**.
- Las credenciales del keystore están en `SECRETOS-LOCALES.md`.
