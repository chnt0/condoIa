# Flutter Visitas Feature — Design Spec

**Date:** 2026-06-08  
**Scope:** Implementación completa de la feature de visitas en Flutter (USUARIO, GUARDIA, ADMIN, SUPERADMIN)

---

## Context

El backend Spring Boot ya tiene todos los endpoints de visitas implementados. Este spec cubre únicamente la implementación del lado Flutter.

**Backend endpoints disponibles:**
- `POST /api/visitas` — crear visita (USUARIO, ADMIN)
- `GET /api/visitas` — listar todas las visitas del condominio (GUARDIA, ADMIN)
- `GET /api/visitas/mis-visitas` — visitas del usuario autenticado (USUARIO)
- `GET /api/visitas/{id}` — detalle de visita
- `POST /api/visitas/validar-qr` — validar QR y registrar entrada (GUARDIA)
- `PUT /api/visitas/{id}/cancelar` — cancelar visita
- `GET /api/visitas/{id}/qr-image` — imagen QR en Base64

---

## Navigation Architecture

**Patrón:** `BottomNavigationBar` global con 4 tabs por rol, gestionado por `MainScaffold`.

### Tabs por rol

| Rol | Tab 1 | Tab 2 | Tab 3 | Tab 4 |
|-----|-------|-------|-------|-------|
| USUARIO | 🏠 Inicio | 📋 Mis Visitas | ➕ Nueva Visita | 👤 Perfil |
| GUARDIA | 📷 Escanear QR | 📋 Visitas Hoy | 📁 Historial | 👤 Perfil |
| ADMIN | 📊 Dashboard | 📋 Todas las Visitas | 🔧 Gestión | 👤 Perfil |
| SUPERADMIN | igual que ADMIN | | | |

### Rutas (GoRouter)

```
/splash      → SplashScreen
/login       → LoginScreen
/home        → MainScaffold (BottomNav, redirect según rol)
  /home/visitas/mis           → MisVisitasScreen
  /home/visitas/crear         → CrearVisitaScreen
  /home/visitas/:id           → DetalleVisitaScreen
  /home/escanear              → EscanearQrScreen
  /home/visitas/todas         → VisitasAdminScreen
  /home/dashboard             → DashboardAdminScreen
```

El `redirect` de GoRouter usa el rol del `AuthState` para determinar la ruta inicial dentro de `/home`.

---

## File Structure

```
lib/
├── features/
│   ├── auth/                          # existente
│   └── visitas/
│       ├── models/
│       │   ├── visita.dart
│       │   ├── visita.g.dart          # generado
│       │   ├── create_visita_request.dart
│       │   ├── create_visita_request.g.dart
│       │   ├── validar_qr_request.dart
│       │   ├── validar_qr_request.g.dart
│       │   ├── validar_qr_response.dart
│       │   └── validar_qr_response.g.dart
│       ├── services/
│       │   └── visita_service.dart
│       ├── providers/
│       │   └── visita_provider.dart
│       └── screens/
│           ├── mis_visitas_screen.dart
│           ├── crear_visita_screen.dart
│           ├── detalle_visita_screen.dart
│           ├── visitas_admin_screen.dart
│           ├── escanear_qr_screen.dart
│           └── dashboard_admin_screen.dart
└── shared/
    └── widgets/
        └── main_scaffold.dart         # nuevo — BottomNav por rol
```

---

## Data Model

### `Visita` (espejo de `VisitaResponse` del backend)

```dart
@JsonSerializable()
class Visita {
  final int id;
  final String nombreVisitante;
  final String? telefonoVisitante;
  @JsonKey(name: 'fechaHoraProgramada')
  final DateTime fechaHoraProgramada;
  final String codigoQrHash;
  final String? motivo;
  final String? vehiculoPlacas;
  final String estado; // 'PROGRAMADA' | 'COMPLETADA' | 'CANCELADA'
  final DateTime? fechaHoraEntrada;
  final String? notas;
  final DateTime createdAt;
  final int usuarioId;
  final String usuarioNombre;
  final String? unidadHabitacional;
  final int? guardiaEntradaId;
  final String? guardiaEntradaNombre;
}
```

### `CreateVisitaRequest`

```dart
@JsonSerializable()
class CreateVisitaRequest {
  final String nombreVisitante;
  final String? telefonoVisitante;
  final DateTime fechaHoraProgramada;
  final String? motivo;
  final String? vehiculoPlacas;
}
```

### `ValidarQrRequest` / `ValidarQrResponse`

```dart
@JsonSerializable()
class ValidarQrRequest {
  final String codigoQr;
  final String? notas;
}

@JsonSerializable()
class ValidarQrResponse {
  final bool valido;
  final String mensaje;
  final Visita? visita;
}
```

---

## State Management

Sigue el patrón existente `StateNotifier` + Riverpod.

### `VisitaState`

```dart
class VisitaState {
  final List<Visita> visitas;
  final bool isLoading;
  final String? error;
}
```

### `VisitaNotifier` — operaciones

| Método | Endpoint | Roles |
|--------|----------|-------|
| `cargarMisVisitas()` | `GET /mis-visitas` | USUARIO |
| `cargarTodasVisitas()` | `GET /api/visitas` | GUARDIA, ADMIN |
| `crearVisita(request)` | `POST /api/visitas` | USUARIO, ADMIN |
| `cancelarVisita(id)` | `PUT /{id}/cancelar` | USUARIO, ADMIN |
| `validarQr(codigo, notas)` | `POST /validar-qr` | GUARDIA |
| `obtenerImagenQr(id)` | `GET /{id}/qr-image` | USUARIO |

---

## Screens

### USUARIO

**MisVisitasScreen** — lista de visitas del usuario con estado (badge color por estado: azul=PROGRAMADA, verde=COMPLETADA, rojo=CANCELADA). Tap abre `DetalleVisitaScreen`.

**CrearVisitaScreen** — formulario con campos:
- Nombre del visitante (requerido)
- Teléfono (opcional)
- Fecha y hora programada — `DateTimePicker` (requerido)
- Motivo (opcional)
- Placas del vehículo (opcional)

Al guardar: `POST /api/visitas` → navega a `DetalleVisitaScreen` con la visita creada.

**DetalleVisitaScreen** — muestra datos de la visita + imagen QR (cargada via `GET /{id}/qr-image`, decodificada de Base64 con `Image.memory()`). Botón "Cancelar visita" visible solo si estado = PROGRAMADA.

### GUARDIA

**EscanearQrScreen** — dos modos:
1. **Cámara** (por defecto): vista de cámara con `mobile_scanner`. Al detectar QR llama `POST /validar-qr` automáticamente.
2. **Código manual**: botón alterna a campo de texto para pegar/escribir el hash. Botón "Validar".

Tras validación muestra dialog de resultado (éxito/error) con datos del visitante.

**VisitasAdminScreen** (usada también por GUARDIA como "Visitas Hoy" e "Historial") — misma pantalla con parámetro `filterToday: bool`. Para GUARDIA, tab "Visitas Hoy" pasa `filterToday: true` (filtra por fecha actual); tab "Historial" pasa `filterToday: false` (muestra todo).

### ADMIN / SUPERADMIN

**DashboardAdminScreen** — cards de resumen: visitas hoy, programadas, completadas, canceladas. Datos calculados del lado cliente a partir de `GET /api/visitas`.

**VisitasAdminScreen** — lista completa sin filtro de fecha. Tap → detalle. Puede cancelar visitas en estado PROGRAMADA.

---

## New Dependencies

Agregar a `pubspec.yaml`:

```yaml
mobile_scanner: ^6.0.0   # cámara QR para GUARDIA
```

Permisos requeridos:
- Android: `CAMERA` en `AndroidManifest.xml`
- iOS: `NSCameraUsageDescription` en `Info.plist`

---

## ApiClient — Cambios requeridos

El `ApiClient` existente solo tiene `get()` (retorna `Map`) y `post()`. Para esta feature se necesitan:

- **`getList(endpoint)`** → `List<dynamic>`: para endpoints que retornan array (`/mis-visitas`, `/api/visitas`)
- **`put(endpoint, body)`** → `Map<String, dynamic>`: para `PUT /{id}/cancelar`

Estos métodos se agregan a `lib/shared/services/api_client.dart` siguiendo el mismo patrón de manejo de errores/timeout existente.

---

## Error Handling

- Errores de red: `ApiException` ya manejada por `ApiClient`. El `VisitaNotifier` captura y setea `state.error`.
- Cada pantalla observa `state.error` y muestra `SnackBar` rojo (mismo patrón que `LoginScreen`).
- QR inválido: el backend devuelve `{ valido: false, mensaje: "..." }` — mostrar en dialog, no como error de red.

---

## Out of Scope

- Gestión de usuarios (ADMIN) — scope futuro
- Notificaciones push para visitas programadas — scope futuro
- Modo offline / cache local
- Paginación de listas (asumimos volumen manejable por condominio)
