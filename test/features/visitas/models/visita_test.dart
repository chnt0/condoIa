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
