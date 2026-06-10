import 'package:json_annotation/json_annotation.dart';

part 'cuota_usuario_response.g.dart';

enum EstadoPago {
  @JsonValue('PENDIENTE')
  pendiente,

  @JsonValue('REPORTADO')
  reportado,

  @JsonValue('CONFIRMADO')
  confirmado,

  @JsonValue('RECHAZADO')
  rechazado,
}

@JsonSerializable()
class CuotaUsuarioResponse {
  final int id;
  final int cuotaId;
  final String concepto;
  final double monto;
  final String fechaVencimiento;
  final int usuarioId;
  final String usuarioNombre;
  final String? unidadHabitacional;
  final EstadoPago estado;
  final String? referenciaPago;
  final String? notasUsuario;
  final String? notasAdmin;
  final DateTime? fechaReporte;
  final DateTime? fechaConfirmacion;

  CuotaUsuarioResponse({
    required this.id,
    required this.cuotaId,
    required this.concepto,
    required this.monto,
    required this.fechaVencimiento,
    required this.usuarioId,
    required this.usuarioNombre,
    this.unidadHabitacional,
    required this.estado,
    this.referenciaPago,
    this.notasUsuario,
    this.notasAdmin,
    this.fechaReporte,
    this.fechaConfirmacion,
  });

  factory CuotaUsuarioResponse.fromJson(Map<String, dynamic> json) =>
      _$CuotaUsuarioResponseFromJson(json);
  Map<String, dynamic> toJson() => _$CuotaUsuarioResponseToJson(this);
}
