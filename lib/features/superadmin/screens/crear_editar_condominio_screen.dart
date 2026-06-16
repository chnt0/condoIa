import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/condominio_sa.dart';
import '../models/create_condominio_request.dart';
import '../providers/condominio_sa_provider.dart';

class CrearEditarCondominioScreen extends ConsumerStatefulWidget {
  final CondominiSa? condominio;

  const CrearEditarCondominioScreen({super.key, this.condominio});

  @override
  ConsumerState<CrearEditarCondominioScreen> createState() =>
      _CrearEditarCondominioScreenState();
}

class _CrearEditarCondominioScreenState
    extends ConsumerState<CrearEditarCondominioScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _direccionCtrl;
  late final TextEditingController _unidadesCtrl;
  late bool _activo;

  bool get _esEdicion => widget.condominio != null;

  @override
  void initState() {
    super.initState();
    final c = widget.condominio;
    _nombreCtrl = TextEditingController(text: c?.nombre ?? '');
    _direccionCtrl = TextEditingController(text: c?.direccion ?? '');
    _unidadesCtrl =
        TextEditingController(text: c?.numUnidades.toString() ?? '');
    _activo = c?.activo ?? true;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _direccionCtrl.dispose();
    _unidadesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final request = CreateCondominioRequest(
      nombre: _nombreCtrl.text.trim(),
      direccion: _direccionCtrl.text.trim(),
      numUnidades: int.parse(_unidadesCtrl.text.trim()),
      activo: _activo,
    );

    if (_esEdicion) {
      await ref
          .read(condominioSaProvider.notifier)
          .editarCondominio(widget.condominio!.id, request);
    } else {
      await ref.read(condominioSaProvider.notifier).crearCondominio(request);
    }

    if (mounted) {
      final error = ref.read(condominioSaProvider).error;
      if (error == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(_esEdicion
                ? 'Condominio actualizado'
                : 'Condominio creado exitosamente')));
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: Colors.red));
        ref.read(condominioSaProvider.notifier).clearError();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(condominioSaProvider);

    return Scaffold(
      appBar: AppBar(
          title: Text(
              _esEdicion ? 'Editar Condominio' : 'Nuevo Condominio')),
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _direccionCtrl,
                decoration: const InputDecoration(
                    labelText: 'Dirección *',
                    border: OutlineInputBorder()),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _unidadesCtrl,
                decoration: const InputDecoration(
                    labelText: 'Número de unidades *',
                    border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Campo requerido';
                  final n = int.tryParse(v.trim());
                  if (n == null || n < 1) return 'Ingresa un número válido';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Condominio activo'),
                value: _activo,
                onChanged: (v) => setState(() => _activo = v),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: state.isLoading ? null : _submit,
                child: state.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(_esEdicion
                        ? 'Guardar Cambios'
                        : 'Crear Condominio'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
