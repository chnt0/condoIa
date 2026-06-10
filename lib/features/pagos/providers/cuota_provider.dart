import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/auth_provider.dart';
import '../models/confirmar_pago_request.dart';
import '../models/create_cuota_request.dart';
import '../models/cuota_response.dart';
import '../models/cuota_usuario_response.dart';
import '../models/reportar_pago_request.dart';
import '../services/cuota_service.dart';

class CuotaState {
  final List<CuotaResponse> cuotas;
  final List<CuotaUsuarioResponse> misCuotas;
  final bool isLoading;
  final String? error;

  CuotaState({
    this.cuotas = const [],
    this.misCuotas = const [],
    this.isLoading = false,
    this.error,
  });

  CuotaState copyWith({
    List<CuotaResponse>? cuotas,
    List<CuotaUsuarioResponse>? misCuotas,
    bool? isLoading,
    String? error,
  }) {
    return CuotaState(
      cuotas: cuotas ?? this.cuotas,
      misCuotas: misCuotas ?? this.misCuotas,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class CuotaNotifier extends StateNotifier<CuotaState> {
  final CuotaService _service;

  CuotaNotifier(this._service) : super(CuotaState());

  Future<void> cargarCuotas() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final cuotas = await _service.listarCuotas();
      state = state.copyWith(cuotas: cuotas, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> cargarMisCuotas() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final misCuotas = await _service.listarMisCuotas();
      state = state.copyWith(misCuotas: misCuotas, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<CuotaResponse?> crearCuota(CreateCuotaRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final cuota = await _service.crearCuota(request);
      state = state.copyWith(
        cuotas: [cuota, ...state.cuotas],
        isLoading: false,
      );
      return cuota;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<List<CuotaUsuarioResponse>> obtenerDetalle(int cuotaId) async {
    try {
      return await _service.obtenerDetalle(cuotaId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  Future<void> reportarPago(
      int cuotaUsuarioId, ReportarPagoRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updated = await _service.reportarPago(cuotaUsuarioId, request);
      state = state.copyWith(
        misCuotas: state.misCuotas
            .map((c) => c.id == cuotaUsuarioId ? updated : c)
            .toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> confirmarPago(
      int cuotaUsuarioId, ConfirmarPagoRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.confirmarPago(cuotaUsuarioId, request);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final cuotaServiceProvider = Provider<CuotaService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CuotaService(apiClient: apiClient);
});

final cuotaProvider = StateNotifierProvider<CuotaNotifier, CuotaState>((ref) {
  final service = ref.watch(cuotaServiceProvider);
  return CuotaNotifier(service);
});
