import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/create_incidente_request.dart';
import '../models/incidente.dart';
import '../providers/incidente_provider.dart';
import '../providers/categoria_provider.dart';

class CrearIncidenteScreen extends ConsumerStatefulWidget {
  const CrearIncidenteScreen({super.key});

  @override
  ConsumerState<CrearIncidenteScreen> createState() =>
      _CrearIncidenteScreenState();
}

class _CrearIncidenteScreenState extends ConsumerState<CrearIncidenteScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _categoriaSeleccionada;
  PrioridadIncidente _prioridad = PrioridadIncidente.media;
  final _tituloCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _ubicacionCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(categoriaProvider.notifier).cargarCategorias();
    });
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descripcionCtrl.dispose();
    _ubicacionCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoriaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una categoría')),
      );
      return;
    }
    final request = CreateIncidenteRequest(
      categoria: _categoriaSeleccionada!,
      titulo: _tituloCtrl.text.trim(),
      descripcion: _descripcionCtrl.text.trim(),
      ubicacion: _ubicacionCtrl.text.trim(),
      prioridad: _prioridad,
    );
    final incidente =
        await ref.read(incidenteProvider.notifier).crearIncidente(request);
    if (mounted) {
      if (incidente != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incidente reportado exitosamente')),
        );
        context.pop();
      } else {
        final error = ref.read(incidenteProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(error ?? 'Error al reportar incidente'),
              backgroundColor: Colors.red),
        );
        ref.read(incidenteProvider.notifier).clearError();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(incidenteProvider);
    final catState = ref.watch(categoriaProvider);
    final categorias =
        catState.categorias.where((c) => c.activa).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Reportar Incidente')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Categoría dinámica
              catState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<String>(
                      value: _categoriaSeleccionada,
                      decoration: const InputDecoration(
                        labelText: 'Categoría *',
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('Selecciona una categoría'),
                      items: categorias
                          .map((c) => DropdownMenuItem(
                                value: c.nombre,
                                child: Text(c.nombre),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _categoriaSeleccionada = v),
                      validator: (v) =>
                          v == null ? 'Selecciona una categoría' : null,
                    ),
              const SizedBox(height: 16),
              DropdownButtonFormField<PrioridadIncidente>(
                value: _prioridad,
                decoration: const InputDecoration(
                  labelText: 'Prioridad',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                      value: PrioridadIncidente.baja, child: Text('Baja')),
                  DropdownMenuItem(
                      value: PrioridadIncidente.media, child: Text('Media')),
                  DropdownMenuItem(
                      value: PrioridadIncidente.alta, child: Text('Alta')),
                ],
                onChanged: (v) => setState(() => _prioridad = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tituloCtrl,
                decoration: const InputDecoration(
                  labelText: 'Título *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descripcionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Descripción *',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ubicacionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Ubicación *',
                  hintText: 'Ej: Área de alberca, Torre A piso 3',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: state.isLoading ? null : _submit,
                child: state.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Reportar Incidente'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
