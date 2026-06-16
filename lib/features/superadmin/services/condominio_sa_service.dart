import '../../../core/constants/api_constants.dart';
import '../../../features/usuarios/models/usuario_admin.dart';
import '../../../shared/services/api_client.dart';
import '../models/condominio_sa.dart';
import '../models/create_condominio_request.dart';

class CondominioSaService {
  final ApiClient apiClient;

  CondominioSaService({required this.apiClient});

  Future<List<CondominiSa>> listarCondominios() async {
    final response = await apiClient.getList(ApiConstants.condominios);
    return response
        .map((item) => CondominiSa.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<CondominiSa> crearCondominio(CreateCondominioRequest request) async {
    final response =
        await apiClient.post(ApiConstants.condominios, request.toJson());
    return CondominiSa.fromJson(response);
  }

  Future<CondominiSa> editarCondominio(
      int id, CreateCondominioRequest request) async {
    final response =
        await apiClient.put(ApiConstants.condominioById(id), request.toJson());
    return CondominiSa.fromJson(response);
  }

  Future<CondominiSa> toggleActivo(int id) async {
    final response =
        await apiClient.put(ApiConstants.toggleCondominio(id), {});
    return CondominiSa.fromJson(response);
  }

  Future<List<UsuarioAdmin>> listarAdmins(int condominioId) async {
    final response =
        await apiClient.getList(ApiConstants.condominioAdmins(condominioId));
    return response
        .map((item) => UsuarioAdmin.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
