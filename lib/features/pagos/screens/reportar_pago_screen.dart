import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/cuota_usuario_response.dart';
import '../models/reportar_pago_request.dart';
import '../providers/cuota_provider.dart';

class ReportarPagoScreen extends ConsumerStatefulWidget {
  final int cuotaUsuarioId;

  const ReportarPagoScreen({super.key, required this.cuotaUsuarioId});

  @override
  ConsumerState<ReportarPagoScreen> createState() => _ReportarPagoScreenState();
}

class _ReportarPagoScreenState extends ConsumerState<ReportarPagoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _referenciaCtrl = TextEditingController();
  final _notasCtrl = TextEditingController();

  CuotaUsuarioResponse? _cuota;

  @override
  void initState() {
    super.initState();
    final state = ref.read(cuotaProvider);
    _cuota = state.misCuotas
        .where((c) => c.id == widget.cuotaUsuarioId)
        .firstOrNull;
  }

  @override
  void dispose() {
    _referenciaCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final request = ReportarPagoRequest(
      referenciaPago: _referenciaCtrl.text.trim(),
      notasUsuario:
          _notasCtrl.text.trim().isEmpty ? null : _notasCtrl.text.trim(),
    );
    await ref
        .read(cuotaProvider.notifier)
        .reportarPago(widget.cuotaUsuarioId, request);
    if (mounted) {
      final error = ref.read(cuotaProvider).error;
      if (error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pago reportado exitosamente')),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
        ref.read(cuotaProvider.notifier).clearError();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cuotaProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Reportar Pago')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (_cuota != null) ...[
                Text(_cuota!.concepto,
                    style: Theme.of(context).textTheme.titleLarge),
                Text('Monto: \$${_cuota!.monto.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodyLarge),
                Text('Vence: ${_cuota!.fechaVencimiento}'),
                const SizedBox(height: 16),
                if (_cuota!.estado == EstadoPago.rechazado &&
                    _cuota!.notasAdmin != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(color: Colors.red),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Motivo de rechazo: ${_cuota!.notasAdmin}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
              ],
              TextFormField(
                controller: _referenciaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Referencia de pago *',
                  hintText: 'Número de transferencia o comprobante',
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
                maxLines: 3,
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
                    : const Text('Reportar Pago'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
