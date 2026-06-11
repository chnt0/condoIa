import 'package:json_annotation/json_annotation.dart';

part 'comentario.g.dart';

@JsonSerializable()
class Comentario {
  final int id;
  final int incidenteId;
  final int usuarioId;
  final String usuarioNombre;
  final String comentario;
  final DateTime createdAt;

  Comentario({
    required this.id,
    required this.incidenteId,
    required this.usuarioId,
    required this.usuarioNombre,
    required this.comentario,
    required this.createdAt,
  });

  factory Comentario.fromJson(Map<String, dynamic> json) =>
      _$ComentarioFromJson(json);
  Map<String, dynamic> toJson() => _$ComentarioToJson(this);
}
