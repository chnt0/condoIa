# Deploy en Oracle Cloud Free Tier

## Tiempo estimado: 45–60 minutos (primera vez)

---

## Paso 1 — Crear cuenta Oracle Cloud

1. Ir a **cloud.oracle.com** → "Start for free"
2. Llenar el formulario (requiere tarjeta de crédito para verificación, **no cobra**)
3. Seleccionar región: elige la más cercana a México (ej: US East Ashburn o Sao Paulo)
4. Esperar el email de activación (puede tardar 10-30 min)

---

## Paso 2 — Crear la VM (Compute Instance)

1. En el panel de Oracle Cloud → **Compute → Instances → Create Instance**

2. Configurar:
   - **Name:** `condos-server`
   - **Shape:** Cambia a `VM.Standard.A1.Flex` (ARM Ampere — Always Free)
     - OCPUs: **2** | Memory: **4 GB**
   - **Image:** Ubuntu 22.04 (Canonical)
   - **Boot volume:** 50 GB (el free tier incluye 200 GB total)

3. **SSH Keys:** 
   - Si tienes una clave SSH: súbela
   - Si no: descarga la que Oracle genera automáticamente (`*.key`)

4. Click **Create** → esperar ~2 minutos

5. Anotar la **IP pública** de la instancia

---

## Paso 3 — Abrir puertos en Oracle Cloud

En la VM recién creada:
**Primary VNIC → Subnet → Security List → Add Ingress Rules**

Agregar estas tres reglas:

| Source CIDR | Protocol | Port | Descripción |
|---|---|---|---|
| 0.0.0.0/0 | TCP | 80 | HTTP → Caddy redirige a HTTPS |
| 0.0.0.0/0 | TCP | 443 | HTTPS → app |
| 0.0.0.0/0 | TCP | 22 | SSH (ya existe) |

> El puerto 8080 NO debe ser público — Caddy hace el proxy internamente.

---

## Paso 4 — Conectarse por SSH y configurar el servidor

```bash
# Desde tu Mac (reemplaza con tu IP y la ruta a tu clave)
chmod 400 ~/Downloads/oracle-key.key
ssh -i ~/Downloads/oracle-key.key ubuntu@IP_PUBLICA_DE_TU_VM
```

Una vez dentro del servidor, ejecutar el script de configuración:

```bash
# Descargar y ejecutar el script de setup
curl -fsSL https://raw.githubusercontent.com/TU_USUARIO/TU_REPO/main/deploy/server-setup.sh | sudo bash
```

O si no tienes el repo en GitHub, copiar el script manualmente:

```bash
# Desde tu Mac — copiar el script al servidor
scp -i oracle-key.key deploy/server-setup.sh ubuntu@IP:/home/ubuntu/
# En el servidor:
sudo bash /home/ubuntu/server-setup.sh
```

---

## Paso 5 — Apuntar un dominio a la IP (opcional pero recomendado)

Si tienes un dominio (ej. en Namecheap, GoDaddy, o Cloudflare):

1. Agregar registro DNS tipo **A**:
   - Nombre: `api`
   - Valor: `IP_PUBLICA_DE_TU_VM`
   - TTL: 300

2. Esperar 5-15 minutos para que propague

Si **no tienes dominio**, puedes usar la IP directa con HTTP (sin HTTPS). Solo modifica el Caddyfile para usar `:80` en lugar del dominio.

---

## Paso 6 — Configurar Caddy

```bash
# Editar el Caddyfile
sudo nano /etc/caddy/Caddyfile
```

Reemplazar el contenido con el de `deploy/Caddyfile`, cambiando `api.tu-dominio.com` por tu dominio real.

```bash
# Aplicar cambios
sudo systemctl reload caddy
```

---

## Paso 7 — Generar el JWT secret

```bash
# En tu Mac o en el servidor
openssl rand -hex 32
# Ejemplo output: a3f8c2d1e9b4...  <- esto es tu JWT_SECRET
```

---

## Paso 8 — Configurar el servicio de la app

```bash
# Copiar el archivo de servicio al servidor
scp -i oracle-key.key deploy/condos.service ubuntu@IP:/home/ubuntu/

# En el servidor: editar las variables de entorno
nano /home/ubuntu/condos.service
# Cambiar: DB_PASSWORD, JWT_SECRET, CORS_ORIGINS (tu dominio)

# Instalar el servicio
sudo cp /home/ubuntu/condos.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable condos
```

---

## Paso 9 — Subir y arrancar la app

**Desde tu Mac:**

```bash
# Primera vez: compilar y subir
cd ~/flutter/condos/backend
./mvnw clean package -DskipTests

scp -i oracle-key.key target/condos-0.0.1-SNAPSHOT.jar ubuntu@IP:/opt/condos/condos.jar
```

**En el servidor:**

```bash
sudo chown condos:condos /opt/condos/condos.jar
sudo systemctl start condos

# Ver que esté corriendo
sudo systemctl status condos

# Ver logs en tiempo real
sudo journalctl -u condos -f
```

Deberías ver `Started CondosApplication in X seconds` en los logs.

---

## Paso 10 — Verificar que funciona

```bash
# Desde tu Mac — reemplaza con tu IP o dominio
curl https://api.tu-dominio.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'

# Si usas IP directa sin dominio:
curl http://IP_PUBLICA:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'
```

---

## Paso 11 — Compilar la app Flutter para producción

```bash
# Desde tu Mac
bash deploy/build-apk.sh https://api.tu-dominio.com

# O con IP directa (sin HTTPS):
bash deploy/build-apk.sh http://IP_PUBLICA:8080
```

El APK queda en `build/app/outputs/flutter-apk/app-release.apk`.  
Compártelo por WhatsApp, email, o instálalo con `adb install`.

---

## Actualizaciones futuras (10 segundos)

```bash
# Cada vez que cambies código del backend:
bash deploy/deploy.sh ubuntu@IP_PUBLICA
```

---

## Resumen de costos

| Recurso | Costo |
|---|---|
| VM ARM A1 (2 OCPU, 4 GB) | **$0 — siempre gratis** |
| 50 GB almacenamiento | **$0 — siempre gratis** |
| PostgreSQL (en el VM) | **$0** |
| Caddy + Let's Encrypt | **$0** |
| Dominio (opcional) | ~$10/año o gratis en freenom.com |
| **Total** | **$0/mes** |

---

## Comandos útiles en el servidor

```bash
# Ver logs de la app
sudo journalctl -u condos -f

# Reiniciar la app
sudo systemctl restart condos

# Ver estado de servicios
sudo systemctl status condos caddy postgresql

# Conectarse a la BD
sudo -u postgres psql condos_db

# Espacio en disco
df -h
```
