import 'package:json_annotation/json_annotation.dart';

part 'categoria_incidente.g.dart';

@JsonSerializable()
class CategoriaIncidente {
  final int id;
  final String nombre;
  final bool activa;

  CategoriaIncidente({
    required this.id,
    required this.nombre,
    required this.activa,
  });

  factory CategoriaIncidente.fromJson(Map<String, dynamic> json) =>
      _$CategoriaIncidenteFromJson(json);
  Map<String, dynamic> toJson() => _$CategoriaIncidenteToJson(this);
}
