# Push Notifications (FCM) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enviar notificaciones push al residente cuando el GUARDIA registra un paquete o una visita directa, usando Firebase Cloud Messaging (FCM).

**Architecture:** Backend: Firebase Admin SDK inicializado desde la variable de entorno `FIREBASE_SERVICE_ACCOUNT_JSON`; `NotificacionPushService` consulta tokens de la tabla `device_tokens` y envía FCM; se llama desde `PaqueteService` y `VisitaService`. Flutter: `firebase_core` + `firebase_messaging` inicializados en `main.dart`; token FCM registrado en el backend después del login.

**Tech Stack:** Spring Boot 3.2 + Firebase Admin SDK 9.4.1 | Flutter + firebase_core ^3.6.0 + firebase_messaging ^15.1.3

---

## File Map

### Backend — nuevos archivos

```
com/condos/dispositivo/
  model/DeviceToken.java
  repository/DeviceTokenRepository.java
  dto/RegisterTokenRequest.java
  controller/DeviceTokenController.java

com/condos/config/
  FirebaseConfig.java

com/condos/notificacion/service/
  NotificacionPushService.java
```

### Backend — modificados

```
backend/pom.xml                             ← + firebase-admin 9.4.1
com/condos/paquete/service/PaqueteService   ← llamada a push tras registrar paquete
com/condos/visita/service/VisitaService     ← llamada a push tras visita directa
```

### Flutter — nuevos archivos

```
lib/core/services/firebase_service.dart    ← init Firebase, permisos, obtener token, registrar en backend
```

### Flutter — modificados

```
pubspec.yaml                               ← + firebase_core, firebase_messaging
android/build.gradle                       ← google-services plugin classpath
android/app/build.gradle                   ← apply plugin google-services
lib/main.dart                              ← WidgetsFlutterBinding + Firebase.initializeApp()
lib/shared/providers/auth_provider.dart    ← llamar FirebaseService.registrarToken() post-login
```

---

## Task 1: Backend — pom.xml + DeviceToken entity + repository

**Files:**
- Modify: `backend/pom.xml`
- Create: `backend/src/main/java/com/condos/dispositivo/model/DeviceToken.java`
- Create: `backend/src/main/java/com/condos/dispositivo/repository/DeviceTokenRepository.java`

- [ ] **Step 1: Agregar firebase-admin a pom.xml**

Dentro de `<dependencies>`, agregar:

```xml
<dependency>
    <groupId>com.google.firebase</groupId>
    <artifactId>firebase-admin</artifactId>
    <version>9.4.1</version>
</dependency>
```

- [ ] **Step 2: DeviceToken.java**

```java
package com.condos.dispositivo.model;

import com.condos.usuario.model.Usuario;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "device_tokens")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DeviceToken {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "usuario_id", nullable = false)
    private Usuario usuario;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String token;

    @Column(nullable = false, length = 10)
    private String plataforma;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
}
```

- [ ] **Step 3: DeviceTokenRepository.java**

```java
package com.condos.dispositivo.repository;

import com.condos.dispositivo.model.DeviceToken;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface DeviceTokenRepository extends JpaRepository<DeviceToken, Long> {
    List<DeviceToken> findByUsuarioId(Long usuarioId);
    Optional<DeviceToken> findByUsuarioIdAndPlataforma(Long usuarioId, String plataforma);
}
```

- [ ] **Step 4: Migración V14 — convertir plataforma a VARCHAR**

La columna `plataforma` en `device_tokens` es `plataforma_device` (enum PostgreSQL). Como el resto de enums, hay que convertirla a VARCHAR:

```sql
-- Crear backend/src/main/resources/db/migration/V14__convert_device_token_plataforma.sql
ALTER TABLE device_tokens ALTER COLUMN plataforma TYPE VARCHAR(10) USING plataforma::text;
DROP TYPE IF EXISTS plataforma_device CASCADE;
```

- [ ] **Step 5: Commit**

```bash
git add backend/pom.xml \
        backend/src/main/java/com/condos/dispositivo/ \
        backend/src/main/resources/db/migration/V14__convert_device_token_plataforma.sql
git commit -m "feat(push): add firebase-admin dep, DeviceToken entity+repo, V14 migration"
```

---

## Task 2: Backend — FirebaseConfig + NotificacionPushService

**Files:**
- Create: `backend/src/main/java/com/condos/config/FirebaseConfig.java`
- Create: `backend/src/main/java/com/condos/notificacion/service/NotificacionPushService.java`

- [ ] **Step 1: FirebaseConfig.java**

Lee el JSON de cuenta de servicio desde la variable de entorno `FIREBASE_SERVICE_ACCOUNT_JSON`. Si no existe, loguea un warning y no inicializa Firebase (el sistema sigue funcionando sin push).

```java
package com.condos.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Configuration;

import jakarta.annotation.PostConstruct;
import java.io.ByteArrayInputStream;
import java.nio.charset.StandardCharsets;

@Slf4j
@Configuration
public class FirebaseConfig {

    @PostConstruct
    public void initializeFirebase() {
        String serviceAccountJson = System.getenv("FIREBASE_SERVICE_ACCOUNT_JSON");
        if (serviceAccountJson == null || serviceAccountJson.isBlank()) {
            log.warn("FIREBASE_SERVICE_ACCOUNT_JSON no configurado — push notifications desactivadas");
            return;
        }
        try {
            if (!FirebaseApp.getApps().isEmpty()) return;

            GoogleCredentials credentials = GoogleCredentials.fromStream(
                    new ByteArrayInputStream(serviceAccountJson.getBytes(StandardCharsets.UTF_8))
            );
            FirebaseOptions options = FirebaseOptions.builder()
                    .setCredentials(credentials)
                    .build();
            FirebaseApp.initializeApp(options);
            log.info("Firebase Admin SDK inicializado correctamente");
        } catch (Exception e) {
            log.error("Error al inicializar Firebase: {}", e.getMessage());
        }
    }
}
```

- [ ] **Step 2: NotificacionPushService.java**

```java
package com.condos.notificacion.service;

import com.condos.dispositivo.repository.DeviceTokenRepository;
import com.google.firebase.FirebaseApp;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

@Slf4j
@Service
@RequiredArgsConstructor
public class NotificacionPushService {

    private final DeviceTokenRepository deviceTokenRepository;

    @Async
    public void notificarPaquete(Long usuarioId, String descripcion) {
        enviar(
                usuarioId,
                "📦 Tienes un paquete",
                "Llegó un paquete para ti en portería. Pasa a recogerlo."
        );
    }

    @Async
    public void notificarVisitaDirecta(Long usuarioId, String nombreVisitante, String motivo) {
        enviar(
                usuarioId,
                "🔔 Tienes una visita",
                "Visitante: " + nombreVisitante + ". Motivo: " + motivo
        );
    }

    private void enviar(Long usuarioId, String titulo, String cuerpo) {
        if (FirebaseApp.getApps().isEmpty()) {
            log.debug("Firebase no inicializado — omitiendo push para usuario {}", usuarioId);
            return;
        }
        deviceTokenRepository.findByUsuarioId(usuarioId).forEach(dt -> {
            try {
                Message message = Message.builder()
                        .setNotification(Notification.builder()
                                .setTitle(titulo)
                                .setBody(cuerpo)
                                .build())
                        .setToken(dt.getToken())
                        .build();
                String response = FirebaseMessaging.getInstance().send(message);
                log.info("Push enviado a usuario={} token_prefix={}: {}", usuarioId,
                        dt.getToken().substring(0, Math.min(10, dt.getToken().length())), response);
            } catch (Exception e) {
                log.warn("Error enviando push a usuario={}: {}", usuarioId, e.getMessage());
            }
        });
    }
}
```

- [ ] **Step 3: Habilitar @Async en la aplicación principal**

En `CondosApplication.java`, agregar la anotación:

```java
@SpringBootApplication
@EnableAsync
public class CondosApplication { ... }
```

Agregar import:
```java
import org.springframework.scheduling.annotation.EnableAsync;
```

- [ ] **Step 4: Verificar compilación**

```bash
cd backend && ./mvnw compile -q
```

Expected: BUILD SUCCESS.

- [ ] **Step 5: Commit**

```bash
git add backend/src/main/java/com/condos/config/FirebaseConfig.java \
        backend/src/main/java/com/condos/notificacion/service/NotificacionPushService.java \
        backend/src/main/java/com/condos/CondosApplication.java
git commit -m "feat(push): add FirebaseConfig, NotificacionPushService with @Async"
```

---

## Task 3: Backend — DeviceTokenController + integración en PaqueteService y VisitaService

**Files:**
- Create: `backend/src/main/java/com/condos/dispositivo/dto/RegisterTokenRequest.java`
- Create: `backend/src/main/java/com/condos/dispositivo/controller/DeviceTokenController.java`
- Modify: `backend/src/main/java/com/condos/paquete/service/PaqueteService.java`
- Modify: `backend/src/main/java/com/condos/visita/service/VisitaService.java`

- [ ] **Step 1: RegisterTokenRequest.java**

```java
package com.condos.dispositivo.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class RegisterTokenRequest {

    @NotBlank
    private String token;

    @NotBlank
    private String plataforma; // ANDROID, IOS, WEB
}
```

- [ ] **Step 2: DeviceTokenController.java**

```java
package com.condos.dispositivo.controller;

import com.condos.dispositivo.dto.RegisterTokenRequest;
import com.condos.dispositivo.model.DeviceToken;
import com.condos.dispositivo.repository.DeviceTokenRepository;
import com.condos.usuario.model.Usuario;
import com.condos.usuario.repository.UsuarioRepository;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@Slf4j
@RestController
@RequestMapping("/api/device-tokens")
@RequiredArgsConstructor
public class DeviceTokenController {

    private final DeviceTokenRepository deviceTokenRepository;
    private final UsuarioRepository usuarioRepository;

    @PostMapping
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<Void> registerToken(
            @Valid @RequestBody RegisterTokenRequest request,
            Authentication authentication) {

        Long usuarioId = Long.parseLong(authentication.getName());
        Usuario usuario = usuarioRepository.findById(usuarioId)
                .orElseThrow(() -> new RuntimeException("Usuario no encontrado"));

        // Actualizar token si ya existe para esta plataforma, sino crear nuevo
        deviceTokenRepository.findByUsuarioIdAndPlataforma(usuarioId, request.getPlataforma())
                .ifPresentOrElse(
                        existing -> {
                            existing.setToken(request.getToken());
                            deviceTokenRepository.save(existing);
                        },
                        () -> deviceTokenRepository.save(DeviceToken.builder()
                                .usuario(usuario)
                                .token(request.getToken())
                                .plataforma(request.getPlataforma())
                                .build())
                );

        log.info("Token FCM registrado: usuario={}, plataforma={}", usuarioId, request.getPlataforma());
        return ResponseEntity.noContent().build();
    }
}
```

- [ ] **Step 3: Agregar push en PaqueteService.registrarPaquete()**

En `PaqueteService.java`, inyectar `NotificacionPushService` en el constructor y al final de `registrarPaquete()`, antes del `return`:

```java
// Inyectar en el constructor (agregar a @RequiredArgsConstructor)
private final NotificacionPushService notificacionPushService;
```

Y al final de `registrarPaquete()`, antes del `return`:

```java
        // Notificar al residente
        notificacionPushService.notificarPaquete(destinatario.getId(), request.getDescripcion());
```

- [ ] **Step 4: Agregar push en VisitaService.registrarVisitaDirecta()**

En `VisitaService.java`, inyectar `NotificacionPushService` (ya tiene `@RequiredArgsConstructor`) y al final de `registrarVisitaDirecta()`, antes del `return`:

```java
// Agregar al campo de dependencias:
private final NotificacionPushService notificacionPushService;
```

Y al final de `registrarVisitaDirecta()`, antes del `return`:

```java
        // Notificar al residente destinatario
        notificacionPushService.notificarVisitaDirecta(
                destinatario.getId(),
                request.getNombreVisitante(),
                request.getMotivo()
        );
```

- [ ] **Step 5: Agregar ApiConstants en Flutter**

En `lib/core/constants/api_constants.dart`:

```dart
static const String deviceTokens = '$apiPrefix/device-tokens';
```

- [ ] **Step 6: Verificar compilación**

```bash
cd backend && ./mvnw compile -q
```

Expected: BUILD SUCCESS.

- [ ] **Step 7: Commit**

```bash
git add backend/src/main/java/com/condos/dispositivo/ \
        backend/src/main/java/com/condos/paquete/service/PaqueteService.java \
        backend/src/main/java/com/condos/visita/service/VisitaService.java \
        lib/core/constants/api_constants.dart
git commit -m "feat(push): DeviceTokenController, integrate push in PaqueteService and VisitaService"
```

---

## Task 4: Flutter — pubspec + android build.gradle + main.dart + FirebaseService

**Files:**
- Modify: `pubspec.yaml`
- Modify: `android/build.gradle`
- Modify: `android/app/build.gradle`
- Create: `lib/core/services/firebase_service.dart`
- Modify: `lib/main.dart`

- [ ] **Step 1: Agregar dependencias a pubspec.yaml**

Dentro de `dependencies`, agregar después de `image_picker`:

```yaml
  # Firebase push notifications
  firebase_core: ^3.6.0
  firebase_messaging: ^15.1.3
  flutter_local_notifications: ^17.2.2
```

- [ ] **Step 2: Actualizar android/build.gradle**

En `android/build.gradle`, dentro de `buildscript > dependencies`, agregar:

```groovy
classpath 'com.google.gms:google-services:4.4.2'
```

El archivo completo del bloque `buildscript` queda:

```groovy
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath 'com.android.tools.build:gradle:8.1.0'
        classpath 'com.google.gms:google-services:4.4.2'
    }
}
```

- [ ] **Step 3: Actualizar android/app/build.gradle**

Al final del archivo `android/app/build.gradle`, agregar:

```groovy
apply plugin: 'com.google.gms.google-services'
```

- [ ] **Step 4: flutter pub get**

```bash
cd ~/flutter/condos
~/flutter/condos/flutter/bin/flutter pub get
```

Expected: `Got dependencies!`

- [ ] **Step 5: FirebaseService.dart**

```dart
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../core/constants/api_constants.dart';
import '../../shared/services/api_client.dart';

// Handler para mensajes en background (debe ser top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  // Firebase ya muestra la notificación automáticamente en background/killed
}

class FirebaseService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Inicializar notificaciones locales (para cuando la app está en primer plano)
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(initSettings);

    // Handler para mensajes en background
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

    // Mostrar notificación cuando la app está en primer plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'condos_channel',
              'Condos Notificaciones',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
        );
      }
    });
  }

  static Future<void> registrarToken(ApiClient apiClient) async {
    try {
      // Pedir permiso en iOS (en Android se otorga automáticamente)
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;

      final plataforma = Platform.isIOS ? 'IOS' : 'ANDROID';

      await apiClient.post(ApiConstants.deviceTokens, {
        'token': token,
        'plataforma': plataforma,
      });
    } catch (e) {
      // No interrumpir el login si falla el registro del token
    }
  }
}
```

- [ ] **Step 6: Modificar main.dart**

Agregar la inicialización de Firebase antes de `runApp()`. El `main.dart` completo queda:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/routes/app_router.dart';
import 'core/services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  await Firebase.initializeApp();
  await FirebaseService.initialize();

  runApp(const ProviderScope(child: CondosApp()));
}

class CondosApp extends ConsumerWidget {
  const CondosApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    return MaterialApp.router(
      title: 'Condos',
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
```

- [ ] **Step 7: Commit**

```bash
git add pubspec.yaml pubspec.lock \
        android/build.gradle android/app/build.gradle \
        lib/core/services/firebase_service.dart \
        lib/main.dart
git commit -m "feat(push): add Firebase Flutter SDK, FirebaseService, initialize in main.dart"
```

---

## Task 5: Flutter — registrar token FCM después del login

**Files:**
- Modify: `lib/shared/providers/auth_provider.dart`

- [ ] **Step 1: Llamar FirebaseService.registrarToken() después de login exitoso**

En `AuthNotifier.login()`, después de `state = AuthState(user: user, isLoading: false)`:

```dart
import '../../core/services/firebase_service.dart';
```

Y en el método `login()`, después de actualizar el state:

```dart
  Future<void> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _authService.login(username, password);
      state = AuthState(user: user, isLoading: false);
      // Registrar token FCM para recibir push notifications
      FirebaseService.registrarToken(_authService.apiClient);
    } catch (e) {
      state = AuthState(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }
```

Para que `_authService.apiClient` sea accesible, agregar getter en `AuthService`:

```dart
// En lib/shared/services/auth_service.dart:
ApiClient get apiClient => apiClient;  // ya es field, solo hacer getter público
```

Verificar que `apiClient` en `AuthService` sea accesible. Si es `final ApiClient apiClient;` ya es público — no hay cambio.

- [ ] **Step 2: Commit y push**

```bash
git add lib/shared/providers/auth_provider.dart \
        lib/shared/services/auth_service.dart
git commit -m "feat(push): register FCM token after login"
git push
```

---

## Self-Review

### Spec Coverage

| Requisito | Task |
|---|---|
| `firebase-admin` en pom.xml | Task 1 |
| `DeviceToken` entity + repository | Task 1 |
| V14 migration — convertir plataforma a VARCHAR | Task 1 |
| `FirebaseConfig` inicializa desde `FIREBASE_SERVICE_ACCOUNT_JSON` | Task 2 |
| Fallback silencioso si no hay config | Task 2 |
| `NotificacionPushService` con `@Async` | Task 2 |
| `@EnableAsync` en `CondosApplication` | Task 2 |
| `POST /api/device-tokens` — upsert por plataforma | Task 3 |
| Push en `PaqueteService.registrarPaquete()` | Task 3 |
| Push en `VisitaService.registrarVisitaDirecta()` | Task 3 |
| `ApiConstants.deviceTokens` | Task 3 |
| Backend compila | Task 3 |
| `firebase_core`, `firebase_messaging`, `flutter_local_notifications` en pubspec | Task 4 |
| `google-services` plugin en android/build.gradle | Task 4 |
| `FirebaseService` — init, permisos, obtener token, registrar en backend | Task 4 |
| Notificación local cuando app está en primer plano | Task 4 |
| `main.dart` inicializa Firebase antes de `runApp()` | Task 4 |
| Token FCM registrado post-login | Task 5 |
| Sin crash si Firebase no configurado | Tasks 2+4 |
| Contenido notificación paquete y visita directa | Task 2 |
