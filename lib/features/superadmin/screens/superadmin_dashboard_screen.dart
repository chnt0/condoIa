import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/condominio_sa.dart';
import '../providers/condominio_sa_provider.dart';

class SuperadminDashboardScreen extends ConsumerStatefulWidget {
  const SuperadminDashboardScreen({super.key});

  @override
  ConsumerState<SuperadminDashboardScreen> createState() =>
      _SuperadminDashboardScreenState();
}

class _SuperadminDashboardScreenState
    extends ConsumerState<SuperadminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(condominioSaProvider.notifier).cargarCondominios();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(condominioSaProvider);
    final total = state.condominios.length;
    final activos = state.condominios.where((c) => c.activo).length;
    final inactivos = total - activos;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel SUPERADMIN'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(condominioSaProvider.notifier).cargarCondominios(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/home/condominios/nuevo');
          ref.read(condominioSaProvider.notifier).cargarCondominios();
        },
        child: const Icon(Icons.add),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(condominioSaProvider.notifier).cargarCondominios(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      _StatCard('Total', total, Icons.apartment, Colors.indigo),
                      const SizedBox(width: 12),
                      _StatCard('Activos', activos,
                          Icons.check_circle_outline, Colors.green),
                      const SizedBox(width: 12),
                      _StatCard(
                          'Inactivos', inactivos, Icons.block, Colors.grey),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Condominios',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  if (state.error != null)
                    Text(state.error!,
                        style: const TextStyle(color: Colors.red)),
                  if (state.condominios.isEmpty && !state.isLoading)
                    const Center(
                        child: Text('No hay condominios registrados.'))
                  else
                    ...state.condominios.map((c) => _CondominioTile(c: c)),
                ],
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _StatCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text('$value',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color)),
              Text(label,
                  style:
                      const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CondominioTile extends ConsumerWidget {
  final CondominiSa c;

  const _CondominioTile({required this.c});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: c.activo ? Colors.indigo : Colors.grey,
          child: const Icon(Icons.apartment, color: Colors.white),
        ),
        title: Text(c.nombre,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (c.direccion != null) Text(c.direccion!),
            Text(
                '${c.numUnidades} unidades · ${c.totalUsuarios} usuarios · ${c.totalAdmins} admins'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: c.activo,
              onChanged: (_) => ref
                  .read(condominioSaProvider.notifier)
                  .toggleActivo(c.id),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () => context.push('/home/condominios/${c.id}/detalle'),
      ),
    );
  }
}
