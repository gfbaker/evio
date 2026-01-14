import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evio_core/evio_core.dart';
import '../../../providers/follow_provider.dart';
import '../../../widgets/search/search_users_bottom_sheet.dart';
import '../widgets/user_follow_card.dart';

/// Tab social con seguidos y seguidores
class SocialTab extends ConsumerWidget {
  const SocialTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          // Sub-tabs
          Container(
            color: Colors.transparent,
            padding: EdgeInsets.symmetric(horizontal: EvioSpacing.lg),
            child: TabBar(
              labelColor: EvioFanColors.primary,
              unselectedLabelColor: EvioFanColors.mutedForeground,
              indicatorColor: EvioFanColors.primary,
              indicatorWeight: 2,
              dividerColor: EvioFanColors.border.withValues(alpha: 0.3),
              labelStyle: EvioTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              unselectedLabelStyle: EvioTypography.labelMedium.copyWith(
                fontSize: 14,
              ),
              tabs: const [
                Tab(text: 'Seguidos'),
                Tab(text: 'Seguidores'),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: EdgeInsets.fromLTRB(
              EvioSpacing.lg,
              EvioSpacing.md,
              EvioSpacing.lg,
              EvioSpacing.sm,
            ),
            child: GestureDetector(
              onTap: () => SearchUsersBottomSheet.show(context),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: EvioSpacing.md,
                  vertical: EvioSpacing.sm + 2,
                ),
                decoration: BoxDecoration(
                  color: EvioFanColors.surface,
                  borderRadius: BorderRadius.circular(EvioRadius.input),
                  border: Border.all(color: EvioFanColors.border),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      color: EvioFanColors.mutedForeground,
                      size: 20,
                    ),
                    SizedBox(width: EvioSpacing.sm),
                    Text(
                      'Buscar usuarios...',
                      style: EvioTypography.bodyMedium.copyWith(
                        color: EvioFanColors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Content
          Expanded(
            child: TabBarView(
              children: [
                _FollowingList(),
                _FollowersList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// FOLLOWING LIST
// ============================================

class _FollowingList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followingAsync = ref.watch(myFollowingProvider);

    return followingAsync.when(
      data: (users) {
        if (users.isEmpty) {
          return _buildEmptyState(
            title: 'No seguís a nadie aún',
            subtitle: 'Buscá usuarios y empezá\na seguirlos',
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(EvioSpacing.lg),
          itemCount: users.length,
          itemBuilder: (context, index) => UserFollowCard(user: users[index]),
        );
      },
      loading: () => Center(
        child: CircularProgressIndicator(color: EvioFanColors.primary),
      ),
      error: (e, st) => _buildErrorState('Error al cargar usuarios'),
    );
  }
}

// ============================================
// FOLLOWERS LIST
// ============================================

class _FollowersList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followersAsync = ref.watch(myFollowersProvider);

    return followersAsync.when(
      data: (users) {
        if (users.isEmpty) {
          return _buildEmptyState(
            title: 'Sin seguidores',
            subtitle: 'Cuando otros usuarios te sigan,\naparecerán aquí',
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(EvioSpacing.lg),
          itemCount: users.length,
          itemBuilder: (context, index) => UserFollowCard(user: users[index]),
        );
      },
      loading: () => Center(
        child: CircularProgressIndicator(color: EvioFanColors.primary),
      ),
      error: (e, st) => _buildErrorState('Error al cargar seguidores'),
    );
  }
}

// ============================================
// SHARED STATES
// ============================================

Widget _buildEmptyState({required String title, required String subtitle}) {
  return Center(
    child: Padding(
      padding: EdgeInsets.only(
        left: EvioSpacing.xl,
        right: EvioSpacing.xl,
        top: EvioSpacing.xl,
        bottom: 120,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: EvioTypography.h3.copyWith(
              color: EvioFanColors.foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: EvioSpacing.sm),
          Text(
            subtitle,
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

Widget _buildErrorState(String message) {
  return Center(
    child: Padding(
      padding: EdgeInsets.all(EvioSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: EvioFanColors.error),
          SizedBox(height: EvioSpacing.lg),
          Text(
            message,
            style: EvioTypography.h4.copyWith(color: EvioFanColors.foreground),
          ),
        ],
      ),
    ),
  );
}
