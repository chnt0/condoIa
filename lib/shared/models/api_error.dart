import 'package:json_annotation/json_annotation.dart';

part 'api_error.g.dart';

@JsonSerializable()
class ApiError {
  final String error;
  final String message;
  final int code;
  final String? timestamp;

  ApiError({
    required this.error,
    required this.message,
    required this.code,
    this.timestamp,
  });

  factory ApiError.fromJson(Map<String, dynamic> json) =>
      _$ApiErrorFromJson(json);

  Map<String, dynamic> toJson() => _$ApiErrorToJson(this);
}
