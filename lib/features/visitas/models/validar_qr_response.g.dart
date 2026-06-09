// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'validar_qr_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ValidarQrResponse _$ValidarQrResponseFromJson(Map<String, dynamic> json) =>
    ValidarQrResponse(
      valido: json['valido'] as bool,
      mensaje: json['mensaje'] as String,
      visita: json['visita'] == null
          ? null
          : Visita.fromJson(json['visita'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ValidarQrResponseToJson(ValidarQrResponse instance) =>
    <String, dynamic>{
      'valido': instance.valido,
      'mensaje': instance.mensaje,
      'visita': instance.visita,
    };
