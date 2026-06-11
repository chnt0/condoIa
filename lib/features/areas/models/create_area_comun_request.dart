import 'package:json_annotation/json_annotation.dart';

part 'create_area_comun_request.g.dart';

@JsonSerializable()
class CreateAreaComunRequest {
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

  CreateAreaComunRequest({
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
  });

  factory CreateAreaComunRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateAreaComunRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateAreaComunRequestToJson(this);
}
