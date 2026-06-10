# Pagos / Cuotas — Design Spec

**Date:** 2026-06-10  
**Scope:** Módulo de gestión de cuotas y pagos para ADMIN y USUARIO. Backend Spring Boot + Flutter.

---

## Context

El sistema de condominios necesita que el ADMIN pueda generar cobros (cuotas mensuales y extraordinarias) y que los residentes (USUARIO) puedan reportar sus pagos para que el ADMIN los confirme.

**Roles involucrados:**
- `ADMIN` / `SUPERADMIN` — crean cuotas, ven detalle por residente, confirman/rechazan pagos
- `USUARIO` — ve sus cuotas pendientes e historial, reporta cuando paga

---

## Data Model — 2 nuevas tablas

### `cuotas`

Representa la definición del cobro.

| Columna | Tipo | Descripción |
|---------|------|-------------|
| `id` | BIGSERIAL PK | |
| `condominio_id` | BIGINT FK → condominios | |
| `tipo` | ENUM `tipo_cuota` | `MENSUAL` o `EXTRAORDINARIA` |
| `concepto` | VARCHAR(255) | Descripción del cobro (ej: "Mantenimiento Enero 2025") |
| `monto` | NUMERIC(10,2) | Monto en la moneda local |
| `mes` | VARCHAR(7) | Solo para MENSUAL: formato `YYYY-MM` (ej: `"2025-01"`) |
| `fecha_vencimiento` | DATE | Fecha límite de pago |
| `created_at` | TIMESTAMP | |
| `updated_at` | TIMESTAMP | |

### `cuota_usuarios`

Una fila por cada par (cuota, residente). Registra el estado del pago de ese residente para esa cuota.

| Columna | Tipo | Descripción |
|---------|------|-------------|
| `id` | BIGSERIAL PK | |
| `cuota_id` | BIGINT FK → cuotas | |
| `usuario_id` | BIGINT FK → usuarios | |
| `estado` | ENUM `estado_pago` | `PENDIENTE`, `REPORTADO`, `CONFIRMADO`, `RECHAZADO` |
| `referencia_pago` | VARCHAR(255) | Número de transferencia o referencia que ingresa el USUARIO |
| `notas_usuario` | TEXT | Notas opcionales del USUARIO al reportar |
| `notas_admin` | TEXT | Comentario del ADMIN al confirmar/rechazar |
| `fecha_reporte` | TIMESTAMP | Cuando el USUARIO reportó el pago |
| `fecha_confirmacion` | TIMESTAMP | Cuando el ADMIN confirmó o rechazó |
| `created_at` | TIMESTAMP | |
| `updated_at` | TIMESTAMP | |

**Restricción:** `UNIQUE(cuota_id, usuario_id)` — un residente tiene exactamente un registro por cuota.

---

## Business Rules

1. **Crear cuota MENSUAL** → el backend genera automáticamente una `cuota_usuario` en estado `PENDIENTE` por cada usuario con rol `USUARIO` activo en el condominio.
2. **Crear cuota EXTRAORDINARIA** → el ADMIN incluye una lista de `usuarioIds`; se generan `cuota_usuario` solo para esos usuarios.
3. **Reportar pago** (USUARIO) → el USUARIO proporciona `referencia_pago` y `notas_usuario` opcionales; estado cambia de `PENDIENTE` o `RECHAZADO` a `REPORTADO`.
4. **Confirmar pago** (ADMIN) → estado cambia a `CONFIRMADO`; ADMIN puede agregar `notas_admin`.
5. **Rechazar pago** (ADMIN) → estado cambia a `RECHAZADO`; ADMIN debe proporcionar `notas_admin` explicando el motivo.
6. Si el estado es `RECHAZADO`, el USUARIO puede volver a reportar (el registro se actualiza, no se crea uno nuevo).

---

## Backend

### Nuevos archivos

```
com/condos/pago/
  model/
    TipoCuota.java          # enum: MENSUAL, EXTRAORDINARIA
    EstadoPago.java         # enum: PENDIENTE, REPORTADO, CONFIRMADO, RECHAZADO
    Cuota.java
    CuotaUsuario.java
  repository/
    CuotaRepository.java
    CuotaUsuarioRepository.java
  dto/
    CreateCuotaRequest.java
    ReportarPagoRequest.java
    ConfirmarPagoRequest.java
    CuotaResponse.java
    CuotaUsuarioResponse.java
  service/
    CuotaService.java
  controller/
    CuotaController.java
```

### Endpoints — `@RequestMapping("/api/cuotas")`

| Método | Path | Descripción | Roles |
|--------|------|-------------|-------|
| `GET` | `/` | Lista cuotas del condominio con resumen (total / confirmados / pendientes) | ADMIN, SUPERADMIN |
| `POST` | `/` | Crea cuota MENSUAL o EXTRAORDINARIA | ADMIN, SUPERADMIN |
| `GET` | `/mis-cuotas` | Lista cuota_usuarios del residente autenticado | USUARIO |
| `GET` | `/{id}/detalle` | Detalle de cuota con lista de cuota_usuario por residente | ADMIN, SUPERADMIN |
| `PUT` | `/{cuotaUsuarioId}/reportar` | USUARIO reporta su pago | USUARIO |
| `PUT` | `/{cuotaUsuarioId}/confirmar` | ADMIN confirma o rechaza pago | ADMIN, SUPERADMIN |

### DTOs

**CreateCuotaRequest:**
```java
TipoCuota tipo             // MENSUAL o EXTRAORDINARIA
String concepto            // requerido
BigDecimal monto           // requerido, > 0
String mes                 // requerido si tipo = MENSUAL (formato "YYYY-MM")
LocalDate fechaVencimiento // requerido
List<Long> usuarioIds      // requerido si tipo = EXTRAORDINARIA; vacío o null = todos para MENSUAL
```

**ReportarPagoRequest:**
```java
String referenciaPago      // requerido
String notasUsuario        // opcional
```

**ConfirmarPagoRequest:**
```java
boolean confirmado         // true = CONFIRMADO, false = RECHAZADO
String notasAdmin          // requerido si confirmado = false
```

**CuotaResponse:**
```java
Long id
TipoCuota tipo
String concepto
BigDecimal monto
String mes
LocalDate fechaVencimiento
int totalResidentes
int totalConfirmados
int totalReportados
int totalPendientes
LocalDateTime createdAt
```

**CuotaUsuarioResponse:**
```java
Long id
Long cuotaId
String concepto
BigDecimal monto
LocalDate fechaVencimiento
Long usuarioId
String usuarioNombre
String unidadHabitacional
EstadoPago estado
String referenciaPago
String notasUsuario
String notasAdmin
LocalDateTime fechaReporte
LocalDateTime fechaConfirmacion
```

### Migración DB

Nueva migración `V3__create_pagos_tables.sql`.

---

## Flutter

### Nuevos archivos

```
lib/features/pagos/
  models/
    cuota.dart + .g.dart
    cuota_usuario.dart + .g.dart
    create_cuota_request.dart + .g.dart
    reportar_pago_request.dart + .g.dart
    confirmar_pago_request.dart + .g.dart
  services/
    cuota_service.dart
  providers/
    cuota_provider.dart
  screens/
    cuotas_admin_screen.dart       # ADMIN: lista de cuotas con resumen
    crear_cuota_screen.dart        # ADMIN: formulario nueva cuota
    detalle_cuota_screen.dart      # ADMIN: lista de residentes con estado
    mis_cuotas_screen.dart         # USUARIO: sus cuotas pendientes e historial
    reportar_pago_screen.dart      # USUARIO: formulario de reporte
```

### Estado Riverpod

```dart
class CuotaState {
  final List<CuotaResponse> cuotas;           // para ADMIN
  final List<CuotaUsuarioResponse> misCuotas; // para USUARIO
  final bool isLoading;
  final String? error;
}

class CuotaNotifier extends StateNotifier<CuotaState> {
  Future<void> cargarCuotas()          // ADMIN: GET /api/cuotas
  Future<void> cargarMisCuotas()       // USUARIO: GET /api/cuotas/mis-cuotas
  Future<CuotaResponse?> crearCuota(CreateCuotaRequest)
  Future<List<CuotaUsuarioResponse>> obtenerDetalle(int cuotaId)
  Future<void> reportarPago(int cuotaUsuarioId, ReportarPagoRequest)
  Future<void> confirmarPago(int cuotaUsuarioId, ConfirmarPagoRequest)
}
```

### Pantallas

**ADMIN — CuotasAdminScreen:**
- Lista de cuotas del condominio ordenadas por fecha de creación desc
- Cada item: concepto, mes/tipo, monto, badge de progreso (ej: "12/20 confirmados")
- FAB `+` → CrearCuotaScreen
- Tap → DetalleCuotaScreen

**ADMIN — CrearCuotaScreen:**
- DropdownButton: MENSUAL / EXTRAORDINARIA
- Campos: concepto, monto, fecha vencimiento (DatePicker)
- Si MENSUAL: campo mes (formato MM/YYYY)
- Si EXTRAORDINARIA: lista de residentes con checkboxes para seleccionar destinatarios

**ADMIN — DetalleCuotaScreen:**
- Header con info de la cuota (concepto, monto, fecha vencimiento)
- Lista de residentes con estado badge (color: gris=PENDIENTE, amarillo=REPORTADO, verde=CONFIRMADO, rojo=RECHAZADO)
- Los REPORTADO tienen botones "Confirmar" y "Rechazar"
- Al rechazar: dialog para ingresar nota de rechazo

**USUARIO — MisCuotasScreen (nuevo tab en BottomNav):**
- Lista de cuota_usuarios con badge de estado
- Subtítulo con referencia si ya reportó, o fecha vencimiento si está pendiente
- Tap en PENDIENTE o RECHAZADO → ReportarPagoScreen

**USUARIO — ReportarPagoScreen:**
- Campo: referencia de pago (requerido)
- Campo: notas opcionales
- Si estado = RECHAZADO: muestra nota del admin en rojo antes del formulario
- Botón "Reportar Pago"

### Navegación — cambios a MainScaffold y GoRouter

**USUARIO** — agregar tab "Cuotas" (5to tab):
- Icon: `Icons.receipt_long`
- Label: "Cuotas"
- Screen: `MisCuotasScreen`

**Decisión:** Agregar tab "Cuotas" como 5to tab tanto a USUARIO como a ADMIN. La pantalla `GestionScreen` (usuarios) permanece intacta como tab 3 del ADMIN.

**Nuevas rutas GoRouter** (sub-rutas bajo `/home`):
```
/home/cuotas                → CuotasAdminScreen (ADMIN) o MisCuotasScreen (USUARIO)
/home/cuotas/nueva          → CrearCuotaScreen (ADMIN)
/home/cuotas/:id/detalle    → DetalleCuotaScreen (ADMIN)
/home/cuotas/:id/reportar   → ReportarPagoScreen (USUARIO)
```

### ApiConstants nuevos

```dart
static const String cuotas = '$apiPrefix/cuotas';
static const String misCuotas = '$apiPrefix/cuotas/mis-cuotas';
static String cuotaDetalle(int id) => '$apiPrefix/cuotas/$id/detalle';
static String reportarPago(int cuotaUsuarioId) => '$apiPrefix/cuotas/$cuotaUsuarioId/reportar';
static String confirmarPago(int cuotaUsuarioId) => '$apiPrefix/cuotas/$cuotaUsuarioId/confirmar';
```

---

## Out of Scope

- Cálculo automático de recargos por mora
- Integración con pasarelas de pago (Stripe, PayPal, etc.)
- Generación de recibos PDF
- Histórico de cambios de estado (audit log)
- Notificaciones push al reportar/confirmar (módulo pendiente separado)
