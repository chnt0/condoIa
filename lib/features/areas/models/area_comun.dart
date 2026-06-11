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
