import 'package:json_annotation/json_annotation.dart';
import 'notificacion.dart';

part 'create_notificacion_request.g.dart';

@JsonSerializable()
class CreateNotificacionRequest {
  final String titulo;
  final String mensaje;
  final SegmentoNotificacion segmento;
  final String? edificio;

  CreateNotificacionRequest({
    required this.titulo,
    required this.mensaje,
    required this.segmento,
    this.edificio,
  });

  factory CreateNotificacionRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateNotificacionRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateNotificacionRequestToJson(this);
}
