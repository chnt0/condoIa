// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_visita_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateVisitaRequest _$CreateVisitaRequestFromJson(Map<String, dynamic> json) =>
    CreateVisitaRequest(
      nombreVisitante: json['nombreVisitante'] as String,
      telefonoVisitante: json['telefonoVisitante'] as String?,
      fechaHoraProgramada:
          DateTime.parse(json['fechaHoraProgramada'] as String),
      motivo: json['motivo'] as String?,
      vehiculoPlacas: json['vehiculoPlacas'] as String?,
    );

Map<String, dynamic> _$CreateVisitaRequestToJson(
        CreateVisitaRequest instance) =>
    <String, dynamic>{
      'nombreVisitante': instance.nombreVisitante,
      'telefonoVisitante': instance.telefonoVisitante,
      'fechaHoraProgramada': instance.fechaHoraProgramada.toIso8601String(),
      'motivo': instance.motivo,
      'vehiculoPlacas': instance.vehiculoPlacas,
    };
