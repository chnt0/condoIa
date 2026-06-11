// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reservacion.dart';

Reservacion _$ReservacionFromJson(Map<String, dynamic> json) => Reservacion(
      id: (json['id'] as num).toInt(),
      areaComunId: (json['areaComunId'] as num).toInt(),
      areaComunNombre: json['areaComunNombre'] as String,
      usuarioId: (json['usuarioId'] as num).toInt(),
      usuarioNombre: json['usuarioNombre'] as String,
      fechaHoraInicio: DateTime.parse(json['fechaHoraInicio'] as String),
      fechaHoraFin: DateTime.parse(json['fechaHoraFin'] as String),
      estado: $enumDecode(_$EstadoReservacionEnumMap, json['estado']),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$ReservacionToJson(Reservacion instance) =>
    <String, dynamic>{
      'id': instance.id,
      'areaComunId': instance.areaComunId,
      'areaComunNombre': instance.areaComunNombre,
      'usuarioId': instance.usuarioId,
      'usuarioNombre': instance.usuarioNombre,
      'fechaHoraInicio': instance.fechaHoraInicio.toIso8601String(),
      'fechaHoraFin': instance.fechaHoraFin.toIso8601String(),
      'estado': _$EstadoReservacionEnumMap[instance.estado]!,
      'createdAt': instance.createdAt.toIso8601String(),
    };

const _$EstadoReservacionEnumMap = {
  EstadoReservacion.activa: 'ACTIVA',
  EstadoReservacion.cancelada: 'CANCELADA',
};
