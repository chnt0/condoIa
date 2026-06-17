// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'categoria_incidente.dart';

CategoriaIncidente _$CategoriaIncidenteFromJson(Map<String, dynamic> json) =>
    CategoriaIncidente(
      id: (json['id'] as num).toInt(),
      nombre: json['nombre'] as String,
      activa: json['activa'] as bool,
    );

Map<String, dynamic> _$CategoriaIncidenteToJson(CategoriaIncidente instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nombre': instance.nombre,
      'activa': instance.activa,
    };
