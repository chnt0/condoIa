import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/visita.dart';
import '../providers/visita_provider.dart';

class DashboardAdminScreen extends ConsumerWidget {
  const DashboardAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visitaState = ref.watch(visitaProvider);
    final visitas = visitaState.todasVisitas;
    final now = DateTime.now();

    final hoy = visitas
        .where((v) =>
            v.fechaHoraProgramada.year == now.year &&
            v.fechaHoraProgramada.month == now.month &&
            v.fechaHoraProgramada.day == now.day)
        .length;

    final programadas = visitas.where((v) => v.estado == EstadoVisita.programada).length;
    final completadas = visitas.where((v) => v.estado == EstadoVisita.completada).length;
    final canceladas = visitas.where((v) => v.estado == EstadoVisita.cancelada).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(visitaProvider.notifier).cargarTodasVisitas(),
          ),
        ],
      ),
      body: visitaState.isLoading && visitas.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resumen de visitas',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _StatCard(title: 'Hoy', count: hoy, icon: Icons.today, color: Colors.indigo),
                      _StatCard(title: 'Programadas', count: programadas, icon: Icons.schedule, color: Colors.blue),
                      _StatCard(title: 'Completadas', count: completadas, icon: Icons.check_circle_outline, color: Colors.green),
                      _StatCard(title: 'Canceladas', count: canceladas, icon: Icons.cancel_outlined, color: Colors.red),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Total registradas: ${visitas.length}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(height: 8),
            Text(
              '$count',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color),
            ),
            Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
