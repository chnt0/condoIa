import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/auth_provider.dart';
import '../models/area_comun.dart';
import '../models/create_area_comun_request.dart';
import '../services/area_comun_service.dart';

class AreaComunState {
  final List<AreaComun> areas;
  final bool isLoading;
  final String? error;

  AreaComunState({
    this.areas = const [],
    this.isLoading = false,
    this.error,
  });

  AreaComunState copyWith({
    List<AreaComun>? areas,
    bool? isLoading,
    String? error,
  }) {
    return AreaComunState(
      areas: areas ?? this.areas,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AreaComunNotifier extends StateNotifier<AreaComunState> {
  final AreaComunService _service;

  AreaComunNotifier(this._service) : super(AreaComunState());

  Future<void> cargarAreas() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final areas = await _service.listarAreas();
      state = state.copyWith(areas: areas, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<AreaComun?> crearArea(CreateAreaComunRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final area = await _service.crearArea(request);
      final areas = [...state.areas, area];
      areas.sort((a, b) => a.nombre.compareTo(b.nombre));
      state = state.copyWith(areas: areas, isLoading: false);
      return area;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<AreaComun?> editarArea(int id, CreateAreaComunRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updated = await _service.editarArea(id, request);
      state = state.copyWith(
        areas: state.areas.map((a) => a.id == id ? updated : a).toList(),
        isLoading: false,
      );
      return updated;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<void> toggleActiva(int id) async {
    try {
      final updated = await _service.toggleActiva(id);
      state = state.copyWith(
        areas: state.areas.map((a) => a.id == id ? updated : a).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void clearError() => state = state.copyWith(error: null);
}

final areaComunServiceProvider = Provider<AreaComunService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AreaComunService(apiClient: apiClient);
});

final areaComunProvider =
    StateNotifierProvider<AreaComunNotifier, AreaComunState>((ref) {
  final service = ref.watch(areaComunServiceProvider);
  return AreaComunNotifier(service);
});
