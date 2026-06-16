import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../features/usuarios/models/create_usuario_request.dart';
import '../../../features/usuarios/models/usuario_admin.dart';
import '../../../features/usuarios/services/usuario_admin_service.dart';
import '../../../shared/providers/auth_provider.dart';
import '../models/condominio_sa.dart';
import '../providers/condominio_sa_provider.dart';
import '../services/condominio_sa_service.dart';

class DetalleCondominioScreen extends ConsumerStatefulWidget {
  final int condominioId;

  const DetalleCondominioScreen({super.key, required this.condominioId});

  @override
  ConsumerState<DetalleCondominioScreen> createState() =>
      _DetalleCondominioScreenState();
}

class _DetalleCondominioScreenState
    extends ConsumerState<DetalleCondominioScreen> {
  List<UsuarioAdmin> _admins = [];
  bool _loadingAdmins = true;

  @override
  void initState() {
    super.initState();
    _cargarAdmins();
  }

  Future<void> _cargarAdmins() async {
    setState(() => _loadingAdmins = true);
    try {
      final service = ref.read(condominioSaServiceProvider);
      final admins = await service.listarAdmins(widget.condominioId);
      setState(() {
        _admins = admins;
        _loadingAdmins = false;
      });
    } catch (e) {
      setState(() => _loadingAdmins = false);
    }
  }

  Future<void> _mostrarFormularioAdmin(BuildContext context) async {
    final nombreCtrl = TextEditingController();
    final usernameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    final apiClient = ref.read(apiClientProvider);
    final service = UsuarioAdminService(apiClient: apiClient);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Agregar Administrador'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreCtrl,
                decoration: const InputDecoration(
                    labelText: 'Nombre completo',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: usernameCtrl,
                decoration: const InputDecoration(
                    labelText: 'Username', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(
                    labelText: 'Email', border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passCtrl,
                decoration: const InputDecoration(
                    labelText: 'Contraseña', border: OutlineInputBorder()),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              try {
                await service.crearUsuario(CreateUsuarioRequest(
                  username: usernameCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  password: passCtrl.text,
                  nombreCompleto: nombreCtrl.text.trim(),
                  rol: 'ADMIN',
                  condominioId: widget.condominioId,
                  esPropietario: false,
                ));
                if (ctx.mounted) Navigator.pop(ctx);
                _cargarAdmins();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Administrador creado exitosamente')),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                        content: Text(e.toString()),
                        backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Crear Admin'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(condominioSaProvider);
    final condominio = state.condominios
        .where((c) => c.id == widget.condominioId)
        .firstOrNull;

    if (condominio == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Condominio')),
        body: const Center(child: Text('Condominio no encontrado')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(condominio.nombre),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              await context
                  .push('/home/condominios/${condominio.id}/editar');
              ref.read(condominioSaProvider.notifier).cargarCondominios();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(condominio.nombre,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                      ),
                      Chip(
                        label: Text(
                          condominio.activo ? 'ACTIVO' : 'INACTIVO',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11),
                        ),
                        backgroundColor:
                            condominio.activo ? Colors.green : Colors.grey,
                      ),
                    ],
                  ),
                  if (condominio.direccion != null) ...[
                    const SizedBox(height: 8),
                    Text(condominio.direccion!,
                        style: const TextStyle(color: Colors.grey)),
                  ],
                  const SizedBox(height: 8),
                  Text('${condominio.numUnidades} unidades habitacionales',
                      style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _InfoChip(
                          '${condominio.totalUsuarios} usuarios',
                          Colors.blue),
                      const SizedBox(width: 8),
                      _InfoChip(
                          '${condominio.totalAdmins} admins', Colors.indigo),
                    ],
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: state.isLoading
                        ? null
                        : () => ref
                            .read(condominioSaProvider.notifier)
                            .toggleActivo(condominio.id),
                    icon: Icon(condominio.activo
                        ? Icons.block
                        : Icons.check_circle_outline),
                    label: Text(
                        condominio.activo ? 'Desactivar' : 'Activar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          condominio.activo ? Colors.red : Colors.green,
                      side: BorderSide(
                          color: condominio.activo
                              ? Colors.red
                              : Colors.green),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Administradores',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              TextButton.icon(
                onPressed: () => _mostrarFormularioAdmin(context),
                icon: const Icon(Icons.add),
                label: const Text('Agregar Admin'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_loadingAdmins)
            const Center(child: CircularProgressIndicator())
          else if (_admins.isEmpty)
            const Text('Sin administradores asignados.',
                style: TextStyle(color: Colors.grey))
          else
            ..._admins.map((admin) => ListTile(
                  leading: CircleAvatar(
                    child: Text(admin.nombreCompleto[0].toUpperCase()),
                  ),
                  title: Text(admin.nombreCompleto),
                  subtitle: Text(admin.username),
                  trailing: Chip(
                    label: Text(
                      admin.activo ? 'ACTIVO' : 'INACTIVO',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 10),
                    ),
                    backgroundColor:
                        admin.activo ? Colors.green : Colors.grey,
                  ),
                )),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final Color color;

  const _InfoChip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label, style: TextStyle(color: color, fontSize: 12)),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color.withOpacity(0.3)),
    );
  }
}
