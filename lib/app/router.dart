import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/auth/presentation/providers/auth_notifier.dart';
import '../features/prop_snap/presentation/pages/prop_snap_page.dart';
import '../features/settings/presentation/pages/settings_page.dart';

class _AuthRouterNotifier extends ChangeNotifier {
  _AuthRouterNotifier(ProviderContainer container) {
    _sub = container.listen<AuthState>(authNotifierProvider, (_, __) => notifyListeners());
  }

  late final ProviderSubscription<AuthState> _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}

GoRouter createRouter(ProviderContainer container) {
  final notifier = _AuthRouterNotifier(container);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = container.read(authNotifierProvider);
      final isAuthenticated = authState is AuthAuthenticated;
      final isInitial = authState is AuthInitial;
      final isAuthRoute = state.matchedLocation == '/login' || state.matchedLocation == '/register';

      if (isInitial) return null;
      if (!isAuthenticated && !isAuthRoute) return '/login';
      if (isAuthenticated && isAuthRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),
      GoRoute(path: '/home', builder: (_, __) => const PropSnapPage()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsPage()),
    ],
  );
}
