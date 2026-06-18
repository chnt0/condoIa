import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/models/usuario.dart';
import '../../../shared/providers/auth_provider.dart';
import '../models/paquete.dart';
import '../providers/paquete_provider.dart';

class PaquetesScreen extends ConsumerStatefulWidget {
  const PaquetesScreen({super.key});

  @override
  ConsumerState<PaquetesScreen> createState() => _PaquetesScreenState();
}

class _PaquetesScreenState extends ConsumerState<PaquetesScreen> {
  String _filtroUnidad = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  void _cargar() {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    if (user.rol == Rol.usuario) {
      ref.read(paqueteProvider.notifier).cargarMisPaquetes();
    } else {
      ref.read(paqueteProvider.notifier).cargarPaquetes();
    }
  }

  List<Paquete> _filtrar(List<Paquete> lista) {
    if (_filtroUnidad.trim().isEmpty) return lista;
    final q = _filtroUnidad.toLowerCase();
    return lista
        .where((p) =>
            (p.destinatarioUnidad ?? '').toLowerCase().contains(q) ||
            p.destinatarioNombre.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final state = ref.watch(paqueteProvider);
    final esGuardia = user?.rol == Rol.guardia;
    final esUsuario = user?.rol == Rol.usuario;

    final pendientes = _filtrar(state.paquetes
        .where((p) => p.estado == EstadoPaquete.pendiente)
        .toList());
    final entregados = _filtrar(state.paquetes
        .where((p) => p.estado == EstadoPaquete.entregado)
        .toList());

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Paquetes'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Pendientes'),
              Tab(text: 'Entregados'),
            ],
          ),
        ),
        floatingActionButton: esGuardia
            ? FloatingActionButton(
                onPressed: () async {
                  await context.push('/home/paquetes/nuevo');
                  _cargar();
                },
                child: const Icon(Icons.add),
              )
            : null,
        body: Column(
          children: [
            // Filtro por unidad — solo para GUARDIA y ADMIN
            if (!esUsuario)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Filtrar por unidad o nombre',
                    prefixIcon: Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                  onChanged: (v) => setState(() => _filtroUnidad = v),
                ),
              ),
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state.error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(state.error!,
                                  style:
                                      const TextStyle(color: Colors.red)),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                  onPressed: _cargar,
                                  child: const Text('Reintentar')),
                            ],
                          ),
                        )
                      : TabBarView(
                          children: [
                            _PaqueteList(
                              paquetes: pendientes,
                              esGuardia: esGuardia,
                              onRefresh: _cargar,
                            ),
                            _PaqueteList(
                              paquetes: entregados,
                              esGuardia: false,
                              onRefresh: _cargar,
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaqueteList extends ConsumerWidget {
  final List<Paquete> paquetes;
  final bool esGuardia;
  final VoidCallback onRefresh;

  const _PaqueteList({
    required this.paquetes,
    required this.esGuardia,
    required this.onRefresh,
  });

  String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (paquetes.isEmpty) {
      return const Center(child: Text('No hay paquetes en esta sección.'));
    }
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        itemCount: paquetes.length,
        itemBuilder: (context, index) {
          final p = paquetes[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: ListTile(
              leading: Icon(
                Icons.inventory_2_outlined,
                color: p.estado == EstadoPaquete.pendiente
                    ? Colors.orange
                    : Colors.green,
                size: 32,
              ),
              title: Text(p.descripcion,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${p.destinatarioNombre}'
                    '${p.destinatarioUnidad != null ? " · ${p.destinatarioUnidad}" : ""}',
                  ),
                  Text('Llegó: ${_fmt(p.fechaHoraLlegada)}',
                      style: const TextStyle(fontSize: 12)),
                  if (p.fechaHoraEntrega != null)
                    Text('Entregado: ${_fmt(p.fechaHoraEntrega!)}',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.green)),
                ],
              ),
              trailing: esGuardia && p.estado == EstadoPaquete.pendiente
                  ? ElevatedButton(
                      onPressed: () async {
                        await ref
                            .read(paqueteProvider.notifier)
                            .entregarPaquete(p.id);
                        onRefresh();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: const Text('Entregar',
                          style: TextStyle(fontSize: 12)),
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }
}
