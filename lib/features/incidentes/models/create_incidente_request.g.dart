// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_incidente_request.dart';

CreateIncidenteRequest _$CreateIncidenteRequestFromJson(
        Map<String, dynamic> json) =>
    CreateIncidenteRequest(
      categoria: json['categoria'] as String,
      titulo: json['titulo'] as String,
      descripcion: json['descripcion'] as String,
      ubicacion: json['ubicacion'] as String,
      prioridad: $enumDecode(_$PrioridadIncidenteEnumMap, json['prioridad']),
    );

Map<String, dynamic> _$CreateIncidenteRequestToJson(
        CreateIncidenteRequest instance) =>
    <String, dynamic>{
      'categoria': instance.categoria,
      'titulo': instance.titulo,
      'descripcion': instance.descripcion,
      'ubicacion': instance.ubicacion,
      'prioridad': _$PrioridadIncidenteEnumMap[instance.prioridad]!,
    };

const _$PrioridadIncidenteEnumMap = {
  PrioridadIncidente.baja: 'BAJA',
  PrioridadIncidente.media: 'MEDIA',
  PrioridadIncidente.alta: 'ALTA',
};
