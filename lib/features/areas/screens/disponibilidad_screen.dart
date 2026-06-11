import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/area_comun.dart';
import '../models/bloque_disponibilidad.dart';
import '../models/create_reservacion_request.dart';
import '../providers/area_comun_provider.dart';
import '../providers/reservacion_provider.dart';

class DisponibilidadScreen extends ConsumerStatefulWidget {
  final int areaComunId;

  const DisponibilidadScreen({super.key, required this.areaComunId});

  @override
  ConsumerState<DisponibilidadScreen> createState() =>
      _DisponibilidadScreenState();
}

class _DisponibilidadScreenState extends ConsumerState<DisponibilidadScreen> {
  DateTime _fechaSeleccionada = DateTime.now().add(const Duration(days: 1));
  List<BloqueDisponibilidad> _bloques = [];
  bool _loadingBloques = false;
  AreaComun? _area;

  @override
  void initState() {
    super.initState();
    final state = ref.read(areaComunProvider);
    _area =
        state.areas.where((a) => a.id == widget.areaComunId).firstOrNull;
    _cargarBloques();
  }

  Future<void> _cargarBloques() async {
    setState(() => _loadingBloques = true);
    try {
      final service = ref.read(areaComunServiceProvider);
      final fechaStr =
          '${_fechaSeleccionada.year}-${_fechaSeleccionada.month.toString().padLeft(2, '0')}-${_fechaSeleccionada.day.toString().padLeft(2, '0')}';
      final bloques =
          await service.obtenerDisponibilidad(widget.areaComunId, fechaStr);
      setState(() {
        _bloques = bloques;
        _loadingBloques = false;
      });
    } catch (e) {
      setState(() => _loadingBloques = false);
    }
  }

  Future<void> _seleccionarFecha() async {
    final ahora = DateTime.now();
    final maxDias = _area?.anticipacionMaximaDias ?? 30;
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: ahora,
      lastDate: ahora.add(Duration(days: maxDias)),
    );
    if (picked != null) {
      setState(() => _fechaSeleccionada = picked);
      _cargarBloques();
    }
  }

  Future<void> _confirmarReservacion(BloqueDisponibilidad bloque) async {
    final h = (t) =>
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar reservación'),
        content: Text(
          '${_area?.nombre ?? "Área"}\n'
          '${bloque.fechaHoraInicio.day}/${bloque.fechaHoraInicio.month}/${bloque.fechaHoraInicio.year}\n'
          '${h(bloque.fechaHoraInicio)} – ${h(bloque.fechaHoraFin)}',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirmar')),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final reservacion = await ref
          .read(reservacionProvider.notifier)
          .crearReservacion(CreateReservacionRequest(
            areaComunId: widget.areaComunId,
            fechaHoraInicio: bloque.fechaHoraInicio,
          ));
      if (mounted) {
        if (reservacion != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reservación creada exitosamente')),
          );
          _cargarBloques();
        } else {
          final error = ref.read(reservacionProvider).error;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(error ?? 'Error al crear reservación'),
                backgroundColor: Colors.red),
          );
          ref.read(reservacionProvider.notifier).clearError();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final area = _area;
    return Scaffold(
      appBar: AppBar(title: Text(area?.nombre ?? 'Disponibilidad')),
      body: Column(
        children: [
          if (area != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (area.descripcion != null)
                    Text(area.descripcion!,
                        style: const TextStyle(color: Colors.grey)),
                  Text(
                      'Horario: ${area.horarioInicio} – ${area.horarioFin} · Bloques de ${area.duracionBloqueMinutos} min'),
                ],
              ),
            ),
          ListTile(
            title: Text(
              'Fecha: ${_fechaSeleccionada.day.toString().padLeft(2, '0')}/${_fechaSeleccionada.month.toString().padLeft(2, '0')}/${_fechaSeleccionada.year}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: const Icon(Icons.calendar_today),
            onTap: _seleccionarFecha,
          ),
          const Divider(),
          Expanded(
            child: _loadingBloques
                ? const Center(child: CircularProgressIndicator())
                : _bloques.isEmpty
                    ? const Center(
                        child: Text(
                            'No hay bloques disponibles para esta fecha.'))
                    : Padding(
                        padding: const EdgeInsets.all(16),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _bloques.map((bloque) {
                            final label =
                                '${bloque.fechaHoraInicio.hour.toString().padLeft(2, '0')}:${bloque.fechaHoraInicio.minute.toString().padLeft(2, '0')}';
                            return ElevatedButton(
                              onPressed: bloque.disponible
                                  ? () => _confirmarReservacion(bloque)
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: bloque.disponible
                                    ? Colors.green
                                    : Colors.grey.shade300,
                                foregroundColor: bloque.disponible
                                    ? Colors.white
                                    : Colors.grey,
                              ),
                              child: Text(label),
                            );
                          }).toList(),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
