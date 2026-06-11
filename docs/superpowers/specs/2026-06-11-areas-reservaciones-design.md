# Áreas Comunes + Reservaciones — Design Spec

**Date:** 2026-06-11  
**Scope:** Módulo de gestión de áreas comunes y reservaciones. ADMIN hace CRUD de áreas. USUARIO reserva bloques de tiempo disponibles con validación de conflictos, límite mensual y morosos.

---

## Context

Los residentes necesitan reservar áreas comunes (alberca, salón, gimnasio) en bloques de tiempo configurables. El ADMIN define cada área con su horario, duración de bloque y restricciones. El sistema valida conflictos, límites mensuales y bloquea a usuarios morosos.

**Out of scope:** Foto del área, pagos por uso de área, notificaciones push al crear reservación, aprobación manual de reservaciones por ADMIN (son auto-aprobadas al crearlas).

---

## Roles involucrados

- `ADMIN` / `SUPERADMIN` — CRUD de áreas comunes, ver todas las reservaciones, cancelar cualquiera
- `USUARIO` — ve áreas activas, reserva bloques disponibles, ve sus reservaciones, cancela las propias
- `GUARDIA` — sin acceso al módulo

---

## Data Model — 2 nuevas tablas

### `areas_comunes`

| Columna | Tipo | Descripción |
|---------|------|-------------|
| `id` | BIGSERIAL PK | |
| `condominio_id` | BIGINT FK → condominios | |
| `nombre` | VARCHAR(100) NOT NULL | Ej: "Alberca", "Salón de Eventos" |
| `descripcion` | TEXT NULL | |
| `capacidad` | INT NOT NULL | Aforo máximo |
| `horario_inicio` | TIME NOT NULL | Ej: `08:00` |
| `horario_fin` | TIME NOT NULL | Ej: `22:00` |
| `duracion_bloque_minutos` | INT NOT NULL | Ej: 60, 120 |
| `max_reservas_mes_por_usuario` | INT NOT NULL | Límite mensual por residente por área |
| `anticipacion_minima_horas` | INT NOT NULL | Mínimo de horas de anticipación para reservar |
| `anticipacion_maxima_dias` | INT NOT NULL | Máximo de días de anticipación para reservar |
| `activa` | BOOLEAN NOT NULL DEFAULT true | Si aparece disponible para reservar |
| `created_at` | TIMESTAMP | |
| `updated_at` | TIMESTAMP | |

### `reservaciones`

| Columna | Tipo | Descripción |
|---------|------|-------------|
| `id` | BIGSERIAL PK | |
| `area_comun_id` | BIGINT FK → areas_comunes | |
| `usuario_id` | BIGINT FK → usuarios | |
| `fecha_hora_inicio` | TIMESTAMP NOT NULL | |
| `fecha_hora_fin` | TIMESTAMP NOT NULL | inicio + duracion_bloque_minutos |
| `estado` | ENUM `estado_reservacion` | `ACTIVA` o `CANCELADA` |
| `created_at` | TIMESTAMP | |

**Migración:** `V7__create_areas_reservaciones_tables.sql`

---

## Business Rules

1. **Solo ACTIVA / CANCELADA.** Pasada la fecha, la reservación queda histórica sin cambio de estado.
2. **Conflicto de bloque:** No se puede crear una reservación si existe otra `ACTIVA` para la misma área con solapamiento de horario (`fecha_hora_inicio` del nuevo == `fecha_hora_inicio` de uno existente). Como los bloques son fijos y no se solapan parcialmente, la validación es simplemente: no existe otra reservación `ACTIVA` con el mismo `area_comun_id` y `fecha_hora_inicio`.
3. **Moroso:** El backend consulta si el usuario tiene alguna `cuota_usuario` con `estado = PENDIENTE` y `fecha_vencimiento < hoy`. Si es así, rechaza la reservación con error 400.
4. **Límite mensual:** El usuario no puede tener más de `max_reservas_mes_por_usuario` reservaciones `ACTIVA` en el mes calendario actual para el mismo `area_comun_id`.
5. **Anticipación mínima:** `fecha_hora_inicio >= now() + anticipacion_minima_horas`.
6. **Anticipación máxima:** `fecha_hora_inicio <= now() + anticipacion_maxima_dias`.
7. **Cancelación USUARIO:** Solo puede cancelar sus propias reservaciones `ACTIVA` cuya `fecha_hora_inicio > now()`.
8. **Cancelación ADMIN:** Puede cancelar cualquier reservación `ACTIVA`.

---

## Backend

### Nuevos archivos

```
com/condos/area/
  model/
    AreaComun.java
  repository/
    AreaComunRepository.java
  dto/
    CreateAreaComunRequest.java
    AreaComunResponse.java
    BloqueDisponibilidadResponse.java
  service/
    AreaComunService.java
  controller/
    AreaComunController.java

com/condos/reservacion/
  model/
    EstadoReservacion.java
    Reservacion.java
  repository/
    ReservacionRepository.java
  dto/
    CreateReservacionRequest.java
    ReservacionResponse.java
  service/
    ReservacionService.java      ← importa CuotaUsuarioRepository de com.condos.pago
  controller/
    ReservacionController.java
```

### Endpoints `/api/areas-comunes`

| Método | Path | Descripción | Roles |
|--------|------|-------------|-------|
| `GET` | `/` | Lista áreas: USUARIO = solo activas; ADMIN = todas | Autenticados |
| `POST` | `/` | Crear área | ADMIN, SUPERADMIN |
| `PUT` | `/{id}` | Editar área | ADMIN, SUPERADMIN |
| `PUT` | `/{id}/toggle` | Activar / desactivar | ADMIN, SUPERADMIN |
| `GET` | `/{id}/disponibilidad?fecha=YYYY-MM-DD` | Bloques del día con disponibilidad | USUARIO, ADMIN, SUPERADMIN |

### Endpoints `/api/reservaciones`

| Método | Path | Descripción | Roles |
|--------|------|-------------|-------|
| `GET` | `/` | Todas las reservaciones del condo | ADMIN, SUPERADMIN |
| `GET` | `/mis-reservaciones` | Reservaciones del USUARIO autenticado | USUARIO |
| `POST` | `/` | Crear reservación | USUARIO |
| `DELETE` | `/{id}` | Cancelar reservación | USUARIO (propia), ADMIN |

### DTOs clave

**CreateAreaComunRequest:**
```java
String nombre, descripcion
int capacidad, duracionBloqueMinutos, maxReservasMesPorUsuario
int anticipacionMinimaHoras, anticipacionMaximaDias
LocalTime horarioInicio, horarioFin
boolean activa
```

**AreaComunResponse:**
```java
Long id, String nombre, String descripcion, int capacidad
LocalTime horarioInicio, LocalTime horarioFin
int duracionBloqueMinutos, maxReservasMesPorUsuario
int anticipacionMinimaHoras, anticipacionMaximaDias
boolean activa, LocalDateTime createdAt
```

**BloqueDisponibilidadResponse:**
```java
LocalDateTime fechaHoraInicio, LocalDateTime fechaHoraFin
boolean disponible
```

**CreateReservacionRequest:**
```java
Long areaComunId
LocalDateTime fechaHoraInicio
```

**ReservacionResponse:**
```java
Long id, Long areaComunId, String areaComunNombre
Long usuarioId, String usuarioNombre
LocalDateTime fechaHoraInicio, LocalDateTime fechaHoraFin
EstadoReservacion estado, LocalDateTime createdAt
```

### Lógica de disponibilidad

`GET /{id}/disponibilidad?fecha=YYYY-MM-DD`:
1. Obtener el área por id
2. Generar todos los bloques del día: desde `horario_inicio` hasta `horario_fin` con saltos de `duracion_bloque_minutos`
3. Excluir bloques cuya `fecha_hora_inicio` ya pasó (`< now()`)
4. Excluir bloques con reservación `ACTIVA` existente
5. Devolver lista de `BloqueDisponibilidadResponse` con `disponible = true/false`

---

## Flutter

### Nuevos archivos

```
lib/features/areas/
  models/
    area_comun.dart + .g.dart
    create_area_comun_request.dart + .g.dart
    bloque_disponibilidad.dart + .g.dart
    reservacion.dart + .g.dart
    create_reservacion_request.dart + .g.dart
  services/
    area_comun_service.dart
    reservacion_service.dart
  providers/
    area_comun_provider.dart
    reservacion_provider.dart
  screens/
    areas_screen.dart               # USUARIO: tabs Áreas / Mis Reservas; ADMIN: lista + FAB
    crear_editar_area_screen.dart   # ADMIN: form crear/editar
    disponibilidad_screen.dart      # USUARIO: DatePicker + grid de bloques
```

### ApiConstants nuevos

```dart
static const String areasComunesPath = '$apiPrefix/areas-comunes';
static String areaComunById(int id) => '$apiPrefix/areas-comunes/$id';
static String toggleAreaComun(int id) => '$apiPrefix/areas-comunes/$id/toggle';
static String disponibilidad(int id) => '$apiPrefix/areas-comunes/$id/disponibilidad';
static const String reservaciones = '$apiPrefix/reservaciones';
static const String misReservaciones = '$apiPrefix/reservaciones/mis-reservaciones';
static String cancelarReservacion(int id) => '$apiPrefix/reservaciones/$id';
```

### Estado Riverpod

**AreaComunProvider:**
```dart
class AreaComunState { List<AreaComun> areas; bool isLoading; String? error; }
// cargarAreas(), crearArea(), editarArea(), toggleActiva()
```

**ReservacionProvider:**
```dart
class ReservacionState { List<Reservacion> reservaciones; List<Reservacion> misReservaciones; bool isLoading; String? error; }
// cargarReservaciones(), cargarMisReservaciones(), crearReservacion(), cancelarReservacion()
```

Los bloques de disponibilidad se cargan localmente en `DisponibilidadScreen` usando `areaComunServiceProvider` directamente (igual que comentarios en incidentes).

### Pantallas

**AreasScreen** — comportamiento según rol:

*USUARIO* — `DefaultTabController` con 2 tabs:
- Tab "Áreas": lista de áreas activas con nombre, capacidad, horario. Tap → `DisponibilidadScreen`
- Tab "Mis Reservas": lista de sus reservaciones ordenadas por fecha. Chip ACTIVA (verde) / CANCELADA (gris). Botón "Cancelar" en reservaciones ACTIVA futuras.

*ADMIN* — lista de todas las áreas:
- Chip activa/inactiva
- Botón switch para toggle activa
- FAB `+` → `CrearEditarAreaScreen` (crear)
- Tap → `CrearEditarAreaScreen` (editar)

**CrearEditarAreaScreen** (ADMIN):
- `TextFormField`: nombre (requerido), descripción (opcional)
- `TextFormField` numérico: capacidad, max reservas/mes, anticipación mínima (horas), anticipación máxima (días)
- `DropdownButtonFormField`: duración bloque (30 / 60 / 90 / 120 minutos)
- `ListTile` con `TimePicker`: horario inicio y horario fin
- `Switch`: activa

**DisponibilidadScreen** (USUARIO):
- Header: nombre del área, horario, duración de bloque, capacidad
- `CalendarDatePicker` para seleccionar fecha (limitado por anticipación mínima y máxima)
- Grid de bloques del día: verde = disponible, gris = ocupado
- Tap en bloque verde → `AlertDialog` con info del bloque + botón "Confirmar reservación"

### Navegación

Tab "Áreas" (`Icons.meeting_room_outlined`) agregado a USUARIO y ADMIN antes de "Avisos":
- **USUARIO** (9 tabs): Inicio, Visitas, Nueva, Paquetes, Incidentes, Cuotas, Áreas, Avisos, Perfil
- **ADMIN** (9 tabs): Dashboard, Visitas, Paquetes, Incidentes, Gestión, Cuotas, Áreas, Avisos, Perfil
- **GUARDIA**: sin cambios

Nuevas rutas GoRouter:
```
/home/areas/nueva            → CrearEditarAreaScreen (sin parámetro = crear)
/home/areas/:id/editar       → CrearEditarAreaScreen (con id = editar)
/home/areas/:id/disponibilidad → DisponibilidadScreen
```

---

## Out of Scope

- Foto del área
- Pagos por uso de área
- Notificaciones push al crear reservación
- Aprobación manual de reservaciones por ADMIN (auto-aprobadas)
- GUARDIA: sin acceso al módulo
