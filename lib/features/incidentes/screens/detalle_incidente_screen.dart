import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/usuario.dart';
import '../../../shared/providers/auth_provider.dart';
import '../models/add_comentario_request.dart';
import '../models/comentario.dart';
import '../models/incidente.dart';
import '../models/update_estado_request.dart';
import '../providers/incidente_provider.dart';

class DetalleIncidenteScreen extends ConsumerStatefulWidget {
  final int incidenteId;

  const DetalleIncidenteScreen({super.key, required this.incidenteId});

  @override
  ConsumerState<DetalleIncidenteScreen> createState() =>
      _DetalleIncidenteScreenState();
}

class _DetalleIncidenteScreenState
    extends ConsumerState<DetalleIncidenteScreen> {
  List<Comentario> _comentarios = [];
  bool _loadingComentarios = true;
  final _comentarioCtrl = TextEditingController();
  bool _enviando = false;
  EstadoIncidente? _nuevoEstado;

  @override
  void initState() {
    super.initState();
    _cargarComentarios();
  }

  @override
  void dispose() {
    _comentarioCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarComentarios() async {
    setState(() => _loadingComentarios = true);
    try {
      final service = ref.read(incidenteServiceProvider);
      final comentarios =
          await service.listarComentarios(widget.incidenteId);
      setState(() {
        _comentarios = comentarios;
        _loadingComentarios = false;
      });
    } catch (e) {
      setState(() => _loadingComentarios = false);
    }
  }

  Future<void> _enviarComentario() async {
    final texto = _comentarioCtrl.text.trim();
    if (texto.isEmpty) return;
    setState(() => _enviando = true);
    try {
      final service = ref.read(incidenteServiceProvider);
      final nuevo = await service.agregarComentario(
          widget.incidenteId, AddComentarioRequest(comentario: texto));
      setState(() {
        _comentarios = [..._comentarios, nuevo];
        _enviando = false;
      });
      _comentarioCtrl.clear();
    } catch (e) {
      setState(() => _enviando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _actualizarEstado() async {
    if (_nuevoEstado == null) return;
    await ref.read(incidenteProvider.notifier).actualizarEstado(
          widget.incidenteId,
          UpdateEstadoRequest(estado: _nuevoEstado!),
        );
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Estado actualizado')));
      setState(() => _nuevoEstado = null);
    }
  }

  Future<void> _cancelar() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar incidente'),
        content: const Text(
            '¿Estás seguro de que quieres cancelar este incidente?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('No')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await ref
          .read(incidenteProvider.notifier)
          .cancelarIncidente(widget.incidenteId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Incidente cancelado')));
        Navigator.pop(context);
      }
    }
  }

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

  String _estadoLabel(EstadoIncidente e) => switch (e) {
        EstadoIncidente.pendiente => 'PENDIENTE',
        EstadoIncidente.enProceso => 'EN PROCESO',
        EstadoIncidente.resuelto => 'RESUELTO',
        EstadoIncidente.cancelado => 'CANCELADO',
      };

  String _categoriaLabel(CategoriaIncidente c) => switch (c) {
        CategoriaIncidente.mantenimiento => 'Mantenimiento',
        CategoriaIncidente.seguridad => 'Seguridad',
        CategoriaIncidente.ruido => 'Ruido',
        CategoriaIncidente.limpieza => 'Limpieza',
        CategoriaIncidente.otro => 'Otro',
      };

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final state = ref.watch(incidenteProvider);
    final incidente = state.incidentes
        .where((i) => i.id == widget.incidenteId)
        .firstOrNull;

    if (incidente == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Incidente')),
        body: const Center(child: Text('Incidente no encontrado')),
      );
    }

    final esAdmin =
        user?.rol == Rol.admin || user?.rol == Rol.superadmin;
    final esUsuarioDueno = user?.rol == Rol.usuario &&
        user?.id == incidente.usuarioReportaId;
    final puedeComentar = esAdmin || esUsuarioDueno;
    final esCerrado = incidente.estado == EstadoIncidente.resuelto ||
        incidente.estado == EstadoIncidente.cancelado;

    return Scaffold(
      appBar: AppBar(title: Text(incidente.titulo)),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(
                      label: Text(_estadoLabel(incidente.estado),
                          style: const TextStyle(color: Colors.white)),
                      backgroundColor: _estadoColor(incidente.estado),
                    ),
                    Chip(
                      label: Text(
                          incidente.prioridad.name.toUpperCase(),
                          style: const TextStyle(color: Colors.white)),
                      backgroundColor: _prioridadColor(incidente.prioridad),
                    ),
                    Chip(
                        label:
                            Text(_categoriaLabel(incidente.categoria))),
                  ],
                ),
                const SizedBox(height: 12),
                Text(incidente.descripcion),
                const SizedBox(height: 8),
                Text('Ubicación: ${incidente.ubicacion}',
                    style: const TextStyle(color: Colors.grey)),
                Text(
                    'Reportado por: ${incidente.usuarioReportaNombre}',
                    style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 16),

                if (esAdmin && !esCerrado) ...[
                  const Divider(),
                  DropdownButtonFormField<EstadoIncidente>(
                    value: _nuevoEstado,
                    hint: const Text('Cambiar estado a...'),
                    decoration: const InputDecoration(
                        border: OutlineInputBorder()),
                    items: [EstadoIncidente.enProceso, EstadoIncidente.resuelto]
                        .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(_estadoLabel(e)),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _nuevoEstado = v),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: state.isLoading || _nuevoEstado == null
                        ? null
                        : _actualizarEstado,
                    child: const Text('Actualizar estado'),
                  ),
                  const SizedBox(height: 16),
                ],

                if (esUsuarioDueno && !esCerrado) ...[
                  const Divider(),
                  OutlinedButton(
                    onPressed: state.isLoading ? null : _cancelar,
                    style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red)),
                    child: const Text('Cancelar incidente'),
                  ),
                  const SizedBox(height: 16),
                ],

                const Divider(),
                const Text('Comentarios',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                if (_loadingComentarios)
                  const Center(child: CircularProgressIndicator())
                else if (_comentarios.isEmpty)
                  const Text('Sin comentarios aún.',
                      style: TextStyle(color: Colors.grey))
                else
                  ..._comentarios.map((c) => _ComentarioTile(c: c)),
              ],
            ),
          ),

          if (puedeComentar)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border:
                    Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _comentarioCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Agregar comentario...',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      maxLines: 2,
                      minLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _enviando ? null : _enviarComentario,
                    icon: _enviando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2))
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ComentarioTile extends StatelessWidget {
  final Comentario c;

  const _ComentarioTile({required this.c});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            child: Text(c.usuarioNombre[0].toUpperCase()),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.usuarioNombre,
                    style:
                        const TextStyle(fontWeight: FontWeight.bold)),
                Text(c.comentario),
                Text(
                  '${c.createdAt.day}/${c.createdAt.month}/${c.createdAt.year}',
                  style: const TextStyle(
                      fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
