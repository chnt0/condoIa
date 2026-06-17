# Reporte de Cuotas + Morosidad Dashboard — Design Spec

**Date:** 2026-06-17  
**Scope:** (1) Pantalla de reporte de cuotas para ADMIN con filtros por mes y estado, exportable a CSV. (2) Sección de morosidad en el Dashboard del ADMIN mostrando total vencido, morosos y cuotas vencidas.

---

## Feature 1 — Reporte de Cuotas (ADMIN)

### Backend

**Nuevo endpoint:** `GET /api/cuotas/reporte?mes=2026-06&estado=TODOS`

- **Parámetros opcionales:**
  - `mes`: string formato `YYYY-MM` — filtra cuotas cuyo campo `mes` coincide, o cuya `fecha_vencimiento` cae en ese mes
  - `estado`: `TODOS` (default) | `CONFIRMADO` | `PENDIENTE` (incluye PENDIENTE y RECHAZADO)
- **Roles:** ADMIN, SUPERADMIN
- **Response:** Lista de `CuotaUsuarioResponse` (ya existe el DTO) filtrada

El filtrado se hace en `CuotaService.listarReporte(String mes, String estado)`:
- Query sobre `cuota_usuarios` JOIN `cuotas` del condominio actual (TenantContext)
- Si `mes` no es null: `WHERE cuotas.mes = :mes OR (EXTRACT(YEAR FROM cuotas.fecha_vencimiento) = year AND EXTRACT(MONTH FROM cuotas.fecha_vencimiento) = month)`
- Si `estado = CONFIRMADO`: `WHERE cuota_usuarios.estado = 'CONFIRMADO'`
- Si `estado = PENDIENTE`: `WHERE cuota_usuarios.estado IN ('PENDIENTE', 'RECHAZADO')`
- Ordenado por `cuota.mes DESC, usuario.unidad_habitacional ASC`

### Flutter

**Nueva pantalla `ReporteCuotasScreen`:**
- Acceso: botón `Icons.bar_chart` en AppBar de `CuotasAdminScreen`
- Ruta: `/home/cuotas/reporte`

**Filtros:**
- `TextFormField` para mes (formato YYYY-MM, ej. `2026-07`)
- `DropdownButtonFormField` de estado: Todos / Pagados / Pendientes
- Botón "Buscar" carga los datos

**Lista:**
- Cada ítem: unidad habitacional + nombre residente, concepto de cuota, monto, chip de estado (verde=CONFIRMADO, naranja=REPORTADO, gris=PENDIENTE, rojo=RECHAZADO), referencia de pago si aplica

**Exportar CSV:**
- Botón en AppBar: `Icons.download`
- Genera CSV en memoria con los datos actuales filtrados
- Columnas: `Unidad,Nombre,Concepto,Mes,Monto,Estado,Referencia,Fecha_Reporte`
- En web: descarga usando `dart:html` anchor con `href = 'data:text/csv,...'`
- En Android/iOS: compartir con `Share.shareXFiles` del paquete `share_plus`

**Nueva dependencia Flutter:** `share_plus: ^10.0.0`

---

## Feature 2 — Morosidad en Dashboard ADMIN

### Backend

**Nuevo endpoint:** `GET /api/cuotas/morosidad`

- **Roles:** ADMIN, SUPERADMIN
- **Response:**
```json
{
  "totalMonto": 15300.00,
  "totalMorosos": 8,
  "cuotasVencidas": 12
}
```

**Definición de moroso:** `cuota_usuario` con `estado IN ('PENDIENTE', 'RECHAZADO')` Y `cuota.fecha_vencimiento < CURRENT_DATE`.

**Nuevo DTO:** `MorosidadResponse.java` con `totalMonto (BigDecimal)`, `totalMorosos (int)`, `cuotasVencidas (int)`.

**Implementación en `CuotaService.obtenerMorosidad()`:**
- Toma `condominioId` del `TenantContext`
- Query: todas las `cuota_usuarios` del condominio con estado PENDIENTE o RECHAZADO y `cuota.fecha_vencimiento < LocalDate.now()`
- Agrega: suma de `cuota.monto`, count de usuarios distintos, count de registros

### Flutter

**`DashboardAdminScreen`:** agrega sección de morosidad cargada en `initState`.

**Nueva tarjeta en el dashboard** con 3 métricas:
```
[💰 Total vencido]  [👤 Morosos]  [📋 Cuotas vencidas]
  $15,300              8               12
```

**ApiConstants:** `static const String morosidad = '$apiPrefix/cuotas/morosidad';`

Los datos se cargan junto con las visitas al entrar al dashboard.

---

## Archivos modificados/creados

### Backend
```
com/condos/pago/dto/MorosidadResponse.java                 ← nuevo
com/condos/pago/service/CuotaService.java                  ← + listarReporte() + obtenerMorosidad()
com/condos/pago/controller/CuotaController.java             ← + GET /reporte + GET /morosidad
```

### Flutter
```
pubspec.yaml                                               ← + share_plus ^10.0.0
lib/core/constants/api_constants.dart                      ← + cuotaReporte, morosidad
lib/features/pagos/screens/reporte_cuotas_screen.dart      ← nuevo
lib/features/pagos/screens/cuotas_admin_screen.dart        ← + botón reporte en AppBar
lib/features/visitas/screens/dashboard_admin_screen.dart   ← + sección morosidad
lib/core/routes/app_router.dart                            ← + ruta /home/cuotas/reporte
```

---

## Out of Scope
- Reporte PDF
- Envío del CSV por email
- Histórico de morosidad en el tiempo (solo estado actual)
