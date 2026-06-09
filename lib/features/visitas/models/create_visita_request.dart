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
