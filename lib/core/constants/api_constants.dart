class ApiConstants {
  // En desarrollo: flutter run (usa localhost por defecto)
  // En producción: flutter build apk --dart-define=BASE_URL=https://api.tu-dominio.com
  static const String baseUrl =
      String.fromEnvironment('BASE_URL', defaultValue: 'http://localhost:8080');
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
  static const String usuariosBulk = '$apiPrefix/usuarios/bulk';
  static String usuarioById(int id) => '$apiPrefix/usuarios/$id';
  static String usuarioEstado(int id) => '$apiPrefix/usuarios/$id/estado';

  // Condominios (SUPERADMIN)
  static const String condominios = '$apiPrefix/condominios';
  static String condominioById(int id) => '$apiPrefix/condominios/$id';
  static String toggleCondominio(int id) => '$apiPrefix/condominios/$id/toggle';
  static String condominioAdmins(int id) => '$apiPrefix/condominios/$id/admins';

  // Áreas Comunes
  static const String areasComunes = '$apiPrefix/areas-comunes';
  static String areaComunById(int id) => '$apiPrefix/areas-comunes/$id';
  static String toggleAreaComun(int id) => '$apiPrefix/areas-comunes/$id/toggle';
  static String disponibilidad(int id) => '$apiPrefix/areas-comunes/$id/disponibilidad';

  // Reservaciones
  static const String reservaciones = '$apiPrefix/reservaciones';
  static const String misReservaciones = '$apiPrefix/reservaciones/mis-reservaciones';
  static String cancelarReservacion(int id) => '$apiPrefix/reservaciones/$id';

  // Notificaciones
  static const String notificaciones = '$apiPrefix/notificaciones';
  static String notificacionById(int id) => '$apiPrefix/notificaciones/$id';

  // Incidentes
  static const String incidentes = '$apiPrefix/incidentes';
  static const String misIncidentes = '$apiPrefix/incidentes/mis-incidentes';
  static String incidenteEstado(int id) => '$apiPrefix/incidentes/$id/estado';
  static String cancelarIncidente(int id) => '$apiPrefix/incidentes/$id';
  static String incidenteComentarios(int id) => '$apiPrefix/incidentes/$id/comentarios';

  // Paquetes
  static const String paquetes = '$apiPrefix/paquetes';
  static const String misPaquetes = '$apiPrefix/paquetes/mis-paquetes';
  static String entregarPaquete(int id) => '$apiPrefix/paquetes/$id/entregar';
  static const String residentes = '$apiPrefix/usuarios/residentes';

  // Cuotas / Pagos
  static const String cuotas = '$apiPrefix/cuotas';
  static const String misCuotas = '$apiPrefix/cuotas/mis-cuotas';
  static String cuotaDetalle(int id) => '$apiPrefix/cuotas/$id/detalle';
  static String reportarPago(int cuotaUsuarioId) => '$apiPrefix/cuotas/$cuotaUsuarioId/reportar';
  static String confirmarPago(int cuotaUsuarioId) => '$apiPrefix/cuotas/$cuotaUsuarioId/confirmar';

  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration defaultTimeout = Duration(seconds: 30);
}
