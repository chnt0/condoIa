// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'confirmar_pago_request.dart';

ConfirmarPagoRequest _$ConfirmarPagoRequestFromJson(
        Map<String, dynamic> json) =>
    ConfirmarPagoRequest(
      confirmado: json['confirmado'] as bool,
      notasAdmin: json['notasAdmin'] as String?,
    );

Map<String, dynamic> _$ConfirmarPagoRequestToJson(
        ConfirmarPagoRequest instance) =>
    <String, dynamic>{
      'confirmado': instance.confirmado,
      'notasAdmin': instance.notasAdmin,
    };
