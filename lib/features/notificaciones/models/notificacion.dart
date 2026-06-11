import 'package:json_annotation/json_annotation.dart';

part 'notificacion.g.dart';

enum SegmentoNotificacion {
  @JsonValue('TODOS')
  todos,

  @JsonValue('EDIFICIO_X')
  edificioX,
}

@JsonSerializable()
class Notificacion {
  final int id;
  final String titulo;
  final String mensaje;
  final SegmentoNotificacion segmento;
  final String? edificio;
  final int adminCreadorId;
  final String adminCreadorNombre;
  final DateTime createdAt;

  Notificacion({
    required this.id,
    required this.titulo,
    required this.mensaje,
    required this.segmento,
    this.edificio,
    required this.adminCreadorId,
    required this.adminCreadorNombre,
    required this.createdAt,
  });

  factory Notificacion.fromJson(Map<String, dynamic> json) =>
      _$NotificacionFromJson(json);
  Map<String, dynamic> toJson() => _$NotificacionToJson(this);
}
