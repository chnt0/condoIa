# Áreas Comunes + Reservaciones — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implementar gestión de áreas comunes (CRUD por ADMIN) y reservaciones de bloques horarios (USUARIO reserva, valida conflictos/morosos/límite mensual, puede cancelar).

**Architecture:** Backend primero (V7 migration → entities → repos → DTOs → AreaComunService → ReservacionService con validaciones cruzadas → controllers), luego Flutter (models → services → providers → 3 screens → navegación). Los bloques de disponibilidad se generan dinámicamente en el service. `ReservacionService` importa `CuotaUsuarioRepository` de `com.condos.pago` para validar morosos.

**Tech Stack:** Spring Boot 3 + JPA + Flyway + PostgreSQL | Flutter + Riverpod StateNotifier + GoRouter + DefaultTabController + json_annotation (sin build_runner)

---

## File Map

### Backend — nuevos archivos

```
backend/src/main/resources/db/migration/
  V7__create_areas_reservaciones_tables.sql

backend/src/main/java/com/condos/area/
  model/AreaComun.java
  repository/AreaComunRepository.java
  dto/CreateAreaComunRequest.java
  dto/AreaComunResponse.java
  dto/BloqueDisponibilidadResponse.java
  service/AreaComunService.java
  controller/AreaComunController.java

backend/src/main/java/com/condos/reservacion/
  model/EstadoReservacion.java
  model/Reservacion.java
  repository/ReservacionRepository.java
  dto/CreateReservacionRequest.java
  dto/ReservacionResponse.java
  service/ReservacionService.java
  controller/ReservacionController.java
```

### Backend — archivos modificados

```
com/condos/pago/repository/CuotaUsuarioRepository.java
  + existsByUsuarioIdAndEstadoAndCuotaFechaVencimientoBefore(Long, EstadoPago, LocalDate)
```

### Flutter — nuevos archivos

```
lib/features/areas/
  models/
    area_comun.dart + .g.dart
    create_area_comun_request.dart + .g.dart
    bloque_disponibilidad.dart + .g.dart
    reservacion.dart + .g.dart
    create_reservacion_request.dart + .g.dart
  services/
    area_comun_service.dart
    reservacion_service.dart
  providers/
    area_comun_provider.dart
    reservacion_provider.dart
  screens/
    areas_screen.dart
    crear_editar_area_screen.dart
    disponibilidad_screen.dart
```

### Flutter — archivos modificados

```
lib/core/constants/api_constants.dart    ← 7 nuevas constantes
lib/core/routes/app_router.dart          ← 3 nuevas rutas
lib/shared/widgets/main_scaffold.dart    ← tab Áreas para USUARIO y ADMIN
```

---

## Task 1: DB Migration V7

**Files:**
- Create: `backend/src/main/resources/db/migration/V7__create_areas_reservaciones_tables.sql`

- [ ] **Step 1: Escribir la migración**

```sql
-- V7__create_areas_reservaciones_tables.sql

CREATE TYPE estado_reservacion AS ENUM ('ACTIVA', 'CANCELADA');

CREATE TABLE areas_comunes (
    id                          BIGSERIAL PRIMARY KEY,
    condominio_id               BIGINT NOT NULL REFERENCES condominios(id),
    nombre                      VARCHAR(100) NOT NULL,
    descripcion                 TEXT,
    capacidad                   INT NOT NULL,
    horario_inicio              TIME NOT NULL,
    horario_fin                 TIME NOT NULL,
    duracion_bloque_minutos     INT NOT NULL,
    max_reservas_mes_por_usuario INT NOT NULL,
    anticipacion_minima_horas   INT NOT NULL,
    anticipacion_maxima_dias    INT NOT NULL,
    activa                      BOOLEAN NOT NULL DEFAULT true,
    created_at                  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE reservaciones (
    id               BIGSERIAL PRIMARY KEY,
    area_comun_id    BIGINT NOT NULL REFERENCES areas_comunes(id),
    usuario_id       BIGINT NOT NULL REFERENCES usuarios(id),
    fecha_hora_inicio TIMESTAMP NOT NULL,
    fecha_hora_fin   TIMESTAMP NOT NULL,
    estado           estado_reservacion NOT NULL DEFAULT 'ACTIVA',
    created_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_areas_comunes_condominio ON areas_comunes(condominio_id);
CREATE INDEX idx_reservaciones_area ON reservaciones(area_comun_id);
CREATE INDEX idx_reservaciones_usuario ON reservaciones(usuario_id);
CREATE INDEX idx_reservaciones_estado ON reservaciones(estado);
CREATE INDEX idx_reservaciones_inicio ON reservaciones(fecha_hora_inicio);

CREATE TRIGGER update_areas_comunes_updated_at
    BEFORE UPDATE ON areas_comunes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

- [ ] **Step 2: Commit**

```bash
git add backend/src/main/resources/db/migration/V7__create_areas_reservaciones_tables.sql
git commit -m "feat(areas): add V7 migration — areas_comunes and reservaciones tables"
```

---

## Task 2: Java Entities

**Files:**
- Create: `backend/src/main/java/com/condos/area/model/AreaComun.java`
- Create: `backend/src/main/java/com/condos/reservacion/model/EstadoReservacion.java`
- Create: `backend/src/main/java/com/condos/reservacion/model/Reservacion.java`

- [ ] **Step 1: AreaComun.java**

```java
package com.condos.area.model;

import com.condos.condominio.model.Condominio;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;
import lombok.ToString;

import java.time.LocalDateTime;
import java.time.LocalTime;

@Entity
@Table(name = "areas_comunes")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@ToString(exclude = "condominio")
@EqualsAndHashCode(exclude = "condominio")
public class AreaComun {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "condominio_id", nullable = false)
    private Condominio condominio;

    @Column(nullable = false, length = 100)
    private String nombre;

    @Column(columnDefinition = "TEXT")
    private String descripcion;

    @Column(nullable = false)
    private int capacidad;

    @Column(name = "horario_inicio", nullable = false)
    private LocalTime horarioInicio;

    @Column(name = "horario_fin", nullable = false)
    private LocalTime horarioFin;

    @Column(name = "duracion_bloque_minutos", nullable = false)
    private int duracionBloqueMinutos;

    @Column(name = "max_reservas_mes_por_usuario", nullable = false)
    private int maxReservasMesPorUsuario;

    @Column(name = "anticipacion_minima_horas", nullable = false)
    private int anticipacionMinimaHoras;

    @Column(name = "anticipacion_maxima_dias", nullable = false)
    private int anticipacionMaximaDias;

    @Column(nullable = false)
    private boolean activa = true;

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

- [ ] **Step 2: EstadoReservacion.java**

```java
package com.condos.reservacion.model;

public enum EstadoReservacion {
    ACTIVA,
    CANCELADA
}
```

- [ ] **Step 3: Reservacion.java**

```java
package com.condos.reservacion.model;

import com.condos.area.model.AreaComun;
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
@Table(name = "reservaciones")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@ToString(exclude = {"areaComun", "usuario"})
@EqualsAndHashCode(exclude = {"areaComun", "usuario"})
public class Reservacion {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "area_comun_id", nullable = false)
    private AreaComun areaComun;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "usuario_id", nullable = false)
    private Usuario usuario;

    @Column(name = "fecha_hora_inicio", nullable = false)
    private LocalDateTime fechaHoraInicio;

    @Column(name = "fecha_hora_fin", nullable = false)
    private LocalDateTime fechaHoraFin;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private EstadoReservacion estado;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        if (estado == null) estado = EstadoReservacion.ACTIVA;
    }
}
```

- [ ] **Step 4: Commit**

```bash
git add backend/src/main/java/com/condos/area/ \
        backend/src/main/java/com/condos/reservacion/
git commit -m "feat(areas): add AreaComun entity, EstadoReservacion enum, Reservacion entity"
```

---

## Task 3: Repositories

**Files:**
- Create: `backend/src/main/java/com/condos/area/repository/AreaComunRepository.java`
- Create: `backend/src/main/java/com/condos/reservacion/repository/ReservacionRepository.java`
- Modify: `backend/src/main/java/com/condos/pago/repository/CuotaUsuarioRepository.java`

- [ ] **Step 1: AreaComunRepository.java**

```java
package com.condos.area.repository;

import com.condos.area.model.AreaComun;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface AreaComunRepository extends JpaRepository<AreaComun, Long> {
    List<AreaComun> findByCondominioIdOrderByNombreAsc(Long condominioId);
    List<AreaComun> findByCondominioIdAndActivaOrderByNombreAsc(Long condominioId, boolean activa);
}
```

- [ ] **Step 2: ReservacionRepository.java**

```java
package com.condos.reservacion.repository;

import com.condos.reservacion.model.EstadoReservacion;
import com.condos.reservacion.model.Reservacion;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface ReservacionRepository extends JpaRepository<Reservacion, Long> {
    List<Reservacion> findByAreaComunIdOrderByFechaHoraInicioAsc(Long areaComunId);
    List<Reservacion> findByAreaComunCondominioIdOrderByFechaHoraInicioDesc(Long condominioId);
    List<Reservacion> findByUsuarioIdOrderByFechaHoraInicioDesc(Long usuarioId);

    boolean existsByAreaComunIdAndFechaHoraInicioAndEstado(
            Long areaComunId, LocalDateTime fechaHoraInicio, EstadoReservacion estado);

    long countByAreaComunIdAndUsuarioIdAndEstadoAndFechaHoraInicioGreaterThanEqualAndFechaHoraInicioLessThan(
            Long areaComunId, Long usuarioId, EstadoReservacion estado,
            LocalDateTime inicioMes, LocalDateTime finMes);
}
```

- [ ] **Step 3: Agregar método a CuotaUsuarioRepository**

En `backend/src/main/java/com/condos/pago/repository/CuotaUsuarioRepository.java`, agregar:

```java
import com.condos.pago.model.EstadoPago;
import java.time.LocalDate;

boolean existsByUsuarioIdAndEstadoAndCuotaFechaVencimientoBefore(
        Long usuarioId, EstadoPago estado, LocalDate fecha);
```

El archivo completo queda:

```java
package com.condos.pago.repository;

import com.condos.pago.model.CuotaUsuario;
import com.condos.pago.model.EstadoPago;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;

@Repository
public interface CuotaUsuarioRepository extends JpaRepository<CuotaUsuario, Long> {
    List<CuotaUsuario> findByCuotaId(Long cuotaId);
    List<CuotaUsuario> findByUsuarioIdOrderByCreatedAtDesc(Long usuarioId);
    boolean existsByUsuarioIdAndEstadoAndCuotaFechaVencimientoBefore(
            Long usuarioId, EstadoPago estado, LocalDate fecha);
}
```

- [ ] **Step 4: Commit**

```bash
git add backend/src/main/java/com/condos/area/repository/ \
        backend/src/main/java/com/condos/reservacion/repository/ \
        backend/src/main/java/com/condos/pago/repository/CuotaUsuarioRepository.java
git commit -m "feat(areas): add AreaComunRepository, ReservacionRepository; extend CuotaUsuarioRepository"
```

---

## Task 4: DTOs

**Files:**
- Create: `backend/src/main/java/com/condos/area/dto/CreateAreaComunRequest.java`
- Create: `backend/src/main/java/com/condos/area/dto/AreaComunResponse.java`
- Create: `backend/src/main/java/com/condos/area/dto/BloqueDisponibilidadResponse.java`
- Create: `backend/src/main/java/com/condos/reservacion/dto/CreateReservacionRequest.java`
- Create: `backend/src/main/java/com/condos/reservacion/dto/ReservacionResponse.java`

- [ ] **Step 1: CreateAreaComunRequest.java**

```java
package com.condos.area.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class CreateAreaComunRequest {

    @NotBlank
    private String nombre;

    private String descripcion;

    @NotNull
    @Min(1)
    private Integer capacidad;

    @NotBlank
    private String horarioInicio;

    @NotBlank
    private String horarioFin;

    @NotNull
    @Min(15)
    private Integer duracionBloqueMinutos;

    @NotNull
    @Min(1)
    private Integer maxReservasMesPorUsuario;

    @NotNull
    @Min(0)
    private Integer anticipacionMinimaHoras;

    @NotNull
    @Min(1)
    private Integer anticipacionMaximaDias;

    private boolean activa = true;
}
```

- [ ] **Step 2: AreaComunResponse.java**

```java
package com.condos.area.dto;

import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Builder
public class AreaComunResponse {
    private Long id;
    private String nombre;
    private String descripcion;
    private int capacidad;
    private String horarioInicio;
    private String horarioFin;
    private int duracionBloqueMinutos;
    private int maxReservasMesPorUsuario;
    private int anticipacionMinimaHoras;
    private int anticipacionMaximaDias;
    private boolean activa;
    private LocalDateTime createdAt;
}
```

- [ ] **Step 3: BloqueDisponibilidadResponse.java**

```java
package com.condos.area.dto;

import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Builder
public class BloqueDisponibilidadResponse {
    private LocalDateTime fechaHoraInicio;
    private LocalDateTime fechaHoraFin;
    private boolean disponible;
}
```

- [ ] **Step 4: CreateReservacionRequest.java**

```java
package com.condos.reservacion.dto;

import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.time.LocalDateTime;

@Data
public class CreateReservacionRequest {

    @NotNull
    private Long areaComunId;

    @NotNull
    private LocalDateTime fechaHoraInicio;
}
```

- [ ] **Step 5: ReservacionResponse.java**

```java
package com.condos.reservacion.dto;

import com.condos.reservacion.model.EstadoReservacion;
import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Builder
public class ReservacionResponse {
    private Long id;
    private Long areaComunId;
    private String areaComunNombre;
    private Long usuarioId;
    private String usuarioNombre;
    private LocalDateTime fechaHoraInicio;
    private LocalDateTime fechaHoraFin;
    private EstadoReservacion estado;
    private LocalDateTime createdAt;
}
```

- [ ] **Step 6: Commit**

```bash
git add backend/src/main/java/com/condos/area/dto/ \
        backend/src/main/java/com/condos/reservacion/dto/
git commit -m "feat(areas): add all DTOs — AreaComun, BloqueDisponibilidad, Reservacion"
```

---

## Task 5: AreaComunService

**Files:**
- Create: `backend/src/main/java/com/condos/area/service/AreaComunService.java`

- [ ] **Step 1: AreaComunService.java**

```java
package com.condos.area.service;

import com.condos.area.dto.AreaComunResponse;
import com.condos.area.dto.BloqueDisponibilidadResponse;
import com.condos.area.dto.CreateAreaComunRequest;
import com.condos.area.model.AreaComun;
import com.condos.area.repository.AreaComunRepository;
import com.condos.common.exceptions.ResourceNotFoundException;
import com.condos.common.utils.TenantContext;
import com.condos.condominio.model.Condominio;
import com.condos.condominio.repository.CondominioRepository;
import com.condos.reservacion.model.EstadoReservacion;
import com.condos.reservacion.repository.ReservacionRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class AreaComunService {

    private final AreaComunRepository areaComunRepository;
    private final CondominioRepository condominioRepository;
    private final ReservacionRepository reservacionRepository;

    private static final DateTimeFormatter TIME_FORMATTER = DateTimeFormatter.ofPattern("HH:mm");

    @Transactional(readOnly = true)
    public List<AreaComunResponse> listarAreas(boolean soloActivas) {
        Long condominioId = TenantContext.getCondominioId();
        List<AreaComun> areas = soloActivas
                ? areaComunRepository.findByCondominioIdAndActivaOrderByNombreAsc(condominioId, true)
                : areaComunRepository.findByCondominioIdOrderByNombreAsc(condominioId);
        return areas.stream().map(this::toResponse).collect(Collectors.toList());
    }

    @Transactional
    public AreaComunResponse crearArea(CreateAreaComunRequest request) {
        Long condominioId = TenantContext.getCondominioId();
        Condominio condominio = condominioRepository.findById(condominioId)
                .orElseThrow(() -> new ResourceNotFoundException("Condominio no encontrado"));

        AreaComun area = AreaComun.builder()
                .condominio(condominio)
                .nombre(request.getNombre())
                .descripcion(request.getDescripcion())
                .capacidad(request.getCapacidad())
                .horarioInicio(LocalTime.parse(request.getHorarioInicio(), TIME_FORMATTER))
                .horarioFin(LocalTime.parse(request.getHorarioFin(), TIME_FORMATTER))
                .duracionBloqueMinutos(request.getDuracionBloqueMinutos())
                .maxReservasMesPorUsuario(request.getMaxReservasMesPorUsuario())
                .anticipacionMinimaHoras(request.getAnticipacionMinimaHoras())
                .anticipacionMaximaDias(request.getAnticipacionMaximaDias())
                .activa(request.isActiva())
                .build();

        area = areaComunRepository.save(area);
        log.info("Área común creada: id={}, nombre={}", area.getId(), area.getNombre());
        return toResponse(area);
    }

    @Transactional
    public AreaComunResponse editarArea(Long id, CreateAreaComunRequest request) {
        AreaComun area = findAndValidate(id);
        area.setNombre(request.getNombre());
        area.setDescripcion(request.getDescripcion());
        area.setCapacidad(request.getCapacidad());
        area.setHorarioInicio(LocalTime.parse(request.getHorarioInicio(), TIME_FORMATTER));
        area.setHorarioFin(LocalTime.parse(request.getHorarioFin(), TIME_FORMATTER));
        area.setDuracionBloqueMinutos(request.getDuracionBloqueMinutos());
        area.setMaxReservasMesPorUsuario(request.getMaxReservasMesPorUsuario());
        area.setAnticipacionMinimaHoras(request.getAnticipacionMinimaHoras());
        area.setAnticipacionMaximaDias(request.getAnticipacionMaximaDias());
        area.setActiva(request.isActiva());
        area = areaComunRepository.save(area);
        log.info("Área común editada: id={}", id);
        return toResponse(area);
    }

    @Transactional
    public AreaComunResponse toggleActiva(Long id) {
        AreaComun area = findAndValidate(id);
        area.setActiva(!area.isActiva());
        area = areaComunRepository.save(area);
        log.info("Área común {} activa: {}", id, area.isActiva());
        return toResponse(area);
    }

    @Transactional(readOnly = true)
    public List<BloqueDisponibilidadResponse> obtenerDisponibilidad(Long areaId, LocalDate fecha) {
        AreaComun area = findAndValidate(areaId);
        LocalDateTime ahora = LocalDateTime.now();
        List<BloqueDisponibilidadResponse> bloques = new ArrayList<>();

        LocalDateTime bloque = LocalDateTime.of(fecha, area.getHorarioInicio());
        LocalDateTime fin = LocalDateTime.of(fecha, area.getHorarioFin());

        while (bloque.isBefore(fin)) {
            LocalDateTime bloqueHoraFin = bloque.plusMinutes(area.getDuracionBloqueMinutos());
            if (bloqueHoraFin.isAfter(fin)) break;

            if (bloque.isAfter(ahora)) {
                boolean ocupado = reservacionRepository.existsByAreaComunIdAndFechaHoraInicioAndEstado(
                        areaId, bloque, EstadoReservacion.ACTIVA);
                bloques.add(BloqueDisponibilidadResponse.builder()
                        .fechaHoraInicio(bloque)
                        .fechaHoraFin(bloqueHoraFin)
                        .disponible(!ocupado)
                        .build());
            }
            bloque = bloque.plusMinutes(area.getDuracionBloqueMinutos());
        }
        return bloques;
    }

    private AreaComun findAndValidate(Long id) {
        AreaComun area = areaComunRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Área común no encontrada"));
        Long condominioId = TenantContext.getCondominioId();
        if (!area.getCondominio().getId().equals(condominioId)) {
            throw new com.condos.common.exceptions.TenantMismatchException("No tienes permiso sobre esta área");
        }
        return area;
    }

    public AreaComunResponse toResponse(AreaComun area) {
        return AreaComunResponse.builder()
                .id(area.getId())
                .nombre(area.getNombre())
                .descripcion(area.getDescripcion())
                .capacidad(area.getCapacidad())
                .horarioInicio(area.getHorarioInicio().format(TIME_FORMATTER))
                .horarioFin(area.getHorarioFin().format(TIME_FORMATTER))
                .duracionBloqueMinutos(area.getDuracionBloqueMinutos())
                .maxReservasMesPorUsuario(area.getMaxReservasMesPorUsuario())
                .anticipacionMinimaHoras(area.getAnticipacionMinimaHoras())
                .anticipacionMaximaDias(area.getAnticipacionMaximaDias())
                .activa(area.isActiva())
                .createdAt(area.getCreatedAt())
                .build();
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add backend/src/main/java/com/condos/area/service/
git commit -m "feat(areas): add AreaComunService — CRUD and disponibilidad block generation"
```

---

## Task 6: ReservacionService

**Files:**
- Create: `backend/src/main/java/com/condos/reservacion/service/ReservacionService.java`

- [ ] **Step 1: ReservacionService.java**

```java
package com.condos.reservacion.service;

import com.condos.area.model.AreaComun;
import com.condos.area.repository.AreaComunRepository;
import com.condos.common.exceptions.ResourceNotFoundException;
import com.condos.common.exceptions.UnauthorizedException;
import com.condos.common.utils.TenantContext;
import com.condos.pago.model.EstadoPago;
import com.condos.pago.repository.CuotaUsuarioRepository;
import com.condos.reservacion.dto.CreateReservacionRequest;
import com.condos.reservacion.dto.ReservacionResponse;
import com.condos.reservacion.model.EstadoReservacion;
import com.condos.reservacion.model.Reservacion;
import com.condos.reservacion.repository.ReservacionRepository;
import com.condos.usuario.model.Usuario;
import com.condos.usuario.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.YearMonth;
import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class ReservacionService {

    private final ReservacionRepository reservacionRepository;
    private final AreaComunRepository areaComunRepository;
    private final UsuarioRepository usuarioRepository;
    private final CuotaUsuarioRepository cuotaUsuarioRepository;

    @Transactional
    public ReservacionResponse crearReservacion(CreateReservacionRequest request, Long usuarioId) {
        AreaComun area = areaComunRepository.findById(request.getAreaComunId())
                .orElseThrow(() -> new ResourceNotFoundException("Área común no encontrada"));

        if (!area.isActiva()) {
            throw new IllegalStateException("El área no está disponible para reservas");
        }

        Usuario usuario = usuarioRepository.findById(usuarioId)
                .orElseThrow(() -> new ResourceNotFoundException("Usuario no encontrado"));

        // Validar moroso
        boolean esMoroso = cuotaUsuarioRepository.existsByUsuarioIdAndEstadoAndCuotaFechaVencimientoBefore(
                usuarioId, EstadoPago.PENDIENTE, LocalDate.now());
        if (esMoroso) {
            throw new IllegalStateException("No puedes realizar reservaciones mientras tengas pagos pendientes vencidos");
        }

        LocalDateTime inicio = request.getFechaHoraInicio();
        LocalDateTime fin = inicio.plusMinutes(area.getDuracionBloqueMinutos());
        LocalDateTime ahora = LocalDateTime.now();

        // Validar anticipación mínima
        if (inicio.isBefore(ahora.plusHours(area.getAnticipacionMinimaHoras()))) {
            throw new IllegalArgumentException(
                    "La reservación debe hacerse con al menos " + area.getAnticipacionMinimaHoras() + " horas de anticipación");
        }

        // Validar anticipación máxima
        if (inicio.isAfter(ahora.plusDays(area.getAnticipacionMaximaDias()))) {
            throw new IllegalArgumentException(
                    "La reservación no puede hacerse con más de " + area.getAnticipacionMaximaDias() + " días de anticipación");
        }

        // Validar conflicto
        boolean ocupado = reservacionRepository.existsByAreaComunIdAndFechaHoraInicioAndEstado(
                area.getId(), inicio, EstadoReservacion.ACTIVA);
        if (ocupado) {
            throw new IllegalStateException("Este bloque horario ya está reservado");
        }

        // Validar límite mensual
        YearMonth mesActual = YearMonth.from(inicio);
        LocalDateTime inicioMes = mesActual.atDay(1).atStartOfDay();
        LocalDateTime finMes = mesActual.atEndOfMonth().atTime(23, 59, 59);

        long reservasMes = reservacionRepository
                .countByAreaComunIdAndUsuarioIdAndEstadoAndFechaHoraInicioGreaterThanEqualAndFechaHoraInicioLessThan(
                        area.getId(), usuarioId, EstadoReservacion.ACTIVA, inicioMes, finMes.plusSeconds(1));
        if (reservasMes >= area.getMaxReservasMesPorUsuario()) {
            throw new IllegalStateException(
                    "Has alcanzado el límite de " + area.getMaxReservasMesPorUsuario() + " reservaciones mensuales para esta área");
        }

        Reservacion reservacion = Reservacion.builder()
                .areaComun(area)
                .usuario(usuario)
                .fechaHoraInicio(inicio)
                .fechaHoraFin(fin)
                .estado(EstadoReservacion.ACTIVA)
                .build();

        reservacion = reservacionRepository.save(reservacion);
        log.info("Reservación creada: id={}, area={}, usuario={}", reservacion.getId(), area.getNombre(), usuario.getUsername());
        return toResponse(reservacion);
    }

    @Transactional(readOnly = true)
    public List<ReservacionResponse> listarReservaciones() {
        Long condominioId = TenantContext.getCondominioId();
        return reservacionRepository.findByAreaComunCondominioIdOrderByFechaHoraInicioDesc(condominioId)
                .stream().map(this::toResponse).collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<ReservacionResponse> listarMisReservaciones(Long usuarioId) {
        return reservacionRepository.findByUsuarioIdOrderByFechaHoraInicioDesc(usuarioId)
                .stream().map(this::toResponse).collect(Collectors.toList());
    }

    @Transactional
    public void cancelarReservacion(Long reservacionId, Long usuarioId, boolean esAdmin) {
        Reservacion reservacion = reservacionRepository.findById(reservacionId)
                .orElseThrow(() -> new ResourceNotFoundException("Reservación no encontrada"));

        if (!esAdmin && !reservacion.getUsuario().getId().equals(usuarioId)) {
            throw new UnauthorizedException("No tienes permiso para cancelar esta reservación");
        }
        if (!esAdmin && reservacion.getFechaHoraInicio().isBefore(LocalDateTime.now())) {
            throw new IllegalStateException("No puedes cancelar una reservación que ya pasó");
        }
        if (reservacion.getEstado() == EstadoReservacion.CANCELADA) {
            throw new IllegalStateException("La reservación ya está cancelada");
        }

        reservacion.setEstado(EstadoReservacion.CANCELADA);
        reservacionRepository.save(reservacion);
        log.info("Reservación cancelada: id={}", reservacionId);
    }

    private ReservacionResponse toResponse(Reservacion r) {
        return ReservacionResponse.builder()
                .id(r.getId())
                .areaComunId(r.getAreaComun().getId())
                .areaComunNombre(r.getAreaComun().getNombre())
                .usuarioId(r.getUsuario().getId())
                .usuarioNombre(r.getUsuario().getNombreCompleto())
                .fechaHoraInicio(r.getFechaHoraInicio())
                .fechaHoraFin(r.getFechaHoraFin())
                .estado(r.getEstado())
                .createdAt(r.getCreatedAt())
                .build();
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add backend/src/main/java/com/condos/reservacion/service/
git commit -m "feat(areas): add ReservacionService — conflict, moroso, monthly limit validations"
```

---

## Task 7: Controllers + compilación

**Files:**
- Create: `backend/src/main/java/com/condos/area/controller/AreaComunController.java`
- Create: `backend/src/main/java/com/condos/reservacion/controller/ReservacionController.java`

- [ ] **Step 1: AreaComunController.java**

```java
package com.condos.area.controller;

import com.condos.area.dto.AreaComunResponse;
import com.condos.area.dto.BloqueDisponibilidadResponse;
import com.condos.area.dto.CreateAreaComunRequest;
import com.condos.area.service.AreaComunService;
import com.condos.usuario.model.Rol;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/areas-comunes")
@RequiredArgsConstructor
public class AreaComunController {

    private final AreaComunService areaComunService;

    @GetMapping
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<List<AreaComunResponse>> listarAreas(Authentication authentication) {
        // USUARIO ve solo activas; ADMIN ve todas
        boolean esUsuario = authentication.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_USUARIO"));
        return ResponseEntity.ok(areaComunService.listarAreas(esUsuario));
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPERADMIN')")
    public ResponseEntity<AreaComunResponse> crearArea(@Valid @RequestBody CreateAreaComunRequest request) {
        return ResponseEntity.ok(areaComunService.crearArea(request));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPERADMIN')")
    public ResponseEntity<AreaComunResponse> editarArea(
            @PathVariable Long id,
            @Valid @RequestBody CreateAreaComunRequest request) {
        return ResponseEntity.ok(areaComunService.editarArea(id, request));
    }

    @PutMapping("/{id}/toggle")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPERADMIN')")
    public ResponseEntity<AreaComunResponse> toggleActiva(@PathVariable Long id) {
        return ResponseEntity.ok(areaComunService.toggleActiva(id));
    }

    @GetMapping("/{id}/disponibilidad")
    @PreAuthorize("hasAnyRole('USUARIO', 'ADMIN', 'SUPERADMIN')")
    public ResponseEntity<List<BloqueDisponibilidadResponse>> obtenerDisponibilidad(
            @PathVariable Long id,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate fecha) {
        return ResponseEntity.ok(areaComunService.obtenerDisponibilidad(id, fecha));
    }
}
```

- [ ] **Step 2: ReservacionController.java**

```java
package com.condos.reservacion.controller;

import com.condos.reservacion.dto.CreateReservacionRequest;
import com.condos.reservacion.dto.ReservacionResponse;
import com.condos.reservacion.service.ReservacionService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/reservaciones")
@RequiredArgsConstructor
public class ReservacionController {

    private final ReservacionService reservacionService;

    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPERADMIN')")
    public ResponseEntity<List<ReservacionResponse>> listarReservaciones() {
        return ResponseEntity.ok(reservacionService.listarReservaciones());
    }

    @GetMapping("/mis-reservaciones")
    @PreAuthorize("hasRole('USUARIO')")
    public ResponseEntity<List<ReservacionResponse>> listarMisReservaciones(Authentication authentication) {
        Long usuarioId = Long.parseLong(authentication.getName());
        return ResponseEntity.ok(reservacionService.listarMisReservaciones(usuarioId));
    }

    @PostMapping
    @PreAuthorize("hasRole('USUARIO')")
    public ResponseEntity<ReservacionResponse> crearReservacion(
            @Valid @RequestBody CreateReservacionRequest request,
            Authentication authentication) {
        Long usuarioId = Long.parseLong(authentication.getName());
        return ResponseEntity.ok(reservacionService.crearReservacion(request, usuarioId));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasAnyRole('USUARIO', 'ADMIN', 'SUPERADMIN')")
    public ResponseEntity<Void> cancelarReservacion(
            @PathVariable Long id,
            Authentication authentication) {
        Long usuarioId = Long.parseLong(authentication.getName());
        boolean esAdmin = authentication.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN") ||
                               a.getAuthority().equals("ROLE_SUPERADMIN"));
        reservacionService.cancelarReservacion(id, usuarioId, esAdmin);
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
git add backend/src/main/java/com/condos/area/controller/ \
        backend/src/main/java/com/condos/reservacion/controller/
git commit -m "feat(areas): add AreaComunController and ReservacionController — 9 endpoints total"
```

---

## Task 8: Flutter Models + .g.dart

**Files:**
- Create: `lib/features/areas/models/area_comun.dart` + `.g.dart`
- Create: `lib/features/areas/models/create_area_comun_request.dart` + `.g.dart`
- Create: `lib/features/areas/models/bloque_disponibilidad.dart` + `.g.dart`
- Create: `lib/features/areas/models/reservacion.dart` + `.g.dart`
- Create: `lib/features/areas/models/create_reservacion_request.dart` + `.g.dart`

- [ ] **Step 1: area_comun.dart**

```dart
import 'package:json_annotation/json_annotation.dart';

part 'area_comun.g.dart';

@JsonSerializable()
class AreaComun {
  final int id;
  final String nombre;
  final String? descripcion;
  final int capacidad;
  final String horarioInicio;
  final String horarioFin;
  final int duracionBloqueMinutos;
  final int maxReservasMesPorUsuario;
  final int anticipacionMinimaHoras;
  final int anticipacionMaximaDias;
  final bool activa;
  final DateTime createdAt;

  AreaComun({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.capacidad,
    required this.horarioInicio,
    required this.horarioFin,
    required this.duracionBloqueMinutos,
    required this.maxReservasMesPorUsuario,
    required this.anticipacionMinimaHoras,
    required this.anticipacionMaximaDias,
    required this.activa,
    required this.createdAt,
  });

  factory AreaComun.fromJson(Map<String, dynamic> json) =>
      _$AreaComunFromJson(json);
  Map<String, dynamic> toJson() => _$AreaComunToJson(this);
}
```

- [ ] **Step 2: area_comun.g.dart**

```dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'area_comun.dart';

AreaComun _$AreaComunFromJson(Map<String, dynamic> json) => AreaComun(
      id: (json['id'] as num).toInt(),
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      capacidad: (json['capacidad'] as num).toInt(),
      horarioInicio: json['horarioInicio'] as String,
      horarioFin: json['horarioFin'] as String,
      duracionBloqueMinutos: (json['duracionBloqueMinutos'] as num).toInt(),
      maxReservasMesPorUsuario:
          (json['maxReservasMesPorUsuario'] as num).toInt(),
      anticipacionMinimaHoras:
          (json['anticipacionMinimaHoras'] as num).toInt(),
      anticipacionMaximaDias: (json['anticipacionMaximaDias'] as num).toInt(),
      activa: json['activa'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$AreaComunToJson(AreaComun instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nombre': instance.nombre,
      'descripcion': instance.descripcion,
      'capacidad': instance.capacidad,
      'horarioInicio': instance.horarioInicio,
      'horarioFin': instance.horarioFin,
      'duracionBloqueMinutos': instance.duracionBloqueMinutos,
      'maxReservasMesPorUsuario': instance.maxReservasMesPorUsuario,
      'anticipacionMinimaHoras': instance.anticipacionMinimaHoras,
      'anticipacionMaximaDias': instance.anticipacionMaximaDias,
      'activa': instance.activa,
      'createdAt': instance.createdAt.toIso8601String(),
    };
```

- [ ] **Step 3: create_area_comun_request.dart**

```dart
import 'package:json_annotation/json_annotation.dart';

part 'create_area_comun_request.g.dart';

@JsonSerializable()
class CreateAreaComunRequest {
  final String nombre;
  final String? descripcion;
  final int capacidad;
  final String horarioInicio;
  final String horarioFin;
  final int duracionBloqueMinutos;
  final int maxReservasMesPorUsuario;
  final int anticipacionMinimaHoras;
  final int anticipacionMaximaDias;
  final bool activa;

  CreateAreaComunRequest({
    required this.nombre,
    this.descripcion,
    required this.capacidad,
    required this.horarioInicio,
    required this.horarioFin,
    required this.duracionBloqueMinutos,
    required this.maxReservasMesPorUsuario,
    required this.anticipacionMinimaHoras,
    required this.anticipacionMaximaDias,
    required this.activa,
  });

  factory CreateAreaComunRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateAreaComunRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateAreaComunRequestToJson(this);
}
```

- [ ] **Step 4: create_area_comun_request.g.dart**

```dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_area_comun_request.dart';

CreateAreaComunRequest _$CreateAreaComunRequestFromJson(
        Map<String, dynamic> json) =>
    CreateAreaComunRequest(
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      capacidad: (json['capacidad'] as num).toInt(),
      horarioInicio: json['horarioInicio'] as String,
      horarioFin: json['horarioFin'] as String,
      duracionBloqueMinutos: (json['duracionBloqueMinutos'] as num).toInt(),
      maxReservasMesPorUsuario:
          (json['maxReservasMesPorUsuario'] as num).toInt(),
      anticipacionMinimaHoras:
          (json['anticipacionMinimaHoras'] as num).toInt(),
      anticipacionMaximaDias: (json['anticipacionMaximaDias'] as num).toInt(),
      activa: json['activa'] as bool,
    );

Map<String, dynamic> _$CreateAreaComunRequestToJson(
        CreateAreaComunRequest instance) =>
    <String, dynamic>{
      'nombre': instance.nombre,
      'descripcion': instance.descripcion,
      'capacidad': instance.capacidad,
      'horarioInicio': instance.horarioInicio,
      'horarioFin': instance.horarioFin,
      'duracionBloqueMinutos': instance.duracionBloqueMinutos,
      'maxReservasMesPorUsuario': instance.maxReservasMesPorUsuario,
      'anticipacionMinimaHoras': instance.anticipacionMinimaHoras,
      'anticipacionMaximaDias': instance.anticipacionMaximaDias,
      'activa': instance.activa,
    };
```

- [ ] **Step 5: bloque_disponibilidad.dart**

```dart
import 'package:json_annotation/json_annotation.dart';

part 'bloque_disponibilidad.g.dart';

@JsonSerializable()
class BloqueDisponibilidad {
  final DateTime fechaHoraInicio;
  final DateTime fechaHoraFin;
  final bool disponible;

  BloqueDisponibilidad({
    required this.fechaHoraInicio,
    required this.fechaHoraFin,
    required this.disponible,
  });

  factory BloqueDisponibilidad.fromJson(Map<String, dynamic> json) =>
      _$BloqueDisponibilidadFromJson(json);
  Map<String, dynamic> toJson() => _$BloqueDisponibilidadToJson(this);
}
```

- [ ] **Step 6: bloque_disponibilidad.g.dart**

```dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bloque_disponibilidad.dart';

BloqueDisponibilidad _$BloqueDisponibilidadFromJson(
        Map<String, dynamic> json) =>
    BloqueDisponibilidad(
      fechaHoraInicio: DateTime.parse(json['fechaHoraInicio'] as String),
      fechaHoraFin: DateTime.parse(json['fechaHoraFin'] as String),
      disponible: json['disponible'] as bool,
    );

Map<String, dynamic> _$BloqueDisponibilidadToJson(
        BloqueDisponibilidad instance) =>
    <String, dynamic>{
      'fechaHoraInicio': instance.fechaHoraInicio.toIso8601String(),
      'fechaHoraFin': instance.fechaHoraFin.toIso8601String(),
      'disponible': instance.disponible,
    };
```

- [ ] **Step 7: reservacion.dart**

```dart
import 'package:json_annotation/json_annotation.dart';

part 'reservacion.g.dart';

enum EstadoReservacion {
  @JsonValue('ACTIVA')
  activa,

  @JsonValue('CANCELADA')
  cancelada,
}

@JsonSerializable()
class Reservacion {
  final int id;
  final int areaComunId;
  final String areaComunNombre;
  final int usuarioId;
  final String usuarioNombre;
  final DateTime fechaHoraInicio;
  final DateTime fechaHoraFin;
  final EstadoReservacion estado;
  final DateTime createdAt;

  Reservacion({
    required this.id,
    required this.areaComunId,
    required this.areaComunNombre,
    required this.usuarioId,
    required this.usuarioNombre,
    required this.fechaHoraInicio,
    required this.fechaHoraFin,
    required this.estado,
    required this.createdAt,
  });

  factory Reservacion.fromJson(Map<String, dynamic> json) =>
      _$ReservacionFromJson(json);
  Map<String, dynamic> toJson() => _$ReservacionToJson(this);
}
```

- [ ] **Step 8: reservacion.g.dart**

```dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reservacion.dart';

Reservacion _$ReservacionFromJson(Map<String, dynamic> json) => Reservacion(
      id: (json['id'] as num).toInt(),
      areaComunId: (json['areaComunId'] as num).toInt(),
      areaComunNombre: json['areaComunNombre'] as String,
      usuarioId: (json['usuarioId'] as num).toInt(),
      usuarioNombre: json['usuarioNombre'] as String,
      fechaHoraInicio: DateTime.parse(json['fechaHoraInicio'] as String),
      fechaHoraFin: DateTime.parse(json['fechaHoraFin'] as String),
      estado: $enumDecode(_$EstadoReservacionEnumMap, json['estado']),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$ReservacionToJson(Reservacion instance) =>
    <String, dynamic>{
      'id': instance.id,
      'areaComunId': instance.areaComunId,
      'areaComunNombre': instance.areaComunNombre,
      'usuarioId': instance.usuarioId,
      'usuarioNombre': instance.usuarioNombre,
      'fechaHoraInicio': instance.fechaHoraInicio.toIso8601String(),
      'fechaHoraFin': instance.fechaHoraFin.toIso8601String(),
      'estado': _$EstadoReservacionEnumMap[instance.estado]!,
      'createdAt': instance.createdAt.toIso8601String(),
    };

const _$EstadoReservacionEnumMap = {
  EstadoReservacion.activa: 'ACTIVA',
  EstadoReservacion.cancelada: 'CANCELADA',
};
```

- [ ] **Step 9: create_reservacion_request.dart**

```dart
import 'package:json_annotation/json_annotation.dart';

part 'create_reservacion_request.g.dart';

@JsonSerializable()
class CreateReservacionRequest {
  final int areaComunId;
  final DateTime fechaHoraInicio;

  CreateReservacionRequest({
    required this.areaComunId,
    required this.fechaHoraInicio,
  });

  factory CreateReservacionRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateReservacionRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateReservacionRequestToJson(this);
}
```

- [ ] **Step 10: create_reservacion_request.g.dart**

```dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_reservacion_request.dart';

CreateReservacionRequest _$CreateReservacionRequestFromJson(
        Map<String, dynamic> json) =>
    CreateReservacionRequest(
      areaComunId: (json['areaComunId'] as num).toInt(),
      fechaHoraInicio: DateTime.parse(json['fechaHoraInicio'] as String),
    );

Map<String, dynamic> _$CreateReservacionRequestToJson(
        CreateReservacionRequest instance) =>
    <String, dynamic>{
      'areaComunId': instance.areaComunId,
      'fechaHoraInicio': instance.fechaHoraInicio.toIso8601String(),
    };
```

- [ ] **Step 11: Commit**

```bash
git add lib/features/areas/models/
git commit -m "feat(areas): add Flutter models AreaComun, BloqueDisponibilidad, Reservacion with manual .g.dart"
```

---

## Task 9: ApiConstants + Flutter Services

**Files:**
- Modify: `lib/core/constants/api_constants.dart`
- Create: `lib/features/areas/services/area_comun_service.dart`
- Create: `lib/features/areas/services/reservacion_service.dart`

- [ ] **Step 1: Agregar constantes a api_constants.dart**

Insertar antes de `// Notificaciones`:

```dart
  // Áreas Comunes
  static const String areasComunes = '$apiPrefix/areas-comunes';
  static String areaComunById(int id) => '$apiPrefix/areas-comunes/$id';
  static String toggleAreaComun(int id) => '$apiPrefix/areas-comunes/$id/toggle';
  static String disponibilidad(int id) => '$apiPrefix/areas-comunes/$id/disponibilidad';

  // Reservaciones
  static const String reservaciones = '$apiPrefix/reservaciones';
  static const String misReservaciones = '$apiPrefix/reservaciones/mis-reservaciones';
  static String cancelarReservacion(int id) => '$apiPrefix/reservaciones/$id';
```

- [ ] **Step 2: area_comun_service.dart**

```dart
import '../../../core/constants/api_constants.dart';
import '../../../shared/services/api_client.dart';
import '../models/area_comun.dart';
import '../models/bloque_disponibilidad.dart';
import '../models/create_area_comun_request.dart';

class AreaComunService {
  final ApiClient apiClient;

  AreaComunService({required this.apiClient});

  Future<List<AreaComun>> listarAreas() async {
    final response = await apiClient.getList(ApiConstants.areasComunes);
    return response
        .map((item) => AreaComun.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<AreaComun> crearArea(CreateAreaComunRequest request) async {
    final response =
        await apiClient.post(ApiConstants.areasComunes, request.toJson());
    return AreaComun.fromJson(response);
  }

  Future<AreaComun> editarArea(int id, CreateAreaComunRequest request) async {
    final response =
        await apiClient.put(ApiConstants.areaComunById(id), request.toJson());
    return AreaComun.fromJson(response);
  }

  Future<AreaComun> toggleActiva(int id) async {
    final response = await apiClient.put(ApiConstants.toggleAreaComun(id), {});
    return AreaComun.fromJson(response);
  }

  Future<List<BloqueDisponibilidad>> obtenerDisponibilidad(
      int id, String fecha) async {
    final response = await apiClient.getList(
      ApiConstants.disponibilidad(id),
      queryParameters: {'fecha': fecha},
    );
    return response
        .map((item) =>
            BloqueDisponibilidad.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
```

- [ ] **Step 3: reservacion_service.dart**

```dart
import '../../../core/constants/api_constants.dart';
import '../../../shared/services/api_client.dart';
import '../models/create_reservacion_request.dart';
import '../models/reservacion.dart';

class ReservacionService {
  final ApiClient apiClient;

  ReservacionService({required this.apiClient});

  Future<List<Reservacion>> listarReservaciones() async {
    final response = await apiClient.getList(ApiConstants.reservaciones);
    return response
        .map((item) => Reservacion.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<Reservacion>> listarMisReservaciones() async {
    final response = await apiClient.getList(ApiConstants.misReservaciones);
    return response
        .map((item) => Reservacion.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Reservacion> crearReservacion(CreateReservacionRequest request) async {
    final response =
        await apiClient.post(ApiConstants.reservaciones, request.toJson());
    return Reservacion.fromJson(response);
  }

  Future<void> cancelarReservacion(int id) async {
    await apiClient.delete(ApiConstants.cancelarReservacion(id));
  }
}
```

- [ ] **Step 4: Verificar que ApiClient.getList acepta queryParameters**

Leer `lib/shared/services/api_client.dart` y confirmar que `getList` acepta `Map<String, String>? queryParameters`. Ya existe este parámetro desde el código original — no se necesita modificación.

- [ ] **Step 5: Commit**

```bash
git add lib/core/constants/api_constants.dart \
        lib/features/areas/services/
git commit -m "feat(areas): add ApiConstants for areas/reservaciones and Flutter services"
```

---

## Task 10: Providers

**Files:**
- Create: `lib/features/areas/providers/area_comun_provider.dart`
- Create: `lib/features/areas/providers/reservacion_provider.dart`

- [ ] **Step 1: area_comun_provider.dart**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/auth_provider.dart';
import '../models/area_comun.dart';
import '../models/create_area_comun_request.dart';
import '../services/area_comun_service.dart';

class AreaComunState {
  final List<AreaComun> areas;
  final bool isLoading;
  final String? error;

  AreaComunState({
    this.areas = const [],
    this.isLoading = false,
    this.error,
  });

  AreaComunState copyWith({
    List<AreaComun>? areas,
    bool? isLoading,
    String? error,
  }) {
    return AreaComunState(
      areas: areas ?? this.areas,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AreaComunNotifier extends StateNotifier<AreaComunState> {
  final AreaComunService _service;

  AreaComunNotifier(this._service) : super(AreaComunState());

  Future<void> cargarAreas() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final areas = await _service.listarAreas();
      state = state.copyWith(areas: areas, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<AreaComun?> crearArea(CreateAreaComunRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final area = await _service.crearArea(request);
      state = state.copyWith(
        areas: [...state.areas, area]
          ..sort((a, b) => a.nombre.compareTo(b.nombre)),
        isLoading: false,
      );
      return area;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<AreaComun?> editarArea(int id, CreateAreaComunRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updated = await _service.editarArea(id, request);
      state = state.copyWith(
        areas: state.areas.map((a) => a.id == id ? updated : a).toList(),
        isLoading: false,
      );
      return updated;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<void> toggleActiva(int id) async {
    try {
      final updated = await _service.toggleActiva(id);
      state = state.copyWith(
        areas: state.areas.map((a) => a.id == id ? updated : a).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void clearError() => state = state.copyWith(error: null);
}

final areaComunServiceProvider = Provider<AreaComunService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AreaComunService(apiClient: apiClient);
});

final areaComunProvider =
    StateNotifierProvider<AreaComunNotifier, AreaComunState>((ref) {
  final service = ref.watch(areaComunServiceProvider);
  return AreaComunNotifier(service);
});
```

- [ ] **Step 2: reservacion_provider.dart**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/auth_provider.dart';
import '../models/create_reservacion_request.dart';
import '../models/reservacion.dart';
import '../services/reservacion_service.dart';

class ReservacionState {
  final List<Reservacion> reservaciones;
  final List<Reservacion> misReservaciones;
  final bool isLoading;
  final String? error;

  ReservacionState({
    this.reservaciones = const [],
    this.misReservaciones = const [],
    this.isLoading = false,
    this.error,
  });

  ReservacionState copyWith({
    List<Reservacion>? reservaciones,
    List<Reservacion>? misReservaciones,
    bool? isLoading,
    String? error,
  }) {
    return ReservacionState(
      reservaciones: reservaciones ?? this.reservaciones,
      misReservaciones: misReservaciones ?? this.misReservaciones,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ReservacionNotifier extends StateNotifier<ReservacionState> {
  final ReservacionService _service;

  ReservacionNotifier(this._service) : super(ReservacionState());

  Future<void> cargarReservaciones() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final reservaciones = await _service.listarReservaciones();
      state = state.copyWith(reservaciones: reservaciones, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> cargarMisReservaciones() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final misReservaciones = await _service.listarMisReservaciones();
      state = state.copyWith(
          misReservaciones: misReservaciones, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<Reservacion?> crearReservacion(
      CreateReservacionRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final reservacion = await _service.crearReservacion(request);
      state = state.copyWith(
        misReservaciones: [reservacion, ...state.misReservaciones],
        isLoading: false,
      );
      return reservacion;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<void> cancelarReservacion(int id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.cancelarReservacion(id);
      state = state.copyWith(
        misReservaciones: state.misReservaciones
            .map((r) => r.id == id
                ? Reservacion(
                    id: r.id,
                    areaComunId: r.areaComunId,
                    areaComunNombre: r.areaComunNombre,
                    usuarioId: r.usuarioId,
                    usuarioNombre: r.usuarioNombre,
                    fechaHoraInicio: r.fechaHoraInicio,
                    fechaHoraFin: r.fechaHoraFin,
                    estado: EstadoReservacion.cancelada,
                    createdAt: r.createdAt,
                  )
                : r)
            .toList(),
        reservaciones: state.reservaciones
            .map((r) => r.id == id
                ? Reservacion(
                    id: r.id,
                    areaComunId: r.areaComunId,
                    areaComunNombre: r.areaComunNombre,
                    usuarioId: r.usuarioId,
                    usuarioNombre: r.usuarioNombre,
                    fechaHoraInicio: r.fechaHoraInicio,
                    fechaHoraFin: r.fechaHoraFin,
                    estado: EstadoReservacion.cancelada,
                    createdAt: r.createdAt,
                  )
                : r)
            .toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clearError() => state = state.copyWith(error: null);
}

final reservacionServiceProvider = Provider<ReservacionService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ReservacionService(apiClient: apiClient);
});

final reservacionProvider =
    StateNotifierProvider<ReservacionNotifier, ReservacionState>((ref) {
  final service = ref.watch(reservacionServiceProvider);
  return ReservacionNotifier(service);
});
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/areas/providers/
git commit -m "feat(areas): add AreaComunNotifier and ReservacionNotifier providers"
```

---

## Task 11: AreasScreen

**Files:**
- Create: `lib/features/areas/screens/areas_screen.dart`

- [ ] **Step 1: areas_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/models/usuario.dart';
import '../../../shared/providers/auth_provider.dart';
import '../models/area_comun.dart';
import '../models/reservacion.dart';
import '../providers/area_comun_provider.dart';
import '../providers/reservacion_provider.dart';

class AreasScreen extends ConsumerStatefulWidget {
  const AreasScreen({super.key});

  @override
  ConsumerState<AreasScreen> createState() => _AreasScreenState();
}

class _AreasScreenState extends ConsumerState<AreasScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  void _cargar() {
    final user = ref.read(authProvider).user;
    ref.read(areaComunProvider.notifier).cargarAreas();
    if (user?.rol == Rol.usuario) {
      ref.read(reservacionProvider.notifier).cargarMisReservaciones();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final esAdmin = user?.rol == Rol.admin || user?.rol == Rol.superadmin;
    final esUsuario = user?.rol == Rol.usuario;

    if (esAdmin) return _buildAdminView(context);
    if (esUsuario) return _buildUsuarioView(context);
    return const Scaffold(body: Center(child: Text('Sin acceso')));
  }

  Widget _buildAdminView(BuildContext context) {
    final state = ref.watch(areaComunProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Áreas Comunes')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/home/areas/nueva');
          ref.read(areaComunProvider.notifier).cargarAreas();
        },
        child: const Icon(Icons.add),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.areas.isEmpty
              ? const Center(child: Text('No hay áreas registradas.'))
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(areaComunProvider.notifier).cargarAreas(),
                  child: ListView.builder(
                    itemCount: state.areas.length,
                    itemBuilder: (context, index) {
                      final area = state.areas[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        child: ListTile(
                          title: Text(area.nombre,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          subtitle: Text(
                              '${area.horarioInicio} – ${area.horarioFin} · ${area.duracionBloqueMinutos} min'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Switch(
                                value: area.activa,
                                onChanged: (_) => ref
                                    .read(areaComunProvider.notifier)
                                    .toggleActiva(area.id),
                              ),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                          onTap: () async {
                            await context.push('/home/areas/${area.id}/editar');
                            ref
                                .read(areaComunProvider.notifier)
                                .cargarAreas();
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildUsuarioView(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Áreas'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Áreas Disponibles'),
              Tab(text: 'Mis Reservas'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _AreasList(),
            _MisReservacionesList(),
          ],
        ),
      ),
    );
  }
}

class _AreasList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(areaComunProvider);

    if (state.isLoading) return const Center(child: CircularProgressIndicator());
    if (state.areas.isEmpty) {
      return const Center(child: Text('No hay áreas disponibles.'));
    }
    return RefreshIndicator(
      onRefresh: () => ref.read(areaComunProvider.notifier).cargarAreas(),
      child: ListView.builder(
        itemCount: state.areas.length,
        itemBuilder: (context, index) {
          final area = state.areas[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: ListTile(
              leading: const Icon(Icons.meeting_room_outlined, size: 36),
              title: Text(area.nombre,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Horario: ${area.horarioInicio} – ${area.horarioFin}'),
                  Text('Bloques de ${area.duracionBloqueMinutos} min · Capacidad ${area.capacidad}'),
                ],
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/home/areas/${area.id}/disponibilidad'),
            ),
          );
        },
      ),
    );
  }
}

class _MisReservacionesList extends ConsumerWidget {
  String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reservacionProvider);

    if (state.isLoading) return const Center(child: CircularProgressIndicator());
    if (state.misReservaciones.isEmpty) {
      return const Center(child: Text('No tienes reservaciones.'));
    }
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(reservacionProvider.notifier).cargarMisReservaciones(),
      child: ListView.builder(
        itemCount: state.misReservaciones.length,
        itemBuilder: (context, index) {
          final r = state.misReservaciones[index];
          final esActiva = r.estado == EstadoReservacion.activa;
          final esFutura = r.fechaHoraInicio.isAfter(DateTime.now());

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: ListTile(
              title: Text(r.areaComunNombre,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${_fmt(r.fechaHoraInicio)} – ${_fmt(r.fechaHoraFin)}'),
                ],
              ),
              trailing: esActiva && esFutura
                  ? TextButton(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Cancelar reservación'),
                            content:
                                const Text('¿Cancelar esta reservación?'),
                            actions: [
                              TextButton(
                                  onPressed: () =>
                                      Navigator.pop(ctx, false),
                                  child: const Text('No')),
                              ElevatedButton(
                                onPressed: () =>
                                    Navigator.pop(ctx, true),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red),
                                child: const Text('Sí'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await ref
                              .read(reservacionProvider.notifier)
                              .cancelarReservacion(r.id);
                        }
                      },
                      style: TextButton.styleFrom(
                          foregroundColor: Colors.red),
                      child: const Text('Cancelar'),
                    )
                  : Chip(
                      label: Text(
                        esActiva ? 'ACTIVA' : 'CANCELADA',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 11),
                      ),
                      backgroundColor:
                          esActiva ? Colors.green : Colors.grey,
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
git add lib/features/areas/screens/areas_screen.dart
git commit -m "feat(areas): add AreasScreen — admin list with toggle, usuario tabs Áreas/Mis Reservas"
```

---

## Task 12: CrearEditarAreaScreen

**Files:**
- Create: `lib/features/areas/screens/crear_editar_area_screen.dart`

- [ ] **Step 1: crear_editar_area_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/area_comun.dart';
import '../models/create_area_comun_request.dart';
import '../providers/area_comun_provider.dart';

class CrearEditarAreaScreen extends ConsumerStatefulWidget {
  final AreaComun? area;

  const CrearEditarAreaScreen({super.key, this.area});

  @override
  ConsumerState<CrearEditarAreaScreen> createState() =>
      _CrearEditarAreaScreenState();
}

class _CrearEditarAreaScreenState
    extends ConsumerState<CrearEditarAreaScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _descripcionCtrl;
  late final TextEditingController _capacidadCtrl;
  late final TextEditingController _maxReservasCtrl;
  late final TextEditingController _anticipacionMinCtrl;
  late final TextEditingController _anticipacionMaxCtrl;
  late int _duracionBloque;
  late TimeOfDay _horarioInicio;
  late TimeOfDay _horarioFin;
  late bool _activa;

  bool get _esEdicion => widget.area != null;

  @override
  void initState() {
    super.initState();
    final a = widget.area;
    _nombreCtrl = TextEditingController(text: a?.nombre ?? '');
    _descripcionCtrl = TextEditingController(text: a?.descripcion ?? '');
    _capacidadCtrl =
        TextEditingController(text: a?.capacidad.toString() ?? '');
    _maxReservasCtrl = TextEditingController(
        text: a?.maxReservasMesPorUsuario.toString() ?? '');
    _anticipacionMinCtrl = TextEditingController(
        text: a?.anticipacionMinimaHoras.toString() ?? '');
    _anticipacionMaxCtrl = TextEditingController(
        text: a?.anticipacionMaximaDias.toString() ?? '');
    _duracionBloque = a?.duracionBloqueMinutos ?? 60;
    _activa = a?.activa ?? true;

    if (a != null) {
      final parts = a.horarioInicio.split(':');
      _horarioInicio =
          TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      final partsF = a.horarioFin.split(':');
      _horarioFin =
          TimeOfDay(hour: int.parse(partsF[0]), minute: int.parse(partsF[1]));
    } else {
      _horarioInicio = const TimeOfDay(hour: 8, minute: 0);
      _horarioFin = const TimeOfDay(hour: 22, minute: 0);
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    _capacidadCtrl.dispose();
    _maxReservasCtrl.dispose();
    _anticipacionMinCtrl.dispose();
    _anticipacionMaxCtrl.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime(bool esInicio) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: esInicio ? _horarioInicio : _horarioFin,
    );
    if (picked != null) {
      setState(() {
        if (esInicio) {
          _horarioInicio = picked;
        } else {
          _horarioFin = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final request = CreateAreaComunRequest(
      nombre: _nombreCtrl.text.trim(),
      descripcion: _descripcionCtrl.text.trim().isEmpty
          ? null
          : _descripcionCtrl.text.trim(),
      capacidad: int.parse(_capacidadCtrl.text.trim()),
      horarioInicio: _formatTime(_horarioInicio),
      horarioFin: _formatTime(_horarioFin),
      duracionBloqueMinutos: _duracionBloque,
      maxReservasMesPorUsuario: int.parse(_maxReservasCtrl.text.trim()),
      anticipacionMinimaHoras: int.parse(_anticipacionMinCtrl.text.trim()),
      anticipacionMaximaDias: int.parse(_anticipacionMaxCtrl.text.trim()),
      activa: _activa,
    );

    if (_esEdicion) {
      await ref
          .read(areaComunProvider.notifier)
          .editarArea(widget.area!.id, request);
    } else {
      await ref.read(areaComunProvider.notifier).crearArea(request);
    }

    if (mounted) {
      final error = ref.read(areaComunProvider).error;
      if (error == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(_esEdicion
                ? 'Área actualizada exitosamente'
                : 'Área creada exitosamente')));
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: Colors.red));
        ref.read(areaComunProvider.notifier).clearError();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(areaComunProvider);

    return Scaffold(
      appBar: AppBar(
          title: Text(_esEdicion ? 'Editar Área' : 'Nueva Área Común')),
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
              const SizedBox(height: 12),
              TextFormField(
                controller: _descripcionCtrl,
                decoration: const InputDecoration(
                    labelText: 'Descripción', border: OutlineInputBorder()),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _capacidadCtrl,
                decoration: const InputDecoration(
                    labelText: 'Capacidad (personas) *',
                    border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Campo requerido';
                  if (int.tryParse(v.trim()) == null || int.parse(v.trim()) < 1)
                    return 'Ingresa un número válido';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Horario inicio'),
                      subtitle: Text(_formatTime(_horarioInicio)),
                      trailing: const Icon(Icons.access_time),
                      onTap: () => _pickTime(true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Horario fin'),
                      subtitle: Text(_formatTime(_horarioFin)),
                      trailing: const Icon(Icons.access_time),
                      onTap: () => _pickTime(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _duracionBloque,
                decoration: const InputDecoration(
                    labelText: 'Duración de bloque',
                    border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 30, child: Text('30 minutos')),
                  DropdownMenuItem(value: 60, child: Text('60 minutos')),
                  DropdownMenuItem(value: 90, child: Text('90 minutos')),
                  DropdownMenuItem(value: 120, child: Text('120 minutos')),
                ],
                onChanged: (v) => setState(() => _duracionBloque = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _maxReservasCtrl,
                decoration: const InputDecoration(
                    labelText: 'Máx. reservas por mes/usuario *',
                    border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Campo requerido';
                  if (int.tryParse(v.trim()) == null || int.parse(v.trim()) < 1)
                    return 'Ingresa un número válido';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _anticipacionMinCtrl,
                decoration: const InputDecoration(
                    labelText: 'Anticipación mínima (horas) *',
                    border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Campo requerido';
                  if (int.tryParse(v.trim()) == null || int.parse(v.trim()) < 0)
                    return 'Ingresa un número válido';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _anticipacionMaxCtrl,
                decoration: const InputDecoration(
                    labelText: 'Anticipación máxima (días) *',
                    border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Campo requerido';
                  if (int.tryParse(v.trim()) == null || int.parse(v.trim()) < 1)
                    return 'Ingresa un número válido';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Área activa'),
                value: _activa,
                onChanged: (v) => setState(() => _activa = v),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: state.isLoading ? null : _submit,
                child: state.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(_esEdicion ? 'Guardar Cambios' : 'Crear Área'),
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
git add lib/features/areas/screens/crear_editar_area_screen.dart
git commit -m "feat(areas): add CrearEditarAreaScreen — ADMIN creates/edits area with time pickers"
```

---

## Task 13: DisponibilidadScreen

**Files:**
- Create: `lib/features/areas/screens/disponibilidad_screen.dart`

- [ ] **Step 1: disponibilidad_screen.dart**

Los bloques se cargan directamente desde `areaComunServiceProvider`.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/area_comun.dart';
import '../models/bloque_disponibilidad.dart';
import '../models/create_reservacion_request.dart';
import '../providers/area_comun_provider.dart';
import '../providers/reservacion_provider.dart';
import '../services/area_comun_service.dart';

class DisponibilidadScreen extends ConsumerStatefulWidget {
  final int areaComunId;

  const DisponibilidadScreen({super.key, required this.areaComunId});

  @override
  ConsumerState<DisponibilidadScreen> createState() =>
      _DisponibilidadScreenState();
}

class _DisponibilidadScreenState extends ConsumerState<DisponibilidadScreen> {
  DateTime _fechaSeleccionada = DateTime.now().add(const Duration(days: 1));
  List<BloqueDisponibilidad> _bloques = [];
  bool _loadingBloques = false;
  AreaComun? _area;

  @override
  void initState() {
    super.initState();
    final state = ref.read(areaComunProvider);
    _area = state.areas
        .where((a) => a.id == widget.areaComunId)
        .firstOrNull;
    _cargarBloques();
  }

  Future<void> _cargarBloques() async {
    setState(() => _loadingBloques = true);
    try {
      final service = ref.read(areaComunServiceProvider);
      final fechaStr =
          '${_fechaSeleccionada.year}-${_fechaSeleccionada.month.toString().padLeft(2, '0')}-${_fechaSeleccionada.day.toString().padLeft(2, '0')}';
      final bloques =
          await service.obtenerDisponibilidad(widget.areaComunId, fechaStr);
      setState(() {
        _bloques = bloques;
        _loadingBloques = false;
      });
    } catch (e) {
      setState(() => _loadingBloques = false);
    }
  }

  Future<void> _seleccionarFecha() async {
    final area = _area;
    DateTime minDate = DateTime.now();
    DateTime maxDate = DateTime.now()
        .add(Duration(days: area?.anticipacionMaximaDias ?? 30));

    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: minDate,
      lastDate: maxDate,
    );
    if (picked != null) {
      setState(() => _fechaSeleccionada = picked);
      _cargarBloques();
    }
  }

  Future<void> _confirmarReservacion(BloqueDisponibilidad bloque) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar reservación'),
        content: Text(
          'Reservar ${_area?.nombre ?? "área"}\n'
          '${bloque.fechaHoraInicio.day}/${bloque.fechaHoraInicio.month}/${bloque.fechaHoraInicio.year}\n'
          '${bloque.fechaHoraInicio.hour.toString().padLeft(2, '0')}:${bloque.fechaHoraInicio.minute.toString().padLeft(2, '0')} – '
          '${bloque.fechaHoraFin.hour.toString().padLeft(2, '0')}:${bloque.fechaHoraFin.minute.toString().padLeft(2, '0')}',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirmar')),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final reservacion = await ref
          .read(reservacionProvider.notifier)
          .crearReservacion(CreateReservacionRequest(
            areaComunId: widget.areaComunId,
            fechaHoraInicio: bloque.fechaHoraInicio,
          ));
      if (mounted) {
        if (reservacion != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reservación creada exitosamente')),
          );
          _cargarBloques();
        } else {
          final error = ref.read(reservacionProvider).error;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(error ?? 'Error al crear reservación'),
                backgroundColor: Colors.red),
          );
          ref.read(reservacionProvider.notifier).clearError();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final area = _area;

    return Scaffold(
      appBar: AppBar(
        title: Text(area?.nombre ?? 'Disponibilidad'),
      ),
      body: Column(
        children: [
          if (area != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (area.descripcion != null)
                    Text(area.descripcion!,
                        style: const TextStyle(color: Colors.grey)),
                  Text(
                      'Horario: ${area.horarioInicio} – ${area.horarioFin} · Bloques de ${area.duracionBloqueMinutos} min'),
                ],
              ),
            ),
          ListTile(
            title: Text(
              'Fecha: ${_fechaSeleccionada.day.toString().padLeft(2, '0')}/${_fechaSeleccionada.month.toString().padLeft(2, '0')}/${_fechaSeleccionada.year}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: const Icon(Icons.calendar_today),
            onTap: _seleccionarFecha,
          ),
          const Divider(),
          Expanded(
            child: _loadingBloques
                ? const Center(child: CircularProgressIndicator())
                : _bloques.isEmpty
                    ? const Center(
                        child: Text('No hay bloques disponibles para esta fecha.'))
                    : Padding(
                        padding: const EdgeInsets.all(16),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _bloques.map((bloque) {
                            final label =
                                '${bloque.fechaHoraInicio.hour.toString().padLeft(2, '0')}:${bloque.fechaHoraInicio.minute.toString().padLeft(2, '0')}';
                            return ElevatedButton(
                              onPressed: bloque.disponible
                                  ? () => _confirmarReservacion(bloque)
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: bloque.disponible
                                    ? Colors.green
                                    : Colors.grey.shade300,
                                foregroundColor: bloque.disponible
                                    ? Colors.white
                                    : Colors.grey,
                              ),
                              child: Text(label),
                            );
                          }).toList(),
                        ),
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
git add lib/features/areas/screens/disponibilidad_screen.dart
git commit -m "feat(areas): add DisponibilidadScreen — date picker + block grid, confirm reservation dialog"
```

---

## Task 14: Navegación — MainScaffold + GoRouter

**Files:**
- Modify: `lib/shared/widgets/main_scaffold.dart`
- Modify: `lib/core/routes/app_router.dart`

- [ ] **Step 1: Actualizar main_scaffold.dart**

Tabs finales:
- USUARIO (9): Inicio(0), Visitas(1), Nueva(2), Paquetes(3), Incidentes(4), Cuotas(5), Áreas(6), Avisos(7), Perfil(8)
- GUARDIA (6): Escanear(0), Paquetes(1), Hoy(2), Historial(3), Avisos(4), Perfil(5) — sin cambios
- ADMIN (9): Dashboard(0), Visitas(1), Paquetes(2), Incidentes(3), Gestión(4), Cuotas(5), Áreas(6), Avisos(7), Perfil(8)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/areas/providers/area_comun_provider.dart';
import '../../features/areas/providers/reservacion_provider.dart';
import '../../features/areas/screens/areas_screen.dart';
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
    final areaNotifier = ref.read(areaComunProvider.notifier);
    switch (user.rol) {
      case Rol.usuario:
        visitaNotifier.cargarMisVisitas();
        cuotaNotifier.cargarMisCuotas();
        paqueteNotifier.cargarMisPaquetes();
        incidenteNotifier.cargarMisIncidentes();
        notificacionNotifier.cargarNotificaciones();
        areaNotifier.cargarAreas();
        ref.read(reservacionProvider.notifier).cargarMisReservaciones();
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
        areaNotifier.cargarAreas();
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
          const AreasScreen(),
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
          const AreasScreen(),
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
          BottomNavigationBarItem(icon: Icon(Icons.meeting_room_outlined), label: 'Áreas'),
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
          BottomNavigationBarItem(icon: Icon(Icons.meeting_room_outlined), label: 'Áreas'),
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
      body: IndexedStack(index: _currentIndex, children: screens),
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
import '../../features/areas/models/area_comun.dart';
import '../../features/areas/screens/crear_editar_area_screen.dart';
import '../../features/areas/screens/disponibilidad_screen.dart';
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
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: '/home',
        builder: (_, __) => const MainScaffold(),
        routes: [
          GoRoute(
            path: 'visitas/:id',
            builder: (context, state) => DetalleVisitaScreen(
                visitaId: int.parse(state.pathParameters['id']!)),
          ),
          GoRoute(
            path: 'usuarios/nuevo',
            builder: (_, __) => const CrearUsuarioScreen(),
          ),
          GoRoute(
            path: 'usuarios/:id',
            builder: (context, state) => DetalleUsuarioScreen(
                usuarioId: int.parse(state.pathParameters['id']!)),
          ),
          GoRoute(
            path: 'cuotas/nueva',
            builder: (_, __) => const CrearCuotaScreen(),
          ),
          GoRoute(
            path: 'cuotas/:id/detalle',
            builder: (context, state) => DetalleCuotaScreen(
                cuotaId: int.parse(state.pathParameters['id']!)),
          ),
          GoRoute(
            path: 'cuotas/:id/reportar',
            builder: (context, state) => ReportarPagoScreen(
                cuotaUsuarioId: int.parse(state.pathParameters['id']!)),
          ),
          GoRoute(
            path: 'paquetes/nuevo',
            builder: (_, __) => const RegistrarPaqueteScreen(),
          ),
          GoRoute(
            path: 'incidentes/nuevo',
            builder: (_, __) => const CrearIncidenteScreen(),
          ),
          GoRoute(
            path: 'incidentes/:id',
            builder: (context, state) => DetalleIncidenteScreen(
                incidenteId: int.parse(state.pathParameters['id']!)),
          ),
          GoRoute(
            path: 'notificaciones/nueva',
            builder: (_, __) => const CrearNotificacionScreen(),
          ),
          GoRoute(
            path: 'notificaciones/:id',
            builder: (context, state) => DetalleNotificacionScreen(
                notificacionId: int.parse(state.pathParameters['id']!)),
          ),
          GoRoute(
            path: 'areas/nueva',
            builder: (_, __) => const CrearEditarAreaScreen(),
          ),
          GoRoute(
            path: 'areas/:id/editar',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              final areaState = ref.read(areaComunProvider);
              final area = areaState.areas.where((a) => a.id == id).firstOrNull;
              return CrearEditarAreaScreen(area: area);
            },
          ),
          GoRoute(
            path: 'areas/:id/disponibilidad',
            builder: (context, state) => DisponibilidadScreen(
                areaComunId: int.parse(state.pathParameters['id']!)),
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
git commit -m "feat(areas): wire navigation — Áreas tab for USUARIO and ADMIN, 3 new GoRouter routes"
```

---

## Self-Review

### Spec Coverage

| Requisito spec | Task |
|---|---|
| V7 migration: `areas_comunes`, `reservaciones`, `estado_reservacion` enum | Task 1 |
| `AreaComun` entity con todos los campos incluyendo `LocalTime` horarios | Task 2 |
| `EstadoReservacion` enum (ACTIVA, CANCELADA) | Task 2 |
| `Reservacion` entity | Task 2 |
| `AreaComunRepository`: listar por condominio y por activa | Task 3 |
| `ReservacionRepository`: queries de conflicto y conteo mensual | Task 3 |
| `CuotaUsuarioRepository`: método moroso check con join a Cuota | Task 3 |
| 5 DTOs: CreateAreaComun, AreaComunResponse, BloqueDisponibilidad, CreateReservacion, ReservacionResponse | Task 4 |
| `AreaComunService`: listar (soloActivas flag), crear, editar, toggle, disponibilidad con bloques | Task 5 |
| Disponibilidad excluye bloques pasados y bloques con ACTIVA existente | Task 5 |
| `ReservacionService`: validar moroso, conflicto, límite mensual, anticipación min/max | Task 6 |
| Cancelación: USUARIO solo propia y futura; ADMIN cualquiera | Task 6 |
| `AreaComunController`: 5 endpoints con @PreAuthorize correcto | Task 7 |
| `ReservacionController`: 4 endpoints | Task 7 |
| Backend compila | Task 7 |
| Flutter models (5) + .g.dart manuales | Task 8 |
| ApiConstants: 7 constantes | Task 9 |
| `AreaComunService` Flutter con getList queryParameters | Task 9 |
| `ReservacionService` Flutter | Task 9 |
| `AreaComunProvider`: cargar, crear, editar, toggle | Task 10 |
| `ReservacionProvider`: cargar todos, mis-reservaciones, crear, cancelar (actualiza estado local) | Task 10 |
| `AreasScreen`: admin = lista con switch toggle; usuario = tabs Áreas / Mis Reservas con botón cancelar | Task 11 |
| `CrearEditarAreaScreen`: todos los campos, TimePicker, dropdown duración, Switch activa | Task 12 |
| `DisponibilidadScreen`: DatePicker, grid de bloques verde/gris, diálogo confirmación | Task 13 |
| Tab Áreas: USUARIO índice 6, ADMIN índice 6; GUARDIA sin cambios | Task 14 |
| Rutas: /home/areas/nueva, /home/areas/:id/editar, /home/areas/:id/disponibilidad | Task 14 |
| loadInitialData carga áreas y mis-reservaciones según rol | Task 14 |
| Sin foto de área | — out of scope |
| Sin pagos por área | — out of scope |
| GUARDIA sin acceso | — @PreAuthorize en controllers |
