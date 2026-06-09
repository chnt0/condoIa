// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'validar_qr_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ValidarQrRequest _$ValidarQrRequestFromJson(Map<String, dynamic> json) =>
    ValidarQrRequest(
      codigoQr: json['codigoQr'] as String,
      notas: json['notas'] as String?,
    );

Map<String, dynamic> _$ValidarQrRequestToJson(ValidarQrRequest instance) =>
    <String, dynamic>{
      'codigoQr': instance.codigoQr,
      'notas': instance.notas,
    };
