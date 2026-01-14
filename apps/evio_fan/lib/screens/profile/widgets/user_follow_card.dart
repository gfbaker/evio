import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evio_core/evio_core.dart';
import '../../../providers/follow_provider.dart';

/// Card para mostrar un usuario en las listas de seguidos/seguidores
class UserFollowCard extends ConsumerWidget {
  final User user;

  const UserFollowCard({super.key, required this.user});

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
            backgroundImage: user.avatarUrl != null 
                ? NetworkImage(user.avatarUrl!) 
                : null,
            child: user.avatarUrl == null
                ? Text(
                    user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
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
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
