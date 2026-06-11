import 'package:json_annotation/json_annotation.dart';

part 'create_reservacion_request.g.dart';

@JsonSerializable()
class CreateReservacionRequest {
  final int areaComunId;
  final DateTime fechaHoraInicio;

  CreateReservacionRequest({
    required this.areaComunId,
    required this.fechaHoraInicio,
  });

  factory CreateReservacionRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateReservacionRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateReservacionRequestToJson(this);
}
