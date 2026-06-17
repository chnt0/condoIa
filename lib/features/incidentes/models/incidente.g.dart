// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'incidente.dart';

Incidente _$IncidenteFromJson(Map<String, dynamic> json) => Incidente(
      id: (json['id'] as num).toInt(),
      categoria: json['categoria'] as String,
      titulo: json['titulo'] as String,
      descripcion: json['descripcion'] as String,
      ubicacion: json['ubicacion'] as String,
      prioridad: $enumDecode(_$PrioridadIncidenteEnumMap, json['prioridad']),
      estado: $enumDecode(_$EstadoIncidenteEnumMap, json['estado']),
      usuarioReportaId: (json['usuarioReportaId'] as num).toInt(),
      usuarioReportaNombre: json['usuarioReportaNombre'] as String,
      usuarioReportaUnidad: json['usuarioReportaUnidad'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$IncidenteToJson(Incidente instance) =>
    <String, dynamic>{
      'id': instance.id,
      'categoria': instance.categoria,
      'titulo': instance.titulo,
      'descripcion': instance.descripcion,
      'ubicacion': instance.ubicacion,
      'prioridad': _$PrioridadIncidenteEnumMap[instance.prioridad]!,
      'estado': _$EstadoIncidenteEnumMap[instance.estado]!,
      'usuarioReportaId': instance.usuarioReportaId,
      'usuarioReportaNombre': instance.usuarioReportaNombre,
      'usuarioReportaUnidad': instance.usuarioReportaUnidad,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

const _$CategoriaIncidenteEnumMap = {
  CategoriaIncidente.mantenimiento: 'MANTENIMIENTO',
  CategoriaIncidente.seguridad: 'SEGURIDAD',
  CategoriaIncidente.ruido: 'RUIDO',
  CategoriaIncidente.limpieza: 'LIMPIEZA',
  CategoriaIncidente.otro: 'OTRO',
};

const _$PrioridadIncidenteEnumMap = {
  PrioridadIncidente.baja: 'BAJA',
  PrioridadIncidente.media: 'MEDIA',
  PrioridadIncidente.alta: 'ALTA',
};

const _$EstadoIncidenteEnumMap = {
  EstadoIncidente.pendiente: 'PENDIENTE',
  EstadoIncidente.enProceso: 'EN_PROCESO',
  EstadoIncidente.resuelto: 'RESUELTO',
  EstadoIncidente.cancelado: 'CANCELADO',
};
