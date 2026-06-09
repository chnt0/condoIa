import 'package:json_annotation/json_annotation.dart';
import 'visita.dart';

part 'validar_qr_response.g.dart';

@JsonSerializable()
class ValidarQrResponse {
  final bool valido;
  final String mensaje;
  final Visita? visita;

  ValidarQrResponse({
    required this.valido,
    required this.mensaje,
    this.visita,
  });

  factory ValidarQrResponse.fromJson(Map<String, dynamic> json) =>
      _$ValidarQrResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ValidarQrResponseToJson(this);
}
