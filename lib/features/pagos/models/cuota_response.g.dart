// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cuota_response.dart';

CuotaResponse _$CuotaResponseFromJson(Map<String, dynamic> json) =>
    CuotaResponse(
      id: (json['id'] as num).toInt(),
      tipo: $enumDecode(_$TipoCuotaEnumMap, json['tipo']),
      concepto: json['concepto'] as String,
      monto: (json['monto'] as num).toDouble(),
      mes: json['mes'] as String?,
      fechaVencimiento: json['fechaVencimiento'] as String,
      totalResidentes: (json['totalResidentes'] as num).toInt(),
      totalConfirmados: (json['totalConfirmados'] as num).toInt(),
      totalReportados: (json['totalReportados'] as num).toInt(),
      totalPendientes: (json['totalPendientes'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$CuotaResponseToJson(CuotaResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tipo': _$TipoCuotaEnumMap[instance.tipo]!,
      'concepto': instance.concepto,
      'monto': instance.monto,
      'mes': instance.mes,
      'fechaVencimiento': instance.fechaVencimiento,
      'totalResidentes': instance.totalResidentes,
      'totalConfirmados': instance.totalConfirmados,
      'totalReportados': instance.totalReportados,
      'totalPendientes': instance.totalPendientes,
      'createdAt': instance.createdAt.toIso8601String(),
    };

const _$TipoCuotaEnumMap = {
  TipoCuota.mensual: 'MENSUAL',
  TipoCuota.extraordinaria: 'EXTRAORDINARIA',
};
