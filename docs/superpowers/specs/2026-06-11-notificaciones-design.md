# Notificaciones — Design Spec

**Date:** 2026-06-11  
**Scope:** Módulo de avisos in-app. ADMIN publica notificaciones segmentadas (todos o por edificio). Todos los roles las leen. Sin tracking de lectura ni Firebase.

---

## Context

El ADMIN necesita comunicar avisos a los residentes (cortes de agua, eventos, recordatorios) de forma segmentada. Las notificaciones son in-app únicamente — no se usa Firebase en esta versión.

**Out of scope:** Tracking de lectura por usuario, notificaciones push (Firebase), segmentos MOROSOS y PROPIETARIOS, fecha de expiración, editar notificación publicada.

---

## Roles involucrados

- `ADMIN` / `SUPERADMIN` — crea y elimina notificaciones
- `USUARIO`, `GUARDIA`, `ADMIN`, `SUPERADMIN` — leen notificaciones visibles según su segmento

---

## Data Model — 1 nueva tabla

### `notificaciones`

| Columna | Tipo | Descripción |
|---------|------|-------------|
| `id` | BIGSERIAL PK | |
| `condominio_id` | BIGINT FK → condominios | |
| `admin_creador_id` | BIGINT FK → usuarios | Admin que publicó |
| `titulo` | VARCHAR(200) NOT NULL | |
| `mensaje` | TEXT NOT NULL | |
| `segmento` | ENUM `segmento_notificacion` | `TODOS` o `EDIFICIO_X` |
| `edificio` | VARCHAR(50) NULL | Requerido si segmento = EDIFICIO_X |
| `created_at` | TIMESTAMP NOT NULL | |

**Migración:** `V6__create_notificaciones_table.sql`

**Sin tabla `notificaciones_leidas`** — no se rastrea lectura individual.

---

## Business Rules

1. Al crear con `segmento = TODOS` → visible para todos los usuarios del condominio.
2. Al crear con `segmento = EDIFICIO_X` → el ADMIN proporciona un string `edificio` (ej. `"Torre A"`). La notificación es visible solo para usuarios cuyo `unidadHabitacional` empieza con ese string (case-insensitive).
3. GUARDIA y ADMIN/SUPERADMIN siempre ven todas las notificaciones del condominio (sin filtro de segmento), ya que no tienen `unidadHabitacional`.
4. Las notificaciones se devuelven ordenadas por `created_at DESC`.
5. Solo el ADMIN que creó la notificación, o un SUPERADMIN, puede eliminarla. (Para simplificar: cualquier ADMIN/SUPERADMIN puede eliminar cualquier notificación del condominio.)

---

## Backend

### Nuevos archivos

```
com/condos/notificacion/
  model/
    SegmentoNotificacion.java
    Notificacion.java
  repository/
    NotificacionRepository.java
  dto/
    CreateNotificacionRequest.java
    NotificacionResponse.java
  service/
    NotificacionService.java
  controller/
    NotificacionController.java
```

### Endpoints `/api/notificaciones`

| Método | Path | Descripción | Roles |
|--------|------|-------------|-------|
| `GET` | `/` | Lista notificaciones visibles para el usuario autenticado | TODOS |
| `POST` | `/` | Crear notificación | ADMIN, SUPERADMIN |
| `DELETE` | `/{id}` | Eliminar notificación | ADMIN, SUPERADMIN |

### DTOs

**CreateNotificacionRequest:**
```java
String titulo                      // requerido
String mensaje                     // requerido
SegmentoNotificacion segmento      // TODOS o EDIFICIO_X
String edificio                    // requerido si segmento = EDIFICIO_X
```

**NotificacionResponse:**
```java
Long id
String titulo
String mensaje
SegmentoNotificacion segmento
String edificio
Long adminCreadorId
String adminCreadorNombre
LocalDateTime createdAt
```

### Lógica de filtrado (GET)

El service recibe el usuario autenticado y filtra:
- Si el usuario es ADMIN, SUPERADMIN o GUARDIA → devuelve todas las notificaciones del condominio
- Si el usuario es USUARIO → filtra: incluye las de `segmento = TODOS` + las de `segmento = EDIFICIO_X` donde `unidadHabitacional ILIKE edificio%`

---

## Flutter

### Nuevos archivos

```
lib/features/notificaciones/
  models/
    notificacion.dart + .g.dart
    create_notificacion_request.dart + .g.dart
  services/
    notificacion_service.dart
  providers/
    notificacion_provider.dart
  screens/
    notificaciones_screen.dart
    crear_notificacion_screen.dart
    detalle_notificacion_screen.dart
```

### ApiConstants nuevos

```dart
static const String notificaciones = '$apiPrefix/notificaciones';
static String notificacionById(int id) => '$apiPrefix/notificaciones/$id';
```

### Estado Riverpod

```dart
class NotificacionState {
  final List<Notificacion> notificaciones;
  final bool isLoading;
  final String? error;
}

class NotificacionNotifier extends StateNotifier<NotificacionState> {
  Future<void> cargarNotificaciones()
  Future<Notificacion?> crearNotificacion(CreateNotificacionRequest)
  Future<void> eliminarNotificacion(int id)
}
```

### Pantallas

**NotificacionesScreen** (todos los roles):
- Lista con `ListTile`: título + chip segmento (azul="Todos", naranja=edificio) + fecha
- ADMIN/SUPERADMIN: FAB `+` → `CrearNotificacionScreen`
- Tap → `DetalleNotificacionScreen`

**CrearNotificacionScreen** (solo ADMIN/SUPERADMIN):
- `TextFormField`: título (requerido)
- `TextFormField`: mensaje multiline (requerido)
- `DropdownButtonFormField`: segmento (Todos / Por Edificio)
- Si "Por Edificio": `TextFormField` para el identificador del edificio

**DetalleNotificacionScreen** (todos los roles):
- Header: título, fecha, chip de segmento
- Mensaje completo
- ADMIN/SUPERADMIN: botón "Eliminar" con diálogo de confirmación → pop al eliminar

### Navegación — cambios a MainScaffold y GoRouter

Tab "Avisos" (`Icons.notifications_outlined`) agregado a todos los roles, siempre como penúltimo tab (antes de Perfil):

- **USUARIO** (8 tabs): Inicio, Mis Visitas, Nueva, Paquetes, Incidentes, Cuotas, Avisos, Perfil
- **GUARDIA** (6 tabs): Escanear, Paquetes, Hoy, Historial, Avisos, Perfil
- **ADMIN** (8 tabs): Dashboard, Visitas, Paquetes, Incidentes, Gestión, Cuotas, Avisos, Perfil

Nuevas rutas GoRouter:
```
/home/notificaciones/nueva    → CrearNotificacionScreen
/home/notificaciones/:id      → DetalleNotificacionScreen
```

---

## Out of Scope

- Tracking de lectura por usuario (`notificaciones_leidas`)
- Notificaciones push / Firebase Cloud Messaging
- Segmentos MOROSOS y PROPIETARIOS
- Fecha de expiración
- Editar notificación publicada
