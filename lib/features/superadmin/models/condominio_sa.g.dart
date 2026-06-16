// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'condominio_sa.dart';

CondominiSa _$CondominiSaFromJson(Map<String, dynamic> json) => CondominiSa(
      id: (json['id'] as num).toInt(),
      nombre: json['nombre'] as String,
      direccion: json['direccion'] as String?,
      numUnidades: (json['numUnidades'] as num).toInt(),
      activo: json['activo'] as bool,
      totalUsuarios: (json['totalUsuarios'] as num).toInt(),
      totalAdmins: (json['totalAdmins'] as num).toInt(),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$CondominiSaToJson(CondominiSa instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nombre': instance.nombre,
      'direccion': instance.direccion,
      'numUnidades': instance.numUnidades,
      'activo': instance.activo,
      'totalUsuarios': instance.totalUsuarios,
      'totalAdmins': instance.totalAdmins,
      'createdAt': instance.createdAt?.toIso8601String(),
    };
