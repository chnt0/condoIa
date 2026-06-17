// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reportar_pago_request.dart';

ReportarPagoRequest _$ReportarPagoRequestFromJson(
        Map<String, dynamic> json) =>
    ReportarPagoRequest(
      referenciaPago: json['referenciaPago'] as String,
      notasUsuario: json['notasUsuario'] as String?,
      comprobanteFoto: json['comprobanteFoto'] as String?,
    );

Map<String, dynamic> _$ReportarPagoRequestToJson(
        ReportarPagoRequest instance) =>
    <String, dynamic>{
      'referenciaPago': instance.referenciaPago,
      'notasUsuario': instance.notasUsuario,
      'comprobanteFoto': instance.comprobanteFoto,
    };
