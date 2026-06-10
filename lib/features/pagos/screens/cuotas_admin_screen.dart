import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/cuota_response.dart';
import '../providers/cuota_provider.dart';

class CuotasAdminScreen extends ConsumerStatefulWidget {
  const CuotasAdminScreen({super.key});

  @override
  ConsumerState<CuotasAdminScreen> createState() => _CuotasAdminScreenState();
}

class _CuotasAdminScreenState extends ConsumerState<CuotasAdminScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cuotaProvider.notifier).cargarCuotas();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cuotaProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Cuotas')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/home/cuotas/nueva'),
        child: const Icon(Icons.add),
      ),
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
                            ref.read(cuotaProvider.notifier).cargarCuotas(),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : state.cuotas.isEmpty
                  ? const Center(child: Text('No hay cuotas registradas.'))
                  : RefreshIndicator(
                      onRefresh: () =>
                          ref.read(cuotaProvider.notifier).cargarCuotas(),
                      child: ListView.builder(
                        itemCount: state.cuotas.length,
                        itemBuilder: (context, index) {
                          final cuota = state.cuotas[index];
                          return _CuotaTile(cuota: cuota);
                        },
                      ),
                    ),
    );
  }
}

class _CuotaTile extends StatelessWidget {
  final CuotaResponse cuota;

  const _CuotaTile({required this.cuota});

  @override
  Widget build(BuildContext context) {
    final confirmados = cuota.totalConfirmados;
    final total = cuota.totalResidentes;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        title: Text(cuota.concepto,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${cuota.tipo == TipoCuota.mensual ? "Mensual" : "Extraordinaria"}'
              '${cuota.mes != null ? " · ${cuota.mes}" : ""}',
            ),
            Text('Monto: \$${cuota.monto.toStringAsFixed(2)}'),
            Text('Vence: ${cuota.fechaVencimiento}'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$confirmados/$total',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            const Text('confirm.', style: TextStyle(fontSize: 11)),
          ],
        ),
        onTap: () => context.push('/home/cuotas/${cuota.id}/detalle'),
      ),
    );
  }
}
