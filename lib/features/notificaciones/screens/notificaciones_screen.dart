import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/models/usuario.dart';
import '../../../shared/providers/auth_provider.dart';
import '../models/notificacion.dart';
import '../providers/notificacion_provider.dart';

class NotificacionesScreen extends ConsumerStatefulWidget {
  const NotificacionesScreen({super.key});

  @override
  ConsumerState<NotificacionesScreen> createState() =>
      _NotificacionesScreenState();
}

class _NotificacionesScreenState extends ConsumerState<NotificacionesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificacionProvider.notifier).cargarNotificaciones();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final state = ref.watch(notificacionProvider);
    final esAdmin =
        user?.rol == Rol.admin || user?.rol == Rol.superadmin;

    return Scaffold(
      appBar: AppBar(title: const Text('Avisos')),
      floatingActionButton: esAdmin
          ? FloatingActionButton(
              onPressed: () async {
                await context.push('/home/notificaciones/nueva');
                ref.read(notificacionProvider.notifier).cargarNotificaciones();
              },
              child: const Icon(Icons.add),
            )
          : null,
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(state.error!,
                          style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref
                            .read(notificacionProvider.notifier)
                            .cargarNotificaciones(),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : state.notificaciones.isEmpty
                  ? const Center(child: Text('No hay avisos publicados.'))
                  : RefreshIndicator(
                      onRefresh: () => ref
                          .read(notificacionProvider.notifier)
                          .cargarNotificaciones(),
                      child: ListView.builder(
                        itemCount: state.notificaciones.length,
                        itemBuilder: (context, index) {
                          final n = state.notificaciones[index];
                          return _NotificacionTile(n: n);
                        },
                      ),
                    ),
    );
  }
}

class _NotificacionTile extends StatelessWidget {
  final Notificacion n;

  const _NotificacionTile({required this.n});

  String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  @override
  Widget build(BuildContext context) {
    final esEdificio = n.segmento == SegmentoNotificacion.edificioX;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: const Icon(Icons.notifications_outlined, size: 32),
        title: Text(n.titulo,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(_fmt(n.createdAt),
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: Chip(
          label: Text(
            esEdificio ? n.edificio ?? 'Edificio' : 'Todos',
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
          backgroundColor: esEdificio ? Colors.orange : Colors.blue,
        ),
        onTap: () => context.push('/home/notificaciones/${n.id}'),
      ),
    );
  }
}
