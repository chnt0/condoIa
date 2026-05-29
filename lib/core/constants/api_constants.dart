class ApiConstants {
  static const String baseUrl = 'http://localhost:8080';
  static const String apiPrefix = '/api';

  static const String login = '$apiPrefix/auth/login';
  static const String me = '$apiPrefix/auth/me';

  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration defaultTimeout = Duration(seconds: 30);
}
