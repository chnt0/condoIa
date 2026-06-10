// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cuota_usuario_response.dart';

CuotaUsuarioResponse _$CuotaUsuarioResponseFromJson(
        Map<String, dynamic> json) =>
    CuotaUsuarioResponse(
      id: (json['id'] as num).toInt(),
      cuotaId: (json['cuotaId'] as num).toInt(),
      concepto: json['concepto'] as String,
      monto: (json['monto'] as num).toDouble(),
      fechaVencimiento: json['fechaVencimiento'] as String,
      usuarioId: (json['usuarioId'] as num).toInt(),
      usuarioNombre: json['usuarioNombre'] as String,
      unidadHabitacional: json['unidadHabitacional'] as String?,
      estado: $enumDecode(_$EstadoPagoEnumMap, json['estado']),
      referenciaPago: json['referenciaPago'] as String?,
      notasUsuario: json['notasUsuario'] as String?,
      notasAdmin: json['notasAdmin'] as String?,
      fechaReporte: json['fechaReporte'] == null
          ? null
          : DateTime.parse(json['fechaReporte'] as String),
      fechaConfirmacion: json['fechaConfirmacion'] == null
          ? null
          : DateTime.parse(json['fechaConfirmacion'] as String),
    );

Map<String, dynamic> _$CuotaUsuarioResponseToJson(
        CuotaUsuarioResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'cuotaId': instance.cuotaId,
      'concepto': instance.concepto,
      'monto': instance.monto,
      'fechaVencimiento': instance.fechaVencimiento,
      'usuarioId': instance.usuarioId,
      'usuarioNombre': instance.usuarioNombre,
      'unidadHabitacional': instance.unidadHabitacional,
      'estado': _$EstadoPagoEnumMap[instance.estado]!,
      'referenciaPago': instance.referenciaPago,
      'notasUsuario': instance.notasUsuario,
      'notasAdmin': instance.notasAdmin,
      'fechaReporte': instance.fechaReporte?.toIso8601String(),
      'fechaConfirmacion': instance.fechaConfirmacion?.toIso8601String(),
    };

const _$EstadoPagoEnumMap = {
  EstadoPago.pendiente: 'PENDIENTE',
  EstadoPago.reportado: 'REPORTADO',
  EstadoPago.confirmado: 'CONFIRMADO',
  EstadoPago.rechazado: 'RECHAZADO',
};
