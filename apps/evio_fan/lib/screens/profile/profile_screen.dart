import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:evio_core/evio_core.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/saved_event_provider.dart';
import '../../providers/follow_provider.dart';
import '../../widgets/cached_event_image.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    // 4 tabs ahora (Guardados, Coleccionables, Social, Config)
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    return currentUser.when(
      data: (user) {
        if (user == null) {
          return _buildNoSessionState();
        }
        return _buildContent(user);
      },
      loading: () => Scaffold(
        body: Container(
          decoration: EvioBackgrounds.screenBackground(
            EvioFanColors.background,
          ),
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
      body: Container(
        decoration: EvioBackgrounds.screenBackground(EvioFanColors.background),
        child: Column(
          children: [
            // ✅ HEADER FIJO (no hace scroll)
            _buildFixedHeader(user),

            // ✅ TABS FIJOS
            _buildFixedTabBar(),

            // ✅ BODY CON SCROLL
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildGuardadosTab(),
                  _buildColeccionablesTab(),
                  _buildSocialTab(),
                  _buildConfigTab(user), // Ahora incluye datos personales
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // HEADER FIJO
  // ============================================

  Widget _buildFixedHeader(User user) {
    return Container(
      color: EvioFanColors.background,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            EvioSpacing.xl,
            EvioSpacing.lg,
            EvioSpacing.xl,
            EvioSpacing.lg,
          ),
          child: Column(
            children: [
              // Avatar
              GestureDetector(
                onTap: () => _showAvatarOptions(user),
                child: Stack(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            EvioFanColors.primary.withValues(alpha: 0.3),
                            EvioFanColors.primary.withValues(alpha: 0.1),
                          ],
                        ),
                      ),
                      child:
                          user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                          ? ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: user.avatarUrl!,
                                fit: BoxFit.cover,
                                width: 90,
                                height: 90,
                                placeholder: (context, url) => Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: EvioFanColors.primary,
                                  ),
                                ),
                                errorWidget: (context, url, error) => Icon(
                                  Icons.person_rounded,
                                  size: 45,
                                  color: EvioFanColors.mutedForeground,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.person_rounded,
                              size: 45,
                              color: EvioFanColors.primary,
                            ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: EvioFanColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: EvioFanColors.background,
                            width: 2.5,
                          ),
                        ),
                        child: Icon(
                          Icons.camera_alt,
                          size: 14,
                          color: EvioFanColors.primaryForeground,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: EvioSpacing.md),

              // Nombre
              Text(
                user.fullName,
                style: EvioTypography.h2.copyWith(
                  color: EvioFanColors.foreground,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: EvioSpacing.xxs),

              // Email
              Text(
                user.email,
                style: EvioTypography.bodySmall.copyWith(
                  color: EvioFanColors.mutedForeground,
                ),
              ),
              SizedBox(height: EvioSpacing.lg),

              // ✅ Stats Row (MEJORADOS)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildModernStatItem(
                    icon: Icons.notifications_none,
                    value: '3',
                    label: 'Notif',
                    onTap: () {
                      // TODO: Navigate to notifications
                    },
                  ),
                  _buildModernStatItem(
                    icon: Icons.emoji_events_outlined,
                    value: '5',
                    label: 'Totems',
                    onTap: () {
                      _tabController.animateTo(0);
                    },
                  ),
                  _buildModernStatItem(
                    icon: Icons.people_outline,
                    value: '24',
                    label: 'Amigos',
                    onTap: () {
                      _tabController.animateTo(1);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ STATS MODERNOS (con containers y mejor diseño)
  Widget _buildModernStatItem({
    required IconData icon,
    required String value,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: EvioSpacing.lg,
          vertical: EvioSpacing.md,
        ),
        decoration: BoxDecoration(
          color: EvioFanColors.surface,
          borderRadius: BorderRadius.circular(EvioRadius.button),
          border: Border.all(color: EvioFanColors.border, width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: EvioFanColors.primary, size: 24),
            SizedBox(height: EvioSpacing.xxs),
            Text(
              value,
              style: EvioTypography.h4.copyWith(
                color: EvioFanColors.foreground,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: EvioTypography.labelSmall.copyWith(
                color: EvioFanColors.mutedForeground,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // TABS FIJOS (MEJORADOS)
  // ============================================

  Widget _buildFixedTabBar() {
    return Container(
      color: EvioFanColors.background,
      padding: EdgeInsets.symmetric(horizontal: EvioSpacing.md),
      child: TabBar(
        controller: _tabController,
        labelColor: EvioFanColors.primary,
        unselectedLabelColor: EvioFanColors.mutedForeground,
        indicatorColor: EvioFanColors.primary,
        indicatorWeight: 3,
        labelStyle: EvioTypography.labelMedium.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        unselectedLabelStyle: EvioTypography.labelMedium.copyWith(fontSize: 14),
        // ✅ Sin isScrollable para que las palabras se vean completas
        isScrollable: false,
        tabs: const [
          Tab(text: 'Guardados'),
          Tab(text: 'Totems'),
          Tab(text: 'Social'),
          Tab(text: 'Config'),
        ],
      ),
    );
  }

  // ============================================
  // TAB: GUARDADOS
  // ============================================

  Widget _buildGuardadosTab() {
    final savedEventsAsync = ref.watch(savedEventsProvider);

    return savedEventsAsync.when(
      data: (events) {
        if (events.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(EvioSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(EvioSpacing.xl),
                    decoration: BoxDecoration(
                      color: EvioFanColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.bookmark_border,
                      size: 64,
                      color: EvioFanColors.primary,
                    ),
                  ),
                  SizedBox(height: EvioSpacing.xl),
                  Text(
                    'Sin eventos guardados',
                    style: EvioTypography.h3.copyWith(
                      color: EvioFanColors.foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: EvioSpacing.sm),
                  Text(
                    'Guardá tus eventos favoritos\npara verlos rápidamente aquí',
                    style: EvioTypography.bodyMedium.copyWith(
                      color: EvioFanColors.mutedForeground,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: EdgeInsets.all(EvioSpacing.lg),
          itemCount: events.length,
          separatorBuilder: (context, index) => SizedBox(height: EvioSpacing.md),
          itemBuilder: (context, index) {
            final event = events[index];
            return _SavedEventCard(event: event);
          },
        );
      },
      loading: () => Center(
        child: CircularProgressIndicator(color: EvioFanColors.primary),
      ),
      error: (e, st) => Center(
        child: Padding(
          padding: EdgeInsets.all(EvioSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: EvioFanColors.error,
              ),
              SizedBox(height: EvioSpacing.lg),
              Text(
                'Error al cargar eventos',
                style: EvioTypography.h4.copyWith(
                  color: EvioFanColors.foreground,
                ),
              ),
              SizedBox(height: EvioSpacing.sm),
              Text(
                e.toString(),
                style: EvioTypography.bodySmall.copyWith(
                  color: EvioFanColors.mutedForeground,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================
  // TAB: COLECCIONABLES
  // ============================================

  Widget _buildColeccionablesTab() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(EvioSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(EvioSpacing.xl),
              decoration: BoxDecoration(
                color: EvioFanColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.emoji_events_outlined,
                size: 64,
                color: EvioFanColors.primary,
              ),
            ),
            SizedBox(height: EvioSpacing.xl),
            Text(
              'Próximamente',
              style: EvioTypography.h3.copyWith(
                color: EvioFanColors.foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: EvioSpacing.sm),
            Text(
              'Coleccioná totems exclusivos\nde cada evento',
              style: EvioTypography.bodyMedium.copyWith(
                color: EvioFanColors.mutedForeground,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // TAB: SOCIAL
  // ============================================

  Widget _buildSocialTab() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          // Sub-tabs
          Container(
            color: EvioFanColors.background,
            child: TabBar(
              labelColor: EvioFanColors.primary,
              unselectedLabelColor: EvioFanColors.mutedForeground,
              indicatorColor: EvioFanColors.primary,
              tabs: const [
                Tab(text: 'Seguidos'),
                Tab(text: 'Seguidores'),
              ],
            ),
          ),

          // Content
          Expanded(
            child: TabBarView(
              children: [
                _buildFollowingList(),
                _buildFollowersList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowingList() {
    final followingAsync = ref.watch(myFollowingProvider);

    return followingAsync.when(
      data: (users) {
        if (users.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(EvioSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(EvioSpacing.xl),
                    decoration: BoxDecoration(
                      color: EvioFanColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_add_outlined,
                      size: 64,
                      color: EvioFanColors.primary,
                    ),
                  ),
                  SizedBox(height: EvioSpacing.xl),
                  Text(
                    'No seguís a nadie aún',
                    style: EvioTypography.h3.copyWith(
                      color: EvioFanColors.foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: EvioSpacing.sm),
                  Text(
                    'Buscá usuarios y empezá\na seguirlos',
                    style: EvioTypography.bodyMedium.copyWith(
                      color: EvioFanColors.mutedForeground,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(EvioSpacing.lg),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return _UserFollowCard(user: user);
          },
        );
      },
      loading: () => Center(
        child: CircularProgressIndicator(color: EvioFanColors.primary),
      ),
      error: (e, st) => Center(
        child: Padding(
          padding: EdgeInsets.all(EvioSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: EvioFanColors.error,
              ),
              SizedBox(height: EvioSpacing.lg),
              Text(
                'Error al cargar usuarios',
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

  Widget _buildFollowersList() {
    final followersAsync = ref.watch(myFollowersProvider);

    return followersAsync.when(
      data: (users) {
        if (users.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(EvioSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(EvioSpacing.xl),
                    decoration: BoxDecoration(
                      color: EvioFanColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.people_outline,
                      size: 64,
                      color: EvioFanColors.primary,
                    ),
                  ),
                  SizedBox(height: EvioSpacing.xl),
                  Text(
                    'Sin seguidores',
                    style: EvioTypography.h3.copyWith(
                      color: EvioFanColors.foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: EvioSpacing.sm),
                  Text(
                    'Cuando otros usuarios te sigan,\naparecerán aquí',
                    style: EvioTypography.bodyMedium.copyWith(
                      color: EvioFanColors.mutedForeground,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(EvioSpacing.lg),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return _UserFollowCard(user: user);
          },
        );
      },
      loading: () => Center(
        child: CircularProgressIndicator(color: EvioFanColors.primary),
      ),
      error: (e, st) => Center(
        child: Padding(
          padding: EdgeInsets.all(EvioSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: EvioFanColors.error,
              ),
              SizedBox(height: EvioSpacing.lg),
              Text(
                'Error al cargar seguidores',
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

  // ============================================
  // TAB: CONFIGURACIÓN (con datos personales)
  // ============================================

  Widget _buildConfigTab(User user) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(EvioSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ SECCIÓN: DATOS PERSONALES
          Text(
            'DATOS PERSONALES',
            style: EvioTypography.labelSmall.copyWith(
              color: EvioFanColors.mutedForeground,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: EvioSpacing.sm),

          _buildConfigOption(
            icon: Icons.person_outline,
            title: 'Editar perfil',
            subtitle: 'Nombre, email, teléfono, DNI',
            onTap: () => context.push('/profile/edit'),
          ),

          SizedBox(height: EvioSpacing.xl),

          // ✅ SECCIÓN: CONFIGURACIÓN
          Text(
            'CONFIGURACIÓN',
            style: EvioTypography.labelSmall.copyWith(
              color: EvioFanColors.mutedForeground,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: EvioSpacing.sm),

          _buildConfigOption(
            icon: Icons.notifications_outlined,
            title: 'Notificaciones',
            subtitle: 'Preferencias y alertas',
            onTap: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Próximamente')));
            },
          ),
          _buildConfigOption(
            icon: Icons.help_outline,
            title: 'Ayuda y soporte',
            subtitle: 'Centro de ayuda',
            onTap: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Próximamente')));
            },
          ),
          _buildConfigOption(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacidad',
            subtitle: 'Política de privacidad',
            onTap: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Próximamente')));
            },
          ),

          SizedBox(height: EvioSpacing.xl),

          // ✅ CERRAR SESIÓN
          _buildConfigOption(
            icon: Icons.logout,
            title: 'Cerrar sesión',
            isDestructive: true,
            onTap: () async {
              final authRepo = AuthRepository();
              await authRepo.signOut();

              if (!mounted) return;
              
              // Navegar al home
              context.go('/home');
              
              // Mostrar mensaje
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sesión cerrada'),
                  backgroundColor: EvioFanColors.primary,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildConfigOption({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(EvioSpacing.md),
        margin: EdgeInsets.only(bottom: EvioSpacing.sm),
        decoration: BoxDecoration(
          color: EvioFanColors.surface,
          borderRadius: BorderRadius.circular(EvioRadius.card),
          border: Border.all(color: EvioFanColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(EvioSpacing.sm),
              decoration: BoxDecoration(
                color: isDestructive
                    ? EvioFanColors.error.withValues(alpha: 0.1)
                    : EvioFanColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(EvioRadius.button),
              ),
              child: Icon(
                icon,
                color: isDestructive
                    ? EvioFanColors.error
                    : EvioFanColors.primary,
                size: 22,
              ),
            ),
            SizedBox(width: EvioSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: EvioTypography.bodyLarge.copyWith(
                      color: isDestructive
                          ? EvioFanColors.error
                          : EvioFanColors.foreground,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: EvioTypography.bodySmall.copyWith(
                        color: EvioFanColors.mutedForeground,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: EvioFanColors.mutedForeground,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // NO SESSION STATE
  // ============================================

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

  // ============================================
  // AVATAR OPTIONS
  // ============================================

  void _showAvatarOptions(User user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: EvioFanColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(EvioRadius.card),
        ),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Elegir de galería'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery, user);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tomar foto'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera, user);
              },
            ),
            if (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
              ListTile(
                leading: Icon(Icons.delete, color: EvioFanColors.error),
                title: Text(
                  'Eliminar foto',
                  style: TextStyle(color: EvioFanColors.error),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deleteAvatar(user);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source, User user) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null || _isDisposed || !mounted) return;

      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: EdgeInsets.all(EvioSpacing.xl),
            decoration: BoxDecoration(
              color: EvioFanColors.surface,
              borderRadius: BorderRadius.circular(EvioRadius.card),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: EvioFanColors.primary),
                SizedBox(height: EvioSpacing.md),
                Text(
                  'Subiendo imagen...',
                  style: EvioTypography.bodyMedium.copyWith(
                    color: EvioFanColors.foreground,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final file = File(pickedFile.path);
      final profileActions = ref.read(profileActionsProvider);

      await profileActions.uploadAvatar(userId: user.id, file: file);

      if (!_isDisposed && mounted) {
        Navigator.of(context).pop(); // Cerrar loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Avatar actualizado'),
            backgroundColor: EvioFanColors.primary,
          ),
        );
      }
    } catch (e) {
      if (!_isDisposed && mounted) {
        Navigator.of(context).pop(); // Cerrar loading si está abierto
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: EvioFanColors.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteAvatar(User user) async {
    try {
      final userRepo = ref.read(userRepositoryProvider);

      await userRepo.updateAvatar(user.id, '');

      if (!_isDisposed && mounted) {
        ref.invalidate(currentUserProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Avatar eliminado'),
            backgroundColor: EvioFanColors.primary,
          ),
        );
      }
    } catch (e) {
      if (!_isDisposed && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: EvioFanColors.error,
          ),
        );
      }
    }
  }
}

// ============================================
// SAVED EVENT CARD
// ============================================

class _SavedEventCard extends ConsumerWidget {
  final Event event;

  const _SavedEventCard({required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context.push('/event/${event.id}'),
      child: Container(
        padding: EdgeInsets.all(EvioSpacing.sm),
        decoration: BoxDecoration(
          color: EvioFanColors.surface,
          borderRadius: BorderRadius.circular(EvioRadius.card),
          border: Border.all(color: EvioFanColors.border),
        ),
        child: Row(
          children: [
            // Imagen
            Stack(
              children: [
                CachedEventImage(
                  imageUrl: event.imageUrl,
                  thumbnailUrl: event.thumbnailUrl,
                  fullImageUrl: event.fullImageUrl,
                  useThumbnail: true,
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.circular(EvioRadius.button),
                  memCacheWidth: 180,
                ),

                // Botón de quitar
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () {
                      ref.read(savedEventActionsProvider).unsaveEvent(event.id);
                    },
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.bookmark,
                        color: EvioFanColors.primary,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(width: EvioSpacing.md),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: EvioTypography.labelLarge.copyWith(
                      color: EvioFanColors.foreground,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: EvioSpacing.xxs),
                  Text(
                    _formatDate(event.startDatetime),
                    style: EvioTypography.bodySmall.copyWith(
                      color: EvioFanColors.mutedForeground,
                    ),
                  ),
                  SizedBox(height: EvioSpacing.xxs),
                  Text(
                    event.venueName,
                    style: EvioTypography.bodySmall.copyWith(
                      color: EvioFanColors.mutedForeground,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            Icon(
              Icons.chevron_right,
              color: EvioFanColors.mutedForeground,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final days = ['domingo', 'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado'];
    final months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];

    final dayName = days[date.weekday % 7];
    final day = date.day;
    final month = months[date.month - 1];

    return '$dayName $day.$month';
  }
}

// ============================================
// USER FOLLOW CARD
// ============================================

class _UserFollowCard extends ConsumerWidget {
  final User user;

  const _UserFollowCard({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followingIdsAsync = ref.watch(myFollowingIdsProvider);
    final isFollowing = followingIdsAsync.maybeWhen(
      data: (ids) => ids.contains(user.id),
      orElse: () => false,
    );

    return Container(
      padding: EdgeInsets.all(EvioSpacing.sm),
      margin: EdgeInsets.only(bottom: EvioSpacing.sm),
      decoration: BoxDecoration(
        color: EvioFanColors.surface,
        borderRadius: BorderRadius.circular(EvioRadius.card),
        border: Border.all(color: EvioFanColors.border),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 28,
            backgroundColor: EvioFanColors.primary.withValues(alpha: 0.2),
            backgroundImage:
                user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
            child: user.avatarUrl == null
                ? Text(
                    user.fullName[0].toUpperCase(),
                    style: TextStyle(
                      color: EvioFanColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  )
                : null,
          ),

          SizedBox(width: EvioSpacing.md),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: EvioTypography.labelLarge.copyWith(
                    color: EvioFanColors.foreground,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  user.email,
                  style: EvioTypography.bodySmall.copyWith(
                    color: EvioFanColors.mutedForeground,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Botón Follow/Unfollow
          SizedBox(
            height: 36,
            child: OutlinedButton(
              onPressed: () {
                ref.read(followActionsProvider).toggleFollow(user.id);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: isFollowing
                    ? EvioFanColors.mutedForeground
                    : EvioFanColors.primary,
                side: BorderSide(
                  color: isFollowing
                      ? EvioFanColors.border
                      : EvioFanColors.primary,
                ),
                padding: EdgeInsets.symmetric(horizontal: EvioSpacing.md),
              ),
              child: Text(
                isFollowing ? 'Siguiendo' : 'Seguir',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
