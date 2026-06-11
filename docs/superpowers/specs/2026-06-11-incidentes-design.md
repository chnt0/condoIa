# Incidentes — Design Spec

**Date:** 2026-06-11  
**Scope:** Módulo de reporte y seguimiento de incidentes. USUARIO reporta y puede cancelar. ADMIN gestiona estados y ambos comentan.

---

## Context

Los residentes necesitan un canal formal para reportar problemas en el condominio (ruido, mantenimiento, seguridad, limpieza). El ADMIN gestiona el ciclo de vida de cada incidente cambiando su estado y comunicándose con el residente mediante comentarios.

**Out of scope:** Fotos adjuntas (to-do futuro), notificaciones push al cambiar estado, asignación de incidentes a técnicos.

---

## Roles involucrados

- `USUARIO` — crea incidentes, ve los propios, puede cancelarlos (si no están ya RESUELTOS o CANCELADOS), puede comentar en los suyos
- `ADMIN` / `SUPERADMIN` — ve todos los incidentes del condominio, cambia estado, comenta en cualquiera
- `GUARDIA` — sin acceso al módulo

---

## Data Model — 2 nuevas tablas

### `incidentes`

| Columna | Tipo | Descripción |
|---------|------|-------------|
| `id` | BIGSERIAL PK | |
| `condominio_id` | BIGINT FK → condominios | |
| `usuario_reporta_id` | BIGINT FK → usuarios | Residente que reporta |
| `categoria` | ENUM `categoria_incidente` | `MANTENIMIENTO`, `SEGURIDAD`, `RUIDO`, `LIMPIEZA`, `OTRO` |
| `titulo` | VARCHAR(200) NOT NULL | |
| `descripcion` | TEXT NOT NULL | |
| `ubicacion` | VARCHAR(200) NOT NULL | Área o unidad afectada |
| `prioridad` | ENUM `prioridad_incidente` | `BAJA`, `MEDIA`, `ALTA` |
| `estado` | ENUM `estado_incidente` | `PENDIENTE`, `EN_PROCESO`, `RESUELTO`, `CANCELADO` |
| `created_at` | TIMESTAMP | |
| `updated_at` | TIMESTAMP | |

**Migración:** `V5__create_incidentes_tables.sql`

### `incidente_comentarios`

| Columna | Tipo | Descripción |
|---------|------|-------------|
| `id` | BIGSERIAL PK | |
| `incidente_id` | BIGINT FK → incidentes | |
| `usuario_id` | BIGINT FK → usuarios | Quien comenta |
| `comentario` | TEXT NOT NULL | |
| `created_at` | TIMESTAMP | |

---

## Business Rules

1. Al crear un incidente, `estado = PENDIENTE`.
2. Solo ADMIN puede cambiar el estado: `PENDIENTE → EN_PROCESO → RESUELTO` (cualquier transición hacia adelante; no se puede retroceder).
3. El USUARIO puede cancelar su incidente si está en `PENDIENTE` o `EN_PROCESO`. Cancelar pone `estado = CANCELADO`.
4. Un incidente `RESUELTO` o `CANCELADO` no puede cambiar de estado.
5. Los incidentes `CANCELADO` no aparecen en ningún tab de la lista — solo son visibles en el detalle si se navega directamente.
6. Tanto USUARIO (en sus propios incidentes) como ADMIN pueden agregar comentarios.

---

## Backend

### Nuevos archivos

```
com/condos/incidente/
  model/
    CategoriaIncidente.java
    PrioridadIncidente.java
    EstadoIncidente.java
    Incidente.java
    IncidenteComentario.java
  repository/
    IncidenteRepository.java
    IncidenteComentarioRepository.java
  dto/
    CreateIncidenteRequest.java
    UpdateEstadoRequest.java
    IncidenteResponse.java
    ComentarioResponse.java
    AddComentarioRequest.java
  service/
    IncidenteService.java
  controller/
    IncidenteController.java
```

### Endpoints `/api/incidentes`

| Método | Path | Descripción | Roles |
|--------|------|-------------|-------|
| `GET` | `/` | Todos los incidentes del condo | ADMIN, SUPERADMIN |
| `GET` | `/mis-incidentes` | Incidentes del usuario autenticado | USUARIO |
| `POST` | `/` | Crear incidente | USUARIO |
| `PUT` | `/{id}/estado` | Cambiar estado | ADMIN, SUPERADMIN |
| `DELETE` | `/{id}` | Cancelar (estado → CANCELADO) | USUARIO |
| `GET` | `/{id}/comentarios` | Lista de comentarios | USUARIO, ADMIN, SUPERADMIN |
| `POST` | `/{id}/comentarios` | Agregar comentario | USUARIO, ADMIN, SUPERADMIN |

### DTOs

**CreateIncidenteRequest:**
```java
CategoriaIncidente categoria   // requerido
String titulo                  // requerido
String descripcion             // requerido
String ubicacion               // requerido
PrioridadIncidente prioridad   // requerido
```

**UpdateEstadoRequest:**
```java
EstadoIncidente estado   // EN_PROCESO o RESUELTO
```

**IncidenteResponse:**
```java
Long id
CategoriaIncidente categoria
String titulo
String descripcion
String ubicacion
PrioridadIncidente prioridad
EstadoIncidente estado
Long usuarioReportaId
String usuarioReportaNombre
String usuarioReportaUnidad
LocalDateTime createdAt
LocalDateTime updatedAt
```

**ComentarioResponse:**
```java
Long id
Long incidenteId
Long usuarioId
String usuarioNombre
String comentario
LocalDateTime createdAt
```

**AddComentarioRequest:**
```java
String comentario   // requerido
```

---

## Flutter

### Nuevos archivos

```
lib/features/incidentes/
  models/
    incidente.dart + .g.dart
    create_incidente_request.dart + .g.dart
    update_estado_request.dart + .g.dart
    comentario.dart + .g.dart
    add_comentario_request.dart + .g.dart
  services/
    incidente_service.dart
  providers/
    incidente_provider.dart
  screens/
    incidentes_screen.dart          # tabs: Pendiente / En Proceso / Resuelto
    crear_incidente_screen.dart     # solo USUARIO
    detalle_incidente_screen.dart   # USUARIO y ADMIN
```

### ApiConstants nuevos

```dart
static const String incidentes = '$apiPrefix/incidentes';
static const String misIncidentes = '$apiPrefix/incidentes/mis-incidentes';
static String incidenteEstado(int id) => '$apiPrefix/incidentes/$id/estado';
static String cancelarIncidente(int id) => '$apiPrefix/incidentes/$id';
static String incidenteComentarios(int id) => '$apiPrefix/incidentes/$id/comentarios';
```

### Estado Riverpod

```dart
class IncidenteState {
  final List<Incidente> incidentes;
  final bool isLoading;
  final String? error;
}

class IncidenteNotifier extends StateNotifier<IncidenteState> {
  Future<void> cargarIncidentes()           // ADMIN: GET /api/incidentes
  Future<void> cargarMisIncidentes()        // USUARIO: GET /api/incidentes/mis-incidentes
  Future<Incidente?> crearIncidente(CreateIncidenteRequest)
  Future<void> actualizarEstado(int id, UpdateEstadoRequest)
  Future<void> cancelarIncidente(int id)
}
```

Los comentarios se cargan localmente en `DetalleIncidenteScreen` (no en el provider global) para no saturar el estado.

### Pantallas

**IncidentesScreen** (3 tabs con `DefaultTabController`):
- Tab "Pendiente" — chip rojo, muestra prioridad y categoría
- Tab "En Proceso" — chip azul
- Tab "Resuelto" — chip verde
- Incidentes CANCELADOS: no aparecen en ningún tab
- USUARIO: FAB `+` → `CrearIncidenteScreen`
- ADMIN: sin FAB
- Tap en ítem → `DetalleIncidenteScreen`

**CrearIncidenteScreen** (solo USUARIO):
- `DropdownButtonFormField`: categoría (MANTENIMIENTO / SEGURIDAD / RUIDO / LIMPIEZA / OTRO)
- `DropdownButtonFormField`: prioridad (BAJA / MEDIA / ALTA)
- `TextFormField`: título (requerido)
- `TextFormField`: descripción multiline (requerido)
- `TextFormField`: ubicación (requerido)
- Botón "Reportar Incidente"

**DetalleIncidenteScreen** (USUARIO y ADMIN):
- Header con: título, categoría, prioridad, ubicación, estado (chip), fecha, reportado por
- **ADMIN:** `DropdownButton` para elegir nuevo estado + botón "Actualizar estado" (visible si estado ≠ RESUELTO y ≠ CANCELADO)
- **USUARIO:** botón "Cancelar incidente" en rojo (visible si estado == PENDIENTE o EN_PROCESO)
- Divider "Comentarios"
- Lista de comentarios con nombre del autor y fecha
- Campo de texto + botón "Comentar" al fondo (accesible para USUARIO dueño y ADMIN)

### Navegación

**USUARIO** — agregar tab "Incidentes" como 5to tab (entre "Paquetes" y "Cuotas"):
- Icon: `Icons.report_outlined`
- Label: "Incidentes"

**ADMIN** — agregar tab "Incidentes" como 4to tab (entre "Paquetes" y "Gestión"):
- Icon: `Icons.report_outlined`
- Label: "Incidentes"

**Nuevas rutas GoRouter** (sub-rutas bajo `/home`):
```
/home/incidentes/nuevo    → CrearIncidenteScreen (USUARIO)
/home/incidentes/:id      → DetalleIncidenteScreen (USUARIO y ADMIN)
```

---

## Out of Scope

- Fotos adjuntas al incidente (to-do futuro)
- Notificaciones push al cambiar estado
- Asignación de incidentes a técnicos o responsables
- GUARDIA: sin acceso al módulo
