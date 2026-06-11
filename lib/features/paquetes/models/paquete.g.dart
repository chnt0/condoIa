// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paquete.dart';

Paquete _$PaqueteFromJson(Map<String, dynamic> json) => Paquete(
      id: (json['id'] as num).toInt(),
      usuarioDestinatarioId: (json['usuarioDestinatarioId'] as num).toInt(),
      destinatarioNombre: json['destinatarioNombre'] as String,
      destinatarioUnidad: json['destinatarioUnidad'] as String?,
      descripcion: json['descripcion'] as String,
      notas: json['notas'] as String?,
      fechaHoraLlegada: DateTime.parse(json['fechaHoraLlegada'] as String),
      guardiaRegistroId: (json['guardiaRegistroId'] as num).toInt(),
      guardiaRegistroNombre: json['guardiaRegistroNombre'] as String,
      estado: $enumDecode(_$EstadoPaqueteEnumMap, json['estado']),
      fechaHoraEntrega: json['fechaHoraEntrega'] == null
          ? null
          : DateTime.parse(json['fechaHoraEntrega'] as String),
      guardiaEntregaId: (json['guardiaEntregaId'] as num?)?.toInt(),
      guardiaEntregaNombre: json['guardiaEntregaNombre'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$PaqueteToJson(Paquete instance) => <String, dynamic>{
      'id': instance.id,
      'usuarioDestinatarioId': instance.usuarioDestinatarioId,
      'destinatarioNombre': instance.destinatarioNombre,
      'destinatarioUnidad': instance.destinatarioUnidad,
      'descripcion': instance.descripcion,
      'notas': instance.notas,
      'fechaHoraLlegada': instance.fechaHoraLlegada.toIso8601String(),
      'guardiaRegistroId': instance.guardiaRegistroId,
      'guardiaRegistroNombre': instance.guardiaRegistroNombre,
      'estado': _$EstadoPaqueteEnumMap[instance.estado]!,
      'fechaHoraEntrega': instance.fechaHoraEntrega?.toIso8601String(),
      'guardiaEntregaId': instance.guardiaEntregaId,
      'guardiaEntregaNombre': instance.guardiaEntregaNombre,
      'createdAt': instance.createdAt.toIso8601String(),
    };

const _$EstadoPaqueteEnumMap = {
  EstadoPaquete.pendiente: 'PENDIENTE',
  EstadoPaquete.entregado: 'ENTREGADO',
};
