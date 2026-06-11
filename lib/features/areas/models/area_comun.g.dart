// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'area_comun.dart';

AreaComun _$AreaComunFromJson(Map<String, dynamic> json) => AreaComun(
      id: (json['id'] as num).toInt(),
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
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$AreaComunToJson(AreaComun instance) =>
    <String, dynamic>{
      'id': instance.id,
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
      'createdAt': instance.createdAt.toIso8601String(),
    };
