import 'package:json_annotation/json_annotation.dart';

part 'validar_qr_request.g.dart';

@JsonSerializable()
class ValidarQrRequest {
  final String codigoQr;
  final String? notas;

  ValidarQrRequest({required this.codigoQr, this.notas});

  factory ValidarQrRequest.fromJson(Map<String, dynamic> json) =>
      _$ValidarQrRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ValidarQrRequestToJson(this);
}
