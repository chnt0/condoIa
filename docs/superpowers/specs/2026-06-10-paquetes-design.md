# Paquetes — Design Spec

**Date:** 2026-06-10  
**Scope:** Módulo de gestión de paquetes recibidos en portería. GUARDIA registra y entrega, USUARIO ve los suyos, ADMIN solo lectura.

---

## Context

El sistema de condominios necesita que el GUARDIA pueda registrar paquetes que llegan a portería y marcarlos como entregados cuando el residente los recoge en persona. Los residentes (USUARIO) pueden consultar sus paquetes pendientes e historial de entregados. El ADMIN puede ver todos los paquetes del condominio como referencia.

**Out of scope:** Foto del paquete (to-do futuro), notificaciones push al llegar un paquete.

---

## Roles involucrados

- `GUARDIA` — registra paquetes y los marca como entregados
- `USUARIO` — ve sus propios paquetes (tabs: pendientes / entregados)
- `ADMIN` / `SUPERADMIN` — ve todos los paquetes del condominio (solo lectura)

---

## Data Model — nueva tabla

### `paquetes`

| Columna | Tipo | Descripción |
|---------|------|-------------|
| `id` | BIGSERIAL PK | |
| `condominio_id` | BIGINT FK → condominios | Multi-tenancy |
| `usuario_destinatario_id` | BIGINT FK → usuarios | Residente destinatario |
| `descripcion` | VARCHAR(500) NOT NULL | Descripción del paquete |
| `notas` | TEXT NULL | Notas opcionales del guardia |
| `fecha_hora_llegada` | TIMESTAMP NOT NULL | Auto-set al crear |
| `guardia_registro_id` | BIGINT FK → usuarios | Guardia que lo registró |
| `estado` | ENUM `estado_paquete` | `PENDIENTE` o `ENTREGADO` |
| `fecha_hora_entrega` | TIMESTAMP NULL | Cuándo fue entregado |
| `guardia_entrega_id` | BIGINT FK → usuarios NULL | Guardia que lo entregó |
| `created_at` | TIMESTAMP | |
| `updated_at` | TIMESTAMP | |

**Migración:** `V4__create_paquetes_table.sql`

---

## Business Rules

1. Al registrar un paquete, `estado = PENDIENTE` y `fecha_hora_llegada = NOW()`.
2. Solo el GUARDIA puede marcar como `ENTREGADO`. Al hacerlo se setean `fecha_hora_entrega = NOW()` y `guardia_entrega_id`.
3. Un paquete ya entregado no puede volver a PENDIENTE.
4. El GUARDIA selecciona al destinatario por unidad habitacional usando el endpoint `/api/usuarios/residentes`.

---

## Backend

### Nuevos archivos

```
com/condos/paquete/
  model/
    EstadoPaquete.java
    Paquete.java
  repository/
    PaqueteRepository.java
  dto/
    CreatePaqueteRequest.java
    PaqueteResponse.java
  service/
    PaqueteService.java
  controller/
    PaqueteController.java
```

### Endpoint adicional en UsuarioController

`GET /api/usuarios/residentes` — devuelve lista básica (id, nombreCompleto, unidadHabitacional) de usuarios activos con rol `USUARIO` en el condominio actual. Accesible por `GUARDIA`, `ADMIN`, `SUPERADMIN`.

DTO nuevo: `ResidenteBasicoResponse.java` (id, nombreCompleto, unidadHabitacional).

### Endpoints `/api/paquetes`

| Método | Path | Descripción | Roles |
|--------|------|-------------|-------|
| `GET` | `/` | Todos los paquetes del condo | ADMIN, SUPERADMIN, GUARDIA |
| `GET` | `/mis-paquetes` | Paquetes del residente autenticado | USUARIO |
| `POST` | `/` | Registrar nuevo paquete | GUARDIA |
| `PUT` | `/{id}/entregar` | Marcar como entregado | GUARDIA |

### DTOs

**CreatePaqueteRequest:**
```java
Long usuarioDestinatarioId   // requerido
String descripcion           // requerido
String notas                 // opcional
```

**PaqueteResponse:**
```java
Long id
Long usuarioDestinatarioId
String destinatarioNombre
String destinatarioUnidad
String descripcion
String notas
LocalDateTime fechaHoraLlegada
Long guardiaRegistroId
String guardiaRegistroNombre
EstadoPaquete estado
LocalDateTime fechaHoraEntrega
Long guardiaEntregaId
String guardiaEntregaNombre
LocalDateTime createdAt
```

---

## Flutter

### Nuevos archivos

```
lib/features/paquetes/
  models/
    paquete.dart + .g.dart
    create_paquete_request.dart + .g.dart
    residente_basico.dart + .g.dart
  services/
    paquete_service.dart
  providers/
    paquete_provider.dart
  screens/
    paquetes_screen.dart           # Compartida: tabs Pendientes/Entregados
    registrar_paquete_screen.dart  # Solo GUARDIA
```

### ApiConstants nuevos

```dart
static const String paquetes = '$apiPrefix/paquetes';
static const String misPaquetes = '$apiPrefix/paquetes/mis-paquetes';
static String entregarPaquete(int id) => '$apiPrefix/paquetes/$id/entregar';
static const String residentes = '$apiPrefix/usuarios/residentes';
```

### Estado Riverpod

```dart
class PaqueteState {
  final List<Paquete> paquetes;   // GUARDIA y ADMIN: todos; USUARIO: los suyos
  final bool isLoading;
  final String? error;
}

class PaqueteNotifier extends StateNotifier<PaqueteState> {
  Future<void> cargarPaquetes()           // GUARDIA/ADMIN: GET /api/paquetes
  Future<void> cargarMisPaquetes()        // USUARIO: GET /api/paquetes/mis-paquetes
  Future<Paquete?> registrarPaquete(CreatePaqueteRequest)
  Future<void> entregarPaquete(int id)
}
```

### Pantallas

**PaquetesScreen** (compartida, con `DefaultTabController`):
- Tab "Pendientes" — filtro `estado == PENDIENTE`, chip naranja
- Tab "Entregados" — filtro `estado == ENTREGADO`, chip verde
- Cada item muestra: descripción, unidad del destinatario, fecha llegada
- GUARDIA: FAB `+` → RegistrarPaqueteScreen + botón "Entregar" en items pendientes
- USUARIO y ADMIN: sin FAB, sin botón entregar (solo lectura)

**RegistrarPaqueteScreen** (solo GUARDIA):
- `TextField`: descripción (requerido)
- `TextField`: notas (opcional)  
- Selector de residente: lista scrolleable filtrada con `TextField` de búsqueda por unidad habitacional, cargada desde `/api/usuarios/residentes`
- Botón "Registrar Paquete"

### Navegación — cambios a MainScaffold y GoRouter

**GUARDIA** — agregar tab "Paquetes" como 2do tab (entre "Escanear" y "Hoy"):
- Icon: `Icons.inventory_2_outlined`
- Label: "Paquetes"

**USUARIO** — agregar tab "Paquetes" como 4to tab (entre "Nueva" y "Cuotas"):
- Icon: `Icons.inventory_2_outlined`
- Label: "Paquetes"

**ADMIN** — agregar tab "Paquetes" como 3er tab (entre "Visitas" y "Gestión"):
- Icon: `Icons.inventory_2_outlined`
- Label: "Paquetes"

**Nueva ruta GoRouter** (sub-ruta bajo `/home`):
```
/home/paquetes/nuevo    → RegistrarPaqueteScreen (GUARDIA)
```

---

## Out of Scope

- Foto del paquete al registrar (to-do futuro)
- Notificaciones push al llegar un paquete
- El USUARIO confirma recepción desde la app (el GUARDIA es quien entrega y registra)
- Cancelación/eliminación de paquetes por ADMIN
