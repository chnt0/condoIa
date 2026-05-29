import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../models/usuario.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

// Storage Service Provider
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

// API Client Provider
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(baseUrl: ApiConstants.baseUrl);
});

// Auth Service Provider
final authServiceProvider = Provider<AuthService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final storageService = ref.watch(storageServiceProvider);
  return AuthService(
    apiClient: apiClient,
    storageService: storageService,
  );
});

// Auth State
class AuthState {
  final Usuario? user;
  final bool isLoading;
  final String? error;

  AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    Usuario? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  AuthState clearUser() {
    return AuthState(
      user: null,
      isLoading: isLoading,
      error: error,
    );
  }
}

// Auth Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(AuthState(isLoading: true)) {
    _init();
  }

  Future<void> _init() async {
    try {
      // Initialize API client from storage
      await _authService.initializeFromStorage();

      // Check if user is authenticated
      final isAuth = await _authService.isAuthenticated();
      if (isAuth) {
        final user = await _authService.getCachedUser();
        state = AuthState(user: user, isLoading: false);
      } else {
        state = AuthState(isLoading: false);
      }
    } catch (e) {
      state = AuthState(
        isLoading: false,
        error: 'Error al inicializar la sesión',
      );
    }
  }

  Future<void> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _authService.login(username, password);
      state = AuthState(user: user, isLoading: false);
    } catch (e) {
      state = AuthState(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    try {
      await _authService.logout();
      state = AuthState(isLoading: false);
    } catch (e) {
      state = AuthState(
        isLoading: false,
        error: 'Error al cerrar sesión',
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Auth Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});
