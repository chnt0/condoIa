import '../../../core/constants/api_constants.dart';
import '../../../shared/services/api_client.dart';
import '../models/add_comentario_request.dart';
import '../models/comentario.dart';
import '../models/create_incidente_request.dart';
import '../models/incidente.dart';
import '../models/update_estado_request.dart';

class IncidenteService {
  final ApiClient apiClient;

  IncidenteService({required this.apiClient});

  Future<List<Incidente>> listarIncidentes() async {
    final response = await apiClient.getList(ApiConstants.incidentes);
    return response
        .map((item) => Incidente.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<Incidente>> listarMisIncidentes() async {
    final response = await apiClient.getList(ApiConstants.misIncidentes);
    return response
        .map((item) => Incidente.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Incidente> crearIncidente(CreateIncidenteRequest request) async {
    final response =
        await apiClient.post(ApiConstants.incidentes, request.toJson());
    return Incidente.fromJson(response);
  }

  Future<Incidente> actualizarEstado(int id, UpdateEstadoRequest request) async {
    final response =
        await apiClient.put(ApiConstants.incidenteEstado(id), request.toJson());
    return Incidente.fromJson(response);
  }

  Future<void> cancelarIncidente(int id) async {
    await apiClient.delete(ApiConstants.cancelarIncidente(id));
  }

  Future<List<Comentario>> listarComentarios(int incidenteId) async {
    final response =
        await apiClient.getList(ApiConstants.incidenteComentarios(incidenteId));
    return response
        .map((item) => Comentario.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Comentario> agregarComentario(
      int incidenteId, AddComentarioRequest request) async {
    final response = await apiClient.post(
        ApiConstants.incidenteComentarios(incidenteId), request.toJson());
    return Comentario.fromJson(response);
  }
}
