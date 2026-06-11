import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/auth_provider.dart';
import '../models/create_reservacion_request.dart';
import '../models/reservacion.dart';
import '../services/reservacion_service.dart';

class ReservacionState {
  final List<Reservacion> reservaciones;
  final List<Reservacion> misReservaciones;
  final bool isLoading;
  final String? error;

  ReservacionState({
    this.reservaciones = const [],
    this.misReservaciones = const [],
    this.isLoading = false,
    this.error,
  });

  ReservacionState copyWith({
    List<Reservacion>? reservaciones,
    List<Reservacion>? misReservaciones,
    bool? isLoading,
    String? error,
  }) {
    return ReservacionState(
      reservaciones: reservaciones ?? this.reservaciones,
      misReservaciones: misReservaciones ?? this.misReservaciones,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ReservacionNotifier extends StateNotifier<ReservacionState> {
  final ReservacionService _service;

  ReservacionNotifier(this._service) : super(ReservacionState());

  Future<void> cargarReservaciones() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final reservaciones = await _service.listarReservaciones();
      state = state.copyWith(reservaciones: reservaciones, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> cargarMisReservaciones() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final misReservaciones = await _service.listarMisReservaciones();
      state = state.copyWith(
          misReservaciones: misReservaciones, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<Reservacion?> crearReservacion(
      CreateReservacionRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final reservacion = await _service.crearReservacion(request);
      state = state.copyWith(
        misReservaciones: [reservacion, ...state.misReservaciones],
        isLoading: false,
      );
      return reservacion;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<void> cancelarReservacion(int id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.cancelarReservacion(id);
      Reservacion _cancel(Reservacion r) => r.id != id
          ? r
          : Reservacion(
              id: r.id,
              areaComunId: r.areaComunId,
              areaComunNombre: r.areaComunNombre,
              usuarioId: r.usuarioId,
              usuarioNombre: r.usuarioNombre,
              fechaHoraInicio: r.fechaHoraInicio,
              fechaHoraFin: r.fechaHoraFin,
              estado: EstadoReservacion.cancelada,
              createdAt: r.createdAt,
            );
      state = state.copyWith(
        misReservaciones: state.misReservaciones.map(_cancel).toList(),
        reservaciones: state.reservaciones.map(_cancel).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clearError() => state = state.copyWith(error: null);
}

final reservacionServiceProvider = Provider<ReservacionService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ReservacionService(apiClient: apiClient);
});

final reservacionProvider =
    StateNotifierProvider<ReservacionNotifier, ReservacionState>((ref) {
  final service = ref.watch(reservacionServiceProvider);
  return ReservacionNotifier(service);
});
