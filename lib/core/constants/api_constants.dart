class ApiConstants {
  static const String baseUrl = 'http://localhost:8080';
  static const String apiPrefix = '/api';

  static const String login = '$apiPrefix/auth/login';
  static const String me = '$apiPrefix/auth/me';

  // Visitas
  static const String visitas = '$apiPrefix/visitas';
  static const String misVisitas = '$apiPrefix/visitas/mis-visitas';
  static const String validarQr = '$apiPrefix/visitas/validar-qr';

  static String visitaById(int id) => '$apiPrefix/visitas/$id';
  static String cancelarVisita(int id) => '$apiPrefix/visitas/$id/cancelar';
  static String qrImage(int id) => '$apiPrefix/visitas/$id/qr-image';

  // Usuarios (gestión por ADMIN)
  static const String usuarios = '$apiPrefix/usuarios';
  static String usuarioById(int id) => '$apiPrefix/usuarios/$id';
  static String usuarioEstado(int id) => '$apiPrefix/usuarios/$id/estado';

  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration defaultTimeout = Duration(seconds: 30);
}
