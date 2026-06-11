// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_reservacion_request.dart';

CreateReservacionRequest _$CreateReservacionRequestFromJson(
        Map<String, dynamic> json) =>
    CreateReservacionRequest(
      areaComunId: (json['areaComunId'] as num).toInt(),
      fechaHoraInicio: DateTime.parse(json['fechaHoraInicio'] as String),
    );

Map<String, dynamic> _$CreateReservacionRequestToJson(
        CreateReservacionRequest instance) =>
    <String, dynamic>{
      'areaComunId': instance.areaComunId,
      'fechaHoraInicio': instance.fechaHoraInicio.toIso8601String(),
    };
