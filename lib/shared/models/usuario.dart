import 'package:json_annotation/json_annotation.dart';

part 'usuario.g.dart';

enum Rol {
  @JsonValue('SUPERADMIN')
  superadmin,

  @JsonValue('ADMIN')
  admin,

  @JsonValue('USUARIO')
  usuario,

  @JsonValue('GUARDIA')
  guardia,
}

@JsonSerializable()
class Usuario {
  final int id;
  final String username;
  final String email;
  final String nombreCompleto;
  final Rol rol;
  final int? condominioId;
  final String? condominioNombre;
  final String? unidadHabitacional;

  Usuario({
    required this.id,
    required this.username,
    required this.email,
    required this.nombreCompleto,
    required this.rol,
    this.condominioId,
    this.condominioNombre,
    this.unidadHabitacional,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) =>
      _$UsuarioFromJson(json);

  Map<String, dynamic> toJson() => _$UsuarioToJson(this);
}
