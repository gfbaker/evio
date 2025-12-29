import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:evio_core/evio_core.dart';

import '../../providers/auth_provider.dart';

class AdminSidebar extends ConsumerWidget {
  const AdminSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocation = GoRouterState.of(context).uri.toString();
    final userAsync = ref.watch(currentUserProvider);

    return Container(
      width: EvioSpacing.sidebarWidth,
      decoration: BoxDecoration(
        color: EvioLightColors.sidebar,
        border: Border(
          right: BorderSide(color: EvioLightColors.sidebarBorder, width: 1),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: EvioSpacing.md,
                vertical: EvioSpacing.lg,
              ),
              children: [
                _buildSectionTitle('MENÚ PRINCIPAL'),
                SizedBox(height: EvioSpacing.md),

                _buildMenuItem(
                  context,
                  icon: Icons.calendar_today,
                  label: 'Eventos',
                  route: '/admin/dashboard',
                  isActive: currentLocation.startsWith('/admin/dashboard'),
                ),
                SizedBox(height: EvioSpacing.xs),

                _buildMenuItem(
                  context,
                  icon: Icons.add,
                  label: 'Crear Evento',
                  route: '/admin/events/new',
                  isActive: currentLocation == '/admin/events/new',
                ),

                SizedBox(height: EvioSpacing.xxl),

                _buildSectionTitle('HERRAMIENTAS'),
                SizedBox(height: EvioSpacing.md),

                _buildMenuItem(
                  context,
                  icon: Icons.bar_chart,
                  label: 'Estadísticas',
                  route: '/admin/statistics',
                  isActive: currentLocation.startsWith('/admin/statistics'),
                ),
                SizedBox(height: EvioSpacing.xs),

                _buildMenuItem(
                  context,
                  icon: Icons.settings,
                  label: 'Configuración',
                  route: '/admin/settings',
                  isActive: currentLocation.startsWith('/admin/settings'),
                ),
              ],
            ),
          ),
          _buildFooter(context, ref, userAsync),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(EvioSpacing.lg),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: EvioLightColors.sidebarBorder, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: EvioLightColors.primary,
              borderRadius: BorderRadius.circular(EvioRadius.lg),
            ),
            child: Icon(
              Icons.music_note,
              color: EvioLightColors.primaryForeground,
              size: 20,
            ),
          ),
          SizedBox(width: EvioSpacing.sm),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'EventPulse',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: EvioLightColors.textPrimary,
                    height: 1.5,
                  ),
                ),
                Text(
                  'Electronic Events',
                  style: TextStyle(
                    fontSize: 12.25,
                    fontWeight: FontWeight.w400,
                    color: EvioLightColors.mutedForeground,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(left: EvioSpacing.sm, bottom: EvioSpacing.md),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w500,
          color: EvioLightColors.mutedForeground,
          height: 1.5,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
    required bool isActive,
  }) {
    final backgroundColor = isActive
        ? EvioLightColors.secondary
        : Colors.transparent;

    final foregroundColor = isActive
        ? EvioLightColors.secondaryForeground
        : EvioLightColors.textPrimary;

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(EvioRadius.lg),
      child: InkWell(
        onTap: () => context.go(route),
        borderRadius: BorderRadius.circular(EvioRadius.lg),
        hoverColor: EvioLightColors.sidebarAccent,
        child: Container(
          height: 40,
          padding: EdgeInsets.symmetric(
            horizontal: EvioSpacing.sm,
            vertical: 10,
          ),
          child: Row(
            children: [
              Icon(icon, size: EvioSpacing.iconS, color: foregroundColor),
              SizedBox(width: EvioSpacing.sm),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                  color: foregroundColor,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<User?> userAsync,
  ) {
    return Container(
      padding: EdgeInsets.all(EvioSpacing.md),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: EvioLightColors.sidebarBorder, width: 1),
        ),
      ),
      child: Column(
        children: [
          // User info
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: EvioLightColors.muted,
                child: userAsync.when(
                  data: (user) => Text(
                    user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: EvioLightColors.mutedForeground,
                    ),
                  ),
                  loading: () => SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (_, __) => Icon(Icons.person, size: 16),
                ),
              ),
              SizedBox(width: EvioSpacing.sm),

              Expanded(
                child: userAsync.when(
                  data: (user) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        user?.email ?? 'Usuario',
                        style: TextStyle(
                          fontSize: 12.25,
                          fontWeight: FontWeight.w400,
                          color: EvioLightColors.textPrimary,
                          height: 1.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        user?.email ?? '',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w400,
                          color: EvioLightColors.mutedForeground,
                          height: 1.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  loading: () => Text('Cargando...'),
                  error: (_, __) => Text('Error'),
                ),
              ),
            ],
          ),

          SizedBox(height: EvioSpacing.sm),

          // Logout button
          SizedBox(
            width: double.infinity,
            height: 36,
            child: OutlinedButton.icon(
              onPressed: () async {
                try {
                  await ref.read(authControllerProvider).signOut();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al cerrar sesión: $e'),
                        backgroundColor: EvioLightColors.destructive,
                      ),
                    );
                  }
                }
              },
              icon: Icon(Icons.logout, size: 16),
              label: Text('Cerrar sesión'),
              style: OutlinedButton.styleFrom(
                foregroundColor: EvioLightColors.destructive,
                side: BorderSide(color: EvioLightColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(EvioRadius.button),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
