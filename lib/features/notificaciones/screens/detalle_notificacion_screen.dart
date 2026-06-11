import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/usuario.dart';
import '../../../shared/providers/auth_provider.dart';
import '../models/notificacion.dart';
import '../providers/notificacion_provider.dart';

class DetalleNotificacionScreen extends ConsumerWidget {
  final int notificacionId;

  const DetalleNotificacionScreen({super.key, required this.notificacionId});

  String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final state = ref.watch(notificacionProvider);
    final notificacion = state.notificaciones
        .where((n) => n.id == notificacionId)
        .firstOrNull;

    if (notificacion == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Aviso')),
        body: const Center(child: Text('Aviso no encontrado')),
      );
    }

    final esAdmin =
        user?.rol == Rol.admin || user?.rol == Rol.superadmin;
    final esEdificio = notificacion.segmento == SegmentoNotificacion.edificioX;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Aviso'),
        actions: [
          if (esAdmin)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: state.isLoading
                  ? null
                  : () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Eliminar aviso'),
                          content: const Text(
                              '¿Estás seguro de que quieres eliminar este aviso?'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancelar')),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red),
                              child: const Text('Eliminar'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true && context.mounted) {
                        await ref
                            .read(notificacionProvider.notifier)
                            .eliminarNotificacion(notificacionId);
                        if (context.mounted) Navigator.pop(context);
                      }
                    },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notificacion.titulo,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(
                  label: Text(
                    esEdificio
                        ? notificacion.edificio ?? 'Edificio'
                        : 'Todos',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 11),
                  ),
                  backgroundColor:
                      esEdificio ? Colors.orange : Colors.blue,
                ),
                const SizedBox(width: 8),
                Text(_fmt(notificacion.createdAt),
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey)),
              ],
            ),
            Text(
              'Publicado por: ${notificacion.adminCreadorNombre}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const Divider(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  notificacion.mensaje,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
