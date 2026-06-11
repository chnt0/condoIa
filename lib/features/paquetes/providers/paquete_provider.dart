import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/auth_provider.dart';
import '../models/create_paquete_request.dart';
import '../models/paquete.dart';
import '../models/residente_basico.dart';
import '../services/paquete_service.dart';

class PaqueteState {
  final List<Paquete> paquetes;
  final List<ResidenteBasico> residentes;
  final bool isLoading;
  final String? error;

  PaqueteState({
    this.paquetes = const [],
    this.residentes = const [],
    this.isLoading = false,
    this.error,
  });

  PaqueteState copyWith({
    List<Paquete>? paquetes,
    List<ResidenteBasico>? residentes,
    bool? isLoading,
    String? error,
  }) {
    return PaqueteState(
      paquetes: paquetes ?? this.paquetes,
      residentes: residentes ?? this.residentes,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class PaqueteNotifier extends StateNotifier<PaqueteState> {
  final PaqueteService _service;

  PaqueteNotifier(this._service) : super(PaqueteState());

  Future<void> cargarPaquetes() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final paquetes = await _service.listarPaquetes();
      state = state.copyWith(paquetes: paquetes, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> cargarMisPaquetes() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final paquetes = await _service.listarMisPaquetes();
      state = state.copyWith(paquetes: paquetes, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> cargarResidentes() async {
    try {
      final residentes = await _service.listarResidentes();
      state = state.copyWith(residentes: residentes);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<Paquete?> registrarPaquete(CreatePaqueteRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final paquete = await _service.registrarPaquete(request);
      state = state.copyWith(
        paquetes: [paquete, ...state.paquetes],
        isLoading: false,
      );
      return paquete;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<void> entregarPaquete(int id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updated = await _service.entregarPaquete(id);
      state = state.copyWith(
        paquetes: state.paquetes.map((p) => p.id == id ? updated : p).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final paqueteServiceProvider = Provider<PaqueteService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PaqueteService(apiClient: apiClient);
});

final paqueteProvider = StateNotifierProvider<PaqueteNotifier, PaqueteState>((ref) {
  final service = ref.watch(paqueteServiceProvider);
  return PaqueteNotifier(service);
});
