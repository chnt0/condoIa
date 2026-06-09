// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'visita.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Visita _$VisitaFromJson(Map<String, dynamic> json) => Visita(
      id: (json['id'] as num).toInt(),
      nombreVisitante: json['nombreVisitante'] as String,
      telefonoVisitante: json['telefonoVisitante'] as String?,
      fechaHoraProgramada:
          DateTime.parse(json['fechaHoraProgramada'] as String),
      codigoQrHash: json['codigoQrHash'] as String,
      motivo: json['motivo'] as String?,
      vehiculoPlacas: json['vehiculoPlacas'] as String?,
      estado: $enumDecode(_$EstadoVisitaEnumMap, json['estado']),
      fechaHoraEntrada: json['fechaHoraEntrada'] == null
          ? null
          : DateTime.parse(json['fechaHoraEntrada'] as String),
      notas: json['notas'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      usuarioId: (json['usuarioId'] as num).toInt(),
      usuarioNombre: json['usuarioNombre'] as String,
      unidadHabitacional: json['unidadHabitacional'] as String?,
      guardiaEntradaId: (json['guardiaEntradaId'] as num?)?.toInt(),
      guardiaEntradaNombre: json['guardiaEntradaNombre'] as String?,
    );

Map<String, dynamic> _$VisitaToJson(Visita instance) => <String, dynamic>{
      'id': instance.id,
      'nombreVisitante': instance.nombreVisitante,
      'telefonoVisitante': instance.telefonoVisitante,
      'fechaHoraProgramada': instance.fechaHoraProgramada.toIso8601String(),
      'codigoQrHash': instance.codigoQrHash,
      'motivo': instance.motivo,
      'vehiculoPlacas': instance.vehiculoPlacas,
      'estado': _$EstadoVisitaEnumMap[instance.estado]!,
      'fechaHoraEntrada': instance.fechaHoraEntrada?.toIso8601String(),
      'notas': instance.notas,
      'createdAt': instance.createdAt.toIso8601String(),
      'usuarioId': instance.usuarioId,
      'usuarioNombre': instance.usuarioNombre,
      'unidadHabitacional': instance.unidadHabitacional,
      'guardiaEntradaId': instance.guardiaEntradaId,
      'guardiaEntradaNombre': instance.guardiaEntradaNombre,
    };

const _$EstadoVisitaEnumMap = {
  EstadoVisita.programada: 'PROGRAMADA',
  EstadoVisita.completada: 'COMPLETADA',
  EstadoVisita.cancelada: 'CANCELADA',
};
