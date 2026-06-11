import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/auth_provider.dart';
import '../models/create_notificacion_request.dart';
import '../models/notificacion.dart';
import '../services/notificacion_service.dart';

class NotificacionState {
  final List<Notificacion> notificaciones;
  final bool isLoading;
  final String? error;

  NotificacionState({
    this.notificaciones = const [],
    this.isLoading = false,
    this.error,
  });

  NotificacionState copyWith({
    List<Notificacion>? notificaciones,
    bool? isLoading,
    String? error,
  }) {
    return NotificacionState(
      notificaciones: notificaciones ?? this.notificaciones,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class NotificacionNotifier extends StateNotifier<NotificacionState> {
  final NotificacionService _service;

  NotificacionNotifier(this._service) : super(NotificacionState());

  Future<void> cargarNotificaciones() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final notificaciones = await _service.listarNotificaciones();
      state = state.copyWith(notificaciones: notificaciones, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<Notificacion?> crearNotificacion(CreateNotificacionRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final notificacion = await _service.crearNotificacion(request);
      state = state.copyWith(
        notificaciones: [notificacion, ...state.notificaciones],
        isLoading: false,
      );
      return notificacion;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<void> eliminarNotificacion(int id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.eliminarNotificacion(id);
      state = state.copyWith(
        notificaciones:
            state.notificaciones.where((n) => n.id != id).toList(),
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

final notificacionServiceProvider = Provider<NotificacionService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NotificacionService(apiClient: apiClient);
});

final notificacionProvider =
    StateNotifierProvider<NotificacionNotifier, NotificacionState>((ref) {
  final service = ref.watch(notificacionServiceProvider);
  return NotificacionNotifier(service);
});
