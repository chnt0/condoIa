# Notificaciones — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implementar avisos in-app: ADMIN publica notificaciones segmentadas (todos o por edificio), todos los roles las leen en lista + pantalla de detalle con opción de eliminar para ADMIN.

**Architecture:** Backend primero (V6 migration → enum → entity → repo → DTOs → service con filtrado por segmento → controller), luego Flutter (models + .g.dart manuales → service → provider → 3 screens → navegación). El filtrado de EDIFICIO_X se hace en el service Java con streams, sin JPQL complejo.

**Tech Stack:** Spring Boot 3 + JPA + Flyway + PostgreSQL | Flutter + Riverpod StateNotifier + GoRouter + json_annotation (sin build_runner)

---

## File Map

### Backend — nuevos archivos

```
backend/src/main/resources/db/migration/
  V6__create_notificaciones_table.sql

backend/src/main/java/com/condos/notificacion/
  model/
    SegmentoNotificacion.java
    Notificacion.java
  repository/
    NotificacionRepository.java
  dto/
    CreateNotificacionRequest.java
    NotificacionResponse.java
  service/
    NotificacionService.java
  controller/
    NotificacionController.java
```

### Flutter — nuevos archivos

```
lib/features/notificaciones/
  models/
    notificacion.dart + .g.dart
    create_notificacion_request.dart + .g.dart
  services/
    notificacion_service.dart
  providers/
    notificacion_provider.dart
  screens/
    notificaciones_screen.dart
    crear_notificacion_screen.dart
    detalle_notificacion_screen.dart
```

### Flutter — archivos modificados

```
lib/core/constants/api_constants.dart    ← 2 nuevas constantes
lib/core/routes/app_router.dart          ← 2 nuevas rutas
lib/shared/widgets/main_scaffold.dart    ← tab Avisos para todos los roles
```

---

## Task 1: DB Migration V6

**Files:**
- Create: `backend/src/main/resources/db/migration/V6__create_notificaciones_table.sql`

- [ ] **Step 1: Escribir la migración**

```sql
-- V6__create_notificaciones_table.sql

CREATE TYPE segmento_notificacion AS ENUM ('TODOS', 'EDIFICIO_X');

CREATE TABLE notificaciones (
    id                BIGSERIAL PRIMARY KEY,
    condominio_id     BIGINT NOT NULL REFERENCES condominios(id),
    admin_creador_id  BIGINT NOT NULL REFERENCES usuarios(id),
    titulo            VARCHAR(200) NOT NULL,
    mensaje           TEXT NOT NULL,
    segmento          segmento_notificacion NOT NULL,
    edificio          VARCHAR(50),
    created_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_notificaciones_condominio ON notificaciones(condominio_id);
CREATE INDEX idx_notificaciones_created ON notificaciones(created_at DESC);
```

- [ ] **Step 2: Commit**

```bash
git add backend/src/main/resources/db/migration/V6__create_notificaciones_table.sql
git commit -m "feat(notificaciones): add V6 migration — notificaciones table"
```

---

## Task 2: Java Enum + Entity

**Files:**
- Create: `backend/src/main/java/com/condos/notificacion/model/SegmentoNotificacion.java`
- Create: `backend/src/main/java/com/condos/notificacion/model/Notificacion.java`

- [ ] **Step 1: SegmentoNotificacion.java**

```java
package com.condos.notificacion.model;

public enum SegmentoNotificacion {
    TODOS,
    EDIFICIO_X
}
```

- [ ] **Step 2: Notificacion.java**

```java
package com.condos.notificacion.model;

import com.condos.condominio.model.Condominio;
import com.condos.usuario.model.Usuario;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;
import lombok.ToString;

import java.time.LocalDateTime;

@Entity
@Table(name = "notificaciones")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@ToString(exclude = {"condominio", "adminCreador"})
@EqualsAndHashCode(exclude = {"condominio", "adminCreador"})
public class Notificacion {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "condominio_id", nullable = false)
    private Condominio condominio;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "admin_creador_id", nullable = false)
    private Usuario adminCreador;

    @Column(nullable = false, length = 200)
    private String titulo;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String mensaje;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private SegmentoNotificacion segmento;

    @Column(length = 50)
    private String edificio;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
}
```

- [ ] **Step 3: Commit**

```bash
git add backend/src/main/java/com/condos/notificacion/
git commit -m "feat(notificaciones): add SegmentoNotificacion enum and Notificacion entity"
```

---

## Task 3: Repository + DTOs

**Files:**
- Create: `backend/src/main/java/com/condos/notificacion/repository/NotificacionRepository.java`
- Create: `backend/src/main/java/com/condos/notificacion/dto/CreateNotificacionRequest.java`
- Create: `backend/src/main/java/com/condos/notificacion/dto/NotificacionResponse.java`

- [ ] **Step 1: NotificacionRepository.java**

```java
package com.condos.notificacion.repository;

import com.condos.notificacion.model.Notificacion;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface NotificacionRepository extends JpaRepository<Notificacion, Long> {
    List<Notificacion> findByCondominioIdOrderByCreatedAtDesc(Long condominioId);
}
```

- [ ] **Step 2: CreateNotificacionRequest.java**

```java
package com.condos.notificacion.dto;

import com.condos.notificacion.model.SegmentoNotificacion;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class CreateNotificacionRequest {

    @NotBlank
    private String titulo;

    @NotBlank
    private String mensaje;

    @NotNull
    private SegmentoNotificacion segmento;

    private String edificio;
}
```

- [ ] **Step 3: NotificacionResponse.java**

```java
package com.condos.notificacion.dto;

import com.condos.notificacion.model.SegmentoNotificacion;
import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Builder
public class NotificacionResponse {
    private Long id;
    private String titulo;
    private String mensaje;
    private SegmentoNotificacion segmento;
    private String edificio;
    private Long adminCreadorId;
    private String adminCreadorNombre;
    private LocalDateTime createdAt;
}
```

- [ ] **Step 4: Commit**

```bash
git add backend/src/main/java/com/condos/notificacion/repository/ \
        backend/src/main/java/com/condos/notificacion/dto/
git commit -m "feat(notificaciones): add NotificacionRepository and DTOs"
```

---

## Task 4: NotificacionService + Controller + compilación

**Files:**
- Create: `backend/src/main/java/com/condos/notificacion/service/NotificacionService.java`
- Create: `backend/src/main/java/com/condos/notificacion/controller/NotificacionController.java`

- [ ] **Step 1: NotificacionService.java**

```java
package com.condos.notificacion.service;

import com.condos.common.exceptions.ResourceNotFoundException;
import com.condos.common.utils.TenantContext;
import com.condos.condominio.model.Condominio;
import com.condos.condominio.repository.CondominioRepository;
import com.condos.notificacion.dto.CreateNotificacionRequest;
import com.condos.notificacion.dto.NotificacionResponse;
import com.condos.notificacion.model.Notificacion;
import com.condos.notificacion.model.SegmentoNotificacion;
import com.condos.notificacion.repository.NotificacionRepository;
import com.condos.usuario.model.Rol;
import com.condos.usuario.model.Usuario;
import com.condos.usuario.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class NotificacionService {

    private final NotificacionRepository notificacionRepository;
    private final UsuarioRepository usuarioRepository;
    private final CondominioRepository condominioRepository;

    @Transactional
    public NotificacionResponse crearNotificacion(CreateNotificacionRequest request, Long adminId) {
        Long condominioId = TenantContext.getCondominioId();
        Condominio condominio = condominioRepository.findById(condominioId)
                .orElseThrow(() -> new ResourceNotFoundException("Condominio no encontrado"));
        Usuario admin = usuarioRepository.findById(adminId)
                .orElseThrow(() -> new ResourceNotFoundException("Admin no encontrado"));

        if (request.getSegmento() == SegmentoNotificacion.EDIFICIO_X &&
                (request.getEdificio() == null || request.getEdificio().isBlank())) {
            throw new IllegalArgumentException("El campo 'edificio' es requerido para el segmento EDIFICIO_X");
        }

        Notificacion notificacion = Notificacion.builder()
                .condominio(condominio)
                .adminCreador(admin)
                .titulo(request.getTitulo())
                .mensaje(request.getMensaje())
                .segmento(request.getSegmento())
                .edificio(request.getEdificio())
                .build();

        notificacion = notificacionRepository.save(notificacion);
        log.info("Notificación creada: id={}, segmento={}", notificacion.getId(), notificacion.getSegmento());
        return toResponse(notificacion);
    }

    @Transactional(readOnly = true)
    public List<NotificacionResponse> listarNotificaciones(Long usuarioId) {
        Long condominioId = TenantContext.getCondominioId();
        List<Notificacion> todas = notificacionRepository.findByCondominioIdOrderByCreatedAtDesc(condominioId);

        Usuario usuario = usuarioRepository.findById(usuarioId)
                .orElseThrow(() -> new ResourceNotFoundException("Usuario no encontrado"));

        if (usuario.getRol() != Rol.USUARIO) {
            return todas.stream().map(this::toResponse).collect(Collectors.toList());
        }

        String unidad = usuario.getUnidadHabitacional();
        return todas.stream()
                .filter(n -> {
                    if (n.getSegmento() == SegmentoNotificacion.TODOS) return true;
                    if (unidad == null || n.getEdificio() == null) return false;
                    return unidad.toLowerCase().startsWith(n.getEdificio().toLowerCase());
                })
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    @Transactional
    public void eliminarNotificacion(Long id) {
        Notificacion notificacion = notificacionRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Notificación no encontrada"));
        notificacionRepository.delete(notificacion);
        log.info("Notificación eliminada: id={}", id);
    }

    private NotificacionResponse toResponse(Notificacion n) {
        return NotificacionResponse.builder()
                .id(n.getId())
                .titulo(n.getTitulo())
                .mensaje(n.getMensaje())
                .segmento(n.getSegmento())
                .edificio(n.getEdificio())
                .adminCreadorId(n.getAdminCreador().getId())
                .adminCreadorNombre(n.getAdminCreador().getNombreCompleto())
                .createdAt(n.getCreatedAt())
                .build();
    }
}
```

- [ ] **Step 2: NotificacionController.java**

```java
package com.condos.notificacion.controller;

import com.condos.notificacion.dto.CreateNotificacionRequest;
import com.condos.notificacion.dto.NotificacionResponse;
import com.condos.notificacion.service.NotificacionService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/notificaciones")
@RequiredArgsConstructor
public class NotificacionController {

    private final NotificacionService notificacionService;

    @GetMapping
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<List<NotificacionResponse>> listarNotificaciones(Authentication authentication) {
        Long usuarioId = Long.parseLong(authentication.getName());
        return ResponseEntity.ok(notificacionService.listarNotificaciones(usuarioId));
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPERADMIN')")
    public ResponseEntity<NotificacionResponse> crearNotificacion(
            @Valid @RequestBody CreateNotificacionRequest request,
            Authentication authentication) {
        Long adminId = Long.parseLong(authentication.getName());
        return ResponseEntity.ok(notificacionService.crearNotificacion(request, adminId));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPERADMIN')")
    public ResponseEntity<Void> eliminarNotificacion(@PathVariable Long id) {
        notificacionService.eliminarNotificacion(id);
        return ResponseEntity.noContent().build();
    }
}
```

- [ ] **Step 3: Verificar compilación**

```bash
cd backend && ./mvnw compile -q
```

Expected: sin output (BUILD SUCCESS).

- [ ] **Step 4: Commit**

```bash
git add backend/src/main/java/com/condos/notificacion/service/ \
        backend/src/main/java/com/condos/notificacion/controller/
git commit -m "feat(notificaciones): add NotificacionService and NotificacionController — 3 endpoints"
```

---

## Task 5: Flutter Models + .g.dart

**Files:**
- Create: `lib/features/notificaciones/models/notificacion.dart`
- Create: `lib/features/notificaciones/models/notificacion.g.dart`
- Create: `lib/features/notificaciones/models/create_notificacion_request.dart`
- Create: `lib/features/notificaciones/models/create_notificacion_request.g.dart`

- [ ] **Step 1: notificacion.dart**

```dart
import 'package:json_annotation/json_annotation.dart';

part 'notificacion.g.dart';

enum SegmentoNotificacion {
  @JsonValue('TODOS')
  todos,

  @JsonValue('EDIFICIO_X')
  edificioX,
}

@JsonSerializable()
class Notificacion {
  final int id;
  final String titulo;
  final String mensaje;
  final SegmentoNotificacion segmento;
  final String? edificio;
  final int adminCreadorId;
  final String adminCreadorNombre;
  final DateTime createdAt;

  Notificacion({
    required this.id,
    required this.titulo,
    required this.mensaje,
    required this.segmento,
    this.edificio,
    required this.adminCreadorId,
    required this.adminCreadorNombre,
    required this.createdAt,
  });

  factory Notificacion.fromJson(Map<String, dynamic> json) =>
      _$NotificacionFromJson(json);
  Map<String, dynamic> toJson() => _$NotificacionToJson(this);
}
```

- [ ] **Step 2: notificacion.g.dart**

```dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notificacion.dart';

Notificacion _$NotificacionFromJson(Map<String, dynamic> json) => Notificacion(
      id: (json['id'] as num).toInt(),
      titulo: json['titulo'] as String,
      mensaje: json['mensaje'] as String,
      segmento: $enumDecode(_$SegmentoNotificacionEnumMap, json['segmento']),
      edificio: json['edificio'] as String?,
      adminCreadorId: (json['adminCreadorId'] as num).toInt(),
      adminCreadorNombre: json['adminCreadorNombre'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$NotificacionToJson(Notificacion instance) =>
    <String, dynamic>{
      'id': instance.id,
      'titulo': instance.titulo,
      'mensaje': instance.mensaje,
      'segmento': _$SegmentoNotificacionEnumMap[instance.segmento]!,
      'edificio': instance.edificio,
      'adminCreadorId': instance.adminCreadorId,
      'adminCreadorNombre': instance.adminCreadorNombre,
      'createdAt': instance.createdAt.toIso8601String(),
    };

const _$SegmentoNotificacionEnumMap = {
  SegmentoNotificacion.todos: 'TODOS',
  SegmentoNotificacion.edificioX: 'EDIFICIO_X',
};
```

- [ ] **Step 3: create_notificacion_request.dart**

```dart
import 'package:json_annotation/json_annotation.dart';
import 'notificacion.dart';

part 'create_notificacion_request.g.dart';

@JsonSerializable()
class CreateNotificacionRequest {
  final String titulo;
  final String mensaje;
  final SegmentoNotificacion segmento;
  final String? edificio;

  CreateNotificacionRequest({
    required this.titulo,
    required this.mensaje,
    required this.segmento,
    this.edificio,
  });

  factory CreateNotificacionRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateNotificacionRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateNotificacionRequestToJson(this);
}
```

- [ ] **Step 4: create_notificacion_request.g.dart**

```dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_notificacion_request.dart';

CreateNotificacionRequest _$CreateNotificacionRequestFromJson(
        Map<String, dynamic> json) =>
    CreateNotificacionRequest(
      titulo: json['titulo'] as String,
      mensaje: json['mensaje'] as String,
      segmento: $enumDecode(_$SegmentoNotificacionEnumMap, json['segmento']),
      edificio: json['edificio'] as String?,
    );

Map<String, dynamic> _$CreateNotificacionRequestToJson(
        CreateNotificacionRequest instance) =>
    <String, dynamic>{
      'titulo': instance.titulo,
      'mensaje': instance.mensaje,
      'segmento': _$SegmentoNotificacionEnumMap[instance.segmento]!,
      'edificio': instance.edificio,
    };

const _$SegmentoNotificacionEnumMap = {
  SegmentoNotificacion.todos: 'TODOS',
  SegmentoNotificacion.edificioX: 'EDIFICIO_X',
};
```

- [ ] **Step 5: Commit**

```bash
git add lib/features/notificaciones/models/
git commit -m "feat(notificaciones): add Flutter models Notificacion and CreateNotificacionRequest with manual .g.dart"
```

---

## Task 6: ApiConstants + NotificacionService Flutter

**Files:**
- Modify: `lib/core/constants/api_constants.dart`
- Create: `lib/features/notificaciones/services/notificacion_service.dart`

- [ ] **Step 1: Agregar constantes a api_constants.dart**

Insertar antes de `// Incidentes`:

```dart
  // Notificaciones
  static const String notificaciones = '$apiPrefix/notificaciones';
  static String notificacionById(int id) => '$apiPrefix/notificaciones/$id';
```

- [ ] **Step 2: notificacion_service.dart**

```dart
import '../../../core/constants/api_constants.dart';
import '../../../shared/services/api_client.dart';
import '../models/create_notificacion_request.dart';
import '../models/notificacion.dart';

class NotificacionService {
  final ApiClient apiClient;

  NotificacionService({required this.apiClient});

  Future<List<Notificacion>> listarNotificaciones() async {
    final response = await apiClient.getList(ApiConstants.notificaciones);
    return response
        .map((item) => Notificacion.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Notificacion> crearNotificacion(CreateNotificacionRequest request) async {
    final response =
        await apiClient.post(ApiConstants.notificaciones, request.toJson());
    return Notificacion.fromJson(response);
  }

  Future<void> eliminarNotificacion(int id) async {
    await apiClient.delete(ApiConstants.notificacionById(id));
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/core/constants/api_constants.dart \
        lib/features/notificaciones/services/notificacion_service.dart
git commit -m "feat(notificaciones): add ApiConstants and NotificacionService Flutter"
```

---

## Task 7: NotificacionProvider

**Files:**
- Create: `lib/features/notificaciones/providers/notificacion_provider.dart`

- [ ] **Step 1: notificacion_provider.dart**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/auth_provider.dart';
import '../models/create_notificacion_request.dart';
import '../models/notificacion.dart';
import '../services/notificacion_service.dart';

class NotificacionState {
  final List<Notificacion> notificaciones;
  final bool isLoading;
  final String? error;

  NotificacionState({
    this.notificaciones = const [],
    this.isLoading = false,
    this.error,
  });

  NotificacionState copyWith({
    List<Notificacion>? notificaciones,
    bool? isLoading,
    String? error,
  }) {
    return NotificacionState(
      notificaciones: notificaciones ?? this.notificaciones,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class NotificacionNotifier extends StateNotifier<NotificacionState> {
  final NotificacionService _service;

  NotificacionNotifier(this._service) : super(NotificacionState());

  Future<void> cargarNotificaciones() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final notificaciones = await _service.listarNotificaciones();
      state = state.copyWith(notificaciones: notificaciones, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<Notificacion?> crearNotificacion(CreateNotificacionRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final notificacion = await _service.crearNotificacion(request);
      state = state.copyWith(
        notificaciones: [notificacion, ...state.notificaciones],
        isLoading: false,
      );
      return notificacion;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<void> eliminarNotificacion(int id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.eliminarNotificacion(id);
      state = state.copyWith(
        notificaciones:
            state.notificaciones.where((n) => n.id != id).toList(),
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

final notificacionServiceProvider = Provider<NotificacionService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NotificacionService(apiClient: apiClient);
});

final notificacionProvider =
    StateNotifierProvider<NotificacionNotifier, NotificacionState>((ref) {
  final service = ref.watch(notificacionServiceProvider);
  return NotificacionNotifier(service);
});
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/notificaciones/providers/notificacion_provider.dart
git commit -m "feat(notificaciones): add NotificacionNotifier and notificacionProvider"
```

---

## Task 8: NotificacionesScreen

**Files:**
- Create: `lib/features/notificaciones/screens/notificaciones_screen.dart`

- [ ] **Step 1: notificaciones_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/models/usuario.dart';
import '../../../shared/providers/auth_provider.dart';
import '../models/notificacion.dart';
import '../providers/notificacion_provider.dart';

class NotificacionesScreen extends ConsumerStatefulWidget {
  const NotificacionesScreen({super.key});

  @override
  ConsumerState<NotificacionesScreen> createState() =>
      _NotificacionesScreenState();
}

class _NotificacionesScreenState extends ConsumerState<NotificacionesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificacionProvider.notifier).cargarNotificaciones();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final state = ref.watch(notificacionProvider);
    final esAdmin =
        user?.rol == Rol.admin || user?.rol == Rol.superadmin;

    return Scaffold(
      appBar: AppBar(title: const Text('Avisos')),
      floatingActionButton: esAdmin
          ? FloatingActionButton(
              onPressed: () async {
                await context.push('/home/notificaciones/nueva');
                ref.read(notificacionProvider.notifier).cargarNotificaciones();
              },
              child: const Icon(Icons.add),
            )
          : null,
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(state.error!,
                          style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref
                            .read(notificacionProvider.notifier)
                            .cargarNotificaciones(),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : state.notificaciones.isEmpty
                  ? const Center(child: Text('No hay avisos publicados.'))
                  : RefreshIndicator(
                      onRefresh: () => ref
                          .read(notificacionProvider.notifier)
                          .cargarNotificaciones(),
                      child: ListView.builder(
                        itemCount: state.notificaciones.length,
                        itemBuilder: (context, index) {
                          final n = state.notificaciones[index];
                          return _NotificacionTile(n: n);
                        },
                      ),
                    ),
    );
  }
}

class _NotificacionTile extends StatelessWidget {
  final Notificacion n;

  const _NotificacionTile({required this.n});

  String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  @override
  Widget build(BuildContext context) {
    final esEdificio = n.segmento == SegmentoNotificacion.edificioX;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: const Icon(Icons.notifications_outlined, size: 32),
        title: Text(n.titulo,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_fmt(n.createdAt),
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        trailing: Chip(
          label: Text(
            esEdificio ? n.edificio ?? 'Edificio' : 'Todos',
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
          backgroundColor: esEdificio ? Colors.orange : Colors.blue,
        ),
        onTap: () => context.push('/home/notificaciones/${n.id}'),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/notificaciones/screens/notificaciones_screen.dart
git commit -m "feat(notificaciones): add NotificacionesScreen with list and FAB for ADMIN"
```

---

## Task 9: CrearNotificacionScreen

**Files:**
- Create: `lib/features/notificaciones/screens/crear_notificacion_screen.dart`

- [ ] **Step 1: crear_notificacion_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/create_notificacion_request.dart';
import '../models/notificacion.dart';
import '../providers/notificacion_provider.dart';

class CrearNotificacionScreen extends ConsumerStatefulWidget {
  const CrearNotificacionScreen({super.key});

  @override
  ConsumerState<CrearNotificacionScreen> createState() =>
      _CrearNotificacionScreenState();
}

class _CrearNotificacionScreenState
    extends ConsumerState<CrearNotificacionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _mensajeCtrl = TextEditingController();
  final _edificioCtrl = TextEditingController();
  SegmentoNotificacion _segmento = SegmentoNotificacion.todos;

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _mensajeCtrl.dispose();
    _edificioCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final request = CreateNotificacionRequest(
      titulo: _tituloCtrl.text.trim(),
      mensaje: _mensajeCtrl.text.trim(),
      segmento: _segmento,
      edificio: _segmento == SegmentoNotificacion.edificioX
          ? _edificioCtrl.text.trim()
          : null,
    );

    final notificacion = await ref
        .read(notificacionProvider.notifier)
        .crearNotificacion(request);

    if (mounted) {
      if (notificacion != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aviso publicado exitosamente')),
        );
        context.pop();
      } else {
        final error = ref.read(notificacionProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(error ?? 'Error al publicar aviso'),
              backgroundColor: Colors.red),
        );
        ref.read(notificacionProvider.notifier).clearError();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificacionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo Aviso')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _tituloCtrl,
                decoration: const InputDecoration(
                  labelText: 'Título *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _mensajeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Mensaje *',
                  border: OutlineInputBorder(),
                ),
                maxLines: 6,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<SegmentoNotificacion>(
                value: _segmento,
                decoration: const InputDecoration(
                  labelText: 'Destinatarios',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: SegmentoNotificacion.todos,
                    child: Text('Todos los residentes'),
                  ),
                  DropdownMenuItem(
                    value: SegmentoNotificacion.edificioX,
                    child: Text('Por edificio'),
                  ),
                ],
                onChanged: (v) => setState(() => _segmento = v!),
              ),
              if (_segmento == SegmentoNotificacion.edificioX) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _edificioCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Edificio *',
                    hintText: 'Ej: Torre A',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (_segmento != SegmentoNotificacion.edificioX) return null;
                    return v == null || v.trim().isEmpty ? 'Campo requerido' : null;
                  },
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: state.isLoading ? null : _submit,
                child: state.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Publicar Aviso'),
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
git add lib/features/notificaciones/screens/crear_notificacion_screen.dart
git commit -m "feat(notificaciones): add CrearNotificacionScreen with segmento selector"
```

---

## Task 10: DetalleNotificacionScreen

**Files:**
- Create: `lib/features/notificaciones/screens/detalle_notificacion_screen.dart`

- [ ] **Step 1: detalle_notificacion_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/usuario.dart';
import '../../../shared/providers/auth_provider.dart';
import '../models/notificacion.dart';
import '../providers/notificacion_provider.dart';

class DetalleNotificacionScreen extends ConsumerWidget {
  final int notificacionId;

  const DetalleNotificacionScreen({super.key, required this.notificacionId});

  String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final state = ref.watch(notificacionProvider);
    final notificacion = state.notificaciones
        .where((n) => n.id == notificacionId)
        .firstOrNull;

    if (notificacion == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Aviso')),
        body: const Center(child: Text('Aviso no encontrado')),
      );
    }

    final esAdmin =
        user?.rol == Rol.admin || user?.rol == Rol.superadmin;
    final esEdificio = notificacion.segmento == SegmentoNotificacion.edificioX;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Aviso'),
        actions: [
          if (esAdmin)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: state.isLoading
                  ? null
                  : () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Eliminar aviso'),
                          content: const Text(
                              '¿Estás seguro de que quieres eliminar este aviso?'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancelar')),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red),
                              child: const Text('Eliminar'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true && context.mounted) {
                        await ref
                            .read(notificacionProvider.notifier)
                            .eliminarNotificacion(notificacionId);
                        if (context.mounted) Navigator.pop(context);
                      }
                    },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notificacion.titulo,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    )),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(
                  label: Text(
                    esEdificio
                        ? notificacion.edificio ?? 'Edificio'
                        : 'Todos',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 11),
                  ),
                  backgroundColor:
                      esEdificio ? Colors.orange : Colors.blue,
                ),
                const SizedBox(width: 8),
                Text(_fmt(notificacion.createdAt),
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 4),
            Text('Publicado por: ${notificacion.adminCreadorNombre}',
                style:
                    const TextStyle(fontSize: 12, color: Colors.grey)),
            const Divider(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Text(notificacion.mensaje,
                    style: Theme.of(context).textTheme.bodyLarge),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/notificaciones/screens/detalle_notificacion_screen.dart
git commit -m "feat(notificaciones): add DetalleNotificacionScreen with delete for ADMIN"
```

---

## Task 11: Navegación — MainScaffold + GoRouter

**Files:**
- Modify: `lib/shared/widgets/main_scaffold.dart`
- Modify: `lib/core/routes/app_router.dart`

- [ ] **Step 1: Actualizar main_scaffold.dart**

Tabs finales:
- USUARIO (8): Inicio, Mis Visitas, Nueva, Paquetes, Incidentes, Cuotas, Avisos, Perfil
- GUARDIA (6): Escanear, Paquetes, Hoy, Historial, Avisos, Perfil
- ADMIN (8): Dashboard, Visitas, Paquetes, Incidentes, Gestión, Cuotas, Avisos, Perfil

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/incidentes/providers/incidente_provider.dart';
import '../../features/incidentes/screens/incidentes_screen.dart';
import '../../features/notificaciones/providers/notificacion_provider.dart';
import '../../features/notificaciones/screens/notificaciones_screen.dart';
import '../../features/pagos/providers/cuota_provider.dart';
import '../../features/pagos/screens/cuotas_admin_screen.dart';
import '../../features/pagos/screens/mis_cuotas_screen.dart';
import '../../features/paquetes/providers/paquete_provider.dart';
import '../../features/paquetes/screens/paquetes_screen.dart';
import '../../features/usuarios/screens/gestion_screen.dart';
import '../../features/perfil/screens/perfil_screen.dart';
import '../../features/visitas/providers/visita_provider.dart';
import '../../features/visitas/screens/crear_visita_screen.dart';
import '../../features/visitas/screens/dashboard_admin_screen.dart';
import '../../features/visitas/screens/escanear_qr_screen.dart';
import '../../features/visitas/screens/inicio_usuario_screen.dart';
import '../../features/visitas/screens/mis_visitas_screen.dart';
import '../../features/visitas/screens/visitas_admin_screen.dart';
import '../models/usuario.dart';
import '../providers/auth_provider.dart';

class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialData());
  }

  void _loadInitialData() {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    final visitaNotifier = ref.read(visitaProvider.notifier);
    final cuotaNotifier = ref.read(cuotaProvider.notifier);
    final paqueteNotifier = ref.read(paqueteProvider.notifier);
    final incidenteNotifier = ref.read(incidenteProvider.notifier);
    final notificacionNotifier = ref.read(notificacionProvider.notifier);
    switch (user.rol) {
      case Rol.usuario:
        visitaNotifier.cargarMisVisitas();
        cuotaNotifier.cargarMisCuotas();
        paqueteNotifier.cargarMisPaquetes();
        incidenteNotifier.cargarMisIncidentes();
        notificacionNotifier.cargarNotificaciones();
      case Rol.guardia:
        visitaNotifier.cargarTodasVisitas();
        paqueteNotifier.cargarPaquetes();
        notificacionNotifier.cargarNotificaciones();
      case Rol.admin:
      case Rol.superadmin:
        visitaNotifier.cargarTodasVisitas();
        cuotaNotifier.cargarCuotas();
        paqueteNotifier.cargarPaquetes();
        incidenteNotifier.cargarIncidentes();
        notificacionNotifier.cargarNotificaciones();
    }
  }

  List<Widget> _buildScreens(Rol rol) {
    return switch (rol) {
      Rol.usuario => [
          const InicioUsuarioScreen(),
          const MisVisitasScreen(),
          const CrearVisitaScreen(),
          const PaquetesScreen(),
          const IncidentesScreen(),
          const MisCuotasScreen(),
          const NotificacionesScreen(),
          const PerfilScreen(),
        ],
      Rol.guardia => [
          const EscanearQrScreen(),
          const PaquetesScreen(),
          const VisitasAdminScreen(filterToday: true),
          const VisitasAdminScreen(filterToday: false),
          const NotificacionesScreen(),
          const PerfilScreen(),
        ],
      Rol.admin || Rol.superadmin => [
          const DashboardAdminScreen(),
          const VisitasAdminScreen(filterToday: false),
          const PaquetesScreen(),
          const IncidentesScreen(),
          const GestionScreen(),
          const CuotasAdminScreen(),
          const NotificacionesScreen(),
          const PerfilScreen(),
        ],
    };
  }

  List<BottomNavigationBarItem> _buildItems(Rol rol) {
    return switch (rol) {
      Rol.usuario => const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Visitas'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Nueva'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), label: 'Paquetes'),
          BottomNavigationBarItem(icon: Icon(Icons.report_outlined), label: 'Incidentes'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Cuotas'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), label: 'Avisos'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Perfil'),
        ],
      Rol.guardia => const [
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: 'Escanear'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), label: 'Paquetes'),
          BottomNavigationBarItem(icon: Icon(Icons.today), label: 'Hoy'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Historial'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), label: 'Avisos'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Perfil'),
        ],
      Rol.admin || Rol.superadmin => const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Visitas'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), label: 'Paquetes'),
          BottomNavigationBarItem(icon: Icon(Icons.report_outlined), label: 'Incidentes'),
          BottomNavigationBarItem(icon: Icon(Icons.manage_accounts), label: 'Gestión'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Cuotas'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), label: 'Avisos'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Perfil'),
        ],
    };
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    if (user == null) return const SizedBox.shrink();

    final screens = _buildScreens(user.rol);
    final items = _buildItems(user.rol);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: items,
      ),
    );
  }
}
```

- [ ] **Step 2: Actualizar app_router.dart**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/incidentes/screens/crear_incidente_screen.dart';
import '../../features/incidentes/screens/detalle_incidente_screen.dart';
import '../../features/notificaciones/screens/crear_notificacion_screen.dart';
import '../../features/notificaciones/screens/detalle_notificacion_screen.dart';
import '../../features/pagos/screens/crear_cuota_screen.dart';
import '../../features/pagos/screens/detalle_cuota_screen.dart';
import '../../features/pagos/screens/reportar_pago_screen.dart';
import '../../features/paquetes/screens/registrar_paquete_screen.dart';
import '../../features/usuarios/screens/crear_usuario_screen.dart';
import '../../features/usuarios/screens/detalle_usuario_screen.dart';
import '../../features/visitas/screens/detalle_visita_screen.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/widgets/main_scaffold.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      final isAuthenticated = authState.isAuthenticated;
      final isSplash = state.matchedLocation == '/splash';
      final isLogin = state.matchedLocation == '/login';
      if (isLoading) return isSplash ? null : '/splash';
      if (!isAuthenticated) return isLogin ? null : '/login';
      if (isSplash || isLogin) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/home',
        builder: (context, state) => const MainScaffold(),
        routes: [
          GoRoute(
            path: 'visitas/:id',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return DetalleVisitaScreen(visitaId: id);
            },
          ),
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
          GoRoute(
            path: 'cuotas/nueva',
            builder: (context, state) => const CrearCuotaScreen(),
          ),
          GoRoute(
            path: 'cuotas/:id/detalle',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return DetalleCuotaScreen(cuotaId: id);
            },
          ),
          GoRoute(
            path: 'cuotas/:id/reportar',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return ReportarPagoScreen(cuotaUsuarioId: id);
            },
          ),
          GoRoute(
            path: 'paquetes/nuevo',
            builder: (context, state) => const RegistrarPaqueteScreen(),
          ),
          GoRoute(
            path: 'incidentes/nuevo',
            builder: (context, state) => const CrearIncidenteScreen(),
          ),
          GoRoute(
            path: 'incidentes/:id',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return DetalleIncidenteScreen(incidenteId: id);
            },
          ),
          GoRoute(
            path: 'notificaciones/nueva',
            builder: (context, state) => const CrearNotificacionScreen(),
          ),
          GoRoute(
            path: 'notificaciones/:id',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return DetalleNotificacionScreen(notificacionId: id);
            },
          ),
        ],
      ),
    ],
  );
});
```

- [ ] **Step 3: Commit**

```bash
git add lib/shared/widgets/main_scaffold.dart \
        lib/core/routes/app_router.dart
git commit -m "feat(notificaciones): wire navigation — Avisos tab for all roles, GoRouter routes"
```

---

## Self-Review

### Spec Coverage

| Requisito spec | Task |
|---|---|
| V6 migration con enum `segmento_notificacion` y tabla `notificaciones` | Task 1 |
| Sin tabla `notificaciones_leidas` | — (out of scope, no task) |
| `SegmentoNotificacion` enum Java | Task 2 |
| `Notificacion` entity JPA | Task 2 |
| `NotificacionRepository` query por condominio ordenado por fecha desc | Task 3 |
| `CreateNotificacionRequest`, `NotificacionResponse` DTOs | Task 3 |
| `NotificacionService`: crear (con validación edificio), listar con filtro segmento, eliminar | Task 4 |
| Filtrado: USUARIO ve TODOS + EDIFICIO_X que matchean su unidad; ADMIN/GUARDIA ven todo | Task 4 |
| `GET /api/notificaciones` accesible por todos los roles autenticados | Task 4 |
| `POST /api/notificaciones` solo ADMIN/SUPERADMIN | Task 4 |
| `DELETE /api/notificaciones/{id}` solo ADMIN/SUPERADMIN | Task 4 |
| Backend compila | Task 4 |
| Flutter `Notificacion` model + .g.dart con enum `SegmentoNotificacion` | Task 5 |
| Flutter `CreateNotificacionRequest` + .g.dart | Task 5 |
| ApiConstants: `notificaciones`, `notificacionById` | Task 6 |
| `NotificacionService` Flutter: listar, crear, eliminar (usa `delete()`) | Task 6 |
| `NotificacionNotifier`: cargar, crear (prepend lista), eliminar (filter lista) | Task 7 |
| `NotificacionesScreen`: lista, FAB solo ADMIN, chip segmento azul/naranja | Task 8 |
| `CrearNotificacionScreen`: título, mensaje, dropdown segmento, campo edificio condicional | Task 9 |
| `DetalleNotificacionScreen`: mensaje completo, chip, botón eliminar solo ADMIN con diálogo | Task 10 |
| Tab "Avisos" USUARIO índice 6, GUARDIA índice 4, ADMIN índice 6 | Task 11 |
| Rutas `/home/notificaciones/nueva` y `/home/notificaciones/:id` | Task 11 |
| `loadInitialData` carga notificaciones para todos los roles | Task 11 |
| Sin tracking de lectura | — (out of scope) |
| Sin Firebase push | — (out of scope) |
| Sin segmentos MOROSOS/PROPIETARIOS | — (out of scope) |
