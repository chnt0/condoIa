# Cómo construir y publicar la app web

## Requisitos previos

- Flutter SDK descargado en `~/flutter/condos/flutter/`
- Backend corriendo en Render: `https://condoia.onrender.com`

---

## Compilar y actualizar web-dist

Ejecuta estos comandos en orden:

```bash
# 1. Ir al proyecto
cd ~/flutter/condos

# 2. Compilar apuntando al backend de producción
~/flutter/condos/flutter/bin/flutter build web \
  --dart-define=BASE_URL=https://condoia.onrender.com

# 3. Copiar el resultado a web-dist
cp -r build/web/* web-dist/

# 4. Subir a GitHub (Render detecta el push y redespliega automáticamente)
git add web-dist/
git commit -m "chore: update web build"
git push
```

Render despliega los cambios en ~30 segundos.  
La app queda disponible en: **https://condov.onrender.com**

---

## Compilar en un solo comando

```bash
cd ~/flutter/condos && \
~/flutter/condos/flutter/bin/flutter build web --dart-define=BASE_URL=https://condoia.onrender.com && \
cp -r build/web/* web-dist/ && \
git add web-dist/ && \
git commit -m "chore: update web build" && \
git push
```

---

---

## Correr en local (desarrollo)

### 1. Arrancar el backend

```bash
cd ~/flutter/condos/backend
./mvnw spring-boot:run
```

El backend queda en `http://localhost:8080`.

### 2. Correr la app web

```bash
cd ~/flutter/condos
~/flutter/condos/flutter/bin/flutter run -d chrome --web-port 5000
```

Abre Chrome en `http://localhost:5000`.  
No necesitas `--dart-define` — usa `localhost:8080` por default.

### Credenciales de prueba

| Usuario | Contraseña | Rol |
|---|---|---|
| `admin` | `admin123` | ADMIN |
| `superadmin` | `admin123` | SUPERADMIN |
| `residente1` | `pass123` | USUARIO |
| `guardia1` | `pass123` | GUARDIA |

---

## Notas

- El campo `BASE_URL` debe apuntar siempre al backend de producción.
- La pantalla de **Escanear QR** no funciona en web — es exclusiva de la app móvil.
- Usuarios creados por CSV reciben contraseña temporal `Condos2024!`.
