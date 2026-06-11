// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bloque_disponibilidad.dart';

BloqueDisponibilidad _$BloqueDisponibilidadFromJson(
        Map<String, dynamic> json) =>
    BloqueDisponibilidad(
      fechaHoraInicio: DateTime.parse(json['fechaHoraInicio'] as String),
      fechaHoraFin: DateTime.parse(json['fechaHoraFin'] as String),
      disponible: json['disponible'] as bool,
    );

Map<String, dynamic> _$BloqueDisponibilidadToJson(
        BloqueDisponibilidad instance) =>
    <String, dynamic>{
      'fechaHoraInicio': instance.fechaHoraInicio.toIso8601String(),
      'fechaHoraFin': instance.fechaHoraFin.toIso8601String(),
      'disponible': instance.disponible,
    };
