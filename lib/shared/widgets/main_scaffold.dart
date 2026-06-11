import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/areas/providers/area_comun_provider.dart';
import '../../features/areas/providers/reservacion_provider.dart';
import '../../features/areas/screens/areas_screen.dart';
import '../../features/incidentes/providers/incidente_provider.dart';
import '../../features/incidentes/screens/incidentes_screen.dart';
import '../../features/notificaciones/providers/notificacion_provider.dart';
import '../../features/notificaciones/screens/notificaciones_screen.dart';
import '../../features/pagos/providers/cuota_provider.dart';
import '../../features/pagos/screens/cuotas_admin_screen.dart';
import '../../features/pagos/screens/mis_cuotas_screen.dart';
import '../../features/paquetes/providers/paquete_provider.dart';
import '../../features/paquetes/screens/paquetes_screen.dart';
import '../../features/usuarios/screens/gestion_screen.dart';
import '../../features/perfil/screens/perfil_screen.dart';
import '../../features/visitas/providers/visita_provider.dart';
import '../../features/visitas/screens/crear_visita_screen.dart';
import '../../features/visitas/screens/dashboard_admin_screen.dart';
import '../../features/visitas/screens/escanear_qr_screen.dart';
import '../../features/visitas/screens/inicio_usuario_screen.dart';
import '../../features/visitas/screens/mis_visitas_screen.dart';
import '../../features/visitas/screens/visitas_admin_screen.dart';
import '../models/usuario.dart';
import '../providers/auth_provider.dart';

class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialData());
  }

  void _loadInitialData() {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    final visitaNotifier = ref.read(visitaProvider.notifier);
    final cuotaNotifier = ref.read(cuotaProvider.notifier);
    final paqueteNotifier = ref.read(paqueteProvider.notifier);
    final incidenteNotifier = ref.read(incidenteProvider.notifier);
    final notificacionNotifier = ref.read(notificacionProvider.notifier);
    final areaNotifier = ref.read(areaComunProvider.notifier);
    switch (user.rol) {
      case Rol.usuario:
        visitaNotifier.cargarMisVisitas();
        cuotaNotifier.cargarMisCuotas();
        paqueteNotifier.cargarMisPaquetes();
        incidenteNotifier.cargarMisIncidentes();
        notificacionNotifier.cargarNotificaciones();
        areaNotifier.cargarAreas();
        ref.read(reservacionProvider.notifier).cargarMisReservaciones();
      case Rol.guardia:
        visitaNotifier.cargarTodasVisitas();
        paqueteNotifier.cargarPaquetes();
        notificacionNotifier.cargarNotificaciones();
      case Rol.admin:
      case Rol.superadmin:
        visitaNotifier.cargarTodasVisitas();
        cuotaNotifier.cargarCuotas();
        paqueteNotifier.cargarPaquetes();
        incidenteNotifier.cargarIncidentes();
        notificacionNotifier.cargarNotificaciones();
        areaNotifier.cargarAreas();
    }
  }

  List<Widget> _buildScreens(Rol rol) {
    return switch (rol) {
      Rol.usuario => [
          const InicioUsuarioScreen(),
          const MisVisitasScreen(),
          const CrearVisitaScreen(),
          const PaquetesScreen(),
          const IncidentesScreen(),
          const MisCuotasScreen(),
          const AreasScreen(),
          const NotificacionesScreen(),
          const PerfilScreen(),
        ],
      Rol.guardia => [
          const EscanearQrScreen(),
          const PaquetesScreen(),
          const VisitasAdminScreen(filterToday: true),
          const VisitasAdminScreen(filterToday: false),
          const NotificacionesScreen(),
          const PerfilScreen(),
        ],
      Rol.admin || Rol.superadmin => [
          const DashboardAdminScreen(),
          const VisitasAdminScreen(filterToday: false),
          const PaquetesScreen(),
          const IncidentesScreen(),
          const GestionScreen(),
          const CuotasAdminScreen(),
          const AreasScreen(),
          const NotificacionesScreen(),
          const PerfilScreen(),
        ],
    };
  }

  List<BottomNavigationBarItem> _buildItems(Rol rol) {
    return switch (rol) {
      Rol.usuario => const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Visitas'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Nueva'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), label: 'Paquetes'),
          BottomNavigationBarItem(icon: Icon(Icons.report_outlined), label: 'Incidentes'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Cuotas'),
          BottomNavigationBarItem(icon: Icon(Icons.meeting_room_outlined), label: 'Áreas'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), label: 'Avisos'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Perfil'),
        ],
      Rol.guardia => const [
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: 'Escanear'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), label: 'Paquetes'),
          BottomNavigationBarItem(icon: Icon(Icons.today), label: 'Hoy'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Historial'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), label: 'Avisos'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Perfil'),
        ],
      Rol.admin || Rol.superadmin => const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Visitas'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), label: 'Paquetes'),
          BottomNavigationBarItem(icon: Icon(Icons.report_outlined), label: 'Incidentes'),
          BottomNavigationBarItem(icon: Icon(Icons.manage_accounts), label: 'Gestión'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Cuotas'),
          BottomNavigationBarItem(icon: Icon(Icons.meeting_room_outlined), label: 'Áreas'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), label: 'Avisos'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Perfil'),
        ],
    };
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    if (user == null) return const SizedBox.shrink();
    final screens = _buildScreens(user.rol);
    final items = _buildItems(user.rol);
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: items,
      ),
    );
  }
}
