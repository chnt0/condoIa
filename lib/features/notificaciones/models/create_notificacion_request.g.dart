// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_notificacion_request.dart';

CreateNotificacionRequest _$CreateNotificacionRequestFromJson(
        Map<String, dynamic> json) =>
    CreateNotificacionRequest(
      titulo: json['titulo'] as String,
      mensaje: json['mensaje'] as String,
      segmento: $enumDecode(_$SegmentoNotificacionEnumMap, json['segmento']),
      edificio: json['edificio'] as String?,
    );

Map<String, dynamic> _$CreateNotificacionRequestToJson(
        CreateNotificacionRequest instance) =>
    <String, dynamic>{
      'titulo': instance.titulo,
      'mensaje': instance.mensaje,
      'segmento': _$SegmentoNotificacionEnumMap[instance.segmento]!,
      'edificio': instance.edificio,
    };

const _$SegmentoNotificacionEnumMap = {
  SegmentoNotificacion.todos: 'TODOS',
  SegmentoNotificacion.edificioX: 'EDIFICIO_X',
};
