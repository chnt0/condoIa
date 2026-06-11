import 'package:json_annotation/json_annotation.dart';

part 'paquete.g.dart';

enum EstadoPaquete {
  @JsonValue('PENDIENTE')
  pendiente,

  @JsonValue('ENTREGADO')
  entregado,
}

@JsonSerializable()
class Paquete {
  final int id;
  final int usuarioDestinatarioId;
  final String destinatarioNombre;
  final String? destinatarioUnidad;
  final String descripcion;
  final String? notas;
  final DateTime fechaHoraLlegada;
  final int guardiaRegistroId;
  final String guardiaRegistroNombre;
  final EstadoPaquete estado;
  final DateTime? fechaHoraEntrega;
  final int? guardiaEntregaId;
  final String? guardiaEntregaNombre;
  final DateTime createdAt;

  Paquete({
    required this.id,
    required this.usuarioDestinatarioId,
    required this.destinatarioNombre,
    this.destinatarioUnidad,
    required this.descripcion,
    this.notas,
    required this.fechaHoraLlegada,
    required this.guardiaRegistroId,
    required this.guardiaRegistroNombre,
    required this.estado,
    this.fechaHoraEntrega,
    this.guardiaEntregaId,
    this.guardiaEntregaNombre,
    required this.createdAt,
  });

  factory Paquete.fromJson(Map<String, dynamic> json) => _$PaqueteFromJson(json);
  Map<String, dynamic> toJson() => _$PaqueteToJson(this);
}
