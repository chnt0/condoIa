import 'package:json_annotation/json_annotation.dart';

part 'update_usuario_request.g.dart';

@JsonSerializable()
class UpdateUsuarioRequest {
  final String nombreCompleto;
  final String? telefono;
  final String rol;
  final String? unidadHabitacional;
  final bool esPropietario;

  UpdateUsuarioRequest({
    required this.nombreCompleto,
    this.telefono,
    required this.rol,
    this.unidadHabitacional,
    required this.esPropietario,
  });

  factory UpdateUsuarioRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateUsuarioRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateUsuarioRequestToJson(this);
}
