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
