import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/models/usuario.dart';
import '../../../shared/providers/auth_provider.dart';
import '../models/area_comun.dart';
import '../models/reservacion.dart';
import '../providers/area_comun_provider.dart';
import '../providers/reservacion_provider.dart';

class AreasScreen extends ConsumerStatefulWidget {
  const AreasScreen({super.key});

  @override
  ConsumerState<AreasScreen> createState() => _AreasScreenState();
}

class _AreasScreenState extends ConsumerState<AreasScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  void _cargar() {
    final user = ref.read(authProvider).user;
    ref.read(areaComunProvider.notifier).cargarAreas();
    if (user?.rol == Rol.usuario) {
      ref.read(reservacionProvider.notifier).cargarMisReservaciones();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final esAdmin = user?.rol == Rol.admin || user?.rol == Rol.superadmin;
    if (esAdmin) return _buildAdminView(context);
    return _buildUsuarioView(context);
  }

  Widget _buildAdminView(BuildContext context) {
    final state = ref.watch(areaComunProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Áreas Comunes')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/home/areas/nueva');
          ref.read(areaComunProvider.notifier).cargarAreas();
        },
        child: const Icon(Icons.add),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.areas.isEmpty
              ? const Center(child: Text('No hay áreas registradas.'))
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(areaComunProvider.notifier).cargarAreas(),
                  child: ListView.builder(
                    itemCount: state.areas.length,
                    itemBuilder: (context, index) {
                      final area = state.areas[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        child: ListTile(
                          title: Text(area.nombre,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          subtitle: Text(
                              '${area.horarioInicio} – ${area.horarioFin} · ${area.duracionBloqueMinutos} min'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Switch(
                                value: area.activa,
                                onChanged: (_) => ref
                                    .read(areaComunProvider.notifier)
                                    .toggleActiva(area.id),
                              ),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                          onTap: () async {
                            await context
                                .push('/home/areas/${area.id}/editar');
                            ref
                                .read(areaComunProvider.notifier)
                                .cargarAreas();
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildUsuarioView(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Áreas'),
          bottom: const TabBar(tabs: [
            Tab(text: 'Áreas Disponibles'),
            Tab(text: 'Mis Reservas'),
          ]),
        ),
        body: const TabBarView(
          children: [_AreasList(), _MisReservacionesList()],
        ),
      ),
    );
  }
}

class _AreasList extends ConsumerWidget {
  const _AreasList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(areaComunProvider);
    if (state.isLoading) return const Center(child: CircularProgressIndicator());
    if (state.areas.isEmpty) {
      return const Center(child: Text('No hay áreas disponibles.'));
    }
    return RefreshIndicator(
      onRefresh: () => ref.read(areaComunProvider.notifier).cargarAreas(),
      child: ListView.builder(
        itemCount: state.areas.length,
        itemBuilder: (context, index) {
          final area = state.areas[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: ListTile(
              leading: const Icon(Icons.meeting_room_outlined, size: 36),
              title: Text(area.nombre,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${area.horarioInicio} – ${area.horarioFin}'),
                  Text('Bloques de ${area.duracionBloqueMinutos} min · Cap. ${area.capacidad}'),
                ],
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context
                  .push('/home/areas/${area.id}/disponibilidad'),
            ),
          );
        },
      ),
    );
  }
}

class _MisReservacionesList extends ConsumerWidget {
  const _MisReservacionesList();

  String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reservacionProvider);
    if (state.isLoading) return const Center(child: CircularProgressIndicator());
    if (state.misReservaciones.isEmpty) {
      return const Center(child: Text('No tienes reservaciones.'));
    }
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(reservacionProvider.notifier).cargarMisReservaciones(),
      child: ListView.builder(
        itemCount: state.misReservaciones.length,
        itemBuilder: (context, index) {
          final r = state.misReservaciones[index];
          final esActiva = r.estado == EstadoReservacion.activa;
          final esFutura = r.fechaHoraInicio.isAfter(DateTime.now());
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: ListTile(
              title: Text(r.areaComunNombre,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                  '${_fmt(r.fechaHoraInicio)} – ${_fmt(r.fechaHoraFin)}'),
              trailing: esActiva && esFutura
                  ? TextButton(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Cancelar reservación'),
                            content:
                                const Text('¿Cancelar esta reservación?'),
                            actions: [
                              TextButton(
                                  onPressed: () =>
                                      Navigator.pop(ctx, false),
                                  child: const Text('No')),
                              ElevatedButton(
                                onPressed: () =>
                                    Navigator.pop(ctx, true),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red),
                                child: const Text('Sí'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await ref
                              .read(reservacionProvider.notifier)
                              .cancelarReservacion(r.id);
                        }
                      },
                      style:
                          TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Cancelar'),
                    )
                  : Chip(
                      label: Text(esActiva ? 'ACTIVA' : 'CANCELADA',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11)),
                      backgroundColor:
                          esActiva ? Colors.green : Colors.grey,
                    ),
            ),
          );
        },
      ),
    );
  }
}
