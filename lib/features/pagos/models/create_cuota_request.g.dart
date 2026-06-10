// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_cuota_request.dart';

CreateCuotaRequest _$CreateCuotaRequestFromJson(Map<String, dynamic> json) =>
    CreateCuotaRequest(
      tipo: $enumDecode(_$TipoCuotaEnumMap, json['tipo']),
      concepto: json['concepto'] as String,
      monto: (json['monto'] as num).toDouble(),
      mes: json['mes'] as String?,
      fechaVencimiento: json['fechaVencimiento'] as String,
      usuarioIds: (json['usuarioIds'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
    );

Map<String, dynamic> _$CreateCuotaRequestToJson(
        CreateCuotaRequest instance) =>
    <String, dynamic>{
      'tipo': _$TipoCuotaEnumMap[instance.tipo]!,
      'concepto': instance.concepto,
      'monto': instance.monto,
      'mes': instance.mes,
      'fechaVencimiento': instance.fechaVencimiento,
      'usuarioIds': instance.usuarioIds,
    };

const _$TipoCuotaEnumMap = {
  TipoCuota.mensual: 'MENSUAL',
  TipoCuota.extraordinaria: 'EXTRAORDINARIA',
};
