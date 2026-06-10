import 'package:json_annotation/json_annotation.dart';

part 'cuota_response.g.dart';

enum TipoCuota {
  @JsonValue('MENSUAL')
  mensual,

  @JsonValue('EXTRAORDINARIA')
  extraordinaria,
}

@JsonSerializable()
class CuotaResponse {
  final int id;
  final TipoCuota tipo;
  final String concepto;
  final double monto;
  final String? mes;
  final String fechaVencimiento;
  final int totalResidentes;
  final int totalConfirmados;
  final int totalReportados;
  final int totalPendientes;
  final DateTime createdAt;

  CuotaResponse({
    required this.id,
    required this.tipo,
    required this.concepto,
    required this.monto,
    this.mes,
    required this.fechaVencimiento,
    required this.totalResidentes,
    required this.totalConfirmados,
    required this.totalReportados,
    required this.totalPendientes,
    required this.createdAt,
  });

  factory CuotaResponse.fromJson(Map<String, dynamic> json) =>
      _$CuotaResponseFromJson(json);
  Map<String, dynamic> toJson() => _$CuotaResponseToJson(this);
}
