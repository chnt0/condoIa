import 'package:json_annotation/json_annotation.dart';

part 'incidente.g.dart';

enum CategoriaIncidente {
  @JsonValue('MANTENIMIENTO')
  mantenimiento,
  @JsonValue('SEGURIDAD')
  seguridad,
  @JsonValue('RUIDO')
  ruido,
  @JsonValue('LIMPIEZA')
  limpieza,
  @JsonValue('OTRO')
  otro,
}

enum PrioridadIncidente {
  @JsonValue('BAJA')
  baja,
  @JsonValue('MEDIA')
  media,
  @JsonValue('ALTA')
  alta,
}

enum EstadoIncidente {
  @JsonValue('PENDIENTE')
  pendiente,
  @JsonValue('EN_PROCESO')
  enProceso,
  @JsonValue('RESUELTO')
  resuelto,
  @JsonValue('CANCELADO')
  cancelado,
}

@JsonSerializable()
class Incidente {
  final int id;
  final CategoriaIncidente categoria;
  final String titulo;
  final String descripcion;
  final String ubicacion;
  final PrioridadIncidente prioridad;
  final EstadoIncidente estado;
  final int usuarioReportaId;
  final String usuarioReportaNombre;
  final String? usuarioReportaUnidad;
  final DateTime createdAt;
  final DateTime updatedAt;

  Incidente({
    required this.id,
    required this.categoria,
    required this.titulo,
    required this.descripcion,
    required this.ubicacion,
    required this.prioridad,
    required this.estado,
    required this.usuarioReportaId,
    required this.usuarioReportaNombre,
    this.usuarioReportaUnidad,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Incidente.fromJson(Map<String, dynamic> json) =>
      _$IncidenteFromJson(json);
  Map<String, dynamic> toJson() => _$IncidenteToJson(this);
}
