import '../../../core/constants/api_constants.dart';
import '../../../shared/services/api_client.dart';
import '../models/create_notificacion_request.dart';
import '../models/notificacion.dart';

class NotificacionService {
  final ApiClient apiClient;

  NotificacionService({required this.apiClient});

  Future<List<Notificacion>> listarNotificaciones() async {
    final response = await apiClient.getList(ApiConstants.notificaciones);
    return response
        .map((item) => Notificacion.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Notificacion> crearNotificacion(CreateNotificacionRequest request) async {
    final response =
        await apiClient.post(ApiConstants.notificaciones, request.toJson());
    return Notificacion.fromJson(response);
  }

  Future<void> eliminarNotificacion(int id) async {
    await apiClient.delete(ApiConstants.notificacionById(id));
  }
}
