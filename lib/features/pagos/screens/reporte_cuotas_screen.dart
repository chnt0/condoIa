import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/api_constants.dart';
import '../../../shared/providers/auth_provider.dart';
import '../models/cuota_usuario_response.dart';

class ReporteCuotasScreen extends ConsumerStatefulWidget {
  const ReporteCuotasScreen({super.key});

  @override
  ConsumerState<ReporteCuotasScreen> createState() =>
      _ReporteCuotasScreenState();
}

class _ReporteCuotasScreenState extends ConsumerState<ReporteCuotasScreen> {
  final _mesCtrl = TextEditingController();
  String _estadoFiltro = 'TODOS';
  List<CuotaUsuarioResponse> _registros = [];
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _mesCtrl.dispose();
    super.dispose();
  }

  Future<void> _buscar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final apiClient = ref.read(apiClientProvider);
      final params = <String, String>{'estado': _estadoFiltro};
      final mes = _mesCtrl.text.trim();
      if (mes.isNotEmpty) params['mes'] = mes;

      final response = await apiClient.getList(
        ApiConstants.cuotaReporte,
        queryParameters: params,
      );
      setState(() {
        _registros = response
            .map((item) =>
                CuotaUsuarioResponse.fromJson(item as Map<String, dynamic>))
            .toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _buildCsv() {
    final buf = StringBuffer();
    buf.writeln('Unidad,Nombre,Concepto,Monto,Estado,Referencia,Fecha_Reporte');
    for (final r in _registros) {
      final unidad = r.unidadHabitacional ?? '';
      final nombre = r.usuarioNombre.replaceAll(',', ' ');
      final concepto = r.concepto.replaceAll(',', ' ');
      final monto = r.monto.toStringAsFixed(2);
      final estado = r.estado.name.toUpperCase();
      final ref_ = r.referenciaPago ?? '';
      final fecha =
          r.fechaReporte?.toIso8601String().substring(0, 10) ?? '';
      buf.writeln('$unidad,$nombre,$concepto,$monto,$estado,$ref_,$fecha');
    }
    return buf.toString();
  }

  Future<void> _exportarCsv() async {
    final csv = _buildCsv();
    final mes = _mesCtrl.text.trim().replaceAll('-', '');
    final filename = 'reporte_cuotas_${mes.isNotEmpty ? mes : 'general'}.csv';

    if (kIsWeb) {
      // En web compartir como texto
      await Share.share(csv, subject: filename);
    } else {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsString(csv);
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Reporte de cuotas',
      );
    }
  }

  Color _estadoColor(EstadoPago e) => switch (e) {
        EstadoPago.confirmado => Colors.green,
        EstadoPago.reportado => Colors.orange,
        EstadoPago.pendiente => Colors.grey,
        EstadoPago.rechazado => Colors.red,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reporte de Cuotas'),
        actions: [
          if (_registros.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Exportar CSV',
              onPressed: _exportarCsv,
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _mesCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Mes (YYYY-MM)',
                      hintText: '2026-07',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _estadoFiltro,
                    decoration: const InputDecoration(
                      labelText: 'Estado',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'TODOS', child: Text('Todos')),
                      DropdownMenuItem(
                          value: 'CONFIRMADO', child: Text('Pagados')),
                      DropdownMenuItem(
                          value: 'PENDIENTE', child: Text('Pendientes')),
                    ],
                    onChanged: (v) => setState(() => _estadoFiltro = v!),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _loading ? null : _buscar,
                  child: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child:
                              CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Buscar'),
                ),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(_error!,
                  style: const TextStyle(color: Colors.red)),
            ),
          if (_registros.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${_registros.length} registros · Toca ↓ para exportar',
                  style:
                      const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ),
          Expanded(
            child: _registros.isEmpty && !_loading
                ? const Center(
                    child: Text('Aplica filtros y presiona Buscar',
                        style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    itemCount: _registros.length,
                    itemBuilder: (context, index) {
                      final r = _registros[index];
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          backgroundColor:
                              _estadoColor(r.estado).withOpacity(0.15),
                          radius: 20,
                          child: Text(
                            r.unidadHabitacional
                                    ?.split('-')
                                    .last
                                    .trim() ??
                                '?',
                            style: TextStyle(
                                fontSize: 10,
                                color: _estadoColor(r.estado),
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(r.usuarioNombre,
                            style: const TextStyle(fontSize: 13)),
                        subtitle: Text(
                            '${r.concepto} · \$${r.monto.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 11)),
                        trailing: Chip(
                          label: Text(
                            r.estado.name.toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 10),
                          ),
                          backgroundColor: _estadoColor(r.estado),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
