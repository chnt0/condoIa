// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_area_comun_request.dart';

CreateAreaComunRequest _$CreateAreaComunRequestFromJson(
        Map<String, dynamic> json) =>
    CreateAreaComunRequest(
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      capacidad: (json['capacidad'] as num).toInt(),
      horarioInicio: json['horarioInicio'] as String,
      horarioFin: json['horarioFin'] as String,
      duracionBloqueMinutos: (json['duracionBloqueMinutos'] as num).toInt(),
      maxReservasMesPorUsuario:
          (json['maxReservasMesPorUsuario'] as num).toInt(),
      anticipacionMinimaHoras:
          (json['anticipacionMinimaHoras'] as num).toInt(),
      anticipacionMaximaDias: (json['anticipacionMaximaDias'] as num).toInt(),
      activa: json['activa'] as bool,
    );

Map<String, dynamic> _$CreateAreaComunRequestToJson(
        CreateAreaComunRequest instance) =>
    <String, dynamic>{
      'nombre': instance.nombre,
      'descripcion': instance.descripcion,
      'capacidad': instance.capacidad,
      'horarioInicio': instance.horarioInicio,
      'horarioFin': instance.horarioFin,
      'duracionBloqueMinutos': instance.duracionBloqueMinutos,
      'maxReservasMesPorUsuario': instance.maxReservasMesPorUsuario,
      'anticipacionMinimaHoras': instance.anticipacionMinimaHoras,
      'anticipacionMaximaDias': instance.anticipacionMaximaDias,
      'activa': instance.activa,
    };
