// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_usuario_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateUsuarioRequest _$CreateUsuarioRequestFromJson(
        Map<String, dynamic> json) =>
    CreateUsuarioRequest(
      username: json['username'] as String,
      email: json['email'] as String,
      password: json['password'] as String,
      nombreCompleto: json['nombreCompleto'] as String,
      telefono: json['telefono'] as String?,
      telefono2: json['telefono2'] as String?,
      rol: json['rol'] as String,
      unidadHabitacional: json['unidadHabitacional'] as String?,
      esPropietario: json['esPropietario'] as bool? ?? false,
      condominioId: (json['condominioId'] as num?)?.toInt(),
    );

Map<String, dynamic> _$CreateUsuarioRequestToJson(
        CreateUsuarioRequest instance) =>
    <String, dynamic>{
      'username': instance.username,
      'email': instance.email,
      'password': instance.password,
      'nombreCompleto': instance.nombreCompleto,
      'telefono': instance.telefono,
      'telefono2': instance.telefono2,
      'rol': instance.rol,
      'unidadHabitacional': instance.unidadHabitacional,
      'esPropietario': instance.esPropietario,
      'condominioId': instance.condominioId,
    };
