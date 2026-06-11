import 'package:json_annotation/json_annotation.dart';

part 'add_comentario_request.g.dart';

@JsonSerializable()
class AddComentarioRequest {
  final String comentario;

  AddComentarioRequest({required this.comentario});

  factory AddComentarioRequest.fromJson(Map<String, dynamic> json) =>
      _$AddComentarioRequestFromJson(json);
  Map<String, dynamic> toJson() => _$AddComentarioRequestToJson(this);
}
