# Mejoras Gestión de Usuarios — Design Spec

**Date:** 2026-06-16  
**Scope:** Tres mejoras al módulo de gestión de usuarios: username auto-fill desde email, unidad habitacional requerida para USUARIO, y carga masiva desde CSV.

---

## 1. Username = Email (auto-fill)

### Problema
El formulario de alta de usuario pide username y email por separado, lo que confunde y genera usernames inconsistentes.

### Solución
El campo `username` se elimina del formulario visible. El valor se auto-llena con el email ingresado (mismo valor). El backend continúa recibiendo `username` en el request, pero el frontend lo envía igual al email.

### Cambios
- **Flutter `CrearUsuarioScreen`:** Eliminar el `TextFormField` de username. Al cambiar el campo email, se asigna el mismo valor al username en el estado antes de enviar.
- **Backend:** Sin cambios — ya acepta email como username.

---

## 2. Unidad habitacional requerida para rol USUARIO

### Backend
En `UsuarioService.crearUsuario()` y `actualizarUsuario()`, antes de persistir:
```java
if (request.getRol() == Rol.USUARIO) {
    if (request.getUnidadHabitacional() == null || request.getUnidadHabitacional().isBlank()) {
        throw new IllegalArgumentException("La unidad habitacional es requerida para residentes");
    }
}
```

### Flutter `CrearUsuarioScreen`
El validator del campo "Unidad habitacional" activa el requerido solo cuando el rol seleccionado es USUARIO:
```dart
validator: (v) {
  if (_selectedRol == RolUsuario.usuario && (v == null || v.trim().isEmpty)) {
    return 'Requerido para residentes';
  }
  return null;
}
```

---

## 3. Carga masiva de usuarios desde CSV

### Formato del archivo CSV

```
nombre_completo,email,rol,unidad_habitacional
María González,maria@gmail.com,USUARIO,Torre A-101
Carlos Mendoza,carlos@gmail.com,GUARDIA,
Pedro López,pedro@gmail.com,USUARIO,Torre B-202
```

Reglas:
- Columna `unidad_habitacional` puede estar vacía para GUARDIA
- `username` = `email` (se genera automáticamente)
- Contraseña temporal fija: **`Condos2024!`** para todos
- Primera fila es el header (se ignora al procesar)
- Si una fila tiene error (email duplicado, campos vacíos) se omite esa fila y continúa con las demás

### Backend — nuevo endpoint

`POST /api/usuarios/bulk` — `multipart/form-data` con campo `file` (CSV)

**Roles permitidos:** ADMIN, SUPERADMIN

**Response:**
```json
{
  "creados": 2,
  "errores": [
    { "fila": 3, "email": "pedro@gmail.com", "motivo": "El email ya está en uso" }
  ]
}
```

**Nuevos archivos:**
```
com/condos/usuario/dto/BulkUsuarioResponse.java
com/condos/usuario/dto/BulkUsuarioError.java
```

**Método nuevo en `UsuarioService`:**
```java
public BulkUsuarioResponse crearUsuariosBulk(MultipartFile file, Long condominioId)
```

**Método nuevo en `UsuarioController`:**
```java
@PostMapping("/bulk")
@PreAuthorize("hasAnyRole('ADMIN', 'SUPERADMIN')")
public ResponseEntity<BulkUsuarioResponse> crearBulk(@RequestParam MultipartFile file)
```

### Flutter — cambios en GestionScreen

- Agregar botón `IconButton(Icons.upload_file)` en el AppBar de `GestionScreen`
- Al tocar: abre el file picker (paquete `file_picker`, solo `.csv`)
- Muestra un `AlertDialog` de "Procesando..." mientras sube
- Al terminar, muestra resumen: "✓ X usuarios creados. Y errores."
- Si hay errores, muestra la lista de filas fallidas con motivo

### Dependencia nueva

```yaml
file_picker: ^8.0.0
```

---

## Out of Scope
- Editar/eliminar usuarios desde CSV
- Envío de email con contraseña temporal (no hay SMTP configurado)
- Actualización masiva de usuarios existentes
