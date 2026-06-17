import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/create_usuario_request.dart';
import '../providers/usuario_admin_provider.dart';

class CrearUsuarioScreen extends ConsumerStatefulWidget {
  const CrearUsuarioScreen({super.key});

  @override
  ConsumerState<CrearUsuarioScreen> createState() => _CrearUsuarioScreenState();
}

class _CrearUsuarioScreenState extends ConsumerState<CrearUsuarioScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _telefono2Controller = TextEditingController();
  final _unidadController = TextEditingController();
  bool _obscurePassword = true;
  String _selectedRol = 'USUARIO';
  bool _esPropietario = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _telefonoController.dispose();
    _telefono2Controller.dispose();
    _unidadController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // username = email (autofill)
    final request = CreateUsuarioRequest(
      username: _emailController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      nombreCompleto: _nombreController.text.trim(),
      telefono: _telefonoController.text.trim().isEmpty
          ? null
          : _telefonoController.text.trim(),
      telefono2: _telefono2Controller.text.trim().isEmpty
          ? null
          : _telefono2Controller.text.trim(),
      rol: _selectedRol,
      unidadHabitacional: _unidadController.text.trim().isEmpty
          ? null
          : _unidadController.text.trim(),
      esPropietario: _esPropietario,
    );

    final nuevo = await ref.read(usuarioAdminProvider.notifier).crearUsuario(request);

    if (!mounted) return;

    if (nuevo != null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usuario creado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      final error = ref.read(usuarioAdminProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Error al crear el usuario'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(usuarioAdminProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo Usuario')),
      body: SingleChildScrollView(
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
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                textInputAction: TextInputAction.next,
                enabled: !isLoading,
              ),
              const SizedBox(height: 16),
              // Email — se usa también como username
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  prefixIcon: Icon(Icons.email),
                  helperText: 'Se usará como usuario de acceso',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Requerido';
                  if (!v.contains('@')) return 'Email inválido';
                  return null;
                },
                textInputAction: TextInputAction.next,
                enabled: !isLoading,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Contraseña *',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                obscureText: _obscurePassword,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requerido';
                  if (v.length < 6) return 'Mínimo 6 caracteres';
                  return null;
                },
                textInputAction: TextInputAction.next,
                enabled: !isLoading,
              ),
              const SizedBox(height: 16),
              // Rol — antes de unidad para que el validator funcione en orden
              DropdownButtonFormField<String>(
                value: _selectedRol,
                decoration: const InputDecoration(
                  labelText: 'Rol *',
                  prefixIcon: Icon(Icons.badge),
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'USUARIO', child: Text('USUARIO — Residente')),
                  DropdownMenuItem(
                      value: 'GUARDIA',
                      child: Text('GUARDIA — Guardia de seguridad')),
                ],
                onChanged: isLoading
                    ? null
                    : (v) => setState(() => _selectedRol = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telefonoController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono 1',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                enabled: !isLoading,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telefono2Controller,
                decoration: const InputDecoration(
                  labelText: 'Teléfono 2 (opcional)',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                enabled: !isLoading,
              ),
              const SizedBox(height: 16),
              // Unidad habitacional — requerida para USUARIO
              TextFormField(
                controller: _unidadController,
                decoration: InputDecoration(
                  labelText: _selectedRol == 'USUARIO'
                      ? 'Unidad habitacional *'
                      : 'Unidad habitacional',
                  prefixIcon: const Icon(Icons.home),
                  hintText: 'Ej: Torre A-101',
                ),
                validator: (v) {
                  if (_selectedRol == 'USUARIO' &&
                      (v == null || v.trim().isEmpty)) {
                    return 'Requerida para residentes';
                  }
                  return null;
                },
                textInputAction: TextInputAction.done,
                enabled: !isLoading,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Es propietario'),
                subtitle: const Text('El residente es dueño de la unidad'),
                value: _esPropietario,
                onChanged: isLoading
                    ? null
                    : (v) => setState(() => _esPropietario = v),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Crear Usuario',
                        style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
