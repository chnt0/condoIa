import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../shared/providers/auth_provider.dart';
import '../models/visita.dart';
import '../providers/visita_provider.dart';

class DashboardAdminScreen extends ConsumerStatefulWidget {
  const DashboardAdminScreen({super.key});

  @override
  ConsumerState<DashboardAdminScreen> createState() =>
      _DashboardAdminScreenState();
}

class _DashboardAdminScreenState extends ConsumerState<DashboardAdminScreen> {
  Map<String, dynamic>? _morosidad;
  bool _loadingMorosidad = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargarMorosidad());
  }

  Future<void> _cargarMorosidad() async {
    setState(() => _loadingMorosidad = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final data = await apiClient.get(ApiConstants.morosidad);
      setState(() {
        _morosidad = data;
        _loadingMorosidad = false;
      });
    } catch (e) {
      setState(() => _loadingMorosidad = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visitaState = ref.watch(visitaProvider);
    final visitas = visitaState.todasVisitas;
    final now = DateTime.now();

    final hoy = visitas
        .where((v) =>
            v.fechaHoraProgramada.year == now.year &&
            v.fechaHoraProgramada.month == now.month &&
            v.fechaHoraProgramada.day == now.day)
        .length;

    final programadas =
        visitas.where((v) => v.estado == EstadoVisita.programada).length;
    final completadas =
        visitas.where((v) => v.estado == EstadoVisita.completada).length;
    final canceladas =
        visitas.where((v) => v.estado == EstadoVisita.cancelada).length;

    final totalMonto =
        (_morosidad?['totalMonto'] as num?)?.toDouble() ?? 0.0;
    final totalMorosos = _morosidad?['totalMorosos'] as int? ?? 0;
    final cuotasVencidas = _morosidad?['cuotasVencidas'] as int? ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(visitaProvider.notifier).cargarTodasVisitas();
              _cargarMorosidad();
            },
          ),
        ],
      ),
      body: visitaState.isLoading && visitas.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Morosidad
                const Text('Morosidad',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                _loadingMorosidad
                    ? const Center(child: CircularProgressIndicator())
                    : Row(
                        children: [
                          _StatCard(
                            title: 'Total vencido',
                            value: '\$${totalMonto.toStringAsFixed(0)}',
                            icon: Icons.money_off,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 8),
                          _StatCard(
                            title: 'Morosos',
                            value: '$totalMorosos',
                            icon: Icons.person_off_outlined,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          _StatCard(
                            title: 'Cuotas venc.',
                            value: '$cuotasVencidas',
                            icon: Icons.receipt_long,
                            color: Colors.deepOrange,
                          ),
                        ],
                      ),
                const SizedBox(height: 24),

                // Visitas
                const Text('Resumen de visitas',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _StatCard(
                        title: 'Hoy',
                        value: '$hoy',
                        icon: Icons.today,
                        color: Colors.indigo),
                    _StatCard(
                        title: 'Programadas',
                        value: '$programadas',
                        icon: Icons.schedule,
                        color: Colors.blue),
                    _StatCard(
                        title: 'Completadas',
                        value: '$completadas',
                        icon: Icons.check_circle_outline,
                        color: Colors.green),
                    _StatCard(
                        title: 'Canceladas',
                        value: '$canceladas',
                        icon: Icons.cancel_outlined,
                        color: Colors.red),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Total registradas: ${visitas.length}',
                  style: const TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style:
                    const TextStyle(fontSize: 11, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
