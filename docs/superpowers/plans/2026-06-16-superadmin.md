# SUPERADMIN — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implementar el panel SUPERADMIN: CRUD de condominios y creación de usuarios ADMIN por condominio. El rol ya existe en BD y JWT (`condominioId=null`).

**Architecture:** Backend: DTOs + CondominioService + CondominioController (5 endpoints, todos protegidos por SUPERADMIN). Flutter: modelos + provider + 3 pantallas nuevas + separar SUPERADMIN del ADMIN en MainScaffold. Sin migraciones — la tabla `condominios` ya existe.

**Tech Stack:** Spring Boot 3 + JPA | Flutter + Riverpod + GoRouter + json_annotation (sin build_runner)

---

## File Map

### Backend — nuevos archivos

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

### Backend — archivos modificados

```
com/condos/condominio/repository/CondominioRepository.java
  + findAllByOrderByNombreAsc()
```

### Flutter — nuevos archivos

```
lib/features/superadmin/
  models/
    condominio_sa.dart + .g.dart
    create_condominio_request.dart + .g.dart
  services/
    condominio_sa_service.dart
  providers/
    condominio_sa_provider.dart
  screens/
    superadmin_dashboard_screen.dart
    crear_editar_condominio_screen.dart
    detalle_condominio_screen.dart
```

### Flutter — archivos modificados

```
lib/core/constants/api_constants.dart        ← 4 nuevas constantes
lib/core/routes/app_router.dart              ← 3 nuevas rutas
lib/shared/widgets/main_scaffold.dart        ← separar Rol.superadmin de Rol.admin
```

---

## Task 1: Backend — DTOs + CondominioRepository update

**Files:**
- Create: `backend/src/main/java/com/condos/condominio/dto/CreateCondominioRequest.java`
- Create: `backend/src/main/java/com/condos/condominio/dto/CondominioResponse.java`
- Modify: `backend/src/main/java/com/condos/condominio/repository/CondominioRepository.java`

- [ ] **Step 1: CreateCondominioRequest.java**

```java
package com.condos.condominio.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class CreateCondominioRequest {

    @NotBlank
    private String nombre;

    @NotBlank
    private String direccion;

    @NotNull
    @Min(1)
    private Integer numUnidades;

    private boolean activo = true;
}
```

- [ ] **Step 2: CondominioResponse.java**

```java
package com.condos.condominio.dto;

import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Builder
public class CondominioResponse {
    private Long id;
    private String nombre;
    private String direccion;
    private int numUnidades;
    private boolean activo;
    private int totalUsuarios;
    private int totalAdmins;
    private LocalDateTime createdAt;
}
```

- [ ] **Step 3: Agregar query a CondominioRepository**

```java
package com.condos.condominio.repository;

import com.condos.condominio.model.Condominio;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface CondominioRepository extends JpaRepository<Condominio, Long> {
    List<Condominio> findByActivoTrue();
    List<Condominio> findAllByOrderByNombreAsc();
}
```

- [ ] **Step 4: Commit**

```bash
git add backend/src/main/java/com/condos/condominio/dto/ \
        backend/src/main/java/com/condos/condominio/repository/CondominioRepository.java
git commit -m "feat(superadmin): add CondominioResponse, CreateCondominioRequest DTOs; extend CondominioRepository"
```

---

## Task 2: Backend — CondominioService + Controller + compilación

**Files:**
- Create: `backend/src/main/java/com/condos/condominio/service/CondominioService.java`
- Create: `backend/src/main/java/com/condos/condominio/controller/CondominioController.java`

- [ ] **Step 1: CondominioService.java**

```java
package com.condos.condominio.service;

import com.condos.common.exceptions.ResourceNotFoundException;
import com.condos.condominio.dto.CondominioResponse;
import com.condos.condominio.dto.CreateCondominioRequest;
import com.condos.condominio.model.Condominio;
import com.condos.condominio.repository.CondominioRepository;
import com.condos.usuario.dto.UsuarioResponse;
import com.condos.usuario.model.Rol;
import com.condos.usuario.repository.UsuarioRepository;
import com.condos.usuario.service.UsuarioService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class CondominioService {

    private final CondominioRepository condominioRepository;
    private final UsuarioRepository usuarioRepository;
    private final UsuarioService usuarioService;

    @Transactional(readOnly = true)
    public List<CondominioResponse> listarCondominios() {
        return condominioRepository.findAllByOrderByNombreAsc()
                .stream().map(this::toResponse).collect(Collectors.toList());
    }

    @Transactional
    public CondominioResponse crearCondominio(CreateCondominioRequest request) {
        Condominio condominio = Condominio.builder()
                .nombre(request.getNombre())
                .direccion(request.getDireccion())
                .numUnidades(request.getNumUnidades())
                .activo(request.isActivo())
                .build();
        condominio = condominioRepository.save(condominio);
        log.info("Condominio creado: id={}, nombre={}", condominio.getId(), condominio.getNombre());
        return toResponse(condominio);
    }

    @Transactional
    public CondominioResponse editarCondominio(Long id, CreateCondominioRequest request) {
        Condominio condominio = findById(id);
        condominio.setNombre(request.getNombre());
        condominio.setDireccion(request.getDireccion());
        condominio.setNumUnidades(request.getNumUnidades());
        condominio.setActivo(request.isActivo());
        condominio = condominioRepository.save(condominio);
        log.info("Condominio editado: id={}", id);
        return toResponse(condominio);
    }

    @Transactional
    public CondominioResponse toggleActivo(Long id) {
        Condominio condominio = findById(id);
        condominio.setActivo(!condominio.getActivo());
        condominio = condominioRepository.save(condominio);
        log.info("Condominio {} activo: {}", id, condominio.getActivo());
        return toResponse(condominio);
    }

    @Transactional(readOnly = true)
    public List<UsuarioResponse> listarAdmins(Long condominioId) {
        findById(condominioId);
        return usuarioRepository.findByCondominioIdAndRolAndActivo(condominioId, Rol.ADMIN, true)
                .stream().map(usuarioService::toResponse).collect(Collectors.toList());
    }

    private Condominio findById(Long id) {
        return condominioRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Condominio no encontrado"));
    }

    public CondominioResponse toResponse(Condominio c) {
        int totalUsuarios = usuarioRepository.findByCondominioId(c.getId()).size();
        long totalAdmins = usuarioRepository.findByCondominioIdAndRolAndActivo(c.getId(), Rol.ADMIN, true).size();
        return CondominioResponse.builder()
                .id(c.getId())
                .nombre(c.getNombre())
                .direccion(c.getDireccion())
                .numUnidades(c.getNumUnidades() != null ? c.getNumUnidades() : 0)
                .activo(c.getActivo())
                .totalUsuarios(totalUsuarios)
                .totalAdmins((int) totalAdmins)
                .createdAt(c.getCreatedAt())
                .build();
    }
}
```

- [ ] **Step 2: Hacer `toResponse` público en UsuarioService**

En `UsuarioService.java`, cambiar:
```java
private UsuarioResponse toResponse(Usuario usuario) {
```
por:
```java
public UsuarioResponse toResponse(Usuario usuario) {
```

- [ ] **Step 3: CondominioController.java**

```java
package com.condos.condominio.controller;

import com.condos.condominio.dto.CondominioResponse;
import com.condos.condominio.dto.CreateCondominioRequest;
import com.condos.condominio.service.CondominioService;
import com.condos.usuario.dto.UsuarioResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/condominios")
@RequiredArgsConstructor
public class CondominioController {

    private final CondominioService condominioService;

    @GetMapping
    @PreAuthorize("hasRole('SUPERADMIN')")
    public ResponseEntity<List<CondominioResponse>> listarCondominios() {
        return ResponseEntity.ok(condominioService.listarCondominios());
    }

    @PostMapping
    @PreAuthorize("hasRole('SUPERADMIN')")
    public ResponseEntity<CondominioResponse> crearCondominio(
            @Valid @RequestBody CreateCondominioRequest request) {
        return ResponseEntity.ok(condominioService.crearCondominio(request));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasRole('SUPERADMIN')")
    public ResponseEntity<CondominioResponse> editarCondominio(
            @PathVariable Long id,
            @Valid @RequestBody CreateCondominioRequest request) {
        return ResponseEntity.ok(condominioService.editarCondominio(id, request));
    }

    @PutMapping("/{id}/toggle")
    @PreAuthorize("hasRole('SUPERADMIN')")
    public ResponseEntity<CondominioResponse> toggleActivo(@PathVariable Long id) {
        return ResponseEntity.ok(condominioService.toggleActivo(id));
    }

    @GetMapping("/{id}/admins")
    @PreAuthorize("hasRole('SUPERADMIN')")
    public ResponseEntity<List<UsuarioResponse>> listarAdmins(@PathVariable Long id) {
        return ResponseEntity.ok(condominioService.listarAdmins(id));
    }
}
```

- [ ] **Step 4: Verificar compilación**

```bash
cd backend && ./mvnw compile -q
```

Expected: sin output.

- [ ] **Step 5: Commit**

```bash
git add backend/src/main/java/com/condos/condominio/service/ \
        backend/src/main/java/com/condos/condominio/controller/ \
        backend/src/main/java/com/condos/usuario/service/UsuarioService.java
git commit -m "feat(superadmin): add CondominioService, CondominioController — 5 endpoints; make toResponse public in UsuarioService"
```

---

## Task 3: Flutter Models + .g.dart

**Files:**
- Create: `lib/features/superadmin/models/condominio_sa.dart`
- Create: `lib/features/superadmin/models/condominio_sa.g.dart`
- Create: `lib/features/superadmin/models/create_condominio_request.dart`
- Create: `lib/features/superadmin/models/create_condominio_request.g.dart`

Nota: usamos el sufijo `_sa` (superadmin) para evitar conflicto con el modelo interno `Condominio` de Spring.

- [ ] **Step 1: condominio_sa.dart**

```dart
import 'package:json_annotation/json_annotation.dart';

part 'condominio_sa.g.dart';

@JsonSerializable()
class CondominiSa {
  final int id;
  final String nombre;
  final String? direccion;
  final int numUnidades;
  final bool activo;
  final int totalUsuarios;
  final int totalAdmins;
  final DateTime? createdAt;

  CondominiSa({
    required this.id,
    required this.nombre,
    this.direccion,
    required this.numUnidades,
    required this.activo,
    required this.totalUsuarios,
    required this.totalAdmins,
    this.createdAt,
  });

  factory CondominiSa.fromJson(Map<String, dynamic> json) =>
      _$CondominiSaFromJson(json);
  Map<String, dynamic> toJson() => _$CondominiSaToJson(this);
}
```

- [ ] **Step 2: condominio_sa.g.dart**

```dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'condominio_sa.dart';

CondominiSa _$CondominiSaFromJson(Map<String, dynamic> json) => CondominiSa(
      id: (json['id'] as num).toInt(),
      nombre: json['nombre'] as String,
      direccion: json['direccion'] as String?,
      numUnidades: (json['numUnidades'] as num).toInt(),
      activo: json['activo'] as bool,
      totalUsuarios: (json['totalUsuarios'] as num).toInt(),
      totalAdmins: (json['totalAdmins'] as num).toInt(),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$CondominiSaToJson(CondominiSa instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nombre': instance.nombre,
      'direccion': instance.direccion,
      'numUnidades': instance.numUnidades,
      'activo': instance.activo,
      'totalUsuarios': instance.totalUsuarios,
      'totalAdmins': instance.totalAdmins,
      'createdAt': instance.createdAt?.toIso8601String(),
    };
```

- [ ] **Step 3: create_condominio_request.dart**

```dart
import 'package:json_annotation/json_annotation.dart';

part 'create_condominio_request.g.dart';

@JsonSerializable()
class CreateCondominioRequest {
  final String nombre;
  final String direccion;
  final int numUnidades;
  final bool activo;

  CreateCondominioRequest({
    required this.nombre,
    required this.direccion,
    required this.numUnidades,
    required this.activo,
  });

  factory CreateCondominioRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateCondominioRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateCondominioRequestToJson(this);
}
```

- [ ] **Step 4: create_condominio_request.g.dart**

```dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_condominio_request.dart';

CreateCondominioRequest _$CreateCondominioRequestFromJson(
        Map<String, dynamic> json) =>
    CreateCondominioRequest(
      nombre: json['nombre'] as String,
      direccion: json['direccion'] as String,
      numUnidades: (json['numUnidades'] as num).toInt(),
      activo: json['activo'] as bool,
    );

Map<String, dynamic> _$CreateCondominioRequestToJson(
        CreateCondominioRequest instance) =>
    <String, dynamic>{
      'nombre': instance.nombre,
      'direccion': instance.direccion,
      'numUnidades': instance.numUnidades,
      'activo': instance.activo,
    };
```

- [ ] **Step 5: Commit**

```bash
git add lib/features/superadmin/models/
git commit -m "feat(superadmin): add Flutter models CondominiSa and CreateCondominioRequest with manual .g.dart"
```

---

## Task 4: ApiConstants + CondominioSaService + Provider

**Files:**
- Modify: `lib/core/constants/api_constants.dart`
- Create: `lib/features/superadmin/services/condominio_sa_service.dart`
- Create: `lib/features/superadmin/providers/condominio_sa_provider.dart`

- [ ] **Step 1: Agregar constantes a api_constants.dart**

Insertar antes de `// Áreas Comunes`:

```dart
  // Condominios (SUPERADMIN)
  static const String condominios = '$apiPrefix/condominios';
  static String condominioById(int id) => '$apiPrefix/condominios/$id';
  static String toggleCondominio(int id) => '$apiPrefix/condominios/$id/toggle';
  static String condominioAdmins(int id) => '$apiPrefix/condominios/$id/admins';
```

- [ ] **Step 2: condominio_sa_service.dart**

```dart
import '../../../core/constants/api_constants.dart';
import '../../../features/usuarios/models/usuario_admin.dart';
import '../../../shared/services/api_client.dart';
import '../models/condominio_sa.dart';
import '../models/create_condominio_request.dart';

class CondominioSaService {
  final ApiClient apiClient;

  CondominioSaService({required this.apiClient});

  Future<List<CondominiSa>> listarCondominios() async {
    final response = await apiClient.getList(ApiConstants.condominios);
    return response
        .map((item) => CondominiSa.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<CondominiSa> crearCondominio(CreateCondominioRequest request) async {
    final response =
        await apiClient.post(ApiConstants.condominios, request.toJson());
    return CondominiSa.fromJson(response);
  }

  Future<CondominiSa> editarCondominio(
      int id, CreateCondominioRequest request) async {
    final response =
        await apiClient.put(ApiConstants.condominioById(id), request.toJson());
    return CondominiSa.fromJson(response);
  }

  Future<CondominiSa> toggleActivo(int id) async {
    final response =
        await apiClient.put(ApiConstants.toggleCondominio(id), {});
    return CondominiSa.fromJson(response);
  }

  Future<List<UsuarioAdmin>> listarAdmins(int condominioId) async {
    final response =
        await apiClient.getList(ApiConstants.condominioAdmins(condominioId));
    return response
        .map((item) => UsuarioAdmin.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
```

- [ ] **Step 3: condominio_sa_provider.dart**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/auth_provider.dart';
import '../models/condominio_sa.dart';
import '../models/create_condominio_request.dart';
import '../services/condominio_sa_service.dart';

class CondominioSaState {
  final List<CondominiSa> condominios;
  final bool isLoading;
  final String? error;

  CondominioSaState({
    this.condominios = const [],
    this.isLoading = false,
    this.error,
  });

  CondominioSaState copyWith({
    List<CondominiSa>? condominios,
    bool? isLoading,
    String? error,
  }) {
    return CondominioSaState(
      condominios: condominios ?? this.condominios,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class CondominioSaNotifier extends StateNotifier<CondominioSaState> {
  final CondominioSaService _service;

  CondominioSaNotifier(this._service) : super(CondominioSaState());

  Future<void> cargarCondominios() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final condominios = await _service.listarCondominios();
      state = state.copyWith(condominios: condominios, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<CondominiSa?> crearCondominio(CreateCondominioRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final c = await _service.crearCondominio(request);
      final updated = [...state.condominios, c]
        ..sort((a, b) => a.nombre.compareTo(b.nombre));
      state = state.copyWith(condominios: updated, isLoading: false);
      return c;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<CondominiSa?> editarCondominio(
      int id, CreateCondominioRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updated = await _service.editarCondominio(id, request);
      state = state.copyWith(
        condominios: state.condominios
            .map((c) => c.id == id ? updated : c)
            .toList(),
        isLoading: false,
      );
      return updated;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<void> toggleActivo(int id) async {
    try {
      final updated = await _service.toggleActivo(id);
      state = state.copyWith(
        condominios: state.condominios
            .map((c) => c.id == id ? updated : c)
            .toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void clearError() => state = state.copyWith(error: null);
}

final condominioSaServiceProvider = Provider<CondominioSaService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CondominioSaService(apiClient: apiClient);
});

final condominioSaProvider =
    StateNotifierProvider<CondominioSaNotifier, CondominioSaState>((ref) {
  final service = ref.watch(condominioSaServiceProvider);
  return CondominioSaNotifier(service);
});
```

- [ ] **Step 4: Commit**

```bash
git add lib/core/constants/api_constants.dart \
        lib/features/superadmin/services/ \
        lib/features/superadmin/providers/
git commit -m "feat(superadmin): add ApiConstants, CondominioSaService, CondominioSaProvider"
```

---

## Task 5: SuperadminDashboardScreen

**Files:**
- Create: `lib/features/superadmin/screens/superadmin_dashboard_screen.dart`

- [ ] **Step 1: superadmin_dashboard_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/condominio_sa.dart';
import '../providers/condominio_sa_provider.dart';

class SuperadminDashboardScreen extends ConsumerStatefulWidget {
  const SuperadminDashboardScreen({super.key});

  @override
  ConsumerState<SuperadminDashboardScreen> createState() =>
      _SuperadminDashboardScreenState();
}

class _SuperadminDashboardScreenState
    extends ConsumerState<SuperadminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(condominioSaProvider.notifier).cargarCondominios();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(condominioSaProvider);
    final total = state.condominios.length;
    final activos = state.condominios.where((c) => c.activo).length;
    final inactivos = total - activos;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel SUPERADMIN'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(condominioSaProvider.notifier).cargarCondominios(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/home/condominios/nuevo');
          ref.read(condominioSaProvider.notifier).cargarCondominios();
        },
        child: const Icon(Icons.add),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(condominioSaProvider.notifier).cargarCondominios(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Stats cards
                  Row(
                    children: [
                      _StatCard('Total', total, Icons.apartment, Colors.indigo),
                      const SizedBox(width: 12),
                      _StatCard('Activos', activos, Icons.check_circle_outline,
                          Colors.green),
                      const SizedBox(width: 12),
                      _StatCard('Inactivos', inactivos, Icons.block,
                          Colors.grey),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Condominios',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  if (state.error != null)
                    Text(state.error!,
                        style: const TextStyle(color: Colors.red)),
                  if (state.condominios.isEmpty && !state.isLoading)
                    const Center(
                        child: Text('No hay condominios registrados.'))
                  else
                    ...state.condominios.map((c) => _CondominioTile(c: c)),
                ],
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _StatCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text('$value',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color)),
              Text(label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CondominioTile extends ConsumerWidget {
  final CondominiSa c;

  const _CondominioTile({required this.c});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              c.activo ? Colors.indigo : Colors.grey,
          child: const Icon(Icons.apartment, color: Colors.white),
        ),
        title: Text(c.nombre,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (c.direccion != null) Text(c.direccion!),
            Text(
                '${c.numUnidades} unidades · ${c.totalUsuarios} usuarios · ${c.totalAdmins} admins'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: c.activo,
              onChanged: (_) =>
                  ref.read(condominioSaProvider.notifier).toggleActivo(c.id),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () => context.push('/home/condominios/${c.id}/detalle'),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/superadmin/screens/superadmin_dashboard_screen.dart
git commit -m "feat(superadmin): add SuperadminDashboardScreen with stats cards and condominio list"
```

---

## Task 6: CrearEditarCondominioScreen

**Files:**
- Create: `lib/features/superadmin/screens/crear_editar_condominio_screen.dart`

- [ ] **Step 1: crear_editar_condominio_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/condominio_sa.dart';
import '../models/create_condominio_request.dart';
import '../providers/condominio_sa_provider.dart';

class CrearEditarCondominioScreen extends ConsumerStatefulWidget {
  final CondominiSa? condominio;

  const CrearEditarCondominioScreen({super.key, this.condominio});

  @override
  ConsumerState<CrearEditarCondominioScreen> createState() =>
      _CrearEditarCondominioScreenState();
}

class _CrearEditarCondominioScreenState
    extends ConsumerState<CrearEditarCondominioScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _direccionCtrl;
  late final TextEditingController _unidadesCtrl;
  late bool _activo;

  bool get _esEdicion => widget.condominio != null;

  @override
  void initState() {
    super.initState();
    final c = widget.condominio;
    _nombreCtrl = TextEditingController(text: c?.nombre ?? '');
    _direccionCtrl = TextEditingController(text: c?.direccion ?? '');
    _unidadesCtrl =
        TextEditingController(text: c?.numUnidades.toString() ?? '');
    _activo = c?.activo ?? true;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _direccionCtrl.dispose();
    _unidadesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final request = CreateCondominioRequest(
      nombre: _nombreCtrl.text.trim(),
      direccion: _direccionCtrl.text.trim(),
      numUnidades: int.parse(_unidadesCtrl.text.trim()),
      activo: _activo,
    );

    if (_esEdicion) {
      await ref
          .read(condominioSaProvider.notifier)
          .editarCondominio(widget.condominio!.id, request);
    } else {
      await ref.read(condominioSaProvider.notifier).crearCondominio(request);
    }

    if (mounted) {
      final error = ref.read(condominioSaProvider).error;
      if (error == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(_esEdicion
                ? 'Condominio actualizado'
                : 'Condominio creado exitosamente')));
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: Colors.red));
        ref.read(condominioSaProvider.notifier).clearError();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(condominioSaProvider);

    return Scaffold(
      appBar: AppBar(
          title:
              Text(_esEdicion ? 'Editar Condominio' : 'Nuevo Condominio')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(
                    labelText: 'Nombre *', border: OutlineInputBorder()),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _direccionCtrl,
                decoration: const InputDecoration(
                    labelText: 'Dirección *', border: OutlineInputBorder()),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _unidadesCtrl,
                decoration: const InputDecoration(
                    labelText: 'Número de unidades *',
                    border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Campo requerido';
                  final n = int.tryParse(v.trim());
                  if (n == null || n < 1) return 'Ingresa un número válido';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Condominio activo'),
                value: _activo,
                onChanged: (v) => setState(() => _activo = v),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: state.isLoading ? null : _submit,
                child: state.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(_esEdicion ? 'Guardar Cambios' : 'Crear Condominio'),
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
git add lib/features/superadmin/screens/crear_editar_condominio_screen.dart
git commit -m "feat(superadmin): add CrearEditarCondominioScreen for SUPERADMIN"
```

---

## Task 7: DetalleCondominioScreen

**Files:**
- Create: `lib/features/superadmin/screens/detalle_condominio_screen.dart`

- [ ] **Step 1: detalle_condominio_screen.dart**

Los admins se cargan localmente desde `condominioSaServiceProvider` (igual que comentarios en incidentes).

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../features/usuarios/models/usuario_admin.dart';
import '../../../features/usuarios/services/usuario_admin_service.dart';
import '../../../shared/providers/auth_provider.dart';
import '../models/condominio_sa.dart';
import '../providers/condominio_sa_provider.dart';
import '../services/condominio_sa_service.dart';

class DetalleCondominioScreen extends ConsumerStatefulWidget {
  final int condominioId;

  const DetalleCondominioScreen({super.key, required this.condominioId});

  @override
  ConsumerState<DetalleCondominioScreen> createState() =>
      _DetalleCondominioScreenState();
}

class _DetalleCondominioScreenState
    extends ConsumerState<DetalleCondominioScreen> {
  List<UsuarioAdmin> _admins = [];
  bool _loadingAdmins = true;

  CondominiSa? get _condominio {
    final state = ref.read(condominioSaProvider);
    return state.condominios
        .where((c) => c.id == widget.condominioId)
        .firstOrNull;
  }

  @override
  void initState() {
    super.initState();
    _cargarAdmins();
  }

  Future<void> _cargarAdmins() async {
    setState(() => _loadingAdmins = true);
    try {
      final service = ref.read(condominioSaServiceProvider);
      final admins = await service.listarAdmins(widget.condominioId);
      setState(() {
        _admins = admins;
        _loadingAdmins = false;
      });
    } catch (e) {
      setState(() => _loadingAdmins = false);
    }
  }

  Future<void> _mostrarFormularioAdmin() async {
    final usernameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final nombreCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    final apiClient = ref.read(apiClientProvider);
    final service = UsuarioAdminService(apiClient: apiClient);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Agregar Admin'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreCtrl,
                decoration: const InputDecoration(
                    labelText: 'Nombre completo',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: usernameCtrl,
                decoration: const InputDecoration(
                    labelText: 'Username', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(
                    labelText: 'Email', border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passCtrl,
                decoration: const InputDecoration(
                    labelText: 'Contraseña', border: OutlineInputBorder()),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              try {
                await service.crearUsuario(
                  com.condos.features.usuarios.models.CreateUsuarioRequest(
                    username: usernameCtrl.text.trim(),
                    email: emailCtrl.text.trim(),
                    password: passCtrl.text,
                    nombreCompleto: nombreCtrl.text.trim(),
                    rol: 'ADMIN',
                    condominioId: widget.condominioId,
                    esPropietario: false,
                  ),
                );
                if (ctx.mounted) Navigator.pop(ctx);
                _cargarAdmins();
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                        content: Text(e.toString()),
                        backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Crear Admin'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(condominioSaProvider);
    final condominio =
        state.condominios.where((c) => c.id == widget.condominioId).firstOrNull;

    if (condominio == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Condominio')),
        body: const Center(child: Text('Condominio no encontrado')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(condominio.nombre),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              await context.push('/home/condominios/${condominio.id}/editar');
              ref.read(condominioSaProvider.notifier).cargarCondominios();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info del condominio
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(condominio.nombre,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                      ),
                      Chip(
                        label: Text(
                          condominio.activo ? 'ACTIVO' : 'INACTIVO',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11),
                        ),
                        backgroundColor:
                            condominio.activo ? Colors.green : Colors.grey,
                      ),
                    ],
                  ),
                  if (condominio.direccion != null) ...[
                    const SizedBox(height: 8),
                    Text(condominio.direccion!,
                        style: const TextStyle(color: Colors.grey)),
                  ],
                  const SizedBox(height: 8),
                  Text(
                      '${condominio.numUnidades} unidades habitacionales',
                      style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _InfoChip(
                          '${condominio.totalUsuarios} usuarios', Colors.blue),
                      const SizedBox(width: 8),
                      _InfoChip(
                          '${condominio.totalAdmins} admins', Colors.indigo),
                    ],
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: state.isLoading
                        ? null
                        : () => ref
                            .read(condominioSaProvider.notifier)
                            .toggleActivo(condominio.id),
                    icon: Icon(condominio.activo
                        ? Icons.block
                        : Icons.check_circle_outline),
                    label: Text(
                        condominio.activo ? 'Desactivar' : 'Activar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          condominio.activo ? Colors.red : Colors.green,
                      side: BorderSide(
                          color: condominio.activo ? Colors.red : Colors.green),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Admins
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Administradores',
                  style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              TextButton.icon(
                onPressed: _mostrarFormularioAdmin,
                icon: const Icon(Icons.add),
                label: const Text('Agregar Admin'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_loadingAdmins)
            const Center(child: CircularProgressIndicator())
          else if (_admins.isEmpty)
            const Text('Sin administradores asignados.',
                style: TextStyle(color: Colors.grey))
          else
            ..._admins.map((admin) => ListTile(
                  leading: CircleAvatar(
                    child: Text(admin.nombreCompleto[0].toUpperCase()),
                  ),
                  title: Text(admin.nombreCompleto),
                  subtitle: Text(admin.username),
                  trailing: Chip(
                    label: Text(
                      admin.activo ? 'ACTIVO' : 'INACTIVO',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 10),
                    ),
                    backgroundColor:
                        admin.activo ? Colors.green : Colors.grey,
                  ),
                )),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final Color color;

  const _InfoChip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label,
          style: TextStyle(color: color, fontSize: 12)),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color.withOpacity(0.3)),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/superadmin/screens/detalle_condominio_screen.dart
git commit -m "feat(superadmin): add DetalleCondominioScreen with admin list and toggle activo"
```

---

## Task 8: Navegación — MainScaffold + GoRouter

**Files:**
- Modify: `lib/shared/widgets/main_scaffold.dart`
- Modify: `lib/core/routes/app_router.dart`

- [ ] **Step 1: Separar Rol.superadmin en MainScaffold**

En `main_scaffold.dart`:

1. En `_loadInitialData()` — eliminar `case Rol.superadmin` del bloque compartido con admin y agregar su propio caso:

```dart
case Rol.superadmin:
  ref.read(condominioSaProvider.notifier).cargarCondominios();
```

2. En `_buildScreens()` — separar `Rol.superadmin` de `Rol.admin`:

Cambiar:
```dart
Rol.admin || Rol.superadmin => [ /* screens admin */ ]
```
Por dos casos separados:
```dart
Rol.admin => [ /* screens admin existentes */ ],
Rol.superadmin => [
  const SuperadminDashboardScreen(),
  const PerfilScreen(),
],
```

3. En `_buildItems()` — separar igual:

```dart
Rol.admin => const [ /* items admin existentes */ ],
Rol.superadmin => const [
  BottomNavigationBarItem(
      icon: Icon(Icons.apartment), label: 'Condominios'),
  BottomNavigationBarItem(
      icon: Icon(Icons.person_outline), label: 'Perfil'),
],
```

4. Agregar los imports necesarios al inicio del archivo:

```dart
import '../../features/superadmin/providers/condominio_sa_provider.dart';
import '../../features/superadmin/screens/superadmin_dashboard_screen.dart';
```

- [ ] **Step 2: Agregar rutas a app_router.dart**

Agregar imports:
```dart
import '../../features/superadmin/screens/crear_editar_condominio_screen.dart';
import '../../features/superadmin/screens/detalle_condominio_screen.dart';
```

Agregar dentro de las rutas de `/home`:

```dart
GoRoute(
  path: 'condominios/nuevo',
  builder: (_, __) => const CrearEditarCondominioScreen(),
),
GoRoute(
  path: 'condominios/:id/editar',
  builder: (context, state) {
    final id = int.parse(state.pathParameters['id']!);
    final condominio = ref
        .read(condominioSaProvider)
        .condominios
        .where((c) => c.id == id)
        .firstOrNull;
    return CrearEditarCondominioScreen(condominio: condominio);
  },
),
GoRoute(
  path: 'condominios/:id/detalle',
  builder: (context, state) {
    final id = int.parse(state.pathParameters['id']!);
    return DetalleCondominioScreen(condominioId: id);
  },
),
```

- [ ] **Step 3: Commit**

```bash
git add lib/shared/widgets/main_scaffold.dart \
        lib/core/routes/app_router.dart
git commit -m "feat(superadmin): wire navigation — separate Rol.superadmin from Rol.admin in MainScaffold, add GoRouter routes"
```

---

## Task 9: Fix DetalleCondominioScreen — import de CreateUsuarioRequest

**Context:** El `_mostrarFormularioAdmin` en `DetalleCondominioScreen` usa `CreateUsuarioRequest`. Hay que verificar el import exacto y el modelo.

- [ ] **Step 1: Leer `lib/features/usuarios/models/create_usuario_request.dart`** y verificar el constructor. Si los campos son distintos, ajustar la llamada en `_mostrarFormularioAdmin` para que coincida con los campos reales.

- [ ] **Step 2: Simplificar si hay conflicto de imports**

Si el import es complejo, reemplazar el dialog inline por una navegación a `CrearUsuarioScreen` pasando el `condominioId` como extra. Alternativa: llamar directo al `UsuarioAdminService.crearUsuario()` usando los campos del dialog.

- [ ] **Step 3: Compile check**

Verificar que `flutter analyze` no muestra errores en la pantalla de detalle.

---

## Self-Review

### Spec Coverage

| Requisito | Task |
|---|---|
| `GET /api/condominios` — SUPERADMIN | Task 2 |
| `POST /api/condominios` | Task 2 |
| `PUT /api/condominios/{id}` | Task 2 |
| `PUT /api/condominios/{id}/toggle` | Task 2 |
| `GET /api/condominios/{id}/admins` | Task 2 |
| Backend compila | Task 2 |
| `toResponse` público en UsuarioService | Task 2 |
| Flutter models CondominiSa + CreateCondominioRequest + .g.dart | Task 3 |
| ApiConstants: 4 constantes | Task 4 |
| CondominioSaService Flutter | Task 4 |
| CondominioSaProvider con cargar, crear, editar, toggleActivo | Task 4 |
| SuperadminDashboardScreen: stats cards + lista condominios + FAB | Task 5 |
| CrearEditarCondominioScreen: nombre, dirección, unidades, activo | Task 6 |
| DetalleCondominioScreen: info + toggle + lista admins + agregar admin | Task 7 |
| SUPERADMIN separado de ADMIN en MainScaffold | Task 8 |
| Rutas: /condominios/nuevo, /:id/editar, /:id/detalle | Task 8 |
| Fix import CreateUsuarioRequest en detalle | Task 9 |
