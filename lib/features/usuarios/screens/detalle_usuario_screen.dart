import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/update_usuario_request.dart';
import '../models/usuario_admin.dart';
import '../providers/usuario_admin_provider.dart';

class DetalleUsuarioScreen extends ConsumerStatefulWidget {
  final int usuarioId;

  const DetalleUsuarioScreen({super.key, required this.usuarioId});

  @override
  ConsumerState<DetalleUsuarioScreen> createState() =>
      _DetalleUsuarioScreenState();
}

class _DetalleUsuarioScreenState extends ConsumerState<DetalleUsuarioScreen> {
  bool _editMode = false;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _telefonoController;
  late TextEditingController _unidadController;
  String _selectedRol = 'USUARIO';
  bool _esPropietario = false;

  UsuarioAdmin? _findUsuario() {
    final usuarios = ref.read(usuarioAdminProvider).usuarios;
    for (final u in usuarios) {
      if (u.id == widget.usuarioId) return u;
    }
    return null;
  }

  void _initEditFields(UsuarioAdmin usuario) {
    _nombreController.text = usuario.nombreCompleto;
    _telefonoController.text = usuario.telefono ?? '';
    _unidadController.text = usuario.unidadHabitacional ?? '';
    _selectedRol = usuario.rol == RolUsuario.guardia ? 'GUARDIA' : 'USUARIO';
    _esPropietario = usuario.esPropietario;
  }

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController();
    _telefonoController = TextEditingController();
    _unidadController = TextEditingController();
    final usuario = _findUsuario();
    if (usuario != null) _initEditFields(usuario);
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _unidadController.dispose();
    super.dispose();
  }

  Future<void> _saveEdit(UsuarioAdmin usuario) async {
    if (!_formKey.currentState!.validate()) return;

    final request = UpdateUsuarioRequest(
      nombreCompleto: _nombreController.text.trim(),
      telefono:
          _telefonoController.text.trim().isEmpty ? null : _telefonoController.text.trim(),
      rol: _selectedRol,
      unidadHabitacional:
          _unidadController.text.trim().isEmpty ? null : _unidadController.text.trim(),
      esPropietario: _esPropietario,
    );

    await ref.read(usuarioAdminProvider.notifier).actualizarUsuario(usuario.id, request);

    if (!mounted) return;
    setState(() => _editMode = false);

    final error = ref.read(usuarioAdminProvider).error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Usuario actualizado'),
        backgroundColor: error != null ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _toggleEstado(UsuarioAdmin usuario) async {
    final action = usuario.activo ? 'desactivar' : 'activar';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${action[0].toUpperCase()}${action.substring(1)} usuario'),
        content: Text('¿Deseas $action a ${usuario.nombreCompleto}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Sí, $action')),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    await ref.read(usuarioAdminProvider.notifier).toggleEstado(usuario.id);

    if (!mounted) return;
    final error = ref.read(usuarioAdminProvider).error;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(usuarioAdminProvider);
    final usuario = _findUsuario();

    return Scaffold(
      appBar: AppBar(
        title: Text(usuario?.nombreCompleto ?? 'Usuario'),
        actions: [
          if (usuario != null && !_editMode)
            TextButton(
              onPressed: () {
                _initEditFields(usuario);
                setState(() => _editMode = true);
              },
              child: const Text('Editar'),
            ),
          if (_editMode)
            TextButton(
              onPressed: () => setState(() => _editMode = false),
              child: const Text('Cancelar'),
            ),
        ],
      ),
      body: usuario == null
          ? const Center(child: Text('Usuario no encontrado'))
          : _editMode
              ? _buildEditForm(usuario)
              : _buildDetail(usuario),
    );
  }

  Widget _buildDetail(UsuarioAdmin usuario) {
    final isLoading = ref.watch(usuarioAdminProvider).isLoading;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(icon: Icons.person, label: 'Nombre', value: usuario.nombreCompleto),
          _InfoRow(
              icon: Icons.alternate_email,
              label: 'Username',
              value: '@${usuario.username}'),
          _InfoRow(icon: Icons.email, label: 'Email', value: usuario.email),
          if (usuario.telefono != null)
            _InfoRow(icon: Icons.phone, label: 'Teléfono', value: usuario.telefono!),
          if (usuario.unidadHabitacional != null)
            _InfoRow(
                icon: Icons.home,
                label: 'Unidad',
                value: usuario.unidadHabitacional!),
          _InfoRow(
              icon: Icons.badge, label: 'Rol', value: usuario.rol.name.toUpperCase()),
          _InfoRow(
              icon: Icons.check_circle,
              label: 'Propietario',
              value: usuario.esPropietario ? 'Sí' : 'No'),
          _InfoRow(
            icon: usuario.activo ? Icons.check_circle_outline : Icons.block,
            label: 'Estado',
            value: usuario.activo ? 'Activo' : 'Inactivo',
            valueColor: usuario.activo ? Colors.green : Colors.red,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isLoading ? null : () => _toggleEstado(usuario),
              icon: Icon(
                usuario.activo ? Icons.block : Icons.check_circle_outline,
                color: usuario.activo ? Colors.red : Colors.green,
              ),
              label: Text(
                usuario.activo ? 'Desactivar usuario' : 'Activar usuario',
                style:
                    TextStyle(color: usuario.activo ? Colors.red : Colors.green),
              ),
              style: OutlinedButton.styleFrom(
                side:
                    BorderSide(color: usuario.activo ? Colors.red : Colors.green),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm(UsuarioAdmin usuario) {
    final isLoading = ref.watch(usuarioAdminProvider).isLoading;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre completo *',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              enabled: !isLoading,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _telefonoController,
              decoration: const InputDecoration(
                labelText: 'Teléfono',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
              enabled: !isLoading,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _unidadController,
              decoration: const InputDecoration(
                labelText: 'Unidad habitacional',
                prefixIcon: Icon(Icons.home),
              ),
              enabled: !isLoading,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedRol,
              decoration: const InputDecoration(
                labelText: 'Rol *',
                prefixIcon: Icon(Icons.badge),
              ),
              items: const [
                DropdownMenuItem(value: 'USUARIO', child: Text('USUARIO — Residente')),
                DropdownMenuItem(
                    value: 'GUARDIA',
                    child: Text('GUARDIA — Guardia de seguridad')),
              ],
              onChanged: isLoading ? null : (v) => setState(() => _selectedRol = v!),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Es propietario'),
              value: _esPropietario,
              onChanged:
                  isLoading ? null : (v) => setState(() => _esPropietario = v),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isLoading ? null : () => _saveEdit(usuario),
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16)),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Guardar cambios', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
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
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w500, color: valueColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
