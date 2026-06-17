import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/api_constants.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../paquetes/models/residente_basico.dart';
import '../../paquetes/services/paquete_service.dart';

class RegistrarVisitaDirectaScreen extends ConsumerStatefulWidget {
  const RegistrarVisitaDirectaScreen({super.key});

  @override
  ConsumerState<RegistrarVisitaDirectaScreen> createState() =>
      _RegistrarVisitaDirectaScreenState();
}

class _RegistrarVisitaDirectaScreenState
    extends ConsumerState<RegistrarVisitaDirectaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _motivoCtrl = TextEditingController();
  final _placasCtrl = TextEditingController();
  final _busquedaCtrl = TextEditingController();

  ResidenteBasico? _destinatario;
  List<ResidenteBasico> _residentes = [];
  String _filtro = '';
  Uint8List? _fotoBytes;
  String? _fotoBase64;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _cargarResidentes();
    _busquedaCtrl.addListener(
        () => setState(() => _filtro = _busquedaCtrl.text.toLowerCase()));
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    _motivoCtrl.dispose();
    _placasCtrl.dispose();
    _busquedaCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarResidentes() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final service = PaqueteService(apiClient: apiClient);
      final residentes = await service.listarResidentes();
      setState(() => _residentes = residentes);
    } catch (_) {}
  }

  Future<void> _tomarFoto() async {
    final fuente = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Elegir de galería'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (fuente == null) return;

    final imagen = await ImagePicker()
        .pickImage(source: fuente, imageQuality: 70, maxWidth: 1200);
    if (imagen == null) return;

    final bytes = await imagen.readAsBytes();
    setState(() {
      _fotoBytes = bytes;
      _fotoBase64 = base64Encode(bytes);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_destinatario == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona el residente destinatario')),
      );
      return;
    }
    setState(() => _enviando = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.post(ApiConstants.visitaDirecta, {
        'nombreVisitante': _nombreCtrl.text.trim(),
        'telefonoVisitante': _telefonoCtrl.text.trim().isEmpty
            ? null
            : _telefonoCtrl.text.trim(),
        'motivo': _motivoCtrl.text.trim(),
        'vehiculoPlacas': _placasCtrl.text.trim().isEmpty
            ? null
            : _placasCtrl.text.trim(),
        'fotoVehiculo': _fotoBase64,
        'usuarioDestinatarioId': _destinatario!.id,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Visita registrada exitosamente'),
              backgroundColor: Colors.green),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final residentes = _residentes.where((r) {
      if (_filtro.isEmpty) return true;
      return (r.unidadHabitacional ?? '').toLowerCase().contains(_filtro) ||
          r.nombreCompleto.toLowerCase().contains(_filtro);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Visita Directa')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Datos del visitante
              const Text('Datos del visitante',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(
                    labelText: 'Nombre del visitante *',
                    border: OutlineInputBorder()),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _telefonoCtrl,
                decoration: const InputDecoration(
                    labelText: 'Teléfono (opcional)',
                    border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _motivoCtrl,
                decoration: const InputDecoration(
                    labelText: 'Motivo *',
                    hintText: 'Ej: Delivery, Visita familiar, Servicio técnico',
                    border: OutlineInputBorder()),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _placasCtrl,
                decoration: const InputDecoration(
                    labelText: 'Placas del vehículo (opcional)',
                    border: OutlineInputBorder()),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 12),

              // Foto del vehículo
              const Text('Foto de vehículo/placas',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              if (_fotoBytes != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(_fotoBytes!,
                      height: 160, fit: BoxFit.cover),
                ),
                const SizedBox(height: 4),
                TextButton.icon(
                  onPressed: () =>
                      setState(() {
                        _fotoBytes = null;
                        _fotoBase64 = null;
                      }),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text('Eliminar foto',
                      style: TextStyle(color: Colors.red)),
                ),
              ] else
                OutlinedButton.icon(
                  onPressed: _tomarFoto,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Fotografiar vehículo/placas (opcional)'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 0),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),

              const SizedBox(height: 20),
              const Divider(),

              // Residente destinatario
              const Text('Residente que recibe la visita *',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              if (_destinatario != null)
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
                          '${_destinatario!.unidadHabitacional ?? ""} — ${_destinatario!.nombreCompleto}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () =>
                            setState(() => _destinatario = null),
                      ),
                    ],
                  ),
                ),
              TextField(
                controller: _busquedaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Buscar por unidad o nombre',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 220,
                child: residentes.isEmpty
                    ? const Center(child: Text('No se encontraron residentes'))
                    : ListView.builder(
                        itemCount: residentes.length,
                        itemBuilder: (context, index) {
                          final r = residentes[index];
                          final selected = _destinatario?.id == r.id;
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.home_outlined),
                            title:
                                Text(r.unidadHabitacional ?? 'Sin unidad'),
                            subtitle: Text(r.nombreCompleto),
                            selected: selected,
                            selectedTileColor: Theme.of(context)
                                .colorScheme
                                .primaryContainer
                                .withOpacity(0.3),
                            onTap: () =>
                                setState(() => _destinatario = r),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _enviando ? null : _submit,
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _enviando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Registrar Entrada',
                        style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
