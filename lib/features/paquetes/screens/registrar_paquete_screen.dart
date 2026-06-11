import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/create_paquete_request.dart';
import '../models/residente_basico.dart';
import '../providers/paquete_provider.dart';

class RegistrarPaqueteScreen extends ConsumerStatefulWidget {
  const RegistrarPaqueteScreen({super.key});

  @override
  ConsumerState<RegistrarPaqueteScreen> createState() =>
      _RegistrarPaqueteScreenState();
}

class _RegistrarPaqueteScreenState
    extends ConsumerState<RegistrarPaqueteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descripcionCtrl = TextEditingController();
  final _notasCtrl = TextEditingController();
  final _busquedaCtrl = TextEditingController();
  ResidenteBasico? _selectedResidente;
  String _filtro = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(paqueteProvider.notifier).cargarResidentes();
    });
    _busquedaCtrl.addListener(() {
      setState(() => _filtro = _busquedaCtrl.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _descripcionCtrl.dispose();
    _notasCtrl.dispose();
    _busquedaCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedResidente == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un residente destinatario')),
      );
      return;
    }
    final request = CreatePaqueteRequest(
      usuarioDestinatarioId: _selectedResidente!.id,
      descripcion: _descripcionCtrl.text.trim(),
      notas: _notasCtrl.text.trim().isEmpty ? null : _notasCtrl.text.trim(),
    );
    final paquete =
        await ref.read(paqueteProvider.notifier).registrarPaquete(request);
    if (mounted) {
      if (paquete != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paquete registrado exitosamente')),
        );
        context.pop();
      } else {
        final error = ref.read(paqueteProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(error ?? 'Error al registrar paquete'),
              backgroundColor: Colors.red),
        );
        ref.read(paqueteProvider.notifier).clearError();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paqueteProvider);
    final residentes = state.residentes.where((r) {
      if (_filtro.isEmpty) return true;
      return (r.unidadHabitacional ?? '').toLowerCase().contains(_filtro) ||
          r.nombreCompleto.toLowerCase().contains(_filtro);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Paquete')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _descripcionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Descripción del paquete *',
                  hintText: 'Ej: Caja mediana Amazon',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notasCtrl,
                decoration: const InputDecoration(
                  labelText: 'Notas (opcional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              const Text('Destinatario *',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              TextField(
                controller: _busquedaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Buscar por unidad o nombre',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              if (_selectedResidente != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${_selectedResidente!.unidadHabitacional ?? ""} — ${_selectedResidente!.nombreCompleto}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () =>
                            setState(() => _selectedResidente = null),
                      ),
                    ],
                  ),
                ),
              SizedBox(
                height: 250,
                child: residentes.isEmpty
                    ? const Center(child: Text('No se encontraron residentes'))
                    : ListView.builder(
                        itemCount: residentes.length,
                        itemBuilder: (context, index) {
                          final r = residentes[index];
                          final selected = _selectedResidente?.id == r.id;
                          return ListTile(
                            leading: const Icon(Icons.home_outlined),
                            title: Text(r.unidadHabitacional ?? 'Sin unidad'),
                            subtitle: Text(r.nombreCompleto),
                            selected: selected,
                            selectedTileColor: Theme.of(context)
                                .colorScheme
                                .primaryContainer
                                .withOpacity(0.3),
                            onTap: () =>
                                setState(() => _selectedResidente = r),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: state.isLoading ? null : _submit,
                child: state.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Registrar Paquete'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
