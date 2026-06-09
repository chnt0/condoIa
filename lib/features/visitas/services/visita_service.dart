import '../../../core/constants/api_constants.dart';
import '../../../shared/services/api_client.dart';
import '../models/create_visita_request.dart';
import '../models/validar_qr_request.dart';
import '../models/validar_qr_response.dart';
import '../models/visita.dart';

class VisitaService {
  final ApiClient apiClient;

  VisitaService({required this.apiClient});

  Future<List<Visita>> getMisVisitas() async {
    final response = await apiClient.getList(ApiConstants.misVisitas);
    return response
        .map((item) => Visita.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<Visita>> getTodasVisitas() async {
    final response = await apiClient.getList(ApiConstants.visitas);
    return response
        .map((item) => Visita.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Visita> getVisita(int id) async {
    final response = await apiClient.get(ApiConstants.visitaById(id));
    return Visita.fromJson(response);
  }

  Future<Visita> crearVisita(CreateVisitaRequest request) async {
    final response = await apiClient.post(ApiConstants.visitas, request.toJson());
    return Visita.fromJson(response);
  }

  Future<Visita> cancelarVisita(int id) async {
    final response = await apiClient.put(ApiConstants.cancelarVisita(id), {});
    return Visita.fromJson(response);
  }

  Future<ValidarQrResponse> validarQr(ValidarQrRequest request) async {
    final response = await apiClient.post(ApiConstants.validarQr, request.toJson());
    return ValidarQrResponse.fromJson(response);
  }

  Future<String> obtenerImagenQr(int id) async {
    final response = await apiClient.get(ApiConstants.qrImage(id));
    return response['qrImage'] as String;
  }
}
