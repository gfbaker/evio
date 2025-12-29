import 'package:evio_fan/screens/tickets/ticket_detail_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../screens/home/home_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/tickets/tickets_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/event_detail/event_detail_screen.dart';
import '../screens/checkout/checkout_screen.dart';
import '../widgets/layout/fan_layout.dart';
import '../providers/order_provider.dart';

// ✅ Convertir a provider para acceder al cart
final fanRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      // Shell route con bottom nav persistente
      ShellRoute(
        builder: (context, state, child) {
          return FanLayout(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            pageBuilder: (context, state) =>
                NoTransitionPage(key: state.pageKey, child: const HomeScreen()),
          ),
          GoRoute(
            path: '/search',
            name: 'search',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const SearchScreen(),
            ),
          ),
          GoRoute(
            path: '/tickets',
            name: 'tickets',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const TicketsScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const ProfileScreen(),
            ),
          ),
        ],
      ),

      // Event Detail (sin bottom nav, full screen)
      GoRoute(
        path: '/event/:id',
        name: 'event-detail',
        builder: (context, state) {
          final eventId = state.pathParameters['id']!;
          return EventDetailScreen(eventId: eventId);
        },
      ),

      // Checkout (sin bottom nav, full screen)
      GoRoute(
        path: '/checkout',
        name: 'checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),

      GoRoute(
        path: '/ticket-detail/:eventId', // ← Cambié ticketId por eventId
        builder: (context, state) {
          final eventId = state.pathParameters['eventId']!;
          return TicketDetailScreen(eventId: eventId);
        },
      ),
      // Auth routes (sin bottom nav)
      GoRoute(
        path: '/auth/login',
        name: 'login',
        builder: (context, state) {
          // ✅ Leer el query parameter 'redirect'
          final redirectTo = state.uri.queryParameters['redirect'];

          return LoginScreen(
            onRegisterTap: () {
              // ✅ Pasar el redirect al registro también
              if (redirectTo != null) {
                context.go('/auth/register?redirect=$redirectTo');
              } else {
                context.go('/auth/register');
              }
            },
            onLoginSuccess: () {
              // ✅ Si hay redirectTo, ir ahí. Sino, verificar cart o ir a home
              if (redirectTo != null && redirectTo.isNotEmpty) {
                context.pushReplacement(redirectTo);
              } else {
                // Fallback: verificar cart (caso legacy)
                final cart = ref.read(cartProvider);
                if (cart.eventId != null && cart.items.isNotEmpty) {
                  context.pushReplacement('/checkout');
                } else {
                  context.go('/home');
                }
              }
            },
          );
        },
      ),
      GoRoute(
        path: '/auth/register',
        name: 'register',
        builder: (context, state) {
          // ✅ Leer el query parameter 'redirect'
          final redirectTo = state.uri.queryParameters['redirect'];

          return RegisterScreen(
            onLoginTap: () {
              // ✅ Pasar el redirect al login también
              if (redirectTo != null) {
                context.go('/auth/login?redirect=$redirectTo');
              } else {
                context.go('/auth/login');
              }
            },
            onRegisterSuccess: () {
              // ✅ Si hay redirectTo, ir ahí. Sino, verificar cart o ir a home
              if (redirectTo != null && redirectTo.isNotEmpty) {
                context.pushReplacement(redirectTo);
              } else {
                // Fallback: verificar cart (caso legacy)
                final cart = ref.read(cartProvider);
                if (cart.eventId != null && cart.items.isNotEmpty) {
                  context.pushReplacement('/checkout');
                } else {
                  context.go('/home');
                }
              }
            },
          );
        },
      ),
    ],
  );
});
