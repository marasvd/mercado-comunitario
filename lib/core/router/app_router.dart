import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/domain/auth_models.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/jornadas/presentation/screens/jornada_activa_screen.dart';
import '../../features/jornadas/presentation/screens/jornada_detalle_screen.dart';

// ---------------------------------------------------------------------------
// RouterNotifier — puente entre Riverpod y GoRouter.refreshListenable
// ---------------------------------------------------------------------------

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    ref.listen<AsyncValue<AppUser?>>(
      authNotifierProvider,
      (_, _) => notifyListeners(),
    );
  }
}

final _routerNotifierProvider = Provider<_RouterNotifier>((ref) {
  return _RouterNotifier(ref);
});

// ---------------------------------------------------------------------------
// Routes
// ---------------------------------------------------------------------------

const _loginPath = '/login';
const _adminPath = '/admin';
const _asistentePath = '/asistente';
const _beneficiarioPath = '/beneficiario';

// ---------------------------------------------------------------------------
// Router principal
// ---------------------------------------------------------------------------

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(_routerNotifierProvider);

  return GoRouter(
    initialLocation: _loginPath,
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);

      // Mientras carga la sesión inicial, no redirigir
      if (authState.isLoading) return null;

      final user = authState.valueOrNull;
      final isAtLogin = state.matchedLocation == _loginPath;

      // Sin sesión → siempre al login
      if (user == null && !isAtLogin) return _loginPath;

      // Con sesión en login → redirigir a pantalla del rol
      if (user != null && isAtLogin) {
        return _homeForRole(user.role);
      }

      // Proteger rutas por rol
      if (user != null) {
        final loc = state.matchedLocation;
        if (loc.startsWith(_adminPath) && !user.isAdmin) {
          return _homeForRole(user.role);
        }
        if (loc.startsWith(_asistentePath) && !user.hasAdminAccess) {
          return _homeForRole(user.role);
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: _loginPath,
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: _adminPath,
        builder: (_, _) => const _PlaceholderScreen(title: 'Panel Admin'),
      ),
      GoRoute(
        path: _asistentePath,
        builder: (_, _) => const _PlaceholderScreen(title: 'Panel Asistente'),
      ),
      GoRoute(
        path: _beneficiarioPath,
        builder: (_, _) => const JornadaActivaScreen(),
        routes: [
          GoRoute(
            path: 'jornada/:jornadaId',
            builder: (_, state) => JornadaDetalleScreen(
              jornadaId: state.pathParameters['jornadaId']!,
              jornadaNombre:
                  state.uri.queryParameters['nombre'] ?? 'Jornada',
            ),
          ),
        ],
      ),
    ],
  );
});

String _homeForRole(String role) {
  return switch (role) {
    'ADMINISTRADOR' => _adminPath,
    'ASISTENTE' => _asistentePath,
    'BENEFICIARIO' => _beneficiarioPath,
    _ => _loginPath,
  };
}

// ---------------------------------------------------------------------------
// Placeholder — se reemplaza en fases posteriores
// ---------------------------------------------------------------------------

class _PlaceholderScreen extends ConsumerWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () =>
                ref.read(authNotifierProvider.notifier).signOut(),
          ),
        ],
      ),
      body: Center(
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}
