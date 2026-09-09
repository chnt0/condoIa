// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'residente_basico.dart';

ResidenteBasico _$ResidenteBasicoFromJson(Map<String, dynamic> json) =>
    ResidenteBasico(
      id: (json['id'] as num).toInt(),
      nombreCompleto: json['nombreCompleto'] as String,
      unidadHabitacional: json['unidadHabitacional'] as String?,
      telefono: json['telefono'] as String?,
      telefono2: json['telefono2'] as String?,
    );

Map<String, dynamic> _$ResidenteBasicoToJson(ResidenteBasico instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nombreCompleto': instance.nombreCompleto,
      'unidadHabitacional': instance.unidadHabitacional,
      'telefono': instance.telefono,
      'telefono2': instance.telefono2,
    };
