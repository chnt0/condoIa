import '../../../core/constants/api_constants.dart';
import '../../../shared/services/api_client.dart';
import '../models/create_paquete_request.dart';
import '../models/paquete.dart';
import '../models/residente_basico.dart';

class PaqueteService {
  final ApiClient apiClient;

  PaqueteService({required this.apiClient});

  Future<List<Paquete>> listarPaquetes() async {
    final response = await apiClient.getList(ApiConstants.paquetes);
    return response
        .map((item) => Paquete.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<Paquete>> listarMisPaquetes() async {
    final response = await apiClient.getList(ApiConstants.misPaquetes);
    return response
        .map((item) => Paquete.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Paquete> registrarPaquete(CreatePaqueteRequest request) async {
    final response = await apiClient.post(ApiConstants.paquetes, request.toJson());
    return Paquete.fromJson(response);
  }

  Future<Paquete> entregarPaquete(int id) async {
    final response = await apiClient.put(ApiConstants.entregarPaquete(id), {});
    return Paquete.fromJson(response);
  }

  Future<List<ResidenteBasico>> listarResidentes() async {
    final response = await apiClient.getList(ApiConstants.residentes);
    return response
        .map((item) => ResidenteBasico.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
