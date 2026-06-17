import 'package:json_annotation/json_annotation.dart';

part 'usuario_admin.g.dart';

enum RolUsuario {
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
class UsuarioAdmin {
  final int id;
  final String username;
  final String email;
  final String nombreCompleto;
  final String? telefono;
  final String? telefono2;
  final RolUsuario rol;
  final int? condominioId;
  final String? condominioNombre;
  final String? unidadHabitacional;
  final bool esPropietario;
  final bool activo;
  final DateTime createdAt;

  UsuarioAdmin({
    required this.id,
    required this.username,
    required this.email,
    required this.nombreCompleto,
    this.telefono,
    this.telefono2,
    required this.rol,
    this.condominioId,
    this.condominioNombre,
    this.unidadHabitacional,
    required this.esPropietario,
    required this.activo,
    required this.createdAt,
  });

  factory UsuarioAdmin.fromJson(Map<String, dynamic> json) =>
      _$UsuarioAdminFromJson(json);
  Map<String, dynamic> toJson() => _$UsuarioAdminToJson(this);
}
