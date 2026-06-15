# Pagos / Cuotas — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implementar el módulo de cuotas y pagos: ADMIN genera cuotas (mensuales/extraordinarias), USUARIO reporta pagos, ADMIN confirma/rechaza — backend Spring Boot + Flutter.

**Architecture:** Backend primero (migración DB → entities → service → controller), luego Flutter (models + .g.dart manuales → service → provider → screens → navegación). Los archivos `.g.dart` se escriben manualmente porque `dartaotruntime` no está disponible en este entorno.

**Tech Stack:** Spring Boot 3 + JPA + Flyway + PostgreSQL | Flutter + Riverpod StateNotifier + GoRouter + json_annotation (sin build_runner)

---

## File Map

### Backend nuevos archivos

```
backend/src/main/resources/db/migration/
  V3__create_pagos_tables.sql

backend/src/main/java/com/condos/pago/
  model/
    TipoCuota.java
    EstadoPago.java
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

### Backend modificados

```
backend/src/main/java/com/condos/usuario/repository/UsuarioRepository.java
  + findByCondominioIdAndRolAndActivo(Long, Rol, Boolean): List<Usuario>
```

### Flutter nuevos archivos

```
lib/features/pagos/
  models/
    cuota_response.dart
    cuota_response.g.dart
    cuota_usuario_response.dart
    cuota_usuario_response.g.dart
    create_cuota_request.dart
    create_cuota_request.g.dart
    reportar_pago_request.dart
    reportar_pago_request.g.dart
    confirmar_pago_request.dart
    confirmar_pago_request.g.dart
  services/
    cuota_service.dart
  providers/
    cuota_provider.dart
  screens/
    mis_cuotas_screen.dart
    reportar_pago_screen.dart
    cuotas_admin_screen.dart
    crear_cuota_screen.dart
    detalle_cuota_screen.dart
```

### Flutter modificados

```
lib/core/constants/api_constants.dart          — 5 nuevas constantes/helpers
lib/core/routes/app_router.dart                — 4 nuevas rutas bajo /home
lib/shared/widgets/main_scaffold.dart          — tab "Cuotas" para USUARIO y ADMIN
```

---

## Task 1: DB Migration V3

**Files:**
- Create: `backend/src/main/resources/db/migration/V3__create_pagos_tables.sql`

- [ ] **Step 1: Escribir la migración**

```sql
-- V3__create_pagos_tables.sql

CREATE TYPE tipo_cuota AS ENUM ('MENSUAL', 'EXTRAORDINARIA');
CREATE TYPE estado_pago AS ENUM ('PENDIENTE', 'REPORTADO', 'CONFIRMADO', 'RECHAZADO');

CREATE TABLE cuotas (
    id              BIGSERIAL PRIMARY KEY,
    condominio_id   BIGINT NOT NULL REFERENCES condominios(id),
    tipo            tipo_cuota NOT NULL,
    concepto        VARCHAR(255) NOT NULL,
    monto           NUMERIC(10,2) NOT NULL,
    mes             VARCHAR(7),
    fecha_vencimiento DATE NOT NULL,
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE cuota_usuarios (
    id                  BIGSERIAL PRIMARY KEY,
    cuota_id            BIGINT NOT NULL REFERENCES cuotas(id),
    usuario_id          BIGINT NOT NULL REFERENCES usuarios(id),
    estado              estado_pago NOT NULL DEFAULT 'PENDIENTE',
    referencia_pago     VARCHAR(255),
    notas_usuario       TEXT,
    notas_admin         TEXT,
    fecha_reporte       TIMESTAMP,
    fecha_confirmacion  TIMESTAMP,
    created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (cuota_id, usuario_id)
);

CREATE INDEX idx_cuotas_condominio ON cuotas(condominio_id);
CREATE INDEX idx_cuota_usuarios_cuota ON cuota_usuarios(cuota_id);
CREATE INDEX idx_cuota_usuarios_usuario ON cuota_usuarios(usuario_id);
CREATE INDEX idx_cuota_usuarios_estado ON cuota_usuarios(estado);

CREATE TRIGGER update_cuotas_updated_at
    BEFORE UPDATE ON cuotas
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_cuota_usuarios_updated_at
    BEFORE UPDATE ON cuota_usuarios
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

- [ ] **Step 2: Commit**

```bash
git add backend/src/main/resources/db/migration/V3__create_pagos_tables.sql
git commit -m "feat(pagos): add V3 migration — cuotas and cuota_usuarios tables"
```

---

## Task 2: Java Enums + Entities

**Files:**
- Create: `backend/src/main/java/com/condos/pago/model/TipoCuota.java`
- Create: `backend/src/main/java/com/condos/pago/model/EstadoPago.java`
- Create: `backend/src/main/java/com/condos/pago/model/Cuota.java`
- Create: `backend/src/main/java/com/condos/pago/model/CuotaUsuario.java`

- [ ] **Step 1: TipoCuota.java**

```java
package com.condos.pago.model;

public enum TipoCuota {
    MENSUAL,
    EXTRAORDINARIA
}
```

- [ ] **Step 2: EstadoPago.java**

```java
package com.condos.pago.model;

public enum EstadoPago {
    PENDIENTE,
    REPORTADO,
    CONFIRMADO,
    RECHAZADO
}
```

- [ ] **Step 3: Cuota.java**

```java
package com.condos.pago.model;

import com.condos.condominio.model.Condominio;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "cuotas")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Cuota {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "condominio_id", nullable = false)
    private Condominio condominio;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private TipoCuota tipo;

    @Column(nullable = false, length = 255)
    private String concepto;

    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal monto;

    @Column(length = 7)
    private String mes;

    @Column(name = "fecha_vencimiento", nullable = false)
    private LocalDate fechaVencimiento;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
```

- [ ] **Step 4: CuotaUsuario.java**

```java
package com.condos.pago.model;

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
@Table(name = "cuota_usuarios",
       uniqueConstraints = @UniqueConstraint(columnNames = {"cuota_id", "usuario_id"}))
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@ToString(exclude = {"cuota", "usuario"})
@EqualsAndHashCode(exclude = {"cuota", "usuario"})
public class CuotaUsuario {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "cuota_id", nullable = false)
    private Cuota cuota;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "usuario_id", nullable = false)
    private Usuario usuario;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private EstadoPago estado;

    @Column(name = "referencia_pago", length = 255)
    private String referenciaPago;

    @Column(name = "notas_usuario", columnDefinition = "TEXT")
    private String notasUsuario;

    @Column(name = "notas_admin", columnDefinition = "TEXT")
    private String notasAdmin;

    @Column(name = "fecha_reporte")
    private LocalDateTime fechaReporte;

    @Column(name = "fecha_confirmacion")
    private LocalDateTime fechaConfirmacion;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
        if (estado == null) {
            estado = EstadoPago.PENDIENTE;
        }
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
```

- [ ] **Step 5: Commit**

```bash
git add backend/src/main/java/com/condos/pago/
git commit -m "feat(pagos): add TipoCuota, EstadoPago enums and Cuota, CuotaUsuario entities"
```

---

## Task 3: Repositories

**Files:**
- Create: `backend/src/main/java/com/condos/pago/repository/CuotaRepository.java`
- Create: `backend/src/main/java/com/condos/pago/repository/CuotaUsuarioRepository.java`
- Modify: `backend/src/main/java/com/condos/usuario/repository/UsuarioRepository.java`

- [ ] **Step 1: CuotaRepository.java**

```java
package com.condos.pago.repository;

import com.condos.pago.model.Cuota;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface CuotaRepository extends JpaRepository<Cuota, Long> {
    List<Cuota> findByCondominioIdOrderByCreatedAtDesc(Long condominioId);
}
```

- [ ] **Step 2: CuotaUsuarioRepository.java**

```java
package com.condos.pago.repository;

import com.condos.pago.model.CuotaUsuario;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface CuotaUsuarioRepository extends JpaRepository<CuotaUsuario, Long> {
    List<CuotaUsuario> findByCuotaId(Long cuotaId);
    List<CuotaUsuario> findByUsuarioIdOrderByCreatedAtDesc(Long usuarioId);
}
```

- [ ] **Step 3: Agregar query a UsuarioRepository**

En `UsuarioRepository.java`, agregar:

```java
import com.condos.usuario.model.Rol;

List<Usuario> findByCondominioIdAndRolAndActivo(Long condominioId, Rol rol, Boolean activo);
```

El archivo completo queda:

```java
package com.condos.usuario.repository;

import com.condos.usuario.model.Rol;
import com.condos.usuario.model.Usuario;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UsuarioRepository extends JpaRepository<Usuario, Long> {

    Optional<Usuario> findByUsername(String username);

    Optional<Usuario> findByEmail(String email);

    List<Usuario> findByCondominioId(Long condominioId);

    List<Usuario> findByCondominioIdAndRolAndActivo(Long condominioId, Rol rol, Boolean activo);

    boolean existsByUsername(String username);

    boolean existsByEmail(String email);
}
```

- [ ] **Step 4: Commit**

```bash
git add backend/src/main/java/com/condos/pago/repository/ \
        backend/src/main/java/com/condos/usuario/repository/UsuarioRepository.java
git commit -m "feat(pagos): add CuotaRepository, CuotaUsuarioRepository; extend UsuarioRepository"
```

---

## Task 4: DTOs

**Files:**
- Create: `backend/src/main/java/com/condos/pago/dto/CreateCuotaRequest.java`
- Create: `backend/src/main/java/com/condos/pago/dto/ReportarPagoRequest.java`
- Create: `backend/src/main/java/com/condos/pago/dto/ConfirmarPagoRequest.java`
- Create: `backend/src/main/java/com/condos/pago/dto/CuotaResponse.java`
- Create: `backend/src/main/java/com/condos/pago/dto/CuotaUsuarioResponse.java`

- [ ] **Step 1: CreateCuotaRequest.java**

```java
package com.condos.pago.dto;

import com.condos.pago.model.TipoCuota;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

@Data
public class CreateCuotaRequest {

    @NotNull
    private TipoCuota tipo;

    @NotBlank
    private String concepto;

    @NotNull
    @DecimalMin("0.01")
    private BigDecimal monto;

    private String mes;

    @NotNull
    private LocalDate fechaVencimiento;

    private List<Long> usuarioIds;
}
```

- [ ] **Step 2: ReportarPagoRequest.java**

```java
package com.condos.pago.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class ReportarPagoRequest {

    @NotBlank
    private String referenciaPago;

    private String notasUsuario;
}
```

- [ ] **Step 3: ConfirmarPagoRequest.java**

```java
package com.condos.pago.dto;

import lombok.Data;

@Data
public class ConfirmarPagoRequest {
    private boolean confirmado;
    private String notasAdmin;
}
```

- [ ] **Step 4: CuotaResponse.java**

```java
package com.condos.pago.dto;

import com.condos.pago.model.TipoCuota;
import lombok.Builder;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@Builder
public class CuotaResponse {
    private Long id;
    private TipoCuota tipo;
    private String concepto;
    private BigDecimal monto;
    private String mes;
    private LocalDate fechaVencimiento;
    private int totalResidentes;
    private int totalConfirmados;
    private int totalReportados;
    private int totalPendientes;
    private LocalDateTime createdAt;
}
```

- [ ] **Step 5: CuotaUsuarioResponse.java**

```java
package com.condos.pago.dto;

import com.condos.pago.model.EstadoPago;
import lombok.Builder;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@Builder
public class CuotaUsuarioResponse {
    private Long id;
    private Long cuotaId;
    private String concepto;
    private BigDecimal monto;
    private LocalDate fechaVencimiento;
    private Long usuarioId;
    private String usuarioNombre;
    private String unidadHabitacional;
    private EstadoPago estado;
    private String referenciaPago;
    private String notasUsuario;
    private String notasAdmin;
    private LocalDateTime fechaReporte;
    private LocalDateTime fechaConfirmacion;
}
```

- [ ] **Step 6: Commit**

```bash
git add backend/src/main/java/com/condos/pago/dto/
git commit -m "feat(pagos): add DTOs — CreateCuotaRequest, ReportarPago, ConfirmarPago, CuotaResponse, CuotaUsuarioResponse"
```

---

## Task 5: CuotaService

**Files:**
- Create: `backend/src/main/java/com/condos/pago/service/CuotaService.java`

- [ ] **Step 1: Escribir CuotaService.java**

```java
package com.condos.pago.service;

import com.condos.common.exceptions.ResourceNotFoundException;
import com.condos.common.exceptions.UnauthorizedException;
import com.condos.common.utils.TenantContext;
import com.condos.condominio.model.Condominio;
import com.condos.condominio.repository.CondominioRepository;
import com.condos.pago.dto.*;
import com.condos.pago.model.*;
import com.condos.pago.repository.CuotaRepository;
import com.condos.pago.repository.CuotaUsuarioRepository;
import com.condos.usuario.model.Rol;
import com.condos.usuario.model.Usuario;
import com.condos.usuario.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class CuotaService {

    private final CuotaRepository cuotaRepository;
    private final CuotaUsuarioRepository cuotaUsuarioRepository;
    private final UsuarioRepository usuarioRepository;
    private final CondominioRepository condominioRepository;

    @Transactional
    public CuotaResponse crearCuota(CreateCuotaRequest request) {
        Long condominioId = TenantContext.getCondominioId();
        Condominio condominio = condominioRepository.findById(condominioId)
                .orElseThrow(() -> new ResourceNotFoundException("Condominio no encontrado"));

        Cuota cuota = Cuota.builder()
                .condominio(condominio)
                .tipo(request.getTipo())
                .concepto(request.getConcepto())
                .monto(request.getMonto())
                .mes(request.getMes())
                .fechaVencimiento(request.getFechaVencimiento())
                .build();
        cuota = cuotaRepository.save(cuota);

        List<Usuario> destinatarios;
        if (request.getTipo() == TipoCuota.MENSUAL) {
            destinatarios = usuarioRepository.findByCondominioIdAndRolAndActivo(
                    condominioId, Rol.USUARIO, true);
        } else {
            if (request.getUsuarioIds() == null || request.getUsuarioIds().isEmpty()) {
                throw new IllegalArgumentException(
                        "Una cuota EXTRAORDINARIA requiere al menos un usuario destinatario");
            }
            destinatarios = usuarioRepository.findAllById(request.getUsuarioIds());
        }

        for (Usuario u : destinatarios) {
            CuotaUsuario cu = CuotaUsuario.builder()
                    .cuota(cuota)
                    .usuario(u)
                    .estado(EstadoPago.PENDIENTE)
                    .build();
            cuotaUsuarioRepository.save(cu);
        }

        log.info("Cuota creada: id={}, tipo={}, destinatarios={}", cuota.getId(), cuota.getTipo(), destinatarios.size());
        return toCuotaResponse(cuota);
    }

    @Transactional(readOnly = true)
    public List<CuotaResponse> listarCuotas() {
        Long condominioId = TenantContext.getCondominioId();
        return cuotaRepository.findByCondominioIdOrderByCreatedAtDesc(condominioId)
                .stream()
                .map(this::toCuotaResponse)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<CuotaUsuarioResponse> obtenerDetalle(Long cuotaId) {
        return cuotaUsuarioRepository.findByCuotaId(cuotaId)
                .stream()
                .map(this::toCuotaUsuarioResponse)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<CuotaUsuarioResponse> listarMisCuotas(Long usuarioId) {
        return cuotaUsuarioRepository.findByUsuarioIdOrderByCreatedAtDesc(usuarioId)
                .stream()
                .map(this::toCuotaUsuarioResponse)
                .collect(Collectors.toList());
    }

    @Transactional
    public CuotaUsuarioResponse reportarPago(Long cuotaUsuarioId, ReportarPagoRequest request, Long usuarioId) {
        CuotaUsuario cu = cuotaUsuarioRepository.findById(cuotaUsuarioId)
                .orElseThrow(() -> new ResourceNotFoundException("Cuota de usuario no encontrada"));

        if (!cu.getUsuario().getId().equals(usuarioId)) {
            throw new UnauthorizedException("No tienes permiso para reportar este pago");
        }
        if (cu.getEstado() == EstadoPago.CONFIRMADO) {
            throw new IllegalStateException("Este pago ya fue confirmado");
        }
        if (cu.getEstado() == EstadoPago.REPORTADO) {
            throw new IllegalStateException("El pago ya fue reportado y está pendiente de revisión");
        }

        cu.setEstado(EstadoPago.REPORTADO);
        cu.setReferenciaPago(request.getReferenciaPago());
        cu.setNotasUsuario(request.getNotasUsuario());
        cu.setFechaReporte(LocalDateTime.now());

        cu = cuotaUsuarioRepository.save(cu);
        log.info("Pago reportado: cuotaUsuarioId={}, usuario={}", cuotaUsuarioId, usuarioId);
        return toCuotaUsuarioResponse(cu);
    }

    @Transactional
    public CuotaUsuarioResponse confirmarPago(Long cuotaUsuarioId, ConfirmarPagoRequest request) {
        CuotaUsuario cu = cuotaUsuarioRepository.findById(cuotaUsuarioId)
                .orElseThrow(() -> new ResourceNotFoundException("Cuota de usuario no encontrada"));

        if (cu.getEstado() != EstadoPago.REPORTADO) {
            throw new IllegalStateException("Solo se pueden confirmar/rechazar pagos en estado REPORTADO");
        }
        if (!request.isConfirmado() &&
                (request.getNotasAdmin() == null || request.getNotasAdmin().isBlank())) {
            throw new IllegalArgumentException("Se requiere una nota del admin para rechazar un pago");
        }

        cu.setEstado(request.isConfirmado() ? EstadoPago.CONFIRMADO : EstadoPago.RECHAZADO);
        cu.setNotasAdmin(request.getNotasAdmin());
        cu.setFechaConfirmacion(LocalDateTime.now());

        cu = cuotaUsuarioRepository.save(cu);
        log.info("Pago {}: cuotaUsuarioId={}", cu.getEstado(), cuotaUsuarioId);
        return toCuotaUsuarioResponse(cu);
    }

    private CuotaResponse toCuotaResponse(Cuota cuota) {
        List<CuotaUsuario> registros = cuotaUsuarioRepository.findByCuotaId(cuota.getId());
        long confirmados = registros.stream().filter(r -> r.getEstado() == EstadoPago.CONFIRMADO).count();
        long reportados  = registros.stream().filter(r -> r.getEstado() == EstadoPago.REPORTADO).count();
        long pendientes  = registros.stream().filter(r ->
                r.getEstado() == EstadoPago.PENDIENTE || r.getEstado() == EstadoPago.RECHAZADO).count();

        return CuotaResponse.builder()
                .id(cuota.getId())
                .tipo(cuota.getTipo())
                .concepto(cuota.getConcepto())
                .monto(cuota.getMonto())
                .mes(cuota.getMes())
                .fechaVencimiento(cuota.getFechaVencimiento())
                .totalResidentes(registros.size())
                .totalConfirmados((int) confirmados)
                .totalReportados((int) reportados)
                .totalPendientes((int) pendientes)
                .createdAt(cuota.getCreatedAt())
                .build();
    }

    private CuotaUsuarioResponse toCuotaUsuarioResponse(CuotaUsuario cu) {
        Cuota cuota = cu.getCuota();
        Usuario usuario = cu.getUsuario();
        return CuotaUsuarioResponse.builder()
                .id(cu.getId())
                .cuotaId(cuota.getId())
                .concepto(cuota.getConcepto())
                .monto(cuota.getMonto())
                .fechaVencimiento(cuota.getFechaVencimiento())
                .usuarioId(usuario.getId())
                .usuarioNombre(usuario.getNombreCompleto())
                .unidadHabitacional(usuario.getUnidadHabitacional())
                .estado(cu.getEstado())
                .referenciaPago(cu.getReferenciaPago())
                .notasUsuario(cu.getNotasUsuario())
                .notasAdmin(cu.getNotasAdmin())
                .fechaReporte(cu.getFechaReporte())
                .fechaConfirmacion(cu.getFechaConfirmacion())
                .build();
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add backend/src/main/java/com/condos/pago/service/
git commit -m "feat(pagos): add CuotaService with business rules for cuota creation and payment flow"
```

---

## Task 6: CuotaController

**Files:**
- Create: `backend/src/main/java/com/condos/pago/controller/CuotaController.java`

- [ ] **Step 1: Escribir CuotaController.java**

```java
package com.condos.pago.controller;

import com.condos.pago.dto.*;
import com.condos.pago.service.CuotaService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/cuotas")
@RequiredArgsConstructor
public class CuotaController {

    private final CuotaService cuotaService;

    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPERADMIN')")
    public ResponseEntity<List<CuotaResponse>> listarCuotas() {
        return ResponseEntity.ok(cuotaService.listarCuotas());
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPERADMIN')")
    public ResponseEntity<CuotaResponse> crearCuota(@Valid @RequestBody CreateCuotaRequest request) {
        return ResponseEntity.ok(cuotaService.crearCuota(request));
    }

    @GetMapping("/mis-cuotas")
    @PreAuthorize("hasRole('USUARIO')")
    public ResponseEntity<List<CuotaUsuarioResponse>> listarMisCuotas(Authentication authentication) {
        Long usuarioId = Long.parseLong(authentication.getName());
        return ResponseEntity.ok(cuotaService.listarMisCuotas(usuarioId));
    }

    @GetMapping("/{id}/detalle")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPERADMIN')")
    public ResponseEntity<List<CuotaUsuarioResponse>> obtenerDetalle(@PathVariable Long id) {
        return ResponseEntity.ok(cuotaService.obtenerDetalle(id));
    }

    @PutMapping("/{cuotaUsuarioId}/reportar")
    @PreAuthorize("hasRole('USUARIO')")
    public ResponseEntity<CuotaUsuarioResponse> reportarPago(
            @PathVariable Long cuotaUsuarioId,
            @Valid @RequestBody ReportarPagoRequest request,
            Authentication authentication) {
        Long usuarioId = Long.parseLong(authentication.getName());
        return ResponseEntity.ok(cuotaService.reportarPago(cuotaUsuarioId, request, usuarioId));
    }

    @PutMapping("/{cuotaUsuarioId}/confirmar")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPERADMIN')")
    public ResponseEntity<CuotaUsuarioResponse> confirmarPago(
            @PathVariable Long cuotaUsuarioId,
            @Valid @RequestBody ConfirmarPagoRequest request) {
        return ResponseEntity.ok(cuotaService.confirmarPago(cuotaUsuarioId, request));
    }
}
```

- [ ] **Step 2: Verificar que el backend compila**

```bash
cd backend && ./mvnw compile -q
```

Expected: BUILD SUCCESS (sin errores de compilación).

- [ ] **Step 3: Commit**

```bash
git add backend/src/main/java/com/condos/pago/controller/
git commit -m "feat(pagos): add CuotaController — 6 endpoints for cuota management and payment flow"
```

---

## Task 7: Flutter Models — CuotaResponse y CuotaUsuarioResponse

**Files:**
- Create: `lib/features/pagos/models/cuota_response.dart`
- Create: `lib/features/pagos/models/cuota_response.g.dart`
- Create: `lib/features/pagos/models/cuota_usuario_response.dart`
- Create: `lib/features/pagos/models/cuota_usuario_response.g.dart`

- [ ] **Step 1: cuota_response.dart**

```dart
import 'package:json_annotation/json_annotation.dart';

part 'cuota_response.g.dart';

enum TipoCuota {
  @JsonValue('MENSUAL')
  mensual,

  @JsonValue('EXTRAORDINARIA')
  extraordinaria,
}

@JsonSerializable()
class CuotaResponse {
  final int id;
  final TipoCuota tipo;
  final String concepto;
  final double monto;
  final String? mes;
  final String fechaVencimiento;
  final int totalResidentes;
  final int totalConfirmados;
  final int totalReportados;
  final int totalPendientes;
  final DateTime createdAt;

  CuotaResponse({
    required this.id,
    required this.tipo,
    required this.concepto,
    required this.monto,
    this.mes,
    required this.fechaVencimiento,
    required this.totalResidentes,
    required this.totalConfirmados,
    required this.totalReportados,
    required this.totalPendientes,
    required this.createdAt,
  });

  factory CuotaResponse.fromJson(Map<String, dynamic> json) =>
      _$CuotaResponseFromJson(json);
  Map<String, dynamic> toJson() => _$CuotaResponseToJson(this);
}
```

- [ ] **Step 2: cuota_response.g.dart**

```dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cuota_response.dart';

CuotaResponse _$CuotaResponseFromJson(Map<String, dynamic> json) =>
    CuotaResponse(
      id: (json['id'] as num).toInt(),
      tipo: $enumDecode(_$TipoCuotaEnumMap, json['tipo']),
      concepto: json['concepto'] as String,
      monto: (json['monto'] as num).toDouble(),
      mes: json['mes'] as String?,
      fechaVencimiento: json['fechaVencimiento'] as String,
      totalResidentes: (json['totalResidentes'] as num).toInt(),
      totalConfirmados: (json['totalConfirmados'] as num).toInt(),
      totalReportados: (json['totalReportados'] as num).toInt(),
      totalPendientes: (json['totalPendientes'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$CuotaResponseToJson(CuotaResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tipo': _$TipoCuotaEnumMap[instance.tipo]!,
      'concepto': instance.concepto,
      'monto': instance.monto,
      'mes': instance.mes,
      'fechaVencimiento': instance.fechaVencimiento,
      'totalResidentes': instance.totalResidentes,
      'totalConfirmados': instance.totalConfirmados,
      'totalReportados': instance.totalReportados,
      'totalPendientes': instance.totalPendientes,
      'createdAt': instance.createdAt.toIso8601String(),
    };

const _$TipoCuotaEnumMap = {
  TipoCuota.mensual: 'MENSUAL',
  TipoCuota.extraordinaria: 'EXTRAORDINARIA',
};
```

- [ ] **Step 3: cuota_usuario_response.dart**

```dart
import 'package:json_annotation/json_annotation.dart';

part 'cuota_usuario_response.g.dart';

enum EstadoPago {
  @JsonValue('PENDIENTE')
  pendiente,

  @JsonValue('REPORTADO')
  reportado,

  @JsonValue('CONFIRMADO')
  confirmado,

  @JsonValue('RECHAZADO')
  rechazado,
}

@JsonSerializable()
class CuotaUsuarioResponse {
  final int id;
  final int cuotaId;
  final String concepto;
  final double monto;
  final String fechaVencimiento;
  final int usuarioId;
  final String usuarioNombre;
  final String? unidadHabitacional;
  final EstadoPago estado;
  final String? referenciaPago;
  final String? notasUsuario;
  final String? notasAdmin;
  final DateTime? fechaReporte;
  final DateTime? fechaConfirmacion;

  CuotaUsuarioResponse({
    required this.id,
    required this.cuotaId,
    required this.concepto,
    required this.monto,
    required this.fechaVencimiento,
    required this.usuarioId,
    required this.usuarioNombre,
    this.unidadHabitacional,
    required this.estado,
    this.referenciaPago,
    this.notasUsuario,
    this.notasAdmin,
    this.fechaReporte,
    this.fechaConfirmacion,
  });

  factory CuotaUsuarioResponse.fromJson(Map<String, dynamic> json) =>
      _$CuotaUsuarioResponseFromJson(json);
  Map<String, dynamic> toJson() => _$CuotaUsuarioResponseToJson(this);
}
```

- [ ] **Step 4: cuota_usuario_response.g.dart**

```dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cuota_usuario_response.dart';

CuotaUsuarioResponse _$CuotaUsuarioResponseFromJson(
        Map<String, dynamic> json) =>
    CuotaUsuarioResponse(
      id: (json['id'] as num).toInt(),
      cuotaId: (json['cuotaId'] as num).toInt(),
      concepto: json['concepto'] as String,
      monto: (json['monto'] as num).toDouble(),
      fechaVencimiento: json['fechaVencimiento'] as String,
      usuarioId: (json['usuarioId'] as num).toInt(),
      usuarioNombre: json['usuarioNombre'] as String,
      unidadHabitacional: json['unidadHabitacional'] as String?,
      estado: $enumDecode(_$EstadoPagoEnumMap, json['estado']),
      referenciaPago: json['referenciaPago'] as String?,
      notasUsuario: json['notasUsuario'] as String?,
      notasAdmin: json['notasAdmin'] as String?,
      fechaReporte: json['fechaReporte'] == null
          ? null
          : DateTime.parse(json['fechaReporte'] as String),
      fechaConfirmacion: json['fechaConfirmacion'] == null
          ? null
          : DateTime.parse(json['fechaConfirmacion'] as String),
    );

Map<String, dynamic> _$CuotaUsuarioResponseToJson(
        CuotaUsuarioResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'cuotaId': instance.cuotaId,
      'concepto': instance.concepto,
      'monto': instance.monto,
      'fechaVencimiento': instance.fechaVencimiento,
      'usuarioId': instance.usuarioId,
      'usuarioNombre': instance.usuarioNombre,
      'unidadHabitacional': instance.unidadHabitacional,
      'estado': _$EstadoPagoEnumMap[instance.estado]!,
      'referenciaPago': instance.referenciaPago,
      'notasUsuario': instance.notasUsuario,
      'notasAdmin': instance.notasAdmin,
      'fechaReporte': instance.fechaReporte?.toIso8601String(),
      'fechaConfirmacion': instance.fechaConfirmacion?.toIso8601String(),
    };

const _$EstadoPagoEnumMap = {
  EstadoPago.pendiente: 'PENDIENTE',
  EstadoPago.reportado: 'REPORTADO',
  EstadoPago.confirmado: 'CONFIRMADO',
  EstadoPago.rechazado: 'RECHAZADO',
};
```

- [ ] **Step 5: Commit**

```bash
git add lib/features/pagos/models/cuota_response.dart \
        lib/features/pagos/models/cuota_response.g.dart \
        lib/features/pagos/models/cuota_usuario_response.dart \
        lib/features/pagos/models/cuota_usuario_response.g.dart
git commit -m "feat(pagos): add Flutter models CuotaResponse and CuotaUsuarioResponse with manual .g.dart"
```

---

## Task 8: Flutter Request Models

**Files:**
- Create: `lib/features/pagos/models/create_cuota_request.dart`
- Create: `lib/features/pagos/models/create_cuota_request.g.dart`
- Create: `lib/features/pagos/models/reportar_pago_request.dart`
- Create: `lib/features/pagos/models/reportar_pago_request.g.dart`
- Create: `lib/features/pagos/models/confirmar_pago_request.dart`
- Create: `lib/features/pagos/models/confirmar_pago_request.g.dart`

- [ ] **Step 1: create_cuota_request.dart**

```dart
import 'package:json_annotation/json_annotation.dart';
import 'cuota_response.dart';

part 'create_cuota_request.g.dart';

@JsonSerializable()
class CreateCuotaRequest {
  final TipoCuota tipo;
  final String concepto;
  final double monto;
  final String? mes;
  final String fechaVencimiento;
  final List<int>? usuarioIds;

  CreateCuotaRequest({
    required this.tipo,
    required this.concepto,
    required this.monto,
    this.mes,
    required this.fechaVencimiento,
    this.usuarioIds,
  });

  factory CreateCuotaRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateCuotaRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateCuotaRequestToJson(this);
}
```

- [ ] **Step 2: create_cuota_request.g.dart**

```dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_cuota_request.dart';

CreateCuotaRequest _$CreateCuotaRequestFromJson(Map<String, dynamic> json) =>
    CreateCuotaRequest(
      tipo: $enumDecode(_$TipoCuotaEnumMap, json['tipo']),
      concepto: json['concepto'] as String,
      monto: (json['monto'] as num).toDouble(),
      mes: json['mes'] as String?,
      fechaVencimiento: json['fechaVencimiento'] as String,
      usuarioIds: (json['usuarioIds'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
    );

Map<String, dynamic> _$CreateCuotaRequestToJson(
        CreateCuotaRequest instance) =>
    <String, dynamic>{
      'tipo': _$TipoCuotaEnumMap[instance.tipo]!,
      'concepto': instance.concepto,
      'monto': instance.monto,
      'mes': instance.mes,
      'fechaVencimiento': instance.fechaVencimiento,
      'usuarioIds': instance.usuarioIds,
    };

const _$TipoCuotaEnumMap = {
  TipoCuota.mensual: 'MENSUAL',
  TipoCuota.extraordinaria: 'EXTRAORDINARIA',
};
```

- [ ] **Step 3: reportar_pago_request.dart**

```dart
import 'package:json_annotation/json_annotation.dart';

part 'reportar_pago_request.g.dart';

@JsonSerializable()
class ReportarPagoRequest {
  final String referenciaPago;
  final String? notasUsuario;

  ReportarPagoRequest({required this.referenciaPago, this.notasUsuario});

  factory ReportarPagoRequest.fromJson(Map<String, dynamic> json) =>
      _$ReportarPagoRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ReportarPagoRequestToJson(this);
}
```

- [ ] **Step 4: reportar_pago_request.g.dart**

```dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reportar_pago_request.dart';

ReportarPagoRequest _$ReportarPagoRequestFromJson(
        Map<String, dynamic> json) =>
    ReportarPagoRequest(
      referenciaPago: json['referenciaPago'] as String,
      notasUsuario: json['notasUsuario'] as String?,
    );

Map<String, dynamic> _$ReportarPagoRequestToJson(
        ReportarPagoRequest instance) =>
    <String, dynamic>{
      'referenciaPago': instance.referenciaPago,
      'notasUsuario': instance.notasUsuario,
    };
```

- [ ] **Step 5: confirmar_pago_request.dart**

```dart
import 'package:json_annotation/json_annotation.dart';

part 'confirmar_pago_request.g.dart';

@JsonSerializable()
class ConfirmarPagoRequest {
  final bool confirmado;
  final String? notasAdmin;

  ConfirmarPagoRequest({required this.confirmado, this.notasAdmin});

  factory ConfirmarPagoRequest.fromJson(Map<String, dynamic> json) =>
      _$ConfirmarPagoRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ConfirmarPagoRequestToJson(this);
}
```

- [ ] **Step 6: confirmar_pago_request.g.dart**

```dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'confirmar_pago_request.dart';

ConfirmarPagoRequest _$ConfirmarPagoRequestFromJson(
        Map<String, dynamic> json) =>
    ConfirmarPagoRequest(
      confirmado: json['confirmado'] as bool,
      notasAdmin: json['notasAdmin'] as String?,
    );

Map<String, dynamic> _$ConfirmarPagoRequestToJson(
        ConfirmarPagoRequest instance) =>
    <String, dynamic>{
      'confirmado': instance.confirmado,
      'notasAdmin': instance.notasAdmin,
    };
```

- [ ] **Step 7: Commit**

```bash
git add lib/features/pagos/models/
git commit -m "feat(pagos): add Flutter request models with manual .g.dart files"
```

---

## Task 9: ApiConstants + CuotaService Flutter

**Files:**
- Modify: `lib/core/constants/api_constants.dart`
- Create: `lib/features/pagos/services/cuota_service.dart`

- [ ] **Step 1: Agregar constantes a api_constants.dart**

Agregar al final de la clase `ApiConstants`, antes del cierre `}`:

```dart
  // Cuotas / Pagos
  static const String cuotas = '$apiPrefix/cuotas';
  static const String misCuotas = '$apiPrefix/cuotas/mis-cuotas';
  static String cuotaDetalle(int id) => '$apiPrefix/cuotas/$id/detalle';
  static String reportarPago(int cuotaUsuarioId) => '$apiPrefix/cuotas/$cuotaUsuarioId/reportar';
  static String confirmarPago(int cuotaUsuarioId) => '$apiPrefix/cuotas/$cuotaUsuarioId/confirmar';
```

- [ ] **Step 2: cuota_service.dart**

```dart
import '../../../core/constants/api_constants.dart';
import '../../../shared/services/api_client.dart';
import '../models/confirmar_pago_request.dart';
import '../models/create_cuota_request.dart';
import '../models/cuota_response.dart';
import '../models/cuota_usuario_response.dart';
import '../models/reportar_pago_request.dart';

class CuotaService {
  final ApiClient apiClient;

  CuotaService({required this.apiClient});

  Future<List<CuotaResponse>> listarCuotas() async {
    final response = await apiClient.getList(ApiConstants.cuotas);
    return response
        .map((item) => CuotaResponse.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<CuotaResponse> crearCuota(CreateCuotaRequest request) async {
    final response = await apiClient.post(ApiConstants.cuotas, request.toJson());
    return CuotaResponse.fromJson(response);
  }

  Future<List<CuotaUsuarioResponse>> listarMisCuotas() async {
    final response = await apiClient.getList(ApiConstants.misCuotas);
    return response
        .map((item) => CuotaUsuarioResponse.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<CuotaUsuarioResponse>> obtenerDetalle(int cuotaId) async {
    final response = await apiClient.getList(ApiConstants.cuotaDetalle(cuotaId));
    return response
        .map((item) => CuotaUsuarioResponse.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<CuotaUsuarioResponse> reportarPago(
      int cuotaUsuarioId, ReportarPagoRequest request) async {
    final response = await apiClient.put(
        ApiConstants.reportarPago(cuotaUsuarioId), request.toJson());
    return CuotaUsuarioResponse.fromJson(response);
  }

  Future<CuotaUsuarioResponse> confirmarPago(
      int cuotaUsuarioId, ConfirmarPagoRequest request) async {
    final response = await apiClient.put(
        ApiConstants.confirmarPago(cuotaUsuarioId), request.toJson());
    return CuotaUsuarioResponse.fromJson(response);
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/core/constants/api_constants.dart \
        lib/features/pagos/services/cuota_service.dart
git commit -m "feat(pagos): add ApiConstants for cuotas and CuotaService Flutter"
```

---

## Task 10: CuotaProvider

**Files:**
- Create: `lib/features/pagos/providers/cuota_provider.dart`

- [ ] **Step 1: cuota_provider.dart**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/auth_provider.dart';
import '../models/confirmar_pago_request.dart';
import '../models/create_cuota_request.dart';
import '../models/cuota_response.dart';
import '../models/cuota_usuario_response.dart';
import '../models/reportar_pago_request.dart';
import '../services/cuota_service.dart';

class CuotaState {
  final List<CuotaResponse> cuotas;
  final List<CuotaUsuarioResponse> misCuotas;
  final bool isLoading;
  final String? error;

  CuotaState({
    this.cuotas = const [],
    this.misCuotas = const [],
    this.isLoading = false,
    this.error,
  });

  CuotaState copyWith({
    List<CuotaResponse>? cuotas,
    List<CuotaUsuarioResponse>? misCuotas,
    bool? isLoading,
    String? error,
  }) {
    return CuotaState(
      cuotas: cuotas ?? this.cuotas,
      misCuotas: misCuotas ?? this.misCuotas,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class CuotaNotifier extends StateNotifier<CuotaState> {
  final CuotaService _service;

  CuotaNotifier(this._service) : super(CuotaState());

  Future<void> cargarCuotas() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final cuotas = await _service.listarCuotas();
      state = state.copyWith(cuotas: cuotas, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> cargarMisCuotas() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final misCuotas = await _service.listarMisCuotas();
      state = state.copyWith(misCuotas: misCuotas, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<CuotaResponse?> crearCuota(CreateCuotaRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final cuota = await _service.crearCuota(request);
      state = state.copyWith(
        cuotas: [cuota, ...state.cuotas],
        isLoading: false,
      );
      return cuota;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<List<CuotaUsuarioResponse>> obtenerDetalle(int cuotaId) async {
    try {
      return await _service.obtenerDetalle(cuotaId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  Future<void> reportarPago(
      int cuotaUsuarioId, ReportarPagoRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updated = await _service.reportarPago(cuotaUsuarioId, request);
      state = state.copyWith(
        misCuotas: state.misCuotas
            .map((c) => c.id == cuotaUsuarioId ? updated : c)
            .toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> confirmarPago(
      int cuotaUsuarioId, ConfirmarPagoRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.confirmarPago(cuotaUsuarioId, request);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final cuotaServiceProvider = Provider<CuotaService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CuotaService(apiClient: apiClient);
});

final cuotaProvider = StateNotifierProvider<CuotaNotifier, CuotaState>((ref) {
  final service = ref.watch(cuotaServiceProvider);
  return CuotaNotifier(service);
});
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/pagos/providers/cuota_provider.dart
git commit -m "feat(pagos): add CuotaNotifier and cuotaProvider with Riverpod StateNotifier"
```

---

## Task 11: MisCuotasScreen (USUARIO)

**Files:**
- Create: `lib/features/pagos/screens/mis_cuotas_screen.dart`

- [ ] **Step 1: mis_cuotas_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/cuota_usuario_response.dart';
import '../providers/cuota_provider.dart';

class MisCuotasScreen extends ConsumerStatefulWidget {
  const MisCuotasScreen({super.key});

  @override
  ConsumerState<MisCuotasScreen> createState() => _MisCuotasScreenState();
}

class _MisCuotasScreenState extends ConsumerState<MisCuotasScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cuotaProvider.notifier).cargarMisCuotas();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cuotaProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mis Cuotas')),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(state.error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () =>
                            ref.read(cuotaProvider.notifier).cargarMisCuotas(),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : state.misCuotas.isEmpty
                  ? const Center(child: Text('No tienes cuotas asignadas.'))
                  : RefreshIndicator(
                      onRefresh: () =>
                          ref.read(cuotaProvider.notifier).cargarMisCuotas(),
                      child: ListView.builder(
                        itemCount: state.misCuotas.length,
                        itemBuilder: (context, index) {
                          final cuota = state.misCuotas[index];
                          return _CuotaUsuarioTile(cuota: cuota);
                        },
                      ),
                    ),
    );
  }
}

class _CuotaUsuarioTile extends StatelessWidget {
  final CuotaUsuarioResponse cuota;

  const _CuotaUsuarioTile({required this.cuota});

  Color _estadoColor(EstadoPago estado) => switch (estado) {
        EstadoPago.pendiente => Colors.grey,
        EstadoPago.reportado => Colors.orange,
        EstadoPago.confirmado => Colors.green,
        EstadoPago.rechazado => Colors.red,
      };

  String _estadoLabel(EstadoPago estado) => switch (estado) {
        EstadoPago.pendiente => 'PENDIENTE',
        EstadoPago.reportado => 'REPORTADO',
        EstadoPago.confirmado => 'CONFIRMADO',
        EstadoPago.rechazado => 'RECHAZADO',
      };

  @override
  Widget build(BuildContext context) {
    final canReport = cuota.estado == EstadoPago.pendiente ||
        cuota.estado == EstadoPago.rechazado;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        title: Text(cuota.concepto,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Monto: \$${cuota.monto.toStringAsFixed(2)}'),
            Text('Vence: ${cuota.fechaVencimiento}'),
            if (cuota.referenciaPago != null)
              Text('Ref: ${cuota.referenciaPago}'),
            if (cuota.notasAdmin != null)
              Text('Admin: ${cuota.notasAdmin}',
                  style: const TextStyle(color: Colors.red)),
          ],
        ),
        trailing: Chip(
          label: Text(_estadoLabel(cuota.estado),
              style: const TextStyle(color: Colors.white, fontSize: 11)),
          backgroundColor: _estadoColor(cuota.estado),
        ),
        onTap: canReport
            ? () => context.push('/home/cuotas/${cuota.id}/reportar')
            : null,
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/pagos/screens/mis_cuotas_screen.dart
git commit -m "feat(pagos): add MisCuotasScreen for USUARIO role"
```

---

## Task 12: ReportarPagoScreen (USUARIO)

**Files:**
- Create: `lib/features/pagos/screens/reportar_pago_screen.dart`

- [ ] **Step 1: reportar_pago_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/cuota_usuario_response.dart';
import '../models/reportar_pago_request.dart';
import '../providers/cuota_provider.dart';

class ReportarPagoScreen extends ConsumerStatefulWidget {
  final int cuotaUsuarioId;

  const ReportarPagoScreen({super.key, required this.cuotaUsuarioId});

  @override
  ConsumerState<ReportarPagoScreen> createState() => _ReportarPagoScreenState();
}

class _ReportarPagoScreenState extends ConsumerState<ReportarPagoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _referenciaCtrl = TextEditingController();
  final _notasCtrl = TextEditingController();

  CuotaUsuarioResponse? _cuota;

  @override
  void initState() {
    super.initState();
    final state = ref.read(cuotaProvider);
    _cuota = state.misCuotas.where((c) => c.id == widget.cuotaUsuarioId).firstOrNull;
  }

  @override
  void dispose() {
    _referenciaCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final request = ReportarPagoRequest(
      referenciaPago: _referenciaCtrl.text.trim(),
      notasUsuario: _notasCtrl.text.trim().isEmpty ? null : _notasCtrl.text.trim(),
    );
    await ref
        .read(cuotaProvider.notifier)
        .reportarPago(widget.cuotaUsuarioId, request);
    if (mounted) {
      final error = ref.read(cuotaProvider).error;
      if (error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pago reportado exitosamente')),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
        ref.read(cuotaProvider.notifier).clearError();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cuotaProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Reportar Pago')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (_cuota != null) ...[
                Text(_cuota!.concepto,
                    style: Theme.of(context).textTheme.titleLarge),
                Text('Monto: \$${_cuota!.monto.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodyLarge),
                Text('Vence: ${_cuota!.fechaVencimiento}'),
                const SizedBox(height: 16),
                if (_cuota!.estado == EstadoPago.rechazado &&
                    _cuota!.notasAdmin != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(color: Colors.red),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Motivo de rechazo: ${_cuota!.notasAdmin}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
              ],
              TextFormField(
                controller: _referenciaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Referencia de pago *',
                  hintText: 'Número de transferencia o comprobante',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notasCtrl,
                decoration: const InputDecoration(
                  labelText: 'Notas (opcional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: state.isLoading ? null : _submit,
                child: state.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Reportar Pago'),
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
git add lib/features/pagos/screens/reportar_pago_screen.dart
git commit -m "feat(pagos): add ReportarPagoScreen — usuario reports payment with reference and notes"
```

---

## Task 13: CuotasAdminScreen (ADMIN)

**Files:**
- Create: `lib/features/pagos/screens/cuotas_admin_screen.dart`

- [ ] **Step 1: cuotas_admin_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/cuota_response.dart';
import '../providers/cuota_provider.dart';

class CuotasAdminScreen extends ConsumerStatefulWidget {
  const CuotasAdminScreen({super.key});

  @override
  ConsumerState<CuotasAdminScreen> createState() => _CuotasAdminScreenState();
}

class _CuotasAdminScreenState extends ConsumerState<CuotasAdminScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cuotaProvider.notifier).cargarCuotas();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cuotaProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Cuotas')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/home/cuotas/nueva'),
        child: const Icon(Icons.add),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(state.error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () =>
                            ref.read(cuotaProvider.notifier).cargarCuotas(),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : state.cuotas.isEmpty
                  ? const Center(child: Text('No hay cuotas registradas.'))
                  : RefreshIndicator(
                      onRefresh: () =>
                          ref.read(cuotaProvider.notifier).cargarCuotas(),
                      child: ListView.builder(
                        itemCount: state.cuotas.length,
                        itemBuilder: (context, index) {
                          final cuota = state.cuotas[index];
                          return _CuotaTile(cuota: cuota);
                        },
                      ),
                    ),
    );
  }
}

class _CuotaTile extends StatelessWidget {
  final CuotaResponse cuota;

  const _CuotaTile({required this.cuota});

  @override
  Widget build(BuildContext context) {
    final total = cuota.totalResidentes;
    final confirmados = cuota.totalConfirmados;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        title: Text(cuota.concepto,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${cuota.tipo == TipoCuota.mensual ? "Mensual" : "Extraordinaria"}'
              '${cuota.mes != null ? " · ${cuota.mes}" : ""}',
            ),
            Text('Monto: \$${cuota.monto.toStringAsFixed(2)}'),
            Text('Vence: ${cuota.fechaVencimiento}'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$confirmados/$total',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            const Text('confirm.', style: TextStyle(fontSize: 11)),
          ],
        ),
        onTap: () => context.push('/home/cuotas/${cuota.id}/detalle'),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/pagos/screens/cuotas_admin_screen.dart
git commit -m "feat(pagos): add CuotasAdminScreen — list with progress badge and FAB to create"
```

---

## Task 14: CrearCuotaScreen (ADMIN)

**Files:**
- Create: `lib/features/pagos/screens/crear_cuota_screen.dart`

- [ ] **Step 1: crear_cuota_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../features/usuarios/providers/usuario_admin_provider.dart';
import '../models/create_cuota_request.dart';
import '../models/cuota_response.dart';
import '../providers/cuota_provider.dart';

class CrearCuotaScreen extends ConsumerStatefulWidget {
  const CrearCuotaScreen({super.key});

  @override
  ConsumerState<CrearCuotaScreen> createState() => _CrearCuotaScreenState();
}

class _CrearCuotaScreenState extends ConsumerState<CrearCuotaScreen> {
  final _formKey = GlobalKey<FormState>();
  TipoCuota _tipo = TipoCuota.mensual;
  final _conceptoCtrl = TextEditingController();
  final _montoCtrl = TextEditingController();
  final _mesCtrl = TextEditingController();
  DateTime? _fechaVencimiento;
  final Set<int> _selectedUsuarioIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(usuarioAdminProvider.notifier).cargarUsuarios();
    });
  }

  @override
  void dispose() {
    _conceptoCtrl.dispose();
    _montoCtrl.dispose();
    _mesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFechaVencimiento() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _fechaVencimiento = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fechaVencimiento == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona la fecha de vencimiento')),
      );
      return;
    }
    if (_tipo == TipoCuota.extraordinaria && _selectedUsuarioIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos un residente')),
      );
      return;
    }

    final fechaStr =
        '${_fechaVencimiento!.year}-${_fechaVencimiento!.month.toString().padLeft(2, '0')}-${_fechaVencimiento!.day.toString().padLeft(2, '0')}';

    final request = CreateCuotaRequest(
      tipo: _tipo,
      concepto: _conceptoCtrl.text.trim(),
      monto: double.parse(_montoCtrl.text.trim()),
      mes: _tipo == TipoCuota.mensual ? _mesCtrl.text.trim() : null,
      fechaVencimiento: fechaStr,
      usuarioIds: _tipo == TipoCuota.extraordinaria
          ? _selectedUsuarioIds.toList()
          : null,
    );

    final cuota = await ref.read(cuotaProvider.notifier).crearCuota(request);
    if (mounted) {
      if (cuota != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cuota creada exitosamente')),
        );
        context.pop();
      } else {
        final error = ref.read(cuotaProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(error ?? 'Error al crear cuota'),
              backgroundColor: Colors.red),
        );
        ref.read(cuotaProvider.notifier).clearError();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cuotaState = ref.watch(cuotaProvider);
    final usuarioState = ref.watch(usuarioAdminProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Nueva Cuota')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<TipoCuota>(
                value: _tipo,
                decoration: const InputDecoration(
                  labelText: 'Tipo de cuota',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                      value: TipoCuota.mensual, child: Text('Mensual')),
                  DropdownMenuItem(
                      value: TipoCuota.extraordinaria,
                      child: Text('Extraordinaria')),
                ],
                onChanged: (v) => setState(() => _tipo = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _conceptoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Concepto *',
                  hintText: 'Ej: Mantenimiento Enero 2025',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _montoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Monto *',
                  prefixText: '\$',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Campo requerido';
                  final n = double.tryParse(v.trim());
                  if (n == null || n <= 0) return 'Ingresa un monto válido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              if (_tipo == TipoCuota.mensual) ...[
                TextFormField(
                  controller: _mesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Mes (YYYY-MM) *',
                    hintText: 'Ej: 2025-01',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Campo requerido';
                    final regex = RegExp(r'^\d{4}-\d{2}$');
                    if (!regex.hasMatch(v.trim())) return 'Formato: YYYY-MM';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_fechaVencimiento == null
                    ? 'Fecha de vencimiento *'
                    : 'Vence: ${_fechaVencimiento!.day}/${_fechaVencimiento!.month}/${_fechaVencimiento!.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickFechaVencimiento,
              ),
              if (_tipo == TipoCuota.extraordinaria) ...[
                const Divider(),
                const Text('Selecciona destinatarios:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                if (usuarioState.isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  ...usuarioState.usuarios
                      .where((u) => u.rol == 'USUARIO' && u.activo)
                      .map((u) => CheckboxListTile(
                            title: Text(u.nombreCompleto ?? u.username),
                            subtitle: Text(u.unidadHabitacional ?? ''),
                            value: _selectedUsuarioIds.contains(u.id),
                            onChanged: (checked) {
                              setState(() {
                                if (checked == true) {
                                  _selectedUsuarioIds.add(u.id);
                                } else {
                                  _selectedUsuarioIds.remove(u.id);
                                }
                              });
                            },
                          )),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: cuotaState.isLoading ? null : _submit,
                child: cuotaState.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Crear Cuota'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verificar que UsuarioAdmin tenga los campos `rol`, `activo`, `nombreCompleto`, `unidadHabitacional`, `username`**

Leer `lib/features/usuarios/models/usuario_admin.dart` y confirmar que esos campos existen. Si el campo `rol` es de tipo enum, ajustar el where en la pantalla para comparar contra el enum (ej. `u.rol == Rol.usuario`). Si es String, queda como está.

- [ ] **Step 3: Commit**

```bash
git add lib/features/pagos/screens/crear_cuota_screen.dart
git commit -m "feat(pagos): add CrearCuotaScreen — ADMIN creates MENSUAL or EXTRAORDINARIA cuota"
```

---

## Task 15: DetalleCuotaScreen (ADMIN)

**Files:**
- Create: `lib/features/pagos/screens/detalle_cuota_screen.dart`

- [ ] **Step 1: detalle_cuota_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/confirmar_pago_request.dart';
import '../models/cuota_usuario_response.dart';
import '../providers/cuota_provider.dart';

class DetalleCuotaScreen extends ConsumerStatefulWidget {
  final int cuotaId;

  const DetalleCuotaScreen({super.key, required this.cuotaId});

  @override
  ConsumerState<DetalleCuotaScreen> createState() => _DetalleCuotaScreenState();
}

class _DetalleCuotaScreenState extends ConsumerState<DetalleCuotaScreen> {
  List<CuotaUsuarioResponse> _registros = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargarDetalle();
  }

  Future<void> _cargarDetalle() async {
    setState(() => _loading = true);
    final registros =
        await ref.read(cuotaProvider.notifier).obtenerDetalle(widget.cuotaId);
    setState(() {
      _registros = registros;
      _loading = false;
    });
  }

  Future<void> _confirmar(int cuotaUsuarioId) async {
    await ref.read(cuotaProvider.notifier).confirmarPago(
          cuotaUsuarioId,
          const ConfirmarPagoRequest(confirmado: true),
        );
    _cargarDetalle();
  }

  Future<void> _rechazar(int cuotaUsuarioId) async {
    final notasCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rechazar pago'),
        content: TextField(
          controller: notasCtrl,
          decoration: const InputDecoration(
            labelText: 'Motivo del rechazo *',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (notasCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(cuotaProvider.notifier).confirmarPago(
            cuotaUsuarioId,
            ConfirmarPagoRequest(
                confirmado: false, notasAdmin: notasCtrl.text.trim()),
          );
      _cargarDetalle();
    }
  }

  Color _estadoColor(EstadoPago estado) => switch (estado) {
        EstadoPago.pendiente => Colors.grey,
        EstadoPago.reportado => Colors.orange,
        EstadoPago.confirmado => Colors.green,
        EstadoPago.rechazado => Colors.red,
      };

  String _estadoLabel(EstadoPago estado) => switch (estado) {
        EstadoPago.pendiente => 'PENDIENTE',
        EstadoPago.reportado => 'REPORTADO',
        EstadoPago.confirmado => 'CONFIRMADO',
        EstadoPago.rechazado => 'RECHAZADO',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Cuota'),
        actions: [
          IconButton(
              onPressed: _cargarDetalle, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _registros.isEmpty
              ? const Center(child: Text('No hay residentes asignados.'))
              : ListView.builder(
                  itemCount: _registros.length,
                  itemBuilder: (context, index) {
                    final r = _registros[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(r.usuarioNombre,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                Chip(
                                  label: Text(_estadoLabel(r.estado),
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 11)),
                                  backgroundColor: _estadoColor(r.estado),
                                ),
                              ],
                            ),
                            if (r.unidadHabitacional != null)
                              Text('Unidad: ${r.unidadHabitacional}'),
                            if (r.referenciaPago != null)
                              Text('Ref: ${r.referenciaPago}'),
                            if (r.notasUsuario != null)
                              Text('Nota usuario: ${r.notasUsuario}'),
                            if (r.notasAdmin != null)
                              Text('Nota admin: ${r.notasAdmin}',
                                  style: const TextStyle(color: Colors.red)),
                            if (r.estado == EstadoPago.reportado)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () => _rechazar(r.id),
                                    style: TextButton.styleFrom(
                                        foregroundColor: Colors.red),
                                    child: const Text('Rechazar'),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () => _confirmar(r.id),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green),
                                    child: const Text('Confirmar'),
                                  ),
                                ],
                              ),
                          ],
                        ),
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
git add lib/features/pagos/screens/detalle_cuota_screen.dart
git commit -m "feat(pagos): add DetalleCuotaScreen — ADMIN confirms or rejects reported payments"
```

---

## Task 16: Navegación — MainScaffold + GoRouter

**Files:**
- Modify: `lib/shared/widgets/main_scaffold.dart`
- Modify: `lib/core/routes/app_router.dart`

- [ ] **Step 1: Actualizar main_scaffold.dart**

Agregar imports de las nuevas pantallas y agregar tab "Cuotas" a USUARIO y ADMIN:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/pagos/providers/cuota_provider.dart';
import '../../features/pagos/screens/cuotas_admin_screen.dart';
import '../../features/pagos/screens/mis_cuotas_screen.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  void _loadInitialData() {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    final visitaNotifier = ref.read(visitaProvider.notifier);
    final cuotaNotifier = ref.read(cuotaProvider.notifier);
    switch (user.rol) {
      case Rol.usuario:
        visitaNotifier.cargarMisVisitas();
        cuotaNotifier.cargarMisCuotas();
      case Rol.guardia:
        visitaNotifier.cargarTodasVisitas();
      case Rol.admin:
      case Rol.superadmin:
        visitaNotifier.cargarTodasVisitas();
        cuotaNotifier.cargarCuotas();
    }
  }

  List<Widget> _buildScreens(Rol rol) {
    return switch (rol) {
      Rol.usuario => [
          const InicioUsuarioScreen(),
          const MisVisitasScreen(),
          const CrearVisitaScreen(),
          const MisCuotasScreen(),
          const PerfilScreen(),
        ],
      Rol.guardia => [
          const EscanearQrScreen(),
          const VisitasAdminScreen(filterToday: true),
          const VisitasAdminScreen(filterToday: false),
          const PerfilScreen(),
        ],
      Rol.admin || Rol.superadmin => [
          const DashboardAdminScreen(),
          const VisitasAdminScreen(filterToday: false),
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
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Cuotas'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Perfil'),
        ],
      Rol.guardia => const [
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: 'Escanear'),
          BottomNavigationBarItem(icon: Icon(Icons.today), label: 'Hoy'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Historial'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Perfil'),
        ],
      Rol.admin || Rol.superadmin => const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Visitas'),
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

Agregar imports y rutas:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/pagos/screens/crear_cuota_screen.dart';
import '../../features/pagos/screens/detalle_cuota_screen.dart';
import '../../features/pagos/screens/reportar_pago_screen.dart';
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
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
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
git commit -m "feat(pagos): wire navigation — add Cuotas tab to USUARIO and ADMIN, add GoRouter routes"
```

---

## Task 17: Verificación final del modelo UsuarioAdmin

**Context:** `CrearCuotaScreen` usa `usuarioState.usuarios` y accede a `.rol`, `.activo`, `.nombreCompleto`, `.unidadHabitacional`, `.username`. Esto debe coincidir con el modelo real.

- [ ] **Step 1: Leer el modelo UsuarioAdmin**

Abrir `lib/features/usuarios/models/usuario_admin.dart` y verificar los nombres exactos de los campos.

- [ ] **Step 2: Si el campo `rol` es un enum (ej. `UsuarioRol`)**

Cambiar en `crear_cuota_screen.dart`:
```dart
.where((u) => u.rol == 'USUARIO' && u.activo)
```
por:
```dart
.where((u) => u.rol == UsuarioRol.usuario && u.activo == true)
```

Agregar el import necesario para el enum.

- [ ] **Step 3: Verificar que `usuarioAdminProvider` expone `.usuarios`**

Abrir `lib/features/usuarios/providers/usuario_admin_provider.dart` y confirmar que el state tiene `List<UsuarioAdmin> usuarios`. Si el campo tiene otro nombre, ajustar en `crear_cuota_screen.dart`.

- [ ] **Step 4: Commit si hubo ajustes**

```bash
git add lib/features/pagos/screens/crear_cuota_screen.dart
git commit -m "fix(pagos): align CrearCuotaScreen with actual UsuarioAdmin model fields"
```

---

## Self-Review

### Spec Coverage Check

| Requisito spec | Task que lo implementa |
|---|---|
| Tabla `cuotas` y `cuota_usuarios` con enums PostgreSQL | Task 1 |
| `UNIQUE(cuota_id, usuario_id)` | Task 1 |
| Enums Java `TipoCuota`, `EstadoPago` | Task 2 |
| Entidades JPA `Cuota`, `CuotaUsuario` | Task 2 |
| `GET /api/cuotas` — lista con resumen | Tasks 3-6 |
| `POST /api/cuotas` — crear MENSUAL o EXTRAORDINARIA | Tasks 3-6 |
| `GET /api/cuotas/mis-cuotas` | Tasks 3-6 |
| `GET /api/cuotas/{id}/detalle` | Tasks 3-6 |
| `PUT /{id}/reportar` | Tasks 3-6 |
| `PUT /{id}/confirmar` | Tasks 3-6 |
| Regla: MENSUAL → todos los USUARIO activos del condominio | Task 5 (CuotaService) |
| Regla: EXTRAORDINARIA → lista de usuarioIds dada | Task 5 |
| Regla: REPORTADO → solo desde PENDIENTE o RECHAZADO | Task 5 |
| Regla: rechazado puede volver a reportar | Task 5 (actualiza el registro existente) |
| Regla: notas_admin requerido al rechazar | Task 5 + Task 4 (ConfirmarPagoRequest) |
| Flutter models + .g.dart manuales | Tasks 7-8 |
| CuotaService Flutter | Task 9 |
| CuotaProvider Riverpod | Task 10 |
| MisCuotasScreen (USUARIO) con badges de estado | Task 11 |
| ReportarPagoScreen con nota de rechazo en rojo | Task 12 |
| CuotasAdminScreen con badge progreso | Task 13 |
| CrearCuotaScreen con tipo/concepto/monto/mes/fecha/checkboxes | Task 14 |
| DetalleCuotaScreen con botones Confirmar/Rechazar | Task 15 |
| Tab "Cuotas" en USUARIO y ADMIN | Task 16 |
| Rutas GoRouter para cuotas | Task 16 |
| ApiConstants nuevos | Task 9 |

### Notas de consistencia

- `TipoCuota` se define en `cuota_response.dart` y se importa en `create_cuota_request.dart` — una sola fuente de verdad.
- `EstadoPago` se define en `cuota_usuario_response.dart` — todas las pantallas importan desde ahí.
- `ConfirmarPagoRequest` usa `const` constructor en `DetalleCuotaScreen` para el caso `confirmado: true` — válido porque no tiene campos con estado mutable.
