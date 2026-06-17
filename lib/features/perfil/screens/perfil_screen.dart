import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/services/auth_service.dart';

class PerfilScreen extends ConsumerWidget {
  const PerfilScreen({super.key});

  Future<void> _solicitarEliminarCuenta(
      BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar cuenta'),
        content: const Text(
          'Tu cuenta quedará desactivada inmediatamente y será eliminada permanentemente en un plazo de 30 días.\n\n'
          '¿Estás seguro de que deseas continuar?',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sí, eliminar mi cuenta'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        final apiClient = ref.read(apiClientProvider);
        await apiClient.delete(ApiConstants.eliminarCuenta);
        if (context.mounted) {
          await ref.read(authProvider.notifier).logout();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Cuenta desactivada. Será eliminada en 30 días.'),
                backgroundColor: Colors.orange),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Error: ${e.toString()}'),
                backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _mostrarCambiarPassword(
      BuildContext context, WidgetRef ref) async {
    final actualCtrl = TextEditingController();
    final nuevoCtrl = TextEditingController();
    final confirmarCtrl = TextEditingController();
    bool enviando = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Cambiar contraseña'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: actualCtrl,
                decoration: const InputDecoration(
                    labelText: 'Contraseña actual',
                    border: OutlineInputBorder()),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nuevoCtrl,
                decoration: const InputDecoration(
                    labelText: 'Nueva contraseña (mín. 6 caracteres)',
                    border: OutlineInputBorder()),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmarCtrl,
                decoration: const InputDecoration(
                    labelText: 'Confirmar nueva contraseña',
                    border: OutlineInputBorder()),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: enviando
                  ? null
                  : () async {
                      if (actualCtrl.text.isEmpty ||
                          nuevoCtrl.text.isEmpty ||
                          confirmarCtrl.text.isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                            content: Text('Completa todos los campos')));
                        return;
                      }
                      if (nuevoCtrl.text.length < 6) {
                        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                            content:
                                Text('La nueva contraseña debe tener al menos 6 caracteres')));
                        return;
                      }
                      if (nuevoCtrl.text != confirmarCtrl.text) {
                        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                            content: Text('Las contraseñas no coinciden'),
                            backgroundColor: Colors.red));
                        return;
                      }
                      setState(() => enviando = true);
                      try {
                        final authService = ref.read(authServiceProvider);
                        await authService.cambiarPassword(
                            actualCtrl.text, nuevoCtrl.text);
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Contraseña actualizada'),
                                backgroundColor: Colors.green),
                          );
                        }
                      } catch (e) {
                        setState(() => enviando = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                              content: Text(e.toString()),
                              backgroundColor: Colors.red));
                        }
                      }
                    },
              child: enviando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user!;
    final initials = user.nombreCompleto
        .split(' ')
        .where((s) => s.isNotEmpty)
        .take(2)
        .map((s) => s[0].toUpperCase())
        .join();

    return Scaffold(
      appBar: AppBar(title: const Text('Mi Perfil')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 44,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                initials,
                style: const TextStyle(fontSize: 28, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user.nombreCompleto,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              user.email,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Chip(label: Text(user.rol.name.toUpperCase())),
            if (user.unidadHabitacional != null) ...[
              const SizedBox(height: 4),
              Text('Unidad: ${user.unidadHabitacional}'),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _mostrarCambiarPassword(context, ref),
                icon: const Icon(Icons.lock_outline),
                label: const Text('Cambiar contraseña'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(authProvider.notifier).logout();
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('Cerrar Sesión',
                    style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () =>
                    _solicitarEliminarCuenta(context, ref),
                child: const Text(
                  'Solicitar eliminación de cuenta',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
