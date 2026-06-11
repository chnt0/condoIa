import '../../../core/constants/api_constants.dart';
import '../../../shared/services/api_client.dart';
import '../models/create_reservacion_request.dart';
import '../models/reservacion.dart';

class ReservacionService {
  final ApiClient apiClient;

  ReservacionService({required this.apiClient});

  Future<List<Reservacion>> listarReservaciones() async {
    final response = await apiClient.getList(ApiConstants.reservaciones);
    return response
        .map((item) => Reservacion.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<Reservacion>> listarMisReservaciones() async {
    final response = await apiClient.getList(ApiConstants.misReservaciones);
    return response
        .map((item) => Reservacion.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Reservacion> crearReservacion(CreateReservacionRequest request) async {
    final response =
        await apiClient.post(ApiConstants.reservaciones, request.toJson());
    return Reservacion.fromJson(response);
  }

  Future<void> cancelarReservacion(int id) async {
    await apiClient.delete(ApiConstants.cancelarReservacion(id));
  }
}
