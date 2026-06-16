# Mejoras Gestión de Usuarios — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Tres mejoras al alta de usuarios: username auto-fill desde email, unidad habitacional requerida para USUARIO, y carga masiva desde CSV con contraseña temporal `Condos2024!`.

**Architecture:** Backend: validación condicional en `UsuarioService` + nuevo endpoint `POST /api/usuarios/bulk` que parsea CSV con `BufferedReader` (sin dependencias extra). Flutter: eliminar campo username de `CrearUsuarioScreen`, validator condicional para unidad, nuevo botón CSV en `GestionScreen` usando `file_picker` + método `postFile` en `ApiClient`.

**Tech Stack:** Spring Boot 3 + Multipart | Flutter + file_picker ^8.0.0 + http.MultipartRequest

---

## File Map

### Backend — modificados

```
com/condos/usuario/service/UsuarioService.java        ← validación unidad + método crearBulk
com/condos/usuario/controller/UsuarioController.java  ← endpoint POST /bulk
```

### Backend — nuevos

```
com/condos/usuario/dto/BulkUsuarioResponse.java
com/condos/usuario/dto/BulkUsuarioError.java
```

### Flutter — modificados

```
pubspec.yaml                                              ← + file_picker ^8.0.0
lib/shared/services/api_client.dart                      ← + método postFile()
lib/features/usuarios/screens/crear_usuario_screen.dart  ← remove username, autofill, unidad required
lib/features/usuarios/services/usuario_admin_service.dart ← + crearUsuariosBulk()
lib/features/usuarios/providers/usuario_admin_provider.dart ← + uploadCsv()
lib/features/usuarios/screens/gestion_screen.dart         ← + botón CSV upload
```

---

## Task 1: Backend — validación unidad + DTOs bulk

**Files:**
- Modify: `backend/src/main/java/com/condos/usuario/service/UsuarioService.java`
- Create: `backend/src/main/java/com/condos/usuario/dto/BulkUsuarioResponse.java`
- Create: `backend/src/main/java/com/condos/usuario/dto/BulkUsuarioError.java`

- [ ] **Step 1: BulkUsuarioError.java**

```java
package com.condos.usuario.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class BulkUsuarioError {
    private int fila;
    private String email;
    private String motivo;
}
```

- [ ] **Step 2: BulkUsuarioResponse.java**

```java
package com.condos.usuario.dto;

import lombok.Builder;
import lombok.Data;

import java.util.List;

@Data
@Builder
public class BulkUsuarioResponse {
    private int creados;
    private List<BulkUsuarioError> errores;
}
```

- [ ] **Step 3: Agregar validación de unidad en UsuarioService**

En el método `crearUsuario()`, antes de construir el objeto `Usuario`, agregar:

```java
if (request.getRol() == Rol.USUARIO) {
    if (request.getUnidadHabitacional() == null || request.getUnidadHabitacional().isBlank()) {
        throw new IllegalArgumentException("La unidad habitacional es requerida para residentes");
    }
}
```

La misma validación en `actualizarUsuario()`, antes de `usuario.setRol(request.getRol())`:

```java
if (request.getRol() == Rol.USUARIO) {
    if (request.getUnidadHabitacional() == null || request.getUnidadHabitacional().isBlank()) {
        throw new IllegalArgumentException("La unidad habitacional es requerida para residentes");
    }
}
```

- [ ] **Step 4: Agregar método crearUsuariosBulk a UsuarioService**

Agregar imports:
```java
import com.condos.usuario.dto.BulkUsuarioError;
import com.condos.usuario.dto.BulkUsuarioResponse;
import org.springframework.web.multipart.MultipartFile;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
```

Agregar método al final de la clase:

```java
@Transactional
public BulkUsuarioResponse crearUsuariosBulk(MultipartFile file) {
    Long condominioId = TenantContext.getCondominioId();
    Condominio condominio = condominioRepository.findById(condominioId)
            .orElseThrow(() -> new ResourceNotFoundException("Condominio no encontrado"));

    int creados = 0;
    List<BulkUsuarioError> errores = new ArrayList<>();
    int fila = 1;

    try (BufferedReader reader = new BufferedReader(
            new InputStreamReader(file.getInputStream(), StandardCharsets.UTF_8))) {

        String linea;
        boolean primeraLinea = true;

        while ((linea = reader.readLine()) != null) {
            if (primeraLinea) {
                primeraLinea = false;
                continue;
            }
            fila++;
            String[] columnas = linea.split(",", -1);
            if (columnas.length < 3) {
                errores.add(new BulkUsuarioError(fila, "", "Formato inválido: faltan columnas"));
                continue;
            }

            String nombreCompleto = columnas[0].trim();
            String email = columnas[1].trim();
            String rol = columnas[2].trim().toUpperCase();
            String unidad = columnas.length > 3 ? columnas[3].trim() : "";

            if (nombreCompleto.isEmpty() || email.isEmpty() || rol.isEmpty()) {
                errores.add(new BulkUsuarioError(fila, email, "Campos obligatorios vacíos"));
                continue;
            }

            if (!rol.equals("USUARIO") && !rol.equals("GUARDIA")) {
                errores.add(new BulkUsuarioError(fila, email, "Rol inválido: " + rol));
                continue;
            }

            if (rol.equals("USUARIO") && unidad.isEmpty()) {
                errores.add(new BulkUsuarioError(fila, email, "Unidad habitacional requerida para USUARIO"));
                continue;
            }

            if (usuarioRepository.existsByEmail(email)) {
                errores.add(new BulkUsuarioError(fila, email, "El email ya está en uso"));
                continue;
            }

            if (usuarioRepository.existsByUsername(email)) {
                errores.add(new BulkUsuarioError(fila, email, "El username ya está en uso"));
                continue;
            }

            try {
                Rol rolEnum = Rol.valueOf(rol);
                Usuario usuario = Usuario.builder()
                        .username(email)
                        .email(email)
                        .passwordHash(passwordEncoder.encode("Condos2024!"))
                        .nombreCompleto(nombreCompleto)
                        .rol(rolEnum)
                        .condominio(condominio)
                        .unidadHabitacional(unidad.isEmpty() ? null : unidad)
                        .esPropietario(false)
                        .activo(true)
                        .build();
                usuarioRepository.save(usuario);
                creados++;
            } catch (Exception e) {
                errores.add(new BulkUsuarioError(fila, email, "Error al crear: " + e.getMessage()));
            }
        }
    } catch (Exception e) {
        throw new IllegalArgumentException("Error al leer el archivo: " + e.getMessage());
    }

    log.info("Bulk usuarios: creados={}, errores={}", creados, errores.size());
    return BulkUsuarioResponse.builder().creados(creados).errores(errores).build();
}
```

- [ ] **Step 5: Commit**

```bash
git add backend/src/main/java/com/condos/usuario/dto/BulkUsuarioError.java \
        backend/src/main/java/com/condos/usuario/dto/BulkUsuarioResponse.java \
        backend/src/main/java/com/condos/usuario/service/UsuarioService.java
git commit -m "feat(usuarios): add unidad validation for USUARIO rol + bulk CSV creation method"
```

---

## Task 2: Backend — UsuarioController endpoint /bulk + compilación

**Files:**
- Modify: `backend/src/main/java/com/condos/usuario/controller/UsuarioController.java`

- [ ] **Step 1: Agregar imports a UsuarioController**

```java
import com.condos.usuario.dto.BulkUsuarioResponse;
import org.springframework.web.multipart.MultipartFile;
```

- [ ] **Step 2: Agregar endpoint /bulk**

```java
@PostMapping("/bulk")
@PreAuthorize("hasAnyRole('ADMIN', 'SUPERADMIN')")
public ResponseEntity<BulkUsuarioResponse> crearBulk(
        @RequestParam("file") MultipartFile file) {
    if (file.isEmpty()) {
        throw new IllegalArgumentException("El archivo está vacío");
    }
    return ResponseEntity.ok(usuarioService.crearUsuariosBulk(file));
}
```

- [ ] **Step 3: Verificar compilación**

```bash
cd backend && ./mvnw compile -q
```

Expected: sin output.

- [ ] **Step 4: Commit**

```bash
git add backend/src/main/java/com/condos/usuario/controller/UsuarioController.java
git commit -m "feat(usuarios): add POST /api/usuarios/bulk endpoint for CSV mass creation"
```

---

## Task 3: Flutter — pubspec + ApiClient.postFile()

**Files:**
- Modify: `pubspec.yaml`
- Modify: `lib/shared/services/api_client.dart`

- [ ] **Step 1: Agregar file_picker a pubspec.yaml**

En la sección `dependencies`, agregar después de `equatable`:

```yaml
  # File picker para carga masiva de usuarios
  file_picker: ^8.0.0
```

- [ ] **Step 2: Correr pub get**

```bash
cd ~/flutter/condos
~/flutter/condos/flutter/bin/flutter pub get
```

- [ ] **Step 3: Agregar método postFile() a ApiClient**

En `lib/shared/services/api_client.dart`, agregar import:

```dart
import 'dart:io';
```

Agregar el método antes de `_handleResponse`:

```dart
Future<Map<String, dynamic>> postFile(
  String endpoint,
  String fieldName,
  String filePath,
  String fileName, {
  Map<String, String>? headers,
}) async {
  try {
    final url = Uri.parse('$baseUrl$endpoint');
    final request = http.MultipartRequest('POST', url);

    final headerMap = _getHeaders(additionalHeaders: headers);
    headerMap.remove('Content-Type');
    request.headers.addAll(headerMap);

    request.files.add(await http.MultipartFile.fromPath(
      fieldName,
      filePath,
      filename: fileName,
    ));

    final streamedResponse = await request.send().timeout(timeout);
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  } on TimeoutException {
    throw ApiException(
      'La solicitud tardó demasiado tiempo. Por favor, intente nuevamente.',
      statusCode: 408,
    );
  } catch (e) {
    if (e is ApiException) rethrow;
    throw ApiException('Error de conexión. Verifique su internet e intente nuevamente.');
  }
}
```

- [ ] **Step 4: Agregar constante a ApiConstants**

En `lib/core/constants/api_constants.dart`, dentro de la sección `// Usuarios (gestión por ADMIN)`:

```dart
static const String usuariosBulk = '$apiPrefix/usuarios/bulk';
```

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml lib/shared/services/api_client.dart lib/core/constants/api_constants.dart
git commit -m "feat(usuarios): add file_picker dep, ApiClient.postFile(), ApiConstants.usuariosBulk"
```

---

## Task 4: Flutter — CrearUsuarioScreen (username autofill + unidad required)

**Files:**
- Modify: `lib/features/usuarios/screens/crear_usuario_screen.dart`

- [ ] **Step 1: Eliminar _usernameController, agregar listener en email**

Cambiar la declaración de controllers — eliminar `_usernameController`:

```dart
final _formKey = GlobalKey<FormState>();
final _nombreController = TextEditingController();
final _emailController = TextEditingController();
final _passwordController = TextEditingController();
final _telefonoController = TextEditingController();
final _unidadController = TextEditingController();
bool _obscurePassword = true;
String _selectedRol = 'USUARIO';
bool _esPropietario = false;
```

Actualizar `dispose()`:

```dart
@override
void dispose() {
  _nombreController.dispose();
  _emailController.dispose();
  _passwordController.dispose();
  _telefonoController.dispose();
  _unidadController.dispose();
  super.dispose();
}
```

Actualizar `_submit()` — el username es el email:

```dart
final request = CreateUsuarioRequest(
  username: _emailController.text.trim(),
  email: _emailController.text.trim(),
  password: _passwordController.text,
  nombreCompleto: _nombreController.text.trim(),
  telefono: _telefonoController.text.trim().isEmpty
      ? null
      : _telefonoController.text.trim(),
  rol: _selectedRol,
  unidadHabitacional: _unidadController.text.trim().isEmpty
      ? null
      : _unidadController.text.trim(),
  esPropietario: _esPropietario,
);
```

- [ ] **Step 2: Eliminar el TextFormField de username del build()**

En el método `build()`, dentro del `Column` del formulario, **eliminar completamente** el bloque:

```dart
// ELIMINAR este bloque:
const SizedBox(height: 16),
TextFormField(
  controller: _usernameController,
  decoration: const InputDecoration(
    labelText: 'Username *',
    prefixIcon: Icon(Icons.alternate_email),
  ),
  validator: (v) {
    if (v == null || v.trim().isEmpty) return 'Requerido';
    if (v.trim().length < 3) return 'Mínimo 3 caracteres';
    return null;
  },
  textInputAction: TextInputAction.next,
  enabled: !isLoading,
),
```

- [ ] **Step 3: Hacer unidad habitacional requerida para USUARIO**

Actualizar el `TextFormField` de unidad habitacional — agregar `*` al label y validator condicional:

```dart
TextFormField(
  controller: _unidadController,
  decoration: InputDecoration(
    labelText: _selectedRol == 'USUARIO'
        ? 'Unidad habitacional *'
        : 'Unidad habitacional',
    prefixIcon: const Icon(Icons.home),
    hintText: 'Ej: Torre A-101',
  ),
  validator: (v) {
    if (_selectedRol == 'USUARIO' && (v == null || v.trim().isEmpty)) {
      return 'Requerida para residentes';
    }
    return null;
  },
  textInputAction: TextInputAction.done,
  enabled: !isLoading,
),
```

Asegurarse de que el `onChanged` del DropdownButtonFormField llama a `setState`:

```dart
onChanged: isLoading
    ? null
    : (v) => setState(() => _selectedRol = v!),
```

- [ ] **Step 4: Commit**

```bash
git add lib/features/usuarios/screens/crear_usuario_screen.dart
git commit -m "feat(usuarios): remove username field (autofill from email), unidad required for USUARIO"
```

---

## Task 5: Flutter — UsuarioAdminService + Provider + GestionScreen CSV upload

**Files:**
- Modify: `lib/features/usuarios/services/usuario_admin_service.dart`
- Modify: `lib/features/usuarios/providers/usuario_admin_provider.dart`
- Modify: `lib/features/usuarios/screens/gestion_screen.dart`

- [ ] **Step 1: Agregar crearUsuariosBulk a UsuarioAdminService**

En `lib/features/usuarios/services/usuario_admin_service.dart`, agregar import:

```dart
import '../../../core/constants/api_constants.dart';
```

Agregar método:

```dart
Future<Map<String, dynamic>> crearUsuariosBulk(String filePath, String fileName) async {
  final response = await apiClient.postFile(
    ApiConstants.usuariosBulk,
    'file',
    filePath,
    fileName,
  );
  return response;
}
```

- [ ] **Step 2: Agregar uploadCsv a UsuarioAdminNotifier**

En `lib/features/usuarios/providers/usuario_admin_provider.dart`, agregar al notifier:

```dart
Future<Map<String, dynamic>?> uploadCsv(String filePath, String fileName) async {
  state = state.copyWith(isLoading: true, error: null);
  try {
    final result = await _service.crearUsuariosBulk(filePath, fileName);
    await cargarUsuarios();
    return result;
  } catch (e) {
    state = state.copyWith(isLoading: false, error: e.toString());
    return null;
  }
}
```

- [ ] **Step 3: Agregar botón CSV en GestionScreen**

En `lib/features/usuarios/screens/gestion_screen.dart`, agregar imports:

```dart
import 'package:file_picker/file_picker.dart';
```

Agregar método `_subirCsv` a `_GestionScreenState`:

```dart
Future<void> _subirCsv(BuildContext context) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['csv'],
  );

  if (result == null || result.files.single.path == null) return;

  final file = result.files.single;

  if (!context.mounted) return;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const AlertDialog(
      content: Row(
        children: [
          CircularProgressIndicator(),
          SizedBox(width: 16),
          Text('Procesando archivo...'),
        ],
      ),
    ),
  );

  final response = await ref
      .read(usuarioAdminProvider.notifier)
      .uploadCsv(file.path!, file.name);

  if (!context.mounted) return;
  Navigator.pop(context); // cerrar dialog de carga

  if (response != null) {
    final creados = response['creados'] as int? ?? 0;
    final errores = response['errores'] as List? ?? [];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resultado de carga'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('✓ $creados usuarios creados',
                style: const TextStyle(
                    color: Colors.green, fontWeight: FontWeight.bold)),
            if (errores.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('✗ ${errores.length} errores:',
                  style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 4),
              ...errores.take(5).map((e) => Text(
                    '• Fila ${e['fila']}: ${e['motivo']}',
                    style: const TextStyle(fontSize: 12),
                  )),
              if (errores.length > 5)
                Text('  ... y ${errores.length - 5} más',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cerrar')),
        ],
      ),
    );
  } else {
    final error = ref.read(usuarioAdminProvider).error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(error ?? 'Error al procesar el archivo'),
          backgroundColor: Colors.red),
    );
  }
}
```

Agregar el botón en el `AppBar` de `GestionScreen`, junto al botón de refresh:

```dart
AppBar(
  title: const Text('Gestión de Usuarios'),
  actions: [
    IconButton(
      icon: const Icon(Icons.upload_file),
      tooltip: 'Subir CSV',
      onPressed: () => _subirCsv(context),
    ),
    IconButton(
      icon: const Icon(Icons.refresh),
      onPressed: () => ref.read(usuarioAdminProvider.notifier).cargarUsuarios(),
    ),
  ],
),
```

- [ ] **Step 4: Commit y push**

```bash
git add lib/features/usuarios/services/usuario_admin_service.dart \
        lib/features/usuarios/providers/usuario_admin_provider.dart \
        lib/features/usuarios/screens/gestion_screen.dart \
        pubspec.lock
git commit -m "feat(usuarios): add CSV bulk upload — UsuarioAdminService, provider, GestionScreen button"
git push
```

---

## Self-Review

### Spec Coverage

| Requisito | Task |
|---|---|
| `unidad habitacional` requerida para USUARIO en backend | Task 1 |
| `unidad habitacional` requerida para USUARIO en `actualizarUsuario` | Task 1 |
| DTOs `BulkUsuarioResponse` y `BulkUsuarioError` | Task 1 |
| Método `crearUsuariosBulk` en `UsuarioService` (parsea CSV, password `Condos2024!`, username=email) | Task 1 |
| Filas con error no detienen el proceso | Task 1 |
| Endpoint `POST /api/usuarios/bulk` — multipart, ADMIN/SUPERADMIN | Task 2 |
| Backend compila | Task 2 |
| `file_picker ^8.0.0` en pubspec | Task 3 |
| `ApiClient.postFile()` con MultipartRequest | Task 3 |
| `ApiConstants.usuariosBulk` | Task 3 |
| Eliminar campo username de `CrearUsuarioScreen` | Task 4 |
| Username = email en `_submit()` | Task 4 |
| Validator condicional para unidad (requerida solo si rol=USUARIO) | Task 4 |
| `UsuarioAdminService.crearUsuariosBulk()` | Task 5 |
| `UsuarioAdminNotifier.uploadCsv()` | Task 5 |
| Botón upload en AppBar de `GestionScreen` | Task 5 |
| Dialog de procesando + dialog de resultado con errores | Task 5 |
