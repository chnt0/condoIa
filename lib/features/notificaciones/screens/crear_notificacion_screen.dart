import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/create_notificacion_request.dart';
import '../models/notificacion.dart';
import '../providers/notificacion_provider.dart';

class CrearNotificacionScreen extends ConsumerStatefulWidget {
  const CrearNotificacionScreen({super.key});

  @override
  ConsumerState<CrearNotificacionScreen> createState() =>
      _CrearNotificacionScreenState();
}

class _CrearNotificacionScreenState
    extends ConsumerState<CrearNotificacionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _mensajeCtrl = TextEditingController();
  final _edificioCtrl = TextEditingController();
  SegmentoNotificacion _segmento = SegmentoNotificacion.todos;

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _mensajeCtrl.dispose();
    _edificioCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final request = CreateNotificacionRequest(
      titulo: _tituloCtrl.text.trim(),
      mensaje: _mensajeCtrl.text.trim(),
      segmento: _segmento,
      edificio: _segmento == SegmentoNotificacion.edificioX
          ? _edificioCtrl.text.trim()
          : null,
    );

    final notificacion = await ref
        .read(notificacionProvider.notifier)
        .crearNotificacion(request);

    if (mounted) {
      if (notificacion != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aviso publicado exitosamente')),
        );
        context.pop();
      } else {
        final error = ref.read(notificacionProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(error ?? 'Error al publicar aviso'),
              backgroundColor: Colors.red),
        );
        ref.read(notificacionProvider.notifier).clearError();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificacionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo Aviso')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
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
                controller: _mensajeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Mensaje *',
                  border: OutlineInputBorder(),
                ),
                maxLines: 6,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<SegmentoNotificacion>(
                value: _segmento,
                decoration: const InputDecoration(
                  labelText: 'Destinatarios',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: SegmentoNotificacion.todos,
                    child: Text('Todos los residentes'),
                  ),
                  DropdownMenuItem(
                    value: SegmentoNotificacion.edificioX,
                    child: Text('Por edificio'),
                  ),
                ],
                onChanged: (v) => setState(() => _segmento = v!),
              ),
              if (_segmento == SegmentoNotificacion.edificioX) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _edificioCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Edificio *',
                    hintText: 'Ej: Torre A',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (_segmento != SegmentoNotificacion.edificioX) return null;
                    return v == null || v.trim().isEmpty
                        ? 'Campo requerido'
                        : null;
                  },
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: state.isLoading ? null : _submit,
                child: state.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Publicar Aviso'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
