import 'package:json_annotation/json_annotation.dart';

part 'create_paquete_request.g.dart';

@JsonSerializable()
class CreatePaqueteRequest {
  final int usuarioDestinatarioId;
  final String descripcion;
  final String? notas;
  final String? foto;

  CreatePaqueteRequest({
    required this.usuarioDestinatarioId,
    required this.descripcion,
    this.notas,
    this.foto,
  });

  factory CreatePaqueteRequest.fromJson(Map<String, dynamic> json) =>
      _$CreatePaqueteRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreatePaqueteRequestToJson(this);
}
