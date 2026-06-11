// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notificacion.dart';

Notificacion _$NotificacionFromJson(Map<String, dynamic> json) => Notificacion(
      id: (json['id'] as num).toInt(),
      titulo: json['titulo'] as String,
      mensaje: json['mensaje'] as String,
      segmento: $enumDecode(_$SegmentoNotificacionEnumMap, json['segmento']),
      edificio: json['edificio'] as String?,
      adminCreadorId: (json['adminCreadorId'] as num).toInt(),
      adminCreadorNombre: json['adminCreadorNombre'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$NotificacionToJson(Notificacion instance) =>
    <String, dynamic>{
      'id': instance.id,
      'titulo': instance.titulo,
      'mensaje': instance.mensaje,
      'segmento': _$SegmentoNotificacionEnumMap[instance.segmento]!,
      'edificio': instance.edificio,
      'adminCreadorId': instance.adminCreadorId,
      'adminCreadorNombre': instance.adminCreadorNombre,
      'createdAt': instance.createdAt.toIso8601String(),
    };

const _$SegmentoNotificacionEnumMap = {
  SegmentoNotificacion.todos: 'TODOS',
  SegmentoNotificacion.edificioX: 'EDIFICIO_X',
};
