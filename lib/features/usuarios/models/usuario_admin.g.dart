// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'usuario_admin.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UsuarioAdmin _$UsuarioAdminFromJson(Map<String, dynamic> json) => UsuarioAdmin(
      id: (json['id'] as num).toInt(),
      username: json['username'] as String,
      email: json['email'] as String,
      nombreCompleto: json['nombreCompleto'] as String,
      telefono: json['telefono'] as String?,
      rol: $enumDecode(_$RolUsuarioEnumMap, json['rol']),
      condominioId: (json['condominioId'] as num?)?.toInt(),
      condominioNombre: json['condominioNombre'] as String?,
      unidadHabitacional: json['unidadHabitacional'] as String?,
      esPropietario: json['esPropietario'] as bool,
      activo: json['activo'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$UsuarioAdminToJson(UsuarioAdmin instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'email': instance.email,
      'nombreCompleto': instance.nombreCompleto,
      'telefono': instance.telefono,
      'rol': _$RolUsuarioEnumMap[instance.rol]!,
      'condominioId': instance.condominioId,
      'condominioNombre': instance.condominioNombre,
      'unidadHabitacional': instance.unidadHabitacional,
      'esPropietario': instance.esPropietario,
      'activo': instance.activo,
      'createdAt': instance.createdAt.toIso8601String(),
    };

const _$RolUsuarioEnumMap = {
  RolUsuario.superadmin: 'SUPERADMIN',
  RolUsuario.admin: 'ADMIN',
  RolUsuario.usuario: 'USUARIO',
  RolUsuario.guardia: 'GUARDIA',
};
