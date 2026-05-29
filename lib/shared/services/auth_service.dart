import '../models/usuario.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';
import 'api_client.dart';
import 'storage_service.dart';

class AuthService {
  final ApiClient apiClient;
  final StorageService storageService;

  AuthService({
    required this.apiClient,
    required this.storageService,
  });

  Future<Usuario> login(String username, String password) async {
    final request = LoginRequest(username: username, password: password);

    final response = await apiClient.post(
      '/auth/login',
      request.toJson(),
    );

    final loginResponse = LoginResponse.fromJson(response);

    // Save token and user to storage
    await storageService.saveToken(loginResponse.token);
    await storageService.saveUser(loginResponse.usuario);

    // Update API client token
    apiClient.setToken(loginResponse.token);

    return loginResponse.usuario;
  }

  Future<Usuario> getCurrentUser() async {
    final response = await apiClient.get('/auth/me');
    final usuario = Usuario.fromJson(response);

    // Update cached user
    await storageService.saveUser(usuario);

    return usuario;
  }

  Future<void> logout() async {
    await storageService.clearToken();
    await storageService.clearUser();
    apiClient.setToken(null);
  }

  Future<bool> isAuthenticated() async {
    final token = await storageService.getToken();
    return token != null;
  }

  Future<Usuario?> getCachedUser() async {
    return await storageService.getUser();
  }

  Future<String?> getToken() async {
    return await storageService.getToken();
  }

  Future<void> initializeFromStorage() async {
    final token = await storageService.getToken();
    if (token != null) {
      apiClient.setToken(token);
    }
  }
}
