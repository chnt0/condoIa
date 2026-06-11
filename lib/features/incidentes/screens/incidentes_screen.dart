import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/models/usuario.dart';
import '../../../shared/providers/auth_provider.dart';
import '../models/incidente.dart';
import '../providers/incidente_provider.dart';

class IncidentesScreen extends ConsumerStatefulWidget {
  const IncidentesScreen({super.key});

  @override
  ConsumerState<IncidentesScreen> createState() => _IncidentesScreenState();
}

class _IncidentesScreenState extends ConsumerState<IncidentesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  void _cargar() {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    if (user.rol == Rol.usuario) {
      ref.read(incidenteProvider.notifier).cargarMisIncidentes();
    } else {
      ref.read(incidenteProvider.notifier).cargarIncidentes();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final state = ref.watch(incidenteProvider);
    final esUsuario = user?.rol == Rol.usuario;

    final pendientes = state.incidentes
        .where((i) => i.estado == EstadoIncidente.pendiente)
        .toList();
    final enProceso = state.incidentes
        .where((i) => i.estado == EstadoIncidente.enProceso)
        .toList();
    final resueltos = state.incidentes
        .where((i) => i.estado == EstadoIncidente.resuelto)
        .toList();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Incidentes'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Pendiente'),
              Tab(text: 'En Proceso'),
              Tab(text: 'Resuelto'),
            ],
          ),
        ),
        floatingActionButton: esUsuario
            ? FloatingActionButton(
                onPressed: () async {
                  await context.push('/home/incidentes/nuevo');
                  _cargar();
                },
                child: const Icon(Icons.add),
              )
            : null,
        body: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : state.error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(state.error!,
                            style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                            onPressed: _cargar,
                            child: const Text('Reintentar')),
                      ],
                    ),
                  )
                : TabBarView(
                    children: [
                      _IncidenteList(
                          incidentes: pendientes, onRefresh: _cargar),
                      _IncidenteList(
                          incidentes: enProceso, onRefresh: _cargar),
                      _IncidenteList(
                          incidentes: resueltos, onRefresh: _cargar),
                    ],
                  ),
      ),
    );
  }
}

class _IncidenteList extends StatelessWidget {
  final List<Incidente> incidentes;
  final VoidCallback onRefresh;

  const _IncidenteList({required this.incidentes, required this.onRefresh});

  Color _prioridadColor(PrioridadIncidente p) => switch (p) {
        PrioridadIncidente.alta => Colors.red,
        PrioridadIncidente.media => Colors.orange,
        PrioridadIncidente.baja => Colors.grey,
      };

  Color _estadoColor(EstadoIncidente e) => switch (e) {
        EstadoIncidente.pendiente => Colors.orange,
        EstadoIncidente.enProceso => Colors.blue,
        EstadoIncidente.resuelto => Colors.green,
        EstadoIncidente.cancelado => Colors.grey,
      };

  String _categoriaLabel(CategoriaIncidente c) => switch (c) {
        CategoriaIncidente.mantenimiento => 'Mantenimiento',
        CategoriaIncidente.seguridad => 'Seguridad',
        CategoriaIncidente.ruido => 'Ruido',
        CategoriaIncidente.limpieza => 'Limpieza',
        CategoriaIncidente.otro => 'Otro',
      };

  String _estadoLabel(EstadoIncidente e) => switch (e) {
        EstadoIncidente.pendiente => 'PENDIENTE',
        EstadoIncidente.enProceso => 'EN PROCESO',
        EstadoIncidente.resuelto => 'RESUELTO',
        EstadoIncidente.cancelado => 'CANCELADO',
      };

  @override
  Widget build(BuildContext context) {
    if (incidentes.isEmpty) {
      return const Center(child: Text('No hay incidentes en esta sección.'));
    }
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        itemCount: incidentes.length,
        itemBuilder: (context, index) {
          final i = incidentes[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _prioridadColor(i.prioridad),
                child: Text(
                  i.prioridad.name[0].toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(i.titulo,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_categoriaLabel(i.categoria)),
                  Text(i.ubicacion,
                      style: const TextStyle(fontSize: 12)),
                ],
              ),
              trailing: Chip(
                label: Text(
                  _estadoLabel(i.estado),
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
                backgroundColor: _estadoColor(i.estado),
              ),
              onTap: () async {
                await context.push('/home/incidentes/${i.id}');
                onRefresh();
              },
            ),
          );
        },
      ),
    );
  }
}
