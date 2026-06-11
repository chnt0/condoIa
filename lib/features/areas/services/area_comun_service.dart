import '../../../core/constants/api_constants.dart';
import '../../../shared/services/api_client.dart';
import '../models/area_comun.dart';
import '../models/bloque_disponibilidad.dart';
import '../models/create_area_comun_request.dart';

class AreaComunService {
  final ApiClient apiClient;

  AreaComunService({required this.apiClient});

  Future<List<AreaComun>> listarAreas() async {
    final response = await apiClient.getList(ApiConstants.areasComunes);
    return response
        .map((item) => AreaComun.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<AreaComun> crearArea(CreateAreaComunRequest request) async {
    final response =
        await apiClient.post(ApiConstants.areasComunes, request.toJson());
    return AreaComun.fromJson(response);
  }

  Future<AreaComun> editarArea(int id, CreateAreaComunRequest request) async {
    final response =
        await apiClient.put(ApiConstants.areaComunById(id), request.toJson());
    return AreaComun.fromJson(response);
  }

  Future<AreaComun> toggleActiva(int id) async {
    final response = await apiClient.put(ApiConstants.toggleAreaComun(id), {});
    return AreaComun.fromJson(response);
  }

  Future<List<BloqueDisponibilidad>> obtenerDisponibilidad(
      int id, String fecha) async {
    final response = await apiClient.getList(
      ApiConstants.disponibilidad(id),
      queryParameters: {'fecha': fecha},
    );
    return response
        .map((item) =>
            BloqueDisponibilidad.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
