import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/cuota_usuario_response.dart';
import '../providers/cuota_provider.dart';

class MisCuotasScreen extends ConsumerStatefulWidget {
  const MisCuotasScreen({super.key});

  @override
  ConsumerState<MisCuotasScreen> createState() => _MisCuotasScreenState();
}

class _MisCuotasScreenState extends ConsumerState<MisCuotasScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cuotaProvider.notifier).cargarMisCuotas();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cuotaProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mis Cuotas')),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(state.error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () =>
                            ref.read(cuotaProvider.notifier).cargarMisCuotas(),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : state.misCuotas.isEmpty
                  ? const Center(child: Text('No tienes cuotas asignadas.'))
                  : RefreshIndicator(
                      onRefresh: () =>
                          ref.read(cuotaProvider.notifier).cargarMisCuotas(),
                      child: ListView.builder(
                        itemCount: state.misCuotas.length,
                        itemBuilder: (context, index) {
                          final cuota = state.misCuotas[index];
                          return _CuotaUsuarioTile(cuota: cuota);
                        },
                      ),
                    ),
    );
  }
}

class _CuotaUsuarioTile extends StatelessWidget {
  final CuotaUsuarioResponse cuota;

  const _CuotaUsuarioTile({required this.cuota});

  bool _esVencida() {
    if (cuota.estado != EstadoPago.pendiente) return false;
    try {
      final venc = DateTime.parse(cuota.fechaVencimiento);
      return venc.isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  Color _estadoColor(EstadoPago estado) {
    if (estado == EstadoPago.pendiente && _esVencida()) return Colors.red;
    return switch (estado) {
      EstadoPago.pendiente => Colors.grey,
      EstadoPago.reportado => Colors.orange,
      EstadoPago.confirmado => Colors.green,
      EstadoPago.rechazado => Colors.red,
    };
  }

  String _estadoLabel(EstadoPago estado) {
    if (estado == EstadoPago.pendiente && _esVencida()) return 'VENCIDO';
    return switch (estado) {
      EstadoPago.pendiente => 'PENDIENTE',
      EstadoPago.reportado => 'REPORTADO',
      EstadoPago.confirmado => 'CONFIRMADO',
      EstadoPago.rechazado => 'RECHAZADO',
    };
  }

  @override
  Widget build(BuildContext context) {
    final canReport = cuota.estado == EstadoPago.pendiente ||
        cuota.estado == EstadoPago.rechazado;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        title: Text(cuota.concepto,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Monto: \$${cuota.monto.toStringAsFixed(2)}'),
            Text('Vence: ${cuota.fechaVencimiento}'),
            if (cuota.referenciaPago != null)
              Text('Ref: ${cuota.referenciaPago}'),
            if (cuota.notasAdmin != null)
              Text('Admin: ${cuota.notasAdmin}',
                  style: const TextStyle(color: Colors.red)),
          ],
        ),
        trailing: Chip(
          label: Text(_estadoLabel(cuota.estado),
              style: const TextStyle(color: Colors.white, fontSize: 11)),
          backgroundColor: _estadoColor(cuota.estado),
        ),
        onTap: canReport
            ? () => context.push('/home/cuotas/${cuota.id}/reportar')
            : null,
      ),
    );
  }
}
