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
2. **Conflicto de bloque:** No se puede crear una reservación si existe otra `ACTIVA` para la misma área con el mismo `fecha_hora_inicio`.
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
  model/AreaComun.java
  repository/AreaComunRepository.java
  dto/CreateAreaComunRequest.java
  dto/AreaComunResponse.java
  dto/BloqueDisponibilidadResponse.java
  service/AreaComunService.java
  controller/AreaComunController.java

com/condos/reservacion/
  model/EstadoReservacion.java
  model/Reservacion.java
  repository/ReservacionRepository.java
  dto/CreateReservacionRequest.java
  dto/ReservacionResponse.java
  service/ReservacionService.java    ← importa CuotaUsuarioRepository de com.condos.pago
  controller/ReservacionController.java
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

---

## Flutter — implementado

```
lib/features/areas/
  models/ (5 modelos + .g.dart)
  services/ (AreaComunService, ReservacionService)
  providers/ (AreaComunProvider, ReservacionProvider)
  screens/
    areas_screen.dart           — ADMIN: lista+toggle; USUARIO: tabs
    crear_editar_area_screen.dart
    disponibilidad_screen.dart  — DatePicker + grid bloques
```

**Navegación:** Tab "Áreas" índice 6 en USUARIO y ADMIN.

---

## Out of Scope

- Foto del área (to-do futuro)
- Pagos por uso de área
- Notificaciones push al crear reservación
- Aprobación manual de reservaciones por ADMIN
- GUARDIA: sin acceso al módulo
