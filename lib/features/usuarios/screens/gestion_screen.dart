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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(usuarioAdminProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
        actions: [
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
