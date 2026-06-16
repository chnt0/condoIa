// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_condominio_request.dart';

CreateCondominioRequest _$CreateCondominioRequestFromJson(
        Map<String, dynamic> json) =>
    CreateCondominioRequest(
      nombre: json['nombre'] as String,
      direccion: json['direccion'] as String,
      numUnidades: (json['numUnidades'] as num).toInt(),
      activo: json['activo'] as bool,
    );

Map<String, dynamic> _$CreateCondominioRequestToJson(
        CreateCondominioRequest instance) =>
    <String, dynamic>{
      'nombre': instance.nombre,
      'direccion': instance.direccion,
      'numUnidades': instance.numUnidades,
      'activo': instance.activo,
    };
