import 'package:json_annotation/json_annotation.dart';
import 'cuota_response.dart';

part 'create_cuota_request.g.dart';

@JsonSerializable()
class CreateCuotaRequest {
  final TipoCuota tipo;
  final String concepto;
  final double monto;
  final String? mes;
  final String fechaVencimiento;
  final List<int>? usuarioIds;

  CreateCuotaRequest({
    required this.tipo,
    required this.concepto,
    required this.monto,
    this.mes,
    required this.fechaVencimiento,
    this.usuarioIds,
  });

  factory CreateCuotaRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateCuotaRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateCuotaRequestToJson(this);
}
