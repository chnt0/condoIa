import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/validar_qr_request.dart';
import '../models/validar_qr_response.dart';
import '../providers/visita_provider.dart';

class EscanearQrScreen extends ConsumerStatefulWidget {
  const EscanearQrScreen({super.key});

  @override
  ConsumerState<EscanearQrScreen> createState() => _EscanearQrScreenState();
}

class _EscanearQrScreenState extends ConsumerState<EscanearQrScreen> {
  bool _usarCamara = true;
  bool _procesando = false;
  bool _dialogOpen = false;
  final TextEditingController _codigoController = TextEditingController();
  final MobileScannerController _scannerController = MobileScannerController();

  @override
  void dispose() {
    _codigoController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _validar(String codigo) async {
    if (_procesando || codigo.isEmpty || _dialogOpen) return;
    setState(() => _procesando = true);

    final request = ValidarQrRequest(codigoQr: codigo.trim());
    final response = await ref.read(visitaProvider.notifier).validarQr(request);

    if (!mounted) return;
    setState(() => _procesando = false);

    if (response != null) {
      await _mostrarResultado(response);
    }
  }

  Future<void> _mostrarResultado(ValidarQrResponse response) async {
    setState(() => _dialogOpen = true);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              response.valido ? Icons.check_circle : Icons.cancel,
              color: response.valido ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                response.valido ? 'Acceso Permitido' : 'Acceso Denegado',
                style: TextStyle(color: response.valido ? Colors.green : Colors.red),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(response.mensaje),
            if (response.visita != null) ...[
              const Divider(height: 24),
              _ResultRow(label: 'Visitante', value: response.visita!.nombreVisitante),
              _ResultRow(label: 'Residente', value: response.visita!.usuarioNombre),
              if (response.visita!.unidadHabitacional != null)
                _ResultRow(label: 'Unidad', value: response.visita!.unidadHabitacional!),
              if (response.visita!.motivo != null)
                _ResultRow(label: 'Motivo', value: response.visita!.motivo!),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );

    if (mounted) {
      setState(() => _dialogOpen = false);
      if (_usarCamara) _scannerController.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Validar QR'),
        actions: [
          TextButton.icon(
            onPressed: () {
              setState(() {
                _usarCamara = !_usarCamara;
                if (_usarCamara) {
                  _scannerController.start();
                } else {
                  _scannerController.stop();
                }
              });
            },
            icon: Icon(_usarCamara ? Icons.keyboard : Icons.camera_alt),
            label: Text(_usarCamara ? 'Manual' : 'Cámara'),
          ),
        ],
      ),
      body: _usarCamara ? _buildCamara() : _buildManual(),
    );
  }

  Widget _buildCamara() {
    return Stack(
      children: [
        MobileScanner(
          controller: _scannerController,
          onDetect: (capture) {
            final barcodes = capture.barcodes;
            final code = barcodes.isEmpty ? null : barcodes.first.rawValue;
            if (code != null && !_procesando && !_dialogOpen) {
              _scannerController.stop();
              _validar(code);
            }
          },
        ),
        if (_procesando)
          Container(
            color: Colors.black45,
            child: const Center(child: CircularProgressIndicator(color: Colors.white)),
          ),
        Positioned(
          bottom: 32,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Apunta la cámara al código QR del visitante',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildManual() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Ingresa o pega el código QR del visitante:',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _codigoController,
            decoration: const InputDecoration(
              labelText: 'Código QR',
              hintText: 'Pega aquí el código QR',
              prefixIcon: Icon(Icons.qr_code),
            ),
            maxLines: 3,
            enabled: !_procesando,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _procesando ? null : () => _validar(_codigoController.text),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _procesando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Validar Entrada', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;

  const _ResultRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          Flexible(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
