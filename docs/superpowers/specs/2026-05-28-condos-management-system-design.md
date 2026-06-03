# Sistema de Administración de Condominios Multi-Tenant

**Fecha:** 2026-05-28  
**Versión:** 1.0  
**Estado:** Diseño Aprobado

## 1. Resumen Ejecutivo

Sistema multi-tenant de administración de condominios desarrollado en Flutter (Android, iOS, Web) con backend Spring Boot y PostgreSQL. Soporta 4 roles (Superadmin, Admin de Condominio, Usuario, Guardia) y 7 módulos principales: Visitas con QR, Paquetes, Usuarios/Roles, Áreas Comunes con reservaciones, Notificaciones segmentadas, Incidentes con seguimiento, y Pagos con comprobantes.

### Objetivos Principales
- Digitalizar la gestión operativa de condominios
- Mejorar comunicación entre administración y residentes
- Automatizar procesos de visitas, paquetes, reservaciones y pagos
- Proporcionar transparencia en incidentes y seguimiento

### Stack Tecnológico
- **Frontend:** Flutter 3.x (multi-plataforma)
- **Backend:** Spring Boot 3.x + Spring Security + Spring Data JPA
- **Base de Datos:** PostgreSQL 15+
- **Autenticación:** JWT (JSON Web Tokens)
- **Notificaciones:** Firebase Cloud Messaging (FCM)
- **Storage:** Sistema de archivos local o S3-compatible

---

## 2. Arquitectura General

### 2.1 Patrón Arquitectónico

**Monolito Modular** - Backend Spring Boot único con módulos bien separados, consumido por Flutter vía API REST.

**Justificación:**
- Desarrollo más rápido para MVP
- Menor complejidad operacional
- Transacciones entre módulos más simples (ej: morosidad → bloquear reservaciones)
- Posibilidad de evolucionar a microservicios si escala

### 2.2 Multi-Tenancy

**Estrategia:** Base de datos compartida con discriminador `condominio_id`

**Implementación:**
- Todas las tablas principales incluyen columna `condominio_id`
- Filtro automático a nivel JPA/Hibernate para aislar datos
- Tabla `condominios` como entidad raíz
- Superadmin puede acceder a múltiples condominios
- Otros roles están vinculados a un solo condominio

### 2.3 Arquitectura de Capas

**Backend (Spring Boot):**
```
┌─────────────────────────────┐
│   Controller Layer (REST)   │  ← Endpoints HTTP
├─────────────────────────────┤
│   Service Layer             │  ← Lógica de negocio
├─────────────────────────────┤
│   Repository Layer (JPA)    │  ← Acceso a datos
├─────────────────────────────┤
│   PostgreSQL Database       │  ← Persistencia
└─────────────────────────────┘
```

**Frontend (Flutter):**
```
lib/
  ├── core/              # Configuración, constantes, rutas, theme
  ├── shared/            # Widgets, servicios, modelos compartidos
  │   ├── widgets/       # Componentes reutilizables
  │   ├── services/      # API client, auth, storage
  │   ├── models/        # Modelos de dominio
  │   └── utils/         # Helpers, extensiones
  └── features/          # Módulos por funcionalidad
      ├── auth/
      ├── visits/
      ├── packages/
      ├── users/
      ├── common_areas/
      ├── notifications/
      ├── incidents/
      └── payments/
```

---

## 3. Modelo de Datos

### 3.1 Entidades Principales

#### Usuarios y Autenticación

**`condominios`**
- `id` (PK, BIGINT)
- `nombre` (VARCHAR 200)
- `direccion` (VARCHAR 500)
- `num_unidades` (INT)
- `configuracion_json` (JSONB) - Configuraciones específicas
- `activo` (BOOLEAN)
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)

**`usuarios`**
- `id` (PK, BIGINT)
- `username` (VARCHAR 50, UNIQUE)
- `email` (VARCHAR 100, UNIQUE)
- `password_hash` (VARCHAR 255)
- `nombre_completo` (VARCHAR 200)
- `telefono` (VARCHAR 20)
- `rol` (ENUM: SUPERADMIN, ADMIN, USUARIO, GUARDIA)
- `condominio_id` (FK → condominios, NULL para Superadmin)
- `unidad_habitacional` (VARCHAR 20) - Ej: "Torre A-101"
- `es_propietario` (BOOLEAN) - vs inquilino
- `activo` (BOOLEAN)
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)

**`device_tokens`**
- `id` (PK, BIGINT)
- `usuario_id` (FK → usuarios)
- `token` (VARCHAR 500)
- `plataforma` (ENUM: ANDROID, IOS, WEB)
- `created_at` (TIMESTAMP)

#### Visitas

**`visitas`**
- `id` (PK, BIGINT)
- `condominio_id` (FK → condominios)
- `usuario_id` (FK → usuarios) - Quien programa
- `nombre_visitante` (VARCHAR 200)
- `telefono_visitante` (VARCHAR 20)
- `fecha_hora_programada` (TIMESTAMP)
- `codigo_qr_hash` (VARCHAR 500, UNIQUE) - Hash del QR
- `motivo` (VARCHAR 500)
- `vehiculo_placas` (VARCHAR 20, NULL)
- `estado` (ENUM: PROGRAMADA, COMPLETADA, CANCELADA)
- `fecha_hora_entrada` (TIMESTAMP, NULL)
- `guardia_entrada_id` (FK → usuarios, NULL)
- `notas` (TEXT, NULL)
- `created_at` (TIMESTAMP)

#### Paquetes

**`paquetes`**
- `id` (PK, BIGINT)
- `condominio_id` (FK → condominios)
- `usuario_destinatario_id` (FK → usuarios)
- `descripcion` (VARCHAR 500)
- `fecha_hora_llegada` (TIMESTAMP)
- `guardia_registro_id` (FK → usuarios)
- `foto_url` (VARCHAR 500, NULL)
- `estado` (ENUM: PENDIENTE, ENTREGADO)
- `fecha_hora_entrega` (TIMESTAMP, NULL)
- `guardia_entrega_id` (FK → usuarios, NULL)
- `notas` (TEXT, NULL)
- `created_at` (TIMESTAMP)

#### Áreas Comunes

**`areas_comunes`**
- `id` (PK, BIGINT)
- `condominio_id` (FK → condominios)
- `nombre` (VARCHAR 100)
- `descripcion` (TEXT)
- `capacidad` (INT)
- `horario_inicio` (TIME) - Ej: 08:00
- `horario_fin` (TIME) - Ej: 22:00
- `duracion_bloque_minutos` (INT) - Ej: 60, 120, 240
- `max_reservas_mes_por_usuario` (INT)
- `anticipacion_minima_horas` (INT)
- `anticipacion_maxima_dias` (INT)
- `activa` (BOOLEAN)
- `foto_url` (VARCHAR 500, NULL)
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)

**`reservaciones`**
- `id` (PK, BIGINT)
- `area_comun_id` (FK → areas_comunes)
- `usuario_id` (FK → usuarios)
- `fecha_hora_inicio` (TIMESTAMP)
- `fecha_hora_fin` (TIMESTAMP)
- `estado` (ENUM: ACTIVA, CANCELADA, COMPLETADA)
- `created_at` (TIMESTAMP)

#### Notificaciones

**`notificaciones`**
- `id` (PK, BIGINT)
- `condominio_id` (FK → condominios)
- `admin_creador_id` (FK → usuarios)
- `titulo` (VARCHAR 200)
- `mensaje` (TEXT)
- `segmento_destino` (ENUM: TODOS, EDIFICIO_X, MOROSOS, PROPIETARIOS)
- `edificio_numero` (VARCHAR 20, NULL) - Si segmento = EDIFICIO_X
- `fecha_publicacion` (TIMESTAMP)
- `fecha_expiracion` (TIMESTAMP, NULL)
- `created_at` (TIMESTAMP)

**`notificaciones_leidas`**
- `id` (PK, BIGINT)
- `notificacion_id` (FK → notificaciones)
- `usuario_id` (FK → usuarios)
- `fecha_lectura` (TIMESTAMP)

#### Incidentes

**`incidentes`**
- `id` (PK, BIGINT)
- `condominio_id` (FK → condominios)
- `usuario_reporta_id` (FK → usuarios)
- `categoria` (ENUM: MANTENIMIENTO, SEGURIDAD, RUIDO, LIMPIEZA, OTRO)
- `titulo` (VARCHAR 200)
- `descripcion` (TEXT)
- `ubicacion` (VARCHAR 200) - Área común o unidad
- `prioridad` (ENUM: BAJA, MEDIA, ALTA)
- `estado` (ENUM: PENDIENTE, EN_PROCESO, RESUELTO)
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)

**`incidentes_fotos`**
- `id` (PK, BIGINT)
- `incidente_id` (FK → incidentes)
- `foto_url` (VARCHAR 500)
- `created_at` (TIMESTAMP)

**`incidentes_comentarios`**
- `id` (PK, BIGINT)
- `incidente_id` (FK → incidentes)
- `usuario_id` (FK → usuarios)
- `comentario` (TEXT)
- `created_at` (TIMESTAMP)

#### Pagos

**`conceptos_pago`**
- `id` (PK, BIGINT)
- `condominio_id` (FK → condominios)
- `nombre` (VARCHAR 100) - Ej: "Mantenimiento Mensual"
- `monto_default` (DECIMAL 10,2)
- `descripcion` (TEXT)
- `periodicidad` (ENUM: MENSUAL, UNICO)
- `dia_vencimiento` (INT) - Día del mes (1-31)
- `activo` (BOOLEAN)
- `created_at` (TIMESTAMP)

**`recibos`**
- `id` (PK, BIGINT)
- `condominio_id` (FK → condominios)
- `usuario_id` (FK → usuarios)
- `concepto_pago_id` (FK → conceptos_pago)
- `periodo` (VARCHAR 20) - Ej: "2024-05"
- `monto` (DECIMAL 10,2)
- `fecha_emision` (DATE)
- `fecha_vencimiento` (DATE)
- `estado` (ENUM: PENDIENTE, PAGADO, RECHAZADO)
- `comprobante_url` (VARCHAR 500, NULL)
- `fecha_pago` (TIMESTAMP, NULL)
- `admin_aprobo_id` (FK → usuarios, NULL)
- `fecha_aprobacion` (TIMESTAMP, NULL)
- `notas_admin` (TEXT, NULL)
- `created_at` (TIMESTAMP)

**`informacion_pago`**
- `id` (PK, BIGINT)
- `condominio_id` (FK → condominios, UNIQUE)
- `instrucciones_pago_text` (TEXT) - Datos bancarios, referencias
- `updated_at` (TIMESTAMP)

### 3.2 Índices Importantes

```sql
-- Multi-tenancy performance
CREATE INDEX idx_usuarios_condominio ON usuarios(condominio_id);
CREATE INDEX idx_visitas_condominio ON visitas(condominio_id);
CREATE INDEX idx_paquetes_condominio ON paquetes(condominio_id);
CREATE INDEX idx_reservaciones_area ON reservaciones(area_comun_id, fecha_hora_inicio);

-- Business logic queries
CREATE INDEX idx_recibos_usuario_estado ON recibos(usuario_id, estado, fecha_vencimiento);
CREATE INDEX idx_visitas_qr ON visitas(codigo_qr_hash);
CREATE INDEX idx_paquetes_usuario_estado ON paquetes(usuario_destinatario_id, estado);
```

### 3.3 Cálculo de Morosos

**No se almacena como campo**, se calcula en tiempo real:

```sql
SELECT DISTINCT u.id, u.nombre_completo, u.unidad_habitacional
FROM usuarios u
JOIN recibos r ON r.usuario_id = u.id
WHERE r.estado = 'PENDIENTE'
  AND r.fecha_vencimiento < CURRENT_DATE
  AND u.condominio_id = ?
ORDER BY u.unidad_habitacional;
```

---

## 4. Autenticación y Autorización

### 4.1 Flujo de Autenticación JWT

1. Usuario envía credenciales a `POST /api/auth/login`
2. Backend valida contra PostgreSQL (password con BCrypt)
3. Si válido, genera JWT con claims:
   - `userId` (Long)
   - `username` (String)
   - `rol` (String)
   - `condominioId` (Long, null para Superadmin)
4. Token expira en 24 horas, refresh token en 7 días
5. Flutter almacena tokens en `FlutterSecureStorage`
6. Cada request incluye: `Authorization: Bearer {token}`
7. Spring Security valida token con filtro `JwtAuthenticationFilter`

### 4.2 Matriz de Permisos

| Funcionalidad | Superadmin | Admin | Usuario | Guardia |
|---------------|-----------|-------|---------|---------|
| **Gestión de Condominios** |
| CRUD Condominios | ✓ | - | - | - |
| **Gestión de Usuarios** |
| CRUD Usuarios (todos) | ✓ | - | - | - |
| CRUD Usuarios (mismo condo) | ✓ | ✓ | - | - |
| Ver perfil propio | ✓ | ✓ | ✓ | ✓ |
| **Visitas** |
| Programar visita | - | ✓ | ✓ | - |
| Ver visitas programadas | ✓ | ✓ | ✓ (propias) | ✓ (todas) |
| Escanear QR / Registrar entrada | - | - | - | ✓ |
| **Paquetes** |
| Registrar paquete | - | - | - | ✓ |
| Marcar como entregado | - | - | - | ✓ |
| Ver paquetes | ✓ | ✓ | ✓ (propios) | ✓ |
| **Áreas Comunes** |
| CRUD Áreas | ✓ | ✓ | - | - |
| Reservar área | - | ✓ | ✓* | - |
| Ver disponibilidad | ✓ | ✓ | ✓ | - |
| **Notificaciones** |
| Crear notificación | ✓ | ✓ | - | - |
| Ver notificaciones | ✓ | ✓ | ✓ | ✓ |
| **Incidentes** |
| Crear incidente | - | - | ✓ | - |
| Gestionar incidentes (todos) | ✓ | ✓ | - | - |
| Ver incidentes propios | - | - | ✓ | - |
| Comentar en incidentes | ✓ | ✓ | ✓ | - |
| **Pagos** |
| CRUD Conceptos de pago | ✓ | ✓ | - | - |
| Generar recibos | ✓ | ✓ | - | - |
| Ver recibos (todos) | ✓ | ✓ | - | - |
| Ver recibos propios | - | - | ✓ | - |
| Subir comprobante | - | - | ✓ | - |
| Aprobar/Rechazar pago | ✓ | ✓ | - | - |
| Ver lista de morosos | ✓ | ✓ | - | - |

**\* Usuario solo puede reservar si NO es moroso**

### 4.3 Implementación en Spring Security

**Configuración:**
```java
@PreAuthorize("hasAnyRole('ADMIN', 'SUPERADMIN')")
public ResponseEntity<Area> crearArea(@RequestBody AreaDTO dto) { ... }

@PreAuthorize("hasRole('USUARIO')")
public ResponseEntity<Reservacion> reservarArea(@RequestBody ReservacionDTO dto) {
    // Validar morosidad en Service layer
}
```

**Filtro de Multi-tenancy:**
```java
@Aspect
public class TenantFilterAspect {
    @Before("execution(* com.condos.*.repository.*.*(..))")
    public void applyTenantFilter(JoinPoint joinPoint) {
        // Inyectar condominio_id en WHERE clause automáticamente
    }
}
```

### 4.4 Seguridad Adicional

- Passwords hasheados con BCrypt (strength 12)
- CORS configurado para dominios específicos
- Rate limiting en `/api/auth/login` (5 intentos por IP/minuto)
- Validación de entrada con Bean Validation (`@Valid`, `@NotNull`, `@Size`)
- SQL Injection prevenido por JPA/PreparedStatements
- XSS prevenido por sanitización en frontend
- HTTPS obligatorio en producción

---

## 5. Estructura de Módulos Backend

### 5.1 Organización del Código

```
src/main/java/com/condos/
  ├── CondosApplication.java
  ├── config/
  │   ├── SecurityConfig.java
  │   ├── JwtConfig.java
  │   ├── CorsConfig.java
  │   └── TenantFilterConfig.java
  ├── common/
  │   ├── exceptions/
  │   ├── dto/
  │   └── utils/
  ├── auth/
  │   ├── controller/AuthController.java
  │   ├── service/AuthService.java
  │   ├── dto/LoginRequest.java, LoginResponse.java
  │   └── JwtUtil.java
  ├── condominios/
  │   ├── controller/CondominioController.java
  │   ├── service/CondominioService.java
  │   ├── repository/CondominioRepository.java
  │   ├── model/Condominio.java
  │   └── dto/...
  ├── usuarios/
  │   ├── controller/UsuarioController.java
  │   ├── service/UsuarioService.java
  │   ├── repository/UsuarioRepository.java
  │   ├── model/Usuario.java
  │   └── dto/...
  ├── visitas/
  │   ├── controller/VisitaController.java
  │   ├── service/VisitaService.java
  │   ├── repository/VisitaRepository.java
  │   ├── model/Visita.java
  │   ├── dto/...
  │   └── QrCodeService.java
  ├── paquetes/
  │   ├── controller/PaqueteController.java
  │   ├── service/PaqueteService.java
  │   ├── repository/PaqueteRepository.java
  │   ├── model/Paquete.java
  │   └── dto/...
  ├── areas/
  │   ├── controller/AreaController.java, ReservacionController.java
  │   ├── service/AreaService.java, ReservacionService.java
  │   ├── repository/AreaRepository.java, ReservacionRepository.java
  │   ├── model/AreaComun.java, Reservacion.java
  │   └── dto/...
  ├── notificaciones/
  │   ├── controller/NotificacionController.java
  │   ├── service/NotificacionService.java, FcmService.java
  │   ├── repository/NotificacionRepository.java
  │   ├── model/Notificacion.java, NotificacionLeida.java
  │   └── dto/...
  ├── incidentes/
  │   ├── controller/IncidenteController.java
  │   ├── service/IncidenteService.java
  │   ├── repository/IncidenteRepository.java, ComentarioRepository.java
  │   ├── model/Incidente.java, IncidenteFoto.java, IncidenteComentario.java
  │   └── dto/...
  └── pagos/
      ├── controller/PagoController.java, ReciboController.java
      ├── service/PagoService.java, ReciboService.java, PdfService.java
      ├── repository/ConceptoPagoRepository.java, ReciboRepository.java
      ├── model/ConceptoPago.java, Recibo.java, InformacionPago.java
      └── dto/...
```

### 5.2 Endpoints REST Principales

#### Auth
- `POST /api/auth/login` - Login (público)
- `POST /api/auth/refresh` - Refresh token
- `GET /api/auth/me` - Información del usuario actual
- `POST /api/auth/logout` - Invalidar token

#### Condominios (Solo Superadmin)
- `GET /api/condominios` - Listar condominios
- `POST /api/condominios` - Crear condominio
- `GET /api/condominios/{id}` - Ver detalle
- `PUT /api/condominios/{id}` - Actualizar
- `DELETE /api/condominios/{id}` - Desactivar

#### Usuarios
- `GET /api/usuarios` - Listar (Admin ve su condo, Superadmin todos)
- `POST /api/usuarios` - Crear usuario
- `GET /api/usuarios/{id}` - Ver detalle
- `PUT /api/usuarios/{id}` - Actualizar
- `DELETE /api/usuarios/{id}` - Desactivar
- `PUT /api/usuarios/{id}/rol` - Cambiar rol

#### Visitas
- `POST /api/visitas` - Programar visita (genera QR)
- `GET /api/visitas` - Listar visitas
- `GET /api/visitas/{id}` - Ver detalle
- `POST /api/visitas/validar-qr` - Escanear QR y registrar entrada (Guardia)
- `PUT /api/visitas/{id}/cancelar` - Cancelar visita

#### Paquetes
- `POST /api/paquetes` - Registrar paquete (Guardia)
- `GET /api/paquetes` - Listar paquetes
- `GET /api/paquetes/{id}` - Ver detalle
- `PUT /api/paquetes/{id}/entregar` - Marcar como entregado (Guardia)

#### Áreas Comunes
- `GET /api/areas` - Listar áreas
- `POST /api/areas` - Crear área (Admin)
- `GET /api/areas/{id}` - Ver detalle
- `PUT /api/areas/{id}` - Actualizar (Admin)
- `DELETE /api/areas/{id}` - Desactivar (Admin)
- `GET /api/areas/{id}/disponibilidad?fecha=YYYY-MM-DD` - Ver slots disponibles
- `POST /api/reservaciones` - Crear reservación (valida morosidad)
- `GET /api/reservaciones` - Listar reservaciones
- `DELETE /api/reservaciones/{id}` - Cancelar reservación

#### Notificaciones
- `POST /api/notificaciones` - Crear notificación (Admin)
- `GET /api/notificaciones` - Listar (filtradas por segmento del usuario)
- `GET /api/notificaciones/{id}` - Ver detalle
- `POST /api/notificaciones/{id}/marcar-leida` - Marcar como leída
- `DELETE /api/notificaciones/{id}` - Eliminar (Admin)

#### Incidentes
- `POST /api/incidentes` - Crear incidente (Usuario)
- `GET /api/incidentes` - Listar (Usuario ve suyos, Admin todos)
- `GET /api/incidentes/{id}` - Ver detalle con comentarios
- `PUT /api/incidentes/{id}` - Actualizar estado/prioridad (Admin)
- `POST /api/incidentes/{id}/comentarios` - Agregar comentario
- `POST /api/incidentes/{id}/fotos` - Subir foto

#### Pagos
- `GET /api/conceptos-pago` - Listar conceptos
- `POST /api/conceptos-pago` - Crear concepto (Admin)
- `PUT /api/conceptos-pago/{id}` - Actualizar concepto (Admin)
- `POST /api/recibos/generar` - Generar recibos del mes (Admin)
- `GET /api/recibos` - Listar recibos
- `GET /api/recibos/{id}` - Ver detalle
- `GET /api/recibos/{id}/download` - Descargar PDF
- `POST /api/recibos/{id}/comprobante` - Subir comprobante (Usuario)
- `PUT /api/recibos/{id}/aprobar` - Aprobar pago (Admin)
- `PUT /api/recibos/{id}/rechazar` - Rechazar pago (Admin)
- `GET /api/pagos/info` - Ver instrucciones de pago
- `PUT /api/pagos/info` - Actualizar instrucciones (Admin)
- `GET /api/morosos` - Lista de morosos (Admin)

#### Archivos
- `GET /api/files/{path}` - Servir archivos (con validación de permisos)
- `POST /api/upload` - Subir archivo genérico

---

## 6. Estructura de Módulos Frontend (Flutter)

### 6.1 Organización por Features

Cada feature sigue esta estructura interna:
```
feature_name/
  ├── screens/       # Páginas completas (Scaffold)
  ├── widgets/       # Componentes UI específicos del feature
  ├── services/      # Lógica de API calls
  ├── models/        # Modelos de datos
  └── providers/     # State management (Riverpod)
```

### 6.2 Features Detalladas

#### Auth (`features/auth/`)
**Screens:**
- `splash_screen.dart` - Verifica token, redirige a login o home
- `login_screen.dart` - Formulario de login

**Services:**
- `auth_service.dart` - Login, logout, refresh, validación de token

**Providers:**
- `auth_provider.dart` - Estado global de autenticación (usuario, rol, condominio)

#### Visits (`features/visits/`)
**Screens:**
- `visits_list_screen.dart` - Lista de visitas programadas
- `create_visit_screen.dart` - Formulario para programar visita
- `qr_detail_screen.dart` - Pantalla mostrando QR generado
- `scan_qr_screen.dart` - Escanear QR (Guardia)

**Widgets:**
- `visit_card.dart` - Card de visita con detalles
- `qr_display_widget.dart` - Display del código QR

**Services:**
- `visits_service.dart` - CRUD visitas, validar QR

#### Packages (`features/packages/`)
**Screens:**
- `packages_list_screen.dart` - Lista de paquetes
- `register_package_screen.dart` - Registrar paquete (Guardia)
- `package_detail_screen.dart` - Detalle de paquete con foto

**Widgets:**
- `package_card.dart` - Card de paquete

**Services:**
- `packages_service.dart` - CRUD paquetes

#### Users (`features/users/`)
**Screens:**
- `users_list_screen.dart` - Lista de usuarios (Admin)
- `user_form_screen.dart` - Crear/editar usuario
- `user_detail_screen.dart` - Perfil de usuario

**Services:**
- `users_service.dart` - CRUD usuarios

#### Common Areas (`features/common_areas/`)
**Screens:**
- `areas_list_screen.dart` - Lista de áreas comunes
- `area_form_screen.dart` - CRUD áreas (Admin)
- `area_detail_screen.dart` - Detalle de área con galería
- `create_reservation_screen.dart` - Calendario de disponibilidad y reservar
- `my_reservations_screen.dart` - Mis reservaciones activas

**Widgets:**
- `availability_calendar.dart` - Calendario con slots disponibles/ocupados
- `area_card.dart` - Card de área común
- `reservation_card.dart` - Card de reservación

**Services:**
- `areas_service.dart` - CRUD áreas, disponibilidad, reservaciones

#### Notifications (`features/notifications/`)
**Screens:**
- `notifications_dashboard.dart` - Dashboard de notificaciones
- `create_notification_screen.dart` - Crear notificación (Admin)
- `notification_detail_screen.dart` - Detalle de notificación

**Widgets:**
- `notification_card.dart` - Card de notificación con badge de leído/no leído
- `segmentation_selector.dart` - Selector de segmento (Admin)

**Services:**
- `notifications_service.dart` - CRUD notificaciones, marcar leídas
- `fcm_service.dart` - Manejo de push notifications

#### Incidents (`features/incidents/`)
**Screens:**
- `incidents_list_screen.dart` - Lista de incidentes
- `create_incident_screen.dart` - Crear incidente con fotos
- `incident_detail_screen.dart` - Detalle con timeline y comentarios

**Widgets:**
- `incident_card.dart` - Card de incidente con categoría y estado
- `incident_timeline.dart` - Timeline de cambios de estado
- `comment_section.dart` - Sección de comentarios bidireccionales
- `photo_gallery.dart` - Galería de fotos del incidente

**Services:**
- `incidents_service.dart` - CRUD incidentes, comentarios, fotos

#### Payments (`features/payments/`)
**Screens:**
- `receipts_list_screen.dart` - Lista de recibos (tabs: pendientes/pagados)
- `receipt_detail_screen.dart` - Detalle de recibo con botón de descarga PDF
- `upload_proof_screen.dart` - Subir comprobante de pago (Usuario)
- `payment_info_screen.dart` - Ver instrucciones de pago
- `manage_payment_concepts_screen.dart` - CRUD conceptos (Admin)
- `generate_receipts_screen.dart` - Generar recibos del mes (Admin)
- `debtors_list_screen.dart` - Lista de morosos (Admin)

**Widgets:**
- `receipt_card.dart` - Card de recibo con estado
- `payment_status_badge.dart` - Badge de estado (pendiente/pagado/rechazado)

**Services:**
- `payments_service.dart` - CRUD conceptos, recibos, comprobantes, morosos
- `pdf_service.dart` - Descargar y abrir PDFs

### 6.3 Navegación

**Bottom Navigation Bar (Usuario/Admin):**
- Inicio (Dashboard personalizado por rol)
- Visitas
- Paquetes
- Áreas
- Incidentes
- Pagos

**Bottom Navigation Bar (Guardia):**
- Inicio
- Visitas (Escanear QR)
- Paquetes (Registrar/Entregar)

**Drawer Lateral (Todos):**
- Perfil
- Notificaciones (badge con contador de no leídas)
- Configuración
- Cerrar Sesión

**Dashboard por Rol:**
- **Superadmin:** Estadísticas globales, lista de condominios, acceso rápido a gestión
- **Admin:** Resumen del condominio (usuarios activos, paquetes pendientes, incidentes abiertos, morosos, próximas reservaciones)
- **Usuario:** Resumen personal (próximas visitas, paquetes pendientes, recibos por pagar, incidentes propios)
- **Guardia:** Pendientes del día (visitas programadas hoy, paquetes no entregados)

### 6.4 State Management

**Riverpod** (recomendado sobre Provider por simplicidad y performance):

**Providers Globales:**
- `authProvider` - Estado de autenticación (usuario, token, rol)
- `condominioProvider` - Datos del condominio actual
- `fcmProvider` - Manejo de notificaciones push

**Providers por Feature:**
- `visitsProvider` - Lista de visitas
- `packagesProvider` - Lista de paquetes
- `areasProvider` - Lista de áreas comunes
- `reservationsProvider` - Reservaciones del usuario
- `notificationsProvider` - Notificaciones (con contador de no leídas)
- `incidentsProvider` - Lista de incidentes
- `receiptsProvider` - Lista de recibos

**Patrón:**
```dart
final visitsProvider = StateNotifierProvider<VisitsNotifier, AsyncValue<List<Visita>>>((ref) {
  return VisitsNotifier(ref.read(visitsServiceProvider));
});
```

---

## 7. Flujos de Usuario Principales

### 7.1 Flujo: Programar y Recibir Visita

**Actores:** Usuario (residente), Guardia, Visitante

**Pasos:**
1. Usuario abre app → navega a "Visitas" → tap en "Nueva Visita"
2. Llena formulario:
   - Nombre del visitante
   - Teléfono (opcional)
   - Fecha y hora programada (DateTimePicker)
   - Motivo de la visita
   - Placas de vehículo (opcional)
3. Tap "Programar" → `POST /api/visitas`
4. Backend:
   - Crea registro en tabla `visitas`
   - Genera código QR único con formato: `VISIT:{id}:{hash}:{timestamp}`
   - Hash = SHA256(visita_id + secret_key + timestamp)
   - Devuelve visita con QR en Base64
5. Flutter muestra pantalla `qr_detail_screen.dart` con:
   - Código QR grande
   - Detalles de la visita
   - Botón "Compartir" (genera imagen y abre share sheet)
6. Usuario comparte QR por WhatsApp/SMS al visitante
7. Visitante llega a caseta → muestra QR (impreso o en pantalla)
8. Guardia abre app → tap "Escanear QR" → cámara se activa
9. Guardia escanea código → `POST /api/visitas/validar-qr { qrCode: "..." }`
10. Backend valida:
    - Decodifica QR y verifica hash
    - Verifica que visita existe y estado = PROGRAMADA
    - Verifica que fecha_hora_programada es hoy
    - Si válido: actualiza estado = COMPLETADA, fecha_hora_entrada = now, guardia_entrada_id
11. Backend devuelve datos del visitante y residente
12. Guardia ve confirmación en pantalla con detalles
13. Backend envía push notification al Usuario: "Tu visita [nombre] ha ingresado a las [hora]"
14. Usuario recibe notificación en tiempo real

**Manejo de Errores:**
- QR inválido/falsificado → "Código QR no válido"
- Visita ya completada → "Esta visita ya fue registrada anteriormente"
- Fecha incorrecta → "Esta visita está programada para [fecha]"

### 7.2 Flujo: Reservar Área Común

**Actores:** Usuario (residente), Sistema

**Pasos:**
1. Usuario abre app → navega a "Áreas Comunes"
2. Ve lista de áreas disponibles (Salón de fiestas, Gimnasio, Alberca, etc.)
3. Tap en área → pantalla de detalle muestra:
   - Fotos del área
   - Descripción y capacidad
   - Horarios disponibles (08:00 - 22:00)
   - Duración de bloques (ej: 4 horas)
   - Reglas (máx 2 reservas/mes, anticipación 24hrs mínimo)
4. Tap "Reservar" → abre calendario de disponibilidad
5. `GET /api/areas/{id}/disponibilidad?fecha=2024-05-15`
6. Backend calcula slots:
   - Genera bloques según `duracion_bloque_minutos` dentro de horario
   - Consulta reservaciones existentes para marcar ocupados
   - Devuelve array: `[{inicio, fin, disponible}]`
7. Flutter muestra calendario con slots verdes (disponibles) y grises (ocupados)
8. Usuario selecciona slot → tap "Confirmar Reservación"
9. `POST /api/reservaciones { area_id, fecha_hora_inicio, fecha_hora_fin }`
10. Backend valida:
    - Usuario no es moroso (query a tabla recibos)
    - Slot sigue disponible (no hay reservación en ese rango)
    - Usuario no excede límite de reservas del mes
    - Anticipación cumple reglas del área
11. Si todo válido:
    - Crea registro en tabla `reservaciones` con estado ACTIVA
    - Devuelve 201 Created
12. Flutter muestra confirmación y redirige a "Mis Reservaciones"
13. Usuario ve su reservación listada con fecha, hora y área

**Manejo de Errores:**
- Usuario moroso → `403 Forbidden` con mensaje: "No puedes reservar áreas comunes debido a pagos pendientes vencidos. Contacta a administración."
- Slot ya ocupado → `409 Conflict`: "Este horario ya fue reservado por otro residente"
- Límite excedido → `400 Bad Request`: "Ya tienes 2 reservaciones este mes (límite máximo)"

### 7.3 Flujo: Reportar y Dar Seguimiento a Incidente

**Actores:** Usuario (residente), Admin

**Pasos:**
1. Usuario abre app → "Incidentes" → "Reportar Incidente"
2. Llena formulario:
   - Categoría (dropdown: Mantenimiento, Seguridad, Ruido, Limpieza, Otro)
   - Título (ej: "Fuga de agua en alberca")
   - Descripción detallada
   - Ubicación (ej: "Área común - Alberca")
   - Fotos (hasta 5 imágenes)
3. Tap "Reportar" → `POST /api/incidentes` (multipart/form-data)
4. Backend:
   - Crea incidente con estado PENDIENTE, prioridad BAJA (default)
   - Guarda fotos en `/uploads/{condominio_id}/incidentes/{incidente_id}/`
   - Crea registros en `incidentes_fotos`
   - Envía push notification a todos los Admins del condominio
5. Flutter muestra confirmación: "Incidente reportado. Recibirás notificaciones sobre su estado."
6. Admin recibe notificación → abre app → ve incidente en dashboard
7. Admin tap en incidente → pantalla de detalle muestra:
   - Título, descripción, fotos
   - Reportado por: [nombre] - Unidad [X]
   - Fecha de reporte
   - Estado actual y prioridad
   - Timeline vacío
   - Sección de comentarios vacía
8. Admin evalúa → tap "Actualizar" → selecciona:
   - Prioridad: ALTA
   - Estado: EN_PROCESO
   - Agrega comentario: "Hemos contactado al técnico de plomería. Estará allí mañana."
9. `PUT /api/incidentes/{id}` + `POST /api/incidentes/{id}/comentarios`
10. Backend:
    - Actualiza incidente
    - Guarda comentario
    - Envía push al Usuario reportante
11. Usuario recibe notificación → abre incidente → ve:
    - Timeline: "Prioridad cambiada a ALTA", "Estado: En proceso"
    - Comentario del admin visible
12. Usuario agrega comentario de respuesta: "¿A qué hora exactamente?"
13. `POST /api/incidentes/{id}/comentarios`
14. Admin recibe notificación → responde: "Entre 10am y 12pm"
15. Técnico resuelve problema → Admin actualiza:
    - Estado: RESUELTO
    - Comentario: "Problema solucionado. Se reemplazó tubería dañada."
16. Usuario recibe notificación final → ve incidente marcado como resuelto

**Timeline muestra:**
```
[28/05/24 10:30] Incidente creado - Prioridad: BAJA, Estado: PENDIENTE
[28/05/24 11:00] Admin cambió prioridad a ALTA
[28/05/24 11:00] Admin cambió estado a EN_PROCESO
[29/05/24 14:30] Admin cambió estado a RESUELTO
```

### 7.4 Flujo: Ciclo Completo de Pago Mensual

**Actores:** Admin, Usuario (residente)

**Fase 1: Configuración (una vez)**
1. Admin abre app → "Pagos" → "Conceptos de Pago" → "Nuevo Concepto"
2. Configura:
   - Nombre: "Mantenimiento Mensual"
   - Monto default: $1,500.00
   - Periodicidad: MENSUAL
   - Día de vencimiento: 10 (cada mes día 10)
   - Activo: Sí
3. `POST /api/conceptos-pago`
4. Admin también configura instrucciones de pago:
   - "Pagos" → "Información de Pago" → edita texto con:
     - Número de cuenta bancaria
     - CLABE interbancaria
     - Referencia (usar número de unidad)
5. `PUT /api/pagos/info`

**Fase 2: Generación de Recibos (inicio de mes)**
1. Admin abre app → "Pagos" → "Generar Recibos"
2. Selecciona:
   - Concepto: "Mantenimiento Mensual"
   - Periodo: "Mayo 2024"
   - Fecha de emisión: 01/05/2024
   - Fecha de vencimiento: 10/05/2024 (auto-calculada según concepto)
3. Tap "Generar para todos los residentes"
4. `POST /api/recibos/generar { concepto_id, periodo, fecha_emision }`
5. Backend:
   - Query todos los usuarios con rol USUARIO del condominio
   - Crea un recibo por cada usuario con estado PENDIENTE
   - Monto individual puede variar (algunos pagan más/menos según unidad)
6. Backend envía push notification a todos: "Tu recibo de Mayo 2024 está disponible"

**Fase 3: Usuario paga**
1. Usuario recibe notificación → abre app → "Pagos"
2. Ve recibo con badge rojo "PENDIENTE":
   - Concepto: Mantenimiento Mensual
   - Periodo: Mayo 2024
   - Monto: $1,500.00
   - Vence: 10/05/2024
3. Tap en recibo → pantalla de detalle:
   - Botón "Descargar PDF"
   - Botón "Ver Instrucciones de Pago"
   - Botón "Subir Comprobante"
4. Tap "Ver Instrucciones" → modal con datos bancarios
5. Usuario hace transferencia en su banco
6. Regresa a app → tap "Subir Comprobante" → selecciona foto/PDF del voucher
7. `POST /api/recibos/{id}/comprobante` (multipart)
8. Backend:
   - Guarda archivo en `/uploads/{condo}/comprobantes/{recibo_id}/`
   - Actualiza `recibo.comprobante_url`
   - Estado sigue PENDIENTE (esperando aprobación)
   - Envía push al Admin: "Nuevo comprobante de pago - [Usuario] - Unidad [X]"
9. Usuario ve en app: "Comprobante subido. Pendiente de aprobación."

**Fase 4: Admin aprueba**
1. Admin recibe notificación → abre "Pagos" → tab "Pendientes de Aprobar"
2. Ve lista de recibos con comprobantes subidos
3. Tap en recibo → ve:
   - Datos del recibo
   - Imagen del comprobante
   - Botones: "Aprobar" / "Rechazar"
4. Admin verifica que transferencia coincide → tap "Aprobar"
5. `PUT /api/recibos/{id}/aprobar`
6. Backend:
   - Actualiza estado = PAGADO
   - Guarda admin_aprobo_id y fecha_aprobacion
   - Envía push al Usuario: "Tu pago de Mayo fue aprobado"
7. Usuario recibe notificación → ve recibo con badge verde "PAGADO"

**Fase 5: Usuario moroso (escenario alternativo)**
1. Usuario NO sube comprobante antes del vencimiento (10/05/2024)
2. Sistema no hace nada automáticamente (no hay cron jobs)
3. Admin abre "Morosos" → `GET /api/morosos`
4. Backend query en tiempo real:
   ```sql
   SELECT usuarios WHERE EXISTS (
     recibos con estado PENDIENTE y fecha_vencimiento < hoy
   )
   ```
5. Admin ve lista de morosos con:
   - Nombre, Unidad
   - Número de recibos vencidos
   - Monto total adeudado
6. Mientras tanto, Usuario moroso intenta reservar área común:
7. `POST /api/reservaciones` → Backend valida morosidad → devuelve 403
8. Flutter muestra: "No puedes reservar áreas comunes. Tienes pagos pendientes vencidos."
9. Usuario revisa "Pagos" → ve recibo vencido → sube comprobante → Admin aprueba
10. Usuario ya puede reservar nuevamente

### 7.5 Flujo: Gestión de Paquetes

**Actores:** Guardia, Usuario (residente)

**Fase 1: Llega paquete**
1. Paquete llega a caseta → Guardia abre app → "Paquetes" → "Registrar Paquete"
2. Llena formulario:
   - Busca residente (por nombre o unidad) → autocomplete
   - Descripción: "Caja Amazon, tamaño mediano"
   - Toma foto del paquete
3. `POST /api/paquetes` (multipart con foto)
4. Backend:
   - Crea paquete con estado PENDIENTE
   - Guarda foto
   - Guarda guardia_registro_id
   - Envía push al Usuario: "Tienes un paquete en caseta"
5. Flutter muestra confirmación al Guardia

**Fase 2: Usuario recoge**
1. Usuario recibe notificación → abre app → "Paquetes"
2. Ve paquete pendiente:
   - Descripción
   - Foto
   - Fecha de llegada
   - Badge "PENDIENTE DE RECOGER"
3. Usuario va a caseta (no necesita mostrar nada en app)
4. Guardia busca paquete físicamente → entrega
5. Guardia abre app → "Paquetes" → filtra por PENDIENTE → tap en paquete
6. Tap "Marcar como Entregado"
7. `PUT /api/paquetes/{id}/entregar`
8. Backend:
   - Actualiza estado = ENTREGADO
   - Guarda fecha_hora_entrega y guardia_entrega_id
9. Usuario ve en app que paquete cambió a estado ENTREGADO con timestamp

**Historial:**
- Usuario puede ver historial de todos sus paquetes (entregados y pendientes)
- Guardia puede ver todos los paquetes del día/semana

---

## 8. Consideraciones Técnicas

### 8.1 Generación de Códigos QR

**Librería Backend:** `com.google.zxing:core:3.5.x` (ZXing)

**Formato del código:**
```
VISIT:{visita_id}:{hash_seguridad}:{timestamp}
```

**Generación del hash:**
```java
String input = visita.getId() + SECRET_KEY + timestamp;
String hash = DigestUtils.sha256Hex(input);
```

**Proceso:**
```java
QRCodeWriter qrCodeWriter = new QRCodeWriter();
BitMatrix bitMatrix = qrCodeWriter.encode(qrData, BarcodeFormat.QR_CODE, 300, 300);
ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
MatrixToImageWriter.writeToStream(bitMatrix, "PNG", outputStream);
byte[] qrBytes = outputStream.toByteArray();
String qrBase64 = Base64.getEncoder().encodeToString(qrBytes);
return qrBase64; // Se devuelve al frontend
```

**Frontend Flutter:**
```dart
// Librería: qr_flutter
QrImageView(
  data: visitaQrCode,
  version: QrVersions.auto,
  size: 280.0,
)
```

### 8.2 Notificaciones Push (Firebase Cloud Messaging)

**Setup:**
1. Proyecto Firebase configurado para Android/iOS/Web
2. `google-services.json` (Android) y `GoogleService-Info.plist` (iOS)
3. Flutter: `firebase_core`, `firebase_messaging` packages

**Registro de Device Token:**
```dart
final fcmToken = await FirebaseMessaging.instance.getToken();
// POST /api/usuarios/device-token { token, plataforma }
```

**Backend envía notificaciones:**
```java
@Service
public class FcmService {
    public void sendNotification(List<String> tokens, String title, String body, Map<String, String> data) {
        MulticastMessage message = MulticastMessage.builder()
            .putAllData(data)
            .setNotification(Notification.builder()
                .setTitle(title)
                .setBody(body)
                .build())
            .addAllTokens(tokens)
            .build();
        
        FirebaseMessaging.getInstance().sendMulticast(message);
    }
}
```

**Eventos que disparan notificaciones:**
- Visita programada próxima (1 hora antes)
- Visitante ingresó (escanearon QR)
- Paquete registrado
- Incidente actualizado (cambio de estado/comentario)
- Recibo generado
- Comprobante aprobado/rechazado
- Nueva notificación del admin
- Reservación próxima (24hrs antes)

### 8.3 Manejo de Imágenes y Archivos

**Storage Strategy:** Sistema de archivos local (para MVP), migrable a S3/MinIO

**Estructura de directorios:**
```
/var/condos/uploads/
  ├── {condominio_id}/
      ├── paquetes/
      │   └── {paquete_id}/
      │       └── {uuid}.jpg
      ├── incidentes/
      │   └── {incidente_id}/
      │       ├── {uuid}.jpg
      │       └── {uuid}.png
      ├── areas/
      │   └── {area_id}/
      │       └── {uuid}.jpg
      └── comprobantes/
          └── {recibo_id}/
              └── {uuid}.pdf
```

**Upload Endpoint:**
```java
@PostMapping(value = "/upload", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
public ResponseEntity<FileResponse> upload(
    @RequestParam("file") MultipartFile file,
    @RequestParam("tipo") String tipo, // paquetes, incidentes, etc
    @RequestParam("entityId") Long entityId
) {
    String filename = UUID.randomUUID() + getExtension(file);
    Path path = Paths.get(UPLOAD_DIR, getCurrentCondominioId(), tipo, entityId, filename);
    Files.copy(file.getInputStream(), path);
    
    String url = "/api/files/" + path.toString();
    return ResponseEntity.ok(new FileResponse(url));
}
```

**Servir archivos con seguridad:**
```java
@GetMapping("/files/**")
public ResponseEntity<Resource> serveFile(HttpServletRequest request) {
    String filepath = request.getRequestURI().substring("/api/files/".length());
    
    // Validar que el usuario tiene permiso para ver este archivo
    // (basado en condominio_id en el path y rol)
    
    Resource file = new FileSystemResource(filepath);
    return ResponseEntity.ok()
        .contentType(MediaType.APPLICATION_OCTET_STREAM)
        .body(file);
}
```

**Límites:**
- Tamaño máximo por archivo: 10MB (configurable)
- Formatos permitidos: JPG, PNG, PDF
- Máximo 5 imágenes por incidente

### 8.4 Generación de PDFs (Recibos)

**Librería:** `com.itextpdf:itext7-core:7.2.x`

**Template de Recibo:**
```java
@Service
public class PdfService {
    public byte[] generarReciboPdf(Recibo recibo) {
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        PdfWriter writer = new PdfWriter(baos);
        PdfDocument pdf = new PdfDocument(writer);
        Document document = new Document(pdf);
        
        // Header con logo del condominio
        Image logo = new Image(ImageDataFactory.create(LOGO_PATH));
        document.add(logo);
        
        // Datos del condominio
        document.add(new Paragraph(recibo.getCondominio().getNombre()));
        
        // Título
        document.add(new Paragraph("RECIBO DE PAGO")
            .setFontSize(18)
            .setBold());
        
        // Datos del recibo
        document.add(new Paragraph("Folio: " + recibo.getId()));
        document.add(new Paragraph("Periodo: " + recibo.getPeriodo()));
        document.add(new Paragraph("Residente: " + recibo.getUsuario().getNombreCompleto()));
        document.add(new Paragraph("Unidad: " + recibo.getUsuario().getUnidadHabitacional()));
        
        // Tabla de conceptos
        Table table = new Table(2);
        table.addHeaderCell("Concepto");
        table.addHeaderCell("Monto");
        table.addCell(recibo.getConceptoPago().getNombre());
        table.addCell("$" + recibo.getMonto());
        document.add(table);
        
        // Footer con instrucciones
        document.add(new Paragraph("\nInstrucciones de pago:"));
        document.add(new Paragraph(recibo.getCondominio().getInformacionPago()));
        
        document.close();
        return baos.toByteArray();
    }
}
```

**Endpoint:**
```java
@GetMapping("/recibos/{id}/download")
public ResponseEntity<byte[]> downloadRecibo(@PathVariable Long id) {
    Recibo recibo = reciboRepository.findById(id);
    byte[] pdf = pdfService.generarReciboPdf(recibo);
    
    return ResponseEntity.ok()
        .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=recibo-" + id + ".pdf")
        .contentType(MediaType.APPLICATION_PDF)
        .body(pdf);
}
```

### 8.5 Validaciones de Negocio Críticas

**1. Validación de Morosidad (antes de reservar):**
```java
public boolean esUsuarioMoroso(Long usuarioId) {
    LocalDate hoy = LocalDate.now();
    long recibosVencidos = reciboRepository.countByUsuarioIdAndEstadoAndFechaVencimientoBefore(
        usuarioId, 
        EstadoRecibo.PENDIENTE, 
        hoy
    );
    return recibosVencidos > 0;
}

@PreAuthorize("hasRole('USUARIO')")
public Reservacion crearReservacion(ReservacionDTO dto) {
    if (esUsuarioMoroso(getCurrentUserId())) {
        throw new MorosidadException("No puedes reservar áreas comunes con pagos vencidos");
    }
    // ... resto de validaciones
}
```

**2. Validación de Límite de Reservas:**
```java
public void validarLimiteReservaciones(Long usuarioId, Long areaId) {
    AreaComun area = areaRepository.findById(areaId);
    
    LocalDate inicioMes = LocalDate.now().withDayOfMonth(1);
    LocalDate finMes = inicioMes.plusMonths(1).minusDays(1);
    
    long reservasEnMes = reservacionRepository.countByUsuarioIdAndAreaIdAndFechaBetween(
        usuarioId,
        areaId,
        inicioMes.atStartOfDay(),
        finMes.atTime(23, 59, 59)
    );
    
    if (reservasEnMes >= area.getMaxReservasMesPorUsuario()) {
        throw new LimiteReservacionesException(
            "Ya alcanzaste el límite de " + area.getMaxReservasMesPorUsuario() + " reservaciones por mes"
        );
    }
}
```

**3. Validación de Disponibilidad de Slot:**
```java
public boolean slotDisponible(Long areaId, LocalDateTime inicio, LocalDateTime fin) {
    long conflictos = reservacionRepository.countByAreaIdAndEstadoAndFechaConflicto(
        areaId,
        EstadoReservacion.ACTIVA,
        inicio,
        fin
    );
    return conflictos == 0;
}

// Query en Repository:
@Query("SELECT COUNT(r) FROM Reservacion r WHERE r.areaComun.id = :areaId " +
       "AND r.estado = :estado " +
       "AND ((r.fechaHoraInicio < :fin AND r.fechaHoraFin > :inicio))")
long countByAreaIdAndEstadoAndFechaConflicto(
    @Param("areaId") Long areaId,
    @Param("estado") EstadoReservacion estado,
    @Param("inicio") LocalDateTime inicio,
    @Param("fin") LocalDateTime fin
);
```

**4. Validación de QR:**
```java
public Visita validarYRegistrarQr(String qrCode) {
    // Formato: VISIT:{id}:{hash}:{timestamp}
    String[] parts = qrCode.split(":");
    if (parts.length != 4 || !parts[0].equals("VISIT")) {
        throw new QrInvalidoException("Código QR inválido");
    }
    
    Long visitaId = Long.parseLong(parts[1]);
    String hashRecibido = parts[2];
    String timestamp = parts[3];
    
    Visita visita = visitaRepository.findById(visitaId)
        .orElseThrow(() -> new QrInvalidoException("Visita no encontrada"));
    
    // Validar hash
    String hashEsperado = generarHash(visitaId, timestamp);
    if (!hashRecibido.equals(hashEsperado)) {
        throw new QrInvalidoException("Código QR adulterado");
    }
    
    // Validar estado
    if (visita.getEstado() == EstadoVisita.COMPLETADA) {
        throw new QrInvalidoException("Esta visita ya fue registrada");
    }
    
    // Validar fecha
    LocalDate hoy = LocalDate.now();
    LocalDate fechaProgramada = visita.getFechaHoraProgramada().toLocalDate();
    if (!hoy.equals(fechaProgramada)) {
        throw new QrInvalidoException("Esta visita está programada para " + fechaProgramada);
    }
    
    // Registrar entrada
    visita.setEstado(EstadoVisita.COMPLETADA);
    visita.setFechaHoraEntrada(LocalDateTime.now());
    visita.setGuardiaEntradaId(getCurrentUserId());
    
    return visitaRepository.save(visita);
}
```

### 8.6 Manejo de Errores

**Backend - Exception Handler Global:**
```java
@ControllerAdvice
public class GlobalExceptionHandler {
    
    @ExceptionHandler(MorosidadException.class)
    public ResponseEntity<ErrorResponse> handleMorosidad(MorosidadException ex) {
        return ResponseEntity
            .status(HttpStatus.FORBIDDEN)
            .body(new ErrorResponse("MOROSIDAD", ex.getMessage(), 403));
    }
    
    @ExceptionHandler(QrInvalidoException.class)
    public ResponseEntity<ErrorResponse> handleQrInvalido(QrInvalidoException ex) {
        return ResponseEntity
            .status(HttpStatus.BAD_REQUEST)
            .body(new ErrorResponse("QR_INVALIDO", ex.getMessage(), 400));
    }
    
    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<ErrorResponse> handleAccessDenied(AccessDeniedException ex) {
        return ResponseEntity
            .status(HttpStatus.FORBIDDEN)
            .body(new ErrorResponse("ACCESS_DENIED", "No tienes permisos para esta acción", 403));
    }
    
    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorResponse> handleGeneral(Exception ex) {
        log.error("Error no manejado", ex);
        return ResponseEntity
            .status(HttpStatus.INTERNAL_SERVER_ERROR)
            .body(new ErrorResponse("INTERNAL_ERROR", "Error del servidor", 500));
    }
}

@Data
public class ErrorResponse {
    private String error;
    private String message;
    private int code;
    private LocalDateTime timestamp = LocalDateTime.now();
}
```

**Flutter - Manejo de Errores:**
```dart
class ApiException implements Exception {
  final String error;
  final String message;
  final int code;
  
  ApiException(this.error, this.message, this.code);
  
  static ApiException fromJson(Map<String, dynamic> json) {
    return ApiException(
      json['error'] ?? 'UNKNOWN',
      json['message'] ?? 'Error desconocido',
      json['code'] ?? 500,
    );
  }
}

// En services:
Future<Reservacion> crearReservacion(ReservacionDTO dto) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/reservaciones'),
      body: jsonEncode(dto.toJson()),
      headers: {'Authorization': 'Bearer $token'},
    );
    
    if (response.statusCode == 201) {
      return Reservacion.fromJson(jsonDecode(response.body));
    } else {
      final error = ApiException.fromJson(jsonDecode(response.body));
      throw error;
    }
  } catch (e) {
    rethrow;
  }
}

// En UI:
void _reservarArea() async {
  try {
    await ref.read(areasServiceProvider).crearReservacion(dto);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('¡Área reservada exitosamente!')),
    );
  } on ApiException catch (e) {
    String mensaje = e.message;
    if (e.error == 'MOROSIDAD') {
      mensaje = 'No puedes reservar áreas comunes. Tienes pagos vencidos pendientes.';
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
    );
  }
}
```

### 8.7 Paginación

**Backend - Spring Data:**
```java
@GetMapping("/incidentes")
public ResponseEntity<Page<Incidente>> listarIncidentes(
    @RequestParam(defaultValue = "0") int page,
    @RequestParam(defaultValue = "20") int size,
    @RequestParam(defaultValue = "createdAt,desc") String[] sort
) {
    Pageable pageable = PageRequest.of(page, size, Sort.by(parseSort(sort)));
    Page<Incidente> incidentes = incidenteService.listar(pageable);
    return ResponseEntity.ok(incidentes);
}
```

**Response:**
```json
{
  "content": [...],
  "pageable": {
    "pageNumber": 0,
    "pageSize": 20
  },
  "totalPages": 5,
  "totalElements": 98,
  "last": false,
  "first": true
}
```

**Flutter - Infinite Scroll:**
```dart
class IncidentsList extends StatefulWidget {
  @override
  _IncidentsListState createState() => _IncidentsListState();
}

class _IncidentsListState extends State<IncidentsList> {
  final ScrollController _scrollController = ScrollController();
  List<Incidente> _incidentes = [];
  int _currentPage = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  
  @override
  void initState() {
    super.initState();
    _loadIncidentes();
    _scrollController.addListener(_onScroll);
  }
  
  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _loadIncidentes();
      }
    }
  }
  
  Future<void> _loadIncidentes() async {
    setState(() => _isLoading = true);
    
    final page = await incidentesService.listar(_currentPage);
    
    setState(() {
      _incidentes.addAll(page.content);
      _currentPage++;
      _hasMore = !page.last;
      _isLoading = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: _incidentes.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _incidentes.length) {
          return Center(child: CircularProgressIndicator());
        }
        return IncidentCard(incidente: _incidentes[index]);
      },
    );
  }
}
```

### 8.8 Testing

**Backend - Unit Tests (JUnit + Mockito):**
```java
@ExtendWith(MockitoExtension.class)
class ReservacionServiceTest {
    
    @Mock
    private ReservacionRepository reservacionRepository;
    
    @Mock
    private ReciboRepository reciboRepository;
    
    @InjectMocks
    private ReservacionService reservacionService;
    
    @Test
    void debeRechazarReservacionSiUsuarioMoroso() {
        // Given
        Long usuarioId = 1L;
        when(reciboRepository.countByUsuarioIdAndEstadoAndFechaVencimientoBefore(
            eq(usuarioId), eq(EstadoRecibo.PENDIENTE), any()
        )).thenReturn(2L);
        
        // When & Then
        assertThrows(MorosidadException.class, () -> {
            reservacionService.crear(new ReservacionDTO());
        });
    }
    
    @Test
    void debeCrearReservacionSiUsuarioNoMoroso() {
        // Given
        when(reciboRepository.countByUsuarioIdAndEstadoAndFechaVencimientoBefore(
            any(), any(), any()
        )).thenReturn(0L);
        
        when(reservacionRepository.countByAreaIdAndEstadoAndFechaConflicto(
            any(), any(), any(), any()
        )).thenReturn(0L);
        
        // When
        Reservacion reservacion = reservacionService.crear(new ReservacionDTO());
        
        // Then
        assertNotNull(reservacion);
        verify(reservacionRepository).save(any());
    }
}
```

**Flutter - Widget Tests:**
```dart
void main() {
  group('VisitCard Widget', () {
    testWidgets('muestra detalles de visita correctamente', (tester) async {
      final visita = Visita(
        id: 1,
        nombreVisitante: 'Juan Pérez',
        fechaHoraProgramada: DateTime.now(),
        estado: EstadoVisita.programada,
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VisitCard(visita: visita),
          ),
        ),
      );
      
      expect(find.text('Juan Pérez'), findsOneWidget);
      expect(find.text('PROGRAMADA'), findsOneWidget);
    });
  });
  
  group('Reservacion Service', () {
    test('lanza excepción si usuario moroso', () async {
      final mockClient = MockHttpClient();
      when(mockClient.post(any, body: any, headers: any))
        .thenAnswer((_) async => http.Response(
          '{"error": "MOROSIDAD", "message": "Usuario moroso"}',
          403,
        ));
      
      final service = ReservacionService(client: mockClient);
      
      expect(
        () => service.crearReservacion(ReservacionDTO()),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
```

**Priorizar tests en:**
- Autenticación y autorización
- Validaciones de negocio (morosidad, disponibilidad)
- Generación de QR y validación
- Cálculo de morosos
- Segmentación de notificaciones

### 8.9 Deployment

**Backend (Spring Boot JAR):**
```bash
# Build
./mvnw clean package -DskipTests

# Deploy en servidor
scp target/condos-0.0.1.jar user@server:/opt/condos/
ssh user@server "sudo systemctl restart condos"
```

**Systemd Service:**
```ini
[Unit]
Description=Condos Management API
After=postgresql.service

[Service]
Type=simple
User=condos
ExecStart=/usr/bin/java -jar /opt/condos/condos-0.0.1.jar
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

**PostgreSQL:**
- Managed Database (DigitalOcean, AWS RDS) recomendado
- Backups automáticos diarios
- Replicación para alta disponibilidad (producción)

**Flutter Web:**
```bash
flutter build web --release
# Deploy a Netlify/Vercel/Firebase Hosting
```

**Flutter Mobile:**
```bash
# Android
flutter build apk --release
# o
flutter build appbundle --release  # Para Google Play

# iOS
flutter build ios --release
# Subir a TestFlight vía Xcode
```

**Nginx Reverse Proxy:**
```nginx
server {
    listen 80;
    server_name api.condos.com;
    
    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

**Variables de Entorno (application.properties):**
```properties
spring.datasource.url=${DB_URL}
spring.datasource.username=${DB_USER}
spring.datasource.password=${DB_PASSWORD}
jwt.secret=${JWT_SECRET}
firebase.credentials.path=${FIREBASE_CREDENTIALS}
upload.directory=${UPLOAD_DIR:/var/condos/uploads}
```

---

## 9. Dependencias y Configuración

### 9.1 Backend - pom.xml (Spring Boot)

```xml
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
    </dependency>
    <dependency>
        <groupId>io.jsonwebtoken</groupId>
        <artifactId>jjwt-jackson</artifactId>
        <version>0.11.5</version>
    </dependency>
    
    <!-- QR Code Generation -->
    <dependency>
        <groupId>com.google.zxing</groupId>
        <artifactId>core</artifactId>
        <version>3.5.2</version>
    </dependency>
    <dependency>
        <groupId>com.google.zxing</groupId>
        <artifactId>javase</artifactId>
        <version>3.5.2</version>
    </dependency>
    
    <!-- PDF Generation -->
    <dependency>
        <groupId>com.itextpdf</groupId>
        <artifactId>itext7-core</artifactId>
        <version>7.2.5</version>
        <type>pom</type>
    </dependency>
    
    <!-- Firebase Admin SDK (FCM) -->
    <dependency>
        <groupId>com.google.firebase</groupId>
        <artifactId>firebase-admin</artifactId>
        <version>9.2.0</version>
    </dependency>
    
    <!-- Lombok (opcional, reduce boilerplate) -->
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
</dependencies>
```

### 9.2 Frontend - pubspec.yaml (Flutter)

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # HTTP & Networking
  http: ^1.1.0
  dio: ^5.4.0  # Alternativa a http con más features
  
  # State Management
  flutter_riverpod: ^2.4.0
  
  # Navigation
  go_router: ^13.0.0
  
  # Storage
  shared_preferences: ^2.2.2
  flutter_secure_storage: ^9.0.0
  
  # Firebase
  firebase_core: ^2.24.0
  firebase_messaging: ^14.7.6
  
  # QR Code
  qr_flutter: ^4.1.0
  mobile_scanner: ^3.5.5  # Para escanear QR
  
  # UI Components
  cupertino_icons: ^1.0.6
  flutter_svg: ^2.0.9
  cached_network_image: ^3.3.0
  image_picker: ^1.0.7
  file_picker: ^6.1.1
  
  # PDF
  pdf: ^3.10.7
  printing: ^5.11.1
  flutter_pdfview: ^1.3.2
  
  # Date/Time
  intl: ^0.18.1
  table_calendar: ^3.0.9
  
  # Utilities
  equatable: ^2.0.5
  json_annotation: ^4.8.1
  
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1
  build_runner: ^2.4.7
  json_serializable: ^6.7.1
  mockito: ^5.4.4
```

### 9.3 Base de Datos - Script de Inicialización

```sql
-- init.sql

-- Creación de tipos ENUM
CREATE TYPE rol_usuario AS ENUM ('SUPERADMIN', 'ADMIN', 'USUARIO', 'GUARDIA');
CREATE TYPE estado_visita AS ENUM ('PROGRAMADA', 'COMPLETADA', 'CANCELADA');
CREATE TYPE estado_paquete AS ENUM ('PENDIENTE', 'ENTREGADO');
CREATE TYPE estado_reservacion AS ENUM ('ACTIVA', 'CANCELADA', 'COMPLETADA');
CREATE TYPE segmento_notificacion AS ENUM ('TODOS', 'EDIFICIO_X', 'MOROSOS', 'PROPIETARIOS');
CREATE TYPE categoria_incidente AS ENUM ('MANTENIMIENTO', 'SEGURIDAD', 'RUIDO', 'LIMPIEZA', 'OTRO');
CREATE TYPE prioridad_incidente AS ENUM ('BAJA', 'MEDIA', 'ALTA');
CREATE TYPE estado_incidente AS ENUM ('PENDIENTE', 'EN_PROCESO', 'RESUELTO');
CREATE TYPE periodicidad_pago AS ENUM ('MENSUAL', 'UNICO');
CREATE TYPE estado_recibo AS ENUM ('PENDIENTE', 'PAGADO', 'RECHAZADO');
CREATE TYPE plataforma_device AS ENUM ('ANDROID', 'IOS', 'WEB');

-- Tabla: condominios
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

-- Tabla: usuarios
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

CREATE INDEX idx_usuarios_condominio ON usuarios(condominio_id);
CREATE INDEX idx_usuarios_rol ON usuarios(rol);

-- Tabla: device_tokens
CREATE TABLE device_tokens (
    id BIGSERIAL PRIMARY KEY,
    usuario_id BIGINT REFERENCES usuarios(id) ON DELETE CASCADE,
    token VARCHAR(500) NOT NULL,
    plataforma plataforma_device NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla: visitas
CREATE TABLE visitas (
    id BIGSERIAL PRIMARY KEY,
    condominio_id BIGINT REFERENCES condominios(id) NOT NULL,
    usuario_id BIGINT REFERENCES usuarios(id) NOT NULL,
    nombre_visitante VARCHAR(200) NOT NULL,
    telefono_visitante VARCHAR(20),
    fecha_hora_programada TIMESTAMP NOT NULL,
    codigo_qr_hash VARCHAR(500) UNIQUE NOT NULL,
    motivo VARCHAR(500),
    vehiculo_placas VARCHAR(20),
    estado estado_visita DEFAULT 'PROGRAMADA',
    fecha_hora_entrada TIMESTAMP,
    guardia_entrada_id BIGINT REFERENCES usuarios(id),
    notas TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_visitas_condominio ON visitas(condominio_id);
CREATE INDEX idx_visitas_usuario ON visitas(usuario_id);
CREATE INDEX idx_visitas_qr ON visitas(codigo_qr_hash);
CREATE INDEX idx_visitas_fecha ON visitas(fecha_hora_programada);

-- Tabla: paquetes
CREATE TABLE paquetes (
    id BIGSERIAL PRIMARY KEY,
    condominio_id BIGINT REFERENCES condominios(id) NOT NULL,
    usuario_destinatario_id BIGINT REFERENCES usuarios(id) NOT NULL,
    descripcion VARCHAR(500) NOT NULL,
    fecha_hora_llegada TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    guardia_registro_id BIGINT REFERENCES usuarios(id) NOT NULL,
    foto_url VARCHAR(500),
    estado estado_paquete DEFAULT 'PENDIENTE',
    fecha_hora_entrega TIMESTAMP,
    guardia_entrega_id BIGINT REFERENCES usuarios(id),
    notas TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_paquetes_condominio ON paquetes(condominio_id);
CREATE INDEX idx_paquetes_usuario_estado ON paquetes(usuario_destinatario_id, estado);

-- Tabla: areas_comunes
CREATE TABLE areas_comunes (
    id BIGSERIAL PRIMARY KEY,
    condominio_id BIGINT REFERENCES condominios(id) NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT,
    capacidad INT,
    horario_inicio TIME NOT NULL,
    horario_fin TIME NOT NULL,
    duracion_bloque_minutos INT NOT NULL,
    max_reservas_mes_por_usuario INT DEFAULT 2,
    anticipacion_minima_horas INT DEFAULT 24,
    anticipacion_maxima_dias INT DEFAULT 30,
    activa BOOLEAN DEFAULT TRUE,
    foto_url VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_areas_condominio ON areas_comunes(condominio_id);

-- Tabla: reservaciones
CREATE TABLE reservaciones (
    id BIGSERIAL PRIMARY KEY,
    area_comun_id BIGINT REFERENCES areas_comunes(id) NOT NULL,
    usuario_id BIGINT REFERENCES usuarios(id) NOT NULL,
    fecha_hora_inicio TIMESTAMP NOT NULL,
    fecha_hora_fin TIMESTAMP NOT NULL,
    estado estado_reservacion DEFAULT 'ACTIVA',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_reservaciones_area ON reservaciones(area_comun_id, fecha_hora_inicio);
CREATE INDEX idx_reservaciones_usuario ON reservaciones(usuario_id);

-- Tabla: notificaciones
CREATE TABLE notificaciones (
    id BIGSERIAL PRIMARY KEY,
    condominio_id BIGINT REFERENCES condominios(id) NOT NULL,
    admin_creador_id BIGINT REFERENCES usuarios(id) NOT NULL,
    titulo VARCHAR(200) NOT NULL,
    mensaje TEXT NOT NULL,
    segmento_destino segmento_notificacion DEFAULT 'TODOS',
    edificio_numero VARCHAR(20),
    fecha_publicacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_expiracion TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_notificaciones_condominio ON notificaciones(condominio_id);

-- Tabla: notificaciones_leidas
CREATE TABLE notificaciones_leidas (
    id BIGSERIAL PRIMARY KEY,
    notificacion_id BIGINT REFERENCES notificaciones(id) ON DELETE CASCADE,
    usuario_id BIGINT REFERENCES usuarios(id) ON DELETE CASCADE,
    fecha_lectura TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(notificacion_id, usuario_id)
);

-- Tabla: incidentes
CREATE TABLE incidentes (
    id BIGSERIAL PRIMARY KEY,
    condominio_id BIGINT REFERENCES condominios(id) NOT NULL,
    usuario_reporta_id BIGINT REFERENCES usuarios(id) NOT NULL,
    categoria categoria_incidente NOT NULL,
    titulo VARCHAR(200) NOT NULL,
    descripcion TEXT NOT NULL,
    ubicacion VARCHAR(200),
    prioridad prioridad_incidente DEFAULT 'BAJA',
    estado estado_incidente DEFAULT 'PENDIENTE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_incidentes_condominio ON incidentes(condominio_id);
CREATE INDEX idx_incidentes_usuario ON incidentes(usuario_reporta_id);
CREATE INDEX idx_incidentes_estado ON incidentes(estado);

-- Tabla: incidentes_fotos
CREATE TABLE incidentes_fotos (
    id BIGSERIAL PRIMARY KEY,
    incidente_id BIGINT REFERENCES incidentes(id) ON DELETE CASCADE,
    foto_url VARCHAR(500) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla: incidentes_comentarios
CREATE TABLE incidentes_comentarios (
    id BIGSERIAL PRIMARY KEY,
    incidente_id BIGINT REFERENCES incidentes(id) ON DELETE CASCADE,
    usuario_id BIGINT REFERENCES usuarios(id) NOT NULL,
    comentario TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_comentarios_incidente ON incidentes_comentarios(incidente_id);

-- Tabla: conceptos_pago
CREATE TABLE conceptos_pago (
    id BIGSERIAL PRIMARY KEY,
    condominio_id BIGINT REFERENCES condominios(id) NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    monto_default DECIMAL(10,2) NOT NULL,
    descripcion TEXT,
    periodicidad periodicidad_pago NOT NULL,
    dia_vencimiento INT CHECK (dia_vencimiento BETWEEN 1 AND 31),
    activo BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_conceptos_condominio ON conceptos_pago(condominio_id);

-- Tabla: recibos
CREATE TABLE recibos (
    id BIGSERIAL PRIMARY KEY,
    condominio_id BIGINT REFERENCES condominios(id) NOT NULL,
    usuario_id BIGINT REFERENCES usuarios(id) NOT NULL,
    concepto_pago_id BIGINT REFERENCES conceptos_pago(id) NOT NULL,
    periodo VARCHAR(20) NOT NULL,
    monto DECIMAL(10,2) NOT NULL,
    fecha_emision DATE NOT NULL,
    fecha_vencimiento DATE NOT NULL,
    estado estado_recibo DEFAULT 'PENDIENTE',
    comprobante_url VARCHAR(500),
    fecha_pago TIMESTAMP,
    admin_aprobo_id BIGINT REFERENCES usuarios(id),
    fecha_aprobacion TIMESTAMP,
    notas_admin TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_recibos_condominio ON recibos(condominio_id);
CREATE INDEX idx_recibos_usuario_estado ON recibos(usuario_id, estado, fecha_vencimiento);

-- Tabla: informacion_pago
CREATE TABLE informacion_pago (
    id BIGSERIAL PRIMARY KEY,
    condominio_id BIGINT REFERENCES condominios(id) UNIQUE NOT NULL,
    instrucciones_pago_text TEXT NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Triggers para updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_condominios_updated_at BEFORE UPDATE ON condominios
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_usuarios_updated_at BEFORE UPDATE ON usuarios
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_areas_updated_at BEFORE UPDATE ON areas_comunes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_incidentes_updated_at BEFORE UPDATE ON incidentes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Datos de ejemplo (OPCIONAL - solo para desarrollo)
INSERT INTO condominios (nombre, direccion, num_unidades) VALUES
('Residencial Las Palmas', 'Av. Principal 123, CDMX', 50),
('Torre Azul', 'Calle Secundaria 456, Guadalajara', 120);

-- Password: "admin123" hasheado con BCrypt
INSERT INTO usuarios (username, email, password_hash, nombre_completo, rol) VALUES
('superadmin', 'super@condos.com', '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYCdGzcBF4m', 'Super Administrador', 'SUPERADMIN');
```

---

## 10. Próximos Pasos

### Fase 1: Setup Inicial (Semana 1-2)
1. Crear repositorio Git
2. Configurar proyecto Spring Boot con dependencias
3. Configurar proyecto Flutter
4. Setup PostgreSQL local y crear schema
5. Configurar Firebase (proyecto, FCM)
6. Implementar autenticación básica (login, JWT)

### Fase 2: Módulos Core (Semana 3-6)
1. Módulo de Usuarios (CRUD, roles)
2. Módulo de Visitas (programar, QR, validar)
3. Módulo de Paquetes (registrar, entregar)
4. Módulo de Áreas Comunes (CRUD, reservaciones)

### Fase 3: Módulos Secundarios (Semana 7-9)
1. Módulo de Notificaciones (CRUD, segmentación, push)
2. Módulo de Incidentes (CRUD, comentarios, timeline)
3. Módulo de Pagos (conceptos, recibos, comprobantes, morosos)

### Fase 4: Integración y Pulido (Semana 10-12)
1. Integración completa de flujos
2. Testing end-to-end
3. UI/UX refinamiento
4. Performance optimization
5. Deployment a staging
6. User acceptance testing (UAT)

### Fase 5: Launch (Semana 13+)
1. Deployment a producción
2. Documentación de usuario
3. Capacitación de admins
4. Monitoreo y ajustes
5. Plan de mantenimiento

---

## 11. Anexos

### 11.1 Glosario

- **Multi-tenant:** Arquitectura donde múltiples clientes (condominios) comparten la misma infraestructura pero con datos aislados
- **JWT:** JSON Web Token, estándar para autenticación stateless
- **QR:** Quick Response code, código de barras 2D
- **FCM:** Firebase Cloud Messaging, servicio de notificaciones push
- **CRUD:** Create, Read, Update, Delete
- **DTO:** Data Transfer Object, objeto para transferir datos entre capas
- **JPA:** Java Persistence API, especificación para ORM en Java
- **ORM:** Object-Relational Mapping, mapeo objeto-relacional

### 11.2 Referencias

- [Spring Boot Documentation](https://spring.io/projects/spring-boot)
- [Flutter Documentation](https://flutter.dev/docs)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Firebase Documentation](https://firebase.google.com/docs)
- [JWT.io](https://jwt.io/)
- [ZXing Library](https://github.com/zxing/zxing)

### 11.3 Contacto y Soporte

Para dudas o ajustes al diseño, contactar al equipo de desarrollo.

---

**Fin del Documento de Diseño**


Próximos pasos cuando continuemos:
1. Revisarás el documento de diseño
2. Crearemos el plan de implementación detallado usando el skill writing-plans
3. Comenzaremos la implementación del código
