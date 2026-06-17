import 'package:json_annotation/json_annotation.dart';
import 'incidente.dart';

part 'create_incidente_request.g.dart';

@JsonSerializable()
class CreateIncidenteRequest {
  final String categoria;       // nombre dinámico de la categoría
  final String titulo;
  final String descripcion;
  final String ubicacion;
  final PrioridadIncidente prioridad;

  CreateIncidenteRequest({
    required this.categoria,
    required this.titulo,
    required this.descripcion,
    required this.ubicacion,
    required this.prioridad,
  });

  factory CreateIncidenteRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateIncidenteRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateIncidenteRequestToJson(this);
}
