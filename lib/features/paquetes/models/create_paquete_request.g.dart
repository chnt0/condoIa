// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_paquete_request.dart';

CreatePaqueteRequest _$CreatePaqueteRequestFromJson(
        Map<String, dynamic> json) =>
    CreatePaqueteRequest(
      usuarioDestinatarioId: (json['usuarioDestinatarioId'] as num).toInt(),
      descripcion: json['descripcion'] as String,
      notas: json['notas'] as String?,
    );

Map<String, dynamic> _$CreatePaqueteRequestToJson(
        CreatePaqueteRequest instance) =>
    <String, dynamic>{
      'usuarioDestinatarioId': instance.usuarioDestinatarioId,
      'descripcion': instance.descripcion,
      'notas': instance.notas,
    };
