import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/create_visita_request.dart';
import '../providers/visita_provider.dart';

class CrearVisitaScreen extends ConsumerStatefulWidget {
  const CrearVisitaScreen({super.key});

  @override
  ConsumerState<CrearVisitaScreen> createState() => _CrearVisitaScreenState();
}

class _CrearVisitaScreenState extends ConsumerState<CrearVisitaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _motivoController = TextEditingController();
  final _placasController = TextEditingController();
  DateTime? _selectedDateTime;

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _motivoController.dispose();
    _placasController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final minDate = now.add(const Duration(minutes: 30));

    final date = await showDatePicker(
      context: context,
      initialDate: minDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(minDate),
    );
    if (time == null || !mounted) return;

    setState(() {
      _selectedDateTime = DateTime(
        date.year, date.month, date.day,
        time.hour, time.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona la fecha y hora de la visita')),
      );
      return;
    }

    final request = CreateVisitaRequest(
      nombreVisitante: _nombreController.text.trim(),
      telefonoVisitante: _telefonoController.text.trim().isEmpty
          ? null
          : _telefonoController.text.trim(),
      fechaHoraProgramada: _selectedDateTime!,
      motivo: _motivoController.text.trim().isEmpty
          ? null
          : _motivoController.text.trim(),
      vehiculoPlacas: _placasController.text.trim().isEmpty
          ? null
          : _placasController.text.trim(),
    );

    final visita = await ref.read(visitaProvider.notifier).crearVisita(request);

    if (!mounted) return;

    if (visita != null) {
      _formKey.currentState!.reset();
      _nombreController.clear();
      _telefonoController.clear();
      _motivoController.clear();
      _placasController.clear();
      setState(() => _selectedDateTime = null);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Visita creada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      final error = ref.read(visitaProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Error al crear la visita'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(visitaProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Nueva Visita')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del visitante *',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                textInputAction: TextInputAction.next,
                enabled: !isLoading,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telefonoController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono del visitante',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                enabled: !isLoading,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: isLoading ? null : _pickDateTime,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Fecha y hora de visita *',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _selectedDateTime != null
                        ? _formatDateTime(_selectedDateTime!)
                        : 'Seleccionar fecha y hora',
                    style: TextStyle(
                      color: _selectedDateTime != null
                          ? null
                          : Theme.of(context).hintColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _motivoController,
                decoration: const InputDecoration(
                  labelText: 'Motivo de la visita',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 2,
                textInputAction: TextInputAction.next,
                enabled: !isLoading,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _placasController,
                decoration: const InputDecoration(
                  labelText: 'Placas del vehículo',
                  prefixIcon: Icon(Icons.directions_car),
                ),
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                enabled: !isLoading,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Crear Visita', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
