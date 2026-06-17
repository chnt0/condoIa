import 'package:json_annotation/json_annotation.dart';

part 'reportar_pago_request.g.dart';

@JsonSerializable()
class ReportarPagoRequest {
  final String referenciaPago;
  final String? notasUsuario;
  final String? comprobanteFoto;

  ReportarPagoRequest({
    required this.referenciaPago,
    this.notasUsuario,
    this.comprobanteFoto,
  });

  factory ReportarPagoRequest.fromJson(Map<String, dynamic> json) =>
      _$ReportarPagoRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ReportarPagoRequestToJson(this);
}
