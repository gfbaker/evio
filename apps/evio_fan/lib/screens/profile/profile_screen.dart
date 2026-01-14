import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evio_core/evio_core.dart';
import '../../providers/auth_provider.dart';
import 'tabs/guardados_tab.dart';
import 'tabs/social_tab.dart';
import 'tabs/collectibles_tab.dart';
import 'tabs/config_tab.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    return currentUser.when(
      data: (user) {
        if (user == null) return _buildNoSessionState();
        return _buildContent(user);
      },
      loading: () => Scaffold(
        body: Container(
          decoration: EvioBackgrounds.screenBackground(EvioFanColors.background),
          child: Center(
            child: CircularProgressIndicator(color: EvioFanColors.primary),
          ),
        ),
      ),
      error: (e, st) => _buildNoSessionState(),
    );
  }

  Widget _buildContent(User user) {
    return Scaffold(
      backgroundColor: Colors.transparent, // ⚡ Forzar transparente
      body: Container(
        decoration: EvioBackgrounds.screenBackground(EvioFanColors.background),
        child: Stack(
          children: [
            // Background gradient
            _buildBackgroundGradient(),

            // Main content
            Column(
              children: [
                _buildTabBar(),
                Expanded(
                  child: Material(
                    type: MaterialType.transparency, // ⚡ FIX: Forzar transparencia
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        const GuardadosTab(),
                        const SocialTab(),
                        const CollectiblesTab(),
                        ConfigTab(user: user),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundGradient() {
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned(
            top: -350,
            left: -100,
            right: -100,
            child: Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 1.8,
                height: MediaQuery.of(context).size.width * 1.8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      EvioFanColors.primary.withValues(alpha: 0.35),
                      EvioFanColors.primary.withValues(alpha: 0.25),
                      EvioFanColors.primary.withValues(alpha: 0.15),
                      EvioFanColors.primary.withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.2, 0.4, 0.6, 1.0],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + EvioSpacing.md,
        left: EvioSpacing.lg,
        right: EvioSpacing.lg,
        bottom: EvioSpacing.md,
      ),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: EvioFanColors.surface,
          borderRadius: BorderRadius.circular(EvioRadius.button + 2),
          border: Border.all(
            color: EvioFanColors.border.withValues(alpha: 0.5),
          ),
        ),
        child: TabBar(
          controller: _tabController,
          labelColor: EvioFanColors.primaryForeground,
          unselectedLabelColor: EvioFanColors.mutedForeground,
          indicator: BoxDecoration(
            color: EvioFanColors.primary,
            borderRadius: BorderRadius.circular(EvioRadius.button),
            boxShadow: [
              BoxShadow(
                color: EvioFanColors.primary.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelStyle: EvioTypography.labelMedium.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: EvioTypography.labelMedium.copyWith(fontSize: 12),
          splashFactory: NoSplash.splashFactory,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          tabs: const [
            Tab(text: 'Guardado'),
            Tab(text: 'Social'),
            Tab(text: 'Totems'),
            Tab(text: 'Config'),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSessionState() {
    return Scaffold(
      body: Container(
        decoration: EvioBackgrounds.screenBackground(EvioFanColors.background),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_off_outlined,
                size: 64,
                color: EvioFanColors.mutedForeground,
              ),
              SizedBox(height: EvioSpacing.lg),
              Text(
                'No hay sesión activa',
                style: EvioTypography.h4.copyWith(
                  color: EvioFanColors.foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
