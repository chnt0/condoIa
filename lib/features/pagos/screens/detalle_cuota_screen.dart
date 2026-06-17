import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/confirmar_pago_request.dart';
import '../models/cuota_usuario_response.dart';
import '../providers/cuota_provider.dart';

class DetalleCuotaScreen extends ConsumerStatefulWidget {
  final int cuotaId;

  const DetalleCuotaScreen({super.key, required this.cuotaId});

  @override
  ConsumerState<DetalleCuotaScreen> createState() => _DetalleCuotaScreenState();
}

class _DetalleCuotaScreenState extends ConsumerState<DetalleCuotaScreen> {
  List<CuotaUsuarioResponse> _registros = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargarDetalle();
  }

  Future<void> _cargarDetalle() async {
    setState(() => _loading = true);
    final registros =
        await ref.read(cuotaProvider.notifier).obtenerDetalle(widget.cuotaId);
    setState(() {
      _registros = registros;
      _loading = false;
    });
  }

  void _verFotoCompleta(BuildContext context, String base64) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Comprobante'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(ctx),
              ),
              automaticallyImplyLeading: false,
            ),
            InteractiveViewer(
              child: Image.memory(base64Decode(base64)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmar(int cuotaUsuarioId) async {
    await ref.read(cuotaProvider.notifier).confirmarPago(
          cuotaUsuarioId,
          const ConfirmarPagoRequest(confirmado: true),
        );
    _cargarDetalle();
  }

  Future<void> _rechazar(int cuotaUsuarioId) async {
    final notasCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rechazar pago'),
        content: TextField(
          controller: notasCtrl,
          decoration: const InputDecoration(
            labelText: 'Motivo del rechazo *',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (notasCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(cuotaProvider.notifier).confirmarPago(
            cuotaUsuarioId,
            ConfirmarPagoRequest(
                confirmado: false, notasAdmin: notasCtrl.text.trim()),
          );
      _cargarDetalle();
    }
  }

  Color _estadoColor(EstadoPago estado) => switch (estado) {
        EstadoPago.pendiente => Colors.grey,
        EstadoPago.reportado => Colors.orange,
        EstadoPago.confirmado => Colors.green,
        EstadoPago.rechazado => Colors.red,
      };

  String _estadoLabel(EstadoPago estado) => switch (estado) {
        EstadoPago.pendiente => 'PENDIENTE',
        EstadoPago.reportado => 'REPORTADO',
        EstadoPago.confirmado => 'CONFIRMADO',
        EstadoPago.rechazado => 'RECHAZADO',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Cuota'),
        actions: [
          IconButton(
              onPressed: _cargarDetalle, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _registros.isEmpty
              ? const Center(child: Text('No hay residentes asignados.'))
              : ListView.builder(
                  itemCount: _registros.length,
                  itemBuilder: (context, index) {
                    final r = _registros[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(r.usuarioNombre,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ),
                                Chip(
                                  label: Text(_estadoLabel(r.estado),
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 11)),
                                  backgroundColor: _estadoColor(r.estado),
                                ),
                              ],
                            ),
                            if (r.unidadHabitacional != null)
                              Text('Unidad: ${r.unidadHabitacional}'),
                            if (r.referenciaPago != null)
                              Text('Ref: ${r.referenciaPago}'),
                            if (r.notasUsuario != null)
                              Text('Nota usuario: ${r.notasUsuario}'),
                            if (r.comprobanteFoto != null) ...[
                              const SizedBox(height: 6),
                              GestureDetector(
                                onTap: () => _verFotoCompleta(
                                    context, r.comprobanteFoto!),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.memory(
                                    base64Decode(r.comprobanteFoto!),
                                    height: 120,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text('Toca la imagen para ampliar',
                                  style: TextStyle(
                                      fontSize: 10, color: Colors.grey)),
                            ],
                            if (r.notasAdmin != null)
                              Text('Nota admin: ${r.notasAdmin}',
                                  style: const TextStyle(color: Colors.red)),
                            if (r.estado == EstadoPago.reportado)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () => _rechazar(r.id),
                                    style: TextButton.styleFrom(
                                        foregroundColor: Colors.red),
                                    child: const Text('Rechazar'),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () => _confirmar(r.id),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green),
                                    child: const Text('Confirmar'),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
