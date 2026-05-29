// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'usuario.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Usuario _$UsuarioFromJson(Map<String, dynamic> json) => Usuario(
      id: (json['id'] as num).toInt(),
      username: json['username'] as String,
      email: json['email'] as String,
      nombreCompleto: json['nombreCompleto'] as String,
      rol: $enumDecode(_$RolEnumMap, json['rol']),
      condominioId: (json['condominioId'] as num?)?.toInt(),
      condominioNombre: json['condominioNombre'] as String?,
      unidadHabitacional: json['unidadHabitacional'] as String?,
    );

Map<String, dynamic> _$UsuarioToJson(Usuario instance) => <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'email': instance.email,
      'nombreCompleto': instance.nombreCompleto,
      'rol': _$RolEnumMap[instance.rol]!,
      'condominioId': instance.condominioId,
      'condominioNombre': instance.condominioNombre,
      'unidadHabitacional': instance.unidadHabitacional,
    };

const _$RolEnumMap = {
  Rol.superadmin: 'SUPERADMIN',
  Rol.admin: 'ADMIN',
  Rol.usuario: 'USUARIO',
  Rol.guardia: 'GUARDIA',
};
