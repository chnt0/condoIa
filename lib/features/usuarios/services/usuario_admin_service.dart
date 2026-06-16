import '../../../core/constants/api_constants.dart';
import '../../../shared/services/api_client.dart';
import '../models/create_usuario_request.dart';
import '../models/update_usuario_request.dart';
import '../models/usuario_admin.dart';


class UsuarioAdminService {
  final ApiClient apiClient;

  UsuarioAdminService({required this.apiClient});

  Future<List<UsuarioAdmin>> listarUsuarios() async {
    final response = await apiClient.getList(ApiConstants.usuarios);
    return response
        .map((item) => UsuarioAdmin.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<UsuarioAdmin> crearUsuario(CreateUsuarioRequest request) async {
    final response = await apiClient.post(ApiConstants.usuarios, request.toJson());
    return UsuarioAdmin.fromJson(response);
  }

  Future<UsuarioAdmin> obtenerUsuario(int id) async {
    final response = await apiClient.get(ApiConstants.usuarioById(id));
    return UsuarioAdmin.fromJson(response);
  }

  Future<UsuarioAdmin> actualizarUsuario(int id, UpdateUsuarioRequest request) async {
    final response = await apiClient.put(ApiConstants.usuarioById(id), request.toJson());
    return UsuarioAdmin.fromJson(response);
  }

  Future<UsuarioAdmin> toggleEstado(int id) async {
    final response = await apiClient.put(ApiConstants.usuarioEstado(id), {});
    return UsuarioAdmin.fromJson(response);
  }

  Future<Map<String, dynamic>> crearUsuariosBulk(
      String filePath, String fileName) async {
    return apiClient.postFile(
      ApiConstants.usuariosBulk,
      'file',
      filePath,
      fileName,
    );
  }
}
