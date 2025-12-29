import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evio_core/evio_core.dart';
import '../../providers/auth_provider.dart';
import 'profile_screen.dart';
import 'company_screen.dart';
import 'users_screen.dart';

enum SettingsView { quickAccess, profile, company, users }

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  SettingsView _currentView = SettingsView.quickAccess;

  void _navigateTo(SettingsView view) {
    setState(() => _currentView = view);
  }

  void _navigateBack() {
    setState(() => _currentView = SettingsView.quickAccess);
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: EvioLightColors.background,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: userAsync.when(
              data: (user) {
                if (user == null) {
                  return const Center(child: Text('No autenticado'));
                }
                return _buildContent(context, user);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final showBackButton = _currentView != SettingsView.quickAccess;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: EvioGradients.headerGradient,
        border: const Border(bottom: BorderSide(color: EvioLightColors.border)),
      ),
      child: Row(
        children: [
          if (showBackButton)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _navigateBack,
                tooltip: 'Volver',
              ),
            ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: EvioLightColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.settings,
              size: 32,
              color: EvioLightColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getViewTitle(),
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getViewSubtitle(),
                  style: const TextStyle(
                    color: EvioLightColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getViewTitle() {
    switch (_currentView) {
      case SettingsView.quickAccess:
        return 'Configuración';
      case SettingsView.profile:
        return 'Mi Perfil';
      case SettingsView.company:
        return 'Mi Productora';
      case SettingsView.users:
        return 'Usuarios';
    }
  }

  String _getViewSubtitle() {
    switch (_currentView) {
      case SettingsView.quickAccess:
        return 'Gestiona tu cuenta y preferencias';
      case SettingsView.profile:
        return 'Información personal';
      case SettingsView.company:
        return 'Datos de la empresa';
      case SettingsView.users:
        return 'Gestionar equipo';
    }
  }

  Widget _buildContent(BuildContext context, User user) {
    switch (_currentView) {
      case SettingsView.quickAccess:
        return _buildQuickAccess(context, user);
      case SettingsView.profile:
        return const ProfileScreen();
      case SettingsView.company:
        return _buildCompanyView();
      case SettingsView.users:
        return _buildUsersView();
    }
  }

  Widget _buildQuickAccess(BuildContext context, User user) {
    final isAdmin = user.isAdmin;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Acceso Rápido',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 900;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: isDesktop
                        ? (constraints.maxWidth - 32) / 3
                        : double.infinity,
                    child: _QuickAccessCard(
                      icon: Icons.person,
                      title: 'Mi Perfil',
                      subtitle: 'Información personal',
                      onTap: () => _navigateTo(SettingsView.profile),
                    ),
                  ),
                  if (isAdmin) ...[
                    SizedBox(
                      width: isDesktop
                          ? (constraints.maxWidth - 32) / 3
                          : double.infinity,
                      child: _QuickAccessCard(
                        icon: Icons.business,
                        title: 'Mi Productora',
                        subtitle: 'Datos de la empresa',
                        onTap: () => _navigateTo(SettingsView.company),
                      ),
                    ),
                    SizedBox(
                      width: isDesktop
                          ? (constraints.maxWidth - 32) / 3
                          : double.infinity,
                      child: _QuickAccessCard(
                        icon: Icons.people,
                        title: 'Usuarios',
                        subtitle: 'Gestionar equipo',
                        onTap: () => _navigateTo(SettingsView.users),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyView() {
    return const CompanyScreen();
  }

  Widget _buildUsersView() {
    return const UsersScreen();
  }
}

class _QuickAccessCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickAccessCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<_QuickAccessCard> createState() => _QuickAccessCardState();
}

class _QuickAccessCardState extends State<_QuickAccessCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: EvioLightColors.border, width: 1),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: EvioLightColors.muted,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  widget.icon,
                  size: 24,
                  color: EvioLightColors.mutedForeground,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: EvioLightColors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: EvioLightColors.mutedForeground,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
