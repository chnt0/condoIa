import 'package:json_annotation/json_annotation.dart';

part 'residente_basico.g.dart';

@JsonSerializable()
class ResidenteBasico {
  final int id;
  final String nombreCompleto;
  final String? unidadHabitacional;
  final String? telefono;
  final String? telefono2;

  ResidenteBasico({
    required this.id,
    required this.nombreCompleto,
    this.unidadHabitacional,
    this.telefono,
    this.telefono2,
  });

  factory ResidenteBasico.fromJson(Map<String, dynamic> json) =>
      _$ResidenteBasicoFromJson(json);
  Map<String, dynamic> toJson() => _$ResidenteBasicoToJson(this);
}
