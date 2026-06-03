import 'package:flutter_test/flutter_test.dart';
import 'package:condos/shared/models/usuario.dart';
import 'package:condos/shared/models/api_error.dart';

void main() {
  group('Usuario Model', () {
    test('fromJson should parse correctly', () {
      final json = {
        'id': 1,
        'username': 'admin',
        'email': 'admin@example.com',
        'nombreCompleto': 'Admin User',
        'rol': 'ADMIN',
        'condominioId': 10,
        'condominioNombre': 'Condominio A',
        'unidadHabitacional': 'A-101',
      };

      final usuario = Usuario.fromJson(json);

      expect(usuario.id, 1);
      expect(usuario.username, 'admin');
      expect(usuario.email, 'admin@example.com');
      expect(usuario.nombreCompleto, 'Admin User');
      expect(usuario.rol, Rol.admin);
      expect(usuario.condominioId, 10);
      expect(usuario.condominioNombre, 'Condominio A');
      expect(usuario.unidadHabitacional, 'A-101');
    });

    test('toJson should serialize correctly', () {
      final usuario = Usuario(
        id: 1,
        username: 'admin',
        email: 'admin@example.com',
        nombreCompleto: 'Admin User',
        rol: Rol.admin,
        condominioId: 10,
        condominioNombre: 'Condominio A',
        unidadHabitacional: 'A-101',
      );

      final json = usuario.toJson();

      expect(json['id'], 1);
      expect(json['username'], 'admin');
      expect(json['email'], 'admin@example.com');
      expect(json['nombreCompleto'], 'Admin User');
      expect(json['rol'], 'ADMIN');
      expect(json['condominioId'], 10);
      expect(json['condominioNombre'], 'Condominio A');
      expect(json['unidadHabitacional'], 'A-101');
    });

    test('Rol enum should use correct JSON values', () {
      expect(Rol.superadmin, isA<Rol>());
      expect(Rol.admin, isA<Rol>());
      expect(Rol.usuario, isA<Rol>());
      expect(Rol.guardia, isA<Rol>());
    });
  });

  group('ApiError Model', () {
    test('fromJson should parse correctly', () {
      final json = {
        'error': 'Bad Request',
        'message': 'Invalid credentials',
        'code': 400,
        'timestamp': '2026-05-29T10:00:00Z',
      };

      final apiError = ApiError.fromJson(json);

      expect(apiError.error, 'Bad Request');
      expect(apiError.message, 'Invalid credentials');
      expect(apiError.code, 400);
      expect(apiError.timestamp, '2026-05-29T10:00:00Z');
    });

    test('toJson should serialize correctly', () {
      final apiError = ApiError(
        error: 'Bad Request',
        message: 'Invalid credentials',
        code: 400,
        timestamp: '2026-05-29T10:00:00Z',
      );

      final json = apiError.toJson();

      expect(json['error'], 'Bad Request');
      expect(json['message'], 'Invalid credentials');
      expect(json['code'], 400);
      expect(json['timestamp'], '2026-05-29T10:00:00Z');
    });

    test('timestamp should be optional', () {
      final json = {
        'error': 'Bad Request',
        'message': 'Invalid credentials',
        'code': 400,
      };

      final apiError = ApiError.fromJson(json);

      expect(apiError.timestamp, isNull);
    });
  });
}
