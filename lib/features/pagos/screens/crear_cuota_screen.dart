import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../features/usuarios/models/usuario_admin.dart';
import '../../../features/usuarios/providers/usuario_admin_provider.dart';
import '../models/create_cuota_request.dart';
import '../models/cuota_response.dart';
import '../providers/cuota_provider.dart';

class CrearCuotaScreen extends ConsumerStatefulWidget {
  const CrearCuotaScreen({super.key});

  @override
  ConsumerState<CrearCuotaScreen> createState() => _CrearCuotaScreenState();
}

class _CrearCuotaScreenState extends ConsumerState<CrearCuotaScreen> {
  final _formKey = GlobalKey<FormState>();
  TipoCuota _tipo = TipoCuota.mensual;
  final _conceptoCtrl = TextEditingController();
  final _montoCtrl = TextEditingController();
  final _mesCtrl = TextEditingController();
  DateTime? _fechaVencimiento;
  final Set<int> _selectedUsuarioIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(usuarioAdminProvider.notifier).cargarUsuarios();
    });
  }

  @override
  void dispose() {
    _conceptoCtrl.dispose();
    _montoCtrl.dispose();
    _mesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFechaVencimiento() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _fechaVencimiento = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fechaVencimiento == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona la fecha de vencimiento')),
      );
      return;
    }
    if (_tipo == TipoCuota.extraordinaria && _selectedUsuarioIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos un residente')),
      );
      return;
    }

    final fechaStr =
        '${_fechaVencimiento!.year}-${_fechaVencimiento!.month.toString().padLeft(2, '0')}-${_fechaVencimiento!.day.toString().padLeft(2, '0')}';

    final request = CreateCuotaRequest(
      tipo: _tipo,
      concepto: _conceptoCtrl.text.trim(),
      monto: double.parse(_montoCtrl.text.trim()),
      mes: _tipo == TipoCuota.mensual ? _mesCtrl.text.trim() : null,
      fechaVencimiento: fechaStr,
      usuarioIds: _tipo == TipoCuota.extraordinaria
          ? _selectedUsuarioIds.toList()
          : null,
    );

    final cuota = await ref.read(cuotaProvider.notifier).crearCuota(request);
    if (mounted) {
      if (cuota != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cuota creada exitosamente')),
        );
        context.pop();
      } else {
        final error = ref.read(cuotaProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(error ?? 'Error al crear cuota'),
              backgroundColor: Colors.red),
        );
        ref.read(cuotaProvider.notifier).clearError();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cuotaState = ref.watch(cuotaProvider);
    final usuarioState = ref.watch(usuarioAdminProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Nueva Cuota')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<TipoCuota>(
                value: _tipo,
                decoration: const InputDecoration(
                  labelText: 'Tipo de cuota',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                      value: TipoCuota.mensual, child: Text('Mensual')),
                  DropdownMenuItem(
                      value: TipoCuota.extraordinaria,
                      child: Text('Extraordinaria')),
                ],
                onChanged: (v) => setState(() => _tipo = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _conceptoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Concepto *',
                  hintText: 'Ej: Mantenimiento Enero 2025',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _montoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Monto *',
                  prefixText: '\$',
                  border: OutlineInputBorder(),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Campo requerido';
                  final n = double.tryParse(v.trim());
                  if (n == null || n <= 0) return 'Ingresa un monto válido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              if (_tipo == TipoCuota.mensual) ...[
                TextFormField(
                  controller: _mesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Mes (YYYY-MM) *',
                    hintText: 'Ej: 2025-01',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Campo requerido';
                    final regex = RegExp(r'^\d{4}-\d{2}$');
                    if (!regex.hasMatch(v.trim())) return 'Formato: YYYY-MM';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_fechaVencimiento == null
                    ? 'Fecha de vencimiento *'
                    : 'Vence: ${_fechaVencimiento!.day}/${_fechaVencimiento!.month}/${_fechaVencimiento!.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickFechaVencimiento,
              ),
              if (_tipo == TipoCuota.extraordinaria) ...[
                const Divider(),
                const Text('Selecciona destinatarios:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                if (usuarioState.isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  ...usuarioState.usuarios
                      .where((u) =>
                          u.rol == RolUsuario.usuario && u.activo)
                      .map((u) => CheckboxListTile(
                            title: Text(u.nombreCompleto),
                            subtitle: Text(u.unidadHabitacional ?? ''),
                            value: _selectedUsuarioIds.contains(u.id),
                            onChanged: (checked) {
                              setState(() {
                                if (checked == true) {
                                  _selectedUsuarioIds.add(u.id);
                                } else {
                                  _selectedUsuarioIds.remove(u.id);
                                }
                              });
                            },
                          )),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: cuotaState.isLoading ? null : _submit,
                child: cuotaState.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Crear Cuota'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
