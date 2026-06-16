# Deploy en Render + Neon (Gratis para siempre)

**Tiempo estimado: 20 minutos**

---

## Requisitos previos

- Cuenta de GitHub (para conectar el repo a Render)
- El proyecto subido a un repo de GitHub

### Subir el proyecto a GitHub

```bash
cd ~/flutter/condos
git remote add origin https://github.com/TU_USUARIO/condos.git
git push -u origin main
```

---

## Paso 1 — Base de datos en Neon (5 min)

1. Ve a **neon.tech** → clic en **"Sign up"** (puedes entrar con Google o GitHub)

2. Clic **"Create project"**:
   - Project name: `condos`
   - Database name: `condos_db`
   - Region: `US East (Virginia)` o la más cercana

3. Clic **"Create project"**

4. Copia la **Connection string** que aparece en pantalla. Tiene este formato:
   ```
   postgresql://condos_user:AbCdEf123@ep-cool-name-123456.us-east-2.aws.neon.tech/condos_db?sslmode=require
   ```
   Guárdala — la necesitas en el siguiente paso.

---

## Paso 2 — Backend en Render (10 min)

1. Ve a **render.com** → clic en **"Get started for free"**
   - Entra con tu cuenta de GitHub

2. En el panel → clic **"New +"** → **"Web Service"**

3. Conecta tu repositorio de GitHub:
   - Busca `condos` → clic **"Connect"**

4. Configura el servicio:

   | Campo | Valor |
   |---|---|
   | **Name** | `condos-api` |
   | **Region** | Oregon (US West) |
   | **Branch** | `main` |
   | **Root Directory** | `backend` |
   | **Runtime** | `Java` |
   | **Build Command** | `./mvnw clean package -DskipTests` |
   | **Start Command** | `java -Xms128m -Xmx400m -XX:+UseG1GC -jar target/condos-0.0.1-SNAPSHOT.jar` |
   | **Plan** | `Free` |

5. Baja hasta **"Environment Variables"** y agrega estas (clic **"Add Environment Variable"** para cada una):

   | Key | Value |
   |---|---|
   | `SPRING_PROFILES_ACTIVE` | `prod` |
   | `JAVA_VERSION` | `17` |
   | `DB_URL` | La connection string de Neon (completa con `?sslmode=require` al final) |
   | `DB_USERNAME` | El usuario de Neon (está en la connection string) |
   | `DB_PASSWORD` | El password de Neon (está en la connection string) |
   | `JWT_SECRET` | Genera uno: en tu Mac corre `openssl rand -hex 32` y pega el resultado |
   | `CORS_ORIGINS` | `https://condos-api.onrender.com` |

6. Clic **"Create Web Service"**

7. Render empieza a compilar — espera 3-5 minutos. Verás los logs en pantalla.

8. Cuando aparezca `Started CondosApplication in X seconds` → **¡listo!**

9. Tu API queda en: **`https://condos-api.onrender.com`**

### Verificar que funciona

```bash
curl https://condos-api.onrender.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'
```

Debes recibir un token JWT en la respuesta.

---

## Paso 3 — Compilar el APK con la URL de producción (2 min)

```bash
cd ~/flutter/condos
bash deploy/build-apk.sh https://condos-api.onrender.com
```

El APK queda en:
```
build/app/outputs/flutter-apk/app-release.apk
```

Comparte ese archivo por WhatsApp, email o cable USB con los residentes del condominio.

---

## Evitar el "sueño" de Render gratis

Render apaga el servicio después de **15 minutos sin peticiones**. El primer request después del sueño tarda ~30-60 segundos en responder.

**Solución — cron gratuito que hace ping cada 10 minutos:**

1. Ve a **cron-job.org** → crear cuenta gratis
2. Clic **"Create cronjob"**
3. Configurar:
   - **URL:** `https://condos-api.onrender.com/api/auth/login`
   - **Method:** POST
   - **Headers:** `Content-Type: application/json`
   - **Body:** `{"username":"admin","password":"admin123"}`
   - **Schedule:** Every 10 minutes
4. Clic **"Create"**

Con esto la app nunca duerme.

---

## Actualizaciones futuras

Cada vez que hagas cambios al código y los subas a GitHub:

```bash
git add -A
git commit -m "feat: descripción del cambio"
git push
```

Render detecta el push automáticamente y redespliega en ~3-5 minutos. **No necesitas hacer nada más.**

---

## Postman Collection

Para probar los endpoints, importa el archivo `condos_postman_collection.json` en Postman y cambia la variable `baseUrl` a:

```
https://condos-api.onrender.com
```

---

## Credenciales iniciales del sistema

| Username | Password | Rol |
|---|---|---|
| `admin` | `admin123` | ADMIN |
| `superadmin` | `admin123` | SUPERADMIN |

> **Importante:** Cambia estas contraseñas después del primer deploy.  
> Puedes crear usuarios desde la pantalla de Gestión en la app, o via Postman usando el endpoint `PUT /api/usuarios/{id}`.

---

## Resolución de problemas

| Problema | Solución |
|---|---|
| Deploy falla — `BUILD FAILURE` | Revisar los logs de Render. Probablemente falta una variable de entorno. |
| `Could not connect to database` | Verificar que `DB_URL` incluye `?sslmode=require` al final |
| La app responde lento la primera vez | Normal — estaba dormida. Configura el cron de cron-job.org |
| APK no conecta al servidor | Verificar que `BASE_URL` en el APK apunta a `https://condos-api.onrender.com` |
| `401 Unauthorized` en todos los endpoints | El token expiró (1 hora). Hacer login nuevamente. |
