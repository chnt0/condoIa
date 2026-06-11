# Incidentes — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implementar el módulo de incidentes: USUARIO reporta y puede cancelar, ADMIN cambia estados, ambos roles pueden comentar. Pantalla con 3 tabs (Pendiente / En Proceso / Resuelto) y detalle con comentarios.

**Architecture:** Backend primero (V5 migration → enums → entities → repos → DTOs → service → controller), luego Flutter (models + .g.dart manuales → service → provider → screens → navegación). Los comentarios se cargan localmente en `DetalleIncidenteScreen` usando `incidenteServiceProvider` directamente, sin saturar el estado global.

**Tech Stack:** Spring Boot 3 + JPA + Flyway + PostgreSQL | Flutter + Riverpod StateNotifier + GoRouter + DefaultTabController + json_annotation (sin build_runner)

---

## File Map

### Backend — nuevos archivos

```
backend/src/main/resources/db/migration/
  V5__create_incidentes_tables.sql

backend/src/main/java/com/condos/incidente/
  model/
    CategoriaIncidente.java
    PrioridadIncidente.java
    EstadoIncidente.java
    Incidente.java
    IncidenteComentario.java
  repository/
    IncidenteRepository.java
    IncidenteComentarioRepository.java
  dto/
    CreateIncidenteRequest.java
    UpdateEstadoRequest.java
    IncidenteResponse.java
    ComentarioResponse.java
    AddComentarioRequest.java
  service/
    IncidenteService.java
  controller/
    IncidenteController.java
```

### Flutter — nuevos archivos

```
lib/features/incidentes/
  models/
    incidente.dart              ← contiene enums CategoriaIncidente, PrioridadIncidente, EstadoIncidente
    incidente.g.dart
    create_incidente_request.dart
    create_incidente_request.g.dart
    update_estado_request.dart
    update_estado_request.g.dart
    comentario.dart
    comentario.g.dart
    add_comentario_request.dart
    add_comentario_request.g.dart
  services/
    incidente_service.dart
  providers/
    incidente_provider.dart
  screens/
    incidentes_screen.dart
    crear_incidente_screen.dart
    detalle_incidente_screen.dart
```

### Flutter — archivos modificados

```
lib/core/constants/api_constants.dart   ← 5 nuevas constantes
lib/core/routes/app_router.dart         ← 2 nuevas rutas
lib/shared/widgets/main_scaffold.dart   ← tab Incidentes para USUARIO y ADMIN
```

---

## Task 1: DB Migration V5

**Files:**
- Create: `backend/src/main/resources/db/migration/V5__create_incidentes_tables.sql`

- [ ] **Step 1: Escribir la migración**

```sql
-- V5__create_incidentes_tables.sql

CREATE TYPE categoria_incidente AS ENUM (
    'MANTENIMIENTO', 'SEGURIDAD', 'RUIDO', 'LIMPIEZA', 'OTRO'
);

CREATE TYPE prioridad_incidente AS ENUM ('BAJA', 'MEDIA', 'ALTA');

CREATE TYPE estado_incidente AS ENUM (
    'PENDIENTE', 'EN_PROCESO', 'RESUELTO', 'CANCELADO'
);

CREATE TABLE incidentes (
    id                  BIGSERIAL PRIMARY KEY,
    condominio_id       BIGINT NOT NULL REFERENCES condominios(id),
    usuario_reporta_id  BIGINT NOT NULL REFERENCES usuarios(id),
    categoria           categoria_incidente NOT NULL,
    titulo              VARCHAR(200) NOT NULL,
    descripcion         TEXT NOT NULL,
    ubicacion           VARCHAR(200) NOT NULL,
    prioridad           prioridad_incidente NOT NULL,
    estado              estado_incidente NOT NULL DEFAULT 'PENDIENTE',
    created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE incidente_comentarios (
    id            BIGSERIAL PRIMARY KEY,
    incidente_id  BIGINT NOT NULL REFERENCES incidentes(id),
    usuario_id    BIGINT NOT NULL REFERENCES usuarios(id),
    comentario    TEXT NOT NULL,
    created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_incidentes_condominio ON incidentes(condominio_id);
CREATE INDEX idx_incidentes_usuario ON incidentes(usuario_reporta_id);
CREATE INDEX idx_incidentes_estado ON incidentes(estado);
CREATE INDEX idx_incidente_comentarios_incidente ON incidente_comentarios(incidente_id);

CREATE TRIGGER update_incidentes_updated_at
    BEFORE UPDATE ON incidentes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

- [ ] **Step 2: Commit**

```bash
git add backend/src/main/resources/db/migration/V5__create_incidentes_tables.sql
git commit -m "feat(incidentes): add V5 migration — incidentes and incidente_comentarios tables"
```

---

## Task 2: Java Enums + Entities

**Files:**
- Create: `backend/src/main/java/com/condos/incidente/model/CategoriaIncidente.java`
- Create: `backend/src/main/java/com/condos/incidente/model/PrioridadIncidente.java`
- Create: `backend/src/main/java/com/condos/incidente/model/EstadoIncidente.java`
- Create: `backend/src/main/java/com/condos/incidente/model/Incidente.java`
- Create: `backend/src/main/java/com/condos/incidente/model/IncidenteComentario.java`

- [ ] **Step 1: CategoriaIncidente.java**

```java
package com.condos.incidente.model;

public enum CategoriaIncidente {
    MANTENIMIENTO,
    SEGURIDAD,
    RUIDO,
    LIMPIEZA,
    OTRO
}
```

- [ ] **Step 2: PrioridadIncidente.java**

```java
package com.condos.incidente.model;

public enum PrioridadIncidente {
    BAJA,
    MEDIA,
    ALTA
}
```

- [ ] **Step 3: EstadoIncidente.java**

```java
package com.condos.incidente.model;

public enum EstadoIncidente {
    PENDIENTE,
    EN_PROCESO,
    RESUELTO,
    CANCELADO
}
```

- [ ] **Step 4: Incidente.java**

```java
package com.condos.incidente.model;

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
@Table(name = "incidentes")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@ToString(exclude = {"condominio", "usuarioReporta"})
@EqualsAndHashCode(exclude = {"condominio", "usuarioReporta"})
public class Incidente {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "condominio_id", nullable = false)
    private Condominio condominio;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "usuario_reporta_id", nullable = false)
    private Usuario usuarioReporta;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private CategoriaIncidente categoria;

    @Column(nullable = false, length = 200)
    private String titulo;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String descripcion;

    @Column(nullable = false, length = 200)
    private String ubicacion;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 10)
    private PrioridadIncidente prioridad;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private EstadoIncidente estado;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
        if (estado == null) estado = EstadoIncidente.PENDIENTE;
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
```

- [ ] **Step 5: IncidenteComentario.java**

```java
package com.condos.incidente.model;

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
@Table(name = "incidente_comentarios")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@ToString(exclude = {"incidente", "usuario"})
@EqualsAndHashCode(exclude = {"incidente", "usuario"})
public class IncidenteComentario {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "incidente_id", nullable = false)
    private Incidente incidente;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "usuario_id", nullable = false)
    private Usuario usuario;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String comentario;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
}
```

- [ ] **Step 6: Commit**

```bash
git add backend/src/main/java/com/condos/incidente/
git commit -m "feat(incidentes): add enums, Incidente and IncidenteComentario entities"
```

---

## Task 3: Repositories

**Files:**
- Create: `backend/src/main/java/com/condos/incidente/repository/IncidenteRepository.java`
- Create: `backend/src/main/java/com/condos/incidente/repository/IncidenteComentarioRepository.java`

- [ ] **Step 1: IncidenteRepository.java**

```java
package com.condos.incidente.repository;

import com.condos.incidente.model.Incidente;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface IncidenteRepository extends JpaRepository<Incidente, Long> {
    List<Incidente> findByCondominioIdOrderByCreatedAtDesc(Long condominioId);
    List<Incidente> findByUsuarioReportaIdOrderByCreatedAtDesc(Long usuarioId);
}
```

- [ ] **Step 2: IncidenteComentarioRepository.java**

```java
package com.condos.incidente.repository;

import com.condos.incidente.model.IncidenteComentario;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface IncidenteComentarioRepository extends JpaRepository<IncidenteComentario, Long> {
    List<IncidenteComentario> findByIncidenteIdOrderByCreatedAtAsc(Long incidenteId);
}
```

- [ ] **Step 3: Commit**

```bash
git add backend/src/main/java/com/condos/incidente/repository/
git commit -m "feat(incidentes): add IncidenteRepository and IncidenteComentarioRepository"
```

---

## Task 4: DTOs

**Files:**
- Create: `backend/src/main/java/com/condos/incidente/dto/CreateIncidenteRequest.java`
- Create: `backend/src/main/java/com/condos/incidente/dto/UpdateEstadoRequest.java`
- Create: `backend/src/main/java/com/condos/incidente/dto/IncidenteResponse.java`
- Create: `backend/src/main/java/com/condos/incidente/dto/ComentarioResponse.java`
- Create: `backend/src/main/java/com/condos/incidente/dto/AddComentarioRequest.java`

- [ ] **Step 1: CreateIncidenteRequest.java**

```java
package com.condos.incidente.dto;

import com.condos.incidente.model.CategoriaIncidente;
import com.condos.incidente.model.PrioridadIncidente;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class CreateIncidenteRequest {

    @NotNull
    private CategoriaIncidente categoria;

    @NotBlank
    private String titulo;

    @NotBlank
    private String descripcion;

    @NotBlank
    private String ubicacion;

    @NotNull
    private PrioridadIncidente prioridad;
}
```

- [ ] **Step 2: UpdateEstadoRequest.java**

```java
package com.condos.incidente.dto;

import com.condos.incidente.model.EstadoIncidente;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class UpdateEstadoRequest {

    @NotNull
    private EstadoIncidente estado;
}
```

- [ ] **Step 3: IncidenteResponse.java**

```java
package com.condos.incidente.dto;

import com.condos.incidente.model.CategoriaIncidente;
import com.condos.incidente.model.EstadoIncidente;
import com.condos.incidente.model.PrioridadIncidente;
import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Builder
public class IncidenteResponse {
    private Long id;
    private CategoriaIncidente categoria;
    private String titulo;
    private String descripcion;
    private String ubicacion;
    private PrioridadIncidente prioridad;
    private EstadoIncidente estado;
    private Long usuarioReportaId;
    private String usuarioReportaNombre;
    private String usuarioReportaUnidad;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
```

- [ ] **Step 4: ComentarioResponse.java**

```java
package com.condos.incidente.dto;

import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Builder
public class ComentarioResponse {
    private Long id;
    private Long incidenteId;
    private Long usuarioId;
    private String usuarioNombre;
    private String comentario;
    private LocalDateTime createdAt;
}
```

- [ ] **Step 5: AddComentarioRequest.java**

```java
package com.condos.incidente.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class AddComentarioRequest {

    @NotBlank
    private String comentario;
}
```

- [ ] **Step 6: Commit**

```bash
git add backend/src/main/java/com/condos/incidente/dto/
git commit -m "feat(incidentes): add DTOs — CreateIncidenteRequest, UpdateEstado, IncidenteResponse, ComentarioResponse, AddComentario"
```

---

## Task 5: IncidenteService

**Files:**
- Create: `backend/src/main/java/com/condos/incidente/service/IncidenteService.java`

- [ ] **Step 1: IncidenteService.java**

```java
package com.condos.incidente.service;

import com.condos.common.exceptions.ResourceNotFoundException;
import com.condos.common.exceptions.UnauthorizedException;
import com.condos.common.utils.TenantContext;
import com.condos.condominio.model.Condominio;
import com.condos.condominio.repository.CondominioRepository;
import com.condos.incidente.dto.*;
import com.condos.incidente.model.*;
import com.condos.incidente.repository.IncidenteComentarioRepository;
import com.condos.incidente.repository.IncidenteRepository;
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
public class IncidenteService {

    private final IncidenteRepository incidenteRepository;
    private final IncidenteComentarioRepository comentarioRepository;
    private final UsuarioRepository usuarioRepository;
    private final CondominioRepository condominioRepository;

    @Transactional
    public IncidenteResponse crearIncidente(CreateIncidenteRequest request, Long usuarioId) {
        Long condominioId = TenantContext.getCondominioId();
        Condominio condominio = condominioRepository.findById(condominioId)
                .orElseThrow(() -> new ResourceNotFoundException("Condominio no encontrado"));
        Usuario usuario = usuarioRepository.findById(usuarioId)
                .orElseThrow(() -> new ResourceNotFoundException("Usuario no encontrado"));

        Incidente incidente = Incidente.builder()
                .condominio(condominio)
                .usuarioReporta(usuario)
                .categoria(request.getCategoria())
                .titulo(request.getTitulo())
                .descripcion(request.getDescripcion())
                .ubicacion(request.getUbicacion())
                .prioridad(request.getPrioridad())
                .estado(EstadoIncidente.PENDIENTE)
                .build();

        incidente = incidenteRepository.save(incidente);
        log.info("Incidente creado: id={}, usuario={}", incidente.getId(), usuario.getUsername());
        return toResponse(incidente);
    }

    @Transactional(readOnly = true)
    public List<IncidenteResponse> listarIncidentes() {
        Long condominioId = TenantContext.getCondominioId();
        return incidenteRepository.findByCondominioIdOrderByCreatedAtDesc(condominioId)
                .stream().map(this::toResponse).collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<IncidenteResponse> listarMisIncidentes(Long usuarioId) {
        return incidenteRepository.findByUsuarioReportaIdOrderByCreatedAtDesc(usuarioId)
                .stream().map(this::toResponse).collect(Collectors.toList());
    }

    @Transactional
    public IncidenteResponse actualizarEstado(Long incidenteId, UpdateEstadoRequest request) {
        Incidente incidente = incidenteRepository.findById(incidenteId)
                .orElseThrow(() -> new ResourceNotFoundException("Incidente no encontrado"));

        if (incidente.getEstado() == EstadoIncidente.RESUELTO ||
                incidente.getEstado() == EstadoIncidente.CANCELADO) {
            throw new IllegalStateException("El incidente ya está cerrado y no puede cambiar de estado");
        }
        if (request.getEstado() == EstadoIncidente.CANCELADO) {
            throw new IllegalArgumentException("Use el endpoint de cancelar para cancelar un incidente");
        }

        incidente.setEstado(request.getEstado());
        incidente = incidenteRepository.save(incidente);
        log.info("Estado incidente actualizado: id={}, estado={}", incidenteId, request.getEstado());
        return toResponse(incidente);
    }

    @Transactional
    public void cancelarIncidente(Long incidenteId, Long usuarioId) {
        Incidente incidente = incidenteRepository.findById(incidenteId)
                .orElseThrow(() -> new ResourceNotFoundException("Incidente no encontrado"));

        if (!incidente.getUsuarioReporta().getId().equals(usuarioId)) {
            throw new UnauthorizedException("No tienes permiso para cancelar este incidente");
        }
        if (incidente.getEstado() == EstadoIncidente.RESUELTO ||
                incidente.getEstado() == EstadoIncidente.CANCELADO) {
            throw new IllegalStateException("El incidente ya está cerrado");
        }

        incidente.setEstado(EstadoIncidente.CANCELADO);
        incidenteRepository.save(incidente);
        log.info("Incidente cancelado: id={}, usuario={}", incidenteId, usuarioId);
    }

    @Transactional(readOnly = true)
    public List<ComentarioResponse> listarComentarios(Long incidenteId) {
        incidenteRepository.findById(incidenteId)
                .orElseThrow(() -> new ResourceNotFoundException("Incidente no encontrado"));
        return comentarioRepository.findByIncidenteIdOrderByCreatedAtAsc(incidenteId)
                .stream().map(this::toComentarioResponse).collect(Collectors.toList());
    }

    @Transactional
    public ComentarioResponse agregarComentario(Long incidenteId, AddComentarioRequest request, Long usuarioId) {
        Incidente incidente = incidenteRepository.findById(incidenteId)
                .orElseThrow(() -> new ResourceNotFoundException("Incidente no encontrado"));
        Usuario usuario = usuarioRepository.findById(usuarioId)
                .orElseThrow(() -> new ResourceNotFoundException("Usuario no encontrado"));

        IncidenteComentario comentario = IncidenteComentario.builder()
                .incidente(incidente)
                .usuario(usuario)
                .comentario(request.getComentario())
                .build();

        comentario = comentarioRepository.save(comentario);
        log.info("Comentario agregado: incidenteId={}, usuario={}", incidenteId, usuario.getUsername());
        return toComentarioResponse(comentario);
    }

    private IncidenteResponse toResponse(Incidente i) {
        return IncidenteResponse.builder()
                .id(i.getId())
                .categoria(i.getCategoria())
                .titulo(i.getTitulo())
                .descripcion(i.getDescripcion())
                .ubicacion(i.getUbicacion())
                .prioridad(i.getPrioridad())
                .estado(i.getEstado())
                .usuarioReportaId(i.getUsuarioReporta().getId())
                .usuarioReportaNombre(i.getUsuarioReporta().getNombreCompleto())
                .usuarioReportaUnidad(i.getUsuarioReporta().getUnidadHabitacional())
                .createdAt(i.getCreatedAt())
                .updatedAt(i.getUpdatedAt())
                .build();
    }

    private ComentarioResponse toComentarioResponse(IncidenteComentario c) {
        return ComentarioResponse.builder()
                .id(c.getId())
                .incidenteId(c.getIncidente().getId())
                .usuarioId(c.getUsuario().getId())
                .usuarioNombre(c.getUsuario().getNombreCompleto())
                .comentario(c.getComentario())
                .createdAt(c.getCreatedAt())
                .build();
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add backend/src/main/java/com/condos/incidente/service/
git commit -m "feat(incidentes): add IncidenteService with full business logic"
```

---

## Task 6: IncidenteController + compilación

**Files:**
- Create: `backend/src/main/java/com/condos/incidente/controller/IncidenteController.java`

- [ ] **Step 1: IncidenteController.java**

```java
package com.condos.incidente.controller;

import com.condos.incidente.dto.*;
import com.condos.incidente.service.IncidenteService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/incidentes")
@RequiredArgsConstructor
public class IncidenteController {

    private final IncidenteService incidenteService;

    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPERADMIN')")
    public ResponseEntity<List<IncidenteResponse>> listarIncidentes() {
        return ResponseEntity.ok(incidenteService.listarIncidentes());
    }

    @GetMapping("/mis-incidentes")
    @PreAuthorize("hasRole('USUARIO')")
    public ResponseEntity<List<IncidenteResponse>> listarMisIncidentes(Authentication authentication) {
        Long usuarioId = Long.parseLong(authentication.getName());
        return ResponseEntity.ok(incidenteService.listarMisIncidentes(usuarioId));
    }

    @PostMapping
    @PreAuthorize("hasRole('USUARIO')")
    public ResponseEntity<IncidenteResponse> crearIncidente(
            @Valid @RequestBody CreateIncidenteRequest request,
            Authentication authentication) {
        Long usuarioId = Long.parseLong(authentication.getName());
        return ResponseEntity.ok(incidenteService.crearIncidente(request, usuarioId));
    }

    @PutMapping("/{id}/estado")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPERADMIN')")
    public ResponseEntity<IncidenteResponse> actualizarEstado(
            @PathVariable Long id,
            @Valid @RequestBody UpdateEstadoRequest request) {
        return ResponseEntity.ok(incidenteService.actualizarEstado(id, request));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('USUARIO')")
    public ResponseEntity<Void> cancelarIncidente(
            @PathVariable Long id,
            Authentication authentication) {
        Long usuarioId = Long.parseLong(authentication.getName());
        incidenteService.cancelarIncidente(id, usuarioId);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/{id}/comentarios")
    @PreAuthorize("hasAnyRole('USUARIO', 'ADMIN', 'SUPERADMIN')")
    public ResponseEntity<List<ComentarioResponse>> listarComentarios(@PathVariable Long id) {
        return ResponseEntity.ok(incidenteService.listarComentarios(id));
    }

    @PostMapping("/{id}/comentarios")
    @PreAuthorize("hasAnyRole('USUARIO', 'ADMIN', 'SUPERADMIN')")
    public ResponseEntity<ComentarioResponse> agregarComentario(
            @PathVariable Long id,
            @Valid @RequestBody AddComentarioRequest request,
            Authentication authentication) {
        Long usuarioId = Long.parseLong(authentication.getName());
        return ResponseEntity.ok(incidenteService.agregarComentario(id, request, usuarioId));
    }
}
```

- [ ] **Step 2: Verificar compilación**

```bash
cd backend && ./mvnw compile -q
```

Expected: sin output (BUILD SUCCESS).

- [ ] **Step 3: Commit**

```bash
git add backend/src/main/java/com/condos/incidente/controller/
git commit -m "feat(incidentes): add IncidenteController — 7 endpoints for incidents and comments"
```

---

## Task 7: Flutter Models + .g.dart

**Files:**
- Create: `lib/features/incidentes/models/incidente.dart`
- Create: `lib/features/incidentes/models/incidente.g.dart`
- Create: `lib/features/incidentes/models/create_incidente_request.dart`
- Create: `lib/features/incidentes/models/create_incidente_request.g.dart`
- Create: `lib/features/incidentes/models/update_estado_request.dart`
- Create: `lib/features/incidentes/models/update_estado_request.g.dart`
- Create: `lib/features/incidentes/models/comentario.dart`
- Create: `lib/features/incidentes/models/comentario.g.dart`
- Create: `lib/features/incidentes/models/add_comentario_request.dart`
- Create: `lib/features/incidentes/models/add_comentario_request.g.dart`

- [ ] **Step 1: incidente.dart**

```dart
import 'package:json_annotation/json_annotation.dart';

part 'incidente.g.dart';

enum CategoriaIncidente {
  @JsonValue('MANTENIMIENTO')
  mantenimiento,
  @JsonValue('SEGURIDAD')
  seguridad,
  @JsonValue('RUIDO')
  ruido,
  @JsonValue('LIMPIEZA')
  limpieza,
  @JsonValue('OTRO')
  otro,
}

enum PrioridadIncidente {
  @JsonValue('BAJA')
  baja,
  @JsonValue('MEDIA')
  media,
  @JsonValue('ALTA')
  alta,
}

enum EstadoIncidente {
  @JsonValue('PENDIENTE')
  pendiente,
  @JsonValue('EN_PROCESO')
  enProceso,
  @JsonValue('RESUELTO')
  resuelto,
  @JsonValue('CANCELADO')
  cancelado,
}

@JsonSerializable()
class Incidente {
  final int id;
  final CategoriaIncidente categoria;
  final String titulo;
  final String descripcion;
  final String ubicacion;
  final PrioridadIncidente prioridad;
  final EstadoIncidente estado;
  final int usuarioReportaId;
  final String usuarioReportaNombre;
  final String? usuarioReportaUnidad;
  final DateTime createdAt;
  final DateTime updatedAt;

  Incidente({
    required this.id,
    required this.categoria,
    required this.titulo,
    required this.descripcion,
    required this.ubicacion,
    required this.prioridad,
    required this.estado,
    required this.usuarioReportaId,
    required this.usuarioReportaNombre,
    this.usuarioReportaUnidad,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Incidente.fromJson(Map<String, dynamic> json) =>
      _$IncidenteFromJson(json);
  Map<String, dynamic> toJson() => _$IncidenteToJson(this);
}
```

- [ ] **Step 2: incidente.g.dart**

```dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'incidente.dart';

Incidente _$IncidenteFromJson(Map<String, dynamic> json) => Incidente(
      id: (json['id'] as num).toInt(),
      categoria: $enumDecode(_$CategoriaIncidenteEnumMap, json['categoria']),
      titulo: json['titulo'] as String,
      descripcion: json['descripcion'] as String,
      ubicacion: json['ubicacion'] as String,
      prioridad: $enumDecode(_$PrioridadIncidenteEnumMap, json['prioridad']),
      estado: $enumDecode(_$EstadoIncidenteEnumMap, json['estado']),
      usuarioReportaId: (json['usuarioReportaId'] as num).toInt(),
      usuarioReportaNombre: json['usuarioReportaNombre'] as String,
      usuarioReportaUnidad: json['usuarioReportaUnidad'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$IncidenteToJson(Incidente instance) =>
    <String, dynamic>{
      'id': instance.id,
      'categoria': _$CategoriaIncidenteEnumMap[instance.categoria]!,
      'titulo': instance.titulo,
      'descripcion': instance.descripcion,
      'ubicacion': instance.ubicacion,
      'prioridad': _$PrioridadIncidenteEnumMap[instance.prioridad]!,
      'estado': _$EstadoIncidenteEnumMap[instance.estado]!,
      'usuarioReportaId': instance.usuarioReportaId,
      'usuarioReportaNombre': instance.usuarioReportaNombre,
      'usuarioReportaUnidad': instance.usuarioReportaUnidad,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

const _$CategoriaIncidenteEnumMap = {
  CategoriaIncidente.mantenimiento: 'MANTENIMIENTO',
  CategoriaIncidente.seguridad: 'SEGURIDAD',
  CategoriaIncidente.ruido: 'RUIDO',
  CategoriaIncidente.limpieza: 'LIMPIEZA',
  CategoriaIncidente.otro: 'OTRO',
};

const _$PrioridadIncidenteEnumMap = {
  PrioridadIncidente.baja: 'BAJA',
  PrioridadIncidente.media: 'MEDIA',
  PrioridadIncidente.alta: 'ALTA',
};

const _$EstadoIncidenteEnumMap = {
  EstadoIncidente.pendiente: 'PENDIENTE',
  EstadoIncidente.enProceso: 'EN_PROCESO',
  EstadoIncidente.resuelto: 'RESUELTO',
  EstadoIncidente.cancelado: 'CANCELADO',
};
```

- [ ] **Step 3: create_incidente_request.dart**

```dart
import 'package:json_annotation/json_annotation.dart';
import 'incidente.dart';

part 'create_incidente_request.g.dart';

@JsonSerializable()
class CreateIncidenteRequest {
  final CategoriaIncidente categoria;
  final String titulo;
  final String descripcion;
  final String ubicacion;
  final PrioridadIncidente prioridad;

  CreateIncidenteRequest({
    required this.categoria,
    required this.titulo,
    required this.descripcion,
    required this.ubicacion,
    required this.prioridad,
  });

  factory CreateIncidenteRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateIncidenteRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateIncidenteRequestToJson(this);
}
```

- [ ] **Step 4: create_incidente_request.g.dart**

```dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_incidente_request.dart';

CreateIncidenteRequest _$CreateIncidenteRequestFromJson(
        Map<String, dynamic> json) =>
    CreateIncidenteRequest(
      categoria: $enumDecode(_$CategoriaIncidenteEnumMap, json['categoria']),
      titulo: json['titulo'] as String,
      descripcion: json['descripcion'] as String,
      ubicacion: json['ubicacion'] as String,
      prioridad: $enumDecode(_$PrioridadIncidenteEnumMap, json['prioridad']),
    );

Map<String, dynamic> _$CreateIncidenteRequestToJson(
        CreateIncidenteRequest instance) =>
    <String, dynamic>{
      'categoria': _$CategoriaIncidenteEnumMap[instance.categoria]!,
      'titulo': instance.titulo,
      'descripcion': instance.descripcion,
      'ubicacion': instance.ubicacion,
      'prioridad': _$PrioridadIncidenteEnumMap[instance.prioridad]!,
    };

const _$CategoriaIncidenteEnumMap = {
  CategoriaIncidente.mantenimiento: 'MANTENIMIENTO',
  CategoriaIncidente.seguridad: 'SEGURIDAD',
  CategoriaIncidente.ruido: 'RUIDO',
  CategoriaIncidente.limpieza: 'LIMPIEZA',
  CategoriaIncidente.otro: 'OTRO',
};

const _$PrioridadIncidenteEnumMap = {
  PrioridadIncidente.baja: 'BAJA',
  PrioridadIncidente.media: 'MEDIA',
  PrioridadIncidente.alta: 'ALTA',
};
```

- [ ] **Step 5: update_estado_request.dart**

```dart
import 'package:json_annotation/json_annotation.dart';
import 'incidente.dart';

part 'update_estado_request.g.dart';

@JsonSerializable()
class UpdateEstadoRequest {
  final EstadoIncidente estado;

  UpdateEstadoRequest({required this.estado});

  factory UpdateEstadoRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateEstadoRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateEstadoRequestToJson(this);
}
```

- [ ] **Step 6: update_estado_request.g.dart**

```dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_estado_request.dart';

UpdateEstadoRequest _$UpdateEstadoRequestFromJson(Map<String, dynamic> json) =>
    UpdateEstadoRequest(
      estado: $enumDecode(_$EstadoIncidenteEnumMap, json['estado']),
    );

Map<String, dynamic> _$UpdateEstadoRequestToJson(
        UpdateEstadoRequest instance) =>
    <String, dynamic>{
      'estado': _$EstadoIncidenteEnumMap[instance.estado]!,
    };

const _$EstadoIncidenteEnumMap = {
  EstadoIncidente.pendiente: 'PENDIENTE',
  EstadoIncidente.enProceso: 'EN_PROCESO',
  EstadoIncidente.resuelto: 'RESUELTO',
  EstadoIncidente.cancelado: 'CANCELADO',
};
```

- [ ] **Step 7: comentario.dart**

```dart
import 'package:json_annotation/json_annotation.dart';

part 'comentario.g.dart';

@JsonSerializable()
class Comentario {
  final int id;
  final int incidenteId;
  final int usuarioId;
  final String usuarioNombre;
  final String comentario;
  final DateTime createdAt;

  Comentario({
    required this.id,
    required this.incidenteId,
    required this.usuarioId,
    required this.usuarioNombre,
    required this.comentario,
    required this.createdAt,
  });

  factory Comentario.fromJson(Map<String, dynamic> json) =>
      _$ComentarioFromJson(json);
  Map<String, dynamic> toJson() => _$ComentarioToJson(this);
}
```

- [ ] **Step 8: comentario.g.dart**

```dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comentario.dart';

Comentario _$ComentarioFromJson(Map<String, dynamic> json) => Comentario(
      id: (json['id'] as num).toInt(),
      incidenteId: (json['incidenteId'] as num).toInt(),
      usuarioId: (json['usuarioId'] as num).toInt(),
      usuarioNombre: json['usuarioNombre'] as String,
      comentario: json['comentario'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$ComentarioToJson(Comentario instance) =>
    <String, dynamic>{
      'id': instance.id,
      'incidenteId': instance.incidenteId,
      'usuarioId': instance.usuarioId,
      'usuarioNombre': instance.usuarioNombre,
      'comentario': instance.comentario,
      'createdAt': instance.createdAt.toIso8601String(),
    };
```

- [ ] **Step 9: add_comentario_request.dart**

```dart
import 'package:json_annotation/json_annotation.dart';

part 'add_comentario_request.g.dart';

@JsonSerializable()
class AddComentarioRequest {
  final String comentario;

  AddComentarioRequest({required this.comentario});

  factory AddComentarioRequest.fromJson(Map<String, dynamic> json) =>
      _$AddComentarioRequestFromJson(json);
  Map<String, dynamic> toJson() => _$AddComentarioRequestToJson(this);
}
```

- [ ] **Step 10: add_comentario_request.g.dart**

```dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'add_comentario_request.dart';

AddComentarioRequest _$AddComentarioRequestFromJson(
        Map<String, dynamic> json) =>
    AddComentarioRequest(
      comentario: json['comentario'] as String,
    );

Map<String, dynamic> _$AddComentarioRequestToJson(
        AddComentarioRequest instance) =>
    <String, dynamic>{
      'comentario': instance.comentario,
    };
```

- [ ] **Step 11: Commit**

```bash
git add lib/features/incidentes/models/
git commit -m "feat(incidentes): add Flutter models with manual .g.dart — Incidente, requests, Comentario"
```

---

## Task 8: ApiConstants + IncidenteService Flutter

**Files:**
- Modify: `lib/core/constants/api_constants.dart`
- Create: `lib/features/incidentes/services/incidente_service.dart`

- [ ] **Step 1: Agregar constantes a api_constants.dart**

Insertar antes de las constantes de paquetes:

```dart
  // Incidentes
  static const String incidentes = '$apiPrefix/incidentes';
  static const String misIncidentes = '$apiPrefix/incidentes/mis-incidentes';
  static String incidenteEstado(int id) => '$apiPrefix/incidentes/$id/estado';
  static String cancelarIncidente(int id) => '$apiPrefix/incidentes/$id';
  static String incidenteComentarios(int id) => '$apiPrefix/incidentes/$id/comentarios';
```

- [ ] **Step 2: incidente_service.dart**

```dart
import '../../../core/constants/api_constants.dart';
import '../../../shared/services/api_client.dart';
import '../models/add_comentario_request.dart';
import '../models/comentario.dart';
import '../models/create_incidente_request.dart';
import '../models/incidente.dart';
import '../models/update_estado_request.dart';

class IncidenteService {
  final ApiClient apiClient;

  IncidenteService({required this.apiClient});

  Future<List<Incidente>> listarIncidentes() async {
    final response = await apiClient.getList(ApiConstants.incidentes);
    return response
        .map((item) => Incidente.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<Incidente>> listarMisIncidentes() async {
    final response = await apiClient.getList(ApiConstants.misIncidentes);
    return response
        .map((item) => Incidente.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Incidente> crearIncidente(CreateIncidenteRequest request) async {
    final response =
        await apiClient.post(ApiConstants.incidentes, request.toJson());
    return Incidente.fromJson(response);
  }

  Future<Incidente> actualizarEstado(
      int id, UpdateEstadoRequest request) async {
    final response = await apiClient.put(
        ApiConstants.incidenteEstado(id), request.toJson());
    return Incidente.fromJson(response);
  }

  Future<void> cancelarIncidente(int id) async {
    await apiClient.delete(ApiConstants.cancelarIncidente(id));
  }

  Future<List<Comentario>> listarComentarios(int incidenteId) async {
    final response =
        await apiClient.getList(ApiConstants.incidenteComentarios(incidenteId));
    return response
        .map((item) => Comentario.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Comentario> agregarComentario(
      int incidenteId, AddComentarioRequest request) async {
    final response = await apiClient.post(
        ApiConstants.incidenteComentarios(incidenteId), request.toJson());
    return Comentario.fromJson(response);
  }
}
```

- [ ] **Step 3: Verificar que ApiClient tiene método `delete`**

Leer `lib/shared/services/api_client.dart` y confirmar que existe un método `delete(String path)`. Si no existe, agregarlo siguiendo el patrón de `put`:

```dart
Future<void> delete(String path) async {
  final response = await _dio.delete(path);
  // no retorna body
}
```

- [ ] **Step 4: Commit**

```bash
git add lib/core/constants/api_constants.dart \
        lib/features/incidentes/services/incidente_service.dart \
        lib/shared/services/api_client.dart
git commit -m "feat(incidentes): add ApiConstants, IncidenteService Flutter; add delete() to ApiClient if missing"
```

---

## Task 9: IncidenteProvider

**Files:**
- Create: `lib/features/incidentes/providers/incidente_provider.dart`

- [ ] **Step 1: incidente_provider.dart**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/auth_provider.dart';
import '../models/create_incidente_request.dart';
import '../models/incidente.dart';
import '../models/update_estado_request.dart';
import '../services/incidente_service.dart';

class IncidenteState {
  final List<Incidente> incidentes;
  final bool isLoading;
  final String? error;

  IncidenteState({
    this.incidentes = const [],
    this.isLoading = false,
    this.error,
  });

  IncidenteState copyWith({
    List<Incidente>? incidentes,
    bool? isLoading,
    String? error,
  }) {
    return IncidenteState(
      incidentes: incidentes ?? this.incidentes,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class IncidenteNotifier extends StateNotifier<IncidenteState> {
  final IncidenteService _service;

  IncidenteNotifier(this._service) : super(IncidenteState());

  Future<void> cargarIncidentes() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final incidentes = await _service.listarIncidentes();
      state = state.copyWith(incidentes: incidentes, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> cargarMisIncidentes() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final incidentes = await _service.listarMisIncidentes();
      state = state.copyWith(incidentes: incidentes, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<Incidente?> crearIncidente(CreateIncidenteRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final incidente = await _service.crearIncidente(request);
      state = state.copyWith(
        incidentes: [incidente, ...state.incidentes],
        isLoading: false,
      );
      return incidente;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<void> actualizarEstado(int id, UpdateEstadoRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updated = await _service.actualizarEstado(id, request);
      state = state.copyWith(
        incidentes:
            state.incidentes.map((i) => i.id == id ? updated : i).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> cancelarIncidente(int id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.cancelarIncidente(id);
      state = state.copyWith(
        incidentes: state.incidentes
            .map((i) => i.id == id
                ? Incidente(
                    id: i.id,
                    categoria: i.categoria,
                    titulo: i.titulo,
                    descripcion: i.descripcion,
                    ubicacion: i.ubicacion,
                    prioridad: i.prioridad,
                    estado: EstadoIncidente.cancelado,
                    usuarioReportaId: i.usuarioReportaId,
                    usuarioReportaNombre: i.usuarioReportaNombre,
                    usuarioReportaUnidad: i.usuarioReportaUnidad,
                    createdAt: i.createdAt,
                    updatedAt: DateTime.now(),
                  )
                : i)
            .toList(),
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

final incidenteServiceProvider = Provider<IncidenteService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return IncidenteService(apiClient: apiClient);
});

final incidenteProvider =
    StateNotifierProvider<IncidenteNotifier, IncidenteState>((ref) {
  final service = ref.watch(incidenteServiceProvider);
  return IncidenteNotifier(service);
});
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/incidentes/providers/incidente_provider.dart
git commit -m "feat(incidentes): add IncidenteNotifier and incidenteProvider"
```

---

## Task 10: IncidentesScreen (3 tabs)

**Files:**
- Create: `lib/features/incidentes/screens/incidentes_screen.dart`

- [ ] **Step 1: incidentes_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/models/usuario.dart';
import '../../../shared/providers/auth_provider.dart';
import '../models/incidente.dart';
import '../providers/incidente_provider.dart';

class IncidentesScreen extends ConsumerStatefulWidget {
  const IncidentesScreen({super.key});

  @override
  ConsumerState<IncidentesScreen> createState() => _IncidentesScreenState();
}

class _IncidentesScreenState extends ConsumerState<IncidentesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  void _cargar() {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    if (user.rol == Rol.usuario) {
      ref.read(incidenteProvider.notifier).cargarMisIncidentes();
    } else {
      ref.read(incidenteProvider.notifier).cargarIncidentes();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final state = ref.watch(incidenteProvider);
    final esUsuario = user?.rol == Rol.usuario;

    final visibles = state.incidentes
        .where((i) => i.estado != EstadoIncidente.cancelado)
        .toList();
    final pendientes =
        visibles.where((i) => i.estado == EstadoIncidente.pendiente).toList();
    final enProceso =
        visibles.where((i) => i.estado == EstadoIncidente.enProceso).toList();
    final resueltos =
        visibles.where((i) => i.estado == EstadoIncidente.resuelto).toList();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Incidentes'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Pendiente'),
              Tab(text: 'En Proceso'),
              Tab(text: 'Resuelto'),
            ],
          ),
        ),
        floatingActionButton: esUsuario
            ? FloatingActionButton(
                onPressed: () async {
                  await context.push('/home/incidentes/nuevo');
                  _cargar();
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
                            onPressed: _cargar,
                            child: const Text('Reintentar')),
                      ],
                    ),
                  )
                : TabBarView(
                    children: [
                      _IncidenteList(incidentes: pendientes, onRefresh: _cargar),
                      _IncidenteList(incidentes: enProceso, onRefresh: _cargar),
                      _IncidenteList(incidentes: resueltos, onRefresh: _cargar),
                    ],
                  ),
      ),
    );
  }
}

class _IncidenteList extends StatelessWidget {
  final List<Incidente> incidentes;
  final VoidCallback onRefresh;

  const _IncidenteList({required this.incidentes, required this.onRefresh});

  Color _prioridadColor(PrioridadIncidente p) => switch (p) {
        PrioridadIncidente.alta => Colors.red,
        PrioridadIncidente.media => Colors.orange,
        PrioridadIncidente.baja => Colors.grey,
      };

  Color _estadoColor(EstadoIncidente e) => switch (e) {
        EstadoIncidente.pendiente => Colors.orange,
        EstadoIncidente.enProceso => Colors.blue,
        EstadoIncidente.resuelto => Colors.green,
        EstadoIncidente.cancelado => Colors.grey,
      };

  String _categoriaLabel(CategoriaIncidente c) => switch (c) {
        CategoriaIncidente.mantenimiento => 'Mantenimiento',
        CategoriaIncidente.seguridad => 'Seguridad',
        CategoriaIncidente.ruido => 'Ruido',
        CategoriaIncidente.limpieza => 'Limpieza',
        CategoriaIncidente.otro => 'Otro',
      };

  @override
  Widget build(BuildContext context) {
    if (incidentes.isEmpty) {
      return const Center(child: Text('No hay incidentes en esta sección.'));
    }
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        itemCount: incidentes.length,
        itemBuilder: (context, index) {
          final i = incidentes[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _prioridadColor(i.prioridad),
                child: Text(
                  i.prioridad.name[0].toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(i.titulo,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_categoriaLabel(i.categoria)),
                  Text(i.ubicacion,
                      style: const TextStyle(fontSize: 12)),
                ],
              ),
              trailing: Chip(
                label: Text(
                  i.estado == EstadoIncidente.enProceso
                      ? 'EN PROCESO'
                      : i.estado.name.toUpperCase(),
                  style:
                      const TextStyle(color: Colors.white, fontSize: 10),
                ),
                backgroundColor: _estadoColor(i.estado),
              ),
              onTap: () async {
                await context.push('/home/incidentes/${i.id}');
                onRefresh();
              },
            ),
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/incidentes/screens/incidentes_screen.dart
git commit -m "feat(incidentes): add IncidentesScreen with 3 tabs — Pendiente, En Proceso, Resuelto"
```

---

## Task 11: CrearIncidenteScreen

**Files:**
- Create: `lib/features/incidentes/screens/crear_incidente_screen.dart`

- [ ] **Step 1: crear_incidente_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/create_incidente_request.dart';
import '../models/incidente.dart';
import '../providers/incidente_provider.dart';

class CrearIncidenteScreen extends ConsumerStatefulWidget {
  const CrearIncidenteScreen({super.key});

  @override
  ConsumerState<CrearIncidenteScreen> createState() =>
      _CrearIncidenteScreenState();
}

class _CrearIncidenteScreenState extends ConsumerState<CrearIncidenteScreen> {
  final _formKey = GlobalKey<FormState>();
  CategoriaIncidente _categoria = CategoriaIncidente.mantenimiento;
  PrioridadIncidente _prioridad = PrioridadIncidente.media;
  final _tituloCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _ubicacionCtrl = TextEditingController();

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descripcionCtrl.dispose();
    _ubicacionCtrl.dispose();
    super.dispose();
  }

  String _categoriaLabel(CategoriaIncidente c) => switch (c) {
        CategoriaIncidente.mantenimiento => 'Mantenimiento',
        CategoriaIncidente.seguridad => 'Seguridad',
        CategoriaIncidente.ruido => 'Ruido',
        CategoriaIncidente.limpieza => 'Limpieza',
        CategoriaIncidente.otro => 'Otro',
      };

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final request = CreateIncidenteRequest(
      categoria: _categoria,
      titulo: _tituloCtrl.text.trim(),
      descripcion: _descripcionCtrl.text.trim(),
      ubicacion: _ubicacionCtrl.text.trim(),
      prioridad: _prioridad,
    );
    final incidente =
        await ref.read(incidenteProvider.notifier).crearIncidente(request);
    if (mounted) {
      if (incidente != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incidente reportado exitosamente')),
        );
        context.pop();
      } else {
        final error = ref.read(incidenteProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(error ?? 'Error al reportar incidente'),
              backgroundColor: Colors.red),
        );
        ref.read(incidenteProvider.notifier).clearError();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(incidenteProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Reportar Incidente')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<CategoriaIncidente>(
                value: _categoria,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  border: OutlineInputBorder(),
                ),
                items: CategoriaIncidente.values
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(_categoriaLabel(c)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _categoria = v!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<PrioridadIncidente>(
                value: _prioridad,
                decoration: const InputDecoration(
                  labelText: 'Prioridad',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: PrioridadIncidente.baja, child: Text('Baja')),
                  DropdownMenuItem(value: PrioridadIncidente.media, child: Text('Media')),
                  DropdownMenuItem(value: PrioridadIncidente.alta, child: Text('Alta')),
                ],
                onChanged: (v) => setState(() => _prioridad = v!),
              ),
              const SizedBox(height: 16),
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
                controller: _descripcionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Descripción *',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ubicacionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Ubicación *',
                  hintText: 'Ej: Área de alberca, Torre A piso 3',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: state.isLoading ? null : _submit,
                child: state.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Reportar Incidente'),
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
git add lib/features/incidentes/screens/crear_incidente_screen.dart
git commit -m "feat(incidentes): add CrearIncidenteScreen with categoria, prioridad, titulo, descripcion, ubicacion"
```

---

## Task 12: DetalleIncidenteScreen

**Files:**
- Create: `lib/features/incidentes/screens/detalle_incidente_screen.dart`

- [ ] **Step 1: detalle_incidente_screen.dart**

Los comentarios se cargan directamente desde `incidenteServiceProvider` (no desde el estado global) para mantener el provider limpio.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/usuario.dart';
import '../../../shared/providers/auth_provider.dart';
import '../models/add_comentario_request.dart';
import '../models/comentario.dart';
import '../models/incidente.dart';
import '../models/update_estado_request.dart';
import '../providers/incidente_provider.dart';

class DetalleIncidenteScreen extends ConsumerStatefulWidget {
  final int incidenteId;

  const DetalleIncidenteScreen({super.key, required this.incidenteId});

  @override
  ConsumerState<DetalleIncidenteScreen> createState() =>
      _DetalleIncidenteScreenState();
}

class _DetalleIncidenteScreenState
    extends ConsumerState<DetalleIncidenteScreen> {
  List<Comentario> _comentarios = [];
  bool _loadingComentarios = true;
  final _comentarioCtrl = TextEditingController();
  bool _enviando = false;
  EstadoIncidente? _nuevoEstado;

  Incidente? get _incidente {
    final state = ref.read(incidenteProvider);
    return state.incidentes
        .where((i) => i.id == widget.incidenteId)
        .firstOrNull;
  }

  @override
  void initState() {
    super.initState();
    _cargarComentarios();
  }

  @override
  void dispose() {
    _comentarioCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarComentarios() async {
    setState(() => _loadingComentarios = true);
    try {
      final service = ref.read(incidenteServiceProvider);
      final comentarios =
          await service.listarComentarios(widget.incidenteId);
      setState(() {
        _comentarios = comentarios;
        _loadingComentarios = false;
      });
    } catch (e) {
      setState(() => _loadingComentarios = false);
    }
  }

  Future<void> _enviarComentario() async {
    final texto = _comentarioCtrl.text.trim();
    if (texto.isEmpty) return;
    setState(() => _enviando = true);
    try {
      final service = ref.read(incidenteServiceProvider);
      final nuevo = await service.agregarComentario(
          widget.incidenteId, AddComentarioRequest(comentario: texto));
      setState(() {
        _comentarios = [..._comentarios, nuevo];
        _enviando = false;
      });
      _comentarioCtrl.clear();
    } catch (e) {
      setState(() => _enviando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _actualizarEstado() async {
    if (_nuevoEstado == null) return;
    await ref.read(incidenteProvider.notifier).actualizarEstado(
          widget.incidenteId,
          UpdateEstadoRequest(estado: _nuevoEstado!),
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Estado actualizado')),
      );
      setState(() => _nuevoEstado = null);
    }
  }

  Future<void> _cancelar() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar incidente'),
        content: const Text(
            '¿Estás seguro de que quieres cancelar este incidente?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('No')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await ref
          .read(incidenteProvider.notifier)
          .cancelarIncidente(widget.incidenteId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incidente cancelado')),
        );
        Navigator.pop(context);
      }
    }
  }

  Color _prioridadColor(PrioridadIncidente p) => switch (p) {
        PrioridadIncidente.alta => Colors.red,
        PrioridadIncidente.media => Colors.orange,
        PrioridadIncidente.baja => Colors.grey,
      };

  String _categoriaLabel(CategoriaIncidente c) => switch (c) {
        CategoriaIncidente.mantenimiento => 'Mantenimiento',
        CategoriaIncidente.seguridad => 'Seguridad',
        CategoriaIncidente.ruido => 'Ruido',
        CategoriaIncidente.limpieza => 'Limpieza',
        CategoriaIncidente.otro => 'Otro',
      };

  String _estadoLabel(EstadoIncidente e) => switch (e) {
        EstadoIncidente.pendiente => 'PENDIENTE',
        EstadoIncidente.enProceso => 'EN PROCESO',
        EstadoIncidente.resuelto => 'RESUELTO',
        EstadoIncidente.cancelado => 'CANCELADO',
      };

  Color _estadoColor(EstadoIncidente e) => switch (e) {
        EstadoIncidente.pendiente => Colors.orange,
        EstadoIncidente.enProceso => Colors.blue,
        EstadoIncidente.resuelto => Colors.green,
        EstadoIncidente.cancelado => Colors.grey,
      };

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final state = ref.watch(incidenteProvider);
    final incidente =
        state.incidentes.where((i) => i.id == widget.incidenteId).firstOrNull;

    if (incidente == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Incidente')),
        body: const Center(child: Text('Incidente no encontrado')),
      );
    }

    final esAdmin =
        user?.rol == Rol.admin || user?.rol == Rol.superadmin;
    final esUsuarioDueno =
        user?.rol == Rol.usuario &&
        user?.id == incidente.usuarioReportaId;
    final puedeComentarAdminODueno = esAdmin || esUsuarioDueno;
    final esCerrado = incidente.estado == EstadoIncidente.resuelto ||
        incidente.estado == EstadoIncidente.cancelado;

    return Scaffold(
      appBar: AppBar(title: Text(incidente.titulo)),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header info
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(
                      label: Text(_estadoLabel(incidente.estado),
                          style: const TextStyle(color: Colors.white)),
                      backgroundColor: _estadoColor(incidente.estado),
                    ),
                    Chip(
                      label: Text(incidente.prioridad.name.toUpperCase(),
                          style: const TextStyle(color: Colors.white)),
                      backgroundColor: _prioridadColor(incidente.prioridad),
                    ),
                    Chip(label: Text(_categoriaLabel(incidente.categoria))),
                  ],
                ),
                const SizedBox(height: 12),
                Text(incidente.descripcion),
                const SizedBox(height: 8),
                Text('Ubicación: ${incidente.ubicacion}',
                    style: const TextStyle(color: Colors.grey)),
                Text('Reportado por: ${incidente.usuarioReportaNombre}',
                    style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 16),

                // ADMIN: cambiar estado
                if (esAdmin && !esCerrado) ...[
                  const Divider(),
                  DropdownButtonFormField<EstadoIncidente>(
                    value: _nuevoEstado,
                    hint: const Text('Cambiar estado a...'),
                    decoration: const InputDecoration(
                        border: OutlineInputBorder()),
                    items: [
                      EstadoIncidente.enProceso,
                      EstadoIncidente.resuelto,
                    ]
                        .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(_estadoLabel(e)),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _nuevoEstado = v),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed:
                        state.isLoading || _nuevoEstado == null
                            ? null
                            : _actualizarEstado,
                    child: const Text('Actualizar estado'),
                  ),
                  const SizedBox(height: 16),
                ],

                // USUARIO dueño: cancelar
                if (esUsuarioDueno && !esCerrado) ...[
                  const Divider(),
                  OutlinedButton(
                    onPressed: state.isLoading ? null : _cancelar,
                    style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red)),
                    child: const Text('Cancelar incidente'),
                  ),
                  const SizedBox(height: 16),
                ],

                // Comentarios
                const Divider(),
                const Text('Comentarios',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                if (_loadingComentarios)
                  const Center(child: CircularProgressIndicator())
                else if (_comentarios.isEmpty)
                  const Text('Sin comentarios aún.',
                      style: TextStyle(color: Colors.grey))
                else
                  ..._comentarios.map((c) => _ComentarioTile(c: c)),
              ],
            ),
          ),

          // Campo de comentario
          if (puedeComentarAdminODueno)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                    top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _comentarioCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Agregar comentario...',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      maxLines: 2,
                      minLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _enviando ? null : _enviarComentario,
                    icon: _enviando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child:
                                CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ComentarioTile extends StatelessWidget {
  final Comentario c;

  const _ComentarioTile({required this.c});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            child: Text(c.usuarioNombre[0].toUpperCase()),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.usuarioNombre,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(c.comentario),
                Text(
                  '${c.createdAt.day}/${c.createdAt.month}/${c.createdAt.year}',
                  style:
                      const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/incidentes/screens/detalle_incidente_screen.dart
git commit -m "feat(incidentes): add DetalleIncidenteScreen with comments, state change, and cancel"
```

---

## Task 13: Navegación — MainScaffold + GoRouter

**Files:**
- Modify: `lib/shared/widgets/main_scaffold.dart`
- Modify: `lib/core/routes/app_router.dart`

- [ ] **Step 1: Actualizar main_scaffold.dart**

Tabs resultantes:
- USUARIO (7): Inicio, Mis Visitas, Nueva, Paquetes, Incidentes, Cuotas, Perfil
- GUARDIA (5): Escanear, Paquetes, Hoy, Historial, Perfil — sin cambios
- ADMIN (7): Dashboard, Visitas, Paquetes, Incidentes, Gestión, Cuotas, Perfil

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/incidentes/providers/incidente_provider.dart';
import '../../features/incidentes/screens/incidentes_screen.dart';
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
    switch (user.rol) {
      case Rol.usuario:
        visitaNotifier.cargarMisVisitas();
        cuotaNotifier.cargarMisCuotas();
        paqueteNotifier.cargarMisPaquetes();
        incidenteNotifier.cargarMisIncidentes();
      case Rol.guardia:
        visitaNotifier.cargarTodasVisitas();
        paqueteNotifier.cargarPaquetes();
      case Rol.admin:
      case Rol.superadmin:
        visitaNotifier.cargarTodasVisitas();
        cuotaNotifier.cargarCuotas();
        paqueteNotifier.cargarPaquetes();
        incidenteNotifier.cargarIncidentes();
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
          const PerfilScreen(),
        ],
      Rol.guardia => [
          const EscanearQrScreen(),
          const PaquetesScreen(),
          const VisitasAdminScreen(filterToday: true),
          const VisitasAdminScreen(filterToday: false),
          const PerfilScreen(),
        ],
      Rol.admin || Rol.superadmin => [
          const DashboardAdminScreen(),
          const VisitasAdminScreen(filterToday: false),
          const PaquetesScreen(),
          const IncidentesScreen(),
          const GestionScreen(),
          const CuotasAdminScreen(),
          const PerfilScreen(),
        ],
    };
  }

  List<BottomNavigationBarItem> _buildItems(Rol rol) {
    return switch (rol) {
      Rol.usuario => const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Mis Visitas'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Nueva'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), label: 'Paquetes'),
          BottomNavigationBarItem(icon: Icon(Icons.report_outlined), label: 'Incidentes'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Cuotas'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Perfil'),
        ],
      Rol.guardia => const [
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: 'Escanear'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), label: 'Paquetes'),
          BottomNavigationBarItem(icon: Icon(Icons.today), label: 'Hoy'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Historial'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Perfil'),
        ],
      Rol.admin || Rol.superadmin => const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Visitas'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), label: 'Paquetes'),
          BottomNavigationBarItem(icon: Icon(Icons.report_outlined), label: 'Incidentes'),
          BottomNavigationBarItem(icon: Icon(Icons.manage_accounts), label: 'Gestión'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Cuotas'),
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
git commit -m "feat(incidentes): wire navigation — Incidentes tab for USUARIO and ADMIN, GoRouter routes"
```

---

## Self-Review

### Spec Coverage

| Requisito spec | Task |
|---|---|
| V5 migration con enums PostgreSQL y 2 tablas | Task 1 |
| Enums Java: CategoriaIncidente, PrioridadIncidente, EstadoIncidente | Task 2 |
| Entities: Incidente, IncidenteComentario | Task 2 |
| IncidenteRepository, IncidenteComentarioRepository | Task 3 |
| DTOs: Create, UpdateEstado, IncidenteResponse, ComentarioResponse, AddComentario | Task 4 |
| IncidenteService: crear, listar, listarMios, actualizarEstado, cancelar, comentarios | Task 5 |
| Regla: solo ADMIN cambia estado; estado no puede retroceder | Task 5 |
| Regla: USUARIO solo cancela sus propios; solo si PENDIENTE o EN_PROCESO | Task 5 |
| Regla: CANCELADO no acepta más cambios | Task 5 |
| IncidenteController: 7 endpoints con @PreAuthorize | Task 6 |
| Backend compila | Task 6 |
| Flutter models + .g.dart: Incidente (con 3 enums), CreateRequest, UpdateEstado, Comentario, AddComentario | Task 7 |
| ApiConstants: 5 nuevas constantes | Task 8 |
| IncidenteService Flutter con delete() | Task 8 |
| Verificar ApiClient.delete() existe | Task 8 |
| IncidenteNotifier: cargar, crearIncidente, actualizarEstado, cancelarIncidente | Task 9 |
| incidenteServiceProvider expuesto para uso directo en DetalleIncidenteScreen | Task 9 |
| IncidentesScreen: 3 tabs, CANCELADO excluido de todos | Task 10 |
| FAB solo para USUARIO | Task 10 |
| CrearIncidenteScreen: categoria, prioridad, titulo, descripcion, ubicacion | Task 11 |
| DetalleIncidenteScreen: comentarios cargados localmente via incidenteServiceProvider | Task 12 |
| ADMIN: dropdown estado + botón actualizar | Task 12 |
| USUARIO dueño: botón cancelar con confirmación dialog | Task 12 |
| Campo comentario visible solo para ADMIN y USUARIO dueño | Task 12 |
| Tab Incidentes: USUARIO (índice 4), ADMIN (índice 3), GUARDIA sin cambios | Task 13 |
| Rutas: /home/incidentes/nuevo, /home/incidentes/:id | Task 13 |
| loadInitialData carga incidentes según rol | Task 13 |
| Sin fotos (out of scope) | — |
| Sin notificaciones push (out of scope) | — |
| GUARDIA sin acceso | — verificado en @PreAuthorize |
