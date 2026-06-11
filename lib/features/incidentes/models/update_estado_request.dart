import 'package:json_annotation/json_annotation.dart';
import 'incidente.dart';

part 'update_estado_request.g.dart';

@JsonSerializable()
class UpdateEstadoRequest {
  final EstadoIncidente estado;

  UpdateEstadoRequest({required this.estado});

  factory UpdateEstadoRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateEstadoRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateEstadoRequestToJson(this);
}
