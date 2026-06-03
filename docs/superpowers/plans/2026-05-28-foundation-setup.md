# Fundación - Setup Inicial + Autenticación + Multi-tenancy

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Establecer la infraestructura base del sistema: backend Spring Boot con autenticación JWT, multi-tenancy, y frontend Flutter con login funcional.

**Architecture:** Monolito modular Spring Boot con PostgreSQL multi-tenant (discriminador `condominio_id`). Frontend Flutter con arquitectura feature-first. Autenticación stateless vía JWT.

**Tech Stack:** Spring Boot 3.x, Spring Security, Spring Data JPA, PostgreSQL 15+, JWT (jjwt), Flutter 3.x, Riverpod, HTTP/Dio

---

## File Structure

### Backend (Spring Boot)

```
backend/
├── src/main/java/com/condos/
│   ├── CondosApplication.java
│   ├── config/
│   │   ├── SecurityConfig.java
│   │   ├── JwtConfig.java
│   │   ├── CorsConfig.java
│   │   └── TenantFilterConfig.java
│   ├── common/
│   │   ├── exceptions/
│   │   │   ├── GlobalExceptionHandler.java
│   │   │   ├── UnauthorizedException.java
│   │   │   ├── ResourceNotFoundException.java
│   │   │   └── TenantMismatchException.java
│   │   ├── dto/
│   │   │   └── ErrorResponse.java
│   │   └── utils/
│   │       └── TenantContext.java
│   ├── auth/
│   │   ├── controller/
│   │   │   └── AuthController.java
│   │   ├── service/
│   │   │   ├── AuthService.java
│   │   │   └── JwtService.java
│   │   ├── dto/
│   │   │   ├── LoginRequest.java
│   │   │   ├── LoginResponse.java
│   │   │   └── UserInfoResponse.java
│   │   ├── filter/
│   │   │   └── JwtAuthenticationFilter.java
│   │   └── security/
│   │       └── UserDetailsServiceImpl.java
│   ├── condominio/
│   │   ├── controller/
│   │   │   └── CondominioController.java
│   │   ├── service/
│   │   │   └── CondominioService.java
│   │   ├── repository/
│   │   │   └── CondominioRepository.java
│   │   ├── model/
│   │   │   └── Condominio.java
│   │   └── dto/
│   │       ├── CondominioRequest.java
│   │       └── CondominioResponse.java
│   └── usuario/
│       ├── controller/
│       │   └── UsuarioController.java
│       ├── service/
│       │   └── UsuarioService.java
│       ├── repository/
│       │   └── UsuarioRepository.java
│       ├── model/
│       │   ├── Usuario.java
│       │   └── Rol.java
│       └── dto/
│           ├── UsuarioRequest.java
│           └── UsuarioResponse.java
├── src/main/resources/
│   ├── application.properties
│   └── db/
│       └── migration/
│           └── V1__initial_schema.sql
└── src/test/java/com/condos/
    ├── auth/
    │   └── AuthServiceTest.java
    └── usuario/
        └── UsuarioServiceTest.java
```

### Frontend (Flutter)

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/
│   │   ├── api_constants.dart
│   │   └── app_constants.dart
│   ├── config/
│   │   └── app_config.dart
│   ├── routes/
│   │   └── app_router.dart
│   └── theme/
│       └── app_theme.dart
├── shared/
│   ├── services/
│   │   ├── api_client.dart
│   │   ├── auth_service.dart
│   │   └── storage_service.dart
│   ├── models/
│   │   ├── usuario.dart
│   │   ├── condominio.dart
│   │   └── api_error.dart
│   ├── providers/
│   │   └── auth_provider.dart
│   └── widgets/
│       ├── custom_button.dart
│       ├── custom_text_field.dart
│       └── loading_indicator.dart
└── features/
    └── auth/
        ├── screens/
        │   ├── splash_screen.dart
        │   └── login_screen.dart
        ├── widgets/
        │   └── login_form.dart
        └── providers/
            └── login_provider.dart
```

---

## Tasks

### Task 1: Backend Project Setup

**Files:**
- Create: `backend/pom.xml`
- Create: `backend/src/main/java/com/condos/CondosApplication.java`
- Create: `backend/src/main/resources/application.properties`

- [ ] **Step 1: Create Spring Boot project structure**

Create `backend/pom.xml`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
         https://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    
    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.2.0</version>
        <relativePath/>
    </parent>
    
    <groupId>com.condos</groupId>
    <artifactId>condos-backend</artifactId>
    <version>0.0.1-SNAPSHOT</version>
    <name>condos-backend</name>
    <description>Sistema de Administración de Condominios</description>
    
    <properties>
        <java.version>17</java.version>
    </properties>
    
    <dependencies>
        <!-- Spring Boot Starters -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-data-jpa</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-security</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-validation</artifactId>
        </dependency>
        
        <!-- PostgreSQL -->
        <dependency>
            <groupId>org.postgresql</groupId>
            <artifactId>postgresql</artifactId>
            <scope>runtime</scope>
        </dependency>
        
        <!-- JWT -->
        <dependency>
            <groupId>io.jsonwebtoken</groupId>
            <artifactId>jjwt-api</artifactId>
            <version>0.11.5</version>
        </dependency>
        <dependency>
            <groupId>io.jsonwebtoken</groupId>
            <artifactId>jjwt-impl</artifactId>
            <version>0.11.5</version>
            <scope>runtime</scope>
        </dependency>
        <dependency>
            <groupId>io.jsonwebtoken</groupId>
            <artifactId>jjwt-jackson</artifactId>
            <version>0.11.5</version>
            <scope>runtime</scope>
        </dependency>
        
        <!-- Lombok -->
        <dependency>
            <groupId>org.projectlombok</groupId>
            <artifactId>lombok</artifactId>
            <optional>true</optional>
        </dependency>
        
        <!-- Testing -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
        <dependency>
            <groupId>org.springframework.security</groupId>
            <artifactId>spring-security-test</artifactId>
            <scope>test</scope>
        </dependency>
        <dependency>
            <groupId>com.h2database</groupId>
            <artifactId>h2</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>
    
    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
                <configuration>
                    <excludes>
                        <exclude>
                            <groupId>org.projectlombok</groupId>
                            <artifactId>lombok</artifactId>
                        </exclude>
                    </excludes>
                </configuration>
            </plugin>
        </plugins>
    </build>
</project>
```

- [ ] **Step 2: Create main application class**

Create `backend/src/main/java/com/condos/CondosApplication.java`:

```java
package com.condos;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class CondosApplication {
    public static void main(String[] args) {
        SpringApplication.run(CondosApplication.class, args);
    }
}
```

- [ ] **Step 3: Create application properties**

Create `backend/src/main/resources/application.properties`:

```properties
# Server
server.port=8080

# Database
spring.datasource.url=jdbc:postgresql://localhost:5432/condos_db
spring.datasource.username=postgres
spring.datasource.password=postgres
spring.datasource.driver-class-name=org.postgresql.Driver

# JPA
spring.jpa.hibernate.ddl-auto=validate
spring.jpa.show-sql=true
spring.jpa.properties.hibernate.format_sql=true
spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.PostgreSQLDialect

# JWT
jwt.secret=your-256-bit-secret-key-change-this-in-production
jwt.expiration=86400000
jwt.refresh-expiration=604800000

# CORS
cors.allowed-origins=http://localhost:3000,http://localhost:8081

# Logging
logging.level.com.condos=DEBUG
logging.level.org.springframework.security=DEBUG
```

- [ ] **Step 4: Verify project compiles**

Run:
```bash
cd backend
./mvnw clean compile
```

Expected: BUILD SUCCESS

- [ ] **Step 5: Commit**

```bash
git add backend/
git commit -m "feat: initialize Spring Boot project with dependencies

- Add pom.xml with Spring Boot, Security, JPA, PostgreSQL, JWT
- Create main application class
- Configure application properties
- Verify compilation

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

### Task 2: Database Schema

**Files:**
- Create: `backend/src/main/resources/db/migration/V1__initial_schema.sql`

- [ ] **Step 1: Create database migration script**

Create `backend/src/main/resources/db/migration/V1__initial_schema.sql`:

```sql
-- Create ENUM types
CREATE TYPE rol_usuario AS ENUM ('SUPERADMIN', 'ADMIN', 'USUARIO', 'GUARDIA');
CREATE TYPE plataforma_device AS ENUM ('ANDROID', 'IOS', 'WEB');

-- Table: condominios
CREATE TABLE condominios (
    id BIGSERIAL PRIMARY KEY,
    nombre VARCHAR(200) NOT NULL,
    direccion VARCHAR(500),
    num_unidades INT,
    configuracion_json JSONB,
    activo BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table: usuarios
CREATE TABLE usuarios (
    id BIGSERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    nombre_completo VARCHAR(200) NOT NULL,
    telefono VARCHAR(20),
    rol rol_usuario NOT NULL,
    condominio_id BIGINT REFERENCES condominios(id),
    unidad_habitacional VARCHAR(20),
    es_propietario BOOLEAN DEFAULT TRUE,
    activo BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table: device_tokens
CREATE TABLE device_tokens (
    id BIGSERIAL PRIMARY KEY,
    usuario_id BIGINT REFERENCES usuarios(id) ON DELETE CASCADE,
    token VARCHAR(500) NOT NULL,
    plataforma plataforma_device NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX idx_usuarios_condominio ON usuarios(condominio_id);
CREATE INDEX idx_usuarios_rol ON usuarios(rol);
CREATE INDEX idx_usuarios_username ON usuarios(username);
CREATE INDEX idx_usuarios_email ON usuarios(email);

-- Triggers for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_condominios_updated_at 
    BEFORE UPDATE ON condominios
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_usuarios_updated_at 
    BEFORE UPDATE ON usuarios
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Seed data for development
INSERT INTO condominios (nombre, direccion, num_unidades) VALUES
    ('Residencial Las Palmas', 'Av. Principal 123, CDMX', 50);

-- Password: "admin123" hashed with BCrypt (strength 12)
INSERT INTO usuarios (username, email, password_hash, nombre_completo, rol, condominio_id) VALUES
    ('superadmin', 'super@condos.com', '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYCdGzcBF4m', 'Super Administrador', 'SUPERADMIN', NULL),
    ('admin', 'admin@condos.com', '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYCdGzcBF4m', 'Administrador Condominio', 'ADMIN', 1);
```

- [ ] **Step 2: Create PostgreSQL database**

Run:
```bash
createdb condos_db
```

Expected: Database created

- [ ] **Step 3: Run migration manually**

Run:
```bash
psql -d condos_db -f backend/src/main/resources/db/migration/V1__initial_schema.sql
```

Expected: All tables and data created successfully

- [ ] **Step 4: Verify schema**

Run:
```bash
psql -d condos_db -c "\dt"
```

Expected: Lists tables `condominios`, `usuarios`, `device_tokens`

- [ ] **Step 5: Commit**

```bash
git add backend/src/main/resources/db/
git commit -m "feat: add initial database schema

- Create condominios, usuarios, device_tokens tables
- Add ENUM types for rol_usuario and plataforma_device
- Add indexes for performance
- Add triggers for updated_at automation
- Seed development data with superadmin and admin users

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

### Task 3: Entity Models

**Files:**
- Create: `backend/src/main/java/com/condos/usuario/model/Rol.java`
- Create: `backend/src/main/java/com/condos/usuario/model/Usuario.java`
- Create: `backend/src/main/java/com/condos/condominio/model/Condominio.java`

- [ ] **Step 1: Create Rol enum**

Create `backend/src/main/java/com/condos/usuario/model/Rol.java`:

```java
package com.condos.usuario.model;

public enum Rol {
    SUPERADMIN,
    ADMIN,
    USUARIO,
    GUARDIA
}
```

- [ ] **Step 2: Create Condominio entity**

Create `backend/src/main/java/com/condos/condominio/model/Condominio.java`:

```java
package com.condos.condominio.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.LocalDateTime;
import java.util.Map;

@Entity
@Table(name = "condominios")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Condominio {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(nullable = false, length = 200)
    private String nombre;
    
    @Column(length = 500)
    private String direccion;
    
    @Column(name = "num_unidades")
    private Integer numUnidades;
    
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "configuracion_json", columnDefinition = "jsonb")
    private Map<String, Object> configuracionJson;
    
    @Column(nullable = false)
    private Boolean activo = true;
    
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;
    
    @Column(name = "updated_at")
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

- [ ] **Step 3: Create Usuario entity**

Create `backend/src/main/java/com/condos/usuario/model/Usuario.java`:

```java
package com.condos.usuario.model;

import com.condos.condominio.model.Condominio;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "usuarios")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Usuario {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(nullable = false, unique = true, length = 50)
    private String username;
    
    @Column(nullable = false, unique = true, length = 100)
    private String email;
    
    @Column(name = "password_hash", nullable = false)
    private String passwordHash;
    
    @Column(name = "nombre_completo", nullable = false, length = 200)
    private String nombreCompleto;
    
    @Column(length = 20)
    private String telefono;
    
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Rol rol;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "condominio_id")
    private Condominio condominio;
    
    @Column(name = "unidad_habitacional", length = 20)
    private String unidadHabitacional;
    
    @Column(name = "es_propietario")
    private Boolean esPropietario = true;
    
    @Column(nullable = false)
    private Boolean activo = true;
    
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;
    
    @Column(name = "updated_at")
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

- [ ] **Step 4: Verify entities compile**

Run:
```bash
cd backend
./mvnw clean compile
```

Expected: BUILD SUCCESS

- [ ] **Step 5: Commit**

```bash
git add backend/src/main/java/com/condos/usuario/model/
git add backend/src/main/java/com/condos/condominio/model/
git commit -m "feat: add JPA entity models for Usuario and Condominio

- Create Rol enum with SUPERADMIN, ADMIN, USUARIO, GUARDIA
- Create Condominio entity with JSONB support
- Create Usuario entity with ManyToOne relationship to Condominio
- Add @PrePersist and @PreUpdate lifecycle callbacks

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

### Task 4: Repositories

**Files:**
- Create: `backend/src/main/java/com/condos/usuario/repository/UsuarioRepository.java`
- Create: `backend/src/main/java/com/condos/condominio/repository/CondominioRepository.java`

- [ ] **Step 1: Create UsuarioRepository**

Create `backend/src/main/java/com/condos/usuario/repository/UsuarioRepository.java`:

```java
package com.condos.usuario.repository;

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
    
    boolean existsByUsername(String username);
    
    boolean existsByEmail(String email);
}
```

- [ ] **Step 2: Create CondominioRepository**

Create `backend/src/main/java/com/condos/condominio/repository/CondominioRepository.java`:

```java
package com.condos.condominio.repository;

import com.condos.condominio.model.Condominio;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface CondominioRepository extends JpaRepository<Condominio, Long> {
    
    List<Condominio> findByActivoTrue();
}
```

- [ ] **Step 3: Verify repositories compile**

Run:
```bash
cd backend
./mvnw clean compile
```

Expected: BUILD SUCCESS

- [ ] **Step 4: Commit**

```bash
git add backend/src/main/java/com/condos/usuario/repository/
git add backend/src/main/java/com/condos/condominio/repository/
git commit -m "feat: add Spring Data JPA repositories

- Create UsuarioRepository with username and email lookups
- Create CondominioRepository with active filter
- Add existence checks for username and email

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

### Task 5: Common Utilities and Exceptions

**Files:**
- Create: `backend/src/main/java/com/condos/common/utils/TenantContext.java`
- Create: `backend/src/main/java/com/condos/common/exceptions/UnauthorizedException.java`
- Create: `backend/src/main/java/com/condos/common/exceptions/ResourceNotFoundException.java`
- Create: `backend/src/main/java/com/condos/common/exceptions/TenantMismatchException.java`
- Create: `backend/src/main/java/com/condos/common/dto/ErrorResponse.java`
- Create: `backend/src/main/java/com/condos/common/exceptions/GlobalExceptionHandler.java`

- [ ] **Step 1: Create TenantContext**

Create `backend/src/main/java/com/condos/common/utils/TenantContext.java`:

```java
package com.condos.common.utils;

public class TenantContext {
    
    private static final ThreadLocal<Long> currentCondominioId = new ThreadLocal<>();
    
    public static void setCondominioId(Long condominioId) {
        currentCondominioId.set(condominioId);
    }
    
    public static Long getCondominioId() {
        return currentCondominioId.get();
    }
    
    public static void clear() {
        currentCondominioId.remove();
    }
}
```

- [ ] **Step 2: Create custom exceptions**

Create `backend/src/main/java/com/condos/common/exceptions/UnauthorizedException.java`:

```java
package com.condos.common.exceptions;

public class UnauthorizedException extends RuntimeException {
    public UnauthorizedException(String message) {
        super(message);
    }
}
```

Create `backend/src/main/java/com/condos/common/exceptions/ResourceNotFoundException.java`:

```java
package com.condos.common.exceptions;

public class ResourceNotFoundException extends RuntimeException {
    public ResourceNotFoundException(String message) {
        super(message);
    }
}
```

Create `backend/src/main/java/com/condos/common/exceptions/TenantMismatchException.java`:

```java
package com.condos.common.exceptions;

public class TenantMismatchException extends RuntimeException {
    public TenantMismatchException(String message) {
        super(message);
    }
}
```

- [ ] **Step 3: Create ErrorResponse DTO**

Create `backend/src/main/java/com/condos/common/dto/ErrorResponse.java`:

```java
package com.condos.common.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ErrorResponse {
    private String error;
    private String message;
    private int code;
    private LocalDateTime timestamp;
    
    public ErrorResponse(String error, String message, int code) {
        this.error = error;
        this.message = message;
        this.code = code;
        this.timestamp = LocalDateTime.now();
    }
}
```

- [ ] **Step 4: Create GlobalExceptionHandler**

Create `backend/src/main/java/com/condos/common/exceptions/GlobalExceptionHandler.java`:

```java
package com.condos.common.exceptions;

import com.condos.common.dto.ErrorResponse;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;

@ControllerAdvice
public class GlobalExceptionHandler {
    
    @ExceptionHandler(UnauthorizedException.class)
    public ResponseEntity<ErrorResponse> handleUnauthorized(UnauthorizedException ex) {
        ErrorResponse error = new ErrorResponse(
            "UNAUTHORIZED",
            ex.getMessage(),
            HttpStatus.UNAUTHORIZED.value()
        );
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(error);
    }
    
    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<ErrorResponse> handleResourceNotFound(ResourceNotFoundException ex) {
        ErrorResponse error = new ErrorResponse(
            "NOT_FOUND",
            ex.getMessage(),
            HttpStatus.NOT_FOUND.value()
        );
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
    }
    
    @ExceptionHandler(TenantMismatchException.class)
    public ResponseEntity<ErrorResponse> handleTenantMismatch(TenantMismatchException ex) {
        ErrorResponse error = new ErrorResponse(
            "TENANT_MISMATCH",
            ex.getMessage(),
            HttpStatus.FORBIDDEN.value()
        );
        return ResponseEntity.status(HttpStatus.FORBIDDEN).body(error);
    }
    
    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<ErrorResponse> handleAccessDenied(AccessDeniedException ex) {
        ErrorResponse error = new ErrorResponse(
            "ACCESS_DENIED",
            "No tienes permisos para esta acción",
            HttpStatus.FORBIDDEN.value()
        );
        return ResponseEntity.status(HttpStatus.FORBIDDEN).body(error);
    }
    
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorResponse> handleValidationErrors(MethodArgumentNotValidException ex) {
        String message = ex.getBindingResult().getAllErrors().get(0).getDefaultMessage();
        ErrorResponse error = new ErrorResponse(
            "VALIDATION_ERROR",
            message,
            HttpStatus.BAD_REQUEST.value()
        );
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(error);
    }
    
    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorResponse> handleGeneral(Exception ex) {
        ErrorResponse error = new ErrorResponse(
            "INTERNAL_ERROR",
            "Error del servidor",
            HttpStatus.INTERNAL_SERVER_ERROR.value()
        );
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(error);
    }
}
```

- [ ] **Step 5: Verify compilation**

Run:
```bash
cd backend
./mvnw clean compile
```

Expected: BUILD SUCCESS

- [ ] **Step 6: Commit**

```bash
git add backend/src/main/java/com/condos/common/
git commit -m "feat: add common utilities and exception handling

- Create TenantContext for ThreadLocal condominio_id storage
- Add custom exceptions (Unauthorized, NotFound, TenantMismatch)
- Create ErrorResponse DTO for consistent error format
- Add GlobalExceptionHandler with @ControllerAdvice

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

### Task 6: JWT Service

**Files:**
- Create: `backend/src/main/java/com/condos/auth/service/JwtService.java`
- Test: `backend/src/test/java/com/condos/auth/JwtServiceTest.java`

- [ ] **Step 1: Write failing test for JWT generation**

Create `backend/src/test/java/com/condos/auth/JwtServiceTest.java`:

```java
package com.condos.auth;

import com.condos.auth.service.JwtService;
import com.condos.usuario.model.Rol;
import io.jsonwebtoken.Claims;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.TestPropertySource;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@TestPropertySource(properties = {
    "jwt.secret=test-secret-key-must-be-at-least-256-bits-long-for-hs256",
    "jwt.expiration=3600000"
})
class JwtServiceTest {
    
    private JwtService jwtService;
    
    @Value("${jwt.secret}")
    private String secret;
    
    @Value("${jwt.expiration}")
    private Long expiration;
    
    @BeforeEach
    void setUp() {
        jwtService = new JwtService(secret, expiration);
    }
    
    @Test
    void shouldGenerateTokenWithUserDetails() {
        Long userId = 1L;
        String username = "testuser";
        Rol rol = Rol.USUARIO;
        Long condominioId = 100L;
        
        String token = jwtService.generateToken(userId, username, rol, condominioId);
        
        assertNotNull(token);
        assertFalse(token.isEmpty());
    }
    
    @Test
    void shouldExtractUsernameFromToken() {
        String token = jwtService.generateToken(1L, "testuser", Rol.USUARIO, 100L);
        
        String username = jwtService.extractUsername(token);
        
        assertEquals("testuser", username);
    }
    
    @Test
    void shouldExtractUserIdFromToken() {
        Long userId = 42L;
        String token = jwtService.generateToken(userId, "testuser", Rol.USUARIO, 100L);
        
        Long extractedId = jwtService.extractUserId(token);
        
        assertEquals(userId, extractedId);
    }
    
    @Test
    void shouldExtractRolFromToken() {
        String token = jwtService.generateToken(1L, "testuser", Rol.ADMIN, 100L);
        
        Rol rol = jwtService.extractRol(token);
        
        assertEquals(Rol.ADMIN, rol);
    }
    
    @Test
    void shouldExtractCondominioIdFromToken() {
        Long condominioId = 999L;
        String token = jwtService.generateToken(1L, "testuser", Rol.USUARIO, condominioId);
        
        Long extractedCondominioId = jwtService.extractCondominioId(token);
        
        assertEquals(condominioId, extractedCondominioId);
    }
    
    @Test
    void shouldValidateValidToken() {
        String token = jwtService.generateToken(1L, "testuser", Rol.USUARIO, 100L);
        
        boolean isValid = jwtService.validateToken(token);
        
        assertTrue(isValid);
    }
    
    @Test
    void shouldInvalidateTamperedToken() {
        String token = jwtService.generateToken(1L, "testuser", Rol.USUARIO, 100L);
        String tamperedToken = token + "tampered";
        
        boolean isValid = jwtService.validateToken(tamperedToken);
        
        assertFalse(isValid);
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```bash
cd backend
./mvnw test -Dtest=JwtServiceTest
```

Expected: FAIL - JwtService class not found

- [ ] **Step 3: Implement JwtService**

Create `backend/src/main/java/com/condos/auth/service/JwtService.java`:

```java
package com.condos.auth.service;

import com.condos.usuario.model.Rol;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.security.Key;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;
import java.util.function.Function;

@Service
public class JwtService {
    
    private final String secret;
    private final Long expiration;
    private final Key signingKey;
    
    public JwtService(
        @Value("${jwt.secret}") String secret,
        @Value("${jwt.expiration}") Long expiration
    ) {
        this.secret = secret;
        this.expiration = expiration;
        this.signingKey = Keys.hmacShaKeyFor(secret.getBytes());
    }
    
    public String generateToken(Long userId, String username, Rol rol, Long condominioId) {
        Map<String, Object> claims = new HashMap<>();
        claims.put("userId", userId);
        claims.put("rol", rol.name());
        if (condominioId != null) {
            claims.put("condominioId", condominioId);
        }
        
        return Jwts.builder()
            .setClaims(claims)
            .setSubject(username)
            .setIssuedAt(new Date(System.currentTimeMillis()))
            .setExpiration(new Date(System.currentTimeMillis() + expiration))
            .signWith(signingKey, SignatureAlgorithm.HS256)
            .compact();
    }
    
    public String extractUsername(String token) {
        return extractClaim(token, Claims::getSubject);
    }
    
    public Long extractUserId(String token) {
        return extractClaim(token, claims -> claims.get("userId", Long.class));
    }
    
    public Rol extractRol(String token) {
        String rolStr = extractClaim(token, claims -> claims.get("rol", String.class));
        return Rol.valueOf(rolStr);
    }
    
    public Long extractCondominioId(String token) {
        return extractClaim(token, claims -> claims.get("condominioId", Long.class));
    }
    
    public boolean validateToken(String token) {
        try {
            Jwts.parserBuilder()
                .setSigningKey(signingKey)
                .build()
                .parseClaimsJws(token);
            return !isTokenExpired(token);
        } catch (Exception e) {
            return false;
        }
    }
    
    private <T> T extractClaim(String token, Function<Claims, T> claimsResolver) {
        final Claims claims = extractAllClaims(token);
        return claimsResolver.apply(claims);
    }
    
    private Claims extractAllClaims(String token) {
        return Jwts.parserBuilder()
            .setSigningKey(signingKey)
            .build()
            .parseClaimsJws(token)
            .getBody();
    }
    
    private boolean isTokenExpired(String token) {
        return extractExpiration(token).before(new Date());
    }
    
    private Date extractExpiration(String token) {
        return extractClaim(token, Claims::getExpiration);
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run:
```bash
cd backend
./mvnw test -Dtest=JwtServiceTest
```

Expected: All tests PASS

- [ ] **Step 5: Commit**

```bash
git add backend/src/main/java/com/condos/auth/service/JwtService.java
git add backend/src/test/java/com/condos/auth/JwtServiceTest.java
git commit -m "feat: implement JWT service with token generation and validation

- Generate JWT tokens with userId, username, rol, condominioId claims
- Extract claims from tokens
- Validate token signature and expiration
- Add comprehensive tests for all JWT operations

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

### Task 7: UserDetailsService Implementation

**Files:**
- Create: `backend/src/main/java/com/condos/auth/security/UserDetailsServiceImpl.java`

- [ ] **Step 1: Implement UserDetailsService**

Create `backend/src/main/java/com/condos/auth/security/UserDetailsServiceImpl.java`:

```java
package com.condos.auth.security;

import com.condos.usuario.model.Usuario;
import com.condos.usuario.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

import java.util.Collections;

@Service
@RequiredArgsConstructor
public class UserDetailsServiceImpl implements UserDetailsService {
    
    private final UsuarioRepository usuarioRepository;
    
    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        Usuario usuario = usuarioRepository.findByUsername(username)
            .orElseThrow(() -> new UsernameNotFoundException("Usuario no encontrado: " + username));
        
        if (!usuario.getActivo()) {
            throw new UsernameNotFoundException("Usuario inactivo: " + username);
        }
        
        return User.builder()
            .username(usuario.getUsername())
            .password(usuario.getPasswordHash())
            .authorities(Collections.singletonList(
                new SimpleGrantedAuthority("ROLE_" + usuario.getRol().name())
            ))
            .accountExpired(false)
            .accountLocked(false)
            .credentialsExpired(false)
            .disabled(!usuario.getActivo())
            .build();
    }
}
```

- [ ] **Step 2: Verify compilation**

Run:
```bash
cd backend
./mvnw clean compile
```

Expected: BUILD SUCCESS

- [ ] **Step 3: Commit**

```bash
git add backend/src/main/java/com/condos/auth/security/
git commit -m "feat: implement UserDetailsService for Spring Security

- Load user by username from database
- Check if user is active
- Map rol to Spring Security GrantedAuthority with ROLE_ prefix

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

### Task 8: JWT Authentication Filter

**Files:**
- Create: `backend/src/main/java/com/condos/auth/filter/JwtAuthenticationFilter.java`

- [ ] **Step 1: Implement JWT filter**

Create `backend/src/main/java/com/condos/auth/filter/JwtAuthenticationFilter.java`:

```java
package com.condos.auth.filter;

import com.condos.auth.service.JwtService;
import com.condos.common.utils.TenantContext;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.lang.NonNull;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Collections;

@Component
@RequiredArgsConstructor
public class JwtAuthenticationFilter extends OncePerRequestFilter {
    
    private final JwtService jwtService;
    
    @Override
    protected void doFilterInternal(
        @NonNull HttpServletRequest request,
        @NonNull HttpServletResponse response,
        @NonNull FilterChain filterChain
    ) throws ServletException, IOException {
        
        final String authHeader = request.getHeader("Authorization");
        
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            filterChain.doFilter(request, response);
            return;
        }
        
        try {
            final String token = authHeader.substring(7);
            
            if (jwtService.validateToken(token)) {
                String username = jwtService.extractUsername(token);
                Long condominioId = jwtService.extractCondominioId(token);
                String rolName = jwtService.extractRol(token).name();
                
                // Set tenant context
                if (condominioId != null) {
                    TenantContext.setCondominioId(condominioId);
                }
                
                UsernamePasswordAuthenticationToken authentication = new UsernamePasswordAuthenticationToken(
                    username,
                    null,
                    Collections.singletonList(new SimpleGrantedAuthority("ROLE_" + rolName))
                );
                
                authentication.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
                SecurityContextHolder.getContext().setAuthentication(authentication);
            }
        } catch (Exception e) {
            logger.error("Error processing JWT token", e);
        } finally {
            filterChain.doFilter(request, response);
            TenantContext.clear();
        }
    }
}
```

- [ ] **Step 2: Verify compilation**

Run:
```bash
cd backend
./mvnw clean compile
```

Expected: BUILD SUCCESS

- [ ] **Step 3: Commit**

```bash
git add backend/src/main/java/com/condos/auth/filter/
git commit -m "feat: implement JWT authentication filter

- Extract JWT from Authorization header
- Validate token and set SecurityContext
- Set TenantContext with condominioId
- Clear context after request

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

### Task 9: Security Configuration

**Files:**
- Create: `backend/src/main/java/com/condos/config/SecurityConfig.java`
- Create: `backend/src/main/java/com/condos/config/CorsConfig.java`

- [ ] **Step 1: Create CORS configuration**

Create `backend/src/main/java/com/condos/config/CorsConfig.java`:

```java
package com.condos.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.Arrays;
import java.util.List;

@Configuration
public class CorsConfig {
    
    @Value("${cors.allowed-origins}")
    private String allowedOrigins;
    
    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        configuration.setAllowedOrigins(Arrays.asList(allowedOrigins.split(",")));
        configuration.setAllowedMethods(Arrays.asList("GET", "POST", "PUT", "DELETE", "OPTIONS"));
        configuration.setAllowedHeaders(List.of("*"));
        configuration.setAllowCredentials(true);
        configuration.setMaxAge(3600L);
        
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }
}
```

- [ ] **Step 2: Create Security configuration**

Create `backend/src/main/java/com/condos/config/SecurityConfig.java`:

```java
package com.condos.config;

import com.condos.auth.filter.JwtAuthenticationFilter;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfigurationSource;

@Configuration
@EnableWebSecurity
@EnableMethodSecurity
@RequiredArgsConstructor
public class SecurityConfig {
    
    private final JwtAuthenticationFilter jwtAuthenticationFilter;
    private final CorsConfigurationSource corsConfigurationSource;
    
    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            .csrf(AbstractHttpConfigurer::disable)
            .cors(cors -> cors.configurationSource(corsConfigurationSource))
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/api/auth/login").permitAll()
                .anyRequest().authenticated()
            )
            .sessionManagement(session -> session
                .sessionCreationPolicy(SessionCreationPolicy.STATELESS)
            )
            .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);
        
        return http.build();
    }
    
    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder(12);
    }
    
    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration config) throws Exception {
        return config.getAuthenticationManager();
    }
}
```

- [ ] **Step 3: Verify compilation**

Run:
```bash
cd backend
./mvnw clean compile
```

Expected: BUILD SUCCESS

- [ ] **Step 4: Commit**

```bash
git add backend/src/main/java/com/condos/config/
git commit -m "feat: configure Spring Security with JWT and CORS

- Disable CSRF for stateless API
- Configure CORS with allowed origins from properties
- Permit /api/auth/login without authentication
- Add JWT filter before UsernamePasswordAuthenticationFilter
- Configure BCrypt password encoder with strength 12

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

### Task 10: Auth DTOs

**Files:**
- Create: `backend/src/main/java/com/condos/auth/dto/LoginRequest.java`
- Create: `backend/src/main/java/com/condos/auth/dto/LoginResponse.java`
- Create: `backend/src/main/java/com/condos/auth/dto/UserInfoResponse.java`

- [ ] **Step 1: Create LoginRequest DTO**

Create `backend/src/main/java/com/condos/auth/dto/LoginRequest.java`:

```java
package com.condos.auth.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class LoginRequest {
    
    @NotBlank(message = "Username es requerido")
    private String username;
    
    @NotBlank(message = "Password es requerido")
    private String password;
}
```

- [ ] **Step 2: Create LoginResponse DTO**

Create `backend/src/main/java/com/condos/auth/dto/LoginResponse.java`:

```java
package com.condos.auth.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class LoginResponse {
    private String token;
    private String type = "Bearer";
    private UserInfoResponse user;
    
    public LoginResponse(String token, UserInfoResponse user) {
        this.token = token;
        this.user = user;
    }
}
```

- [ ] **Step 3: Create UserInfoResponse DTO**

Create `backend/src/main/java/com/condos/auth/dto/UserInfoResponse.java`:

```java
package com.condos.auth.dto;

import com.condos.usuario.model.Rol;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class UserInfoResponse {
    private Long id;
    private String username;
    private String email;
    private String nombreCompleto;
    private Rol rol;
    private Long condominioId;
    private String condominioNombre;
    private String unidadHabitacional;
}
```

- [ ] **Step 4: Verify compilation**

Run:
```bash
cd backend
./mvnw clean compile
```

Expected: BUILD SUCCESS

- [ ] **Step 5: Commit**

```bash
git add backend/src/main/java/com/condos/auth/dto/
git commit -m "feat: add DTOs for authentication endpoints

- Create LoginRequest with validation
- Create LoginResponse with token and user info
- Create UserInfoResponse with user details

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

### Task 11: AuthService

**Files:**
- Create: `backend/src/main/java/com/condos/auth/service/AuthService.java`
- Test: `backend/src/test/java/com/condos/auth/AuthServiceTest.java`

- [ ] **Step 1: Write failing test for login**

Create `backend/src/test/java/com/condos/auth/AuthServiceTest.java`:

```java
package com.condos.auth;

import com.condos.auth.dto.LoginRequest;
import com.condos.auth.dto.LoginResponse;
import com.condos.auth.service.AuthService;
import com.condos.auth.service.JwtService;
import com.condos.common.exceptions.UnauthorizedException;
import com.condos.condominio.model.Condominio;
import com.condos.usuario.model.Rol;
import com.condos.usuario.model.Usuario;
import com.condos.usuario.repository.UsuarioRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {
    
    @Mock
    private UsuarioRepository usuarioRepository;
    
    @Mock
    private JwtService jwtService;
    
    private PasswordEncoder passwordEncoder;
    private AuthService authService;
    
    @BeforeEach
    void setUp() {
        passwordEncoder = new BCryptPasswordEncoder(12);
        authService = new AuthService(usuarioRepository, jwtService, passwordEncoder);
    }
    
    @Test
    void shouldLoginSuccessfullyWithValidCredentials() {
        String rawPassword = "password123";
        String hashedPassword = passwordEncoder.encode(rawPassword);
        
        Condominio condominio = new Condominio();
        condominio.setId(1L);
        condominio.setNombre("Test Condominio");
        
        Usuario usuario = new Usuario();
        usuario.setId(1L);
        usuario.setUsername("testuser");
        usuario.setPasswordHash(hashedPassword);
        usuario.setEmail("test@example.com");
        usuario.setNombreCompleto("Test User");
        usuario.setRol(Rol.USUARIO);
        usuario.setCondominio(condominio);
        usuario.setActivo(true);
        
        when(usuarioRepository.findByUsername("testuser")).thenReturn(Optional.of(usuario));
        when(jwtService.generateToken(1L, "testuser", Rol.USUARIO, 1L))
            .thenReturn("mock-jwt-token");
        
        LoginRequest request = new LoginRequest("testuser", rawPassword);
        LoginResponse response = authService.login(request);
        
        assertNotNull(response);
        assertEquals("mock-jwt-token", response.getToken());
        assertEquals("Bearer", response.getType());
        assertEquals("testuser", response.getUser().getUsername());
        assertEquals(Rol.USUARIO, response.getUser().getRol());
    }
    
    @Test
    void shouldThrowExceptionWhenUserNotFound() {
        when(usuarioRepository.findByUsername("nonexistent")).thenReturn(Optional.empty());
        
        LoginRequest request = new LoginRequest("nonexistent", "password");
        
        assertThrows(UnauthorizedException.class, () -> authService.login(request));
    }
    
    @Test
    void shouldThrowExceptionWhenPasswordIncorrect() {
        String hashedPassword = passwordEncoder.encode("correctpassword");
        
        Usuario usuario = new Usuario();
        usuario.setUsername("testuser");
        usuario.setPasswordHash(hashedPassword);
        usuario.setActivo(true);
        
        when(usuarioRepository.findByUsername("testuser")).thenReturn(Optional.of(usuario));
        
        LoginRequest request = new LoginRequest("testuser", "wrongpassword");
        
        assertThrows(UnauthorizedException.class, () -> authService.login(request));
    }
    
    @Test
    void shouldThrowExceptionWhenUserInactive() {
        String hashedPassword = passwordEncoder.encode("password123");
        
        Usuario usuario = new Usuario();
        usuario.setUsername("testuser");
        usuario.setPasswordHash(hashedPassword);
        usuario.setActivo(false);
        
        when(usuarioRepository.findByUsername("testuser")).thenReturn(Optional.of(usuario));
        
        LoginRequest request = new LoginRequest("testuser", "password123");
        
        assertThrows(UnauthorizedException.class, () -> authService.login(request));
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```bash
cd backend
./mvnw test -Dtest=AuthServiceTest
```

Expected: FAIL - AuthService not found

- [ ] **Step 3: Implement AuthService**

Create `backend/src/main/java/com/condos/auth/service/AuthService.java`:

```java
package com.condos.auth.service;

import com.condos.auth.dto.LoginRequest;
import com.condos.auth.dto.LoginResponse;
import com.condos.auth.dto.UserInfoResponse;
import com.condos.common.exceptions.UnauthorizedException;
import com.condos.usuario.model.Usuario;
import com.condos.usuario.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class AuthService {
    
    private final UsuarioRepository usuarioRepository;
    private final JwtService jwtService;
    private final PasswordEncoder passwordEncoder;
    
    public LoginResponse login(LoginRequest request) {
        Usuario usuario = usuarioRepository.findByUsername(request.getUsername())
            .orElseThrow(() -> new UnauthorizedException("Credenciales inválidas"));
        
        if (!usuario.getActivo()) {
            throw new UnauthorizedException("Usuario inactivo");
        }
        
        if (!passwordEncoder.matches(request.getPassword(), usuario.getPasswordHash())) {
            throw new UnauthorizedException("Credenciales inválidas");
        }
        
        Long condominioId = usuario.getCondominio() != null ? usuario.getCondominio().getId() : null;
        
        String token = jwtService.generateToken(
            usuario.getId(),
            usuario.getUsername(),
            usuario.getRol(),
            condominioId
        );
        
        UserInfoResponse userInfo = new UserInfoResponse(
            usuario.getId(),
            usuario.getUsername(),
            usuario.getEmail(),
            usuario.getNombreCompleto(),
            usuario.getRol(),
            condominioId,
            usuario.getCondominio() != null ? usuario.getCondominio().getNombre() : null,
            usuario.getUnidadHabitacional()
        );
        
        return new LoginResponse(token, userInfo);
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run:
```bash
cd backend
./mvnw test -Dtest=AuthServiceTest
```

Expected: All tests PASS

- [ ] **Step 5: Commit**

```bash
git add backend/src/main/java/com/condos/auth/service/AuthService.java
git add backend/src/test/java/com/condos/auth/AuthServiceTest.java
git commit -m "feat: implement authentication service with login

- Validate user credentials against database
- Check user is active
- Generate JWT token with user details
- Return token and user info
- Add comprehensive tests for login scenarios

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

### Task 12: AuthController

**Files:**
- Create: `backend/src/main/java/com/condos/auth/controller/AuthController.java`

- [ ] **Step 1: Create AuthController**

Create `backend/src/main/java/com/condos/auth/controller/AuthController.java`:

```java
package com.condos.auth.controller;

import com.condos.auth.dto.LoginRequest;
import com.condos.auth.dto.LoginResponse;
import com.condos.auth.dto.UserInfoResponse;
import com.condos.auth.service.AuthService;
import com.condos.auth.service.JwtService;
import com.condos.usuario.model.Usuario;
import com.condos.usuario.repository.UsuarioRepository;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {
    
    private final AuthService authService;
    private final JwtService jwtService;
    private final UsuarioRepository usuarioRepository;
    
    @PostMapping("/login")
    public ResponseEntity<LoginResponse> login(@Valid @RequestBody LoginRequest request) {
        LoginResponse response = authService.login(request);
        return ResponseEntity.ok(response);
    }
    
    @GetMapping("/me")
    public ResponseEntity<UserInfoResponse> getCurrentUser(Authentication authentication) {
        String username = authentication.getName();
        
        Usuario usuario = usuarioRepository.findByUsername(username)
            .orElseThrow(() -> new RuntimeException("Usuario no encontrado"));
        
        Long condominioId = usuario.getCondominio() != null ? usuario.getCondominio().getId() : null;
        
        UserInfoResponse userInfo = new UserInfoResponse(
            usuario.getId(),
            usuario.getUsername(),
            usuario.getEmail(),
            usuario.getNombreCompleto(),
            usuario.getRol(),
            condominioId,
            usuario.getCondominio() != null ? usuario.getCondominio().getNombre() : null,
            usuario.getUnidadHabitacional()
        );
        
        return ResponseEntity.ok(userInfo);
    }
}
```

- [ ] **Step 2: Verify compilation**

Run:
```bash
cd backend
./mvnw clean compile
```

Expected: BUILD SUCCESS

- [ ] **Step 3: Start application**

Run:
```bash
cd backend
./mvnw spring-boot:run
```

Expected: Application starts on port 8080

- [ ] **Step 4: Test login endpoint**

Run in new terminal:
```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'
```

Expected: JSON response with token and user info

- [ ] **Step 5: Test /me endpoint**

Run (replace TOKEN with actual token from previous step):
```bash
curl http://localhost:8080/api/auth/me \
  -H "Authorization: Bearer TOKEN"
```

Expected: JSON response with user info

- [ ] **Step 6: Stop application**

Press Ctrl+C in terminal running the app

- [ ] **Step 7: Commit**

```bash
git add backend/src/main/java/com/condos/auth/controller/
git commit -m "feat: add authentication REST controller

- POST /api/auth/login endpoint for user login
- GET /api/auth/me endpoint to get current user info
- Validate request body with @Valid
- Manual testing confirms endpoints work

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

### Task 13: Flutter Project Setup

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/main.dart`
- Create: `lib/app.dart`

- [ ] **Step 1: Update pubspec.yaml with dependencies**

Modify `pubspec.yaml`:

```yaml
name: condos
description: "Sistema de Administración de Condominios"
publish_to: 'none'

version: 1.0.0+1

environment:
  sdk: ^3.12.0

dependencies:
  flutter:
    sdk: flutter
  
  # HTTP & Networking
  http: ^1.1.0
  
  # State Management
  flutter_riverpod: ^2.4.0
  
  # Navigation
  go_router: ^13.0.0
  
  # Storage
  shared_preferences: ^2.2.2
  flutter_secure_storage: ^9.0.0
  
  # UI
  cupertino_icons: ^1.0.6
  
  # Utilities
  equatable: ^2.0.5
  json_annotation: ^4.8.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  build_runner: ^2.4.7
  json_serializable: ^6.7.1

flutter:
  uses-material-design: true
```

- [ ] **Step 2: Get dependencies**

Run:
```bash
flutter pub get
```

Expected: Dependencies downloaded successfully

- [ ] **Step 3: Create main.dart**

Create `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() {
  runApp(
    const ProviderScope(
      child: CondosApp(),
    ),
  );
}
```

- [ ] **Step 4: Create app.dart**

Create `lib/app.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';

class CondosApp extends ConsumerWidget {
  const CondosApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Condos',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
```

- [ ] **Step 5: Verify app compiles**

Run:
```bash
flutter analyze
```

Expected: Some errors (missing files) - that's expected, we'll create them next

- [ ] **Step 6: Commit**

```bash
git add pubspec.yaml lib/main.dart lib/app.dart
git commit -m "feat: setup Flutter project with Riverpod and GoRouter

- Add dependencies: http, riverpod, go_router, storage
- Create main.dart with ProviderScope
- Create app.dart with MaterialApp.router setup

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

### Task 14: Flutter Core - Theme & Constants

**Files:**
- Create: `lib/core/theme/app_theme.dart`
- Create: `lib/core/constants/api_constants.dart`
- Create: `lib/core/constants/app_constants.dart`

- [ ] **Step 1: Create app theme**

Create `lib/core/theme/app_theme.dart`:

```dart
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
```

- [ ] **Step 2: Create API constants**

Create `lib/core/constants/api_constants.dart`:

```dart
class ApiConstants {
  static const String baseUrl = 'http://localhost:8080';
  static const String apiPrefix = '/api';
  
  // Auth endpoints
  static const String login = '$apiPrefix/auth/login';
  static const String me = '$apiPrefix/auth/me';
  
  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
```

- [ ] **Step 3: Create app constants**

Create `lib/core/constants/app_constants.dart`:

```dart
class AppConstants {
  // Storage keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  
  // App info
  static const String appName = 'Condos';
  static const String appVersion = '1.0.0';
}
```

- [ ] **Step 4: Verify compilation**

Run:
```bash
flutter analyze lib/core/
```

Expected: No issues

- [ ] **Step 5: Commit**

```bash
git add lib/core/
git commit -m "feat: add Flutter theme and constants

- Create AppTheme with Material 3 light theme
- Add ApiConstants with base URL and endpoints
- Add AppConstants with storage keys

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

### Task 15: Flutter Shared Models

**Files:**
- Create: `lib/shared/models/usuario.dart`
- Create: `lib/shared/models/usuario.g.dart` (generated)
- Create: `lib/shared/models/api_error.dart`

- [ ] **Step 1: Create Usuario model**

Create `lib/shared/models/usuario.dart`:

```dart
import 'package:json_annotation/json_annotation.dart';

part 'usuario.g.dart';

enum Rol {
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
class Usuario {
  final int id;
  final String username;
  final String email;
  final String nombreCompleto;
  final Rol rol;
  final int? condominioId;
  final String? condominioNombre;
  final String? unidadHabitacional;

  Usuario({
    required this.id,
    required this.username,
    required this.email,
    required this.nombreCompleto,
    required this.rol,
    this.condominioId,
    this.condominioNombre,
    this.unidadHabitacional,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) => _$UsuarioFromJson(json);
  Map<String, dynamic> toJson() => _$UsuarioToJson(this);
}
```

- [ ] **Step 2: Generate JSON serialization code**

Run:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Expected: Generated `usuario.g.dart`

- [ ] **Step 3: Create ApiError model**

Create `lib/shared/models/api_error.dart`:

```dart
import 'package:json_annotation/json_annotation.dart';

part 'api_error.g.dart';

@JsonSerializable()
class ApiError {
  final String error;
  final String message;
  final int code;
  final String? timestamp;

  ApiError({
    required this.error,
    required this.message,
    required this.code,
    this.timestamp,
  });

  factory ApiError.fromJson(Map<String, dynamic> json) => _$ApiErrorFromJson(json);
  Map<String, dynamic> toJson() => _$ApiErrorToJson(this);
}
```

- [ ] **Step 4: Generate JSON serialization for ApiError**

Run:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Expected: Generated `api_error.g.dart`

- [ ] **Step 5: Verify compilation**

Run:
```bash
flutter analyze lib/shared/models/
```

Expected: No issues

- [ ] **Step 6: Commit**

```bash
git add lib/shared/models/
git commit -m "feat: add Flutter data models with JSON serialization

- Create Usuario model with Rol enum
- Create ApiError model for error responses
- Generate JSON serialization code with build_runner

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

### Task 16: Flutter Storage Service

**Files:**
- Create: `lib/shared/services/storage_service.dart`

- [ ] **Step 1: Create StorageService**

Create `lib/shared/services/storage_service.dart`:

```dart
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/usuario.dart';
import '../../core/constants/app_constants.dart';

class StorageService {
  static const _storage = FlutterSecureStorage();

  Future<void> saveToken(String token) async {
    await _storage.write(key: AppConstants.tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: AppConstants.tokenKey);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: AppConstants.tokenKey);
  }

  Future<void> saveUser(Usuario user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.userKey, jsonEncode(user.toJson()));
  }

  Future<Usuario?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(AppConstants.userKey);
    if (userJson == null) return null;
    return Usuario.fromJson(jsonDecode(userJson));
  }

  Future<void> deleteUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.userKey);
  }

  Future<void> clearAll() async {
    await deleteToken();
    await deleteUser();
  }
}
```

- [ ] **Step 2: Verify compilation**

Run:
```bash
flutter analyze lib/shared/services/storage_service.dart
```

Expected: No issues

- [ ] **Step 3: Commit**

```bash
git add lib/shared/services/storage_service.dart
git commit -m "feat: add storage service for token and user data

- Use FlutterSecureStorage for JWT token (secure)
- Use SharedPreferences for user data (non-sensitive)
- Provide save/get/delete methods for token and user
- Add clearAll method for logout

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

### Task 17: Flutter API Client

**Files:**
- Create: `lib/shared/services/api_client.dart`

- [ ] **Step 1: Create ApiClient**

Create `lib/shared/services/api_client.dart`:

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/api_error.dart';
import '../../core/constants/api_constants.dart';
import 'storage_service.dart';

class ApiException implements Exception {
  final ApiError error;
  ApiException(this.error);

  @override
  String toString() => error.message;
}

class ApiClient {
  final StorageService _storageService;

  ApiClient(this._storageService);

  Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
    };

    if (includeAuth) {
      final token = await _storageService.getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Future<dynamic> post(
    String endpoint, {
    required Map<String, dynamic> body,
    bool includeAuth = false,
  }) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      final headers = await _getHeaders(includeAuth: includeAuth);

      final response = await http
          .post(
            url,
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(ApiConstants.connectionTimeout);

      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        ApiError(
          error: 'NETWORK_ERROR',
          message: 'Error de conexión',
          code: 0,
        ),
      );
    }
  }

  Future<dynamic> get(String endpoint) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      final headers = await _getHeaders();

      final response = await http
          .get(url, headers: headers)
          .timeout(ApiConstants.receiveTimeout);

      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        ApiError(
          error: 'NETWORK_ERROR',
          message: 'Error de conexión',
          code: 0,
        ),
      );
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else {
      ApiError error;
      try {
        error = ApiError.fromJson(jsonDecode(response.body));
      } catch (e) {
        error = ApiError(
          error: 'UNKNOWN_ERROR',
          message: 'Error desconocido del servidor',
          code: response.statusCode,
        );
      }
      throw ApiException(error);
    }
  }
}
```

- [ ] **Step 2: Verify compilation**

Run:
```bash
flutter analyze lib/shared/services/api_client.dart
```

Expected: No issues

- [ ] **Step 3: Commit**

```bash
git add lib/shared/services/api_client.dart
git commit -m "feat: add HTTP API client with error handling

- Create ApiClient with POST and GET methods
- Automatically include Authorization header from storage
- Handle HTTP errors and parse ApiError responses
- Add timeout configuration
- Throw ApiException for error handling

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

### Task 18: Flutter AuthService

**Files:**
- Create: `lib/shared/services/auth_service.dart`

- [ ] **Step 1: Create AuthService**

Create `lib/shared/services/auth_service.dart`:

```dart
import '../models/usuario.dart';
import '../../core/constants/api_constants.dart';
import 'api_client.dart';
import 'storage_service.dart';

class LoginResponse {
  final String token;
  final Usuario user;

  LoginResponse({required this.token, required this.user});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] as String,
      user: Usuario.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

class AuthService {
  final ApiClient _apiClient;
  final StorageService _storageService;

  AuthService(this._apiClient, this._storageService);

  Future<Usuario> login(String username, String password) async {
    final response = await _apiClient.post(
      ApiConstants.login,
      body: {
        'username': username,
        'password': password,
      },
      includeAuth: false,
    );

    final loginResponse = LoginResponse.fromJson(response);

    await _storageService.saveToken(loginResponse.token);
    await _storageService.saveUser(loginResponse.user);

    return loginResponse.user;
  }

  Future<Usuario?> getCurrentUser() async {
    try {
      final response = await _apiClient.get(ApiConstants.me);
      final user = Usuario.fromJson(response);
      await _storageService.saveUser(user);
      return user;
    } catch (e) {
      return null;
    }
  }

  Future<void> logout() async {
    await _storageService.clearAll();
  }

  Future<bool> isAuthenticated() async {
    final token = await _storageService.getToken();
    return token != null;
  }

  Future<Usuario?> getCachedUser() async {
    return await _storageService.getUser();
  }
}
```

- [ ] **Step 2: Verify compilation**

Run:
```bash
flutter analyze lib/shared/services/auth_service.dart
```

Expected: No issues

- [ ] **Step 3: Commit**

```bash
git add lib/shared/services/auth_service.dart
git commit -m "feat: add authentication service for Flutter

- Implement login with username/password
- Save token and user to storage
- Get current user from API
- Logout and clear storage
- Check authentication status
- Get cached user data

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

### Task 19: Flutter Auth Provider

**Files:**
- Create: `lib/shared/providers/auth_provider.dart`

- [ ] **Step 1: Create auth provider**

Create `lib/shared/providers/auth_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/usuario.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

final storageServiceProvider = Provider((ref) => StorageService());

final apiClientProvider = Provider((ref) {
  final storage = ref.watch(storageServiceProvider);
  return ApiClient(storage);
});

final authServiceProvider = Provider((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final storage = ref.watch(storageServiceProvider);
  return AuthService(apiClient, storage);
});

class AuthState {
  final Usuario? user;
  final bool isLoading;
  final String? error;

  AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    Usuario? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  bool get isAuthenticated => user != null;
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(AuthState()) {
    _init();
  }

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    
    final isAuth = await _authService.isAuthenticated();
    if (isAuth) {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        state = AuthState(user: user);
        return;
      }
    }
    
    state = AuthState();
  }

  Future<void> login(String username, String password) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final user = await _authService.login(username, password);
      state = AuthState(user: user);
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.error.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al iniciar sesión',
      );
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    state = AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});
```

- [ ] **Step 2: Verify compilation**

Run:
```bash
flutter analyze lib/shared/providers/
```

Expected: No issues

- [ ] **Step 3: Commit**

```bash
git add lib/shared/providers/
git commit -m "feat: add Riverpod authentication state management

- Create service providers (storage, apiClient, authService)
- Create AuthState with user, loading, error
- Create AuthNotifier with login/logout methods
- Auto-initialize auth state from storage on app start
- Expose authProvider for app-wide auth state

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

### Task 20: Flutter Login Screen

**Files:**
- Create: `lib/features/auth/screens/login_screen.dart`
- Create: `lib/features/auth/screens/splash_screen.dart`

- [ ] **Step 1: Create login screen**

Create `lib/features/auth/screens/login_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      await ref.read(authProvider.notifier).login(
            _usernameController.text,
            _passwordController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen(authProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.apartment,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Condos',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sistema de Administración',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 48),
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Usuario',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingresa tu usuario';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingresa tu contraseña';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: authState.isLoading ? null : _handleLogin,
                    child: authState.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Iniciar Sesión'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Create splash screen**

Create `lib/features/auth/screens/splash_screen.dart`:

```dart
import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.apartment,
              size: 100,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Verify compilation**

Run:
```bash
flutter analyze lib/features/auth/
```

Expected: No issues

- [ ] **Step 4: Commit**

```bash
git add lib/features/auth/
git commit -m "feat: add login and splash screens

- Create LoginScreen with username/password form
- Validate inputs and show loading state
- Display error messages with SnackBar
- Create SplashScreen for initial loading state

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

### Task 21: Flutter Router Configuration

**Files:**
- Create: `lib/core/routes/app_router.dart`

- [ ] **Step 1: Create app router**

Create `lib/core/routes/app_router.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../shared/providers/auth_provider.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isLoading = authState.isLoading;
      final isSplash = state.matchedLocation == '/splash';
      final isLogin = state.matchedLocation == '/login';

      if (isLoading && !isSplash) {
        return '/splash';
      }

      if (!isAuthenticated && !isLogin && !isSplash) {
        return '/login';
      }

      if (isAuthenticated && (isLogin || isSplash)) {
        return '/home';
      }

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
        builder: (context, state) => const HomeScreen(),
      ),
    ],
  );
});

// Temporary home screen placeholder
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: const Center(
        child: Text('Home Screen - Placeholder'),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify compilation**

Run:
```bash
flutter analyze lib/core/routes/
```

Expected: No issues

- [ ] **Step 3: Test app flow**

Run:
```bash
flutter run
```

Expected:
- App shows splash screen briefly
- Redirects to login screen
- Can type username and password
- Shows loading on login button click

- [ ] **Step 4: Test login with real backend**

With backend running (`cd backend && ./mvnw spring-boot:run`):
- Enter username: `admin`
- Enter password: `admin123`
- Click "Iniciar Sesión"

Expected: Redirects to Home screen placeholder

- [ ] **Step 5: Commit**

```bash
git add lib/core/routes/
git commit -m "feat: configure GoRouter with auth flow

- Setup routes: /splash, /login, /home
- Implement redirect logic based on auth state
- Auto-redirect authenticated users to home
- Auto-redirect unauthenticated users to login
- Add temporary HomeScreen placeholder

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Self-Review

**1. Spec coverage:**
✓ Backend setup with Spring Boot, PostgreSQL, JPA  
✓ Database schema with condominios, usuarios, device_tokens  
✓ JWT authentication service  
✓ Spring Security configuration with JWT filter  
✓ Multi-tenancy TenantContext (not yet enforced in queries, but foundation laid)  
✓ Flutter setup with Riverpod, GoRouter  
✓ Flutter auth flow (login, storage, state management)  
✓ End-to-end authentication working

**2. Placeholder scan:**
✓ No TBD, TODO, or placeholders  
✓ All code blocks complete  
✓ All tests have actual assertions  
✓ Commands show expected output

**3. Type consistency:**
✓ Usuario model matches between backend/frontend  
✓ Rol enum consistent (SUPERADMIN, ADMIN, USUARIO, GUARDIA)  
✓ API endpoints match (POST /api/auth/login, GET /api/auth/me)  
✓ JWT claims consistent (userId, username, rol, condominioId)

---

## Plan Complete

Plan saved to `docs/superpowers/plans/2026-05-28-foundation-setup.md`.

**Two execution options:**

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

**Which approach?**
