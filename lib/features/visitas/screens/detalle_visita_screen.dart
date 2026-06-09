import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/visita.dart';
import '../providers/visita_provider.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/models/usuario.dart';

class DetalleVisitaScreen extends ConsumerStatefulWidget {
  final int visitaId;

  const DetalleVisitaScreen({super.key, required this.visitaId});

  @override
  ConsumerState<DetalleVisitaScreen> createState() =>
      _DetalleVisitaScreenState();
}

class _DetalleVisitaScreenState extends ConsumerState<DetalleVisitaScreen> {
  String? _qrBase64;
  bool _loadingQr = true;
  bool _cancelando = false;

  @override
  void initState() {
    super.initState();
    _loadQr();
  }

  Future<void> _loadQr() async {
    final qr = await ref.read(visitaProvider.notifier).obtenerImagenQr(widget.visitaId);
    if (mounted) {
      setState(() {
        _qrBase64 = qr;
        _loadingQr = false;
      });
    }
  }

  Visita? _findVisita() {
    final visitaState = ref.read(visitaProvider);
    for (final v in [...visitaState.misVisitas, ...visitaState.todasVisitas]) {
      if (v.id == widget.visitaId) return v;
    }
    return null;
  }

  Uint8List? _decodeQr() {
    if (_qrBase64 == null) return null;
    try {
      return base64Decode(_qrBase64!);
    } catch (_) {
      return null;
    }
  }

  Future<void> _cancelar(Visita visita) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar visita'),
        content: Text('¿Cancelar la visita de ${visita.nombreVisitante}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sí, cancelar')),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _cancelando = true);
    await ref.read(visitaProvider.notifier).cancelarVisita(visita.id);
    if (!mounted) return;
    setState(() => _cancelando = false);

    final error = ref.read(visitaProvider).error;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Visita cancelada'), backgroundColor: Colors.orange),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(visitaProvider);
    final visita = _findVisita();
    final user = ref.watch(authProvider).user!;
    final canCancel = visita?.estado == EstadoVisita.programada &&
        (user.rol == Rol.usuario || user.rol == Rol.admin || user.rol == Rol.superadmin);

    final qrBytes = _decodeQr();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Visita'),
        actions: [
          if (canCancel)
            TextButton(
              onPressed: _cancelando ? null : () => _cancelar(visita!),
              child: _cancelando
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Cancelar', style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
      body: visita == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: _loadingQr
                        ? const SizedBox(
                            height: 200,
                            width: 200,
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : qrBytes != null
                            ? Image.memory(qrBytes, width: 200, height: 200, fit: BoxFit.contain)
                            : const Icon(Icons.qr_code, size: 100, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Muestra este QR al guardia de entrada',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _InfoTile(icon: Icons.person, label: 'Visitante', value: visita.nombreVisitante),
                  if (visita.telefonoVisitante != null)
                    _InfoTile(icon: Icons.phone, label: 'Teléfono', value: visita.telefonoVisitante!),
                  _InfoTile(
                    icon: Icons.calendar_today,
                    label: 'Fecha y hora',
                    value: '${visita.fechaHoraProgramada.day}/${visita.fechaHoraProgramada.month}/${visita.fechaHoraProgramada.year} '
                        '${visita.fechaHoraProgramada.hour.toString().padLeft(2, '0')}:${visita.fechaHoraProgramada.minute.toString().padLeft(2, '0')}',
                  ),
                  if (visita.motivo != null)
                    _InfoTile(icon: Icons.description, label: 'Motivo', value: visita.motivo!),
                  if (visita.vehiculoPlacas != null)
                    _InfoTile(icon: Icons.directions_car, label: 'Placas', value: visita.vehiculoPlacas!),
                  _InfoTile(
                    icon: Icons.info_outline,
                    label: 'Estado',
                    value: visita.estado.name.toUpperCase(),
                    valueColor: switch (visita.estado) {
                      EstadoVisita.programada => Colors.blue,
                      EstadoVisita.completada => Colors.green,
                      EstadoVisita.cancelada => Colors.red,
                    },
                  ),
                  if (visita.fechaHoraEntrada != null)
                    _InfoTile(
                      icon: Icons.login,
                      label: 'Entrada registrada',
                      value: '${visita.fechaHoraEntrada!.day}/${visita.fechaHoraEntrada!.month}/${visita.fechaHoraEntrada!.year} '
                          '${visita.fechaHoraEntrada!.hour.toString().padLeft(2, '0')}:${visita.fechaHoraEntrada!.minute.toString().padLeft(2, '0')}',
                    ),
                  if (visita.guardiaEntradaNombre != null)
                    _InfoTile(icon: Icons.security, label: 'Guardia', value: visita.guardiaEntradaNombre!),
                ],
              ),
            ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              Text(
                value,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: valueColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
