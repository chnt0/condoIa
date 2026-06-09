// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_usuario_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateUsuarioRequest _$UpdateUsuarioRequestFromJson(
        Map<String, dynamic> json) =>
    UpdateUsuarioRequest(
      nombreCompleto: json['nombreCompleto'] as String,
      telefono: json['telefono'] as String?,
      rol: json['rol'] as String,
      unidadHabitacional: json['unidadHabitacional'] as String?,
      esPropietario: json['esPropietario'] as bool,
    );

Map<String, dynamic> _$UpdateUsuarioRequestToJson(
        UpdateUsuarioRequest instance) =>
    <String, dynamic>{
      'nombreCompleto': instance.nombreCompleto,
      'telefono': instance.telefono,
      'rol': instance.rol,
      'unidadHabitacional': instance.unidadHabitacional,
      'esPropietario': instance.esPropietario,
    };
