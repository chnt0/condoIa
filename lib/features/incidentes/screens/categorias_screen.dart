import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/categoria_provider.dart';

class CategoriasScreen extends ConsumerStatefulWidget {
  const CategoriasScreen({super.key});

  @override
  ConsumerState<CategoriasScreen> createState() => _CategoriasScreenState();
}

class _CategoriasScreenState extends ConsumerState<CategoriasScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(categoriaProvider.notifier).cargarCategorias();
    });
  }

  Future<void> _mostrarAgregar(BuildContext context) async {
    final ctrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva categoría'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'Nombre de la categoría',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              final cat = await ref
                  .read(categoriaProvider.notifier)
                  .crearCategoria(ctrl.text.trim());
              if (cat == null && context.mounted) {
                final error = ref.read(categoriaProvider).error;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(error ?? 'Error al crear categoría'),
                    backgroundColor: Colors.red));
                ref.read(categoriaProvider.notifier).clearError();
              }
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(categoriaProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorías de Incidentes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(categoriaProvider.notifier).cargarCategorias(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarAgregar(context),
        child: const Icon(Icons.add),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.categorias.isEmpty
              ? const Center(child: Text('No hay categorías configuradas.'))
              : Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'Activa o desactiva categorías. Las inactivas no aparecen al crear incidentes.',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: state.categorias.length,
                        itemBuilder: (context, index) {
                          final cat = state.categorias[index];
                          return ListTile(
                            leading: Icon(
                              Icons.category_outlined,
                              color: cat.activa ? Colors.indigo : Colors.grey,
                            ),
                            title: Text(
                              cat.nombre,
                              style: TextStyle(
                                color: cat.activa ? null : Colors.grey,
                                decoration: cat.activa
                                    ? null
                                    : TextDecoration.lineThrough,
                              ),
                            ),
                            trailing: Switch(
                              value: cat.activa,
                              onChanged: (_) => ref
                                  .read(categoriaProvider.notifier)
                                  .toggleActiva(cat.id),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
