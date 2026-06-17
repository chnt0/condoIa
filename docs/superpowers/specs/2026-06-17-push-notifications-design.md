# Push Notifications (FCM) — Design Spec

**Date:** 2026-06-17  
**Scope:** Notificaciones push a residentes cuando el GUARDIA registra un paquete o una visita directa. Se usa Firebase Cloud Messaging (FCM). Android funciona inmediatamente; iOS requiere cuenta Apple Developer ($99/año) que se agrega después.

---

## Flujo

```
GUARDIA registra paquete o visita directa
    → Backend consulta FCM token del residente destinatario
    → Backend llama a Firebase Admin SDK
    → Firebase entrega push al celular del residente
```

---

## Configuración previa (manual — no se puede automatizar)

### 1. Crear proyecto Firebase

1. Ir a **console.firebase.google.com** → crear proyecto
2. En el proyecto → **Cloud Messaging** → habilitado por defecto

### 2. Configurar Android

1. Agregar app Android → package name: `com.condos.condos`
2. Descargar `google-services.json`
3. Colocar en `android/app/google-services.json`

### 3. Obtener clave de cuenta de servicio (para el backend)

1. Firebase Console → Configuración del proyecto → Cuentas de servicio
2. "Generar nueva clave privada" → descarga JSON
3. Guardar como variable de entorno: `FIREBASE_SERVICE_ACCOUNT_JSON` (contenido del JSON como string)

### 4. iOS (cuando haya cuenta Apple Developer)

1. Apple Developer → Certificates → Keys → crear APNs Key
2. Subir la clave a Firebase Console → Configuración → Cloud Messaging → iOS

---

## Backend

### Nueva dependencia en pom.xml

```xml
<dependency>
    <groupId>com.google.firebase</groupId>
    <artifactId>firebase-admin</artifactId>
    <version>9.4.1</version>
</dependency>
```

### Nuevos archivos

```
com/condos/notificacion/service/
  FirebaseAdminConfig.java      ← inicializa Firebase Admin SDK desde env var
  NotificacionPushService.java  ← envía FCM; no lanza excepción si no hay config
com/condos/dispositivo/
  model/DeviceToken.java
  repository/DeviceTokenRepository.java
  dto/RegisterTokenRequest.java
  controller/DeviceTokenController.java
```

### Endpoint nuevo

`POST /api/device-tokens` — USUARIO autenticado registra su token FCM

```json
{ "token": "fcm-token-string", "plataforma": "ANDROID" }
```

- Si el token ya existe para el usuario, se actualiza (no duplica)
- La tabla `device_tokens` ya existe en V1 con columnas: `id`, `usuario_id`, `token`, `plataforma`, `created_at`

### Modificaciones a servicios existentes

**`PaqueteService.registrarPaquete()`**: al final del método, llama a `NotificacionPushService.notificarPaquete(destinatario.getId(), paquete.getDescripcion())`

**`VisitaService.registrarVisitaDirecta()`**: al final del método, llama a `NotificacionPushService.notificarVisitaDirecta(destinatario.getId(), visitante, motivo)`

### Contenido de las notificaciones

| Evento | Título | Cuerpo |
|---|---|---|
| Paquete | `"📦 Tienes un paquete"` | `"Llegó un paquete para ti en portería. Pasa a recogerlo."` |
| Visita directa | `"🔔 Tienes una visita"` | `"Visitante: [nombre]. Motivo: [motivo]"` |

### Comportamiento si Firebase no está configurado

`NotificacionPushService` verifica si Firebase está inicializado. Si `FIREBASE_SERVICE_ACCOUNT_JSON` no existe → loguea un warning y retorna sin lanzar excepción. El registro del paquete/visita se completa normalmente.

---

## Flutter

### Nuevas dependencias pubspec.yaml

```yaml
firebase_core: ^3.6.0
firebase_messaging: ^15.1.3
flutter_local_notifications: ^17.2.2
```

### Archivos nuevos

```
lib/core/services/
  firebase_service.dart   ← inicializa Firebase, pide permisos, obtiene token
```

### Cambios en archivos existentes

**`main.dart`**: inicializar Firebase antes de `runApp()` y configurar handler de background messages.

**`auth_provider.dart`**: después de login exitoso → llamar a `FirebaseService.registrarToken()` que obtiene el FCM token y lo manda al backend.

**Notificaciones en primer plano**: mostrar con `flutter_local_notifications` cuando la app está abierta.

---

## Variables de entorno en Render

Agregar en Render → backend → Environment:

```
FIREBASE_SERVICE_ACCOUNT_JSON = { ...contenido del JSON de cuenta de servicio... }
```

---

## Out of Scope

- iOS en producción (requiere cuenta Apple Developer $99/año)
- Notificaciones para otros eventos (cuotas, incidentes, etc.)
- Historial de notificaciones enviadas
- Preferencias de notificación por usuario (activar/desactivar tipos)
