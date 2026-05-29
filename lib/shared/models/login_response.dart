import 'package:json_annotation/json_annotation.dart';
import 'usuario.dart';

part 'login_response.g.dart';

@JsonSerializable()
class LoginResponse {
  final String token;
  final Usuario usuario;

  LoginResponse({
    required this.token,
    required this.usuario,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseFromJson(json);

  Map<String, dynamic> toJson() => _$LoginResponseToJson(this);
}
