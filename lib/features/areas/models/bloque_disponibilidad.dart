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
