import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/areas/providers/area_comun_provider.dart';
import '../../features/areas/screens/crear_editar_area_screen.dart';
import '../../features/areas/screens/disponibilidad_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/incidentes/screens/categorias_screen.dart';
import '../../features/incidentes/screens/crear_incidente_screen.dart';
import '../../features/incidentes/screens/detalle_incidente_screen.dart';
import '../../features/notificaciones/screens/crear_notificacion_screen.dart';
import '../../features/notificaciones/screens/detalle_notificacion_screen.dart';
import '../../features/pagos/screens/crear_cuota_screen.dart';
import '../../features/pagos/screens/detalle_cuota_screen.dart';
import '../../features/pagos/screens/reportar_pago_screen.dart';
import '../../features/paquetes/screens/registrar_paquete_screen.dart';
import '../../features/superadmin/providers/condominio_sa_provider.dart';
import '../../features/superadmin/screens/crear_editar_condominio_screen.dart';
import '../../features/superadmin/screens/detalle_condominio_screen.dart';
import '../../features/usuarios/screens/crear_usuario_screen.dart';
import '../../features/usuarios/screens/detalle_usuario_screen.dart';
import '../../features/visitas/screens/detalle_visita_screen.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/widgets/main_scaffold.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      final isAuthenticated = authState.isAuthenticated;
      final isSplash = state.matchedLocation == '/splash';
      final isLogin = state.matchedLocation == '/login';
      if (isLoading) return isSplash ? null : '/splash';
      if (!isAuthenticated) return isLogin ? null : '/login';
      if (isSplash || isLogin) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: '/home',
        builder: (_, __) => const MainScaffold(),
        routes: [
          // Visitas
          GoRoute(
            path: 'visitas/:id',
            builder: (context, state) => DetalleVisitaScreen(
                visitaId: int.parse(state.pathParameters['id']!)),
          ),
          // Usuarios
          GoRoute(
            path: 'usuarios/nuevo',
            builder: (_, __) => const CrearUsuarioScreen(),
          ),
          GoRoute(
            path: 'usuarios/:id',
            builder: (context, state) => DetalleUsuarioScreen(
                usuarioId: int.parse(state.pathParameters['id']!)),
          ),
          // Cuotas
          GoRoute(
            path: 'cuotas/nueva',
            builder: (_, __) => const CrearCuotaScreen(),
          ),
          GoRoute(
            path: 'cuotas/:id/detalle',
            builder: (context, state) => DetalleCuotaScreen(
                cuotaId: int.parse(state.pathParameters['id']!)),
          ),
          GoRoute(
            path: 'cuotas/:id/reportar',
            builder: (context, state) => ReportarPagoScreen(
                cuotaUsuarioId: int.parse(state.pathParameters['id']!)),
          ),
          // Paquetes
          GoRoute(
            path: 'paquetes/nuevo',
            builder: (_, __) => const RegistrarPaqueteScreen(),
          ),
          // Incidentes
          GoRoute(
            path: 'incidentes/categorias',
            builder: (_, __) => const CategoriasScreen(),
          ),
          GoRoute(
            path: 'incidentes/nuevo',
            builder: (_, __) => const CrearIncidenteScreen(),
          ),
          GoRoute(
            path: 'incidentes/:id',
            builder: (context, state) => DetalleIncidenteScreen(
                incidenteId: int.parse(state.pathParameters['id']!)),
          ),
          // Notificaciones
          GoRoute(
            path: 'notificaciones/nueva',
            builder: (_, __) => const CrearNotificacionScreen(),
          ),
          GoRoute(
            path: 'notificaciones/:id',
            builder: (context, state) => DetalleNotificacionScreen(
                notificacionId: int.parse(state.pathParameters['id']!)),
          ),
          // Áreas
          GoRoute(
            path: 'areas/nueva',
            builder: (_, __) => const CrearEditarAreaScreen(),
          ),
          GoRoute(
            path: 'areas/:id/editar',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              final area = ref
                  .read(areaComunProvider)
                  .areas
                  .where((a) => a.id == id)
                  .firstOrNull;
              return CrearEditarAreaScreen(area: area);
            },
          ),
          GoRoute(
            path: 'areas/:id/disponibilidad',
            builder: (context, state) => DisponibilidadScreen(
                areaComunId: int.parse(state.pathParameters['id']!)),
          ),
          // Condominios (SUPERADMIN)
          GoRoute(
            path: 'condominios/nuevo',
            builder: (_, __) => const CrearEditarCondominioScreen(),
          ),
          GoRoute(
            path: 'condominios/:id/editar',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              final condominio = ref
                  .read(condominioSaProvider)
                  .condominios
                  .where((c) => c.id == id)
                  .firstOrNull;
              return CrearEditarCondominioScreen(condominio: condominio);
            },
          ),
          GoRoute(
            path: 'condominios/:id/detalle',
            builder: (context, state) => DetalleCondominioScreen(
                condominioId: int.parse(state.pathParameters['id']!)),
          ),
        ],
      ),
    ],
  );
});
