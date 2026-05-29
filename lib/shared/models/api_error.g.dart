// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_error.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApiError _$ApiErrorFromJson(Map<String, dynamic> json) => ApiError(
      error: json['error'] as String,
      message: json['message'] as String,
      code: (json['code'] as num).toInt(),
      timestamp: json['timestamp'] as String?,
    );

Map<String, dynamic> _$ApiErrorToJson(ApiError instance) => <String, dynamic>{
      'error': instance.error,
      'message': instance.message,
      'code': instance.code,
      'timestamp': instance.timestamp,
    };
