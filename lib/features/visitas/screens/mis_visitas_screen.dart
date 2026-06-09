import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/visita.dart';
import '../providers/visita_provider.dart';

class MisVisitasScreen extends ConsumerWidget {
  const MisVisitasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visitaState = ref.watch(visitaProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Visitas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(visitaProvider.notifier).cargarMisVisitas(),
          ),
        ],
      ),
      body: _buildBody(context, ref, visitaState),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, VisitaState state) {
    if (state.isLoading && state.misVisitas.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.misVisitas.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 8),
            Text(state.error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(visitaProvider.notifier).cargarMisVisitas(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (state.misVisitas.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 8),
            Text('No tienes visitas registradas'),
          ],
        ),
      );
    }

    final sorted = [...state.misVisitas]
      ..sort((a, b) => b.fechaHoraProgramada.compareTo(a.fechaHoraProgramada));

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final visita = sorted[index];
        return _VisitaCard(
          visita: visita,
          onTap: () => context.push('/home/visitas/${visita.id}'),
        );
      },
    );
  }
}

class _VisitaCard extends StatelessWidget {
  final Visita visita;
  final VoidCallback onTap;

  const _VisitaCard({required this.visita, required this.onTap});

  Color _estadoColor() {
    return switch (visita.estado) {
      EstadoVisita.programada => Colors.blue,
      EstadoVisita.completada => Colors.green,
      EstadoVisita.cancelada => Colors.red,
    };
  }

  String _estadoLabel() {
    return switch (visita.estado) {
      EstadoVisita.programada => 'PROGRAMADA',
      EstadoVisita.completada => 'COMPLETADA',
      EstadoVisita.cancelada => 'CANCELADA',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 60,
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
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${visita.fechaHoraProgramada.day}/${visita.fechaHoraProgramada.month}/${visita.fechaHoraProgramada.year} '
                      '${visita.fechaHoraProgramada.hour.toString().padLeft(2, '0')}:${visita.fechaHoraProgramada.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    if (visita.motivo != null)
                      Text(
                        visita.motivo!,
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Chip(
                label: Text(
                  _estadoLabel(),
                  style: const TextStyle(fontSize: 10, color: Colors.white),
                ),
                backgroundColor: _estadoColor(),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
