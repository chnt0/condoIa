import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/auth_provider.dart';
import '../models/create_incidente_request.dart';
import '../models/incidente.dart';
import '../models/update_estado_request.dart';
import '../services/incidente_service.dart';

class IncidenteState {
  final List<Incidente> incidentes;
  final bool isLoading;
  final String? error;

  IncidenteState({
    this.incidentes = const [],
    this.isLoading = false,
    this.error,
  });

  IncidenteState copyWith({
    List<Incidente>? incidentes,
    bool? isLoading,
    String? error,
  }) {
    return IncidenteState(
      incidentes: incidentes ?? this.incidentes,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class IncidenteNotifier extends StateNotifier<IncidenteState> {
  final IncidenteService _service;

  IncidenteNotifier(this._service) : super(IncidenteState());

  Future<void> cargarIncidentes() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final incidentes = await _service.listarIncidentes();
      state = state.copyWith(incidentes: incidentes, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> cargarMisIncidentes() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final incidentes = await _service.listarMisIncidentes();
      state = state.copyWith(incidentes: incidentes, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<Incidente?> crearIncidente(CreateIncidenteRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final incidente = await _service.crearIncidente(request);
      state = state.copyWith(
        incidentes: [incidente, ...state.incidentes],
        isLoading: false,
      );
      return incidente;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<void> actualizarEstado(int id, UpdateEstadoRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updated = await _service.actualizarEstado(id, request);
      state = state.copyWith(
        incidentes:
            state.incidentes.map((i) => i.id == id ? updated : i).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> cancelarIncidente(int id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.cancelarIncidente(id);
      state = state.copyWith(
        incidentes: state.incidentes
            .map((i) => i.id == id
                ? Incidente(
                    id: i.id,
                    categoria: i.categoria,
                    titulo: i.titulo,
                    descripcion: i.descripcion,
                    ubicacion: i.ubicacion,
                    prioridad: i.prioridad,
                    estado: EstadoIncidente.cancelado,
                    usuarioReportaId: i.usuarioReportaId,
                    usuarioReportaNombre: i.usuarioReportaNombre,
                    usuarioReportaUnidad: i.usuarioReportaUnidad,
                    createdAt: i.createdAt,
                    updatedAt: DateTime.now(),
                  )
                : i)
            .toList(),
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

final incidenteServiceProvider = Provider<IncidenteService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return IncidenteService(apiClient: apiClient);
});

final incidenteProvider =
    StateNotifierProvider<IncidenteNotifier, IncidenteState>((ref) {
  final service = ref.watch(incidenteServiceProvider);
  return IncidenteNotifier(service);
});
