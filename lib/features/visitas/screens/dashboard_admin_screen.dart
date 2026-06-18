import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../incidentes/models/incidente.dart';
import '../../incidentes/providers/incidente_provider.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarMorosidad();
      ref.read(incidenteProvider.notifier).cargarIncidentes();
    });
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
    final incState = ref.watch(incidenteProvider);
    final incidentes = incState.incidentes
        .where((i) => i.estado != EstadoIncidente.cancelado)
        .toList();

    final pendientes =
        incidentes.where((i) => i.estado == EstadoIncidente.pendiente).length;
    final enProceso =
        incidentes.where((i) => i.estado == EstadoIncidente.enProceso).length;
    final resueltos =
        incidentes.where((i) => i.estado == EstadoIncidente.resuelto).length;
    final alta = incidentes
        .where((i) =>
            i.prioridad == PrioridadIncidente.alta &&
            i.estado != EstadoIncidente.resuelto)
        .length;

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
              _cargarMorosidad();
              ref.read(incidenteProvider.notifier).cargarIncidentes();
            },
          ),
        ],
      ),
      body: incState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Incidentes
                const Text('Incidentes',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _StatCard(
                        title: 'Pendientes',
                        value: '$pendientes',
                        icon: Icons.pending_outlined,
                        color: Colors.orange),
                    const SizedBox(width: 8),
                    _StatCard(
                        title: 'En proceso',
                        value: '$enProceso',
                        icon: Icons.autorenew,
                        color: Colors.blue),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _StatCard(
                        title: 'Resueltos',
                        value: '$resueltos',
                        icon: Icons.check_circle_outline,
                        color: Colors.green),
                    const SizedBox(width: 8),
                    _StatCard(
                        title: 'Prioridad alta',
                        value: '$alta',
                        icon: Icons.priority_high,
                        color: Colors.red),
                  ],
                ),
                const SizedBox(height: 24),

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
                              value:
                                  '\$${totalMonto.toStringAsFixed(0)}',
                              icon: Icons.money_off,
                              color: Colors.red),
                          const SizedBox(width: 8),
                          _StatCard(
                              title: 'Morosos',
                              value: '$totalMorosos',
                              icon: Icons.person_off_outlined,
                              color: Colors.orange),
                          const SizedBox(width: 8),
                          _StatCard(
                              title: 'Cuotas venc.',
                              value: '$cuotasVencidas',
                              icon: Icons.receipt_long,
                              color: Colors.deepOrange),
                        ],
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
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 6),
              Text(value,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color)),
              const SizedBox(height: 4),
              Text(title,
                  style: const TextStyle(
                      fontSize: 11, color: Colors.grey),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
