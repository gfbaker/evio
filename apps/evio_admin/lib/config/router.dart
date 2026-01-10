import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../widgets/layout/admin_layout.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/reset_password_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/events/event_list_screen.dart';
import '../screens/events/event_detail_screen.dart';
import '../screens/events/event_form_screen.dart';
import '../screens/statistics/statistics_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/settings/users_screen.dart';
import '../screens/settings/sellers_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isLoggedIn = authState.valueOrNull?.session != null;
      final isAuthRoute =
          state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/register') ||
          state.matchedLocation.startsWith('/reset-password');

      if (!isLoggedIn && !isAuthRoute) {
        return '/login';
      }

      if (isLoggedIn && isAuthRoute) {
        return '/admin/dashboard';
      }

      return null;
    },
    routes: [
      // Auth routes
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) => NoTransitionPage(child: LoginScreen()),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        pageBuilder: (context, state) =>
            NoTransitionPage(child: RegisterScreen()),
      ),
      GoRoute(
        path: '/reset-password',
        name: 'reset-password',
        pageBuilder: (context, state) =>
            NoTransitionPage(child: ResetPasswordScreen()),
      ),

      // Root redirects
      GoRoute(path: '/', redirect: (context, state) => '/admin/dashboard'),
      GoRoute(path: '/admin', redirect: (context, state) => '/admin/dashboard'),

      // Admin routes
      ShellRoute(
        builder: (context, state, child) => AdminLayout(child: child),
        routes: [
          GoRoute(
            path: '/admin/dashboard',
            name: 'dashboard',
            pageBuilder: (context, state) =>
                NoTransitionPage(child: const DashboardScreen()),
          ),
          GoRoute(
            path: '/admin/events',
            name: 'events',
            pageBuilder: (context, state) =>
                NoTransitionPage(child: EventListScreen()),
          ),
          GoRoute(
            path: '/admin/events/new',
            name: 'event-new',
            pageBuilder: (context, state) =>
                NoTransitionPage(child: EventFormScreen()),
          ),
          GoRoute(
            path: '/admin/events/:id',
            name: 'event-detail',
            pageBuilder: (context, state) => NoTransitionPage(
              child: EventDetailScreen(eventId: state.pathParameters['id']!),
            ),
          ),
          GoRoute(
            path: '/admin/events/:id/edit',
            name: 'event-edit',
            pageBuilder: (context, state) => NoTransitionPage(
              child: EventFormScreen(eventId: state.pathParameters['id']!),
            ),
          ),
          GoRoute(
            path: '/admin/statistics',
            name: 'statistics',
            pageBuilder: (context, state) =>
                NoTransitionPage(child: StatisticsScreen()),
          ),
          GoRoute(
            path: '/admin/settings',
            name: 'settings',
            pageBuilder: (context, state) =>
                NoTransitionPage(child: SettingsScreen()),
          ),
          GoRoute(
            path: '/admin/team/collaborators',
            name: 'team-collaborators',
            pageBuilder: (context, state) =>
                NoTransitionPage(child: const UsersScreen()),
          ),
          GoRoute(
            path: '/admin/team/sellers',
            name: 'team-sellers',
            pageBuilder: (context, state) =>
                NoTransitionPage(child: const SellersScreen()),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error 404',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text('Ruta no encontrada: ${state.uri}'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/admin/dashboard'),
              child: const Text('Volver al Dashboard'),
            ),
          ],
        ),
      ),
    ),
  );

  // Listen to auth changes and refresh router
  ref.listen(authStateProvider, (_, __) {
    router.refresh();
  });

  return router;
});
