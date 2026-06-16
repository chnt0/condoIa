import 'package:json_annotation/json_annotation.dart';

part 'create_condominio_request.g.dart';

@JsonSerializable()
class CreateCondominioRequest {
  final String nombre;
  final String direccion;
  final int numUnidades;
  final bool activo;

  CreateCondominioRequest({
    required this.nombre,
    required this.direccion,
    required this.numUnidades,
    required this.activo,
  });

  factory CreateCondominioRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateCondominioRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateCondominioRequestToJson(this);
}
