import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/models/usuario.dart';
import '../../../shared/providers/auth_provider.dart';
import '../models/visita.dart';
import '../providers/visita_provider.dart';

class VisitasAdminScreen extends ConsumerWidget {
  final bool filterToday;

  const VisitasAdminScreen({super.key, this.filterToday = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visitaState = ref.watch(visitaProvider);
    final user = ref.watch(authProvider).user!;
    final canCancel = user.rol == Rol.admin || user.rol == Rol.superadmin;

    final now = DateTime.now();
    final visitas = filterToday
        ? visitaState.todasVisitas
            .where((v) =>
                v.fechaHoraProgramada.year == now.year &&
                v.fechaHoraProgramada.month == now.month &&
                v.fechaHoraProgramada.day == now.day)
            .toList()
        : visitaState.todasVisitas.toList();

    visitas.sort((a, b) => b.fechaHoraProgramada.compareTo(a.fechaHoraProgramada));

    return Scaffold(
      appBar: AppBar(
        title: Text(filterToday ? 'Visitas de Hoy' : 'Historial de Visitas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(visitaProvider.notifier).cargarTodasVisitas(),
          ),
        ],
      ),
      body: _buildBody(context, ref, visitaState, visitas, canCancel),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    VisitaState state,
    List<Visita> visitas,
    bool canCancel,
  ) {
    if (state.isLoading && state.todasVisitas.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.todasVisitas.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 8),
            Text(state.error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(visitaProvider.notifier).cargarTodasVisitas(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (visitas.isEmpty) {
      return Center(
        child: Text(
          filterToday ? 'No hay visitas programadas para hoy' : 'No hay visitas registradas',
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: visitas.length,
      itemBuilder: (context, index) {
        final visita = visitas[index];
        return _VisitaAdminCard(
          visita: visita,
          canCancel: canCancel && visita.estado == EstadoVisita.programada,
          onTap: () => context.push('/home/visitas/${visita.id}'),
          onCancel: canCancel
              ? () async {
                  await ref.read(visitaProvider.notifier).cancelarVisita(visita.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Visita cancelada')),
                    );
                  }
                }
              : null,
        );
      },
    );
  }
}

class _VisitaAdminCard extends StatelessWidget {
  final Visita visita;
  final bool canCancel;
  final VoidCallback onTap;
  final VoidCallback? onCancel;

  const _VisitaAdminCard({
    required this.visita,
    required this.canCancel,
    required this.onTap,
    this.onCancel,
  });

  Color _estadoColor() => switch (visita.estado) {
        EstadoVisita.programada => Colors.blue,
        EstadoVisita.completada => Colors.green,
        EstadoVisita.cancelada => Colors.red,
      };

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 56,
                decoration: BoxDecoration(
                  color: _estadoColor(),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      visita.nombreVisitante,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      'Residente: ${visita.usuarioNombre}'
                      '${visita.unidadHabitacional != null ? ' · ${visita.unidadHabitacional}' : ''}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    Text(
                      '${visita.fechaHoraProgramada.day}/${visita.fechaHoraProgramada.month}/${visita.fechaHoraProgramada.year} '
                      '${visita.fechaHoraProgramada.hour.toString().padLeft(2, '0')}:${visita.fechaHoraProgramada.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Chip(
                    label: Text(
                      visita.estado.name.toUpperCase(),
                      style: const TextStyle(fontSize: 9, color: Colors.white),
                    ),
                    backgroundColor: _estadoColor(),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  if (canCancel)
                    IconButton(
                      icon: const Icon(Icons.cancel_outlined, color: Colors.red, size: 20),
                      onPressed: onCancel,
                      tooltip: 'Cancelar visita',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
