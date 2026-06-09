# Gestión de Usuarios — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implementar CRUD de usuarios (GUARDIA, USUARIO) para ADMIN en backend Spring Boot y en Flutter, reemplazando el placeholder GestionScreen.

**Architecture:** Backend: Controller → Service → Repository (patrón idéntico al de Visitas). TenantContext determina si el usuario es ADMIN (condominioId != null) o SUPERADMIN (condominioId == null). Flutter: feature-first en `lib/features/usuarios/`, Riverpod StateNotifier, GoRouter sub-rutas bajo `/home`.

**Tech Stack:** Spring Boot 3, Spring Security `@PreAuthorize`, Lombok, Flutter, Riverpod 2.x, GoRouter 13.x, json_annotation (`.g.dart` escritos manualmente).

---

## File Map

**Backend — Crear:**
- `backend/src/main/java/com/condos/usuario/dto/CreateUsuarioRequest.java`
- `backend/src/main/java/com/condos/usuario/dto/UpdateUsuarioRequest.java`
- `backend/src/main/java/com/condos/usuario/dto/UsuarioResponse.java`
- `backend/src/main/java/com/condos/usuario/service/UsuarioService.java`
- `backend/src/main/java/com/condos/usuario/controller/UsuarioController.java`

**Flutter — Crear:**
- `lib/features/usuarios/models/usuario_admin.dart`
- `lib/features/usuarios/models/usuario_admin.g.dart`
- `lib/features/usuarios/models/create_usuario_request.dart`
- `lib/features/usuarios/models/create_usuario_request.g.dart`
- `lib/features/usuarios/models/update_usuario_request.dart`
- `lib/features/usuarios/models/update_usuario_request.g.dart`
- `lib/features/usuarios/services/usuario_admin_service.dart`
- `lib/features/usuarios/providers/usuario_admin_provider.dart`
- `lib/features/usuarios/screens/gestion_screen.dart`
- `lib/features/usuarios/screens/crear_usuario_screen.dart`
- `lib/features/usuarios/screens/detalle_usuario_screen.dart`

**Flutter — Modificar:**
- `lib/core/constants/api_constants.dart` — agregar endpoints usuarios
- `lib/core/routes/app_router.dart` — agregar sub-rutas `/home/usuarios/nuevo` y `/home/usuarios/:id`
- `lib/shared/widgets/main_scaffold.dart` — actualizar import de GestionScreen

**Flutter — Eliminar:**
- `lib/features/perfil/screens/gestion_screen.dart` (placeholder)

---

### Task 1: Backend — DTOs

**Files:**
- Create: `backend/src/main/java/com/condos/usuario/dto/CreateUsuarioRequest.java`
- Create: `backend/src/main/java/com/condos/usuario/dto/UpdateUsuarioRequest.java`
- Create: `backend/src/main/java/com/condos/usuario/dto/UsuarioResponse.java`

- [ ] **Step 1: Create CreateUsuarioRequest.java**

```java
package com.condos.usuario.dto;

import com.condos.usuario.model.Rol;
import jakarta.validation.constraints.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class CreateUsuarioRequest {

    @NotBlank(message = "El username es requerido")
    @Size(min = 3, max = 50, message = "El username debe tener entre 3 y 50 caracteres")
    private String username;

    @NotBlank(message = "El email es requerido")
    @Email(message = "El email no es válido")
    private String email;

    @NotBlank(message = "La contraseña es requerida")
    @Size(min = 6, message = "La contraseña debe tener al menos 6 caracteres")
    private String password;

    @NotBlank(message = "El nombre completo es requerido")
    private String nombreCompleto;

    private String telefono;

    @NotNull(message = "El rol es requerido")
    private Rol rol;

    private String unidadHabitacional;

    private Boolean esPropietario = false;

    private Long condominioId; // Requerido solo cuando SUPERADMIN crea usuarios
}
```

- [ ] **Step 2: Create UpdateUsuarioRequest.java**

```java
package com.condos.usuario.dto;

import com.condos.usuario.model.Rol;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class UpdateUsuarioRequest {

    @NotBlank(message = "El nombre completo es requerido")
    private String nombreCompleto;

    private String telefono;

    @NotNull(message = "El rol es requerido")
    private Rol rol;

    private String unidadHabitacional;

    @NotNull(message = "esPropietario es requerido")
    private Boolean esPropietario;
}
```

- [ ] **Step 3: Create UsuarioResponse.java**

```java
package com.condos.usuario.dto;

import com.condos.usuario.model.Rol;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UsuarioResponse {

    private Long id;
    private String username;
    private String email;
    private String nombreCompleto;
    private String telefono;
    private Rol rol;
    private Long condominioId;
    private String condominioNombre;
    private String unidadHabitacional;
    private Boolean esPropietario;
    private Boolean activo;
    private LocalDateTime createdAt;
}
```

- [ ] **Step 4: Verify compilation**

```bash
cd /Users/jandrade2/flutter/condos/backend && ./mvnw compile -q 2>&1 | tail -5
```

Expected: No errors.

- [ ] **Step 5: Commit**

```bash
git add backend/src/main/java/com/condos/usuario/dto/
git commit -m "feat(usuarios): add CreateUsuarioRequest, UpdateUsuarioRequest, UsuarioResponse DTOs"
```

---

### Task 2: Backend — UsuarioService

**Files:**
- Create: `backend/src/main/java/com/condos/usuario/service/UsuarioService.java`

- [ ] **Step 1: Create UsuarioService.java**

```java
package com.condos.usuario.service;

import com.condos.common.exceptions.ResourceNotFoundException;
import com.condos.common.exceptions.TenantMismatchException;
import com.condos.common.exceptions.UnauthorizedException;
import com.condos.common.utils.TenantContext;
import com.condos.condominio.model.Condominio;
import com.condos.condominio.repository.CondominioRepository;
import com.condos.usuario.dto.CreateUsuarioRequest;
import com.condos.usuario.dto.UpdateUsuarioRequest;
import com.condos.usuario.dto.UsuarioResponse;
import com.condos.usuario.model.Rol;
import com.condos.usuario.model.Usuario;
import com.condos.usuario.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class UsuarioService {

    private final UsuarioRepository usuarioRepository;
    private final CondominioRepository condominioRepository;
    private final PasswordEncoder passwordEncoder;

    @Transactional(readOnly = true)
    public List<UsuarioResponse> listarUsuarios() {
        Long condominioId = TenantContext.getCondominioId();
        List<Usuario> usuarios;
        if (condominioId == null) {
            usuarios = usuarioRepository.findAll();
        } else {
            usuarios = usuarioRepository.findByCondominioId(condominioId);
        }
        return usuarios.stream()
                .filter(u -> u.getRol() != Rol.SUPERADMIN)
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public UsuarioResponse obtenerUsuario(Long id) {
        return toResponse(findAndValidate(id));
    }

    @Transactional
    public UsuarioResponse crearUsuario(CreateUsuarioRequest request) {
        if (usuarioRepository.existsByUsername(request.getUsername())) {
            throw new IllegalArgumentException("El username '" + request.getUsername() + "' ya está en uso");
        }
        if (usuarioRepository.existsByEmail(request.getEmail())) {
            throw new IllegalArgumentException("El email '" + request.getEmail() + "' ya está en uso");
        }

        Long condominioId = TenantContext.getCondominioId();
        if (condominioId == null) {
            // SUPERADMIN: condominioId must come from request
            condominioId = request.getCondominioId();
            if (condominioId == null) {
                throw new IllegalArgumentException("condominioId es requerido");
            }
            if (request.getRol() == Rol.SUPERADMIN) {
                throw new UnauthorizedException("No se puede crear un usuario SUPERADMIN");
            }
        } else {
            // ADMIN: can only create GUARDIA or USUARIO
            if (request.getRol() == Rol.ADMIN || request.getRol() == Rol.SUPERADMIN) {
                throw new UnauthorizedException("ADMIN solo puede crear usuarios con rol GUARDIA o USUARIO");
            }
        }

        Condominio condominio = condominioRepository.findById(condominioId)
                .orElseThrow(() -> new ResourceNotFoundException("Condominio no encontrado"));

        Usuario usuario = Usuario.builder()
                .username(request.getUsername())
                .email(request.getEmail())
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .nombreCompleto(request.getNombreCompleto())
                .telefono(request.getTelefono())
                .rol(request.getRol())
                .condominio(condominio)
                .unidadHabitacional(request.getUnidadHabitacional())
                .esPropietario(request.getEsPropietario() != null ? request.getEsPropietario() : false)
                .activo(true)
                .build();

        usuario = usuarioRepository.save(usuario);
        log.info("Usuario creado: username={}, rol={}, condominioId={}",
                usuario.getUsername(), usuario.getRol(), condominioId);
        return toResponse(usuario);
    }

    @Transactional
    public UsuarioResponse actualizarUsuario(Long id, UpdateUsuarioRequest request) {
        Usuario usuario = findAndValidate(id);

        Long condominioId = TenantContext.getCondominioId();
        if (condominioId != null) {
            if (request.getRol() == Rol.ADMIN || request.getRol() == Rol.SUPERADMIN) {
                throw new UnauthorizedException("ADMIN solo puede asignar roles GUARDIA o USUARIO");
            }
        } else {
            if (request.getRol() == Rol.SUPERADMIN) {
                throw new UnauthorizedException("No se puede asignar rol SUPERADMIN");
            }
        }

        usuario.setNombreCompleto(request.getNombreCompleto());
        usuario.setTelefono(request.getTelefono());
        usuario.setRol(request.getRol());
        usuario.setUnidadHabitacional(request.getUnidadHabitacional());
        usuario.setEsPropietario(request.getEsPropietario());

        usuario = usuarioRepository.save(usuario);
        log.info("Usuario actualizado: id={}", id);
        return toResponse(usuario);
    }

    @Transactional
    public UsuarioResponse toggleEstado(Long id) {
        Usuario usuario = findAndValidate(id);
        usuario.setActivo(!usuario.getActivo());
        usuario = usuarioRepository.save(usuario);
        log.info("Estado de usuario cambiado: id={}, activo={}", id, usuario.getActivo());
        return toResponse(usuario);
    }

    private Usuario findAndValidate(Long id) {
        Usuario usuario = usuarioRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Usuario no encontrado"));

        Long condominioId = TenantContext.getCondominioId();
        if (condominioId != null) {
            if (usuario.getCondominio() == null ||
                    !usuario.getCondominio().getId().equals(condominioId)) {
                throw new TenantMismatchException("No tienes permiso para gestionar este usuario");
            }
        }
        return usuario;
    }

    private UsuarioResponse toResponse(Usuario usuario) {
        return UsuarioResponse.builder()
                .id(usuario.getId())
                .username(usuario.getUsername())
                .email(usuario.getEmail())
                .nombreCompleto(usuario.getNombreCompleto())
                .telefono(usuario.getTelefono())
                .rol(usuario.getRol())
                .condominioId(usuario.getCondominio() != null ? usuario.getCondominio().getId() : null)
                .condominioNombre(usuario.getCondominio() != null ? usuario.getCondominio().getNombre() : null)
                .unidadHabitacional(usuario.getUnidadHabitacional())
                .esPropietario(usuario.getEsPropietario())
                .activo(usuario.getActivo())
                .createdAt(usuario.getCreatedAt())
                .build();
    }
}
```

- [ ] **Step 2: Verify compilation**

```bash
cd /Users/jandrade2/flutter/condos/backend && ./mvnw compile -q 2>&1 | tail -5
```

Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add backend/src/main/java/com/condos/usuario/service/UsuarioService.java
git commit -m "feat(usuarios): add UsuarioService with CRUD and tenant validation"
```

---

### Task 3: Backend — UsuarioController

**Files:**
- Create: `backend/src/main/java/com/condos/usuario/controller/UsuarioController.java`

- [ ] **Step 1: Create UsuarioController.java**

```java
package com.condos.usuario.controller;

import com.condos.usuario.dto.CreateUsuarioRequest;
import com.condos.usuario.dto.UpdateUsuarioRequest;
import com.condos.usuario.dto.UsuarioResponse;
import com.condos.usuario.service.UsuarioService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/usuarios")
@RequiredArgsConstructor
public class UsuarioController {

    private final UsuarioService usuarioService;

    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPERADMIN')")
    public ResponseEntity<List<UsuarioResponse>> listarUsuarios() {
        return ResponseEntity.ok(usuarioService.listarUsuarios());
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPERADMIN')")
    public ResponseEntity<UsuarioResponse> crearUsuario(
            @Valid @RequestBody CreateUsuarioRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(usuarioService.crearUsuario(request));
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPERADMIN')")
    public ResponseEntity<UsuarioResponse> obtenerUsuario(@PathVariable Long id) {
        return ResponseEntity.ok(usuarioService.obtenerUsuario(id));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPERADMIN')")
    public ResponseEntity<UsuarioResponse> actualizarUsuario(
            @PathVariable Long id,
            @Valid @RequestBody UpdateUsuarioRequest request) {
        return ResponseEntity.ok(usuarioService.actualizarUsuario(id, request));
    }

    @PutMapping("/{id}/estado")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPERADMIN')")
    public ResponseEntity<UsuarioResponse> toggleEstado(@PathVariable Long id) {
        return ResponseEntity.ok(usuarioService.toggleEstado(id));
    }
}
```

- [ ] **Step 2: Build and verify no errors**

```bash
cd /Users/jandrade2/flutter/condos/backend && ./mvnw compile -q 2>&1 | tail -5
```

Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add backend/src/main/java/com/condos/usuario/controller/UsuarioController.java
git commit -m "feat(usuarios): add UsuarioController with 5 REST endpoints"
```

- [ ] **Step 4: Manual smoke test (requires backend running)**

Start backend:
```bash
cd /Users/jandrade2/flutter/condos/backend && ./mvnw spring-boot:run &
```

Get a token:
```bash
TOKEN=$(curl -s -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}' | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])")
```

List users:
```bash
curl -s -H "Authorization: Bearer $TOKEN" http://localhost:8080/api/usuarios | python3 -m json.tool
```

Expected: JSON array with the admin user (or empty if no other users in the condominio).

Create a user:
```bash
curl -s -X POST http://localhost:8080/api/usuarios \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"username":"guardia1","email":"guardia1@laspalmas.com","password":"guard123","nombreCompleto":"Guardia Uno","rol":"GUARDIA"}' \
  | python3 -m json.tool
```

Expected: 201 Created with the new user JSON.

Toggle estado:
```bash
# Use the id returned from the create above (e.g., 3)
curl -s -X PUT http://localhost:8080/api/usuarios/3/estado \
  -H "Authorization: Bearer $TOKEN" | python3 -m json.tool
```

Expected: user with `"activo": false`.

---

### Task 4: Flutter — Models

**Files:**
- Create: `lib/features/usuarios/models/usuario_admin.dart`
- Create: `lib/features/usuarios/models/usuario_admin.g.dart`
- Create: `lib/features/usuarios/models/create_usuario_request.dart`
- Create: `lib/features/usuarios/models/create_usuario_request.g.dart`
- Create: `lib/features/usuarios/models/update_usuario_request.dart`
- Create: `lib/features/usuarios/models/update_usuario_request.g.dart`

- [ ] **Step 1: Create directory structure**

```bash
mkdir -p lib/features/usuarios/models lib/features/usuarios/services \
         lib/features/usuarios/providers lib/features/usuarios/screens
```

- [ ] **Step 2: Create usuario_admin.dart**

```dart
import 'package:json_annotation/json_annotation.dart';

part 'usuario_admin.g.dart';

enum RolUsuario {
  @JsonValue('SUPERADMIN')
  superadmin,

  @JsonValue('ADMIN')
  admin,

  @JsonValue('USUARIO')
  usuario,

  @JsonValue('GUARDIA')
  guardia,
}

@JsonSerializable()
class UsuarioAdmin {
  final int id;
  final String username;
  final String email;
  final String nombreCompleto;
  final String? telefono;
  final RolUsuario rol;
  final int? condominioId;
  final String? condominioNombre;
  final String? unidadHabitacional;
  final bool esPropietario;
  final bool activo;
  final DateTime createdAt;

  UsuarioAdmin({
    required this.id,
    required this.username,
    required this.email,
    required this.nombreCompleto,
    this.telefono,
    required this.rol,
    this.condominioId,
    this.condominioNombre,
    this.unidadHabitacional,
    required this.esPropietario,
    required this.activo,
    required this.createdAt,
  });

  factory UsuarioAdmin.fromJson(Map<String, dynamic> json) =>
      _$UsuarioAdminFromJson(json);
  Map<String, dynamic> toJson() => _$UsuarioAdminToJson(this);
}
```

- [ ] **Step 3: Create usuario_admin.g.dart (manual)**

```dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'usuario_admin.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UsuarioAdmin _$UsuarioAdminFromJson(Map<String, dynamic> json) => UsuarioAdmin(
      id: (json['id'] as num).toInt(),
      username: json['username'] as String,
      email: json['email'] as String,
      nombreCompleto: json['nombreCompleto'] as String,
      telefono: json['telefono'] as String?,
      rol: $enumDecode(_$RolUsuarioEnumMap, json['rol']),
      condominioId: (json['condominioId'] as num?)?.toInt(),
      condominioNombre: json['condominioNombre'] as String?,
      unidadHabitacional: json['unidadHabitacional'] as String?,
      esPropietario: json['esPropietario'] as bool,
      activo: json['activo'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$UsuarioAdminToJson(UsuarioAdmin instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'email': instance.email,
      'nombreCompleto': instance.nombreCompleto,
      'telefono': instance.telefono,
      'rol': _$RolUsuarioEnumMap[instance.rol]!,
      'condominioId': instance.condominioId,
      'condominioNombre': instance.condominioNombre,
      'unidadHabitacional': instance.unidadHabitacional,
      'esPropietario': instance.esPropietario,
      'activo': instance.activo,
      'createdAt': instance.createdAt.toIso8601String(),
    };

const _$RolUsuarioEnumMap = {
  RolUsuario.superadmin: 'SUPERADMIN',
  RolUsuario.admin: 'ADMIN',
  RolUsuario.usuario: 'USUARIO',
  RolUsuario.guardia: 'GUARDIA',
};
```

- [ ] **Step 4: Create create_usuario_request.dart**

```dart
import 'package:json_annotation/json_annotation.dart';

part 'create_usuario_request.g.dart';

@JsonSerializable()
class CreateUsuarioRequest {
  final String username;
  final String email;
  final String password;
  final String nombreCompleto;
  final String? telefono;
  final String rol;
  final String? unidadHabitacional;
  final bool esPropietario;
  final int? condominioId;

  CreateUsuarioRequest({
    required this.username,
    required this.email,
    required this.password,
    required this.nombreCompleto,
    this.telefono,
    required this.rol,
    this.unidadHabitacional,
    this.esPropietario = false,
    this.condominioId,
  });

  factory CreateUsuarioRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateUsuarioRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateUsuarioRequestToJson(this);
}
```

- [ ] **Step 5: Create create_usuario_request.g.dart (manual)**

```dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_usuario_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateUsuarioRequest _$CreateUsuarioRequestFromJson(
        Map<String, dynamic> json) =>
    CreateUsuarioRequest(
      username: json['username'] as String,
      email: json['email'] as String,
      password: json['password'] as String,
      nombreCompleto: json['nombreCompleto'] as String,
      telefono: json['telefono'] as String?,
      rol: json['rol'] as String,
      unidadHabitacional: json['unidadHabitacional'] as String?,
      esPropietario: json['esPropietario'] as bool? ?? false,
      condominioId: (json['condominioId'] as num?)?.toInt(),
    );

Map<String, dynamic> _$CreateUsuarioRequestToJson(
        CreateUsuarioRequest instance) =>
    <String, dynamic>{
      'username': instance.username,
      'email': instance.email,
      'password': instance.password,
      'nombreCompleto': instance.nombreCompleto,
      'telefono': instance.telefono,
      'rol': instance.rol,
      'unidadHabitacional': instance.unidadHabitacional,
      'esPropietario': instance.esPropietario,
      'condominioId': instance.condominioId,
    };
```

- [ ] **Step 6: Create update_usuario_request.dart**

```dart
import 'package:json_annotation/json_annotation.dart';

part 'update_usuario_request.g.dart';

@JsonSerializable()
class UpdateUsuarioRequest {
  final String nombreCompleto;
  final String? telefono;
  final String rol;
  final String? unidadHabitacional;
  final bool esPropietario;

  UpdateUsuarioRequest({
    required this.nombreCompleto,
    this.telefono,
    required this.rol,
    this.unidadHabitacional,
    required this.esPropietario,
  });

  factory UpdateUsuarioRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateUsuarioRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateUsuarioRequestToJson(this);
}
```

- [ ] **Step 7: Create update_usuario_request.g.dart (manual)**

```dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_usuario_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateUsuarioRequest _$UpdateUsuarioRequestFromJson(
        Map<String, dynamic> json) =>
    UpdateUsuarioRequest(
      nombreCompleto: json['nombreCompleto'] as String,
      telefono: json['telefono'] as String?,
      rol: json['rol'] as String,
      unidadHabitacional: json['unidadHabitacional'] as String?,
      esPropietario: json['esPropietario'] as bool,
    );

Map<String, dynamic> _$UpdateUsuarioRequestToJson(
        UpdateUsuarioRequest instance) =>
    <String, dynamic>{
      'nombreCompleto': instance.nombreCompleto,
      'telefono': instance.telefono,
      'rol': instance.rol,
      'unidadHabitacional': instance.unidadHabitacional,
      'esPropietario': instance.esPropietario,
    };
```

- [ ] **Step 8: Verify models compile**

```bash
flutter analyze lib/features/usuarios/models/ 2>&1 | grep -v "Swift Package Manager" | grep -v "mobile_scanner" | grep -v "flutter_secure_storage"
```

Expected: `No issues found!`

- [ ] **Step 9: Commit**

```bash
git add lib/features/usuarios/models/
git commit -m "feat(usuarios): add Flutter models UsuarioAdmin, CreateUsuarioRequest, UpdateUsuarioRequest"
```

---

### Task 5: Flutter — ApiConstants + UsuarioAdminService

**Files:**
- Modify: `lib/core/constants/api_constants.dart`
- Create: `lib/features/usuarios/services/usuario_admin_service.dart`

- [ ] **Step 1: Add usuario endpoints to ApiConstants**

In `lib/core/constants/api_constants.dart`, add after the visitas block:

```dart
  // Usuarios (gestión por ADMIN)
  static const String usuarios = '$apiPrefix/usuarios';
  static String usuarioById(int id) => '$apiPrefix/usuarios/$id';
  static String usuarioEstado(int id) => '$apiPrefix/usuarios/$id/estado';
```

- [ ] **Step 2: Create usuario_admin_service.dart**

```dart
import '../../../core/constants/api_constants.dart';
import '../../../shared/services/api_client.dart';
import '../models/create_usuario_request.dart';
import '../models/update_usuario_request.dart';
import '../models/usuario_admin.dart';

class UsuarioAdminService {
  final ApiClient apiClient;

  UsuarioAdminService({required this.apiClient});

  Future<List<UsuarioAdmin>> listarUsuarios() async {
    final response = await apiClient.getList(ApiConstants.usuarios);
    return response
        .map((item) => UsuarioAdmin.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<UsuarioAdmin> crearUsuario(CreateUsuarioRequest request) async {
    final response = await apiClient.post(ApiConstants.usuarios, request.toJson());
    return UsuarioAdmin.fromJson(response);
  }

  Future<UsuarioAdmin> obtenerUsuario(int id) async {
    final response = await apiClient.get(ApiConstants.usuarioById(id));
    return UsuarioAdmin.fromJson(response);
  }

  Future<UsuarioAdmin> actualizarUsuario(int id, UpdateUsuarioRequest request) async {
    final response = await apiClient.put(ApiConstants.usuarioById(id), request.toJson());
    return UsuarioAdmin.fromJson(response);
  }

  Future<UsuarioAdmin> toggleEstado(int id) async {
    final response = await apiClient.put(ApiConstants.usuarioEstado(id), {});
    return UsuarioAdmin.fromJson(response);
  }
}
```

- [ ] **Step 3: Verify**

```bash
flutter analyze lib/features/usuarios/services/ lib/core/constants/api_constants.dart 2>&1 | grep -v "Swift Package Manager" | grep -v "mobile_scanner" | grep -v "flutter_secure_storage"
```

Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/core/constants/api_constants.dart lib/features/usuarios/services/usuario_admin_service.dart
git commit -m "feat(usuarios): add UsuarioAdminService and usuario API constants"
```

---

### Task 6: Flutter — UsuarioAdminNotifier + Provider

**Files:**
- Create: `lib/features/usuarios/providers/usuario_admin_provider.dart`

- [ ] **Step 1: Create usuario_admin_provider.dart**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/auth_provider.dart';
import '../models/create_usuario_request.dart';
import '../models/update_usuario_request.dart';
import '../models/usuario_admin.dart';
import '../services/usuario_admin_service.dart';

class UsuarioAdminState {
  final List<UsuarioAdmin> usuarios;
  final bool isLoading;
  final String? error;

  UsuarioAdminState({
    this.usuarios = const [],
    this.isLoading = false,
    this.error,
  });

  UsuarioAdminState copyWith({
    List<UsuarioAdmin>? usuarios,
    bool? isLoading,
    String? error,
  }) {
    return UsuarioAdminState(
      usuarios: usuarios ?? this.usuarios,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class UsuarioAdminNotifier extends StateNotifier<UsuarioAdminState> {
  final UsuarioAdminService _service;

  UsuarioAdminNotifier(this._service) : super(UsuarioAdminState());

  Future<void> cargarUsuarios() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final usuarios = await _service.listarUsuarios();
      state = state.copyWith(usuarios: usuarios, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<UsuarioAdmin?> crearUsuario(CreateUsuarioRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final nuevo = await _service.crearUsuario(request);
      state = state.copyWith(
        usuarios: [...state.usuarios, nuevo],
        isLoading: false,
      );
      return nuevo;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<void> actualizarUsuario(int id, UpdateUsuarioRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final actualizado = await _service.actualizarUsuario(id, request);
      state = state.copyWith(
        usuarios: state.usuarios.map((u) => u.id == id ? actualizado : u).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> toggleEstado(int id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final actualizado = await _service.toggleEstado(id);
      state = state.copyWith(
        usuarios: state.usuarios.map((u) => u.id == id ? actualizado : u).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final usuarioAdminServiceProvider = Provider<UsuarioAdminService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return UsuarioAdminService(apiClient: apiClient);
});

final usuarioAdminProvider =
    StateNotifierProvider<UsuarioAdminNotifier, UsuarioAdminState>((ref) {
  final service = ref.watch(usuarioAdminServiceProvider);
  return UsuarioAdminNotifier(service);
});
```

- [ ] **Step 2: Verify**

```bash
flutter analyze lib/features/usuarios/providers/ 2>&1 | grep -v "Swift Package Manager" | grep -v "mobile_scanner" | grep -v "flutter_secure_storage"
```

Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/features/usuarios/providers/usuario_admin_provider.dart
git commit -m "feat(usuarios): add UsuarioAdminNotifier and Riverpod provider"
```

---

### Task 7: Flutter — GestionScreen (lista de usuarios)

**Files:**
- Create: `lib/features/usuarios/screens/gestion_screen.dart`
- Delete: `lib/features/perfil/screens/gestion_screen.dart`

- [ ] **Step 1: Create gestion_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/usuario_admin.dart';
import '../providers/usuario_admin_provider.dart';

class GestionScreen extends ConsumerStatefulWidget {
  const GestionScreen({super.key});

  @override
  ConsumerState<GestionScreen> createState() => _GestionScreenState();
}

class _GestionScreenState extends ConsumerState<GestionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(usuarioAdminProvider.notifier).cargarUsuarios();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(usuarioAdminProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(usuarioAdminProvider.notifier).cargarUsuarios(),
          ),
        ],
      ),
      body: _buildBody(context, state),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/home/usuarios/nuevo'),
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildBody(BuildContext context, UsuarioAdminState state) {
    if (state.isLoading && state.usuarios.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.usuarios.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 8),
            Text(state.error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(usuarioAdminProvider.notifier).cargarUsuarios(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (state.usuarios.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.group_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 8),
            Text('No hay usuarios registrados'),
            SizedBox(height: 4),
            Text('Usa el botón + para agregar uno', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: state.usuarios.length,
      itemBuilder: (context, index) {
        final usuario = state.usuarios[index];
        return _UsuarioTile(
          usuario: usuario,
          onTap: () => context.push('/home/usuarios/${usuario.id}'),
        );
      },
    );
  }
}

class _UsuarioTile extends StatelessWidget {
  final UsuarioAdmin usuario;
  final VoidCallback onTap;

  const _UsuarioTile({required this.usuario, required this.onTap});

  Color _rolColor() => switch (usuario.rol) {
        RolUsuario.guardia => Colors.green,
        RolUsuario.usuario => Colors.blue,
        RolUsuario.admin => Colors.purple,
        RolUsuario.superadmin => Colors.red,
      };

  String _rolLabel() => switch (usuario.rol) {
        RolUsuario.guardia => 'GUARDIA',
        RolUsuario.usuario => 'USUARIO',
        RolUsuario.admin => 'ADMIN',
        RolUsuario.superadmin => 'SUPERADMIN',
      };

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: usuario.activo ? _rolColor().withOpacity(0.15) : Colors.grey.shade200,
        child: Icon(
          usuario.rol == RolUsuario.guardia ? Icons.security : Icons.person,
          color: usuario.activo ? _rolColor() : Colors.grey,
        ),
      ),
      title: Text(
        usuario.nombreCompleto,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: usuario.activo ? null : Colors.grey,
        ),
      ),
      subtitle: Text('@${usuario.username}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Chip(
            label: Text(
              _rolLabel(),
              style: const TextStyle(fontSize: 10, color: Colors.white),
            ),
            backgroundColor: usuario.activo ? _rolColor() : Colors.grey,
            padding: EdgeInsets.zero,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          if (!usuario.activo) ...[
            const SizedBox(width: 4),
            const Icon(Icons.block, color: Colors.grey, size: 16),
          ],
        ],
      ),
      onTap: onTap,
    );
  }
}
```

- [ ] **Step 2: Delete the placeholder GestionScreen**

```bash
rm lib/features/perfil/screens/gestion_screen.dart
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/usuarios/screens/gestion_screen.dart
git rm lib/features/perfil/screens/gestion_screen.dart
git commit -m "feat(usuarios): add GestionScreen with user list, replace placeholder"
```

---

### Task 8: Flutter — CrearUsuarioScreen

**Files:**
- Create: `lib/features/usuarios/screens/crear_usuario_screen.dart`

- [ ] **Step 1: Create crear_usuario_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/create_usuario_request.dart';
import '../providers/usuario_admin_provider.dart';

class CrearUsuarioScreen extends ConsumerStatefulWidget {
  const CrearUsuarioScreen({super.key});

  @override
  ConsumerState<CrearUsuarioScreen> createState() => _CrearUsuarioScreenState();
}

class _CrearUsuarioScreenState extends ConsumerState<CrearUsuarioScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _unidadController = TextEditingController();
  bool _obscurePassword = true;
  String _selectedRol = 'USUARIO';
  bool _esPropietario = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _telefonoController.dispose();
    _unidadController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final request = CreateUsuarioRequest(
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      nombreCompleto: _nombreController.text.trim(),
      telefono: _telefonoController.text.trim().isEmpty ? null : _telefonoController.text.trim(),
      rol: _selectedRol,
      unidadHabitacional: _unidadController.text.trim().isEmpty ? null : _unidadController.text.trim(),
      esPropietario: _esPropietario,
    );

    final nuevo = await ref.read(usuarioAdminProvider.notifier).crearUsuario(request);

    if (!mounted) return;

    if (nuevo != null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usuario creado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      final error = ref.read(usuarioAdminProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Error al crear el usuario'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(usuarioAdminProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo Usuario')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre completo *',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                textInputAction: TextInputAction.next,
                enabled: !isLoading,
              ),
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Requerido';
                  if (!v.contains('@')) return 'Email inválido';
                  return null;
                },
                textInputAction: TextInputAction.next,
                enabled: !isLoading,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Contraseña *',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                obscureText: _obscurePassword,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requerido';
                  if (v.length < 6) return 'Mínimo 6 caracteres';
                  return null;
                },
                textInputAction: TextInputAction.next,
                enabled: !isLoading,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telefonoController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                enabled: !isLoading,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _unidadController,
                decoration: const InputDecoration(
                  labelText: 'Unidad habitacional',
                  prefixIcon: Icon(Icons.home),
                  hintText: 'Ej: A-101',
                ),
                textInputAction: TextInputAction.next,
                enabled: !isLoading,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedRol,
                decoration: const InputDecoration(
                  labelText: 'Rol *',
                  prefixIcon: Icon(Icons.badge),
                ),
                items: const [
                  DropdownMenuItem(value: 'USUARIO', child: Text('USUARIO — Residente')),
                  DropdownMenuItem(value: 'GUARDIA', child: Text('GUARDIA — Guardia de seguridad')),
                ],
                onChanged: isLoading ? null : (v) => setState(() => _selectedRol = v!),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Es propietario'),
                subtitle: const Text('El residente es dueño de la unidad'),
                value: _esPropietario,
                onChanged: isLoading ? null : (v) => setState(() => _esPropietario = v),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Crear Usuario', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/usuarios/screens/crear_usuario_screen.dart
git commit -m "feat(usuarios): add CrearUsuarioScreen with form validation"
```

---

### Task 9: Flutter — DetalleUsuarioScreen

**Files:**
- Create: `lib/features/usuarios/screens/detalle_usuario_screen.dart`

- [ ] **Step 1: Create detalle_usuario_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/update_usuario_request.dart';
import '../models/usuario_admin.dart';
import '../providers/usuario_admin_provider.dart';

class DetalleUsuarioScreen extends ConsumerStatefulWidget {
  final int usuarioId;

  const DetalleUsuarioScreen({super.key, required this.usuarioId});

  @override
  ConsumerState<DetalleUsuarioScreen> createState() => _DetalleUsuarioScreenState();
}

class _DetalleUsuarioScreenState extends ConsumerState<DetalleUsuarioScreen> {
  bool _editMode = false;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _telefonoController;
  late TextEditingController _unidadController;
  String _selectedRol = 'USUARIO';
  bool _esPropietario = false;

  UsuarioAdmin? _findUsuario() {
    final usuarios = ref.read(usuarioAdminProvider).usuarios;
    for (final u in usuarios) {
      if (u.id == widget.usuarioId) return u;
    }
    return null;
  }

  void _initEditFields(UsuarioAdmin usuario) {
    _nombreController = TextEditingController(text: usuario.nombreCompleto);
    _telefonoController = TextEditingController(text: usuario.telefono ?? '');
    _unidadController = TextEditingController(text: usuario.unidadHabitacional ?? '');
    _selectedRol = usuario.rol == RolUsuario.guardia ? 'GUARDIA' : 'USUARIO';
    _esPropietario = usuario.esPropietario;
  }

  @override
  void initState() {
    super.initState();
    final usuario = _findUsuario();
    if (usuario != null) {
      _initEditFields(usuario);
    } else {
      _nombreController = TextEditingController();
      _telefonoController = TextEditingController();
      _unidadController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _unidadController.dispose();
    super.dispose();
  }

  Future<void> _saveEdit(UsuarioAdmin usuario) async {
    if (!_formKey.currentState!.validate()) return;

    final request = UpdateUsuarioRequest(
      nombreCompleto: _nombreController.text.trim(),
      telefono: _telefonoController.text.trim().isEmpty ? null : _telefonoController.text.trim(),
      rol: _selectedRol,
      unidadHabitacional: _unidadController.text.trim().isEmpty ? null : _unidadController.text.trim(),
      esPropietario: _esPropietario,
    );

    await ref.read(usuarioAdminProvider.notifier).actualizarUsuario(usuario.id, request);

    if (!mounted) return;
    setState(() => _editMode = false);

    final error = ref.read(usuarioAdminProvider).error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Usuario actualizado'),
        backgroundColor: error != null ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _toggleEstado(UsuarioAdmin usuario) async {
    final action = usuario.activo ? 'desactivar' : 'activar';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${action[0].toUpperCase()}${action.substring(1)} usuario'),
        content: Text('¿Deseas $action a ${usuario.nombreCompleto}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Sí, $action')),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    await ref.read(usuarioAdminProvider.notifier).toggleEstado(usuario.id);

    if (!mounted) return;
    final error = ref.read(usuarioAdminProvider).error;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(usuarioAdminProvider);
    final usuario = _findUsuario();

    return Scaffold(
      appBar: AppBar(
        title: Text(usuario?.nombreCompleto ?? 'Usuario'),
        actions: [
          if (usuario != null && !_editMode)
            TextButton(
              onPressed: () {
                _initEditFields(usuario);
                setState(() => _editMode = true);
              },
              child: const Text('Editar'),
            ),
          if (_editMode)
            TextButton(
              onPressed: () => setState(() => _editMode = false),
              child: const Text('Cancelar'),
            ),
        ],
      ),
      body: usuario == null
          ? const Center(child: Text('Usuario no encontrado'))
          : _editMode
              ? _buildEditForm(usuario)
              : _buildDetail(usuario),
    );
  }

  Widget _buildDetail(UsuarioAdmin usuario) {
    final isLoading = ref.watch(usuarioAdminProvider).isLoading;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(icon: Icons.person, label: 'Nombre', value: usuario.nombreCompleto),
          _InfoRow(icon: Icons.alternate_email, label: 'Username', value: '@${usuario.username}'),
          _InfoRow(icon: Icons.email, label: 'Email', value: usuario.email),
          if (usuario.telefono != null)
            _InfoRow(icon: Icons.phone, label: 'Teléfono', value: usuario.telefono!),
          if (usuario.unidadHabitacional != null)
            _InfoRow(icon: Icons.home, label: 'Unidad', value: usuario.unidadHabitacional!),
          _InfoRow(
            icon: Icons.badge,
            label: 'Rol',
            value: usuario.rol.name.toUpperCase(),
          ),
          _InfoRow(
            icon: Icons.check_circle,
            label: 'Propietario',
            value: usuario.esPropietario ? 'Sí' : 'No',
          ),
          _InfoRow(
            icon: usuario.activo ? Icons.check_circle_outline : Icons.block,
            label: 'Estado',
            value: usuario.activo ? 'Activo' : 'Inactivo',
            valueColor: usuario.activo ? Colors.green : Colors.red,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isLoading ? null : () => _toggleEstado(usuario),
              icon: Icon(
                usuario.activo ? Icons.block : Icons.check_circle_outline,
                color: usuario.activo ? Colors.red : Colors.green,
              ),
              label: Text(
                usuario.activo ? 'Desactivar usuario' : 'Activar usuario',
                style: TextStyle(color: usuario.activo ? Colors.red : Colors.green),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: usuario.activo ? Colors.red : Colors.green),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm(UsuarioAdmin usuario) {
    final isLoading = ref.watch(usuarioAdminProvider).isLoading;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre completo *',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              enabled: !isLoading,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _telefonoController,
              decoration: const InputDecoration(
                labelText: 'Teléfono',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
              enabled: !isLoading,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _unidadController,
              decoration: const InputDecoration(
                labelText: 'Unidad habitacional',
                prefixIcon: Icon(Icons.home),
              ),
              enabled: !isLoading,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedRol,
              decoration: const InputDecoration(
                labelText: 'Rol *',
                prefixIcon: Icon(Icons.badge),
              ),
              items: const [
                DropdownMenuItem(value: 'USUARIO', child: Text('USUARIO — Residente')),
                DropdownMenuItem(value: 'GUARDIA', child: Text('GUARDIA — Guardia de seguridad')),
              ],
              onChanged: isLoading ? null : (v) => setState(() => _selectedRol = v!),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Es propietario'),
              value: _esPropietario,
              onChanged: isLoading ? null : (v) => setState(() => _esPropietario = v),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isLoading ? null : () => _saveEdit(usuario),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Guardar cambios', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              Text(
                value,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: valueColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/usuarios/screens/detalle_usuario_screen.dart
git commit -m "feat(usuarios): add DetalleUsuarioScreen with inline edit and toggle estado"
```

---

### Task 10: Flutter — GoRouter + MainScaffold

**Files:**
- Modify: `lib/core/routes/app_router.dart`
- Modify: `lib/shared/widgets/main_scaffold.dart`

- [ ] **Step 1: Update app_router.dart — add usuario sub-routes**

In `lib/core/routes/app_router.dart`, add these imports at the top:

```dart
import '../../features/usuarios/screens/crear_usuario_screen.dart';
import '../../features/usuarios/screens/detalle_usuario_screen.dart';
```

And add to the `/home` route's `routes:` list (after the existing `visitas/:id` route):

```dart
          GoRoute(
            path: 'usuarios/nuevo',
            builder: (context, state) => const CrearUsuarioScreen(),
          ),
          GoRoute(
            path: 'usuarios/:id',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return DetalleUsuarioScreen(usuarioId: id);
            },
          ),
```

- [ ] **Step 2: Update main_scaffold.dart — fix GestionScreen import**

In `lib/shared/widgets/main_scaffold.dart`, replace:

```dart
import '../../features/perfil/screens/gestion_screen.dart';
```

with:

```dart
import '../../features/usuarios/screens/gestion_screen.dart';
```

- [ ] **Step 3: Verify full project compiles**

```bash
flutter analyze lib/ 2>&1 | grep -v "Swift Package Manager" | grep -v "mobile_scanner" | grep -v "flutter_secure_storage"
```

Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/core/routes/app_router.dart lib/shared/widgets/main_scaffold.dart
git commit -m "feat(usuarios): wire GoRouter routes and update MainScaffold import"
```

---

### Task 11: Final verification

- [ ] **Step 1: Run flutter analyze**

```bash
flutter analyze 2>&1 | grep -v "Swift Package Manager" | grep -v "mobile_scanner" | grep -v "flutter_secure_storage"
```

Expected: `No issues found!`

- [ ] **Step 2: Build backend**

```bash
cd /Users/jandrade2/flutter/condos/backend && ./mvnw compile -q 2>&1 | tail -3
```

Expected: No errors.

- [ ] **Step 3: Final commit**

```bash
git add -A && git status
# Verify only expected files changed, then:
git commit -m "feat(usuarios): complete gestión de usuarios for ADMIN/SUPERADMIN" --allow-empty
```

If nothing is left unstaged, the previous commits cover everything. Check `git log --oneline -10` to verify all tasks are committed.
