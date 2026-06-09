# Flutter Visitas Feature — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the complete visitas (visits) feature in Flutter for all roles (USUARIO, GUARDIA, ADMIN, SUPERADMIN) connecting to the existing Spring Boot backend at `http://localhost:8080`.

**Architecture:** Feature-first folder structure under `lib/features/visitas/`. Riverpod `StateNotifier` pattern (mirrors existing `AuthNotifier`). `BottomNavigationBar` with 4 role-specific tabs in a new `MainScaffold` widget. Sub-routes (detail view) via GoRouter on top of the scaffold.

**Tech Stack:** Flutter, Riverpod 2.x, GoRouter 13.x, json_serializable 6.x, mobile_scanner 6.x (QR camera), http 1.x.

---

## File Map

**Create:**
- `lib/features/visitas/models/visita.dart` — Visita model + EstadoVisita enum
- `lib/features/visitas/models/visita.g.dart` — generated
- `lib/features/visitas/models/create_visita_request.dart`
- `lib/features/visitas/models/create_visita_request.g.dart` — generated
- `lib/features/visitas/models/validar_qr_request.dart`
- `lib/features/visitas/models/validar_qr_request.g.dart` — generated
- `lib/features/visitas/models/validar_qr_response.dart`
- `lib/features/visitas/models/validar_qr_response.g.dart` — generated
- `lib/features/visitas/services/visita_service.dart`
- `lib/features/visitas/providers/visita_provider.dart`
- `lib/features/visitas/screens/mis_visitas_screen.dart`
- `lib/features/visitas/screens/crear_visita_screen.dart`
- `lib/features/visitas/screens/detalle_visita_screen.dart`
- `lib/features/visitas/screens/escanear_qr_screen.dart`
- `lib/features/visitas/screens/visitas_admin_screen.dart`
- `lib/features/visitas/screens/dashboard_admin_screen.dart`
- `lib/features/visitas/screens/inicio_usuario_screen.dart`
- `lib/features/perfil/screens/perfil_screen.dart`
- `lib/features/perfil/screens/gestion_screen.dart`
- `lib/shared/widgets/main_scaffold.dart`
- `test/features/visitas/models/visita_test.dart`

**Modify:**
- `pubspec.yaml` — add mobile_scanner
- `android/app/src/main/AndroidManifest.xml` — camera permission
- `ios/Runner/Info.plist` — camera permission
- `lib/shared/services/api_client.dart` — add getList() and put()
- `lib/core/constants/api_constants.dart` — add visitas endpoints
- `lib/core/routes/app_router.dart` — add /home routes

---

### Task 0: Commit pending Flyway changes

**Files:**
- Modify: `backend/pom.xml` (already staged)
- Modify: `backend/src/main/resources/application.properties` (already staged)

- [ ] **Step 1: Verify the uncommitted changes**

```bash
git diff backend/pom.xml backend/src/main/resources/application.properties
```

Expected: shows Flyway dependency added to pom.xml and Flyway config + local credentials in application.properties.

- [ ] **Step 2: Commit**

```bash
git add backend/pom.xml backend/src/main/resources/application.properties
git commit -m "chore(backend): add Flyway migration support"
```

---

### Task 1: Add mobile_scanner dependency and camera permissions

**Files:**
- Modify: `pubspec.yaml`
- Modify: `android/app/src/main/AndroidManifest.xml`
- Modify: `ios/Runner/Info.plist`

- [ ] **Step 1: Add mobile_scanner to pubspec.yaml**

In `pubspec.yaml`, add under `dependencies:` after `equatable:`:

```yaml
  # QR code scanner
  mobile_scanner: ^6.0.0
```

- [ ] **Step 2: Add camera permission to Android**

In `android/app/src/main/AndroidManifest.xml`, add inside `<manifest>` before `<application>`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
```

- [ ] **Step 3: Add camera permission to iOS**

In `ios/Runner/Info.plist`, add inside `<dict>` (before the closing `</dict>`):

```xml
<key>NSCameraUsageDescription</key>
<string>Necesitamos acceso a la cámara para escanear códigos QR de visitas.</string>
```

- [ ] **Step 4: Fetch packages**

```bash
cd /Users/jandrade2/flutter/condos && flutter pub get
```

Expected: resolves mobile_scanner without conflicts.

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml pubspec.lock android/app/src/main/AndroidManifest.xml ios/Runner/Info.plist
git commit -m "chore(flutter): add mobile_scanner dependency and camera permissions"
```

---

### Task 2: Extend ApiClient with getList() and put()

**Files:**
- Modify: `lib/shared/services/api_client.dart`

- [ ] **Step 1: Add getList() method**

In `lib/shared/services/api_client.dart`, add after the `get()` method (before `_handleResponse`):

```dart
  Future<List<dynamic>> getList(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
  }) async {
    try {
      var url = Uri.parse('$baseUrl$endpoint');
      if (queryParameters != null && queryParameters.isNotEmpty) {
        url = url.replace(queryParameters: queryParameters);
      }

      final response = await http
          .get(
            url,
            headers: _getHeaders(additionalHeaders: headers),
          )
          .timeout(timeout);

      return _handleListResponse(response);
    } on TimeoutException {
      throw ApiException(
        'La solicitud tardó demasiado tiempo. Por favor, intente nuevamente.',
        statusCode: 408,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        'Error de conexión. Verifique su internet e intente nuevamente.',
      );
    }
  }

  Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final response = await http
          .put(
            url,
            headers: _getHeaders(additionalHeaders: headers),
            body: jsonEncode(body),
          )
          .timeout(timeout);

      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException(
        'La solicitud tardó demasiado tiempo. Por favor, intente nuevamente.',
        statusCode: 408,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        'Error de conexión. Verifique su internet e intente nuevamente.',
      );
    }
  }
```

- [ ] **Step 2: Add _handleListResponse() private method**

In `lib/shared/services/api_client.dart`, add after `_handleResponse()`:

```dart
  List<dynamic> _handleListResponse(http.Response response) {
    final statusCode = response.statusCode;

    if (statusCode >= 200 && statusCode < 300) {
      if (response.body.isEmpty) return [];
      try {
        return jsonDecode(response.body) as List<dynamic>;
      } catch (e) {
        throw ApiException(
          'Error al procesar la respuesta del servidor.',
          statusCode: statusCode,
        );
      }
    }

    ApiError? apiError;
    try {
      if (response.body.isNotEmpty) {
        final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
        apiError = ApiError.fromJson(errorJson);
      }
    } catch (e) {
      // continue with generic message
    }

    throw ApiException(
      apiError?.message ?? _getDefaultErrorMessage(statusCode),
      statusCode: statusCode,
      apiError: apiError,
    );
  }
```

- [ ] **Step 3: Verify file compiles**

```bash
cd /Users/jandrade2/flutter/condos && flutter analyze lib/shared/services/api_client.dart
```

Expected: No errors.

- [ ] **Step 4: Commit**

```bash
git add lib/shared/services/api_client.dart
git commit -m "feat(api): add getList() and put() methods to ApiClient"
```

---

### Task 3: Add visitas endpoints to ApiConstants

**Files:**
- Modify: `lib/core/constants/api_constants.dart`

- [ ] **Step 1: Add visitas constants**

Replace the entire content of `lib/core/constants/api_constants.dart`:

```dart
class ApiConstants {
  static const String baseUrl = 'http://localhost:8080';
  static const String apiPrefix = '/api';

  static const String login = '$apiPrefix/auth/login';
  static const String me = '$apiPrefix/auth/me';

  // Visitas
  static const String visitas = '$apiPrefix/visitas';
  static const String misVisitas = '$apiPrefix/visitas/mis-visitas';
  static const String validarQr = '$apiPrefix/visitas/validar-qr';

  static String visitaById(int id) => '$apiPrefix/visitas/$id';
  static String cancelarVisita(int id) => '$apiPrefix/visitas/$id/cancelar';
  static String qrImage(int id) => '$apiPrefix/visitas/$id/qr-image';

  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration defaultTimeout = Duration(seconds: 30);
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/core/constants/api_constants.dart
git commit -m "feat(api): add visitas endpoint constants"
```

---

### Task 4: Create EstadoVisita enum + Visita model

**Files:**
- Create: `lib/features/visitas/models/visita.dart`

- [ ] **Step 1: Create the file**

Create `lib/features/visitas/models/visita.dart`:

```dart
import 'package:json_annotation/json_annotation.dart';

part 'visita.g.dart';

enum EstadoVisita {
  @JsonValue('PROGRAMADA')
  programada,

  @JsonValue('COMPLETADA')
  completada,

  @JsonValue('CANCELADA')
  cancelada,
}

@JsonSerializable()
class Visita {
  final int id;
  final String nombreVisitante;
  final String? telefonoVisitante;
  final DateTime fechaHoraProgramada;
  final String codigoQrHash;
  final String? motivo;
  final String? vehiculoPlacas;
  final EstadoVisita estado;
  final DateTime? fechaHoraEntrada;
  final String? notas;
  final DateTime createdAt;
  final int usuarioId;
  final String usuarioNombre;
  final String? unidadHabitacional;
  final int? guardiaEntradaId;
  final String? guardiaEntradaNombre;

  Visita({
    required this.id,
    required this.nombreVisitante,
    this.telefonoVisitante,
    required this.fechaHoraProgramada,
    required this.codigoQrHash,
    this.motivo,
    this.vehiculoPlacas,
    required this.estado,
    this.fechaHoraEntrada,
    this.notas,
    required this.createdAt,
    required this.usuarioId,
    required this.usuarioNombre,
    this.unidadHabitacional,
    this.guardiaEntradaId,
    this.guardiaEntradaNombre,
  });

  factory Visita.fromJson(Map<String, dynamic> json) => _$VisitaFromJson(json);
  Map<String, dynamic> toJson() => _$VisitaToJson(this);
}
```

---

### Task 5: Create CreateVisitaRequest model

**Files:**
- Create: `lib/features/visitas/models/create_visita_request.dart`

- [ ] **Step 1: Create the file**

Create `lib/features/visitas/models/create_visita_request.dart`:

```dart
import 'package:json_annotation/json_annotation.dart';

part 'create_visita_request.g.dart';

@JsonSerializable()
class CreateVisitaRequest {
  final String nombreVisitante;
  final String? telefonoVisitante;
  final DateTime fechaHoraProgramada;
  final String? motivo;
  final String? vehiculoPlacas;

  CreateVisitaRequest({
    required this.nombreVisitante,
    this.telefonoVisitante,
    required this.fechaHoraProgramada,
    this.motivo,
    this.vehiculoPlacas,
  });

  factory CreateVisitaRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateVisitaRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateVisitaRequestToJson(this);
}
```

---

### Task 6: Create ValidarQrRequest and ValidarQrResponse models

**Files:**
- Create: `lib/features/visitas/models/validar_qr_request.dart`
- Create: `lib/features/visitas/models/validar_qr_response.dart`

- [ ] **Step 1: Create ValidarQrRequest**

Create `lib/features/visitas/models/validar_qr_request.dart`:

```dart
import 'package:json_annotation/json_annotation.dart';

part 'validar_qr_request.g.dart';

@JsonSerializable()
class ValidarQrRequest {
  final String codigoQr;
  final String? notas;

  ValidarQrRequest({required this.codigoQr, this.notas});

  factory ValidarQrRequest.fromJson(Map<String, dynamic> json) =>
      _$ValidarQrRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ValidarQrRequestToJson(this);
}
```

- [ ] **Step 2: Create ValidarQrResponse**

Create `lib/features/visitas/models/validar_qr_response.dart`:

```dart
import 'package:json_annotation/json_annotation.dart';
import 'visita.dart';

part 'validar_qr_response.g.dart';

@JsonSerializable()
class ValidarQrResponse {
  final bool valido;
  final String mensaje;
  final Visita? visita;

  ValidarQrResponse({
    required this.valido,
    required this.mensaje,
    this.visita,
  });

  factory ValidarQrResponse.fromJson(Map<String, dynamic> json) =>
      _$ValidarQrResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ValidarQrResponseToJson(this);
}
```

---

### Task 7: Run build_runner to generate .g.dart files

**Files:**
- Create: `lib/features/visitas/models/visita.g.dart`
- Create: `lib/features/visitas/models/create_visita_request.g.dart`
- Create: `lib/features/visitas/models/validar_qr_request.g.dart`
- Create: `lib/features/visitas/models/validar_qr_response.g.dart`

- [ ] **Step 1: Run code generation**

```bash
cd /Users/jandrade2/flutter/condos && dart run build_runner build --delete-conflicting-outputs
```

Expected output: `[INFO] Build completed successfully!` with 4 new `.g.dart` files created.

- [ ] **Step 2: Verify generated files exist**

```bash
ls lib/features/visitas/models/*.g.dart
```

Expected:
```
lib/features/visitas/models/create_visita_request.g.dart
lib/features/visitas/models/validar_qr_request.g.dart
lib/features/visitas/models/validar_qr_response.g.dart
lib/features/visitas/models/visita.g.dart
```

- [ ] **Step 3: Verify project compiles**

```bash
flutter analyze lib/features/
```

Expected: No errors.

- [ ] **Step 4: Commit**

```bash
git add lib/features/visitas/models/
git commit -m "feat(visitas): add Flutter models for Visita, CreateVisitaRequest, ValidarQr"
```

---

### Task 8: Write model unit tests

**Files:**
- Create: `test/features/visitas/models/visita_test.dart`

- [ ] **Step 1: Create the test file**

Create `test/features/visitas/models/visita_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:condos/features/visitas/models/visita.dart';
import 'package:condos/features/visitas/models/create_visita_request.dart';
import 'package:condos/features/visitas/models/validar_qr_response.dart';

void main() {
  group('Visita.fromJson', () {
    final sampleJson = {
      'id': 1,
      'nombreVisitante': 'Juan Perez',
      'telefonoVisitante': '555-1234',
      'fechaHoraProgramada': '2024-01-15T10:30:00',
      'codigoQrHash': 'COND-1-VIS-1-abc123',
      'motivo': 'Visita familiar',
      'vehiculoPlacas': 'ABC-123',
      'estado': 'PROGRAMADA',
      'fechaHoraEntrada': null,
      'notas': null,
      'createdAt': '2024-01-14T08:00:00',
      'usuarioId': 42,
      'usuarioNombre': 'Maria Lopez',
      'unidadHabitacional': 'A-101',
      'guardiaEntradaId': null,
      'guardiaEntradaNombre': null,
    };

    test('parses all fields correctly', () {
      final visita = Visita.fromJson(sampleJson);

      expect(visita.id, equals(1));
      expect(visita.nombreVisitante, equals('Juan Perez'));
      expect(visita.telefonoVisitante, equals('555-1234'));
      expect(visita.estado, equals(EstadoVisita.programada));
      expect(visita.fechaHoraProgramada, equals(DateTime.parse('2024-01-15T10:30:00')));
      expect(visita.usuarioNombre, equals('Maria Lopez'));
      expect(visita.unidadHabitacional, equals('A-101'));
      expect(visita.guardiaEntradaId, isNull);
    });

    test('parses COMPLETADA estado', () {
      final json = Map<String, dynamic>.from(sampleJson)
        ..['estado'] = 'COMPLETADA'
        ..['fechaHoraEntrada'] = '2024-01-15T10:35:00'
        ..['guardiaEntradaId'] = 5
        ..['guardiaEntradaNombre'] = 'Guardia Gomez';

      final visita = Visita.fromJson(json);

      expect(visita.estado, equals(EstadoVisita.completada));
      expect(visita.guardiaEntradaId, equals(5));
      expect(visita.guardiaEntradaNombre, equals('Guardia Gomez'));
    });

    test('parses CANCELADA estado', () {
      final json = Map<String, dynamic>.from(sampleJson)..['estado'] = 'CANCELADA';
      final visita = Visita.fromJson(json);
      expect(visita.estado, equals(EstadoVisita.cancelada));
    });

    test('handles null optional fields', () {
      final json = Map<String, dynamic>.from(sampleJson)
        ..['telefonoVisitante'] = null
        ..['motivo'] = null
        ..['vehiculoPlacas'] = null
        ..['unidadHabitacional'] = null;

      final visita = Visita.fromJson(json);

      expect(visita.telefonoVisitante, isNull);
      expect(visita.motivo, isNull);
      expect(visita.vehiculoPlacas, isNull);
    });
  });

  group('CreateVisitaRequest.toJson', () {
    test('serializes required fields', () {
      final request = CreateVisitaRequest(
        nombreVisitante: 'Test Visitor',
        fechaHoraProgramada: DateTime(2024, 1, 15, 10, 30),
      );

      final json = request.toJson();

      expect(json['nombreVisitante'], equals('Test Visitor'));
      expect(json['fechaHoraProgramada'], isA<String>());
      expect(json['fechaHoraProgramada'] as String, contains('2024-01-15'));
      expect(json['telefonoVisitante'], isNull);
      expect(json['motivo'], isNull);
    });

    test('serializes optional fields when provided', () {
      final request = CreateVisitaRequest(
        nombreVisitante: 'Test',
        fechaHoraProgramada: DateTime(2024, 1, 15, 10, 30),
        telefonoVisitante: '555-9999',
        motivo: 'Entrega',
        vehiculoPlacas: 'XYZ-001',
      );

      final json = request.toJson();

      expect(json['telefonoVisitante'], equals('555-9999'));
      expect(json['motivo'], equals('Entrega'));
      expect(json['vehiculoPlacas'], equals('XYZ-001'));
    });
  });

  group('ValidarQrResponse.fromJson', () {
    test('parses valid=true response with visita', () {
      final json = {
        'valido': true,
        'mensaje': 'Código QR válido. Entrada registrada correctamente.',
        'visita': {
          'id': 1,
          'nombreVisitante': 'Juan',
          'telefonoVisitante': null,
          'fechaHoraProgramada': '2024-01-15T10:30:00',
          'codigoQrHash': 'hash',
          'motivo': null,
          'vehiculoPlacas': null,
          'estado': 'COMPLETADA',
          'fechaHoraEntrada': '2024-01-15T10:35:00',
          'notas': null,
          'createdAt': '2024-01-14T08:00:00',
          'usuarioId': 1,
          'usuarioNombre': 'Maria',
          'unidadHabitacional': 'A-101',
          'guardiaEntradaId': 5,
          'guardiaEntradaNombre': 'Guardia',
        },
      };

      final response = ValidarQrResponse.fromJson(json);

      expect(response.valido, isTrue);
      expect(response.visita, isNotNull);
      expect(response.visita!.nombreVisitante, equals('Juan'));
    });

    test('parses valid=false response without visita', () {
      final json = {
        'valido': false,
        'mensaje': 'Código QR inválido',
        'visita': null,
      };

      final response = ValidarQrResponse.fromJson(json);

      expect(response.valido, isFalse);
      expect(response.visita, isNull);
    });
  });
}
```

- [ ] **Step 2: Run the tests**

```bash
cd /Users/jandrade2/flutter/condos && flutter test test/features/visitas/models/visita_test.dart -v
```

Expected: All tests pass.

- [ ] **Step 3: Commit**

```bash
git add test/features/visitas/models/visita_test.dart
git commit -m "test(visitas): add model unit tests for Visita, CreateVisitaRequest, ValidarQrResponse"
```

---

### Task 9: Create VisitaService

**Files:**
- Create: `lib/features/visitas/services/visita_service.dart`

- [ ] **Step 1: Create the service**

Create `lib/features/visitas/services/visita_service.dart`:

```dart
import '../../../core/constants/api_constants.dart';
import '../../../shared/services/api_client.dart';
import '../models/create_visita_request.dart';
import '../models/validar_qr_request.dart';
import '../models/validar_qr_response.dart';
import '../models/visita.dart';

class VisitaService {
  final ApiClient apiClient;

  VisitaService({required this.apiClient});

  Future<List<Visita>> getMisVisitas() async {
    final response = await apiClient.getList(ApiConstants.misVisitas);
    return response
        .map((item) => Visita.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<Visita>> getTodasVisitas() async {
    final response = await apiClient.getList(ApiConstants.visitas);
    return response
        .map((item) => Visita.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Visita> getVisita(int id) async {
    final response = await apiClient.get(ApiConstants.visitaById(id));
    return Visita.fromJson(response);
  }

  Future<Visita> crearVisita(CreateVisitaRequest request) async {
    final response = await apiClient.post(ApiConstants.visitas, request.toJson());
    return Visita.fromJson(response);
  }

  Future<Visita> cancelarVisita(int id) async {
    final response = await apiClient.put(ApiConstants.cancelarVisita(id), {});
    return Visita.fromJson(response);
  }

  Future<ValidarQrResponse> validarQr(ValidarQrRequest request) async {
    final response = await apiClient.post(ApiConstants.validarQr, request.toJson());
    return ValidarQrResponse.fromJson(response);
  }

  Future<String> obtenerImagenQr(int id) async {
    final response = await apiClient.get(ApiConstants.qrImage(id));
    return response['qrImage'] as String;
  }
}
```

- [ ] **Step 2: Verify it compiles**

```bash
flutter analyze lib/features/visitas/services/visita_service.dart
```

Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/visitas/services/visita_service.dart
git commit -m "feat(visitas): add VisitaService with all API calls"
```

---

### Task 10: Create VisitaNotifier and providers

**Files:**
- Create: `lib/features/visitas/providers/visita_provider.dart`

- [ ] **Step 1: Create the provider file**

Create `lib/features/visitas/providers/visita_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/auth_provider.dart';
import '../models/create_visita_request.dart';
import '../models/validar_qr_request.dart';
import '../models/validar_qr_response.dart';
import '../models/visita.dart';
import '../services/visita_service.dart';

class VisitaState {
  final List<Visita> misVisitas;
  final List<Visita> todasVisitas;
  final bool isLoading;
  final String? error;

  VisitaState({
    this.misVisitas = const [],
    this.todasVisitas = const [],
    this.isLoading = false,
    this.error,
  });

  VisitaState copyWith({
    List<Visita>? misVisitas,
    List<Visita>? todasVisitas,
    bool? isLoading,
    String? error,
  }) {
    return VisitaState(
      misVisitas: misVisitas ?? this.misVisitas,
      todasVisitas: todasVisitas ?? this.todasVisitas,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class VisitaNotifier extends StateNotifier<VisitaState> {
  final VisitaService _service;

  VisitaNotifier(this._service) : super(VisitaState());

  Future<void> cargarMisVisitas() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final visitas = await _service.getMisVisitas();
      state = state.copyWith(misVisitas: visitas, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> cargarTodasVisitas() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final visitas = await _service.getTodasVisitas();
      state = state.copyWith(todasVisitas: visitas, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<Visita?> crearVisita(CreateVisitaRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final visita = await _service.crearVisita(request);
      state = state.copyWith(
        misVisitas: [...state.misVisitas, visita],
        isLoading: false,
      );
      return visita;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<void> cancelarVisita(int id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updated = await _service.cancelarVisita(id);
      state = state.copyWith(
        misVisitas: state.misVisitas.map((v) => v.id == id ? updated : v).toList(),
        todasVisitas: state.todasVisitas.map((v) => v.id == id ? updated : v).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<ValidarQrResponse?> validarQr(ValidarQrRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _service.validarQr(request);
      state = state.copyWith(isLoading: false);
      return response;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<String?> obtenerImagenQr(int id) async {
    try {
      return await _service.obtenerImagenQr(id);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final visitaServiceProvider = Provider<VisitaService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return VisitaService(apiClient: apiClient);
});

final visitaProvider = StateNotifierProvider<VisitaNotifier, VisitaState>((ref) {
  final service = ref.watch(visitaServiceProvider);
  return VisitaNotifier(service);
});
```

- [ ] **Step 2: Verify it compiles**

```bash
flutter analyze lib/features/visitas/providers/visita_provider.dart
```

Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/visitas/providers/visita_provider.dart
git commit -m "feat(visitas): add VisitaNotifier and Riverpod providers"
```

---

### Task 11: Create MainScaffold with role-based BottomNavigationBar

**Files:**
- Create: `lib/shared/widgets/main_scaffold.dart`

- [ ] **Step 1: Create MainScaffold**

Create `lib/shared/widgets/main_scaffold.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/perfil/screens/gestion_screen.dart';
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
    final notifier = ref.read(visitaProvider.notifier);
    switch (user.rol) {
      case Rol.usuario:
        notifier.cargarMisVisitas();
      case Rol.guardia:
      case Rol.admin:
      case Rol.superadmin:
        notifier.cargarTodasVisitas();
    }
  }

  List<Widget> _buildScreens(Rol rol) {
    return switch (rol) {
      Rol.usuario => [
          const InicioUsuarioScreen(),
          const MisVisitasScreen(),
          const CrearVisitaScreen(),
          const PerfilScreen(),
        ],
      Rol.guardia => [
          const EscanearQrScreen(),
          VisitasAdminScreen(filterToday: true),
          VisitasAdminScreen(filterToday: false),
          const PerfilScreen(),
        ],
      Rol.admin || Rol.superadmin => [
          const DashboardAdminScreen(),
          VisitasAdminScreen(filterToday: false),
          const GestionScreen(),
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

- [ ] **Step 2: Commit (screens not created yet — will fix analyze errors in next tasks)**

```bash
git add lib/shared/widgets/main_scaffold.dart
git commit -m "feat(nav): add MainScaffold with role-based BottomNavigationBar"
```

---

### Task 12: Create PerfilScreen and GestionScreen

**Files:**
- Create: `lib/features/perfil/screens/perfil_screen.dart`
- Create: `lib/features/perfil/screens/gestion_screen.dart`

- [ ] **Step 1: Create PerfilScreen**

Create `lib/features/perfil/screens/perfil_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/auth_provider.dart';

class PerfilScreen extends ConsumerWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user!;
    final initials = user.nombreCompleto
        .split(' ')
        .where((s) => s.isNotEmpty)
        .take(2)
        .map((s) => s[0].toUpperCase())
        .join();

    return Scaffold(
      appBar: AppBar(title: const Text('Mi Perfil')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 44,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                initials,
                style: const TextStyle(fontSize: 28, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user.nombreCompleto,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              user.email,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Chip(label: Text(user.rol.name.toUpperCase())),
            if (user.unidadHabitacional != null) ...[
              const SizedBox(height: 4),
              Text('Unidad: ${user.unidadHabitacional}'),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(authProvider.notifier).logout();
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Create GestionScreen**

Create `lib/features/perfil/screens/gestion_screen.dart`:

```dart
import 'package:flutter/material.dart';

class GestionScreen extends StatelessWidget {
  const GestionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.construction, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Próximamente',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Gestión de usuarios y configuración del condominio',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/perfil/
git commit -m "feat(perfil): add PerfilScreen and GestionScreen"
```

---

### Task 13: Update GoRouter with /home routes

**Files:**
- Modify: `lib/core/routes/app_router.dart`

- [ ] **Step 1: Replace app_router.dart content**

Replace the entire content of `lib/core/routes/app_router.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
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
        ],
      ),
    ],
  );
});
```

- [ ] **Step 2: Commit**

```bash
git add lib/core/routes/app_router.dart
git commit -m "feat(router): update GoRouter with /home and visita detail route"
```

---

### Task 14: Create InicioUsuarioScreen (USUARIO tab 0)

**Files:**
- Create: `lib/features/visitas/screens/inicio_usuario_screen.dart`

- [ ] **Step 1: Create the screen**

Create `lib/features/visitas/screens/inicio_usuario_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/providers/auth_provider.dart';
import '../models/visita.dart';
import '../providers/visita_provider.dart';

class InicioUsuarioScreen extends ConsumerWidget {
  const InicioUsuarioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user!;
    final visitaState = ref.watch(visitaProvider);

    final proximas = visitaState.misVisitas
        .where((v) =>
            v.estado == EstadoVisita.programada &&
            v.fechaHoraProgramada.isAfter(DateTime.now()))
        .toList()
      ..sort((a, b) => a.fechaHoraProgramada.compareTo(b.fechaHoraProgramada));

    return Scaffold(
      appBar: AppBar(
        title: Text('Hola, ${user.nombreCompleto.split(' ').first}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Próximas visitas',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            if (visitaState.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (proximas.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(Icons.event_available, size: 48, color: Colors.grey),
                      const SizedBox(height: 8),
                      const Text('No tienes visitas próximas programadas'),
                    ],
                  ),
                ),
              )
            else
              ...proximas.take(3).map((v) => _VisitaPreviewTile(
                    visita: v,
                    onTap: () => context.push('/home/visitas/${v.id}'),
                  )),
          ],
        ),
      ),
    );
  }
}

class _VisitaPreviewTile extends StatelessWidget {
  final Visita visita;
  final VoidCallback onTap;

  const _VisitaPreviewTile({required this.visita, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.person_pin_circle),
        title: Text(visita.nombreVisitante),
        subtitle: Text(
          '${visita.fechaHoraProgramada.day}/${visita.fechaHoraProgramada.month}/${visita.fechaHoraProgramada.year} '
          '${visita.fechaHoraProgramada.hour.toString().padLeft(2, '0')}:${visita.fechaHoraProgramada.minute.toString().padLeft(2, '0')}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/visitas/screens/inicio_usuario_screen.dart
git commit -m "feat(visitas): add InicioUsuarioScreen with upcoming visits preview"
```

---

### Task 15: Create MisVisitasScreen (USUARIO tab 1)

**Files:**
- Create: `lib/features/visitas/screens/mis_visitas_screen.dart`

- [ ] **Step 1: Create the screen**

Create `lib/features/visitas/screens/mis_visitas_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/visita.dart';
import '../providers/visita_provider.dart';

class MisVisitasScreen extends ConsumerWidget {
  const MisVisitasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visitaState = ref.watch(visitaProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Visitas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(visitaProvider.notifier).cargarMisVisitas(),
          ),
        ],
      ),
      body: _buildBody(context, ref, visitaState),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, VisitaState state) {
    if (state.isLoading && state.misVisitas.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.misVisitas.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 8),
            Text(state.error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(visitaProvider.notifier).cargarMisVisitas(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (state.misVisitas.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 8),
            Text('No tienes visitas registradas'),
          ],
        ),
      );
    }

    final sorted = [...state.misVisitas]
      ..sort((a, b) => b.fechaHoraProgramada.compareTo(a.fechaHoraProgramada));

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final visita = sorted[index];
        return _VisitaCard(
          visita: visita,
          onTap: () => context.push('/home/visitas/${visita.id}'),
        );
      },
    );
  }
}

class _VisitaCard extends StatelessWidget {
  final Visita visita;
  final VoidCallback onTap;

  const _VisitaCard({required this.visita, required this.onTap});

  Color _estadoColor() {
    return switch (visita.estado) {
      EstadoVisita.programada => Colors.blue,
      EstadoVisita.completada => Colors.green,
      EstadoVisita.cancelada => Colors.red,
    };
  }

  String _estadoLabel() {
    return switch (visita.estado) {
      EstadoVisita.programada => 'PROGRAMADA',
      EstadoVisita.completada => 'COMPLETADA',
      EstadoVisita.cancelada => 'CANCELADA',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 60,
                decoration: BoxDecoration(
                  color: _estadoColor(),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      visita.nombreVisitante,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${visita.fechaHoraProgramada.day}/${visita.fechaHoraProgramada.month}/${visita.fechaHoraProgramada.year} '
                      '${visita.fechaHoraProgramada.hour.toString().padLeft(2, '0')}:${visita.fechaHoraProgramada.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    if (visita.motivo != null)
                      Text(
                        visita.motivo!,
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Chip(
                label: Text(
                  _estadoLabel(),
                  style: const TextStyle(fontSize: 10, color: Colors.white),
                ),
                backgroundColor: _estadoColor(),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
git add lib/features/visitas/screens/mis_visitas_screen.dart
git commit -m "feat(visitas): add MisVisitasScreen with sorted list and estado badges"
```

---

### Task 16: Create CrearVisitaScreen (USUARIO tab 2)

**Files:**
- Create: `lib/features/visitas/screens/crear_visita_screen.dart`

- [ ] **Step 1: Create the screen**

Create `lib/features/visitas/screens/crear_visita_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/create_visita_request.dart';
import '../providers/visita_provider.dart';

class CrearVisitaScreen extends ConsumerStatefulWidget {
  const CrearVisitaScreen({super.key});

  @override
  ConsumerState<CrearVisitaScreen> createState() => _CrearVisitaScreenState();
}

class _CrearVisitaScreenState extends ConsumerState<CrearVisitaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _motivoController = TextEditingController();
  final _placasController = TextEditingController();
  DateTime? _selectedDateTime;

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _motivoController.dispose();
    _placasController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final minDate = now.add(const Duration(minutes: 30));

    final date = await showDatePicker(
      context: context,
      initialDate: minDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(minDate),
    );
    if (time == null || !mounted) return;

    setState(() {
      _selectedDateTime = DateTime(
        date.year, date.month, date.day,
        time.hour, time.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona la fecha y hora de la visita')),
      );
      return;
    }

    final request = CreateVisitaRequest(
      nombreVisitante: _nombreController.text.trim(),
      telefonoVisitante: _telefonoController.text.trim().isEmpty
          ? null
          : _telefonoController.text.trim(),
      fechaHoraProgramada: _selectedDateTime!,
      motivo: _motivoController.text.trim().isEmpty
          ? null
          : _motivoController.text.trim(),
      vehiculoPlacas: _placasController.text.trim().isEmpty
          ? null
          : _placasController.text.trim(),
    );

    final visita = await ref.read(visitaProvider.notifier).crearVisita(request);

    if (!mounted) return;

    if (visita != null) {
      _formKey.currentState!.reset();
      _nombreController.clear();
      _telefonoController.clear();
      _motivoController.clear();
      _placasController.clear();
      setState(() => _selectedDateTime = null);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Visita creada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      final error = ref.read(visitaProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Error al crear la visita'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(visitaProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Nueva Visita')),
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
                  labelText: 'Nombre del visitante *',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                textInputAction: TextInputAction.next,
                enabled: !isLoading,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telefonoController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono del visitante',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                enabled: !isLoading,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: isLoading ? null : _pickDateTime,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Fecha y hora de visita *',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _selectedDateTime != null
                        ? _formatDateTime(_selectedDateTime!)
                        : 'Seleccionar fecha y hora',
                    style: TextStyle(
                      color: _selectedDateTime != null
                          ? null
                          : Theme.of(context).hintColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _motivoController,
                decoration: const InputDecoration(
                  labelText: 'Motivo de la visita',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 2,
                textInputAction: TextInputAction.next,
                enabled: !isLoading,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _placasController,
                decoration: const InputDecoration(
                  labelText: 'Placas del vehículo',
                  prefixIcon: Icon(Icons.directions_car),
                ),
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                enabled: !isLoading,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Crear Visita', style: TextStyle(fontSize: 16)),
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
git add lib/features/visitas/screens/crear_visita_screen.dart
git commit -m "feat(visitas): add CrearVisitaScreen with DateTimePicker and form validation"
```

---

### Task 17: Create DetalleVisitaScreen (sub-route with QR image)

**Files:**
- Create: `lib/features/visitas/screens/detalle_visita_screen.dart`

- [ ] **Step 1: Create the screen**

Create `lib/features/visitas/screens/detalle_visita_screen.dart`:

```dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/visita.dart';
import '../providers/visita_provider.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/models/usuario.dart';

class DetalleVisitaScreen extends ConsumerStatefulWidget {
  final int visitaId;

  const DetalleVisitaScreen({super.key, required this.visitaId});

  @override
  ConsumerState<DetalleVisitaScreen> createState() =>
      _DetalleVisitaScreenState();
}

class _DetalleVisitaScreenState extends ConsumerState<DetalleVisitaScreen> {
  String? _qrBase64;
  bool _loadingQr = true;
  bool _cancelando = false;

  @override
  void initState() {
    super.initState();
    _loadQr();
  }

  Future<void> _loadQr() async {
    final qr = await ref.read(visitaProvider.notifier).obtenerImagenQr(widget.visitaId);
    if (mounted) setState(() { _qrBase64 = qr; _loadingQr = false; });
  }

  Visita? _findVisita() {
    final state = ref.read(visitaProvider);
    for (final v in [...state.misVisitas, ...state.todasVisitas]) {
      if (v.id == widget.visitaId) return v;
    }
    return null;
  }

  Uint8List? _decodeQr() {
    if (_qrBase64 == null) return null;
    try {
      return base64Decode(_qrBase64!);
    } catch (_) {
      return null;
    }
  }

  Future<void> _cancelar(Visita visita) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar visita'),
        content: Text('¿Cancelar la visita de ${visita.nombreVisitante}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sí, cancelar')),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _cancelando = true);
    await ref.read(visitaProvider.notifier).cancelarVisita(visita.id);
    if (!mounted) return;
    setState(() => _cancelando = false);

    final error = ref.read(visitaProvider).error;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Visita cancelada'), backgroundColor: Colors.orange),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(visitaProvider);
    final visita = _findVisita();
    final user = ref.watch(authProvider).user!;
    final canCancel = visita?.estado == EstadoVisita.programada &&
        (user.rol == Rol.usuario || user.rol == Rol.admin || user.rol == Rol.superadmin);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Visita'),
        actions: [
          if (canCancel)
            TextButton(
              onPressed: _cancelando ? null : () => _cancelar(visita!),
              child: _cancelando
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Cancelar', style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
      body: visita == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // QR Code image
                  Center(
                    child: _loadingQr
                        ? const SizedBox(
                            height: 200,
                            width: 200,
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : _decodeQr() != null
                            ? Image.memory(
                                _decodeQr()!,
                                width: 200,
                                height: 200,
                                fit: BoxFit.contain,
                              )
                            : const Icon(Icons.qr_code, size: 100, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Muestra este QR al guardia de entrada',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Visit details
                  _InfoTile(icon: Icons.person, label: 'Visitante', value: visita.nombreVisitante),
                  if (visita.telefonoVisitante != null)
                    _InfoTile(icon: Icons.phone, label: 'Teléfono', value: visita.telefonoVisitante!),
                  _InfoTile(
                    icon: Icons.calendar_today,
                    label: 'Fecha y hora',
                    value: '${visita.fechaHoraProgramada.day}/${visita.fechaHoraProgramada.month}/${visita.fechaHoraProgramada.year} '
                        '${visita.fechaHoraProgramada.hour.toString().padLeft(2, '0')}:${visita.fechaHoraProgramada.minute.toString().padLeft(2, '0')}',
                  ),
                  if (visita.motivo != null)
                    _InfoTile(icon: Icons.description, label: 'Motivo', value: visita.motivo!),
                  if (visita.vehiculoPlacas != null)
                    _InfoTile(icon: Icons.directions_car, label: 'Placas', value: visita.vehiculoPlacas!),
                  _InfoTile(
                    icon: Icons.info_outline,
                    label: 'Estado',
                    value: visita.estado.name.toUpperCase(),
                    valueColor: switch (visita.estado) {
                      EstadoVisita.programada => Colors.blue,
                      EstadoVisita.completada => Colors.green,
                      EstadoVisita.cancelada => Colors.red,
                    },
                  ),
                  if (visita.fechaHoraEntrada != null)
                    _InfoTile(
                      icon: Icons.login,
                      label: 'Entrada registrada',
                      value: '${visita.fechaHoraEntrada!.day}/${visita.fechaHoraEntrada!.month}/${visita.fechaHoraEntrada!.year} '
                          '${visita.fechaHoraEntrada!.hour.toString().padLeft(2, '0')}:${visita.fechaHoraEntrada!.minute.toString().padLeft(2, '0')}',
                    ),
                  if (visita.guardiaEntradaNombre != null)
                    _InfoTile(
                      icon: Icons.security,
                      label: 'Guardia',
                      value: visita.guardiaEntradaNombre!,
                    ),
                ],
              ),
            ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoTile({
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
git add lib/features/visitas/screens/detalle_visita_screen.dart
git commit -m "feat(visitas): add DetalleVisitaScreen with QR image and cancel button"
```

---

### Task 18: Create EscanearQrScreen (GUARDIA tab 0)

**Files:**
- Create: `lib/features/visitas/screens/escanear_qr_screen.dart`

- [ ] **Step 1: Create the screen**

Create `lib/features/visitas/screens/escanear_qr_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/validar_qr_request.dart';
import '../models/validar_qr_response.dart';
import '../models/visita.dart';
import '../providers/visita_provider.dart';

class EscanearQrScreen extends ConsumerStatefulWidget {
  const EscanearQrScreen({super.key});

  @override
  ConsumerState<EscanearQrScreen> createState() => _EscanearQrScreenState();
}

class _EscanearQrScreenState extends ConsumerState<EscanearQrScreen> {
  bool _usarCamara = true;
  bool _procesando = false;
  bool _dialogOpen = false;
  final TextEditingController _codigoController = TextEditingController();
  final MobileScannerController _scannerController = MobileScannerController();

  @override
  void dispose() {
    _codigoController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _validar(String codigo) async {
    if (_procesando || codigo.isEmpty || _dialogOpen) return;
    setState(() => _procesando = true);

    final request = ValidarQrRequest(codigoQr: codigo.trim());
    final response = await ref.read(visitaProvider.notifier).validarQr(request);

    if (!mounted) return;
    setState(() => _procesando = false);

    if (response != null) {
      await _mostrarResultado(response);
    }
  }

  Future<void> _mostrarResultado(ValidarQrResponse response) async {
    setState(() => _dialogOpen = true);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              response.valido ? Icons.check_circle : Icons.cancel,
              color: response.valido ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                response.valido ? 'Acceso Permitido' : 'Acceso Denegado',
                style: TextStyle(color: response.valido ? Colors.green : Colors.red),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(response.mensaje),
            if (response.visita != null) ...[
              const Divider(height: 24),
              _ResultRow(label: 'Visitante', value: response.visita!.nombreVisitante),
              _ResultRow(label: 'Residente', value: response.visita!.usuarioNombre),
              if (response.visita!.unidadHabitacional != null)
                _ResultRow(label: 'Unidad', value: response.visita!.unidadHabitacional!),
              if (response.visita!.motivo != null)
                _ResultRow(label: 'Motivo', value: response.visita!.motivo!),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );

    if (mounted) {
      setState(() => _dialogOpen = false);
      if (_usarCamara) _scannerController.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Validar QR'),
        actions: [
          TextButton.icon(
            onPressed: () {
              setState(() {
                _usarCamara = !_usarCamara;
                if (_usarCamara) {
                  _scannerController.start();
                } else {
                  _scannerController.stop();
                }
              });
            },
            icon: Icon(_usarCamara ? Icons.keyboard : Icons.camera_alt),
            label: Text(_usarCamara ? 'Manual' : 'Cámara'),
          ),
        ],
      ),
      body: _usarCamara ? _buildCamara() : _buildManual(),
    );
  }

  Widget _buildCamara() {
    return Stack(
      children: [
        MobileScanner(
          controller: _scannerController,
          onDetect: (capture) {
            final barcodes = capture.barcodes;
            final code = barcodes.isEmpty ? null : barcodes.first.rawValue;
            if (code != null && !_procesando && !_dialogOpen) {
              _scannerController.stop();
              _validar(code);
            }
          },
        ),
        if (_procesando)
          Container(
            color: Colors.black45,
            child: const Center(child: CircularProgressIndicator(color: Colors.white)),
          ),
        Positioned(
          bottom: 32,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Apunta la cámara al código QR del visitante',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildManual() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Ingresa o pega el código QR del visitante:',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _codigoController,
            decoration: const InputDecoration(
              labelText: 'Código QR',
              hintText: 'Pega aquí el código QR',
              prefixIcon: Icon(Icons.qr_code),
            ),
            maxLines: 3,
            enabled: !_procesando,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _procesando
                ? null
                : () => _validar(_codigoController.text),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _procesando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Validar Entrada', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;

  const _ResultRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          Flexible(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/visitas/screens/escanear_qr_screen.dart
git commit -m "feat(visitas): add EscanearQrScreen with camera and manual code entry"
```

---

### Task 19: Create VisitasAdminScreen (GUARDIA + ADMIN)

**Files:**
- Create: `lib/features/visitas/screens/visitas_admin_screen.dart`

- [ ] **Step 1: Create the screen**

Create `lib/features/visitas/screens/visitas_admin_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/models/usuario.dart';
import '../../../shared/providers/auth_provider.dart';
import '../models/visita.dart';
import '../providers/visita_provider.dart';

class VisitasAdminScreen extends ConsumerWidget {
  final bool filterToday;

  const VisitasAdminScreen({super.key, this.filterToday = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visitaState = ref.watch(visitaProvider);
    final user = ref.watch(authProvider).user!;
    final canCancel = user.rol == Rol.admin || user.rol == Rol.superadmin;

    final now = DateTime.now();
    final visitas = filterToday
        ? visitaState.todasVisitas.where((v) =>
            v.fechaHoraProgramada.year == now.year &&
            v.fechaHoraProgramada.month == now.month &&
            v.fechaHoraProgramada.day == now.day).toList()
        : visitaState.todasVisitas.toList();

    visitas.sort((a, b) => b.fechaHoraProgramada.compareTo(a.fechaHoraProgramada));

    return Scaffold(
      appBar: AppBar(
        title: Text(filterToday ? 'Visitas de Hoy' : 'Historial de Visitas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(visitaProvider.notifier).cargarTodasVisitas(),
          ),
        ],
      ),
      body: _buildBody(context, ref, visitaState, visitas, canCancel),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    VisitaState state,
    List<Visita> visitas,
    bool canCancel,
  ) {
    if (state.isLoading && state.todasVisitas.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.todasVisitas.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 8),
            Text(state.error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(visitaProvider.notifier).cargarTodasVisitas(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (visitas.isEmpty) {
      return Center(
        child: Text(filterToday ? 'No hay visitas programadas para hoy' : 'No hay visitas registradas'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: visitas.length,
      itemBuilder: (context, index) {
        final visita = visitas[index];
        return _VisitaAdminCard(
          visita: visita,
          canCancel: canCancel && visita.estado == EstadoVisita.programada,
          onTap: () => context.push('/home/visitas/${visita.id}'),
          onCancel: canCancel
              ? () async {
                  await ref.read(visitaProvider.notifier).cancelarVisita(visita.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Visita cancelada')),
                    );
                  }
                }
              : null,
        );
      },
    );
  }
}

class _VisitaAdminCard extends StatelessWidget {
  final Visita visita;
  final bool canCancel;
  final VoidCallback onTap;
  final VoidCallback? onCancel;

  const _VisitaAdminCard({
    required this.visita,
    required this.canCancel,
    required this.onTap,
    this.onCancel,
  });

  Color _estadoColor() => switch (visita.estado) {
        EstadoVisita.programada => Colors.blue,
        EstadoVisita.completada => Colors.green,
        EstadoVisita.cancelada => Colors.red,
      };

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 56,
                decoration: BoxDecoration(
                  color: _estadoColor(),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      visita.nombreVisitante,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      'Residente: ${visita.usuarioNombre}'
                      '${visita.unidadHabitacional != null ? ' · ${visita.unidadHabitacional}' : ''}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    Text(
                      '${visita.fechaHoraProgramada.day}/${visita.fechaHoraProgramada.month}/${visita.fechaHoraProgramada.year} '
                      '${visita.fechaHoraProgramada.hour.toString().padLeft(2, '0')}:${visita.fechaHoraProgramada.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Chip(
                    label: Text(
                      visita.estado.name.toUpperCase(),
                      style: const TextStyle(fontSize: 9, color: Colors.white),
                    ),
                    backgroundColor: _estadoColor(),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  if (canCancel)
                    IconButton(
                      icon: const Icon(Icons.cancel_outlined, color: Colors.red, size: 20),
                      onPressed: onCancel,
                      tooltip: 'Cancelar visita',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
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
git add lib/features/visitas/screens/visitas_admin_screen.dart
git commit -m "feat(visitas): add VisitasAdminScreen with filterToday and cancel for ADMIN"
```

---

### Task 20: Create DashboardAdminScreen (ADMIN tab 0)

**Files:**
- Create: `lib/features/visitas/screens/dashboard_admin_screen.dart`

- [ ] **Step 1: Create the screen**

Create `lib/features/visitas/screens/dashboard_admin_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/visita.dart';
import '../providers/visita_provider.dart';

class DashboardAdminScreen extends ConsumerWidget {
  const DashboardAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visitaState = ref.watch(visitaProvider);
    final visitas = visitaState.todasVisitas;
    final now = DateTime.now();

    final hoy = visitas.where((v) =>
        v.fechaHoraProgramada.year == now.year &&
        v.fechaHoraProgramada.month == now.month &&
        v.fechaHoraProgramada.day == now.day).length;

    final programadas = visitas.where((v) => v.estado == EstadoVisita.programada).length;
    final completadas = visitas.where((v) => v.estado == EstadoVisita.completada).length;
    final canceladas = visitas.where((v) => v.estado == EstadoVisita.cancelada).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(visitaProvider.notifier).cargarTodasVisitas(),
          ),
        ],
      ),
      body: visitaState.isLoading && visitas.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resumen de visitas',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _StatCard(
                        title: 'Hoy',
                        count: hoy,
                        icon: Icons.today,
                        color: Colors.indigo,
                      ),
                      _StatCard(
                        title: 'Programadas',
                        count: programadas,
                        icon: Icons.schedule,
                        color: Colors.blue,
                      ),
                      _StatCard(
                        title: 'Completadas',
                        count: completadas,
                        icon: Icons.check_circle_outline,
                        color: Colors.green,
                      ),
                      _StatCard(
                        title: 'Canceladas',
                        count: canceladas,
                        icon: Icons.cancel_outlined,
                        color: Colors.red,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Total registradas: ${visitas.length}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(height: 8),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify full project compiles**

```bash
cd /Users/jandrade2/flutter/condos && flutter analyze
```

Expected: No errors. Fix any that appear (most likely unused imports).

- [ ] **Step 3: Commit**

```bash
git add lib/features/visitas/screens/dashboard_admin_screen.dart
git commit -m "feat(visitas): add DashboardAdminScreen with visit statistics"
```

---

### Task 21: Final verification

- [ ] **Step 1: Run all tests**

```bash
cd /Users/jandrade2/flutter/condos && flutter test
```

Expected: All tests pass.

- [ ] **Step 2: Run full analysis**

```bash
flutter analyze
```

Expected: No errors or warnings.

- [ ] **Step 3: Start the Spring Boot backend**

```bash
cd /Users/jandrade2/flutter/condos/backend && ./mvnw spring-boot:run
```

Expected: Server starts on port 8080 with Flyway migrations applied.

- [ ] **Step 4: Run the Flutter app**

```bash
cd /Users/jandrade2/flutter/condos && flutter run
```

Test login with:
- `admin` / `admin123` → ADMIN role → DashboardAdmin + tabs de admin
- (Create a GUARDIA user via DB) → EscanearQr + tabs de guardia
- (Create a USUARIO user via DB) → InicioUsuario + tabs de usuario

- [ ] **Step 5: Final commit**

```bash
git add -A
git commit -m "feat(flutter): complete visitas feature for all roles"
```
