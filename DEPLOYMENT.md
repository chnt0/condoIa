# Guía de Deployment

## Backend (Spring Boot)

### 1. Variables de entorno

Copiar `.env.example` como `.env` y completar todos los valores:

```bash
cp backend/.env.example backend/.env
```

Generar JWT secret seguro:
```bash
openssl rand -hex 32
```

### 2. Compilar el JAR

```bash
cd backend
./mvnw clean package -DskipTests
```

El JAR queda en `backend/target/condos-0.0.1-SNAPSHOT.jar`.

### 3. Correr en producción

```bash
SPRING_PROFILES_ACTIVE=prod \
DB_URL=jdbc:postgresql://localhost:5432/condos_db \
DB_USERNAME=condos_user \
DB_PASSWORD=tu-password \
JWT_SECRET=tu-secreto-de-32-chars \
CORS_ORIGINS=https://tu-dominio.com \
java -jar backend/target/condos-0.0.1-SNAPSHOT.jar
```

O con systemd/docker usando las variables del `.env`.

### 4. HTTPS (obligatorio en producción)

Poner **Caddy** o **nginx** como proxy reverso. Con Caddy (más simple):

```
# Caddyfile
api.tu-dominio.com {
    reverse_proxy localhost:8080
}
```

Caddy gestiona TLS automáticamente con Let's Encrypt.

---

## Flutter — compilar app móvil

### Android APK

```bash
flutter build apk --dart-define=BASE_URL=https://api.tu-dominio.com
```

El APK queda en `build/app/outputs/flutter-apk/app-release.apk`.

### iOS

```bash
flutter build ios --dart-define=BASE_URL=https://api.tu-dominio.com
```

### Desarrollo local (sin cambios)

```bash
flutter run   # usa http://localhost:8080 por defecto
```

---

## Credenciales iniciales

Los usuarios `superadmin` y `admin` se crean en la migración V1 con password `admin123`.

**Cambiar estas contraseñas inmediatamente** después del primer deploy:

```bash
# Cambiar password de admin via la API (como superadmin)
# O directamente en la BD:
psql -U condos_user -d condos_db -c \
  "UPDATE usuarios SET password_hash = '\$2a\$12\$NUEVO_HASH_BCRYPT' WHERE username = 'admin';"
```

Para generar un hash BCrypt:
```bash
# Python
python3 -c "import bcrypt; print(bcrypt.hashpw(b'nueva-password', bcrypt.gensalt(12)).decode())"
```
