import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/providers/auth_provider.dart';
import '../models/visita.dart';
import '../providers/visita_provider.dart';

class InicioUsuarioScreen extends ConsumerWidget {
  const InicioUsuarioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user!;
    final visitaState = ref.watch(visitaProvider);

    final proximas = visitaState.misVisitas
        .where((v) =>
            v.estado == EstadoVisita.programada &&
            v.fechaHoraProgramada.isAfter(DateTime.now()))
        .toList()
      ..sort((a, b) => a.fechaHoraProgramada.compareTo(b.fechaHoraProgramada));

    return Scaffold(
      appBar: AppBar(
        title: Text('Hola, ${user.nombreCompleto.split(' ').first}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Próximas visitas',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            if (visitaState.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (proximas.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: const [
                      Icon(Icons.event_available, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('No tienes visitas próximas programadas'),
                    ],
                  ),
                ),
              )
            else
              ...proximas.take(3).map((v) => _VisitaPreviewTile(
                    visita: v,
                    onTap: () => context.push('/home/visitas/${v.id}'),
                  )),
          ],
        ),
      ),
    );
  }
}

class _VisitaPreviewTile extends StatelessWidget {
  final Visita visita;
  final VoidCallback onTap;

  const _VisitaPreviewTile({required this.visita, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.person_pin_circle),
        title: Text(visita.nombreVisitante),
        subtitle: Text(
          '${visita.fechaHoraProgramada.day}/${visita.fechaHoraProgramada.month}/${visita.fechaHoraProgramada.year} '
          '${visita.fechaHoraProgramada.hour.toString().padLeft(2, '0')}:${visita.fechaHoraProgramada.minute.toString().padLeft(2, '0')}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
