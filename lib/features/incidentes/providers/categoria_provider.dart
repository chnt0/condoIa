import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../shared/providers/auth_provider.dart';
import '../models/categoria_incidente.dart';

class CategoriaState {
  final List<CategoriaIncidente> categorias;
  final bool isLoading;
  final String? error;

  CategoriaState({
    this.categorias = const [],
    this.isLoading = false,
    this.error,
  });

  CategoriaState copyWith({
    List<CategoriaIncidente>? categorias,
    bool? isLoading,
    String? error,
  }) {
    return CategoriaState(
      categorias: categorias ?? this.categorias,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class CategoriaNotifier extends StateNotifier<CategoriaState> {
  final dynamic apiClient;

  CategoriaNotifier(this.apiClient) : super(CategoriaState());

  Future<void> cargarCategorias() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response =
          await apiClient.getList(ApiConstants.categoriasIncidente);
      final categorias = (response as List)
          .map((item) =>
              CategoriaIncidente.fromJson(item as Map<String, dynamic>))
          .toList();
      state = state.copyWith(categorias: categorias, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<CategoriaIncidente?> crearCategoria(String nombre) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await apiClient
          .post(ApiConstants.categoriasIncidente, {'nombre': nombre});
      final cat = CategoriaIncidente.fromJson(response);
      final updated = [...state.categorias, cat]
        ..sort((a, b) => a.nombre.compareTo(b.nombre));
      state = state.copyWith(categorias: updated, isLoading: false);
      return cat;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<void> toggleActiva(int id) async {
    try {
      final response = await apiClient
          .put(ApiConstants.toggleCategoriaIncidente(id), {});
      final updated = CategoriaIncidente.fromJson(response);
      state = state.copyWith(
        categorias: state.categorias
            .map((c) => c.id == id ? updated : c)
            .toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void clearError() => state = state.copyWith(error: null);
}

final categoriaProvider =
    StateNotifierProvider<CategoriaNotifier, CategoriaState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CategoriaNotifier(apiClient);
});
