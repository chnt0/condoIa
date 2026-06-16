# SUPERADMIN — Design Spec

**Date:** 2026-06-16  
**Scope:** Panel de administración global para el rol SUPERADMIN. Gestiona condominios como entidades y crea usuarios ADMIN para cada uno. No accede a los datos operativos (visitas, incidentes, etc.) de cada condominio.

---

## Context

El rol `SUPERADMIN` ya existe en la BD, el JWT y el enum `Rol.java`, pero nunca tuvo pantallas ni endpoints propios. El `condominioId` del JWT es `null` para este rol, lo que le permite operar sin restricción de tenant.

**Out of scope:** Ver datos operativos de cada condominio (visitas, incidentes, pagos), gestión de usuarios no-ADMIN desde el panel SUPERADMIN.

---

## Roles

- `SUPERADMIN` — único rol con acceso a este módulo. Gestiona condominios y sus admins.

---

## Data Model — sin cambios

La tabla `condominios` ya existe con:

| Columna | Tipo |
|---|---|
| `id` | BIGSERIAL PK |
| `nombre` | VARCHAR(200) |
| `direccion` | VARCHAR(500) |
| `num_unidades` | INT |
| `activo` | BOOLEAN |
| `created_at` / `updated_at` | TIMESTAMP |

No se requieren migraciones adicionales.

---

## Backend

### Nuevos archivos

```
com/condos/condominio/
  dto/
    CreateCondominioRequest.java
    CondominioResponse.java
  service/
    CondominioService.java
  controller/
    CondominioController.java
```

### Endpoints `/api/condominios`

| Método | Path | Descripción | Rol |
|---|---|---|---|
| `GET /` | Lista todos los condominios | SUPERADMIN |
| `POST /` | Crear condominio | SUPERADMIN |
| `PUT /{id}` | Editar condominio | SUPERADMIN |
| `PUT /{id}/toggle` | Activar / desactivar | SUPERADMIN |
| `GET /{id}/admins` | Lista admins del condominio | SUPERADMIN |

Para crear un ADMIN de un condominio se reutiliza `POST /api/usuarios` que ya permite a SUPERADMIN crear cualquier usuario en cualquier condominio.

### DTOs

**CreateCondominioRequest:**
```java
String nombre         // requerido
String direccion      // requerido
Integer numUnidades   // requerido, > 0
boolean activo        // default true
```

**CondominioResponse:**
```java
Long id
String nombre
String direccion
int numUnidades
boolean activo
LocalDateTime createdAt
int totalUsuarios      // count de usuarios activos
int totalAdmins        // count de admins activos
```

---

## Flutter

### Nuevos archivos

```
lib/features/superadmin/
  models/
    condominio.dart + .g.dart
    create_condominio_request.dart + .g.dart
  services/
    condominio_service.dart
  providers/
    condominio_provider.dart
  screens/
    superadmin_dashboard_screen.dart
    condominios_screen.dart
    crear_editar_condominio_screen.dart
    detalle_condominio_screen.dart
```

### ApiConstants nuevos

```dart
static const String condominios = '$apiPrefix/condominios';
static String condominioById(int id) => '$apiPrefix/condominios/$id';
static String toggleCondominio(int id) => '$apiPrefix/condominios/$id/toggle';
static String condominioAdmins(int id) => '$apiPrefix/condominios/$id/admins';
```

### Pantallas

**`SuperadminDashboardScreen`** (home del SUPERADMIN):
- Tarjetas stats: total condominios, activos, inactivos
- Lista de condominios con nombre, dirección, num. unidades, badge activo/inactivo
- FAB `+` → `CrearEditarCondominioScreen`
- Tap en condominio → `DetalleCondominioScreen`

**`CrearEditarCondominioScreen`**:
- `TextFormField`: nombre (requerido)
- `TextFormField`: dirección (requerido)
- `TextFormField` numérico: número de unidades (requerido)
- `SwitchListTile`: activo

**`DetalleCondominioScreen`**:
- Header: nombre, dirección, unidades, badge activo
- Botón "Editar" → `CrearEditarCondominioScreen` en modo edición
- Botón "Activar/Desactivar"
- Lista de usuarios ADMIN del condominio (nombre, username, activo)
- Botón "Agregar Admin" → formulario inline o dialog para crear usuario ADMIN

### Navegación

El SUPERADMIN tiene su propio MainScaffold con 3 tabs:

| Tab | Índice | Pantalla |
|---|---|---|
| Dashboard | 0 | `SuperadminDashboardScreen` |
| Condominios | 1 | `CondominiosScreen` (lista separada) |
| Perfil | 2 | `PerfilScreen` |

En `MainScaffold._buildScreens()` y `_buildItems()`, agregar el caso `Rol.superadmin` con estas 3 pantallas y tabs.

**Rutas GoRouter nuevas:**
```
/home/condominios/nuevo           → CrearEditarCondominioScreen
/home/condominios/:id/editar      → CrearEditarCondominioScreen (edición)
/home/condominios/:id/detalle     → DetalleCondominioScreen
```

---

## Out of Scope

- Ver datos operativos de cada condominio (visitas, incidentes, reservaciones, etc.)
- Gestión de usuarios no-ADMIN desde el panel SUPERADMIN
- Estadísticas de uso por condominio (morosos, reservaciones activas, etc.)
