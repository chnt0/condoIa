import 'package:json_annotation/json_annotation.dart';

part 'confirmar_pago_request.g.dart';

@JsonSerializable()
class ConfirmarPagoRequest {
  final bool confirmado;
  final String? notasAdmin;

  const ConfirmarPagoRequest({required this.confirmado, this.notasAdmin});

  factory ConfirmarPagoRequest.fromJson(Map<String, dynamic> json) =>
      _$ConfirmarPagoRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ConfirmarPagoRequestToJson(this);
}
