import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/auth_provider.dart';
import '../models/condominio_sa.dart';
import '../models/create_condominio_request.dart';
import '../services/condominio_sa_service.dart';

class CondominioSaState {
  final List<CondominiSa> condominios;
  final bool isLoading;
  final String? error;

  CondominioSaState({
    this.condominios = const [],
    this.isLoading = false,
    this.error,
  });

  CondominioSaState copyWith({
    List<CondominiSa>? condominios,
    bool? isLoading,
    String? error,
  }) {
    return CondominioSaState(
      condominios: condominios ?? this.condominios,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class CondominioSaNotifier extends StateNotifier<CondominioSaState> {
  final CondominioSaService _service;

  CondominioSaNotifier(this._service) : super(CondominioSaState());

  Future<void> cargarCondominios() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final condominios = await _service.listarCondominios();
      state = state.copyWith(condominios: condominios, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<CondominiSa?> crearCondominio(CreateCondominioRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final c = await _service.crearCondominio(request);
      final updated = [...state.condominios, c]
        ..sort((a, b) => a.nombre.compareTo(b.nombre));
      state = state.copyWith(condominios: updated, isLoading: false);
      return c;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<CondominiSa?> editarCondominio(
      int id, CreateCondominioRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updated = await _service.editarCondominio(id, request);
      state = state.copyWith(
        condominios:
            state.condominios.map((c) => c.id == id ? updated : c).toList(),
        isLoading: false,
      );
      return updated;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<void> toggleActivo(int id) async {
    try {
      final updated = await _service.toggleActivo(id);
      state = state.copyWith(
        condominios:
            state.condominios.map((c) => c.id == id ? updated : c).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void clearError() => state = state.copyWith(error: null);
}

final condominioSaServiceProvider = Provider<CondominioSaService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CondominioSaService(apiClient: apiClient);
});

final condominioSaProvider =
    StateNotifierProvider<CondominioSaNotifier, CondominioSaState>((ref) {
  final service = ref.watch(condominioSaServiceProvider);
  return CondominioSaNotifier(service);
});
