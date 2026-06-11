// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comentario.dart';

Comentario _$ComentarioFromJson(Map<String, dynamic> json) => Comentario(
      id: (json['id'] as num).toInt(),
      incidenteId: (json['incidenteId'] as num).toInt(),
      usuarioId: (json['usuarioId'] as num).toInt(),
      usuarioNombre: json['usuarioNombre'] as String,
      comentario: json['comentario'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$ComentarioToJson(Comentario instance) =>
    <String, dynamic>{
      'id': instance.id,
      'incidenteId': instance.incidenteId,
      'usuarioId': instance.usuarioId,
      'usuarioNombre': instance.usuarioNombre,
      'comentario': instance.comentario,
      'createdAt': instance.createdAt.toIso8601String(),
    };
