# Gestión de Usuarios — Design Spec

**Date:** 2026-06-09  
**Scope:** CRUD de usuarios para ADMIN/SUPERADMIN. Backend Spring Boot + Flutter.

---

## Context

El tab "Gestión" en el MainScaffold de ADMIN/SUPERADMIN existe como placeholder (`GestionScreen`). Este spec lo reemplaza con gestión real de usuarios del condominio.

**Restricciones de negocio:**
- ADMIN solo ve y gestiona usuarios de su propio condominio (extraído del JWT)
- ADMIN solo puede crear roles GUARDIA y USUARIO
- SUPERADMIN ve todos los usuarios y puede crear ADMIN también
- Desactivar usuario no lo elimina — solo cambia `activo = false`
- Password inicial la ingresa el ADMIN al crear el usuario (sin reset por email)

---

## Backend

### Nuevos archivos

```
com/condos/usuario/
  controller/UsuarioController.java
  service/UsuarioService.java
  dto/
    CreateUsuarioRequest.java
    UpdateUsuarioRequest.java
    UsuarioResponse.java
```

### Endpoints — `@RequestMapping("/api/usuarios")`

| Método | Path | Descripción | Roles |
|--------|------|-------------|-------|
| `GET` | `/` | Lista usuarios del condominio del ADMIN autenticado. SUPERADMIN ve todos. | ADMIN, SUPERADMIN |
| `POST` | `/` | Crea usuario. ADMIN: solo GUARDIA/USUARIO. SUPERADMIN: cualquier rol excepto SUPERADMIN. | ADMIN, SUPERADMIN |
| `GET` | `/{id}` | Detalle de usuario. ADMIN valida que pertenece a su condominio. | ADMIN, SUPERADMIN |
| `PUT` | `/{id}` | Actualiza nombre, teléfono, unidad habitacional, rol, esPropietario. No cambia password. | ADMIN, SUPERADMIN |
| `PUT` | `/{id}/estado` | Toggle activo/inactivo. | ADMIN, SUPERADMIN |

### DTOs

**CreateUsuarioRequest:**
```java
String username         // requerido, único
String email            // requerido, único
String password         // requerido, mínimo 6 chars
String nombreCompleto   // requerido
String telefono         // opcional
Rol rol                 // requerido: GUARDIA o USUARIO (ADMIN); GUARDIA, USUARIO o ADMIN (SUPERADMIN)
String unidadHabitacional // opcional
Boolean esPropietario   // default false
```

**UpdateUsuarioRequest:**
```java
String nombreCompleto   // requerido
String telefono         // opcional
Rol rol                 // requerido
String unidadHabitacional // opcional
Boolean esPropietario   // requerido
```

**UsuarioResponse:**
```java
Long id
String username
String email
String nombreCompleto
String telefono
Rol rol
Long condominioId
String condominioNombre
String unidadHabitacional
Boolean esPropietario
Boolean activo
LocalDateTime createdAt
```

### Lógica del servicio

- `listarUsuarios(Long adminId)`: ADMIN → `findByCondominioId(condominioId)`. SUPERADMIN → `findAll()`.
- `crearUsuario(request, adminId)`: valida unicidad de username/email, encripta password con BCrypt, asigna el condominio del ADMIN.
- `actualizarUsuario(id, request, adminId)`: valida que el usuario pertenece al condominio del ADMIN.
- `toggleEstado(id, adminId)`: invierte el campo `activo`.
- Validación de rol permitido: ADMIN no puede asignar rol ADMIN o SUPERADMIN.

### Migración DB

No requiere migración — la tabla `usuarios` ya tiene todos los campos necesarios.

---

## Flutter

### Nuevos archivos

```
lib/features/usuarios/
  models/
    usuario_admin.dart          # modelo + fromJson/toJson (diferente del shared/models/usuario.dart)
    usuario_admin.g.dart        # generado manualmente
    create_usuario_request.dart
    create_usuario_request.g.dart
    update_usuario_request.dart
    update_usuario_request.g.dart
  services/
    usuario_admin_service.dart  # llamadas HTTP
  providers/
    usuario_admin_provider.dart # StateNotifier + providers
  screens/
    gestion_screen.dart         # pantalla principal de gestión (lista de usuarios)
    crear_usuario_screen.dart
    detalle_usuario_screen.dart
```

**Archivo a eliminar:** `lib/features/perfil/screens/gestion_screen.dart` (placeholder).  
**Actualizar:** `lib/shared/widgets/main_scaffold.dart` — cambiar import de `gestion_screen.dart` de `perfil/screens/` a `usuarios/screens/`.

> **Nota:** `UsuarioAdmin` es el modelo de respuesta de la API de gestión. Es distinto de `Usuario` en `shared/models/` que se usa para el usuario autenticado.

### Estado Riverpod

```dart
class UsuarioAdminState {
  final List<UsuarioAdmin> usuarios;
  final bool isLoading;
  final String? error;
}

class UsuarioAdminNotifier extends StateNotifier<UsuarioAdminState> {
  Future<void> cargarUsuarios()
  Future<UsuarioAdmin?> crearUsuario(CreateUsuarioRequest)
  Future<void> actualizarUsuario(int id, UpdateUsuarioRequest)
  Future<void> toggleEstado(int id)
}
```

### Pantallas

**GestionScreen** (reemplaza el placeholder actual en `lib/features/perfil/screens/gestion_screen.dart`):
- Lista de usuarios con `ListTile`: nombre, username, chip de rol, badge verde/gris (activo/inactivo)
- FAB `+` → navega a `CrearUsuarioScreen`
- Tap en item → navega a `DetalleUsuarioScreen`
- Botón refresh en AppBar

**CrearUsuarioScreen** (ruta `/home/usuarios/nuevo`):
- Campos: nombre completo, username, email, password (con ojo), teléfono, unidad habitacional, rol (DropdownButton: GUARDIA / USUARIO), switch "Es propietario"
- Validación inline (requeridos, email format, password >= 6 chars)
- Al guardar: regresa a GestionScreen con snackbar "Usuario creado"

**DetalleUsuarioScreen** (ruta `/home/usuarios/:id`):
- Info del usuario (readonly)
- Botón "Editar" → formulario inline o modal con los campos editables (nombre, teléfono, unidad, rol, esPropietario)
- Botón "Activar" / "Desactivar" con diálogo de confirmación

### Rutas nuevas en GoRouter

```
/home/usuarios/nuevo    → CrearUsuarioScreen
/home/usuarios/:id      → DetalleUsuarioScreen
```

Agregadas como sub-rutas dentro de `/home`.

### ApiConstants nuevos

```dart
static const String usuarios = '$apiPrefix/usuarios';
static String usuarioById(int id) => '$apiPrefix/usuarios/$id';
static String usuarioEstado(int id) => '$apiPrefix/usuarios/$id/estado';
```

---

## Out of Scope

- Cambio de password por ADMIN
- Búsqueda/filtro de usuarios por nombre o rol
- Paginación
- Gestión de condominios (SUPERADMIN)
