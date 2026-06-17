import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/area_comun.dart';
import '../models/create_area_comun_request.dart';
import '../providers/area_comun_provider.dart';

class CrearEditarAreaScreen extends ConsumerStatefulWidget {
  final AreaComun? area;

  const CrearEditarAreaScreen({super.key, this.area});

  @override
  ConsumerState<CrearEditarAreaScreen> createState() =>
      _CrearEditarAreaScreenState();
}

class _CrearEditarAreaScreenState
    extends ConsumerState<CrearEditarAreaScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _descripcionCtrl;
  late final TextEditingController _capacidadCtrl;
  late final TextEditingController _maxReservasCtrl;
  late final TextEditingController _anticipacionMinCtrl;
  late final TextEditingController _anticipacionMaxCtrl;
  late int _duracionBloque;
  late TimeOfDay _horarioInicio;
  late TimeOfDay _horarioFin;
  late bool _activa;

  bool get _esEdicion => widget.area != null;

  @override
  void initState() {
    super.initState();
    final a = widget.area;
    _nombreCtrl = TextEditingController(text: a?.nombre ?? '');
    _descripcionCtrl = TextEditingController(text: a?.descripcion ?? '');
    _capacidadCtrl =
        TextEditingController(text: a?.capacidad.toString() ?? '');
    _maxReservasCtrl = TextEditingController(
        text: a?.maxReservasMesPorUsuario.toString() ?? '');
    _anticipacionMinCtrl = TextEditingController(
        text: a?.anticipacionMinimaHoras.toString() ?? '');
    _anticipacionMaxCtrl = TextEditingController(
        text: a?.anticipacionMaximaDias.toString() ?? '');
    _duracionBloque = a?.duracionBloqueMinutos ?? 0;
    _activa = a?.activa ?? true;

    if (a != null) {
      final p = a.horarioInicio.split(':');
      _horarioInicio =
          TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
      final pf = a.horarioFin.split(':');
      _horarioFin =
          TimeOfDay(hour: int.parse(pf[0]), minute: int.parse(pf[1]));
    } else {
      _horarioInicio = const TimeOfDay(hour: 8, minute: 0);
      _horarioFin = const TimeOfDay(hour: 22, minute: 0);
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    _capacidadCtrl.dispose();
    _maxReservasCtrl.dispose();
    _anticipacionMinCtrl.dispose();
    _anticipacionMaxCtrl.dispose();
    super.dispose();
  }

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime(bool esInicio) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: esInicio ? _horarioInicio : _horarioFin,
    );
    if (picked != null) setState(() => esInicio ? _horarioInicio = picked : _horarioFin = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final request = CreateAreaComunRequest(
      nombre: _nombreCtrl.text.trim(),
      descripcion: _descripcionCtrl.text.trim().isEmpty
          ? null
          : _descripcionCtrl.text.trim(),
      capacidad: int.parse(_capacidadCtrl.text.trim()),
      horarioInicio: _fmtTime(_horarioInicio),
      horarioFin: _fmtTime(_horarioFin),
      duracionBloqueMinutos: _duracionBloque,
      maxReservasMesPorUsuario: int.parse(_maxReservasCtrl.text.trim()),
      anticipacionMinimaHoras: int.parse(_anticipacionMinCtrl.text.trim()),
      anticipacionMaximaDias: int.parse(_anticipacionMaxCtrl.text.trim()),
      activa: _activa,
    );

    if (_esEdicion) {
      await ref
          .read(areaComunProvider.notifier)
          .editarArea(widget.area!.id, request);
    } else {
      await ref.read(areaComunProvider.notifier).crearArea(request);
    }

    if (mounted) {
      final error = ref.read(areaComunProvider).error;
      if (error == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(_esEdicion
                ? 'Área actualizada exitosamente'
                : 'Área creada exitosamente')));
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: Colors.red));
        ref.read(areaComunProvider.notifier).clearError();
      }
    }
  }

  Widget _numField(TextEditingController ctrl, String label,
      {int min = 1}) =>
      TextFormField(
        controller: ctrl,
        decoration: InputDecoration(
            labelText: min == 0 ? label : '$label *',
            border: const OutlineInputBorder()),
        keyboardType: TextInputType.number,
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Campo requerido';
          final n = int.tryParse(v.trim());
          if (n == null || n < min) return 'Ingresa un número válido (mín. $min)';
          return null;
        },
      );

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(areaComunProvider);
    return Scaffold(
      appBar: AppBar(
          title: Text(_esEdicion ? 'Editar Área' : 'Nueva Área Común')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(
                    labelText: 'Nombre *', border: OutlineInputBorder()),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descripcionCtrl,
                decoration: const InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder()),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              _numField(_capacidadCtrl, 'Capacidad (personas)'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Horario inicio'),
                      subtitle: Text(_fmtTime(_horarioInicio)),
                      trailing: const Icon(Icons.access_time),
                      onTap: () => _pickTime(true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Horario fin'),
                      subtitle: Text(_fmtTime(_horarioFin)),
                      trailing: const Icon(Icons.access_time),
                      onTap: () => _pickTime(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _duracionBloque,
                decoration: const InputDecoration(
                    labelText: 'Duración de bloque',
                    border: OutlineInputBorder(),
                    helperText: 'Sin bloque = reserva todo el horario del día'),
                items: const [
                  DropdownMenuItem(value: 0, child: Text('Todo el día (sin división)')),
                  DropdownMenuItem(value: 30, child: Text('30 minutos')),
                  DropdownMenuItem(value: 60, child: Text('60 minutos')),
                  DropdownMenuItem(value: 90, child: Text('90 minutos')),
                  DropdownMenuItem(value: 120, child: Text('120 minutos')),
                  DropdownMenuItem(value: 180, child: Text('3 horas')),
                  DropdownMenuItem(value: 240, child: Text('4 horas')),
                ],
                onChanged: (v) => setState(() => _duracionBloque = v!),
              ),
              const SizedBox(height: 12),
              _numField(_maxReservasCtrl, 'Máx. reservas/mes por usuario'),
              const SizedBox(height: 12),
              _numField(_anticipacionMinCtrl,
                  'Anticipación mínima (horas) — 0 = sin restricción',
                  min: 0),
              const SizedBox(height: 12),
              _numField(_anticipacionMaxCtrl,
                  'Anticipación máxima (días) — 0 = sin restricción',
                  min: 0),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Área activa'),
                value: _activa,
                onChanged: (v) => setState(() => _activa = v),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: state.isLoading ? null : _submit,
                child: state.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(
                        _esEdicion ? 'Guardar Cambios' : 'Crear Área'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
