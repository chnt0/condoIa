import 'package:json_annotation/json_annotation.dart';

part 'create_usuario_request.g.dart';

@JsonSerializable()
class CreateUsuarioRequest {
  final String username;
  final String email;
  final String password;
  final String nombreCompleto;
  final String? telefono;
  final String? telefono2;
  final String rol;
  final String? unidadHabitacional;
  final bool esPropietario;
  final int? condominioId;

  CreateUsuarioRequest({
    required this.username,
    required this.email,
    required this.password,
    required this.nombreCompleto,
    this.telefono,
    this.telefono2,
    required this.rol,
    this.unidadHabitacional,
    this.esPropietario = false,
    this.condominioId,
  });

  factory CreateUsuarioRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateUsuarioRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateUsuarioRequestToJson(this);
}
