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
