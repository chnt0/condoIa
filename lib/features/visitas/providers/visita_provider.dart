import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/auth_provider.dart';
import '../models/create_visita_request.dart';
import '../models/validar_qr_request.dart';
import '../models/validar_qr_response.dart';
import '../models/visita.dart';
import '../services/visita_service.dart';

class VisitaState {
  final List<Visita> misVisitas;
  final List<Visita> todasVisitas;
  final bool isLoading;
  final String? error;

  VisitaState({
    this.misVisitas = const [],
    this.todasVisitas = const [],
    this.isLoading = false,
    this.error,
  });

  VisitaState copyWith({
    List<Visita>? misVisitas,
    List<Visita>? todasVisitas,
    bool? isLoading,
    String? error,
  }) {
    return VisitaState(
      misVisitas: misVisitas ?? this.misVisitas,
      todasVisitas: todasVisitas ?? this.todasVisitas,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class VisitaNotifier extends StateNotifier<VisitaState> {
  final VisitaService _service;

  VisitaNotifier(this._service) : super(VisitaState());

  Future<void> cargarMisVisitas() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final visitas = await _service.getMisVisitas();
      state = state.copyWith(misVisitas: visitas, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> cargarTodasVisitas() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final visitas = await _service.getTodasVisitas();
      state = state.copyWith(todasVisitas: visitas, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<Visita?> crearVisita(CreateVisitaRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final visita = await _service.crearVisita(request);
      state = state.copyWith(
        misVisitas: [...state.misVisitas, visita],
        isLoading: false,
      );
      return visita;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<void> cancelarVisita(int id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updated = await _service.cancelarVisita(id);
      state = state.copyWith(
        misVisitas: state.misVisitas.map((v) => v.id == id ? updated : v).toList(),
        todasVisitas: state.todasVisitas.map((v) => v.id == id ? updated : v).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<ValidarQrResponse?> validarQr(ValidarQrRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _service.validarQr(request);
      state = state.copyWith(isLoading: false);
      return response;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<String?> obtenerImagenQr(int id) async {
    try {
      return await _service.obtenerImagenQr(id);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final visitaServiceProvider = Provider<VisitaService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return VisitaService(apiClient: apiClient);
});

final visitaProvider = StateNotifierProvider<VisitaNotifier, VisitaState>((ref) {
  final service = ref.watch(visitaServiceProvider);
  return VisitaNotifier(service);
});
