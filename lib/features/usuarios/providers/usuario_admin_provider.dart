import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/auth_provider.dart';
import '../models/create_usuario_request.dart';
import '../models/update_usuario_request.dart';
import '../models/usuario_admin.dart';
import '../services/usuario_admin_service.dart';

class UsuarioAdminState {
  final List<UsuarioAdmin> usuarios;
  final bool isLoading;
  final String? error;

  UsuarioAdminState({
    this.usuarios = const [],
    this.isLoading = false,
    this.error,
  });

  UsuarioAdminState copyWith({
    List<UsuarioAdmin>? usuarios,
    bool? isLoading,
    String? error,
  }) {
    return UsuarioAdminState(
      usuarios: usuarios ?? this.usuarios,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class UsuarioAdminNotifier extends StateNotifier<UsuarioAdminState> {
  final UsuarioAdminService _service;

  UsuarioAdminNotifier(this._service) : super(UsuarioAdminState());

  Future<void> cargarUsuarios() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final usuarios = await _service.listarUsuarios();
      state = state.copyWith(usuarios: usuarios, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<UsuarioAdmin?> crearUsuario(CreateUsuarioRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final nuevo = await _service.crearUsuario(request);
      state = state.copyWith(
        usuarios: [...state.usuarios, nuevo],
        isLoading: false,
      );
      return nuevo;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<void> actualizarUsuario(int id, UpdateUsuarioRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final actualizado = await _service.actualizarUsuario(id, request);
      state = state.copyWith(
        usuarios: state.usuarios.map((u) => u.id == id ? actualizado : u).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> toggleEstado(int id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final actualizado = await _service.toggleEstado(id);
      state = state.copyWith(
        usuarios: state.usuarios.map((u) => u.id == id ? actualizado : u).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  Future<Map<String, dynamic>?> uploadCsv(
      List<int> bytes, String fileName) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _service.crearUsuariosBulk(bytes, fileName);
      await cargarUsuarios();
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }
}

final usuarioAdminServiceProvider = Provider<UsuarioAdminService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return UsuarioAdminService(apiClient: apiClient);
});

final usuarioAdminProvider =
    StateNotifierProvider<UsuarioAdminNotifier, UsuarioAdminState>((ref) {
  final service = ref.watch(usuarioAdminServiceProvider);
  return UsuarioAdminNotifier(service);
});
