import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/usuario_admin.dart';
import '../providers/usuario_admin_provider.dart';

class GestionScreen extends ConsumerStatefulWidget {
  const GestionScreen({super.key});

  @override
  ConsumerState<GestionScreen> createState() => _GestionScreenState();
}

class _GestionScreenState extends ConsumerState<GestionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(usuarioAdminProvider.notifier).cargarUsuarios();
    });
  }

  Future<void> _subirCsv(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true, // necesario para web: carga los bytes en memoria
    );

    if (result == null || result.files.single.bytes == null) return;
    if (!context.mounted) return;

    final file = result.files.single;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Procesando archivo...'),
          ],
        ),
      ),
    );

    final response = await ref
        .read(usuarioAdminProvider.notifier)
        .uploadCsv(file.bytes!, file.name);

    if (!context.mounted) return;
    Navigator.pop(context);

    if (response != null) {
      final creados = response['creados'] as int? ?? 0;
      final errores = response['errores'] as List? ?? [];

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Resultado de carga'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('✓ $creados usuarios creados',
                  style: const TextStyle(
                      color: Colors.green, fontWeight: FontWeight.bold)),
              if (errores.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('✗ ${errores.length} errores:',
                    style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 4),
                ...errores.take(5).map((e) => Text(
                      '• Fila ${e['fila']}: ${e['motivo']}',
                      style: const TextStyle(fontSize: 12),
                    )),
                if (errores.length > 5)
                  Text('  ... y ${errores.length - 5} más',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey)),
              ],
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cerrar')),
          ],
        ),
      );
    } else {
      final error = ref.read(usuarioAdminProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error ?? 'Error al procesar el archivo'),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(usuarioAdminProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Subir CSV',
            onPressed: () => _subirCsv(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(usuarioAdminProvider.notifier).cargarUsuarios(),
          ),
        ],
      ),
      body: _buildBody(context, state),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/home/usuarios/nuevo'),
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildBody(BuildContext context, UsuarioAdminState state) {
    if (state.isLoading && state.usuarios.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.usuarios.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 8),
            Text(state.error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(usuarioAdminProvider.notifier).cargarUsuarios(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (state.usuarios.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.group_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 8),
            Text('No hay usuarios registrados'),
            SizedBox(height: 4),
            Text('Usa el botón + para agregar uno', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: state.usuarios.length,
      itemBuilder: (context, index) {
        final usuario = state.usuarios[index];
        return _UsuarioTile(
          usuario: usuario,
          onTap: () => context.push('/home/usuarios/${usuario.id}'),
        );
      },
    );
  }
}

class _UsuarioTile extends StatelessWidget {
  final UsuarioAdmin usuario;
  final VoidCallback onTap;

  const _UsuarioTile({required this.usuario, required this.onTap});

  Color _rolColor() => switch (usuario.rol) {
        RolUsuario.guardia => Colors.green,
        RolUsuario.usuario => Colors.blue,
        RolUsuario.admin => Colors.purple,
        RolUsuario.superadmin => Colors.red,
      };

  String _rolLabel() => switch (usuario.rol) {
        RolUsuario.guardia => 'GUARDIA',
        RolUsuario.usuario => 'USUARIO',
        RolUsuario.admin => 'ADMIN',
        RolUsuario.superadmin => 'SUPERADMIN',
      };

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor:
            usuario.activo ? _rolColor().withValues(alpha: 0.15) : Colors.grey.shade200,
        child: Icon(
          usuario.rol == RolUsuario.guardia ? Icons.security : Icons.person,
          color: usuario.activo ? _rolColor() : Colors.grey,
        ),
      ),
      title: Text(
        usuario.nombreCompleto,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: usuario.activo ? null : Colors.grey,
        ),
      ),
      subtitle: Text('@${usuario.username}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Chip(
            label: Text(
              _rolLabel(),
              style: const TextStyle(fontSize: 10, color: Colors.white),
            ),
            backgroundColor: usuario.activo ? _rolColor() : Colors.grey,
            padding: EdgeInsets.zero,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          if (!usuario.activo) ...[
            const SizedBox(width: 4),
            const Icon(Icons.block, color: Colors.grey, size: 16),
          ],
        ],
      ),
      onTap: onTap,
    );
  }
}
