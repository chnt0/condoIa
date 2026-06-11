// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_estado_request.dart';

UpdateEstadoRequest _$UpdateEstadoRequestFromJson(Map<String, dynamic> json) =>
    UpdateEstadoRequest(
      estado: $enumDecode(_$EstadoIncidenteEnumMap, json['estado']),
    );

Map<String, dynamic> _$UpdateEstadoRequestToJson(
        UpdateEstadoRequest instance) =>
    <String, dynamic>{
      'estado': _$EstadoIncidenteEnumMap[instance.estado]!,
    };

const _$EstadoIncidenteEnumMap = {
  EstadoIncidente.pendiente: 'PENDIENTE',
  EstadoIncidente.enProceso: 'EN_PROCESO',
  EstadoIncidente.resuelto: 'RESUELTO',
  EstadoIncidente.cancelado: 'CANCELADO',
};
