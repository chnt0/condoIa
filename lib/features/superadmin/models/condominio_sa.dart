import 'package:json_annotation/json_annotation.dart';

part 'condominio_sa.g.dart';

@JsonSerializable()
class CondominiSa {
  final int id;
  final String nombre;
  final String? direccion;
  final int numUnidades;
  final bool activo;
  final int totalUsuarios;
  final int totalAdmins;
  final DateTime? createdAt;

  CondominiSa({
    required this.id,
    required this.nombre,
    this.direccion,
    required this.numUnidades,
    required this.activo,
    required this.totalUsuarios,
    required this.totalAdmins,
    this.createdAt,
  });

  factory CondominiSa.fromJson(Map<String, dynamic> json) =>
      _$CondominiSaFromJson(json);
  Map<String, dynamic> toJson() => _$CondominiSaToJson(this);
}
